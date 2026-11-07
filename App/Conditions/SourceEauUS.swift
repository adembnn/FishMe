import Core
import Foundation

/// Où est le proxy FishMe (`outils/us/proxy/`). L'adresse n'est jamais écrite dans le code ni dans git : elle vient, dans cet ordre,
/// de la variable d'environnement `FISHME_US_PROXY_URL` (essais), du réglage `us.proxy.url`, puis de la clé Info `FishMeProxyUSURL`.
/// La clé de l'API USGS reste sur le proxy (`wrangler secret`), l'app n'en a jamais. Sans adresse : aucune requête, « eau indisponible ».
nonisolated enum ConfigProxyUS {
    static func url(env: [String: String] = ProcessInfo.processInfo.environment, reglages: UserDefaults = .standard,
                    bundle: Bundle = .main) -> String? {
        let brute = env["FISHME_US_PROXY_URL"] ?? reglages.string(forKey: "us.proxy.url")
            ?? bundle.object(forInfoDictionaryKey: "FishMeProxyUSURL") as? String
        guard let texte = brute?.trimmingCharacters(in: .whitespacesAndNewlines), !texte.isEmpty,
              let u = URL(string: texte), let h = u.host, !h.isEmpty else { return nil }
        // https obligatoire, sauf pour un proxy local d'essai.
        let local = h == "localhost" || h == "127.0.0.1"
        guard u.scheme == "https" || (u.scheme == "http" && local) else { return nil }
        return texte
    }
}

/// Ce que l'USGS rend pour un spot américain : le niveau de l'eau (hauteur, débit) et sa température. Chaque champ peut manquer.
nonisolated struct LectureEauUS: Sendable, Equatable {
    var niveau: NiveauEau?
    var temperature: TemperatureEau?
}

/// Eau des États-Unis : station USGS la plus proche, lue par le proxy FishMe. Remplace Hub'Eau en région US.
/// Vie privée : seule une cellule de 0,1° (environ 11 km) part vers l'USGS pour chercher la station ; le proxy ne reçoit qu'un identifiant de station.
/// Honnêteté : sans proxy, sans station ou sans réponse, la lecture est vide (rien d'inventé) ; l'écran écrit alors « eau indisponible ».
nonisolated final class SourceEauUS: @unchecked Sendable {
    static let partage = SourceEauUS()

    private let proxy: ClientProxyFishMe?
    private let usgs: ClientUSGS
    private let verrou = NSLock()
    private var memoire: [CelluleUS: (lue: Date, lecture: LectureEauUS)] = [:]
    private let maintenant: @Sendable () -> Date
    static let dureeMemoire: TimeInterval = 300

    init(proxyURL: String? = ConfigProxyUS.url(), transport: TransportUS = TransportURLSession(),
         maintenant: @escaping @Sendable () -> Date = { Date() }) {
        self.proxy = proxyURL.map { ClientProxyFishMe(base: $0, transport: transport) }
        self.usgs = ClientUSGS(transport: transport)
        self.maintenant = maintenant
    }

    var configure: Bool { proxy != nil }

    /// La lecture du spot (mémoire de 5 min par cellule : les mesures USGS arrivent environ tous les quarts d'heure).
    func lecture(pres spot: Coordonnee) async -> LectureEauUS {
        guard let proxy else { return LectureEauUS() }
        let cellule = CelluleUS(latitude: spot.latitude, longitude: spot.longitude)
        let now = maintenant()
        verrou.lock()
        let connue = memoire[cellule]
        verrou.unlock()
        if let connue, now.timeIntervalSince(connue.lue) < Self.dureeMemoire { return connue.lecture }

        var lecture = LectureEauUS()
        for station in await stationsProches(spot: spot, cellule: cellule).prefix(3) {
            guard let mesures = try? await proxy.mesures(stationId: station.id), !mesures.isEmpty else { continue }
            lecture = Self.lecture(station: station, mesures: mesures, spot: spot)
            if lecture.niveau != nil || lecture.temperature != nil { break }
        }
        if lecture.niveau != nil || lecture.temperature != nil {
            verrou.lock()
            memoire[cellule] = (now, lecture)
            verrou.unlock()
        }
        return lecture
    }

    /// Les stations de la cellule du spot, sinon de ses quatre voisines, de la plus proche à la plus lointaine.
    private func stationsProches(spot: Coordonnee, cellule: CelluleUS) async -> [StationUSGS] {
        var trouvees: [StationUSGS] = []
        let pas = CelluleUS.pas
        let voisines = [cellule,
                        CelluleUS(latitude: cellule.latitude + pas + pas / 2, longitude: cellule.longitude),
                        CelluleUS(latitude: cellule.latitude - pas / 2, longitude: cellule.longitude),
                        CelluleUS(latitude: cellule.latitude, longitude: cellule.longitude + pas + pas / 2),
                        CelluleUS(latitude: cellule.latitude, longitude: cellule.longitude - pas / 2)]
        for c in voisines {
            if let liste = try? await usgs.stations(dans: c), !liste.isEmpty { trouvees = liste; break }
        }
        return trouvees.filter { $0.latitude != nil && $0.longitude != nil }
            .sorted { Self.distanceM($0, spot) < Self.distanceM($1, spot) }
    }

    static func distanceM(_ s: StationUSGS, _ p: Coordonnee) -> Double {
        guard let la = s.latitude, let lo = s.longitude else { return .infinity }
        let dLat = (la - p.latitude) * 111_320
        let dLon = (lo - p.longitude) * 111_320 * cos(p.latitude * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot()
    }

    // MARK: conversion (pure, testée)

    static let metresParPied = 0.3048
    static let m3sParPiedCube = 0.028316846592

    /// Mesures USGS (unités de la source) vers les modèles de `Core` (unités SI). On garde la mesure la plus récente de chaque paramètre.
    static func lecture(station: StationUSGS, mesures: [MesureUSGS], spot: Coordonnee? = nil) -> LectureEauUS {
        func derniere(_ p: ParametreUSGS) -> MesureUSGS? { mesures.filter { $0.parametre == p }.max { $0.heure < $1.heure } }
        let coord = Coordonnee(latitude: station.latitude ?? spot?.latitude ?? 0, longitude: station.longitude ?? spot?.longitude ?? 0)
        let hauteur = derniere(.hauteur).flatMap { m -> Double? in
            switch m.unite {
            case .pied: return m.valeur * metresParPied
            case .metre: return m.valeur
            default: return nil
            }
        }
        let debit = derniere(.debit).flatMap { m -> Double? in
            switch m.unite {
            case .piedCubeParSeconde: return m.valeur * m3sParPiedCube
            case .metreCubeParSeconde: return m.valeur
            default: return nil
            }
        }
        var lecture = LectureEauUS()
        if hauteur != nil || debit != nil {
            let heure = [derniere(.hauteur)?.heure, derniere(.debit)?.heure].compactMap { $0 }.max() ?? Date()
            let stationHydro = StationHydro(code: station.id, nom: station.nom, eau: nil, coordonnee: coord)
            lecture.niveau = NiveauEau(station: stationHydro, hauteurM: hauteur, debitM3s: debit, heureMesure: heure)
        }
        if let t = derniere(.temperatureEau), t.unite == .degreCelsius {
            let st = StationTemperature(code: station.id, nom: station.nom, eau: nil, coordonnee: coord,
                                        distanceM: spot.map { distanceM(station, $0) })
            lecture.temperature = TemperatureEau(station: st, celsius: t.valeur, heureMesure: t.heure)
        }
        return lecture
    }
}
