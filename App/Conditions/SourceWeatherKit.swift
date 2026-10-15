import Foundation
import Core
#if canImport(WeatherKit)
import WeatherKit
import CoreLocation

/// Seul endroit de l'app qui lit WeatherKit. Un seul appel : les heures (de H-6 à H+7 j) et les alertes.
nonisolated struct SourceWeatherKit: SourceMeteo {
    init() {}

    func meteo(point: Coordonnee, de: Date, a: Date) async throws -> MeteoBrute {
        let lieu = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let (heures, alertes) = try await WeatherService.shared.weather(
            for: lieu, including: .hourly(startDate: de, endDate: a), .alerts)
        let points = heures.forecast.map { h in
            PointMeteo(
                heure: h.date,
                ventKmh: h.wind.speed.converted(to: .kilometersPerHour).value,
                rafalesKmh: h.wind.gust?.converted(to: .kilometersPerHour).value,
                directionDeg: h.wind.direction.converted(to: .degrees).value,
                pluieMm: h.precipitationAmount.converted(to: .millimeters).value,
                pressionHPa: h.pressure.converted(to: .hectopascals).value,
                temperatureC: h.temperature.converted(to: .celsius).value,
                codeTemps: SourceWeatherKit.code(h.condition))
        }
        let officielles = (alertes ?? []).map {
            AlerteOfficielle(texte: $0.summary, source: $0.source, debut: nil)
        }
        return MeteoBrute(heures: points, alertesOfficielles: officielles)
    }

    /// Code de temps au format WMO (0 dégagé, 2 nuageux, 3 couvert, 45 brouillard, 51 bruine, 61 pluie, 71 neige, 95 orage).
    static func code(_ c: WeatherCondition) -> Int {
        switch c {
        case .clear, .mostlyClear, .hot: return 0
        case .partlyCloudy: return 2
        case .mostlyCloudy, .cloudy: return 3
        case .foggy, .haze, .smoky: return 45
        case .drizzle, .freezingDrizzle: return 51
        case .rain, .sunShowers, .freezingRain, .sleet, .wintryMix: return 61
        case .heavyRain: return 65
        case .snow, .flurries, .sunFlurries, .heavySnow, .blowingSnow, .blizzard, .frigid: return 71
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms, .strongStorms, .hail: return 95
        default: return 3
        }
    }
}

/// La marque et le lien légal viennent de WeatherKit, jamais d'un texte écrit à la main.
nonisolated struct SourceMarqueWeatherKit: SourceMarque {
    init() {}

    func marque() async -> MarqueApple? {
        guard let a = try? await WeatherService.shared.attribution else { return nil }
        return MarqueApple(nom: a.serviceName, claireURL: a.combinedMarkLightURL,
                           sombreURL: a.combinedMarkDarkURL, legaleURL: a.legalPageURL)
    }
}
#endif
