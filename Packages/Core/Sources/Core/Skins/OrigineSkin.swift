import Foundation

/// Ce qu'il faut avoir fait en pêchant pour gagner un décor.
public enum CritereDecor: Sendable, Equatable {
    case especesDifferentes(Int)
    case sessions(Int)
    case unLegendaire
}

/// D'où vient un skin, donc pour qui il est disponible.
public enum OrigineSkin: Sendable, Equatable {
    /// Gagné en pêchant : jamais verrouillé par le Pro, jamais retiré une fois gagné.
    case gagne(CritereDecor)
    /// Inclus dans le Pro, toute l'année.
    case pro
    /// Thème de saison : inclus dans le Pro, applicable pendant sa fenêtre.
    case saison(ThemeSaison, FenetreAnnuelle)
    /// Gratuit, à vie, quand un défi le débloque (`ContexteSkin.defisTermines`). Le défi lui-même n'est pas dans ce lot.
    case offertParDefi
}

/// Trois entiers, rien d'autre : ni endroit, ni date, ni photo. Le calcul est fait par l'app à partir de la collection.
public struct ProgressionPecheur: Sendable, Equatable {
    public let especesDifferentes: Int
    public let sessions: Int
    public let legendairesPris: Int

    public init(especesDifferentes: Int = 0, sessions: Int = 0, legendairesPris: Int = 0) {
        self.especesDifferentes = especesDifferentes
        self.sessions = sessions
        self.legendairesPris = legendairesPris
    }

    public func satisfait(_ critere: CritereDecor) -> Bool {
        switch critere {
        case .especesDifferentes(let n): return especesDifferentes >= n
        case .sessions(let n): return sessions >= n
        case .unLegendaire: return legendairesPris >= 1
        }
    }
}
