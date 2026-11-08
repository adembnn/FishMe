import Foundation

/// Les textes de la racine (onglets, profil, messages) en français avec leur équivalent anglais (région US).
/// Clé = texte français ; traductions dans `RootTextes.xcstrings` (table « RootTextes »). La langue suit la région de l'app
/// (`Locale` de l'environnement), pas celle du téléphone : on cherche donc le dossier `.lproj` de la langue demandée.
nonisolated struct RootTextes: Sendable, Equatable {
    static let table = "RootTextes"

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

    var decors: String { String(localized: "Décors", table: Self.table, bundle: bundle) }
    var messages: String { String(localized: "Messages", table: Self.table, bundle: bundle) }
    var messagesNouveaux: String { String(localized: "Messages, nouveaux messages", table: Self.table, bundle: bundle) }
    var pescedexIndisponible: String {
        String(localized: "Tes cartes ne peuvent pas s'ouvrir pour l'instant.", table: Self.table, bundle: bundle)
    }
    var monProfilPublic: String { String(localized: "Mon profil public", table: Self.table, bundle: bundle) }
    var finisTonProfil: String { String(localized: "Finis ton profil", table: Self.table, bundle: bundle) }
    var surnomSeulNom: String {
        String(localized: "Ton surnom est le seul nom que les autres voient.", table: Self.table, bundle: bundle)
    }
    var mesRecords: String { String(localized: "Mes records", table: Self.table, bundle: bundle) }
    var mesReperes: String { String(localized: "Mes repères", table: Self.table, bundle: bundle) }
    var mesStatistiques: String { String(localized: "Mes statistiques", table: Self.table, bundle: bundle) }
    var mesSorties: String { String(localized: "Mes sorties", table: Self.table, bundle: bundle) }
    var reglages: String { String(localized: "Réglages", table: Self.table, bundle: bundle) }
    var maPecheSecuriteSources: String {
        String(localized: "Ma pêche, sécurité et sources", table: Self.table, bundle: bundle)
    }
    var monProfil: String { String(localized: "Mon profil", table: Self.table, bundle: bundle) }
    var fermer: String { String(localized: "Fermer", table: Self.table, bundle: bundle) }
    var pecheur: String { String(localized: "Pêcheur", table: Self.table, bundle: bundle) }

    /// « Débutant · 12 cartes » / « Beginner · 12 cards ».
    func niveauEtCartes(_ titre: String, _ nombre: Int) -> String {
        String(localized: "\(titre) · \(nombre) cartes", table: Self.table, bundle: bundle)
    }

    func departement(_ code: String) -> String {
        String(localized: "Département \(code)", table: Self.table, bundle: bundle)
    }
}
