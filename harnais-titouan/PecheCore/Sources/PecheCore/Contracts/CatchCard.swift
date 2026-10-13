// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Type de carte : une prise confirmée, une sortie bredouille (sans photo), ou une simple observation.
public enum CardKind: String, Codable, Hashable, Sendable, CaseIterable {
    case prise
    case bredouille
    case observation
}

/// Référence à une photo stockée localement (nom de fichier dans Documents/photos). Jamais de chemin absolu.
public struct PhotoRef: Codable, Hashable, Sendable {
    public let fileName: String

    public init(fileName: String) {
        self.fileName = fileName
    }
}

/// Lieu volontairement flou : jamais de coordonnées exactes (confidentialité des coins de pêche).
public struct FuzzyPlace: Codable, Hashable, Sendable {
    /// Libellé libre grossier (ex. « Oise, près de Cergy »), au niveau commune/région.
    public let label: String?
    public let departmentCode: String?

    public init(label: String? = nil, departmentCode: String? = nil) {
        self.label = label
        self.departmentCode = departmentCode
    }
}

/// La carte à collectionner.
public struct CatchCard: Codable, Identifiable, Hashable, Sendable {
    public let id: UUID
    public var kind: CardKind
    /// nil pour une carte bredouille.
    public var speciesID: String?
    public var sizeCm: Int?
    /// nil = non renseigné ; true = relâché.
    public var released: Bool?
    public var departmentCode: String?
    public var place: FuzzyPlace?
    public var date: Date
    public var photo: PhotoRef?
    public var rarity: RarityTier?
    /// Moteur qui a proposé l'espèce confirmée.
    public var identifiedBy: IdentificationSource?
    /// true si l'utilisateur a choisi une autre espèce que celles proposées.
    public var userCorrected: Bool
    public var tripID: UUID?

    public init(
        id: UUID = UUID(),
        kind: CardKind,
        speciesID: String? = nil,
        sizeCm: Int? = nil,
        released: Bool? = nil,
        departmentCode: String? = nil,
        place: FuzzyPlace? = nil,
        date: Date,
        photo: PhotoRef? = nil,
        rarity: RarityTier? = nil,
        identifiedBy: IdentificationSource? = nil,
        userCorrected: Bool = false,
        tripID: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.speciesID = speciesID
        self.sizeCm = sizeCm
        self.released = released
        self.departmentCode = departmentCode
        self.place = place
        self.date = date
        self.photo = photo
        self.rarity = rarity
        self.identifiedBy = identifiedBy
        self.userCorrected = userCorrected
        self.tripID = tripID
    }
}
