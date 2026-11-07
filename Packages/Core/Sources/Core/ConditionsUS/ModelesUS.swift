import Foundation

// Conditions des rivières aux États-Unis : USGS (stations et mesures), NWS (alertes), NWPS (prévisions de crue).
// Foundation seulement. Les valeurs restent brutes, dans l'unité de la source, avec cette unité écrite dans le type :
// les conversions (°F, pieds, ft³/s vers le SI et inversement) appartiennent au lot us-core.

/// Mentions obligatoires ou demandées par les sources, à afficher avec les données.
public enum AttributionUS {
    /// USGS : mention de la source demandée (domaine public).
    public static let usgs = "Données : U.S. Geological Survey (USGS), Water Data APIs"
    /// USGS : avertissement officiel sur les données provisoires.
    public static let avertissementProvisoireUSGS =
        "Donnée provisoire : elle n'a pas été validée par l'USGS et peut être révisée ou supprimée."
    public static let nws = "Alertes : National Weather Service (NOAA)"
    public static let nwps = "Prévisions de crue : NOAA National Water Prediction Service"
}

/// Une position arrondie : la seule forme sous laquelle la position du pêcheur peut quitter l'appareil (cellule de 0,1° environ 11 km).
public struct CelluleUS: Sendable, Equatable, Hashable, Codable {
    public static let pas = 0.1
    public var latitude: Double
    public var longitude: Double

    /// Coin sud-ouest de la cellule qui contient le point.
    public init(latitude: Double, longitude: Double) {
        self.latitude = (latitude / Self.pas).rounded(.down) * Self.pas
        self.longitude = (longitude / Self.pas).rounded(.down) * Self.pas
    }

    /// « ouest,sud,est,nord », le format du paramètre `bbox` de l'API OGC.
    public var bbox: String {
        func t(_ v: Double) -> String { String(format: "%.1f", (v * 10).rounded() / 10) }
        return "\(t(longitude)),\(t(latitude)),\(t(longitude + Self.pas)),\(t(latitude + Self.pas))"
    }
}

// MARK: USGS

/// Les paramètres USGS suivis. Le code est celui du champ `parameter_code`.
public enum ParametreUSGS: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case debit = "00060"
    case hauteur = "00065"
    case temperatureEau = "00010"
}

/// L'unité d'une mesure USGS, telle que l'API la donne (« ft^3/s », « ft », « degC »). Aucune conversion ici.
public enum UniteUSGS: String, Sendable, Equatable, Hashable, Codable {
    case piedCubeParSeconde = "ft^3/s"
    case pied = "ft"
    case degreCelsius = "degC"
    case metreCubeParSeconde = "m^3/s"
    case metre = "m"
    /// Unité non reconnue : le texte brut est gardé dans `MesureUSGS.uniteBrute`.
    case inconnue = "?"

    init(brute: String?) {
        switch brute {
        case "ft^3/s", "ft3/s", "cfs": self = .piedCubeParSeconde
        case "ft": self = .pied
        case "degC", "deg C": self = .degreCelsius
        case "m^3/s", "m3/s": self = .metreCubeParSeconde
        case "m": self = .metre
        default: self = .inconnue
        }
    }
}

public enum StatutApprobationUSGS: String, Sendable, Equatable, Hashable, Codable {
    case approuvee = "Approved"
    case provisoire = "Provisional"
    case inconnu
}

/// Une station USGS (collection `monitoring-locations`).
public struct StationUSGS: Sendable, Equatable, Hashable, Codable {
    /// « USGS-01646500 ».
    public var id: String
    public var nom: String
    public var latitude: Double?
    public var longitude: Double?
    public var etat: String?
    public var comte: String?
    /// « Stream », « Lake, Reservoir, Impoundment »…
    public var typeDeSite: String?
    /// Surface du bassin, en miles carrés (unité USGS).
    public var bassinMilesCarres: Double?
    public var fuseau: String?
    public var attribution: String

    public init(id: String, nom: String, latitude: Double? = nil, longitude: Double? = nil, etat: String? = nil, comte: String? = nil,
                typeDeSite: String? = nil, bassinMilesCarres: Double? = nil, fuseau: String? = nil, attribution: String = AttributionUS.usgs) {
        self.id = id
        self.nom = nom
        self.latitude = latitude
        self.longitude = longitude
        self.etat = etat
        self.comte = comte
        self.typeDeSite = typeDeSite
        self.bassinMilesCarres = bassinMilesCarres
        self.fuseau = fuseau
        self.attribution = attribution
    }
}

/// Une mesure USGS (collections `latest-continuous` et `continuous`) : valeur brute, unité de la source, heure, statut.
public struct MesureUSGS: Sendable, Equatable, Hashable, Codable {
    public var stationId: String
    public var parametre: ParametreUSGS
    public var valeur: Double
    public var unite: UniteUSGS
    /// Le texte d'unité reçu, gardé tel quel.
    public var uniteBrute: String?
    public var heure: Date
    public var statut: StatutApprobationUSGS
    /// Identifiant de la série : une station peut avoir plusieurs capteurs pour un même paramètre.
    public var serieId: String?
    public var attribution: String

    public init(stationId: String, parametre: ParametreUSGS, valeur: Double, unite: UniteUSGS, uniteBrute: String? = nil, heure: Date,
                statut: StatutApprobationUSGS, serieId: String? = nil, attribution: String = AttributionUS.usgs) {
        self.stationId = stationId
        self.parametre = parametre
        self.valeur = valeur
        self.unite = unite
        self.uniteBrute = uniteBrute
        self.heure = heure
        self.statut = statut
        self.serieId = serieId
        self.attribution = attribution
    }

    /// Vrai si l'USGS n'a pas validé la valeur : l'écran doit alors afficher `avertissement`.
    public var estProvisoire: Bool { statut != .approuvee }

    /// L'avertissement officiel à afficher pour une donnée provisoire ; `nil` pour une donnée approuvée.
    public var avertissement: String? { estProvisoire ? AttributionUS.avertissementProvisoireUSGS : nil }
}

// MARK: NWS

public struct AlerteNWS: Sendable, Equatable, Hashable, Codable {
    public var id: String
    /// « Flood Warning », « Severe Thunderstorm Warning »…
    public var evenement: String
    /// « Minor », « Moderate », « Severe », « Extreme », « Unknown ».
    public var gravite: String
    public var urgence: String?
    public var certitude: String?
    public var titre: String?
    public var description: String?
    public var consigne: String?
    public var zone: String?
    public var emetteur: String?
    public var debut: Date?
    public var fin: Date?
    public var expire: Date?
    public var attribution: String

    public init(id: String, evenement: String, gravite: String, urgence: String? = nil, certitude: String? = nil, titre: String? = nil,
                description: String? = nil, consigne: String? = nil, zone: String? = nil, emetteur: String? = nil, debut: Date? = nil,
                fin: Date? = nil, expire: Date? = nil, attribution: String = AttributionUS.nws) {
        self.id = id
        self.evenement = evenement
        self.gravite = gravite
        self.urgence = urgence
        self.certitude = certitude
        self.titre = titre
        self.description = description
        self.consigne = consigne
        self.zone = zone
        self.emetteur = emetteur
        self.debut = debut
        self.fin = fin
        self.expire = expire
        self.attribution = attribution
    }
}

// MARK: NWPS

public enum CategorieCrueNWPS: String, Sendable, Equatable, Hashable, Codable {
    case pasDeCrue = "no_flooding"
    case action
    case mineure = "minor"
    case moderee = "moderate"
    case majeure = "major"
    case inconnue
}

/// Un point de la courbe observée ou prévue. Hauteur en pieds, débit en milliers de ft³/s (kcfs) comme NWPS le donne ; `nil` si absent (-999).
public struct PointCrueNWPS: Sendable, Equatable, Hashable, Codable {
    public var heure: Date
    public var hauteurPieds: Double?
    public var debitKcfs: Double?

    public init(heure: Date, hauteurPieds: Double?, debitKcfs: Double?) {
        self.heure = heure
        self.hauteurPieds = hauteurPieds
        self.debitKcfs = debitKcfs
    }
}

/// Seuils de crue d'une station, en pieds (`nil` si non définis : « Flood Category Not Defined »).
public struct SeuilsCrueNWPS: Sendable, Equatable, Hashable, Codable {
    public var actionPieds: Double?
    public var mineurePieds: Double?
    public var modereePieds: Double?
    public var majeurePieds: Double?

    public init(actionPieds: Double? = nil, mineurePieds: Double? = nil, modereePieds: Double? = nil, majeurePieds: Double? = nil) {
        self.actionPieds = actionPieds
        self.mineurePieds = mineurePieds
        self.modereePieds = modereePieds
        self.majeurePieds = majeurePieds
    }
}

/// Prévision de crue d'une station NWS : état actuel, seuils, courbes observée et prévue.
public struct PrevisionCrueNWPS: Sendable, Equatable, Hashable, Codable {
    /// Identifiant NWS de 5 caractères (« WASD2 »).
    public var identifiant: String
    public var nom: String
    /// Identifiant USGS lié, s'il existe.
    public var usgsId: String?
    public var latitude: Double?
    public var longitude: Double?
    public var categorieObservee: CategorieCrueNWPS
    public var categoriePrevue: CategorieCrueNWPS
    public var seuils: SeuilsCrueNWPS
    public var observee: [PointCrueNWPS]
    public var prevue: [PointCrueNWPS]
    public var emisePrevision: Date?
    public var attribution: String

    public init(identifiant: String, nom: String, usgsId: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
                categorieObservee: CategorieCrueNWPS = .inconnue, categoriePrevue: CategorieCrueNWPS = .inconnue, seuils: SeuilsCrueNWPS = SeuilsCrueNWPS(),
                observee: [PointCrueNWPS] = [], prevue: [PointCrueNWPS] = [], emisePrevision: Date? = nil, attribution: String = AttributionUS.nwps) {
        self.identifiant = identifiant
        self.nom = nom
        self.usgsId = usgsId
        self.latitude = latitude
        self.longitude = longitude
        self.categorieObservee = categorieObservee
        self.categoriePrevue = categoriePrevue
        self.seuils = seuils
        self.observee = observee
        self.prevue = prevue
        self.emisePrevision = emisePrevision
        self.attribution = attribution
    }
}
