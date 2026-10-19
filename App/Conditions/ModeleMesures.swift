import Foundation
import Combine
import Core

/// Charge la température de l'eau (Hub'Eau, par le seul code de la station) et rend les mesures de N3 pour une lecture.
/// Le calcul des tendances, le choix de la station et la fraîcheur sont dans `Core` (`ServiceMesures`) : ici, rien ne se calcule.
@MainActor
final class ModeleMesures: ObservableObject {
    static let dureeCache: TimeInterval = 30 * 60

    @Published private(set) var temperatures: [String: TemperatureEau] = [:]

    private let service: any TemperatureEauService
    private let noyau: any ServiceMesures
    private let maintenant: @Sendable () -> Date
    private let fichier: URL?
    /// Dernière lecture réseau de chaque station (code seulement, jamais une coordonnée).
    private var luesLe: [String: Date] = [:]

    init(service: any TemperatureEauService, noyau: any ServiceMesures,
         maintenant: @escaping @Sendable () -> Date = { Date() }, fichier: URL? = ModeleMesures.fichierParDefaut()) {
        self.service = service
        self.noyau = noyau
        self.maintenant = maintenant
        self.fichier = fichier
        charger()
    }

    /// Lit la température de la station la plus proche, au plus une fois par 30 min et par station.
    /// Sans station, sans réseau ou sans mesure : on garde la dernière valeur connue (avec son heure de mesure d'origine), sinon rien.
    func charger(spot: Coordonnee, eau: StationHydro?) async {
        guard let station = noyau.stationTemperature(pres: spot, eau: eau) else { return }
        let now = maintenant()
        if let derniere = luesLe[station.code], now.timeIntervalSince(derniere) < Self.dureeCache, temperatures[station.code] != nil { return }
        luesLe[station.code] = now
        if var lue = await service.temperature(station: station) {
            lue.station.distanceM = nil  // la distance au spot ne se garde pas sur disque
            temperatures[station.code] = lue
            enregistrer()
        }
    }

    /// La température connue pour ce spot (lue, ou gardée en cache), ou `nil` : alors aucune ligne « Eau ».
    func temperature(spot: Coordonnee, eau: StationHydro?) -> TemperatureEau? {
        guard let station = noyau.stationTemperature(pres: spot, eau: eau), var t = temperatures[station.code] else { return nil }
        t.station.distanceM = station.distanceM
        return t
    }

    /// Les mesures à afficher, dans l'ordre de `Core` : pression, eau, débit.
    func mesures(lecture: LectureConditions, spot: Coordonnee, date: Date? = nil) -> [MesureSourcee] {
        noyau.mesures(conditions: lecture.conditions, eau: lecture.eau,
                      temperature: temperature(spot: spot, eau: lecture.eau?.station), date: date ?? maintenant())
    }

    // MARK: stockage sur l'iPhone

    nonisolated static func fichierParDefaut() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("mesures-temperature.json")
    }

    private func charger() {
        guard let fichier, let data = try? Data(contentsOf: fichier),
              let liste = try? JSONDecoder().decode([TemperatureEau].self, from: data) else { return }
        for t in liste { temperatures[t.station.code] = t }
    }

    private func enregistrer() {
        guard let fichier, let data = try? JSONEncoder().encode(Array(temperatures.values)) else { return }
        try? FileManager.default.createDirectory(at: fichier.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fichier, options: .atomic)
    }
}
