import Foundation

/// La région de l'app (décision 7 du 7 nov. : une seule app, plusieurs régions). Données, modèle, langue et unités se chargent par région.
public enum RegionApp: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case france
    case etatsUnis

    /// Unités d'affichage par défaut de la région (le pêcheur peut les changer dans les réglages).
    public var unitesParDefaut: SystemeUnites {
        switch self {
        case .france: .metrique
        case .etatsUnis: .imperial
        }
    }
}
