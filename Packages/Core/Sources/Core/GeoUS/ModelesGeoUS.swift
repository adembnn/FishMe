import Foundation

/// Nature d'un point d'accès listé par une agence. { accesPublic } veut dire { accès public listé }, jamais { pêche autorisée }.
public enum TypeAccesUS: String, Sendable, Hashable, CaseIterable, Codable {
    case rampe
    case quai
    case accesPublic
    case autre
}

/// Qui a dressé la liste : l'agence de l'État, ou les bénévoles d'OpenStreetMap. L'app en tire la phrase, dans sa langue.
public enum GenreSourceUS: String, Sendable, Hashable, Codable {
    case agence
    case osm
}

/// Un accès public listé par l'agence d'un État (rampe, quai, accès à pied). `source` nomme l'agence et le jeu de données (noms propres,
/// sans phrase : « Wisconsin DNR, WI DNR, Boat Access Sites (…) »), `genreSource` dit s'il est listé par l'agence ou cartographié par
/// OpenStreetMap, `date` quand on l'a lu (AAAA-MM-JJ). La phrase affichée se compose dans la langue de l'app, pas dans les données.
public struct PointAccesUS: Sendable, Hashable, Identifiable {
    public let id: String
    public let nom: String
    public let etat: String
    public let latitude: Double
    public let longitude: Double
    public let type: TypeAccesUS
    public let source: String
    public let genreSource: GenreSourceUS
    public let date: String

    public init(id: String, nom: String, etat: String, latitude: Double, longitude: Double, type: TypeAccesUS, source: String,
                genreSource: GenreSourceUS = .agence, date: String) {
        self.id = id
        self.nom = nom
        self.etat = etat
        self.latitude = latitude
        self.longitude = longitude
        self.type = type
        self.source = source
        self.genreSource = genreSource
        self.date = date
    }
}

/// Un plan d'eau nommé : centre et rayon du cercle de même surface (pas un contour).
public struct PlanEauUS: Sendable, Hashable, Identifiable {
    public let id: String
    public let nom: String
    public let etat: String
    public let latitude: Double
    public let longitude: Double
    public let rayonMetres: Double
    public let source: String
    public let date: String
    public let lienAgence: String?

    public init(id: String, nom: String, etat: String, latitude: Double, longitude: Double, rayonMetres: Double, source: String, date: String, lienAgence: String?) {
        self.id = id
        self.nom = nom
        self.etat = etat
        self.latitude = latitude
        self.longitude = longitude
        self.rayonMetres = rayonMetres
        self.source = source
        self.date = date
        self.lienAgence = lienAgence
    }
}

/// Un avis de consommation de poisson, daté, avec le lien de la page qui fait foi. `planEauId` est nil pour un avis qui vaut pour tout l'État.
public struct AvisSanteEauUS: Sendable, Hashable {
    public let planEauId: String?
    public let texte: String
    public let date: String
    public let source: String
    public let lien: String

    public init(planEauId: String?, texte: String, date: String, source: String, lien: String) {
        self.planEauId = planEauId
        self.texte = texte
        self.date = date
        self.source = source
        self.lien = lien
    }
}

/// Une ligne d'eau nommée, très simplifiée (environ 200 m) : repère visuel pour la carte, pas un tracé exact. Ajout au contrat de base.
public struct LigneEauUS: Sendable, Hashable, Identifiable {
    public let id: String
    public let nom: String
    public let etat: String
    /// Ordre de Strahler du tronçon (4 et plus).
    public let ordre: Int
    public let points: [Coordonnee]
    public let source: String
    public let date: String

    public init(id: String, nom: String, etat: String, ordre: Int, points: [Coordonnee], source: String, date: String) {
        self.id = id
        self.nom = nom
        self.etat = etat
        self.ordre = ordre
        self.points = points
        self.source = source
        self.date = date
    }
}
