import Foundation
import Testing
@testable import BuildChallenge

/// B7 : le message de la météo dit la vraie cause : autorisation refusée, pas de réseau ou pas de donnée.
struct CauseMeteoTests {
    @Test func autorisationRefusee() {
        #expect(CauseMeteo.depuis(ErreurConditions.autorisation) == .autorisation)
        let jwt = NSError(domain: "WeatherDaemon.WDSJWTAuthenticatorServiceListener.Errors", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to generate jwt token"])
        #expect(CauseMeteo.depuis(jwt) == .autorisation)
    }

    @Test func pasDeReseau() {
        #expect(CauseMeteo.depuis(URLError(.notConnectedToInternet)) == .reseau)
    }

    @Test func pasDeDonnee() {
        #expect(CauseMeteo.depuis(ErreurConditions.indisponible) == .aucuneDonnee)
    }

    @Test func autreCauseNAccuseNiLaConnexionNiLAutorisation() {
        let cause = CauseMeteo.depuis(NSError(domain: "x", code: 1))
        #expect(cause == .autre)
        #expect(!cause.consigne.contains("connexion"))
    }

    @Test func troisMessagesDistincts() {
        let textes = Set([CauseMeteo.autorisation, .reseau, .aucuneDonnee].map(\.consigne))
        #expect(textes.count == 3)
        #expect(CauseMeteo.reseau.consigne.contains("connexion"))
        #expect(!CauseMeteo.autorisation.consigne.contains("connexion"))
        #expect(!CauseMeteo.aucuneDonnee.consigne.contains("connexion"))
    }
}
