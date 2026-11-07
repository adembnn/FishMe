import Foundation
import Core

/// Mise en forme seulement : aucune valeur n'est calculée ici, tout vient de `Core` ou de WeatherKit.
/// Chaque fonction suit la région (`RegionPersistee`) : France en unités métriques et heures sur 24 h, États-Unis en unités
/// américaines (mph, inHg, in, ft, °F) et dates mois/jour. Le paramètre `region` sert aux tests ; par défaut, la région active.
nonisolated enum FormatConditions {
    // Les formateurs coûtent cher à créer : un par (région, format), créés une fois puis gardés sous verrou.
    private static let verrou = NSLock()
    nonisolated(unsafe) private static var formateursDate: [String: DateFormatter] = [:]
    nonisolated(unsafe) private static var formateursNombre: [String: NumberFormatter] = [:]

    private static func fDate(_ format: String, _ region: RegionApp) -> DateFormatter {
        verrou.lock()
        defer { verrou.unlock() }
        let cle = "\(region.rawValue)|\(format)"
        if let f = formateursDate[cle] { return f }
        let f = DateFormatter()
        f.locale = region.locale
        f.dateFormat = format
        formateursDate[cle] = f
        return f
    }

    private static func fNombre(_ decimales: Int, _ region: RegionApp) -> NumberFormatter {
        verrou.lock()
        defer { verrou.unlock() }
        let cle = "\(region.rawValue)|\(decimales)"
        if let f = formateursNombre[cle] { return f }
        let f = NumberFormatter()
        f.locale = region.locale
        f.minimumFractionDigits = decimales
        f.maximumFractionDigits = decimales
        formateursNombre[cle] = f
        return f
    }

    private static func us(_ region: RegionApp) -> Bool { region == .etatsUnis }

    /// « 18 h 05 » (France) ou « 6:05 PM » (États-Unis).
    static func heure(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        fDate(us(region) ? "h:mm a" : "H 'h' mm", region).string(from: date)
    }

    /// « lun. 18 h 05 » ou « Mon, Nov 9, 6:05 PM ».
    static func jourHeure(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        fDate(us(region) ? "EEE, MMM d, h:mm a" : "EEE d MMM, H 'h' mm", region).string(from: date)
    }

    /// « lundi 9 nov. » ou « Monday, Nov 9 ».
    static func jour(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        fDate(us(region) ? "EEEE, MMM d" : "EEEE d MMM", region).string(from: date)
    }

    /// « 08:02 » ou « 8:02 AM ».
    static func horloge(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        fDate(us(region) ? "h:mm a" : "HH:mm", region).string(from: date)
    }

    /// « Auj. » pour aujourd'hui, sinon « Mar. », « Mer. »… (« Today », « Tue »… aux États-Unis).
    static func jourCourt(_ date: Date, aujourdhui: Date = Date(), region: RegionApp = RegionPersistee.lire()) -> String {
        if Calendar.current.isDate(date, inSameDayAs: aujourdhui) { return us(region) ? "Today" : "Auj." }
        let court = fDate("EEE", region).string(from: date)
        return court.prefix(1).uppercased() + court.dropFirst()
    }

    /// Mot court d'un code de temps au format WMO (« Nuageux »).
    static func libelle(codeTemps: Int, region: RegionApp = RegionPersistee.lire()) -> String {
        if us(region) {
            switch codeTemps {
            case 0: return "Clear"
            case 1, 2: return "Partly cloudy"
            case 45...48: return "Fog"
            case 51...57: return "Drizzle"
            case 61...67, 80...82: return "Rain"
            case 71...77, 85, 86: return "Snow"
            case 95...99: return "Thunderstorm"
            default: return "Cloudy"
            }
        }
        switch codeTemps {
        case 0: return "Dégagé"
        case 1, 2: return "Éclaircies"
        case 45...48: return "Brouillard"
        case 51...57: return "Bruine"
        case 61...67, 80...82: return "Pluie"
        case 71...77, 85, 86: return "Neige"
        case 95...99: return "Orage"
        default: return "Nuageux"
        }
    }

    static func nombre(_ v: Double, decimales: Int = 0, region: RegionApp = RegionPersistee.lire()) -> String {
        fNombre(decimales, region).string(from: NSNumber(value: v)) ?? "\(v)"
    }

    // MARK: Valeurs et unités selon la région

    /// Température sans unité : « 12° » (°C) ou « 54° » (°F).
    static func degres(celsius: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        let v = us(region) ? UnitesConditions.fahrenheit(celsius: celsius) : celsius
        return "\(nombre(v, region: region))°"
    }

    /// « 12 km/h » ou « 7 mph ».
    static func vent(kmh: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? "\(nombre(UnitesConditions.milesParHeure(kmh: kmh), region: region)) mph" : "\(nombre(kmh, region: region)) km/h"
    }

    /// Le nombre seul, et l'unité seule, pour les cartes qui les écrivent séparément.
    static func ventValeur(kmh: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        nombre(us(region) ? UnitesConditions.milesParHeure(kmh: kmh) : kmh, region: region)
    }
    static func uniteVent(region: RegionApp = RegionPersistee.lire()) -> String { us(region) ? "mph" : "km/h" }

    /// Pluie cumulée : « 1,2 mm » ou « 0.05 in ».
    static func pluieValeur(mm: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? nombre(UnitesConditions.pouces(mm: mm), decimales: 2, region: region)
                   : nombre(mm, decimales: mm < 10 ? 1 : 0, region: region)
    }
    static func unitePluie(region: RegionApp = RegionPersistee.lire()) -> String { us(region) ? "in" : "mm" }
    static func pluie(mm: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        "\(pluieValeur(mm: mm, region: region)) \(unitePluie(region: region))"
    }

    /// Pression : « 1012 hPa » ou « 29.88 inHg ».
    static func pressionValeur(hPa: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? nombre(UnitesConditions.pouces(mercureDepuisHPa: hPa), decimales: 2, region: region) : nombre(hPa, region: region)
    }
    static func unitePression(region: RegionApp = RegionPersistee.lire()) -> String { us(region) ? "inHg" : "hPa" }
    static func pression(hPa: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        "\(pressionValeur(hPa: hPa, region: region)) \(unitePression(region: region))"
    }

    /// « 1012 hPa ↘ −3 en 6 h » ; « 29.88 inHg ↘ −0.09 in 6 h » aux États-Unis.
    static func pression(_ hPa: Double, tendance: Double?, region: RegionApp = RegionPersistee.lire()) -> String {
        var s = pression(hPa: hPa, region: region)
        if let t = tendance {
            let fleche = t < -0.5 ? "↘" : (t > 0.5 ? "↗" : "→")
            let signe = t < 0 ? "−" : "+"
            s += " \(fleche) \(signe)\(ecartPression(hPa: abs(t), region: region)) \(us(region) ? "inHg in 6 h" : "en 6 h")"
        }
        return s
    }

    /// « en 6 h » ou « inHg in 6 h » : le bout de phrase qui suit un écart de pression.
    static func suffixe6h(region: RegionApp = RegionPersistee.lire()) -> String { us(region) ? "inHg in 6 h" : "en 6 h" }

    /// Un écart de pression : « 3 » ou « 0.09 » (sans unité).
    static func ecartPression(hPa: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? nombre(UnitesConditions.pouces(mercureDepuisHPa: hPa), decimales: 2, region: region) : nombre(hPa, region: region)
    }

    /// Hauteur d'eau : « 1,23 m » ou « 4.04 ft ».
    static func hauteurEau(metres: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? "\(nombre(UnitesConditions.pieds(metres: metres), decimales: 2, region: region)) ft"
                   : "\(nombre(metres, decimales: 2, region: region)) m"
    }

    /// Débit : « 18 m³/s » ou « 636 ft³/s ».
    static func debitEau(m3s: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? "\(nombre(UnitesConditions.piedsCubesParSeconde(m3s: m3s), region: region)) ft³/s"
                   : "\(nombre(m3s, region: region)) m³/s"
    }

    /// Message quand l'eau ne se lit pas : jamais une valeur inventée.
    static func eauIndisponible(region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? "Water data unavailable" : "Eau indisponible"
    }
    static func titreEau(region: RegionApp = RegionPersistee.lire()) -> String { us(region) ? "Water level" : "Niveau de l'eau" }

    /// Le nom de la source de l'eau affiché sous les jauges.
    static func sourceEau(region: RegionApp = RegionPersistee.lire()) -> String { us(region) ? "USGS" : "Hub’Eau" }

    /// « lu à 14 h 05, sans réseau » / « read at 2:05 PM, offline ».
    static func luSansReseau(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        us(region) ? "read at \(heure(date, region: region)), offline" : "lu à \(heure(date, region: region)), sans réseau"
    }

    /// Point cardinal d'une direction en degrés (« O », « NE » ; « W », « NE » aux États-Unis).
    static func cardinal(_ degres: Double, region: RegionApp = RegionPersistee.lire()) -> String {
        let noms = us(region) ? ["N", "NE", "E", "SE", "S", "SW", "W", "NW"] : ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
        guard degres.isFinite else { return "" }
        let i = Int(((degres.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) + 22.5) / 45) % 8
        return noms[i]
    }

    /// Symbole SF d'un code de temps au format WMO.
    static func symbole(codeTemps: Int) -> String {
        switch codeTemps {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 45...48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61...67, 80...82: return "cloud.rain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "cloud.fill"
        }
    }

    /// Le point de la prévision le plus proche de l'heure donnée : une lecture, pas un calcul.
    static func pointLePlusProche(_ meteo: MeteoBrute, de date: Date) -> PointMeteo? {
        meteo.heures.min { abs($0.heure.timeIntervalSince(date)) < abs($1.heure.timeIntervalSince(date)) }
    }
}
