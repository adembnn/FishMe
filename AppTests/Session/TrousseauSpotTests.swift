import Foundation
import Security
import Testing
import Core
@testable import BuildChallenge

/// B11 : le spot gratuit va dans le trousseau d'iOS (`TrousseauSpotGratuit`). Dans une app non signée
/// (`CODE_SIGNING_ALLOWED=NO`), le simulateur refuse le trousseau (-34018, droit manquant) : les tests sont alors IGNORÉS (pas rouges),
/// avec le code reçu dans leur raison. Dans l'app, l'écriture échoue en silence dans ce cas : voir `TrousseauSpotGratuit`.
@Suite(.serialized) @MainActor
struct TrousseauSpotTests {
    /// Le code rendu par une écriture d'essai (même requête que `TrousseauSpotGratuit.ecrire`), lu une fois.
    nonisolated static let statut: OSStatus = {
        let requete: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                      kSecAttrService as String: "fr.fishme.session.test",
                                      kSecAttrAccount as String: "spot-test-\(UUID().uuidString)",
                                      kSecValueData as String: Data("x".utf8),
                                      kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let code = SecItemAdd(requete as CFDictionary, nil)
        SecItemDelete(requete as CFDictionary)
        return code
    }()

    nonisolated static var trousseauDisponible: Bool { statut == errSecSuccess }

    private let spot = Spot(centre: Coordonnee(latitude: 48.8217, longitude: 2.4119), rayonM: 1000, departement: Departement(code: "94"))

    @Test(.enabled(if: TrousseauSpotTests.trousseauDisponible,
                   "Trousseau refusé dans cet environnement : SecItemAdd a rendu \(TrousseauSpotTests.statut) (-34018 : build non signé)"))
    func leTrousseauAccepteUneEcriture() {
        #expect(Self.statut == errSecSuccess)
    }

    @Test(.enabled(if: TrousseauSpotTests.trousseauDisponible,
                   "Trousseau refusé dans cet environnement : SecItemAdd a rendu \(TrousseauSpotTests.statut) (-34018 : build non signé)"))
    func leSpotEcritEstRelu() {
        let coffre = TrousseauSpotGratuit()
        coffre.ecrire(spot)
        #expect(coffre.lire() == spot)
    }
}
