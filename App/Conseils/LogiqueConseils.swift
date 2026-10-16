import Core
import Foundation

/// Clés de ce qui reste sur l'iPhone (`@AppStorage`). Aucune n'est envoyée nulle part.
nonisolated enum ClesConseils {
    static let niveau = "conseils.niveauPecheur"
    static let questionVue = "conseils.questionNiveauVue"
    static let tunnelVu = "conseils.tunnelVu"
}

extension NiveauPecheur {
    /// Question passée ou niveau inconnu : « je débute » (conseils les plus simples).
    nonisolated static var parDefaut: NiveauPecheur { .debutant }

    nonisolated static func depuis(_ brut: String) -> NiveauPecheur {
        NiveauPecheur(rawValue: brut) ?? .parDefaut
    }

    nonisolated var mot: String {
        switch self {
        case .debutant: "Débutant"
        case .occasionnel: "Occasionnel"
        case .confirme: "Confirmé"
        }
    }

    /// Pictogramme provisoire (SF Symbols), en attendant le choix d'Adem.
    nonisolated var pictogramme: String {
        switch self {
        case .debutant: "leaf.fill"
        case .occasionnel: "fish.fill"
        case .confirme: "star.fill"
        }
    }
}

/// Ce que l'écran montre d'une liste de conseils. Rien n'est réécrit : on ne fait que retirer et compter.
nonisolated struct ConseilsAffiches: Sendable, Equatable {
    var visibles: [Conseil]
    var nbCaches: Int
    /// Vrai : la ligne « tout le kit » s'affiche (il reste des conseils derrière le paywall).
    var toutLeKit: Bool { nbCaches > 0 }
}

nonisolated enum RegleConseils {
    /// - Un conseil sans source ne s'affiche jamais.
    /// - `toutOuvert` vient de `peutUtiliser(.conseilsComplets, ...)` de Core : vrai, tout s'affiche ;
    ///   faux, seuls les conseils marqués gratuits par Core (le 1er de chaque espèce) s'affichent.
    static func affiches(_ conseils: [Conseil], toutOuvert: Bool) -> ConseilsAffiches {
        let sourcés = conseils.filter { !$0.source.titre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if toutOuvert { return ConseilsAffiches(visibles: sourcés, nbCaches: 0) }
        let gratuits = sourcés.filter(\.gratuit)
        return ConseilsAffiches(visibles: gratuits, nbCaches: sourcés.count - gratuits.count)
    }
}

/// Ce que la carte « à essayer » et les fiches ont besoin de savoir, passé par A depuis `RootView.swift`.
struct ContexteConseils {
    var conseils: any ServiceConseils
    var session: any ServiceSession
    var mois: Int
    /// Le lieu du spot : la version de `conseils` avec le lieu retire ce qu'une règle du jour y interdit.
    var lieu: Lieu?
    var abonne: Bool
    var surSonSpot: Bool
    /// Action de A vers le paywall de L6, avec le nom de la fonction touchée (E7).
    var toutLeKit: (FonctionPro) -> Void

    /// Le mois demandé d'abord, puis +1, -1, +2, -2… (circulaire). Mois hors 1...12 : seulement lui (Core rend vide).
    static func moisParProximite(_ mois: Int) -> [Int] {
        guard (1...12).contains(mois) else { return [mois] }
        var liste = [mois]
        for d in 1...6 {
            for m in [mois + d, mois - d] {
                let n = (m - 1 + 12) % 12 + 1
                if !liste.contains(n) { liste.append(n) }
            }
        }
        return liste
    }

    /// Le meilleur conseil de chaque type (appât, hameçon, technique, moment), pris au mois le plus proche.
    /// Vide si le service ne sait pas répondre par type (faux services) : l'écran retombe alors sur la liste.
    func parType(espece: Espece, niveau: NiveauPecheur) -> [TypeConseil: Conseil] {
        guard let service = conseils as? any ServiceConseilsParType else { return [:] }
        return service.conseilsParType(espece: espece, niveau: niveau, mois: mois, lieu: lieu)
    }

    func affiches(espece: Espece, niveau: NiveauPecheur) -> ConseilsAffiches {
        // Core ne rend que les conseils du mois (conseils.json : surtout avril à août). Hors saison la liste serait
        // vide : on prend alors les conseils du mois le plus proche, plutôt que « Pas encore de conseil ».
        let brut = Self.moisParProximite(mois).lazy
            .map { m -> [Conseil] in
                if let lieu { return conseils.conseils(espece: espece, niveau: niveau, mois: m, lieu: lieu) }
                return conseils.conseils(espece: espece, niveau: niveau, mois: m)
            }
            .first { !$0.isEmpty } ?? []
        let ouvert = session.peutUtiliser(.conseilsComplets, abonne: abonne, surSonSpot: surSonSpot)
        return RegleConseils.affiches(brut, toutOuvert: ouvert)
    }
}

/// Les espèces du spot, dans l'ordre de la carte « à essayer ».
nonisolated enum EspecesDuSpot {
    /// Ouvertes d'abord, la plus souvent relevée en tête (par défaut, à confirmer par Adem) ; les fermées ensuite, avec leur date.
    /// Jamais classées par « chances ».
    static func ordonnees(_ proches: [EspeceProche]) -> [EspeceProche] {
        func ouverte(_ e: EspeceProche) -> Bool {
            if case .ouverte = e.ouverture { return true }
            return false
        }
        return proches.enumerated().sorted { a, b in
            if ouverte(a.element) != ouverte(b.element) { return ouverte(a.element) }
            if a.element.nPeches != b.element.nPeches { return a.element.nPeches > b.element.nPeches }
            return a.offset < b.offset
        }.map(\.element)
    }

    static func texteFermeture(_ ouverture: OuvertureDuJour) -> String? {
        guard case .fermee(let date) = ouverture else { return nil }
        guard let date else { return "Fermée ce jour" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "dd/MM"
        return "Fermée jusqu'au \(f.string(from: date))"
    }
}

/// Les ~12 espèces du tunnel des 3 premières minutes : celles relevées par l'OFB dans la zone d'abord (la plus fréquente en tête),
/// puis les espèces courantes en France pour compléter. Les salmonidés ne passent devant que si la zone est en 1re catégorie
/// ou s'ils sont relevés dans la zone.
nonisolated enum EspecesDuTunnel {
    static let nombre = 12

    /// Espèces courantes partout en France, dans l'ordre de présentation (choix éditorial, aucun chiffre).
    static let courantes: [String] = [
        "gardon", "perche-commune", "brochet", "carpe-commune", "sandre", "black-bass", "tanche", "chevesne",
        "breme-commune", "rotengle", "silure-glane", "barbeau-fluviatile", "ablette", "goujon", "perche-soleil",
    ]

    static let salmonides: Set<String> = [
        "truite-fario", "truite-arc-en-ciel", "truite-de-mer", "saumon-atlantique", "omble-de-fontaine",
        "omble-chevalier", "cristivomer", "ombre-commun", "huchon", "coregones", "truite-tigre",
    ]

    /// `categorie` : catégorie piscicole de la zone si on la connaît (`nil` ou `.inconnue` : les salmonidés ne complètent pas).
    static func choisir(pechables: [EspecePechable], proches: [EspeceProche], categorie: Categorie? = nil,
                        nombre: Int = EspecesDuTunnel.nombre) -> [EspecePechable] {
        let parId = Dictionary(pechables.map { ($0.espece.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        var choisies: [EspecePechable] = []
        var vues = Set<String>()
        func ajouter(_ p: EspecePechable) {
            if choisies.count < nombre, vues.insert(p.espece.id).inserted { choisies.append(p) }
        }
        // 1. Relevées dans la zone, la plus souvent pêchée d'abord (l'ordre d'origine départage les égalités).
        let triees = proches.enumerated().sorted {
            $0.element.nPeches != $1.element.nPeches ? $0.element.nPeches > $1.element.nPeches : $0.offset < $1.offset
        }
        for (_, proche) in triees {
            if let p = parId[proche.espece.id] { ajouter(p) }
        }
        // 2. Espèces courantes de France.
        for id in courantes {
            if let p = parId[id] { ajouter(p) }
        }
        // 3. Le reste de la liste, sans salmonidés sauf en 1re catégorie.
        let salmonidesAutorises = categorie == .premiere
        for p in pechables where salmonidesAutorises || !salmonides.contains(p.espece.id) {
            ajouter(p)
        }
        return choisies
    }
}
