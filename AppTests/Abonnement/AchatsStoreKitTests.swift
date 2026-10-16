#if canImport(StoreKitTest)
import Foundation
import StoreKit
import StoreKitTest
import Testing
import Core
@testable import BuildChallenge

/// Session de test StoreKit sur `TestConfig.storekit` (A l'ajoute aux ressources de la cible de tests).
/// NON COMPILÉ : les API de `SKTestSession` sont à vérifier sous Xcode (voir le rapport de L6).
/// `.serialized` est indispensable : Swift Testing lance les tests en parallèle, or le démon StoreKit de test est unique
/// pour tout le processus. Un test qui achète (ou qui fait `clearTransactions`/`resetToDefaultState`) change les droits d'un autre :
/// l'abonnement « expiré » voyait l'achat d'un voisin et gardait l'accès pendant tout le sondage.
@Suite(.serialized) @MainActor
struct AchatsStoreKitTests {
    /// Chaque test passe par ici : la session est vidée en sortie, sinon le processus de test ne se termine pas.
    private func avecSession(_ corps: (SKTestSession, AchatsStoreKit) async throws -> Void) async throws {
        let session = try session()
        // Une erreur simulée (mode avion) d'un test précédent resterait sur le démon partagé.
        try? await session.setSimulatedError(nil, forAPI: .loadProducts)
        let achats = achats()
        do {
            try await corps(session, achats)
        } catch {
            achats.arreterEcoute()
            session.clearTransactions()
            session.resetToDefaultState()
            throw error
        }
        achats.arreterEcoute()
        session.clearTransactions()
        session.resetToDefaultState()
    }

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
        try await avecSession { _, achats in
            #expect(await achats.etat() == .nonAbonne)
        }
    }

    @Test func achatPuisAbonnementExpireSansAcces() async throws {
        try await avecSession { session, achats in
            let apres = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
            #expect(apres.donneAcces)
            try session.expireSubscription(productIdentifier: IdentifiantsProduits.annuelFondateur)
            // StoreKit propage l'expiration de façon asynchrone : on sonde jusqu'à 10 s au lieu de lire une seule fois.
            var acces = await achats.etat().donneAcces
            for _ in 0..<40 where acces {
                try await Task.sleep(for: .milliseconds(250))
                acces = await achats.etat().donneAcces
            }
            #expect(!acces)
        }
    }

    @Test func delaiDeGraceGardeLAcces() async throws {
        try await avecSession { session, achats in
            session.billingGracePeriodIsEnabled = true
            session.shouldEnterBillingRetryOnRenewal = true
            _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
            try session.forceRenewalOfSubscription(productIdentifier: IdentifiantsProduits.annuelFondateur)
            // Comme l'expiration, le passage en délai de grâce arrive de façon asynchrone : on sonde jusqu'à 10 s.
            var etat = await achats.etat()
            for _ in 0..<40 {
                if case .delaiDeGrace = etat { break }
                try await Task.sleep(for: .milliseconds(250))
                etat = await achats.etat()
            }
            guard case .delaiDeGrace = etat else { Issue.record("attendu : délai de grâce, reçu \(etat)"); return }
            #expect(etat.donneAcces)
        }
    }

    @Test func remboursementRetireLAcces() async throws {
        try await avecSession { session, achats in
            _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
            let transaction = try #require(session.allTransactions().first)
            try session.refundTransaction(identifier: transaction.identifier)
            #expect(!(await achats.etat().donneAcces))
        }
    }

    @Test func restaurerRendLAbonnement() async throws {
        try await avecSession { _, achats in
            _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
            #expect(await achats.restaurer().donneAcces)
        }
    }

    @Test func modeAvionLeDernierEtatVerifieSert() async throws {
        try await avecSession { session, achats in
            _ = await achats.acheter(produit: IdentifiantsProduits.annuelFondateur)
            try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .loadProducts)
            #expect(await achats.etat().donneAcces)
        }
    }
}
#endif
