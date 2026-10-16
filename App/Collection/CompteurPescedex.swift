import Core
import Foundation

/// Un emplacement du classeur : une espèce, avec la carte prise s'il y en a une.
struct Emplacement: Identifiable {
    var espece: EspecePechable
    var rarete: ResultatRarete
    var carte: Prise?
    /// Relevée dans la zone par l'OFB (compte dans les M du compteur).
    var releveeDansLaZone: Bool
    var id: String { espece.espece.id }
}

/// Compteur par zone, jamais « 3 sur 14 » : « 2 sur les 11 espèces relevées dans le 94 ».
struct CompteurPescedex: Equatable {
    var zone: Departement?
    var trouvees: Int
    var releveesDansLaZone: Int
    /// Légendaires pris, jamais relevés dans la zone : comptent en plus.
    var legendairesEnPlus: Int

    var texte: String {
        guard let zone else { return "Tes cartes se rangent ici, zone après zone." }
        let code = zone.code
        if releveesDansLaZone == 0 {
            return "Aucune espèce relevée dans le \(code) pour l'instant."
        }
        return "\(trouvees) sur les \(releveesDansLaZone) espèces relevées dans le \(code)" + suffixeLegendaires
    }

    /// « , + 1 légendaire » : partagé par `texte` (tests, accessibilité) et `phraseDeZone` (écran).
    private var suffixeLegendaires: String {
        legendairesEnPlus > 0 ? ", + \(legendairesEnPlus) légendaire" + (legendairesEnPlus > 1 ? "s" : "") : ""
    }

    /// La phrase sous le titre du Pescedex (P26 B, P48 B) : « Tu en as trouvé 3 sur 11 espèces de la zone ».
    /// `nil` sans zone connue ou sans espèce relevée dedans.
    var phraseDeZone: String? {
        guard let zone, !zone.estInconnu, releveesDansLaZone > 0 else { return nil }
        return "Tu en as trouvé \(trouvees) sur \(releveesDansLaZone) espèces de la zone" + suffixeLegendaires
    }

    /// La zone par défaut est le département de la dernière carte avec un lieu ; les cartes déclarées n'en ont pas.
    static func zoneParDefaut(cartes: [Prise], repli: Departement? = nil) -> Departement? {
        let avecLieu = cartes
            .filter { !$0.estDeclaree && !$0.exemple }
            .sorted { $0.date > $1.date }
        for carte in avecLieu {
            if let d = Formats.departement(depuisLieuFlou: carte.lieuFlou), !d.estInconnu { return d }
        }
        return repli
    }

    /// Les emplacements : d'abord les espèces relevées dans la zone, puis les autres. La carte d'exemple n'occupe aucun emplacement.
    static func emplacements(cartes: [Prise], especes: [EspecePechable], zone: Departement?,
                             rarete: (Espece, Departement) -> ResultatRarete) -> [Emplacement] {
        let reelles = cartes.filter { !$0.exemple }
        let parEspece = Dictionary(grouping: reelles, by: { $0.espece.id })
        let liste = especes.map { e -> Emplacement in
            let r = zone.map { rarete(e.espece, $0) }
                ?? ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: .departement)
            let derniere = parEspece[e.espece.id]?.sorted { $0.date > $1.date }.first
            return Emplacement(espece: e, rarete: r, carte: derniere, releveeDansLaZone: estReleveeDansLaZone(r))
        }
        // `sorted` n'est pas stable : on garde l'ordre d'origine dans chaque groupe.
        let dansLaZone = liste.filter(\.releveeDansLaZone)
        let ailleurs = liste.filter { !$0.releveeDansLaZone }
        return dansLaZone + ailleurs
    }

    static func compteur(emplacements: [Emplacement], zone: Departement?) -> CompteurPescedex {
        let dansLaZone = emplacements.filter(\.releveeDansLaZone)
        let trouvees = dansLaZone.filter { $0.carte != nil }.count
        let legendaires = emplacements.filter { $0.carte != nil && $0.rarete.niveau == .legendaire }.count
        return CompteurPescedex(zone: zone, trouvees: trouvees, releveesDansLaZone: dansLaZone.count, legendairesEnPlus: legendaires)
    }

    /// Relevée dans la zone : au moins une pêche OFB, et ni légendaire ni non mesurée.
    static func estReleveeDansLaZone(_ r: ResultatRarete) -> Bool {
        r.nPeches > 0 && r.niveau != .legendaire && r.niveau != .nonMesuree
    }

    /// Rang de la carte dans la zone : ordre de première prise parmi les espèces relevées dans cette zone (1 pour la première).
    static func rang(de carte: Prise, parmi cartes: [Prise], zone: Departement?, especesDeLaZone: Set<String>) -> Int? {
        guard zone != nil, especesDeLaZone.contains(carte.espece.id) else { return nil }
        var premieres: [String: Date] = [:]
        for c in cartes where !c.exemple && especesDeLaZone.contains(c.espece.id) {
            if let d = premieres[c.espece.id] { premieres[c.espece.id] = min(d, c.date) } else { premieres[c.espece.id] = c.date }
        }
        let tri = premieres.sorted { $0.value < $1.value }.map(\.key)
        return tri.firstIndex(of: carte.espece.id).map { $0 + 1 }
    }
}
