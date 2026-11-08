import Core
import Foundation

/// La région active, lisible depuis n'importe quel fil (formats de dates et de nombres, sources de données).
///
/// Elle relit les deux valeurs que `RegionCourante` écrit dans `UserDefaults` (choix du pêcheur, région déduite de la dernière
/// position) et applique la même règle : choix explicite, sinon région déduite, sinon France. Aucune coordonnée n'est lue ici.
nonisolated enum RegionPersistee {
    static let cleChoix = "region.choix"
    static let cleDeduite = "region.deduite"

    /// Vrai quand l'app sert d'hôte aux tests unitaires (XCTest ou Swift Testing chargé dans le processus).
    static let estHoteDeTests: Bool = hoteDeTests

    private static let hoteDeTests: Bool = {
        let env = ProcessInfo.processInfo.environment
        return Bundle.allBundles.contains { $0.bundlePath.hasSuffix(".xctest") } || Bundle.main.bundlePath.contains(".xctest") || NSClassFromString("XCTestCase") != nil || env["XCTestConfigurationFilePath"] != nil || env["XCTestBundlePath"] != nil
    }()

    static func lire(_ reglages: UserDefaults = .standard) -> RegionApp {
        // Hôte des tests unitaires : les réglages du simulateur (choix ou position de Cupertino laissés par une autre exécution)
        // ne doivent pas faire passer les tests en région US. Les tests de région utilisent leur propre `UserDefaults`.
        if reglages === UserDefaults.standard, Self.hoteDeTests { return .france }
        switch reglages.string(forKey: cleChoix) {
        case "france": return .france
        case "etatsUnis": return .etatsUnis
        default: break
        }
        return reglages.string(forKey: cleDeduite).flatMap(RegionApp.init(rawValue:)) ?? .france
    }
}
