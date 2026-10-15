import Foundation
import Spark
import StoreKit

/// Le seul fichier qui importe le SDK. La clé d'API n'est pas ici : A passe, dans `BuildChallengeApp.swift`,
/// la fermeture qui construit la configuration (la clé du kit y est déjà) et appelle `Spark.configure`.
/// Le SDK plante si on touche `Spark.shared` avant `configure` : `CoucheMesure` n'appelle cette passerelle qu'après l'accord et après `configurer()`.
nonisolated struct PasserelleSpark: PasserelleSDK {
    private let configuration: @MainActor @Sendable () -> Void

    init(configuration: @escaping @MainActor @Sendable () -> Void) {
        self.configuration = configuration
    }

    @MainActor func configurer() { configuration() }

    func evenement(type: String, proprietes: [String: String]) {
        Spark.shared.analytics.logEvent(type: type, properties: proprietes.isEmpty ? nil : proprietes)
    }

    func enregistrerAchat(_ resultat: Product.PurchaseResult) async {
        try? await Spark.shared.monetization.recordPurchase(resultat)
    }

    func enregistrerTransactions(_ transactions: [VerificationResult<Transaction>]) async {
        try? await Spark.shared.monetization.recordTransactions(transactions)
    }
}
