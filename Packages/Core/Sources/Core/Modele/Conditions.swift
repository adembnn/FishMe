import Foundation

/// Un point de la météo, en nombres (l'app les tire de WeatherKit ; `Core` n'importe jamais WeatherKit).
public struct PointMeteo: Sendable, Equatable, Hashable, Codable {
    public var heure: Date
    public var ventKmh: Double
    public var rafalesKmh: Double?
    public var directionDeg: Double?
    public var pluieMm: Double
    public var pressionHPa: Double
    public var temperatureC: Double
    public var codeTemps: Int

    public init(heure: Date, ventKmh: Double, rafalesKmh: Double? = nil, directionDeg: Double? = nil, pluieMm: Double,
                pressionHPa: Double, temperatureC: Double, codeTemps: Int) {
        self.heure = heure
        self.ventKmh = ventKmh
        self.rafalesKmh = rafalesKmh
        self.directionDeg = directionDeg
        self.pluieMm = pluieMm
        self.pressionHPa = pressionHPa
        self.temperatureC = temperatureC
        self.codeTemps = codeTemps
    }
}

public struct AlerteOfficielle: Sendable, Equatable, Hashable, Codable {
    public var texte: String
    public var source: String
    public var debut: Date?

    public init(texte: String, source: String, debut: Date? = nil) {
        self.texte = texte
        self.source = source
        self.debut = debut
    }
}

/// La météo brute que l'app passe à `lireConditions` et `alerte`.
public struct MeteoBrute: Sendable, Equatable, Hashable, Codable {
    public var heures: [PointMeteo]
    public var alertesOfficielles: [AlerteOfficielle]

    public init(heures: [PointMeteo], alertesOfficielles: [AlerteOfficielle] = []) {
        self.heures = heures
        self.alertesOfficielles = alertesOfficielles
    }
}

public struct StationHydro: Sendable, Equatable, Hashable, Codable {
    public var code: String
    public var nom: String
    public var eau: String?
    public var coordonnee: Coordonnee

    public init(code: String, nom: String, eau: String? = nil, coordonnee: Coordonnee) {
        self.code = code
        self.nom = nom
        self.eau = eau
        self.coordonnee = coordonnee
    }
}

public enum Vigilance: String, Sendable, Equatable, Hashable, Codable {
    case vert
    case jaune
    case orange
    case rouge
}

public struct MesureNiveau: Sendable, Equatable, Hashable, Codable {
    public var heure: Date
    public var hauteurM: Double?
    public var debitM3s: Double?

    public init(heure: Date, hauteurM: Double? = nil, debitM3s: Double? = nil) {
        self.heure = heure
        self.hauteurM = hauteurM
        self.debitM3s = debitM3s
    }
}

/// Niveau de la rivière à une station : hauteur, débit, série de 48 h, normale du mois si la station en a une.
public struct NiveauEau: Sendable, Equatable, Hashable, Codable {
    public var station: StationHydro
    public var hauteurM: Double?
    public var debitM3s: Double?
    public var serie48h: [MesureNiveau]
    /// Débit normal du mois ; `nil` : la jauge ne dit jamais « normal » ni « haut ».
    public var normaleDebitM3s: Double?
    public var vigilance: Vigilance?
    public var heureMesure: Date

    public init(station: StationHydro, hauteurM: Double? = nil, debitM3s: Double? = nil, serie48h: [MesureNiveau] = [],
                normaleDebitM3s: Double? = nil, vigilance: Vigilance? = nil, heureMesure: Date) {
        self.station = station
        self.hauteurM = hauteurM
        self.debitM3s = debitM3s
        self.serie48h = serie48h
        self.normaleDebitM3s = normaleDebitM3s
        self.vigilance = vigilance
        self.heureMesure = heureMesure
    }
}

public enum EtatRiviere: String, Sendable, Equatable, Hashable, Codable {
    case normal
    case haut
    case crue
    case inconnu
}

/// Un jour de la prévision à 7 jours.
public struct JourConditions: Sendable, Equatable, Hashable, Codable {
    public var jour: Date
    public var ventKmh: Double
    public var pluieMm: Double
    public var temperatureMinC: Double
    public var temperatureMaxC: Double
    public var codeTemps: Int

    public init(jour: Date, ventKmh: Double, pluieMm: Double, temperatureMinC: Double, temperatureMaxC: Double, codeTemps: Int) {
        self.jour = jour
        self.ventKmh = ventKmh
        self.pluieMm = pluieMm
        self.temperatureMinC = temperatureMinC
        self.temperatureMaxC = temperatureMaxC
        self.codeTemps = codeTemps
    }
}

/// La rangée « maintenant » et les 7 jours. Chaque valeur porte son heure ; `sources` nomme d'où elle vient.
public struct Conditions: Sendable, Equatable, Hashable, Codable {
    public var heure: Date
    public var ventKmh: Double?
    public var pluieMm: Double?
    public var pressionHPa: Double?
    /// Variation sur 6 h (« -3 hPa en 6 h »).
    public var tendancePressionHPa6h: Double?
    public var aube: Date?
    public var crepuscule: Date?
    public var finLegale: Date?
    public var etatRiviere: EtatRiviere
    public var septJours: [JourConditions]
    public var sources: [String]
    /// L'heure du point météo dont vient la pression (N3 : sert à écrire « prévu » quand elle est loin de l'heure demandée).
    public var heurePression: Date?

    public init(heure: Date, ventKmh: Double? = nil, pluieMm: Double? = nil, pressionHPa: Double? = nil,
                tendancePressionHPa6h: Double? = nil, aube: Date? = nil, crepuscule: Date? = nil, finLegale: Date? = nil,
                etatRiviere: EtatRiviere = .inconnu, septJours: [JourConditions] = [], sources: [String] = [],
                heurePression: Date? = nil) {
        self.heure = heure
        self.ventKmh = ventKmh
        self.pluieMm = pluieMm
        self.pressionHPa = pressionHPa
        self.tendancePressionHPa6h = tendancePressionHPa6h
        self.aube = aube
        self.crepuscule = crepuscule
        self.finLegale = finLegale
        self.etatRiviere = etatRiviere
        self.septJours = septJours
        self.sources = sources
        self.heurePression = heurePression
    }
}

public enum TypeAlerte: String, Sendable, Equatable, Hashable, Codable {
    case orage
    case crue
}

/// Alerte de sécurité : toujours gratuite, jamais derrière le paywall.
public struct Alerte: Sendable, Equatable, Hashable, Codable {
    public var type: TypeAlerte
    public var mesure: String
    public var source: String
    public var heure: Date

    public init(type: TypeAlerte, mesure: String, source: String, heure: Date) {
        self.type = type
        self.mesure = mesure
        self.source = source
        self.heure = heure
    }
}

/// Un conseil court (appât, hameçon, technique), avec sa source ; le premier de chaque espèce est gratuit.
public struct Conseil: Sendable, Equatable, Hashable, Codable {
    public var texte: String
    public var icone: String
    public var source: SourceRegle
    public var gratuit: Bool

    public init(texte: String, icone: String, source: SourceRegle, gratuit: Bool) {
        self.texte = texte
        self.icone = icone
        self.source = source
        self.gratuit = gratuit
    }
}

/// « 4 perches sur 6 par vent d'ouest » : un compte de ses propres prises, jamais une prévision.
public struct Constat: Sendable, Equatable, Hashable, Codable {
    public var texte: String
    public var nPeches: Int
    public var surSorties: Int

    public init(texte: String, nPeches: Int, surSorties: Int) {
        self.texte = texte
        self.nPeches = nPeches
        self.surSorties = surSorties
    }
}

public enum NiveauPecheur: String, Sendable, Equatable, Hashable, Codable {
    case debutant
    case occasionnel
    case confirme
}
