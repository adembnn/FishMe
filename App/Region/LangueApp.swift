import Core
import Foundation

/// La langue de l'app : un choix du pêcheur, indépendant de la région (règles, unités, formats de dates).
/// Un Français aux États-Unis garde le français ; un Américain dont le téléphone est en français peut choisir English.
/// Mémorisée dans `UserDefaults` (`langue.choix`), modifiable dans Réglages.
nonisolated enum LangueApp: String, CaseIterable, Sendable, Identifiable {
    case francais = "fr"
    case anglais = "en"

    var id: String { rawValue }

    static let cle = "langue.choix"

    var locale: Locale { Locale(identifier: self == .francais ? "fr_FR" : "en_US") }

    /// Le nom de la langue, écrit dans sa propre langue (jamais traduit).
    var nomPropre: String { self == .francais ? "Français" : "English" }

    var codeNoms: LangueNomsCode { self == .francais ? .fr : .en }

    /// La langue du téléphone : français si sa première langue préférée est le français, sinon anglais.
    static func duTelephone(_ preferees: [String] = Locale.preferredLanguages) -> LangueApp {
        preferees.first.map { $0.lowercased().hasPrefix("fr") } == true ? .francais : .anglais
    }

    /// La langue des textes pour une région donnée : le choix du pêcheur s'il existe, sinon celle de la région.
    /// Dans l'hôte des tests unitaires, seule la région compte (un choix laissé dans le simulateur ne change rien).
    static func pour(region: RegionApp) -> LangueApp {
        if RegionPersistee.estHoteDeTests { return deLaRegion(region) }
        return LanguePersistee.choix() ?? deLaRegion(region)
    }

    /// La langue d'avant ce choix : celle de la région (décision 7 du 7 nov.). Sert tant que le pêcheur n'a rien choisi.
    static func deLaRegion(_ region: RegionApp) -> LangueApp { region == .etatsUnis ? .anglais : .francais }
}

/// La langue active, lisible depuis n'importe quel fil. Sans choix du pêcheur : la langue de la région (comportement d'avant).
nonisolated enum LanguePersistee {
    /// Le choix explicite, ou `nil`.
    static func choix(_ reglages: UserDefaults = .standard) -> LangueApp? {
        reglages.string(forKey: LangueApp.cle).flatMap(LangueApp.init(rawValue:))
    }

    static func lire(_ reglages: UserDefaults = .standard) -> LangueApp {
        // Hôte des tests unitaires : même garde que `RegionPersistee` (un choix laissé dans le simulateur ne change pas les tests).
        if reglages === UserDefaults.standard, RegionPersistee.estHoteDeTests { return .francais }
        return choix(reglages) ?? LangueApp.deLaRegion(RegionPersistee.lire(reglages))
    }
}
