import Foundation

/// Tout ce que la règle a besoin de savoir, et rien d'autre. Le calendrier et la date sont injectés :
/// la règle ne lit jamais l'horloge elle-même.
public struct ContexteSkin: Sendable {
    public let date: Date
    /// `Europe/Paris` en production.
    public let calendrier: Calendar
    public let abonne: Bool
    public let progression: ProgressionPecheur
    public let defisTermines: Set<IdentifiantSkin>

    public init(date: Date, calendrier: Calendar, abonne: Bool,
                progression: ProgressionPecheur = ProgressionPecheur(),
                defisTermines: Set<IdentifiantSkin> = []) {
        self.date = date
        self.calendrier = calendrier
        self.abonne = abonne
        self.progression = progression
        self.defisTermines = defisTermines
    }
}

public enum RaisonVerrou: Sendable, Equatable {
    case proRequis
}

public enum StatutSkin: Sendable, Equatable {
    /// On peut l'appliquer.
    case disponible
    /// On peut ouvrir l'aperçu, pas l'appliquer.
    case apercuSeulement(raison: RaisonVerrou)
    /// Saison close : revient à cette date (début de jour).
    case horsSaison(revientLe: Date)
    /// Décor à gagner en pêchant.
    case aGagner(CritereDecor)
}
