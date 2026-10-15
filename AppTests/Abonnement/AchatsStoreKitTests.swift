#if canImport(StoreKitTest)
import Foundation
import StoreKit
import StoreKitTest
import Testing
import Core
@testable import BuildChallenge

/// Session de test StoreKit sur `TestConfig.storekit` (A l'ajoute aux ressources de la cible de tests).
/// NON COMPILÉ : les API de `SKTestSession` sont à vérifier sous Xcode (voir le rapport de L6).
@MainActor
struct AchatsStoreKitTests {
    private func session() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "TestConfig")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        return session
    }

    private func achats() -> AchatsStoreKit {
        AchatsStoreKit(reglages: UserDefaults(suiteName: "tests.achats.\(UUID().uuidString)")!)
    }

    @Test func sansAchatNonAbonne() async throws {
        _ = try session()
        #expect(await achats().etat() == .nonAbonne)
    }

    @Test func achatPuisAbonnementExpireSansAcces() async throws {
        let session = try session()
        let achats = achats()
        let apres = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
        #expect(apres.donneAcces)
        try session.expireSubscription(productIdentifier: IdentifiantsProduits.annuelFondateur)
        #expect(!(await achats.etat().donneAcces))
    }

    @Test func delaiDeGraceGardeLAcces() async throws {
        let session = try session()
        session.billingGracePeriodIsEnabled = true
        session.shouldEnterBillingRetryOnRenewal = true
        let achats = achats()
        _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
        try session.forceRenewalOfSubscription(productIdentifier: IdentifiantsProduits.annuelFondateur)
        let etat = await achats.etat()
        guard case .delaiDeGrace = etat else { Issue.record("attendu : délai de grâce, reçu \(etat)"); return }
        #expect(etat.donneAcces)
    }

    @Test func remboursementRetireLAcces() async throws {
        let session = try session()
        let achats = achats()
        _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
        let transaction = try #require(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        #expect(!(await achats.etat().donneAcces))
    }

    @Test func restaurerRendLAbonnement() async throws {
        _ = try session()
        let achats = achats()
        _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
        #expect(await achats.restaurer().donneAcces)
    }

    @Test func modeAvionLeDernierEtatVerifieSert() async throws {
        let session = try session()
        let achats = achats()
        _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
        #expect(await achats.etat().donneAcces)
    }
}
#endif
