import Foundation

/// Textes de la feuille « Mon spot » (MonSpotView) que la région US voit. Même modèle que AnglaisFCarte : table dédiée « MonSpotTextes »,
/// clé = le texte français, langue prise dans le dossier .lproj de la langue de la région. En français, le texte revient tel quel.
nonisolated enum MonSpotTextes {
    static let table = "MonSpotTextes"

    private final class Ancre {}

    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    static func t(_ fr: String, _ locale: Locale = Locale(identifier: "fr_FR")) -> String {
        guard locale.language.languageCode?.identifier != "fr" else { return fr }
        return bundle(locale).localizedString(forKey: fr, value: fr, table: table)
    }

    static func f(_ fr: String, _ locale: Locale, _ args: CVarArg...) -> String {
        String(format: t(fr, locale), locale: locale, arguments: args)
    }

    static func autresPoissons(_ nombre: Int, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        f("Voir les %lld autres poissons du spot", locale, nombre)
    }

    static func origineEtSource(libelle: String, source: String, locale: Locale = Locale(identifier: "fr_FR")) -> String {
        f("%@ · source %@", locale, t(libelle, locale), source)
    }
}
