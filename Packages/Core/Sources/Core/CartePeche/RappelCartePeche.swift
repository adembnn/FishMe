import Foundation

/// Le rappel posé 30 jours avant l'expiration. Pur : l'heure (9 h) et l'envoi sont côté app.
public enum RappelCartePeche {
    public static let joursAvant = 30

    /// Le jour où prévenir : `expireLe` moins 30 jours. `nil` si ce jour est aujourd'hui ou déjà passé
    /// (une notification déjà passée n'est jamais reprogrammée).
    public static func jourDuRappel(expireLe: JourCivil, aujourdhui: JourCivil) -> JourCivil? {
        let jour = expireLe.ajouter(jours: -joursAvant)
        return jour > aujourdhui ? jour : nil
    }

    /// Titre de la notification. Aucun conseil légal.
    public static let titre = "Ta carte de pêche expire dans 30 jours"

    /// « Millésime 2026 · expire le 31/12/2026. »
    public static func corps(millesime: Int, expireLe: JourCivil) -> String {
        "Millésime \(millesime) · expire le \(expireLe.texte)."
    }

    /// Ce que l'écran dit quand aucun rappel n'est possible, ou `nil` quand un rappel l'est.
    public static func messageSansRappel(expireLe: JourCivil, aujourdhui: JourCivil) -> String? {
        guard jourDuRappel(expireLe: expireLe, aujourdhui: aujourdhui) == nil else { return nil }
        let restants = aujourdhui.jours(jusqua: expireLe)
        if restants < 0 { return "Ta carte est expirée : pas de rappel." }
        if restants == 0 { return "Ta carte expire aujourd'hui : pas de rappel." }
        let unite = restants == 1 ? "jour" : "jours"
        return "Moins de \(joursAvant) jours : pas de rappel, ta carte expire dans \(restants) \(unite)."
    }
}
