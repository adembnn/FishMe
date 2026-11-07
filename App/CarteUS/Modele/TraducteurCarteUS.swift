import Foundation

/// Traduit les textes de la carte américaine. La clé est le texte français ; la traduction est dans `AnglaisCarteUS.xcstrings`
/// (table « AnglaisCarteUS »). La langue suit la région de l'app (`Locale` de l'environnement), pas celle du téléphone : on lit le
/// dossier `.lproj` de la langue demandée, comme `TextesReglesUS`. En français, ou si la clé manque, le texte français est rendu.
nonisolated struct TraducteurCarteUS: Sendable, Equatable {
    static let table = "AnglaisCarteUS"
    let locale: Locale

    init(locale: Locale = Locale(identifier: "en_US")) { self.locale = locale }

    private final class Ancre {}

    private var bundle: Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    func callAsFunction(_ cle: String) -> String {
        bundle.localizedString(forKey: cle, value: cle, table: Self.table)
    }

    /// "Site de l'agence : X" / "Site de l'agence" : le préfixe est traduit, le nom de l'agence reste tel quel.
    func libelleLien(_ brut: String) -> String {
        let prefixe = "Site de l'agence : "
        if brut.hasPrefix(prefixe) { return self(prefixe) + brut.dropFirst(prefixe.count) }
        return self(brut)
    }

    /// Le message "sans données" : la phrase est traduite, le nom de l'État reste tel quel.
    func sansDonnees(_ brut: String) -> String {
        let debut = TextesCarteUS.sansDonneesDebut
        if brut == debut + ". Choisis ton État pour voir le site de son agence." { return self("sansDonnees.inconnu") }
        if brut.hasPrefix(debut + " : ") { return self(debut) + " : " + brut.dropFirst((debut + " : ").count) }
        return self(brut)
    }
}
