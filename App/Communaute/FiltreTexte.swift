import Core
import Foundation

/// Pourquoi un texte est refusé à la saisie. Message court, jamais la liste des mots.
nonisolated enum RefusTexte: Sendable, Equatable {
    case tropLong
    case motInterdit
    case coordonnee
    case lienCarte

    var message: String {
        switch self {
        case .tropLong: "Texte trop long."
        case .motInterdit: "Ce mot n'est pas accepté."
        case .coordonnee: "Pas de coordonnées : le coin reste secret."
        case .lienCarte: "Pas de lien de carte : le coin reste secret."
        }
    }
}

/// Le filtre de la règle 1.2 d'Apple (`moderation.md`) : refus à la saisie, par mot entier, jamais par sous-chaîne.
/// La liste de mots vit dans `Core` (`MotsInterditsFR`, LDNOOBW CC-BY-4.0, attribution dans Sources) : une seule liste pour
/// le feed, le chat et les surnoms.
nonisolated enum FiltreTexte {
    static let longueurMax = 280

    private static let liensCarte = [
        "google.com/maps", "goo.gl/maps", "maps.app.goo", "maps.apple", "waze.com", "what3words", "w3w.co",
        "openstreetmap", "geoportail", "geo:",
    ]

    /// `nil` : le texte est accepté.
    static func verifier(_ texte: String) -> RefusTexte? {
        if texte.count > longueurMax { return .tropLong }
        let bas = texte.lowercased()
        if liensCarte.contains(where: { bas.contains($0) }) { return .lienCarte }
        if ressembleACoordonnee(texte) { return .coordonnee }
        if contientMotInterdit(texte) { return .motInterdit }
        return nil
    }

    static func contientMotInterdit(_ texte: String) -> Bool {
        MotsInterditsFR.contient(texte)
    }

    /// Deux nombres décimaux à 3 chiffres ou plus après la virgule, un mot « lat », « lon », « gps », ou des degrés.
    static func ressembleACoordonnee(_ texte: String) -> Bool {
        if occurrences("-?[0-9]{1,3}[.,][0-9]{3,}", dans: texte) >= 2 { return true }
        if occurrences("[0-9]{1,3} ?° ?[0-9]{1,2}", dans: texte) >= 1 { return true }
        let mots = Set(texte.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init))
        return !mots.isDisjoint(with: ["lat", "lon", "lng", "gps", "latitude", "longitude"])
    }

    private static func occurrences(_ motif: String, dans texte: String) -> Int {
        guard let expression = try? NSRegularExpression(pattern: motif) else { return 0 }
        return expression.numberOfMatches(in: texte, range: NSRange(texte.startIndex..., in: texte))
    }

    /// Minuscules, sans accents, 0 devient o, 1 devient i, 3 devient e, @ devient a ; coupe aux caractères qui ne sont pas des lettres.
    static func decouper(_ texte: String) -> [String] {
        let propre = texte.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
        let remplace = propre.map { c -> Character in
            switch c {
            case "0": "o"
            case "1": "i"
            case "3": "e"
            case "@": "a"
            default: c
            }
        }
        return String(remplace).split(whereSeparator: { !$0.isLetter }).map(String.init)
    }

    /// Réduit les lettres répétées (« connaaard » devient « conard ») des deux côtés de la comparaison.
    static func reduire(_ mot: String) -> String {
        var sortie = ""
        for c in mot where c != sortie.last { sortie.append(c) }
        return sortie
    }
}
