// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// Mock : moteur d'identification scripté, pour tests et #Preview. Aucune analyse réelle.
import Foundation

public struct MockIdentifier: SpeciesIdentifier {
    public enum Behavior: Sendable {
        /// Renvoie ces propositions (tronquées à 3).
        case returns([IdentificationCandidate])
        /// Lève cette erreur.
        case fails(IdentificationError)
    }

    public let source: IdentificationSource
    public let available: Bool
    public let behavior: Behavior

    public init(source: IdentificationSource = .manual, available: Bool = true, behavior: Behavior) {
        self.source = source
        self.available = available
        self.behavior = behavior
    }

    /// Mock prêt à l'emploi : trois espèces classiques, probable puis possible.
    public static func withSampleSpecies(source: IdentificationSource = .manual) -> MockIdentifier {
        MockIdentifier(source: source, behavior: .returns([
            IdentificationCandidate(speciesID: "brochet", confidence: .probable, score: 0.8, source: source),
            IdentificationCandidate(speciesID: "perche", confidence: .possible, score: 0.5, source: source),
            IdentificationCandidate(speciesID: "gardon", confidence: .possible, score: 0.3, source: source),
        ]))
    }

    public func isAvailable() async -> Bool {
        available
    }

    public func identify(_ request: IdentificationRequest) async throws -> IdentificationResult {
        switch behavior {
        case .returns(let candidates):
            return IdentificationResult(candidates: candidates, source: source)
        case .fails(let error):
            throw error
        }
    }
}
