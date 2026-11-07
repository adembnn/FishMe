import Foundation

/// Traduction des textes du lot US13e. Même modèle que TextesReglesUS : table dédiée AnglaisE (AnglaisE.xcstrings),
/// clé = le texte français, langue prise dans le dossier .lproj de la langue de la région (décision 7 du 7 nov.),
/// pas dans celle du téléphone. En français, le texte revient tel quel.
nonisolated enum AnglaisE {
    static let table = "AnglaisE"

    private final class Ancre {}

    /// Le paquet de la langue demandée, ou le paquet de l'app si cette langue n'a pas de dossier .lproj.
    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    /// Le texte dans la langue de la région. En français, ou sans traduction : le texte français (la clé).
    static func t(_ fr: String, _ locale: Locale) -> String {
        guard locale.language.languageCode?.identifier != "fr" else { return fr }
        return bundle(locale).localizedString(forKey: fr, value: fr, table: table)
    }

    /// Un texte à trous : la clé française contient %@ (texte) ou %lld (entier), remplis dans l'ordre.
    static func f(_ fr: String, _ locale: Locale, _ args: CVarArg...) -> String {
        String(format: t(fr, locale), locale: locale, arguments: args)
    }
}
