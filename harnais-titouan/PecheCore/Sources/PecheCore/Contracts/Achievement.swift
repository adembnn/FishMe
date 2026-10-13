// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Un succès / objectif de collection. La logique de déblocage viendra dans un lot ultérieur.
public struct Achievement: Codable, Identifiable, Hashable, Sendable {
    /// Identifiant stable ("premiere-prise", "dix-especes"...).
    public let id: String
    public var titre: String
    public var detail: String
    public var progress: Int
    public var target: Int
    public var unlockedAt: Date?

    public var isUnlocked: Bool { unlockedAt != nil }

    public init(id: String, titre: String, detail: String, progress: Int = 0, target: Int = 1, unlockedAt: Date? = nil) {
        self.id = id
        self.titre = titre
        self.detail = detail
        self.progress = progress
        self.target = target
        self.unlockedAt = unlockedAt
    }
}
