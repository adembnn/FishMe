// NON COMPILÉ : écrit sans compilateur Swift. Stub : signatures seulement.
import Foundation
import PecheCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Moteur d'identification via le modèle sur appareil d'Apple (Foundation Models).
///
/// - Disponibilité : iOS 26+ pour le texte ; l'entrée IMAGE demande le SDK iOS 27 (⚠ à vérifier),
///   donc sous `#if IOS27_SDK` + `#available(iOS 27, *)`. Échoue au simulateur : appareil obligatoire.
/// - Contrat : renvoie 0...3 propositions, JAMAIS d'espèce hors `request.candidates`,
///   jamais de pourcentage affiché (le score reste interne).
/// - Repli : si indisponible, `isAvailable()` renvoie false et la chaîne passe au moteur suivant.
public struct FoundationModelsIdentifier: SpeciesIdentifier {
    public let source: IdentificationSource = .foundationModels

    public init() {}

    public func isAvailable() async -> Bool {
        #if canImport(FoundationModels) && IOS27_SDK
        if #available(iOS 27, *) {
            // TODO(Adem) : consulter la disponibilité du modèle système (⚠ nom d'API à vérifier à la compilation).
            return false
        }
        #endif
        return false
    }

    public func identify(_ request: IdentificationRequest) async throws -> IdentificationResult {
        guard request.imageJPEG != nil else { throw IdentificationError.noImage }
        guard !request.candidates.isEmpty else { throw IdentificationError.noCandidates }
        #if canImport(FoundationModels) && IOS27_SDK
        if #available(iOS 27, *) {
            // TODO(Adem) : session + schéma guidé (anyOf sur request.candidates) + image en pièce jointe.
            // TODO(Adem) : mapper guardrailViolation -> IdentificationError.guardrailViolation,
            //              contexte trop long -> .contextTooLarge. Filtrer toute espèce hors candidates.
        }
        #endif
        throw IdentificationError.unavailable
    }
}
