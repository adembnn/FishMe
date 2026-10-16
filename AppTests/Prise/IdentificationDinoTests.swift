import Testing
import UIKit
import Core
@testable import BuildChallenge

struct IdentificationDinoTests {
    /// Fait tourner le vrai modèle sur la photo d'exemple. Ignoré si le modèle ou l'image manque dans le bundle de test.
    @Test func photoExempleDonneUnResultat() async throws {
        let bundles = [Bundle.main, Bundle(for: Repere.self)]
        guard let modele = bundles.first(where: { $0.url(forResource: "PoissonsDino-int8", withExtension: "mlmodelc") != nil }),
              let url = bundles.compactMap({ $0.url(forResource: "photo-exemple", withExtension: "jpg") }).first,
              let data = try? Data(contentsOf: url) else { return }
        let resultat = await IdentificationDino(bundle: modele).identifier(photo: data)
        switch resultat {
        case .scores(let s):
            #expect(s.values.allSatisfy { $0 >= 0 && $0 <= 1.0001 })
            #expect(s.max(by: { $0.value < $1.value })?.key == "brochet", "la photo d'exemple montre un brochet")
        case .grille(let raison): #expect(raison != .aucunModele, "le modèle est présent")
        }
    }

    @Test func lesEtiquettesSontTraduites() throws {
        #expect(IdentificationDino.classe(deEtiquette: "truite-commune") == "truite_commune")
        #expect(IdentificationDino.classe(deEtiquette: "ombre") == "ombre_commun")
        #expect(IdentificationDino.classe(deEtiquette: "pas-un-poisson") == nil)
    }
}

private final class Repere {}
