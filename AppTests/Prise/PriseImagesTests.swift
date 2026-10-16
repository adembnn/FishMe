import Testing
import UIKit
import Core
@testable import BuildChallenge

@MainActor
struct PriseImagesTests {
    /// Compte les illustrations absentes de `App/Assets.xcassets/` et les nomme, sur la vraie liste des espèces de `Core`
    /// (les faux de C0 portent des noms d'images d'essai, « perche », « anguille », qui n'existent pas).
    @Test func toutesLesEspecesOntUneImage() {
        let especes = MoteurCore(donnees: .embarque(dossierFabriques: Bundle.main.resourceURL)).especes
        let manquantes = especes.especesPechables().map { $0.image }.filter { UIImage(named: $0) == nil }
        #expect(manquantes.isEmpty, "Images manquantes : \(manquantes.joined(separator: ", "))")
    }
}
