import Foundation

/// Niveau de rareté dans un département. `nonMesuree` : l'OFB ne suit pas l'espèce (grenouilles, crabe chinois, mulets),
/// jamais « légendaire » à sa place (par défaut, à confirmer par Adem).
public enum NiveauRarete: String, Sendable, Equatable, Hashable, Codable {
    case commun
    case peuCommun
    case rare
    case legendaire
    case nonMesuree
}

public enum EchelleCalcul: String, Sendable, Equatable, Hashable, Codable {
    case departement
    /// Le département a moins de 20 pêches : le calcul se fait sur la région.
    case region
}

/// Résultat de `rarete` : « 9 sur 29 » donne `nPeches` 9 et `nTotal` 29.
public struct ResultatRarete: Sendable, Equatable, Hashable, Codable {
    public var niveau: NiveauRarete
    public var nPeches: Int
    public var nTotal: Int
    public var anneeDernierReleve: Int?
    public var echelle: EchelleCalcul

    public init(niveau: NiveauRarete, nPeches: Int, nTotal: Int, anneeDernierReleve: Int?, echelle: EchelleCalcul) {
        self.niveau = niveau
        self.nPeches = nPeches
        self.nTotal = nTotal
        self.anneeDernierReleve = anneeDernierReleve
        self.echelle = echelle
    }
}

/// « Ouverte aujourd'hui » ou la date de réouverture (nil si inconnue).
public enum OuvertureDuJour: Sendable, Equatable, Hashable, Codable {
    case ouverte
    case fermee(reouverture: Date?)
}

/// Une espèce relevée près d'un coin, avec N, l'année du dernier relevé et son ouverture ce jour.
public struct EspeceProche: Sendable, Equatable, Hashable, Codable {
    public var espece: Espece
    public var nPeches: Int
    public var annee: Int
    public var ouverture: OuvertureDuJour

    public init(espece: Espece, nPeches: Int, annee: Int, ouverture: OuvertureDuJour) {
        self.espece = espece
        self.nPeches = nPeches
        self.annee = annee
        self.ouverture = ouverture
    }
}

/// Une station OFB où une espèce a été relevée (filtre de E3). Triées par distance.
public struct Coin: Sendable, Equatable, Hashable, Codable {
    public var codeStation: String
    public var eau: String?
    public var departement: Departement
    public var coordonnee: Coordonnee
    public var distanceM: Double
    public var nPeches: Int
    public var annee: Int
    public var ouverture: OuvertureDuJour

    public init(codeStation: String, eau: String?, departement: Departement, coordonnee: Coordonnee, distanceM: Double,
                nPeches: Int, annee: Int, ouverture: OuvertureDuJour) {
        self.codeStation = codeStation
        self.eau = eau
        self.departement = departement
        self.coordonnee = coordonnee
        self.distanceM = distanceM
        self.nPeches = nPeches
        self.annee = annee
        self.ouverture = ouverture
    }
}

/// Un département dont le fichier de règles est présent (bandeau de L2).
public enum NiveauCouverture: String, Sendable, Equatable, Hashable, Codable {
    case complet
    case partiel
}

public struct DepartementCouvert: Sendable, Equatable, Hashable, Codable {
    public var departement: Departement
    public var niveau: NiveauCouverture
    public var reglesConfirmees: Int
    public var lignesAVerifier: Int
    public var dateLecture: Date?
    public var expireMin: Date?

    public init(departement: Departement, niveau: NiveauCouverture, reglesConfirmees: Int, lignesAVerifier: Int,
                dateLecture: Date? = nil, expireMin: Date? = nil) {
        self.departement = departement
        self.niveau = niveau
        self.reglesConfirmees = reglesConfirmees
        self.lignesAVerifier = lignesAVerifier
        self.dateLecture = dateLecture
        self.expireMin = expireMin
    }
}

/// Une ligne de la page Sources (`credits.json`).
public struct Credit: Sendable, Equatable, Hashable, Codable {
    public var nom: String
    public var url: String?
    public var mention: String?

    public init(nom: String, url: String? = nil, mention: String? = nil) {
        self.nom = nom
        self.url = url
        self.mention = mention
    }
}

/// Liens d'un département (`liens-federations.json`).
public struct LiensFederation: Sendable, Equatable, Hashable, Codable {
    public var siteFederation: String?
    public var pageCarteDePeche: String?

    public init(siteFederation: String? = nil, pageCarteDePeche: String? = nil) {
        self.siteFederation = siteFederation
        self.pageCarteDePeche = pageCarteDePeche
    }
}

public enum PhaseLune: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case nouvelle
    case premierCroissant
    case premierQuartier
    case gibbeuseCroissante
    case pleine
    case gibbeuseDecroissante
    case dernierQuartier
    case dernierCroissant
}
