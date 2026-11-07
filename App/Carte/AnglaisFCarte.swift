import Foundation

/// Traduction des textes de App/Carte/ que la région US peut voir (lot US13f) : la feuille « Y aller avec », le réglage de navigation,
/// l'invitation Pro et l'écran « Ta zone ». Même modèle que AnglaisE : table dédiée AnglaisFCarte, clé = le texte français,
/// langue prise dans le dossier .lproj de la langue de la région. En français, le texte revient tel quel.
/// La carte de France (VueCarte.corpsFrance et ses fiches) n'est jamais affichée en région US : elle reste en français.
nonisolated enum AnglaisFCarte {
    static let table = "AnglaisFCarte"

    private final class Ancre {}

    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    static func t(_ fr: String, _ locale: Locale) -> String {
        guard locale.language.languageCode?.identifier != "fr" else { return fr }
        return bundle(locale).localizedString(forKey: fr, value: fr, table: table)
    }

    static func f(_ fr: String, _ locale: Locale, _ args: CVarArg...) -> String {
        String(format: t(fr, locale), arguments: args)
    }
}
