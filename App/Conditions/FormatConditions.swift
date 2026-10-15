import Foundation
import Core

/// Mise en forme seulement : aucune valeur n'est calculée ici, tout vient de `Core` ou de WeatherKit.
nonisolated enum FormatConditions {
    /// « 18 h 05 »
    static func heure(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "H 'h' mm"
        return f.string(from: date)
    }

    /// « lun. 18 h 05 »
    static func jourHeure(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEE d MMM, H 'h' mm"
        return f.string(from: date)
    }

    static func jour(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMM"
        return f.string(from: date)
    }

    static func nombre(_ v: Double, decimales: Int = 0) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.minimumFractionDigits = decimales
        f.maximumFractionDigits = decimales
        return f.string(from: NSNumber(value: v)) ?? "\(v)"
    }

    /// « 1012 hPa ↘ −3 en 6 h »
    static func pression(_ hPa: Double, tendance: Double?) -> String {
        var s = "\(nombre(hPa)) hPa"
        if let t = tendance {
            let fleche = t < -0.5 ? "↘" : (t > 0.5 ? "↗" : "→")
            let signe = t < 0 ? "−" : "+"
            s += " \(fleche) \(signe)\(nombre(abs(t))) en 6 h"
        }
        return s
    }

    /// Point cardinal d'une direction en degrés (« O », « NE »).
    static func cardinal(_ degres: Double) -> String {
        let noms = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
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
