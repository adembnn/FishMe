import Core
import Foundation

/// Clés de ce qui reste sur l'iPhone (`@AppStorage`). Aucune n'est envoyée nulle part.
enum ClesConseils {
    static let niveau = "conseils.niveauPecheur"
    static let questionVue = "conseils.questionNiveauVue"
    static let tunnelVu = "conseils.tunnelVu"
}

extension NiveauPecheur {
    /// Question passée : « occasionnel » (par défaut, à confirmer par Adem).
    static let parDefaut = NiveauPecheur.occasionnel

    static func depuis(_ brut: String) -> NiveauPecheur {
        NiveauPecheur(rawValue: brut) ?? .parDefaut
    }

    var mot: String {
        switch self {
        case .debutant: "Débutant"
        case .occasionnel: "Occasionnel"
        case .confirme: "Confirmé"
        }
    }

    /// Pictogramme provisoire (SF Symbols), en attendant le choix d'Adem.
    var pictogramme: String {
        switch self {
        case .debutant: "leaf.fill"
        case .occasionnel: "fish.fill"
        case .confirme: "star.fill"
        }
    }
}

/// Ce que l'écran montre d'une liste de conseils. Rien n'est réécrit : on ne fait que retirer et compter.
struct ConseilsAffiches: Equatable {
    var visibles: [Conseil]
    var nbCaches: Int
    /// Vrai : la ligne « tout le kit » s'affiche (il reste des conseils derrière le paywall).
    var toutLeKit: Bool { nbCaches > 0 }
}

enum RegleConseils {
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

    func affiches(espece: Espece, niveau: NiveauPecheur) -> ConseilsAffiches {
        let brut = if let lieu {
            conseils.conseils(espece: espece, niveau: niveau, mois: mois, lieu: lieu)
        } else {
            conseils.conseils(espece: espece, niveau: niveau, mois: mois)
        }
        let ouvert = session.peutUtiliser(.conseilsComplets, abonne: abonne, surSonSpot: surSonSpot)
        return RegleConseils.affiches(brut, toutOuvert: ouvert)
    }
}

/// Les espèces du spot, dans l'ordre de la carte « à essayer ».
enum EspecesDuSpot {
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

/// Les ~12 espèces du tunnel des 3 premières minutes : celles de la zone d'abord, puis les autres de la liste.
enum EspecesDuTunnel {
    static let nombre = 12

    static func choisir(pechables: [EspecePechable], proches: [EspeceProche], nombre: Int = EspecesDuTunnel.nombre) -> [EspecePechable] {
        let parId = Dictionary(pechables.map { ($0.espece.id, $0) }, uniquingKeysWith: { premier, _ in premier })
        var choisies: [EspecePechable] = []
        var vues = Set<String>()
        for proche in proches.sorted(by: { $0.nPeches > $1.nPeches }) {
            guard choisies.count < nombre, let p = parId[proche.espece.id], vues.insert(p.espece.id).inserted else { continue }
            choisies.append(p)
        }
        for p in pechables where choisies.count < nombre && vues.insert(p.espece.id).inserted {
            choisies.append(p)
        }
        return choisies
    }
}
