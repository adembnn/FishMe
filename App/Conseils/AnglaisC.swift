import SwiftUI

/// Anglais des écrans Conseils, Communauté et Repères (lot US13c). Table « AnglaisC » (`AnglaisC.xcstrings`) :
/// la clé est le texte français, la valeur `en` l'anglais. La langue suit la région de l'app (`Locale` de l'environnement),
/// pas celle du téléphone : on cherche le dossier `.lproj` de la langue demandée, comme `TextesReglesUS`.
/// En français la clé revient telle quelle (rien ne change).
nonisolated enum AnglaisC {
    static let table = "AnglaisC"

    private final class Ancre {}

    /// Le paquet de la langue de `locale` (le paquet de l'app si cette langue n'a pas de dossier).
    static func bundle(_ locale: Locale) -> Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    /// Le texte de la clé française dans la langue de `locale`.
    static func texte(_ cle: String, _ locale: Locale) -> String {
        bundle(locale).localizedString(forKey: cle, value: cle, table: table)
    }

    /// Une clé avec des trous (`%@`, `%lld`) remplis par `args`, dans la langue de `locale`.
    static func texte(_ cle: String, _ locale: Locale, _ args: CVarArg...) -> String {
        String(format: texte(cle, locale), arguments: args)
    }
}

extension Text {
    /// Un texte affiché passant par la table du lot ; la langue vient de `\.locale` de l'environnement (région de l'app).
    /// - Parameter cle: le texte français (la clé de la table).
    init(c cle: String) {
        self.init(LocalizedStringKey(cle), tableName: AnglaisC.table)
    }
}
