import Foundation

/// Traduction des textes du lot US13f (Session, Conditions, Région). Même modèle que AnglaisE : table dédiée AnglaisF
/// (AnglaisF.xcstrings), clé = le texte français, langue prise dans le dossier .lproj de la langue de la région
/// (décision 7 du 7 nov.), pas dans celle du téléphone. En français, ou sans traduction, le texte revient tel quel.
/// Sans locale explicite, la région active (`RegionPersistee`) décide, comme `FormatConditions`.
nonisolated enum AnglaisF {
    static let table = "AnglaisF"

    private final class Ancre {}

    /// La locale de la région active.
    static func localeActive() -> Locale { RegionPersistee.lire().locale }

    /// Le paquet de la langue demandée, ou le paquet de l'app si cette langue n'a pas de dossier .lproj.
    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    /// Vrai pour l'anglais.
    static func estAnglais(_ locale: Locale) -> Bool { locale.language.languageCode?.identifier == "en" }

    static func t(_ fr: String, _ locale: Locale = localeActive()) -> String {
        guard locale.language.languageCode?.identifier != "fr" else { return fr }
        return bundle(locale).localizedString(forKey: fr, value: fr, table: table)
    }

    /// La version en minuscules d'un mot dont la clé est écrite avec une majuscule (« Crue » donne « crue », « flood » en anglais) :
    /// le catalogue ne garde jamais deux clés qui ne diffèrent que par la casse (génération de symboles).
    static func bas(_ cleCapitalisee: String, _ locale: Locale = localeActive()) -> String {
        t(cleCapitalisee, locale).lowercased()
    }

    /// Une question dont la clé est la phrase sans point d'interrogation (la ponctuation ne compte pas pour les symboles du catalogue) :
    /// « Terminer la session ? » en français (espace avant), « End session? » en anglais.
    static func question(_ cle: String, _ locale: Locale = localeActive()) -> String {
        t(cle, locale) + (locale.language.languageCode?.identifier == "fr" ? " ?" : "?")
    }

    /// Un texte à trous : la clé française contient %@, %lld ou %1$@ ; région active.
    static func f(_ fr: String, _ args: CVarArg...) -> String {
        let locale = localeActive()
        return String(format: t(fr, locale), arguments: args)
    }

    static func f(_ fr: String, locale: Locale, _ args: CVarArg...) -> String {
        String(format: t(fr, locale), arguments: args)
    }

    /// Choisit le singulier ou le pluriel avec leurs clés françaises (« 1 prise » / « %lld prises »).
    static func nombre(_ n: Int, un: String, autres: String, locale: Locale = localeActive()) -> String {
        n == 1 ? t(un, locale) : String(format: t(autres, locale), n)
    }
}
