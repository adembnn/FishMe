// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Persistance des données utilisateur (un seul fichier collection.json côté App, écriture atomique).
public protocol CollectionStore: Sendable {
    /// Renvoie `CollectionSnapshot.empty` si rien n'est encore enregistré.
    func load() async throws -> CollectionSnapshot
    func save(_ snapshot: CollectionSnapshot) async throws
}

/// Rareté d'une espèce dans un département (règle explicable, calculée sur les relevés OFB).
/// Le calcul vit dans un lot ultérieur ; ici, le contrat seulement.
public protocol RarityProvider: Sendable {
    /// nil si l'espèce n'a pas de rareté (protégée, exotique) ou si le département est inconnu.
    func rarity(of species: Species, in department: DepartmentProfile) -> RarityInfo?
}

/// Résolution du département à partir d'une position (point-dans-polygone embarqué, hors ligne).
public protocol DepartmentResolver: Sendable {
    /// Code du département ("95", "2A"...) ou nil si hors France ou position inconnue.
    func departmentCode(latitude: Double, longitude: Double) -> String?
}

/// Accès en lecture seule aux données de référence embarquées.
public protocol SpeciesCatalog: Sendable {
    func allSpecies() throws -> [Species]
    func species(id: String) throws -> Species?
    func allDepartments() throws -> [Department]
    /// nil si le département n'a pas de fichier de données.
    func profile(departmentCode: String) throws -> DepartmentProfile?
    /// Espèces présentes dans le département (liste fermée donnée aux moteurs d'identification).
    func candidates(in department: DepartmentProfile) throws -> [Species]
}

/// Horloge injectable (tests déterministes).
public protocol ClockProviding: Sendable {
    func now() -> Date
}

/// Horloge réelle. Seule implémentation « de production » du Core : triviale, donc dans le contrat.
public struct SystemClock: ClockProviding {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
