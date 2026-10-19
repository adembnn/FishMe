import Foundation

public enum ErreurFiche: Sendable, Equatable, CaseIterable {
    case millesimeHorsBornes
    case expirationAvantMillesime
    case expirationTropLointaine

    public var message: String {
        switch self {
        case .millesimeHorsBornes: return "Ce millésime ne semble pas correct."
        case .expirationAvantMillesime: return "La date d'expiration est avant le millésime."
        case .expirationTropLointaine: return "La date d'expiration est trop lointaine."
        }
    }
}

/// Garde-fous de saisie, pas du droit : aucune règle de fond (durée d'une carte, dates de saison).
public enum ValidationFiche {
    /// Plus de 3 ans après aujourd'hui (3 × 365 + 1 jours).
    public static let joursMaxAvantExpiration = 3 * 365 + 1
    public static let premierMillesime = 2000

    public static func verifier(millesime: Int, expireLe: JourCivil, aujourdhui: JourCivil) -> [ErreurFiche] {
        var erreurs: [ErreurFiche] = []
        if !(premierMillesime...(aujourdhui.annee + 1)).contains(millesime) {
            erreurs.append(.millesimeHorsBornes)
        }
        if expireLe.annee < millesime {
            erreurs.append(.expirationAvantMillesime)
        }
        if aujourdhui.jours(jusqua: expireLe) > joursMaxAvantExpiration {
            erreurs.append(.expirationTropLointaine)
        }
        return erreurs
    }
}
