import Core
import Foundation

/// Conversions d'affichage des conditions (vent, pression, pluie, eau). Les valeurs restent stockées en unités SI / usuelles
/// françaises (km/h, hPa, mm, m, m³/s, °C) ; seule la mise en forme change selon la région. Aucune règle de pêche ici.
nonisolated enum UnitesConditions {
    static func imperial(_ region: RegionApp) -> Bool { region == .etatsUnis }

    static func milesParHeure(kmh: Double) -> Double { kmh * 0.621371 }
    static func pouces(mercureDepuisHPa hPa: Double) -> Double { hPa * 0.0295300 }
    static func pouces(mm: Double) -> Double { mm * 0.0393701 }
    static func pieds(metres: Double) -> Double { metres * 3.28084 }
    static func piedsCubesParSeconde(m3s: Double) -> Double { m3s * 35.3147 }
    static func fahrenheit(celsius: Double) -> Double { celsius * 9 / 5 + 32 }
    /// Un écart de température se convertit sans le décalage de 32.
    static func ecartFahrenheit(celsius: Double) -> Double { celsius * 9 / 5 }
}
