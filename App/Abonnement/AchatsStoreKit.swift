import Foundation
import Core
import StoreKit

/// Le contrat `Achats` de Core, rempli avec StoreKit 2.
/// Règles : seules les transactions vérifiées comptent ; l'état se lit dans `Transaction.currentEntitlements` puis dans le statut de l'abonnement
/// (délai de grâce, relance de paiement, remboursement) ; `Transaction.updates` est écouté dès `demarrerEcoute()` ;
/// sans réseau, le dernier état vérifié sert.
nonisolated final class AchatsStoreKit: Achats, @unchecked Sendable {
    typealias SurAchat = @Sendable (Product.PurchaseResult) async -> Void
    typealias SurTransactions = @Sendable ([VerificationResult<Transaction>]) async -> Void

    private let verrou = NSLock()
    private var abonnes: [UUID: AsyncStream<EtatAchats>.Continuation] = [:]
    private var ecoute: Task<Void, Never>?

    private let reglages: UserDefaults
    private let cleDernierAcces = "achats.dernierEtatDonneAcces"
    private let identifiants: Set<String>
    private let horloge: @Sendable () -> Date
    private let surAchat: SurAchat
    private let surTransactions: SurTransactions

    /// `surAchat` et `surTransactions` : A y branche `CoucheMesure.enregistrerAchat` et `enregistrerTransactions` (qui ne font rien sans l'accord).
    init(identifiants: Set<String> = IdentifiantsProduits.tousLesAbonnements,
         reglages: UserDefaults = .standard,
         horloge: @escaping @Sendable () -> Date = { Date() },
         surAchat: @escaping SurAchat = { _ in },
         surTransactions: @escaping SurTransactions = { _ in }) {
        self.identifiants = identifiants
        self.reglages = reglages
        self.horloge = horloge
        self.surAchat = surAchat
        self.surTransactions = surTransactions
    }

    deinit { ecoute?.cancel() }

    // MARK: Contrat Achats

    func etat() async -> EtatAchats {
        let etat = await lireEtat()
        reglages.set(etat.donneAcces, forKey: cleDernierAcces)
        return etat
    }

    func modifications() -> AsyncStream<EtatAchats> {
        AsyncStream { continuation in
            let id = UUID()
            verrou.withLock { abonnes[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.verrou.withLock { self.abonnes[id] = nil }
            }
        }
    }

    func acheter(produit: String) async -> EtatAchats {
        do {
            if let produitStore = try await Product.products(for: [produit]).first {
                let resultat = try await produitStore.purchase()
                await surAchat(resultat)
                if case .success(.verified(let transaction)) = resultat { await transaction.finish() }
            }
        } catch {
            // Achat impossible ou annulé : on rend l'état tel qu'il est, le paywall affiche son message.
        }
        return await rafraichir()
    }

    func restaurer() async -> EtatAchats {
        try? await AppStore.sync()
        return await rafraichir()
    }

    // MARK: Écoute

    /// À appeler une fois, dès le lancement (`BuildChallengeApp.swift`).
    func demarrerEcoute() {
        verrou.withLock {
            guard ecoute == nil else { return }
            ecoute = Task.detached { [weak self] in
                for await resultat in Transaction.updates {
                    await self?.traiter(resultat)
                }
            }
        }
    }

    /// Arrête l'écoute de `Transaction.updates` (fin d'app ou de test) ; `demarrerEcoute()` peut ensuite repartir.
    func arreterEcoute() {
        let tache = verrou.withLock { () -> Task<Void, Never>? in
            defer { ecoute = nil }
            return ecoute
        }
        tache?.cancel()
    }

    private func traiter(_ resultat: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = resultat else { return }
        await transaction.finish()
        await surTransactions([resultat])
        _ = await rafraichir()
    }

    private func rafraichir() async -> EtatAchats {
        let nouvel = await etat()
        let copies = verrou.withLock { Array(abonnes.values) }
        for continuation in copies { continuation.yield(nouvel) }
        return nouvel
    }

    // MARK: Lecture StoreKit

    private func lireEtat() async -> EtatAchats {
        let maintenant = horloge()
        var droits: [StatutAbonnement] = []
        var produitsAvecDroit: Set<String> = []
        for await resultat in Transaction.currentEntitlements {
            guard case .verified(let transaction) = resultat, identifiants.contains(transaction.productID) else { continue }
            if transaction.revocationDate != nil {
                droits.append(Self.statutRevoque(transaction))
            } else if transaction.expirationDate.map({ $0 > maintenant }) ?? true {
                droits.append(.abonne)
                produitsAvecDroit.insert(transaction.productID)
            }
        }

        do {
            let statuts = try await statutsAbonnement(droitsActifs: produitsAvecDroit, maintenant: maintenant)
            if !statuts.isEmpty { return ResolveurEtat.etat(statuts: statuts, maintenant: maintenant) }
            return ResolveurEtat.etat(statuts: droits, maintenant: maintenant)
        } catch {
            // Pas de réseau pour les statuts : un droit vérifié sur l'appareil suffit, sinon le dernier état vérifié sert.
            if !droits.isEmpty { return ResolveurEtat.etat(statuts: droits, maintenant: maintenant) }
            if reglages.bool(forKey: cleDernierAcces) { return ResolveurEtat.sansReseau(dernierEtat: .abonne) }
            return .nonAbonne
        }
    }

    private func statutsAbonnement(droitsActifs: Set<String>, maintenant: Date) async throws -> [StatutAbonnement] {
        let produits = try await Product.products(for: identifiants)
        var statuts: [StatutAbonnement] = []
        for produit in produits {
            guard let statutsProduit = try await produit.subscription?.status else { continue }
            for statut in statutsProduit {
                guard case .verified(let transaction) = statut.transaction else { continue }
                switch statut.state {
                case .subscribed:
                    // StoreKit peut garder « abonné » en cache après l'expiration : la date de fin, la révocation
                    // et la liste des droits en cours (`currentEntitlements`) font foi.
                    let echu = transaction.expirationDate.map { $0 <= maintenant } ?? false
                    if transaction.revocationDate != nil {
                        statuts.append(Self.statutRevoque(transaction))
                    } else if echu || !droitsActifs.contains(transaction.productID) {
                        statuts.append(.expire)
                    } else {
                        statuts.append(.abonne)
                    }
                case .inGracePeriod:
                    var fin: Date?
                    if case .verified(let renouvellement) = statut.renewalInfo { fin = renouvellement.gracePeriodExpirationDate }
                    statuts.append(.delaiDeGrace(fin: fin))
                case .inBillingRetryPeriod:
                    statuts.append(.relancePaiement)
                case .expired:
                    statuts.append(.expire)
                case .revoked:
                    statuts.append(Self.statutRevoque(transaction))
                default:
                    statuts.append(.expire)
                }
            }
        }
        return statuts
    }

    /// Partage familial arrêté : révoqué ; sinon : remboursé.
    private static func statutRevoque(_ transaction: Transaction) -> StatutAbonnement {
        transaction.ownershipType == .familyShared ? .revoque : .rembourse
    }
}
