// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Un département français (code INSEE : "95", "2A", "971"...).
public struct Department: Codable, Hashable, Identifiable, Sendable {
    public let code: String
    public let nom: String
    public var id: String { code }

    public init(code: String, nom: String) {
        self.code = code
        self.nom = nom
    }
}

/// Présence d'une espèce dans les relevés scientifiques OFB d'un département.
public struct SpeciesPresence: Codable, Hashable, Sendable {
    public let speciesID: String
    /// Nombre de stations où l'espèce a été observée (depuis 2010).
    public let stationsPresent: Int
    /// stationsPresent / stationsTotal, dans 0...1.
    public let frequence: Double
    public let derniereAnnee: Int?

    public init(speciesID: String, stationsPresent: Int, frequence: Double, derniereAnnee: Int? = nil) {
        self.speciesID = speciesID
        self.stationsPresent = stationsPresent
        self.frequence = frequence
        self.derniereAnnee = derniereAnnee
    }
}

/// Un fichier JSON par département (généré par Tools/data-pipeline).
public struct DepartmentProfile: Codable, Hashable, Sendable {
    public let code: String
    public let nom: String
    /// Stations ayant eu au moins une pêche depuis 2010.
    public let stationsTotal: Int
    public let especes: [SpeciesPresence]
    public let federationURL: URL?
    public let federationNom: String?

    public var department: Department { Department(code: code, nom: nom) }

    public init(
        code: String,
        nom: String,
        stationsTotal: Int,
        especes: [SpeciesPresence],
        federationURL: URL? = nil,
        federationNom: String? = nil
    ) {
        self.code = code
        self.nom = nom
        self.stationsTotal = stationsTotal
        self.especes = especes
        self.federationURL = federationURL
        self.federationNom = federationNom
    }

    public func presence(of speciesID: String) -> SpeciesPresence? {
        especes.first { $0.speciesID == speciesID }
    }
}
