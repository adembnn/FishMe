// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md (jamais de changement silencieux).
import Foundation

/// Statut réglementaire/écologique d'une espèce (information, jamais un verdict de légalité de capture).
public enum ProtectionStatus: String, Codable, Hashable, Sendable, CaseIterable {
    case aucun
    case protege
    case menace
    case envahissante
}

/// Un critère d'identification visuel utilisé par le mode « manuel assisté » (ex. clé "barbillons", valeur "oui").
public struct IdentificationTrait: Codable, Hashable, Sendable {
    public let key: String
    public let value: String

    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}

/// Réponse de l'utilisateur à une question du questionnaire manuel assisté.
public struct TraitAnswer: Codable, Hashable, Sendable {
    public let traitKey: String
    public let value: String

    public init(traitKey: String, value: String) {
        self.traitKey = traitKey
        self.value = value
    }
}

/// Une espèce du catalogue. `id` = slug stable ("brochet", "carpe-commune"). `codeAspe` = code OFB ("BRO", "GAR").
public struct Species: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let codeAspe: String
    public let nomFr: String
    public let nomLatin: String
    public let famille: String
    public let tailleCommuneCm: Int
    public let tailleMaxCm: Int
    public let traits: [IdentificationTrait]
    public let statut: ProtectionStatus
    public let description: String
    public let anecdote: String
    /// Nom d'asset de l'illustration/carte (résolu côté App).
    public let imageAsset: String

    public init(
        id: String,
        codeAspe: String,
        nomFr: String,
        nomLatin: String,
        famille: String,
        tailleCommuneCm: Int,
        tailleMaxCm: Int,
        traits: [IdentificationTrait],
        statut: ProtectionStatus,
        description: String,
        anecdote: String,
        imageAsset: String
    ) {
        self.id = id
        self.codeAspe = codeAspe
        self.nomFr = nomFr
        self.nomLatin = nomLatin
        self.famille = famille
        self.tailleCommuneCm = tailleCommuneCm
        self.tailleMaxCm = tailleMaxCm
        self.traits = traits
        self.statut = statut
        self.description = description
        self.anecdote = anecdote
        self.imageAsset = imageAsset
    }
}
