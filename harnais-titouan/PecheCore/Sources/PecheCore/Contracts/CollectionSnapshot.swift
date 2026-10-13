// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Photographie complète des données utilisateur (un seul fichier collection.json côté App).
/// `schemaVersion` sert aux migrations.
public struct CollectionSnapshot: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var cards: [CatchCard]
    public var trips: [Trip]
    public var achievements: [Achievement]

    public init(
        schemaVersion: Int = CollectionSnapshot.currentSchemaVersion,
        cards: [CatchCard] = [],
        trips: [Trip] = [],
        achievements: [Achievement] = []
    ) {
        self.schemaVersion = schemaVersion
        self.cards = cards
        self.trips = trips
        self.achievements = achievements
    }

    public static let empty = CollectionSnapshot()
}
