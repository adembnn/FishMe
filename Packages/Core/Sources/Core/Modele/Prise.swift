import Foundation

public enum StadeAnguille: String, Sendable, Equatable, Hashable, Codable {
    case jaune
    case argentee
    case civelle
}

/// D'où vient la carte du Pescedex.
/// `priseReelle` : une vraie prise, photographiée par le pêcheur.
/// `declaree` : la carte du swipe du premier lancement (« déjà pêché »), sans photo, sans taille, sans lieu de pêche.
/// Une carte déclarée ne compte jamais dans un quota, une rareté vécue ni une sortie.
public enum OrigineCarte: String, Sendable, Equatable, Hashable, Codable {
    case priseReelle
    case declaree
}

/// Une carte du Pescedex. Toute prise confirmée y entre, gardée ou relâchée.
public struct Prise: Sendable, Equatable, Hashable, Codable, Identifiable {
    public var id: UUID
    public var espece: Espece
    public var origine: OrigineCarte
    public var longueurCm: Double?
    public var mesure: MethodeMesure?
    /// Seulement pour l'anguille.
    public var stade: StadeAnguille?
    public var date: Date
    /// « La Marne · 94 » : l'eau et le département, jamais le point exact.
    public var lieuFlou: String?
    /// Chemin de la photo, sans GPS. `nil` pour une carte déclarée.
    public var cheminPhoto: String?
    /// Déclaration du pêcheur (interrupteur éteint par défaut) : ne sert qu'au quota du jour.
    public var gardee: Bool
    /// Photo d'exemple (bouton « essayer avec une photo d'exemple »).
    public var exemple: Bool

    public init(id: UUID = UUID(), espece: Espece, origine: OrigineCarte = .priseReelle, longueurCm: Double? = nil,
                mesure: MethodeMesure? = nil, stade: StadeAnguille? = nil, date: Date, lieuFlou: String? = nil,
                cheminPhoto: String? = nil, gardee: Bool = false, exemple: Bool = false) {
        self.id = id
        self.espece = espece
        self.origine = origine
        self.longueurCm = longueurCm
        self.mesure = mesure
        self.stade = stade
        self.date = date
        self.lieuFlou = lieuFlou
        self.cheminPhoto = cheminPhoto
        self.gardee = gardee
        self.exemple = exemple
    }

    public var estDeclaree: Bool { origine == .declaree }

    /// Carte « déclarée » du swipe : aucune photo, aucune mesure, rien de gardé.
    public static func declaree(espece: Espece, date: Date) -> Prise {
        Prise(espece: espece, origine: .declaree, date: date)
    }
}

public struct PoidsEstime: Sendable, Equatable, Hashable, Codable {
    public var kilos: Double
    public var minKilos: Double
    public var maxKilos: Double
    public var source: String

    public init(kilos: Double, minKilos: Double, maxKilos: Double, source: String) {
        self.kilos = kilos
        self.minKilos = minKilos
        self.maxKilos = maxKilos
        self.source = source
    }
}

/// Ce que propose la reconnaissance (aucun score ni pourcentage à l'écran).
public enum TypeProposition: Sendable, Equatable, Hashable, Codable {
    /// Une espèce.
    case espece(Espece)
    /// Une classe dont l'espèce se choisit ensuite en images (lamproie, alose, écrevisse protégée).
    case classe(String)
    /// Bouton « Autre espèce » : grille limitée aux espèces de France, jamais de saisie libre.
    case autreEspece
    case pasUnPoisson
}

public struct Proposition: Sendable, Equatable, Hashable, Codable {
    public var type: TypeProposition

    public init(type: TypeProposition) {
        self.type = type
    }
}

/// Pourquoi la grille de toutes les espèces s'ouvre à la place des propositions.
public enum RaisonGrille: String, Sendable, Equatable, Hashable, Codable {
    case aucunModele
    case modeleSousLeSeuil
    case erreur
}

/// Ce que rend `IdentifieEspece`.
public enum ResultatIdentification: Sendable, Equatable, Hashable, Codable {
    /// Scores par nom de classe du modèle (déjà passés par la température de `reglages.json`).
    case scores([String: Double])
    /// Aucun score : la grille de toutes les espèces, avec la raison.
    case grille(raison: RaisonGrille)
}
