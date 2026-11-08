import Foundation

/// Les textes du bloc de règles (L19) en français avec leur équivalent anglais.
/// La clé est le texte français ; les traductions sont dans `BlocRegles.xcstrings` (table « BlocRegles », comme `TextesReglesUS`).
/// La langue suit la région de l'app (`Locale` de l'environnement), pas celle du téléphone : on cherche le dossier `.lproj` demandé.
/// Le français est la langue de base : sans `.lproj` trouvé, la clé (le texte français) s'affiche telle quelle.
/// Les phrases qui viennent de `Core` (lignes, consignes, titres de source) ne passent pas ici.
nonisolated struct TextesBlocRegles: Sendable, Equatable {
    static let table = "BlocRegles"

    let locale: Locale

    init(locale: Locale = Locale(identifier: "fr_FR")) { self.locale = locale }

    private final class Ancre {}

    private var bundle: Bundle {
        let base = Bundle(for: Ancre.self)
        guard let code = locale.language.languageCode?.identifier,
              let chemin = base.path(forResource: code, ofType: "lproj"),
              let langue = Bundle(path: chemin) else { return base }
        return langue
    }

    // MARK: Titres

    var titreRelacher: String { String(localized: "Il faut relâcher le poisson", table: Self.table, bundle: bundle) }
    var titreReglementation: String {
        String(localized: "Voir la réglementation en vigueur sur ce poisson", table: Self.table, bundle: bundle)
    }
    var raisonEspeceNonConfirmee: String { String(localized: "Espèce non confirmée", table: Self.table, bundle: bundle) }
    var categorieInconnue: String {
        String(localized: "Catégorie du cours d'eau inconnue : vérifie l'arrêté", table: Self.table, bundle: bundle)
    }
    var aucuneLigne: String {
        String(localized: "Aucune ligne de règle n'est disponible ici : lis l'arrêté préfectoral.", table: Self.table, bundle: bundle)
    }
    var mentionFoi: String {
        String(localized: "Les textes lus font foi : l'arrêté préfectoral et le Code de l'environnement.", table: Self.table, bundle: bundle)
    }

    // MARK: Groupes

    var garderOuRelacher: String { String(localized: "Garder ou relâcher", table: Self.table, bundle: bundle) }
    var horaires: String { String(localized: "Horaires", table: Self.table, bundle: bundle) }
    var materielEtPratique: String { String(localized: "Matériel et pratique", table: Self.table, bundle: bundle) }

    // MARK: Lignes

    var regleLue: String { String(localized: "règle lue", table: Self.table, bundle: bundle) }
    var nonRespectee: String { String(localized: "non respectée", table: Self.table, bundle: bundle) }
    var verifieSurPlace: String { String(localized: "vérifie sur place", table: Self.table, bundle: bundle) }

    /// Le mot d'état commençant par une majuscule (« Vérifie sur place »), sous le titre fermé. Même clé que la ligne : pas de doublon de casse.
    var verifieSurPlaceTitre: String {
        let mot = verifieSurPlace
        return mot.prefix(1).uppercased(with: locale) + mot.dropFirst()
    }

    func premiereCategorie(_ valeur: String) -> String { String(localized: "1re : \(valeur)", table: Self.table, bundle: bundle) }
    func deuxiemeCategorie(_ valeur: String) -> String { String(localized: "2e : \(valeur)", table: Self.table, bundle: bundle) }

    var masquerSource: String { String(localized: "Masquer la source", table: Self.table, bundle: bundle) }
    var voirSource: String { String(localized: "Voir la source", table: Self.table, bundle: bundle) }
    var sourceVoirArrete: String {
        String(localized: "Source : voir l'arrêté préfectoral.", table: Self.table, bundle: bundle)
    }

    /// « Lue le 3 novembre 2026 » / « Read on November 3, 2026 » : format de date de la locale, année sans séparateur de milliers.
    func lueLe(_ date: Date) -> String {
        let jour = date.formatted(.dateTime.day().month(.wide).year().locale(locale))
        return String(localized: "Lue le \(jour)", table: Self.table, bundle: bundle)
    }
}
