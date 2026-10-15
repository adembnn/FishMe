import Foundation

/// Un spot : un point (jamais un département) et un rayon, 1 km pour le spot gratuit.
/// `departement` ne sert qu'à savoir si le point est hors de France.
public struct Spot: Sendable, Equatable, Hashable, Codable {
    public var centre: Coordonnee
    public var rayonM: Double
    public var departement: Departement

    public init(centre: Coordonnee, rayonM: Double = 1000, departement: Departement) {
        self.centre = centre
        self.rayonM = rayonM
        self.departement = departement
    }
}

/// Une sortie de pêche. Les `conditions` relevées au départ et à chaque prise restent sur l'iPhone.
public struct Sortie: Sendable, Equatable, Hashable, Codable, Identifiable {
    public var id: UUID
    public var debut: Date
    public var fin: Date?
    public var prises: [Prise]
    /// Nombre de poissons gardés, par identifiant d'espèce.
    public var gardeesParEspece: [String: Int]
    public var conditions: [Conditions]

    public init(id: UUID = UUID(), debut: Date, fin: Date? = nil, prises: [Prise] = [],
                gardeesParEspece: [String: Int] = [:], conditions: [Conditions] = []) {
        self.id = id
        self.debut = debut
        self.fin = fin
        self.prises = prises
        self.gardeesParEspece = gardeesParEspece
        self.conditions = conditions
    }
}

public enum ModePaywall: String, Sendable, Equatable, Hashable, Codable {
    case aucun
    /// Fin de la 1re session : le paywall s'ouvre, puis se ferme.
    case quiSeFerme
    /// Un autre spot que le spot gratuit : le paywall bloque.
    case quiBloque
}

/// Réponse de `acces`.
public struct DecisionAcces: Sendable, Equatable, Hashable, Codable {
    public var sessionPermise: Bool
    public var paywall: ModePaywall
    /// Le spot gratuit à retenir (la 1re session fixe le sien quand aucun n'existe).
    public var spotGratuit: Spot?
    /// Par exemple « hors de France : aucune règle française ».
    public var message: String?

    public init(sessionPermise: Bool, paywall: ModePaywall = .aucun, spotGratuit: Spot? = nil, message: String? = nil) {
        self.sessionPermise = sessionPermise
        self.paywall = paywall
        self.spotGratuit = spotGratuit
        self.message = message
    }
}

public enum FonctionPro: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case meteoDuJour
    case niveauEau
    case septJours
    case prevenirMoi
    case courbeEtNormale
    case conseilsComplets
    case analyseConditions
}

/// L'offre annuelle affichée. 34,99 jusqu'au 31 décembre 2026 (tarif fondateur), 49,99 ensuite.
public struct OffreAffichee: Sendable, Equatable, Hashable, Codable {
    public var produit: String
    public var prixCentimes: Int
    public var tarifFondateur: Bool

    public init(produit: String, prixCentimes: Int, tarifFondateur: Bool) {
        self.produit = produit
        self.prixCentimes = prixCentimes
        self.tarifFondateur = tarifFondateur
    }
}

/// État de l'abonnement, tel que `Achats` le lit dans StoreKit 2.
public enum EtatAchats: Sendable, Equatable, Hashable, Codable {
    case nonAbonne
    case abonne
    /// L'accès reste pendant le délai de grâce.
    case delaiDeGrace(fin: Date)
    case relancePaiement
    case expire
    case rembourse
    case revoque
    /// Sans réseau : le dernier état vérifié sert.
    case sansReseau(dernierEtatAbonne: Bool)

    public var donneAcces: Bool {
        switch self {
        case .abonne, .delaiDeGrace: return true
        case .sansReseau(let abonne): return abonne
        case .nonAbonne, .relancePaiement, .expire, .rembourse, .revoque: return false
        }
    }
}

/// Les 6 événements de l'entonnoir (`fiches/L6.md`).
public enum EvenementMesure: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case carteListe
    case priseCommencee
    case carteCreee
    case sessionCommencee
    case sessionFinie
    case paywallMontre
}
