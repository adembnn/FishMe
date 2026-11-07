import Foundation
import Core

/// Mise en forme des mesures de N3 : aucune valeur n'est calculée ici, tout vient de `ServiceMesures` (Core).
nonisolated enum FormatMesures {
    private static let verrou = NSLock()
    nonisolated(unsafe) private static var formateurs: [RegionApp: DateFormatter] = [:]

    /// « 12 oct. » ou « Oct 12 ».
    static func jour(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String {
        verrou.lock()
        defer { verrou.unlock() }
        let f: DateFormatter
        if let existant = formateurs[region] { f = existant } else {
            f = DateFormatter()
            f.locale = region.locale
            f.dateFormat = region == .etatsUnis ? "MMM d" : "d MMM"
            formateurs[region] = f
        }
        return f.string(from: date)
    }

    static func nom(_ g: Grandeur, region: RegionApp = RegionPersistee.lire()) -> String {
        if region == .etatsUnis {
            switch g {
            case .pression: return "Pressure"
            case .temperatureEau: return "Water"
            case .debit: return "Flow"
            }
        }
        switch g {
        case .pression: return "Pression"
        case .temperatureEau: return "Eau"
        case .debit: return "Débit"
        }
    }

    static func icone(_ g: Grandeur) -> String {
        switch g {
        case .pression: return "gauge.medium"
        case .temperatureEau: return "thermometer.medium"  // ⚠ à vérifier sur Mac : nom du symbole SF
        case .debit: return "water.waves"  // ⚠ à vérifier sur Mac : nom du symbole SF
        }
    }

    static func identifiant(_ g: Grandeur) -> String {
        switch g {
        case .pression: return "mesure-pression"
        case .temperatureEau: return "mesure-eau"
        case .debit: return "mesure-debit"
        }
    }

    /// « 1010 hPa », « 14,2 °C », « 18 m³/s » en France ; « 29.88 inHg », « 57.6 °F », « 636 ft³/s » aux États-Unis.
    static func valeur(_ m: MesureSourcee, region: RegionApp = RegionPersistee.lire()) -> String {
        guard region == .etatsUnis else {
            return "\(FormatConditions.nombre(m.valeur, decimales: decimales(m.grandeur, m.valeur), region: region)) \(m.unite)"
        }
        switch m.grandeur {
        case .pression:
            return FormatConditions.pression(hPa: m.valeur, region: region)
        case .temperatureEau:
            return "\(FormatConditions.nombre(UnitesConditions.fahrenheit(celsius: m.valeur), decimales: 1, region: region)) °F"
        case .debit:
            return FormatConditions.debitEau(m3s: m.valeur, region: region)
        }
    }

    private static func decimales(_ g: Grandeur, _ v: Double) -> Int {
        switch g {
        case .pression: return 0
        case .temperatureEau: return 1
        case .debit: return abs(v) < 10 ? 1 : 0
        }
    }

    /// « −3 hPa en 6 h », « +0,7 °C en 24 h » ; « −0.09 inHg in 6 h », « +1.3 °F in 24 h » aux États-Unis ; `nil` sans tendance.
    static func ecart(_ m: MesureSourcee, region: RegionApp = RegionPersistee.lire()) -> String? {
        guard let t = m.tendance else { return nil }
        let us = region == .etatsUnis
        var ecart = t.ecart
        var unite = m.unite
        var decimalesFixes: Int?
        if us {
            switch m.grandeur {
            case .pression: ecart = UnitesConditions.pouces(mercureDepuisHPa: ecart); unite = "inHg"; decimalesFixes = 2
            case .temperatureEau: ecart = UnitesConditions.ecartFahrenheit(celsius: ecart); unite = "°F"
            case .debit: ecart = UnitesConditions.piedsCubesParSeconde(m3s: ecart); unite = "ft³/s"
            }
        }
        let arrondi = decimalesFixes != nil ? (ecart * 100).rounded() / 100 : (ecart * 10).rounded() / 10
        let d = decimalesFixes ?? (arrondi == arrondi.rounded() ? 0 : 1)
        let signe = arrondi < 0 ? "−" : (arrondi > 0 ? "+" : "")
        let nombre = FormatConditions.nombre(abs(arrondi), decimales: d, region: region)
        return us ? "\(signe)\(nombre) \(unite) in \(t.surHeures) h" : "\(signe)\(nombre) \(unite) en \(t.surHeures) h"
    }

    /// Symbole de la flèche : jamais de couleur, une tendance n'est ni un bon ni un mauvais signe.
    static func fleche(_ s: SensTendance) -> String {
        switch s {
        case .hausse: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .baisse: return "arrow.down.right"
        }
    }

    static func sens(_ s: SensTendance) -> String {
        switch s {
        case .hausse: return "en hausse"
        case .stable: return "stable"
        case .baisse: return "en baisse"
        }
    }

    /// Le nom de la source tel que Core l'écrit (« Hub'Eau, station … ») ; aux États-Unis l'eau vient de l'USGS.
    static func source(_ m: MesureSourcee, region: RegionApp = RegionPersistee.lire()) -> String {
        region == .etatsUnis ? m.source.replacingOccurrences(of: "Hub'Eau", with: "USGS") : m.source
    }

    /// La ligne de légende : la source et l'heure. « Apple Weather · 14 h 05 », « … · prévu 16 h 05 »,
    /// « … · dernière mesure le 12 oct. » pour une mesure d'eau de plus de 48 h.
    static func sourceEtHeure(_ m: MesureSourcee, region: RegionApp = RegionPersistee.lire()) -> String {
        let us = region == .etatsUnis
        let src = source(m, region: region)
        if m.fraicheur == .ancienne { return "\(src) · \(us ? "last reading" : "dernière mesure le") \(jour(m.heure, region: region))" }
        if m.prevue { return "\(src) · \(us ? "forecast" : "prévu") \(FormatConditions.heure(m.heure, region: region))" }
        return "\(src) · \(FormatConditions.heure(m.heure, region: region))"
    }

    /// Ce que VoiceOver lit pour une ligne.
    static func accessibilite(_ m: MesureSourcee, region: RegionApp = RegionPersistee.lire()) -> String {
        var s = "\(nom(m.grandeur)), \(valeur(m, region: region))"
        if let t = m.tendance, let e = ecart(m, region: region) { s += ", \(sens(t.sens)), \(e)" }
        return s + ", " + sourceEtHeure(m, region: region)
    }

    /// « lu à 14 h 05, sans réseau »
    static func luSansReseau(_ date: Date, region: RegionApp = RegionPersistee.lire()) -> String { FormatConditions.luSansReseau(date, region: region) }
}
