// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Moteur qui a proposé une espèce. Utilisé par `CatchCard.identifiedBy`.
public enum IdentificationSource: String, Codable, Hashable, Sendable, CaseIterable {
    case foundationModels
    case coreML
    case manual
    /// Dernier repli : espèces les plus fréquentes du département, sans analyse de photo.
    case priorOnly
}

/// Niveau de confiance QUALITATIF. Jamais de pourcentage affiché à l'utilisateur.
public enum IdentificationConfidence: String, Codable, Hashable, Sendable, CaseIterable {
    case probable
    case possible

    public var libelle: String {
        switch self {
        case .probable: return "Probable"
        case .possible: return "Possible"
        }
    }
}

/// Entrée d'un moteur. `candidates` = liste fermée (espèces présentes dans le département) ;
/// un moteur ne doit jamais renvoyer une espèce hors de cette liste.
public struct IdentificationRequest: Sendable {
    public let imageJPEG: Data?
    public let department: DepartmentProfile
    public let candidates: [Species]
    /// Réponses du questionnaire « manuel assisté » (vide pour les moteurs photo).
    public let answers: [TraitAnswer]

    public init(imageJPEG: Data? = nil, department: DepartmentProfile, candidates: [Species], answers: [TraitAnswer] = []) {
        self.imageJPEG = imageJPEG
        self.department = department
        self.candidates = candidates
        self.answers = answers
    }
}

/// Une proposition d'espèce.
public struct IdentificationCandidate: Codable, Hashable, Sendable {
    public let speciesID: String
    public let confidence: IdentificationConfidence
    /// Score interne 0...1, réservé au classement/fusion. NE DOIT JAMAIS être affiché.
    public let score: Double
    public let source: IdentificationSource

    public init(speciesID: String, confidence: IdentificationConfidence, score: Double, source: IdentificationSource) {
        self.speciesID = speciesID
        self.confidence = confidence
        self.score = min(max(score, 0), 1)
        self.source = source
    }
}

/// Moteur écarté pendant la chaîne de repli (journal pour l'écran debug caché).
public struct IdentificationFailure: Hashable, Sendable {
    public let source: IdentificationSource
    public let error: IdentificationError

    public init(source: IdentificationSource, error: IdentificationError) {
        self.source = source
        self.error = error
    }
}

/// Sortie d'un moteur ou de la chaîne : 0 à 3 propositions, classées de la plus à la moins plausible.
public struct IdentificationResult: Sendable {
    public static let maxCandidates = 3

    public let candidates: [IdentificationCandidate]
    /// Moteur qui a produit `candidates`.
    public let source: IdentificationSource
    /// Moteurs essayés avant celui-ci et tombés en repli.
    public let fallbacks: [IdentificationFailure]

    public init(candidates: [IdentificationCandidate], source: IdentificationSource, fallbacks: [IdentificationFailure] = []) {
        self.candidates = Array(candidates.prefix(IdentificationResult.maxCandidates))
        self.source = source
        self.fallbacks = fallbacks
    }
}

public enum IdentificationError: Error, Hashable, Sendable {
    /// Moteur indisponible (Apple Intelligence absente, modèle non embarqué...).
    case unavailable
    case noImage
    case noCandidates
    /// Garde-fou du modèle déclenché (guardrailViolation).
    case guardrailViolation
    case contextTooLarge
    case unsupportedLanguage
    case failed(String)
    /// Tous les moteurs de la chaîne ont échoué.
    case allEnginesFailed
}

public protocol SpeciesIdentifier: Sendable {
    var source: IdentificationSource { get }
    func isAvailable() async -> Bool
    /// Renvoie 0...3 propositions, jamais d'espèce hors `request.candidates`.
    func identify(_ request: IdentificationRequest) async throws -> IdentificationResult
}

/// Ordre de repli : on essaie chaque moteur dans l'ordre, le premier qui répond non vide gagne.
/// Ordre normal : foundationModels, coreML, manual, priorOnly.
public struct IdentifierChain: Sendable {
    public static let defaultOrder: [IdentificationSource] = [.foundationModels, .coreML, .manual, .priorOnly]

    public let identifiers: [any SpeciesIdentifier]

    public init(identifiers: [any SpeciesIdentifier]) {
        self.identifiers = identifiers
    }

    public func identify(_ request: IdentificationRequest) async throws -> IdentificationResult {
        var failures: [IdentificationFailure] = []
        for engine in identifiers {
            guard await engine.isAvailable() else {
                failures.append(IdentificationFailure(source: engine.source, error: .unavailable))
                continue
            }
            do {
                let result = try await engine.identify(request)
                if !result.candidates.isEmpty {
                    return IdentificationResult(candidates: result.candidates, source: engine.source, fallbacks: failures)
                }
                failures.append(IdentificationFailure(source: engine.source, error: .noCandidates))
            } catch let error as IdentificationError {
                failures.append(IdentificationFailure(source: engine.source, error: error))
            } catch {
                failures.append(IdentificationFailure(source: engine.source, error: .failed("\(error)")))
            }
        }
        throw IdentificationError.allEnginesFailed
    }
}
