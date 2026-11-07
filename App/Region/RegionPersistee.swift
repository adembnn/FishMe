import Core
import Foundation

/// La région active, lisible depuis n'importe quel fil (formats de dates et de nombres, sources de données).
///
/// Elle relit les deux valeurs que `RegionCourante` écrit dans `UserDefaults` (choix du pêcheur, région déduite de la dernière
/// position) et applique la même règle : choix explicite, sinon région déduite, sinon France. Aucune coordonnée n'est lue ici.
nonisolated enum RegionPersistee {
    static let cleChoix = "region.choix"
    static let cleDeduite = "region.deduite"

    static func lire(_ reglages: UserDefaults = .standard) -> RegionApp {
        switch reglages.string(forKey: cleChoix) {
        case "france": return .france
        case "etatsUnis": return .etatsUnis
        default: break
        }
        // Hôte des tests unitaires : la position du simulateur (Cupertino) ne doit pas faire passer les tests en région US.
        if reglages === UserDefaults.standard, ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return .france }
        return reglages.string(forKey: cleDeduite).flatMap(RegionApp.init(rawValue:)) ?? .france
    }
}
