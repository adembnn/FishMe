#if DEBUG
import Foundation
import Core

/// Faux sources, sous #if DEBUG : rien de factice dans le build envoyé à Apple.
nonisolated struct SourceMeteoFaux: SourceMeteo {
    var meteoRendue: MeteoBrute?

    init(meteoRendue: MeteoBrute? = SourceMeteoFaux.exemple(debut: Date(timeIntervalSince1970: 1_760_000_000))) {
        self.meteoRendue = meteoRendue
    }

    func meteo(point: Coordonnee, de: Date, a: Date) async throws -> MeteoBrute {
        guard let m = meteoRendue else { throw ErreurConditions.indisponible }
        return m
    }

    static func exemple(debut: Date) -> MeteoBrute {
        let heures = (-6..<168).map { i in
            PointMeteo(heure: debut.addingTimeInterval(Double(i) * 3600), ventKmh: 12 - Double(i % 6), rafalesKmh: 20,
                       directionDeg: 270, pluieMm: 0, pressionHPa: 1015 - Double(i) / 12, temperatureC: 14, codeTemps: 2)
        }
        return MeteoBrute(heures: heures)
    }
}

nonisolated struct SourceMarqueFaux: SourceMarque {
    func marque() async -> MarqueApple? {
        MarqueApple(nom: "Apple Weather", claireURL: URL(string: "https://example.invalid/claire.png")!,
                    sombreURL: URL(string: "https://example.invalid/sombre.png")!,
                    legaleURL: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!)
    }
}

/// Garde ce qui lui est demandé, pour vérifier ce qui part vers WeatherKit et Hub'Eau.
actor EnregistreurRequetes {
    private(set) var pointsMeteo: [Coordonnee] = []
    private(set) var codesStation: [String] = []
    func meteo(_ p: Coordonnee) { pointsMeteo.append(p) }
    func station(_ c: String) { codesStation.append(c) }
}

nonisolated struct SourceMeteoEspion: SourceMeteo {
    let journal: EnregistreurRequetes
    func meteo(point: Coordonnee, de: Date, a: Date) async throws -> MeteoBrute {
        await journal.meteo(point)
        return SourceMeteoFaux.exemple(debut: de.addingTimeInterval(6 * 3600))
    }
}

nonisolated struct NiveauEauEspion: NiveauEauService {
    let journal: EnregistreurRequetes
    func niveau(station: StationHydro) async -> NiveauEau? {
        await journal.station(station.code)
        return await NiveauEauFaux().niveau(station: station)
    }
}

actor NotifieurFaux: Notifieur {
    private(set) var demandes = 0
    private(set) var programmees: [NotificationPrevue] = []
    var accorde = true
    func demanderPermission() async -> Bool { demandes += 1; return accorde }
    func remplacer(_ notifications: [NotificationPrevue]) async { programmees = notifications }
}
#endif
