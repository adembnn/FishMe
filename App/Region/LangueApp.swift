import Core
import Foundation

/// La langue de l'app : un choix du pêcheur, indépendant de la région (règles, unités, formats de dates).
/// Un Français aux États-Unis garde le français ; un Américain dont le téléphone est en français peut choisir English.
/// Mémorisée dans `UserDefaults` (`langue.choix`), modifiable dans Réglages. Sans choix : l'anglais.
nonisolated enum LangueApp: String, CaseIterable, Sendable, Identifiable {
    case francais = "fr"
    case anglais = "en"

    var id: String { rawValue }

    static let cle = "langue.choix"

    var locale: Locale { Locale(identifier: self == .francais ? "fr_FR" : "en_US") }

    /// Le nom de la langue, écrit dans sa propre langue (jamais traduit).
    var nomPropre: String { self == .francais ? "Français" : "English" }

    var codeNoms: LangueNomsCode { self == .francais ? .fr : .en }

    /// Les choix du premier écran : English d'abord (langue par défaut), puis Français.
    static let ordre: [LangueApp] = [.anglais, .francais]

    /// La langue tant que le pêcheur n'a rien choisi : l'anglais, quelle que soit la langue du téléphone ou la région (8 nov.).
    static let parDefaut: LangueApp = .anglais

    /// La langue des textes pour une région donnée : le choix du pêcheur, sinon l'anglais (la région n'y change rien).
    /// Dans l'hôte des tests unitaires, la langue d'avant (celle de la région) reste, pour ne pas changer les tests existants.
    static func pour(region: RegionApp) -> LangueApp {
        if RegionPersistee.estHoteDeTests { return deLaRegion(region) }
        return LanguePersistee.choix() ?? parDefaut
    }

    /// Ancienne règle (décision 7 du 7 nov.), gardée pour l'hôte des tests unitaires seulement.
    static func deLaRegion(_ region: RegionApp) -> LangueApp { region == .etatsUnis ? .anglais : .francais }
}

/// La langue active, lisible depuis n'importe quel fil. Sans choix du pêcheur : l'anglais.
nonisolated enum LanguePersistee {
    /// Le choix explicite, ou `nil`.
    static func choix(_ reglages: UserDefaults = .standard) -> LangueApp? {
        reglages.string(forKey: LangueApp.cle).flatMap(LangueApp.init(rawValue:))
    }

    static func lire(_ reglages: UserDefaults = .standard) -> LangueApp {
        // Hôte des tests unitaires : même garde que `RegionPersistee` (un choix laissé dans le simulateur ne change pas les tests).
        if reglages === UserDefaults.standard, RegionPersistee.estHoteDeTests { return .francais }
        return choix(reglages) ?? LangueApp.parDefaut
    }
}
