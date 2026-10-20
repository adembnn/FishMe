import Foundation
import Combine
import Core

/// Garde la dernière lecture de chaque spot et rend un instantané pour une prise.
/// WeatherKit reçoit le point de `pointMeteo(spot:)`, Hub'Eau le seul code de `stationHydro(pres:)`.
@MainActor
final class ConditionsDuSpot: ObservableObject {
    static let dureeCache: TimeInterval = 30 * 60
    static let ageMaxInstantane: TimeInterval = 60 * 60

    @Published private(set) var lectures: [Coordonnee: LectureConditions] = [:]
    /// Pourquoi la dernière lecture de météo a échoué (`nil` : elle a réussi ou n'a pas encore eu lieu).
    private(set) var derniereCause: CauseMeteo?

    private let meteo: any SourceMeteo
    private let eau: any NiveauEauService
    private let noyau: any ServiceConditions
    private let maintenant: @Sendable () -> Date
    private let fichier: URL?

    init(meteo: any SourceMeteo, eau: any NiveauEauService, noyau: any ServiceConditions,
         maintenant: @escaping @Sendable () -> Date = { Date() }, fichier: URL? = ConditionsDuSpot.fichierParDefaut()) {
        self.meteo = meteo
        self.eau = eau
        self.noyau = noyau
        self.maintenant = maintenant
        self.fichier = fichier
        charger()
    }

    /// La dernière lecture connue, sans réseau. Le spot exact ne sert qu'à retrouver son point arrondi.
    func derniere(spot: Coordonnee) -> LectureConditions? {
        lectures[noyau.pointMeteo(spot: spot)]
    }

    /// Lit (au plus une fois par 30 min et par spot). Sans réseau : la dernière lecture marquée « cache », ou `nil`.
    @discardableResult
    func lire(spot: Coordonnee, forcer: Bool = false) async -> LectureConditions? {
        let point = noyau.pointMeteo(spot: spot)
        let now = maintenant()
        if !forcer, let l = lectures[point], !l.depuisCache, now.timeIntervalSince(l.lueLe) < Self.dureeCache { return l }

        let niveauLu: NiveauEau?
        if let station = noyau.stationHydro(pres: spot) {
            niveauLu = await eau.niveau(station: station)
        } else {
            niveauLu = nil
        }
        let brute: MeteoBrute?
        do {
            brute = try await meteo.meteo(point: point, de: now.addingTimeInterval(-6 * 3600),
                                          a: now.addingTimeInterval(7 * 86_400))
            derniereCause = nil
        } catch {
            brute = nil
            derniereCause = CauseMeteo.depuis(error)
        }

        guard let brute else {
            guard var ancienne = lectures[point] else { return nil }
            ancienne.depuisCache = true
            lectures[point] = ancienne
            return ancienne
        }
        let lecture = LectureConditions(
            point: point,
            conditions: noyau.lireConditions(meteo: brute, eau: niveauLu, date: now),
            meteo: brute, eau: niveauLu,
            alerte: noyau.alerte(meteo: brute, eau: niveauLu),
            lueLe: now)
        lectures[point] = lecture
        enregistrer()
        return lecture
    }

    /// Instantané pour une prise ou un départ de session : lecture de moins de 60 min, sinon rien.
    func instantane(spot: Coordonnee) -> Conditions? {
        guard let l = derniere(spot: spot), !l.depuisCache,
              maintenant().timeIntervalSince(l.lueLe) < Self.ageMaxInstantane else { return nil }
        return l.conditions
    }

    // MARK: stockage sur l'iPhone

    nonisolated static func fichierParDefaut() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("conditions-lectures.json")
    }

    private func charger() {
        guard let fichier, let data = try? Data(contentsOf: fichier),
              let liste = try? JSONDecoder().decode([LectureConditions].self, from: data) else { return }
        for var l in liste {
            l.depuisCache = true
            lectures[l.point] = l
        }
    }

    private func enregistrer() {
        guard let fichier, let data = try? JSONEncoder().encode(Array(lectures.values)) else { return }
        try? FileManager.default.createDirectory(at: fichier.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fichier, options: .atomic)
    }
}
