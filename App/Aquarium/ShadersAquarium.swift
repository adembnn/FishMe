import Metal
import SwiftUI

/// Les fonctions Metal de l'aquarium sont-elles là ? Sinon (bibliothèque absente, fonction qui ne se charge pas sur cet iPhone),
/// l'aquarium montre les illustrations fixes, sans plantage.
enum ShadersAquarium {
    static let fonctions = ["aquarium_ondeNage", "aquarium_irise"]

    static let disponibles: Bool = {
        guard let appareil = MTLCreateSystemDefaultDevice(),
              let bibliotheque = try? appareil.makeDefaultLibrary(bundle: bundleDesShaders) else { return false }
        return fonctions.allSatisfy { bibliotheque.functionNames.contains($0) }
    }()

    static let bundleDesShaders = Bundle.main
    static var bibliotheque: ShaderLibrary { ShaderLibrary.default }
}
