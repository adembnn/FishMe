// NON COMPILÉ : écrit sans compilateur Swift. Stub : signatures seulement.
import Foundation
import PecheCore
#if canImport(CoreML)
import CoreML
#endif
#if canImport(Vision)
import Vision
#endif

/// Moteur d'identification via un classifieur Create ML embarqué (optionnel, lot L11).
/// Sans modèle dans le bundle : `isAvailable()` renvoie false et la chaîne passe au questionnaire manuel.
public struct CoreMLIdentifier: SpeciesIdentifier {
    public let source: IdentificationSource = .coreML

    /// Nom du modèle compilé (.mlmodelc) dans le bundle de l'app. nil = aucun modèle.
    public let modelResourceName: String?

    public init(modelResourceName: String? = nil) {
        self.modelResourceName = modelResourceName
    }

    public func isAvailable() async -> Bool {
        // TODO(Adem) : vrai si le modèle existe dans Bundle.main et se charge.
        return false
    }

    public func identify(_ request: IdentificationRequest) async throws -> IdentificationResult {
        guard request.imageJPEG != nil else { throw IdentificationError.noImage }
        guard !request.candidates.isEmpty else { throw IdentificationError.noCandidates }
        // TODO(Adem) : classification Vision (VNCoreMLRequest), restreindre aux request.candidates,
        //              garder les 3 meilleures, confidence qualitative (.probable / .possible), score interne.
        throw IdentificationError.unavailable
    }
}
