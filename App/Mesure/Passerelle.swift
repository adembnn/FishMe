import Foundation
import StoreKit

/// La seule porte vers le SDK Spark Flash. Tout le reste de l'app parle au contrat `Mesure` de Core ;
/// cette passerelle existe pour que les tests tournent sans SDK (faux ci-dessous) et que la clé reste dans `BuildChallengeApp.swift`.
nonisolated protocol PasserelleSDK: Sendable {
    /// Appelle `Spark.configure(...)`. Une seule fois, jamais avant l'accord : `CoucheMesure` le garantit.
    @MainActor func configurer()
    func evenement(type: String, proprietes: [String: String])
    func enregistrerAchat(_ resultat: Product.PurchaseResult) async
    func enregistrerTransactions(_ transactions: [VerificationResult<Transaction>]) async
}

/// Passerelle sans effet, pour les tests et les aperçus : retient ce qu'on lui demande.
nonisolated final class PasserelleFausse: PasserelleSDK, @unchecked Sendable {
    private let verrou = NSLock()
    private var _configurations = 0
    private var _evenements: [(type: String, proprietes: [String: String])] = []
    private var _achats = 0
    private var _transactions = 0

    var configurations: Int { verrou.withLock { _configurations } }
    var evenements: [(type: String, proprietes: [String: String])] { verrou.withLock { _evenements } }
    var achats: Int { verrou.withLock { _achats } }
    var transactions: Int { verrou.withLock { _transactions } }

    @MainActor func configurer() { verrou.withLock { _configurations += 1 } }
    func evenement(type: String, proprietes: [String: String]) { verrou.withLock { _evenements.append((type, proprietes)) } }
    func enregistrerAchat(_ resultat: Product.PurchaseResult) async { verrou.withLock { _achats += 1 } }
    func enregistrerTransactions(_ transactions: [VerificationResult<Transaction>]) async { verrou.withLock { _transactions += 1 } }
}
