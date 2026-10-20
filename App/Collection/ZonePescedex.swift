import Core
import Foundation

/// L'étendue du Pescedex, réglée par le menu en haut à droite (L18) : le spot du pêcheur, sa région, ou la France entière.
enum PorteePescedex: String, CaseIterable, Identifiable {
    case monSpot
    case maRegion
    case france

    var id: String { rawValue }

    /// Clé du choix gardé dans `@AppStorage`.
    static let cle = "pescedex.zone"

    /// Un choix inconnu (clé absente, ancienne valeur) revient sur « Mon spot », comme avant L18.
    init(brut: String) {
        self = PorteePescedex(rawValue: brut) ?? .monSpot
    }

    var libelle: String {
        switch self {
        case .monSpot: "Mon spot"
        case .maRegion: "Ma région"
        case .france: "France"
        }
    }

    var icone: String {
        switch self {
        case .monSpot: "mappin"
        case .maRegion: "map"
        case .france: "globe.europe.africa"
        }
    }
}

/// Une région et ses départements, fournis par `Core` (table des 13 régions, demandée à B/L1 : voir la fiche L18).
/// L'app n'invente jamais cette table : sans elle, « Ma région » reste grisé.
struct RegionPescedex: Equatable {
    var nom: String
    var departements: [Departement]
    /// La locution complète pour la phrase du compteur : « en Île-de-France », « dans les Hauts-de-France ».
    /// Sans valeur, « en » suivi du nom.
    var locution: String?

    init(nom: String, departements: [Departement], locution: String? = nil) {
        self.nom = nom
        self.departements = departements
        self.locution = locution
    }

    var phrase: String { locution ?? "en \(nom)" }

    /// La région d'un département d'après la table de `Core` (`RegionsFrance`) ; `nil` hors métropole ou département inconnu.
    /// À passer à `PescedexModele(regionDe:)`. // ⚠ à vérifier
    static func depuisCore(_ departement: Departement) -> RegionPescedex? {
        guard !departement.estInconnu,
              let region = RegionsFrance.region(deDepartement: departement.code) else { return nil }
        return RegionPescedex(nom: region.nom,
                              departements: region.departements.map { Departement(code: $0) },
                              locution: region.locution)
    }
}

/// Les calculs de zone du Pescedex, sans écran : l'union des relevés d'une région et la France entière.
enum CalculZonePescedex {
    /// La rareté d'une espèce sur plusieurs départements : celle du département où l'OFB a le plus de pêches de cette espèce ;
    /// aucun département ne la relève, le premier résultat (légendaire ou non mesurée). Les seuils restent ceux de Core.
    static func rareteUnion(_ resultats: [ResultatRarete]) -> ResultatRarete {
        let relevees = resultats.filter(CompteurPescedex.estReleveeDansLaZone)
        if let meilleure = relevees.max(by: { $0.nPeches < $1.nPeches }) { return meilleure }
        return resultats.first
            ?? ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: .departement)
    }

    /// Les emplacements d'une région : une espèce est « relevée dans la zone » si l'OFB l'a relevée dans un département de la région.
    static func emplacementsRegion(cartes: [Prise], especes: [EspecePechable], departements: [Departement],
                                   rarete: (Espece, Departement) -> ResultatRarete) -> [Emplacement] {
        let parEspece = Dictionary(grouping: cartes.filter { !$0.exemple }, by: { $0.espece.id })
        let liste = especes.map { e -> Emplacement in
            let resultats = departements.map { rarete(e.espece, $0) }
            let derniere = parEspece[e.espece.id]?.sorted { $0.date > $1.date }.first
            return Emplacement(espece: e, rarete: rareteUnion(resultats), carte: derniere,
                               releveeDansLaZone: resultats.contains(where: CompteurPescedex.estReleveeDansLaZone))
        }
        return liste.filter(\.releveeDansLaZone) + liste.filter { !$0.releveeDansLaZone }
    }

    /// Les emplacements de la France entière : toutes les espèces pêchables comptent, dans l'ordre de la liste.
    /// La rareté montrée est celle du département de référence du pêcheur (`nil` : non mesurée), comme avant L18.
    static func emplacementsFrance(cartes: [Prise], especes: [EspecePechable], reference: Departement?,
                                   rarete: (Espece, Departement) -> ResultatRarete) -> [Emplacement] {
        let parEspece = Dictionary(grouping: cartes.filter { !$0.exemple }, by: { $0.espece.id })
        return especes.map { e -> Emplacement in
            let r = reference.map { rarete(e.espece, $0) }
                ?? ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: .departement)
            let derniere = parEspece[e.espece.id]?.sorted { $0.date > $1.date }.first
            return Emplacement(espece: e, rarete: r, carte: derniere, releveeDansLaZone: true)
        }
    }
}
