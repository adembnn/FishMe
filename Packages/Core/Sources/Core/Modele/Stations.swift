import Foundation

/// Un rectangle sur la carte : coin sud-ouest et coin nord-est (ajout du 15 oct., pour L2).
public struct RegionCarte: Sendable, Equatable, Hashable, Codable {
    public var sudOuest: Coordonnee
    public var nordEst: Coordonnee

    public init(sudOuest: Coordonnee, nordEst: Coordonnee) {
        self.sudOuest = sudOuest
        self.nordEst = nordEst
    }

    /// Vrai si le point est dans le rectangle, bords compris.
    public func contient(_ c: Coordonnee) -> Bool {
        c.latitude >= sudOuest.latitude && c.latitude <= nordEst.latitude
            && c.longitude >= sudOuest.longitude && c.longitude <= nordEst.longitude
    }
}

/// Une espèce relevée dans une station OFB : nombre de pêches et année du dernier relevé.
public struct EspeceRelevee: Sendable, Equatable, Hashable, Codable {
    public var espece: Espece
    public var nPeches: Int
    public var annee: Int

    public init(espece: Espece, nPeches: Int, annee: Int) {
        self.espece = espece
        self.nPeches = nPeches
        self.annee = annee
    }
}

/// Une station OFB avec toutes ses espèces. La coordonnée est déjà arrondie à la précision d'affichage (jamais exacte).
public struct StationOFB: Sendable, Equatable, Hashable, Codable {
    public var codeStation: String
    public var eau: String?
    public var departement: Departement
    public var coordonnee: Coordonnee
    public var especes: [EspeceRelevee]

    public init(codeStation: String, eau: String?, departement: Departement, coordonnee: Coordonnee, especes: [EspeceRelevee]) {
        self.codeStation = codeStation
        self.eau = eau
        self.departement = departement
        self.coordonnee = coordonnee
        self.especes = especes
    }
}
