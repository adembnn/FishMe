import Foundation

/// Où en est la date d'expiration d'une carte, sans jamais porter de verdict légal.
/// Le type n'a volontairement aucun cas de verdict (ni validité, ni conformité) : l'app lit une date saisie
/// par le pêcheur, elle ne sait rien de sa situation légale.
public enum EtatCartePeche: Sendable, Equatable {
    /// Plus de 30 jours avant la date d'expiration.
    case jusquAu(JourCivil)
    /// De 0 à 30 jours avant la date d'expiration (0 : c'est le jour même).
    case expireBientot(joursRestants: Int)
    /// La date est passée depuis `depuisJours` jours (au moins 1).
    case expiree(depuisJours: Int)

    public static let seuilExpireBientot = 30

    public static func calculer(expireLe: JourCivil, aujourdhui: JourCivil) -> EtatCartePeche {
        let restants = aujourdhui.jours(jusqua: expireLe)
        if restants < 0 { return .expiree(depuisJours: -restants) }
        if restants <= seuilExpireBientot { return .expireBientot(joursRestants: restants) }
        return .jusquAu(expireLe)
    }

    /// Le texte affiché : « Jusqu'au 31/12/2026 », « Expire dans 12 jours », « Expirée le 31/12/2025 ».
    public func libelle(expireLe: JourCivil) -> String {
        switch self {
        case .jusquAu(let jour):
            return "Jusqu'au \(jour.texte)"
        case .expireBientot(let restants):
            switch restants {
            case 0: return "Expire aujourd'hui"
            case 1: return "Expire demain"
            default: return "Expire dans \(restants) jours"
            }
        case .expiree:
            return "Expirée le \(expireLe.texte)"
        }
    }
}
