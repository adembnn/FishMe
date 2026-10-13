// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

public enum TripOutcome: String, Codable, Hashable, Sendable, CaseIterable {
    case enCours
    case avecPrises
    case bredouille
}

/// Une sortie de pêche (début/fin, lieu optionnel). Une sortie bredouille donne une carte `bredouille`.
public struct Trip: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var startedAt: Date
    public var endedAt: Date?
    public var departmentCode: String?
    public var place: FuzzyPlace?
    public var outcome: TripOutcome
    public var note: String?

    public init(
        id: UUID = UUID(),
        startedAt: Date,
        endedAt: Date? = nil,
        departmentCode: String? = nil,
        place: FuzzyPlace? = nil,
        outcome: TripOutcome = .enCours,
        note: String? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.departmentCode = departmentCode
        self.place = place
        self.outcome = outcome
        self.note = note
    }
}
