// NON COMPILÉ : écrit sans compilateur Swift. Stub : signatures seulement.
import Foundation
import PecheCore
#if canImport(StoreKit)
import StoreKit
#endif

/// Identifiants de produits (doivent correspondre à Pecheur.storekit et à App Store Connect).
public enum StoreProductID {
    public static let group = "pecheur_plus"            // groupe d'abonnement « Pêcheur+ »
    public static let annual = "fr.REMPLACER.bredouille.pro.annual"
    public static let monthly = "fr.REMPLACER.bredouille.pro.monthly"
    public static let all = [annual, monthly]
}

/// Accès StoreKit 2 : lecture du droit courant et achat. Le paywall ne bloque jamais la capture.
/// Le Core ne connaît que `Entitlements` ; la traduction se fait ici.
public protocol StoreServicing: Sendable {
    /// Droit courant, déduit des transactions vérifiées (hors ligne : dernier état connu).
    func currentEntitlements() async -> Entitlements
    /// Lance l'achat d'un produit. TODO(Adem) : Product.purchase(), vérification, finish().
    func purchase(productID: String) async throws
    /// Restaurer les achats (obligatoire côté App Store) : AppStore.sync().
    func restore() async throws
}

/// Implémentation réelle (StoreKit 2). Disponible iOS 26+.
@available(iOS 26.0, macOS 26.0, *)
public struct StoreService: StoreServicing {
    public init() {}

    public func currentEntitlements() async -> Entitlements {
        // TODO(Adem) : parcourir Transaction.currentEntitlements, plan .pro si abonnement actif.
        return Entitlements(plan: .free, limits: .default)
    }

    public func purchase(productID: String) async throws {
        // TODO(Adem) : Product.products(for:), purchase(), switch sur le résultat (success / userCancelled / pending).
    }

    public func restore() async throws {
        // TODO(Adem) : try await AppStore.sync()
    }
}
