import Foundation

/// Textes anglais des dossiers Amis, Profil et Compte (lot US13b) : la clé est le français, la valeur anglaise est dans AnglaisB.xcstrings.
nonisolated enum AnglaisB {
    static let table = "AnglaisB"

    private final class Ancre {}

    /// Le paquet de la langue de la locale (en.lproj), ou le paquet de base quand la langue n'a pas de dossier (le français).
    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    /// La clé est le français littéral avec ses interpolations ; les pluriels sont des variations de plural de la table.
    static func t(_ cle: String.LocalizationValue, _ locale: Locale) -> String {
        String(localized: cle, table: table, bundle: bundle(locale), locale: locale)
    }

    /// La locale du français, pour le code sans environnement SwiftUI : rend le texte français d'origine.
    static let francais = Locale(identifier: "fr_FR")
}
