import Foundation
import Core

// Carte des États-Unis (lot US10). Les données de zones (rampes, quais, accès listés, plans d'eau, avis de santé de l'eau)
// viennent du lot US11 (Core.GeoUS). Pour ne pas attendre, la carte lit un PROTOCOLE à elle (SourceCarteUS) ; l'adaptateur
// vers Core.GeoUS est dans SourceGeoUS.swift. Chaque élément porte sa source et sa date : aucun lieu n'est montré sans elles.

/// Le genre d'un point d'accès listé par l'agence d'État.
nonisolated enum TypeAccesCarteUS: String, Sendable, Hashable, CaseIterable {
    case rampe
    case quai
    case accesPublic
    case autre

    var libelle: String {
        switch self {
        case .rampe: "Rampe de mise à l'eau"
        case .quai: "Quai de pêche"
        case .accesPublic: "Accès public à l'eau"
        case .autre: "Accès listé par l'agence"
        }
    }

    var symbole: String {
        switch self {
        case .rampe: "ferry.fill"
        case .quai: "figure.fishing"
        case .accesPublic: "mappin.circle.fill"
        case .autre: "mappin"
        }
    }
}

/// Un point d'accès (rampe, quai, accès public) tel que l'agence d'État le liste.
nonisolated struct PointAccesCarteUS: Sendable, Hashable, Identifiable {
    var id: String
    var nom: String
    /// Code USPS de l'État (« WI »).
    var etat: String
    var latitude: Double
    var longitude: Double
    var type: TypeAccesCarteUS
    /// D'où vient la donnée (nom du jeu et de l'agence). Vide : « donnée absente ».
    var source: String
    /// Date de la donnée, écrite telle que la source la donne (AAAA-MM-JJ).
    var date: String

    var coordonnee: Coordonnee { Coordonnee(latitude: latitude, longitude: longitude) }
}

/// Un plan d'eau nommé (lac, réservoir), avec un rayon grossier autour de son point.
nonisolated struct PlanEauCarteUS: Sendable, Hashable, Identifiable {
    var id: String
    var nom: String
    var etat: String
    var latitude: Double
    var longitude: Double
    var rayonMetres: Double
    var source: String
    var date: String
    /// Page de l'agence sur ce plan d'eau, si la donnée en porte une (https seulement à l'affichage).
    var lienAgence: String?

    var coordonnee: Coordonnee { Coordonnee(latitude: latitude, longitude: longitude) }
}

/// Un avis de santé de l'eau (proliférations d'algues, consommation de poisson…) daté et sourcé. Affiché tel que lu, jamais reformulé.
nonisolated struct AvisSanteCarteUS: Sendable, Hashable {
    var planEauId: String?
    var texte: String
    var date: String
    var source: String
    var lien: String?
}

/// Ce que la carte lit. L'implémentation réelle est Core.GeoUS (US11) ; les tests posent une source de fixtures.
nonisolated protocol SourceCarteUS: Sendable {
    /// Les États dont des données sont chargées (« WI », « MN »).
    var etatsDisponibles: [String] { get }
    func points(etat: String) -> [PointAccesCarteUS]
    func plansEau(etat: String) -> [PlanEauCarteUS]
    func avis(etat: String) -> [AvisSanteCarteUS]
    /// L'État qui contient ce point, nil s'il n'est dans aucun État chargé.
    func etat(pour latitude: Double, longitude: Double) -> String?
}

/// Aucune donnée chargée : la carte dit honnêtement « Pas encore de données pour cet État ».
nonisolated struct SourceCarteUSVide: SourceCarteUS {
    var etatsDisponibles: [String] { [] }
    func points(etat: String) -> [PointAccesCarteUS] { [] }
    func plansEau(etat: String) -> [PlanEauCarteUS] { [] }
    func avis(etat: String) -> [AvisSanteCarteUS] { [] }
    func etat(pour latitude: Double, longitude: Double) -> String? { nil }
}

/// L'agence d'un État (niveau 1 : regles-us/etats.json).
nonisolated struct InfoAgenceUS: Sendable, Equatable, Identifiable {
    var code: String
    var nomEtat: String
    var agence: String
    var url: URL?

    var id: String { code }
}

nonisolated protocol AgencesCarteUS: Sendable {
    var tous: [InfoAgenceUS] { get }
}

nonisolated extension AgencesCarteUS {
    func agence(code: String) -> InfoAgenceUS? { tous.first { $0.code == code.uppercased() } }
}

/// Une liste d'agences posée à la main (tests, aperçus).
nonisolated struct AgencesFixesCarteUS: AgencesCarteUS {
    var tous: [InfoAgenceUS]
}

/// Les agences du niveau 1, lues dans etats.json embarqué (50 États et DC).
nonisolated struct AgencesNiveau1US: AgencesCarteUS {
    let tous: [InfoAgenceUS]

    init(niveau1: Niveau1US) {
        tous = niveau1.etats.map {
            InfoAgenceUS(code: $0.code.rawValue, nomEtat: $0.nom, agence: $0.agence, url: $0.urlAgence ?? $0.urlReglesEauDouce)
        }.sorted { a, b in a.nomEtat < b.nomEtat }
    }

    /// Les agences embarquées ; liste vide si le fichier est illisible (la carte reste utilisable, sans lien).
    static func embarquees() -> AgencesNiveau1US {
        (try? Niveau1US.embarque()).map(AgencesNiveau1US.init(niveau1:)) ?? AgencesNiveau1US(tous: [])
    }

    private init(tous: [InfoAgenceUS]) { self.tous = tous }
}

nonisolated extension SourceCarteUS {
    /// Les points d'accès à moins de rayonKm du lieu, du plus proche au plus loin, au plus limite.
    /// (Core.GeoUS en offre une version indexée ; celle-ci est le repli, lue État par État.)
    func points(autour latitude: Double, longitude: Double, rayonKm: Double, limite: Int) -> [PointAccesCarteUS] {
        SelectionCarteUS.autour(Coordonnee(latitude: latitude, longitude: longitude), rayonKm: rayonKm, limite: limite,
                                dans: etatsDisponibles.flatMap { points(etat: $0) })
    }
}
