import Core
import Foundation
import SwiftUI

/// Les textes affichés de App/Collection/ et App/Prise/ (lot US13d), en français avec leur équivalent anglais.
/// Même modèle que TextesReglesUS : la clé est le texte français, les traductions sont dans AnglaisD.xcstrings
/// (table « AnglaisD », jamais un second Localizable.xcstrings), et la langue suit la région de l'app (Locale de l'environnement),
/// pas celle du téléphone : on cherche donc le dossier .lproj de la langue demandée. En français la clé est affichée telle quelle.
///
/// Usage dans une vue : @Environment(\.locale) private var locale puis AnglaisD(locale)("Fermer") ou, avec des valeurs,
/// AnglaisD(locale)("Taille : %@", valeur) (spécificateurs %@, %lld, %.1f ; %1$@ si l'ordre change en anglais).
/// Aucun texte ne dit qu'une prise est permise.
nonisolated struct AnglaisD: Sendable, Equatable {
    static let table = "AnglaisD"

    let locale: Locale

    init(_ locale: Locale = Locale(identifier: "fr_FR")) { self.locale = locale }

    private final class Ancre {}

    private var bundle: Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    /// Vrai pour l'anglais (pouces et livres aux États-Unis).
    var estAnglais: Bool { locale.language.languageCode?.identifier == "en" }

    /// La région d'affichage déduite de la langue (anglais : États-Unis, sinon France).
    var region: RegionApp { estAnglais ? .etatsUnis : .france }

    var format: FormatRegion { FormatRegion(region: region) }

    /// Le texte traduit pour cle, sans valeur.
    func callAsFunction(_ cle: String) -> String {
        bundle.localizedString(forKey: cle, value: cle, table: Self.table)
    }

    /// Le texte traduit pour cle (un format), rempli avec valeurs.
    func callAsFunction(_ cle: String, _ valeurs: CVarArg...) -> String {
        String(format: bundle.localizedString(forKey: cle, value: cle, table: Self.table), locale: locale, arguments: valeurs)
    }
}
