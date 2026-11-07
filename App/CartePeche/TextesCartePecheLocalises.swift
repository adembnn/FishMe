import Core
import Foundation

/// Les textes de Core et de la carte de pêche qui ont des trous (jours, nombres), dans la langue de la région.
/// Le français et les chaînes de Core ne changent pas : en français, ces fonctions rendent exactement le même texte.
/// Clés dans `AnglaisE.xcstrings` (table `AnglaisE`).

/// Un jour civil écrit selon la langue : « 31/12/2026 » en français, « Dec 31, 2026 » en anglais.
nonisolated enum JourLocalise {
    static func texte(_ jour: JourCivil, _ locale: Locale) -> String {
        if locale.language.languageCode?.identifier == "fr" { return jour.texte }
        guard let date = jour.date(calendrier: .current) else { return jour.texte }
        let style = Date.FormatStyle(date: .abbreviated, time: .omitted, locale: locale, calendar: .current, timeZone: .current)
        return date.formatted(style)
    }
}

extension EtatCartePeche {
    /// Comme `libelle(expireLe:)`, dans la langue de la région.
    func libelle(expireLe: JourCivil, locale: Locale) -> String {
        switch self {
        case .jusquAu(let jour):
            return AnglaisE.f("Jusqu'au %@", locale, JourLocalise.texte(jour, locale))
        case .expireBientot(let restants):
            switch restants {
            case 0: return AnglaisE.t("Expire aujourd'hui", locale)
            case 1: return AnglaisE.t("Expire demain", locale)
            default: return AnglaisE.f("Expire dans %lld jours", locale, restants)
            }
        case .expiree:
            return AnglaisE.f("Expirée le %@", locale, JourLocalise.texte(expireLe, locale))
        }
    }
}

extension ErreurFiche {
    func messageLocalise(_ locale: Locale) -> String { AnglaisE.t(message, locale) }
}

extension RappelCartePeche {
    /// Titre de la notification, dans la langue de la région.
    static func titreLocalise(_ locale: Locale) -> String { AnglaisE.t(titre, locale) }

    static func corps(millesime: Int, expireLe: JourCivil, locale: Locale) -> String {
        AnglaisE.f("Millésime %lld · expire le %@.", locale, millesime, JourLocalise.texte(expireLe, locale))
    }

    static func messageSansRappel(expireLe: JourCivil, aujourdhui: JourCivil, locale: Locale) -> String? {
        guard jourDuRappel(expireLe: expireLe, aujourdhui: aujourdhui) == nil else { return nil }
        let restants = aujourdhui.jours(jusqua: expireLe)
        if restants < 0 { return AnglaisE.t("Ta carte est expirée : pas de rappel.", locale) }
        if restants == 0 { return AnglaisE.t("Ta carte expire aujourd'hui : pas de rappel.", locale) }
        if restants == 1 { return AnglaisE.t("Moins de 30 jours : pas de rappel, ta carte expire dans 1 jour.", locale) }
        return AnglaisE.f("Moins de 30 jours : pas de rappel, ta carte expire dans %lld jours.", locale, restants)
    }
}
