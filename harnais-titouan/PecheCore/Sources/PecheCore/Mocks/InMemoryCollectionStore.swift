// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// Mock : stockage en mémoire pour tests et #Preview. Aucune logique produit.
import Foundation

public actor InMemoryCollectionStore: CollectionStore {
    private var snapshot: CollectionSnapshot
    /// Si non nil, load()/save() lèvent cette erreur (tests de cas d'échec).
    private var failure: (any Error & Sendable)?

    public init(snapshot: CollectionSnapshot = .empty) {
        self.snapshot = snapshot
    }

    public func setFailure(_ error: (any Error & Sendable)?) {
        failure = error
    }

    public func load() async throws -> CollectionSnapshot {
        if let failure { throw failure }
        return snapshot
    }

    public func save(_ snapshot: CollectionSnapshot) async throws {
        if let failure { throw failure }
        self.snapshot = snapshot
    }
}
