import Testing
import UIKit
import Core
@testable import BuildChallenge

struct PriseImagesTests {
    /// Compte les illustrations absentes de `App/Assets.xcassets/` et les nomme. Avec les faux de C0 il en manque : le vrai `Core` (L1, D1) et les images de D1 le font passer.
    @Test func toutesLesEspecesOntUneImage() {
        let manquantes = EspecesFaux().especesPechables().map { $0.image }.filter { UIImage(named: $0) == nil }
        #expect(manquantes.isEmpty, "Images manquantes : \(manquantes.joined(separator: ", "))")
    }
}
