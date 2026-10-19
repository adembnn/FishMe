import Foundation

// N3 : pression, température de l'eau et débit comme des mesures sourcées, avec leur tendance.
// Rien ici ne classe ni ne prédit : une valeur, son unité, son heure, sa source.

/// Le sens d'une tendance. Ni bon ni mauvais signe : l'écran ne lui met aucune couleur d'alerte.
public enum SensTendance: String, Sendable, Equatable, Hashable, Codable {
    case hausse
    case stable
    case baisse
}

public enum Grandeur: String, Sendable, Equatable, Hashable, Codable {
    case pression
    case temperatureEau
    case debit
}

/// L'écart entre la valeur actuelle et celle d'avant, sur un nombre d'heures.
public struct Tendance: Sendable, Equatable, Hashable, Codable {
    public var sens: SensTendance
    /// Valeur actuelle moins valeur d'avant, dans l'unité de la mesure.
    public var ecart: Double
    /// 6 pour la pression, 24 pour la température, 6 pour le débit.
    public var surHeures: Int

    public init(sens: SensTendance, ecart: Double, surHeures: Int) {
        self.sens = sens
        self.ecart = ecart
        self.surHeures = surHeures
    }
}

/// Une mesure d'eau de plus de 48 h est « ancienne » (l'écran écrit « dernière mesure le… », en gris).
public enum FraicheurMesure: String, Sendable, Equatable, Hashable, Codable {
    case recente
    case ancienne
}

/// Une mesure sourcée : valeur, unité, heure de mesure, source, et tendance si elle se calcule.
public struct MesureSourcee: Sendable, Equatable, Hashable, Codable {
    public var grandeur: Grandeur
    public var valeur: Double
    /// « hPa », « °C », « m³/s ».
    public var unite: String
    public var heure: Date
    /// « Apple Weather », « Hub'Eau, station La Marne à Gournay-sur-Marne, 4 km ».
    public var source: String
    public var tendance: Tendance?
    /// Vrai si la valeur est tirée d'une prévision : l'écran écrit « prévu ».
    public var prevue: Bool
    public var fraicheur: FraicheurMesure

    public init(grandeur: Grandeur, valeur: Double, unite: String, heure: Date, source: String, tendance: Tendance? = nil,
                prevue: Bool = false, fraicheur: FraicheurMesure = .recente) {
        self.grandeur = grandeur
        self.valeur = valeur
        self.unite = unite
        self.heure = heure
        self.source = source
        self.tendance = tendance
        self.prevue = prevue
        self.fraicheur = fraicheur
    }
}

/// Une station du réseau de température des cours d'eau de Hub'Eau (métadonnées seulement).
public struct StationTemperature: Sendable, Equatable, Hashable, Codable {
    public var code: String
    public var nom: String
    /// Le cours d'eau, en clair (« La Marne »).
    public var eau: String?
    /// Le code Sandre du cours d'eau, s'il est connu.
    public var codeEau: String?
    public var coordonnee: Coordonnee
    /// Distance au spot en mètres, remplie par `stationTemperature(pres:eau:)`. Jamais envoyée à Hub'Eau.
    public var distanceM: Double?

    public init(code: String, nom: String, eau: String? = nil, codeEau: String? = nil, coordonnee: Coordonnee, distanceM: Double? = nil) {
        self.code = code
        self.nom = nom
        self.eau = eau
        self.codeEau = codeEau
        self.coordonnee = coordonnee
        self.distanceM = distanceM
    }
}

public struct MesureTemperature: Sendable, Equatable, Hashable, Codable {
    public var heure: Date
    public var celsius: Double

    public init(heure: Date, celsius: Double) {
        self.heure = heure
        self.celsius = celsius
    }
}

/// La dernière température mesurée à une station, avec sa série.
public struct TemperatureEau: Sendable, Equatable, Hashable, Codable {
    public var station: StationTemperature
    public var celsius: Double
    public var heureMesure: Date
    /// Au plus un point par heure, sur les 48 h avant la dernière mesure.
    public var serie48h: [MesureTemperature]

    public init(station: StationTemperature, celsius: Double, heureMesure: Date, serie48h: [MesureTemperature] = []) {
        self.station = station
        self.celsius = celsius
        self.heureMesure = heureMesure
        self.serie48h = serie48h
    }
}
