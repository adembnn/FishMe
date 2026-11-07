import Foundation

// Clients protocolaires : ils construisent l'URL, lisent la réponse, ne gardent rien sur disque.
// La position du pêcheur n'y entre que sous deux formes : un identifiant de station, ou une `CelluleUS` arrondie.

private func motif(_ texte: String, _ regex: String) -> Bool { texte.range(of: regex, options: .regularExpression) != nil }

/// USGS Water Data OGC API (`api.waterdata.usgs.gov`). La clé api.data.gov n'est jamais écrite dans le code : elle est fournie à l'exécution
/// (ou gardée par le proxy `outils/us/proxy/`, auquel cas `ClientProxyFishMe` suffit).
public struct ClientUSGS: Sendable {
    public static let base = "https://api.waterdata.usgs.gov/ogcapi/v1"
    /// Les mesures arrivent environ toutes les 15 min : 5 min de cache.
    public static let dureeCache: TimeInterval = 300

    let lecteur: LecteurUS
    let base: String

    public init(transport: TransportUS = TransportURLSession(), base: String = ClientUSGS.base, cleAPI: String? = nil,
                userAgent: String = "FishMe/1.0 (contact via fishme app)", horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.base = base
        var h: [String: String] = [:]
        if let cleAPI, !cleAPI.isEmpty { h["X-Api-Key"] = cleAPI }
        self.lecteur = LecteurUS(transport: transport, userAgent: userAgent, enTetes: h, horloge: horloge)
    }

    public static func identifiantValide(_ id: String) -> Bool { motif(id, "^USGS-[0-9]{8,15}$") }

    /// Stations d'une cellule arrondie (collection `monitoring-locations`, filtre `bbox`).
    public func stations(dans cellule: CelluleUS, limite: Int = 50) async throws -> [StationUSGS] {
        guard let u = LecteurUS.url(base, "/collections/monitoring-locations/items", ["bbox": cellule.bbox, "f": "json", "limit": String(limite), "site_type_code": "ST"]) else { throw ErreurUS.reponseIllisible }
        return DecodageUS.stationsUSGS(try await lecteur.lire(u, accept: "application/geo+json", duree: 86400))
    }

    public func station(id: String) async throws -> StationUSGS? {
        guard Self.identifiantValide(id), let u = LecteurUS.url(base, "/collections/monitoring-locations/items", ["id": id, "f": "json"]) else { throw ErreurUS.identifiantInvalide }
        return DecodageUS.stationsUSGS(try await lecteur.lire(u, accept: "application/geo+json", duree: 86400)).first
    }

    /// Dernière valeur de chaque série (collection `latest-continuous`).
    public func dernieresMesures(stationId: String, parametres: [ParametreUSGS] = ParametreUSGS.allCases) async throws -> [MesureUSGS] {
        guard Self.identifiantValide(stationId),
              let u = LecteurUS.url(base, "/collections/latest-continuous/items", ["monitoring_location_id": stationId, "parameter_code": parametres.map(\.rawValue).joined(separator: ","), "f": "json", "limit": "50"])
        else { throw ErreurUS.identifiantInvalide }
        return DecodageUS.mesuresUSGS(try await lecteur.lire(u, accept: "application/geo+json", duree: Self.dureeCache))
    }

    /// Série récente (collection `continuous`). `duree` en durée ISO 8601 (« P2D »).
    public func serie(stationId: String, parametre: ParametreUSGS, duree: String = "P2D") async throws -> [MesureUSGS] {
        guard Self.identifiantValide(stationId), motif(duree, "^P[0-9]{1,3}D$"),
              let u = LecteurUS.url(base, "/collections/continuous/items", ["monitoring_location_id": stationId, "parameter_code": parametre.rawValue, "datetime": duree, "f": "json", "limit": "1000"])
        else { throw ErreurUS.identifiantInvalide }
        return DecodageUS.mesuresUSGS(try await lecteur.lire(u, accept: "application/geo+json", duree: Self.dureeCache)).sorted { $0.heure < $1.heure }
    }
}

/// Le proxy FishMe (`outils/us/proxy/`) : il garde la clé api.data.gov et met en cache par station. Seul un identifiant de station lui est envoyé.
public struct ClientProxyFishMe: Sendable {
    let lecteur: LecteurUS
    let base: String

    public init(base: String, transport: TransportUS = TransportURLSession(), userAgent: String = "FishMe/1.0", horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.base = base.hasSuffix("/") ? String(base.dropLast()) : base
        self.lecteur = LecteurUS(transport: transport, userAgent: userAgent, horloge: horloge)
    }

    /// Mêmes mesures que `ClientUSGS.dernieresMesures` (le proxy renvoie le GeoJSON USGS tel quel, avec un bloc `fishme` d'attribution).
    public func mesures(stationId: String) async throws -> [MesureUSGS] {
        guard ClientUSGS.identifiantValide(stationId), let u = LecteurUS.url(base, "/station/\(stationId)", [:]) else { throw ErreurUS.identifiantInvalide }
        return DecodageUS.mesuresUSGS(try await lecteur.lire(u, accept: "application/json", duree: ClientUSGS.dureeCache))
    }
}

/// NWS api.weather.gov : sans clé, mais un User-Agent qui identifie l'app est obligatoire.
public struct ClientNWS: Sendable {
    public static let base = "https://api.weather.gov"
    public static let dureeCache: TimeInterval = 120

    let lecteur: LecteurUS
    let base: String

    public init(transport: TransportUS = TransportURLSession(), base: String = ClientNWS.base,
                userAgent: String = "FishMe/1.0 (contact via fishme app)", horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.base = base
        self.lecteur = LecteurUS(transport: transport, userAgent: userAgent, horloge: horloge)
    }

    /// Alertes en cours dans un État (code postal à deux lettres).
    public func alertesActives(etat: String) async throws -> [AlerteNWS] {
        let e = etat.uppercased()
        guard motif(e, "^[A-Z]{2}$"), let u = LecteurUS.url(base, "/alerts/active", ["area": e]) else { throw ErreurUS.identifiantInvalide }
        return DecodageUS.alertesNWS(try await lecteur.lire(u, accept: "application/geo+json", duree: Self.dureeCache))
    }

    /// Alertes sur le centre d'une cellule arrondie : la position exacte n'est jamais envoyée.
    public func alertesActives(cellule: CelluleUS) async throws -> [AlerteNWS] {
        let point = String(format: "%.2f,%.2f", cellule.latitude + CelluleUS.pas / 2, cellule.longitude + CelluleUS.pas / 2)
        guard let u = LecteurUS.url(base, "/alerts/active", ["point": point]) else { throw ErreurUS.identifiantInvalide }
        return DecodageUS.alertesNWS(try await lecteur.lire(u, accept: "application/geo+json", duree: Self.dureeCache))
    }
}

/// NWPS (`api.water.noaa.gov/nwps/v1`) : seuils et prévisions de crue des stations NWS.
public struct ClientNWPS: Sendable {
    public static let base = "https://api.water.noaa.gov/nwps/v1"
    public static let dureeCache: TimeInterval = 600

    let lecteur: LecteurUS
    let base: String

    public init(transport: TransportUS = TransportURLSession(), base: String = ClientNWPS.base,
                userAgent: String = "FishMe/1.0 (contact via fishme app)", horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.base = base
        self.lecteur = LecteurUS(transport: transport, userAgent: userAgent, horloge: horloge)
    }

    /// `identifiant` : l'identifiant NWS de la station (5 caractères, « WASD2 »). Les courbes sont facultatives : sans elles, seuils et catégories restent.
    public func prevision(identifiant: String) async throws -> PrevisionCrueNWPS? {
        let id = identifiant.uppercased()
        guard motif(id, "^[A-Z0-9]{5}$"), let g = LecteurUS.url(base, "/gauges/\(id)", [:]), let s = LecteurUS.url(base, "/gauges/\(id)/stageflow", [:]) else { throw ErreurUS.identifiantInvalide }
        let gauge = try await lecteur.lire(g, accept: "application/json", duree: Self.dureeCache)
        let courbes = try? await lecteur.lire(s, accept: "application/json", duree: Self.dureeCache)
        return DecodageUS.previsionCrueNWPS(gauge: gauge, stageflow: courbes)
    }
}
