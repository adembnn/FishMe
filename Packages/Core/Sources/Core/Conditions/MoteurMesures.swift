import Foundation

/// Une station du fichier `stations-temperature.json` (fabriqué par D2, jamais commité) : métadonnées seulement.
struct StationTemperatureDonnee: Sendable, Equatable {
    var station: StationTemperature
    var enService: Bool

    /// Un tableau, ou un objet avec la clé `stations`. Clés lues : `code`, `nom`, `eau`, `code_eau`, `lat`, `lon`, `en_service` (vrai si absent).
    static func decoder(_ donnees: Data) -> [StationTemperatureDonnee] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [] }
        let liste: [[String: Any]]
        if let l = json as? [[String: Any]] { liste = l } else if let o = json as? [String: Any], let l = o["stations"] as? [[String: Any]] { liste = l } else { return [] }
        return liste.compactMap { s in
            guard let code = s["code"] as? String, let lat = (s["lat"] as? NSNumber)?.doubleValue,
                  let lon = (s["lon"] as? NSNumber)?.doubleValue else { return nil }
            let station = StationTemperature(code: code, nom: (s["nom"] as? String) ?? code, eau: s["eau"] as? String,
                                             codeEau: (s["code_eau"] as? String) ?? (s["code_eau"] as? NSNumber)?.stringValue,
                                             coordonnee: Coordonnee(latitude: lat, longitude: lon))
            return StationTemperatureDonnee(station: station, enService: (s["en_service"] as? Bool) ?? true)
        }
    }
}

/// N3 : assemble les mesures (pression, eau, débit) avec leur tendance, et choisit la station de température d'un spot.
/// Tout est pur : Foundation seulement, testable sous Linux.
public struct MoteurMesures: ServiceMesures {
    /// Pression « stable » entre −2 et +2 hPa exclus, sur 6 h (par défaut, à confirmer par Adem).
    public static let pressionStableHPa = 2.0
    /// Température de l'eau « stable » sous 0,5 °C d'écart, sur 24 h (par défaut, à confirmer par Adem).
    public static let temperatureStableC = 0.5
    /// Débit « stable » sous 5 % de la valeur d'avant, sur 6 h (par défaut, à confirmer par Adem).
    public static let debitStableFraction = 0.05
    /// La mesure d'avant doit tomber à 2 h près de l'heure visée ; sinon pas de tendance (jamais « stable » par défaut).
    public static let toleranceReference: TimeInterval = 2 * 3600
    /// Une valeur lue à plus de 90 min de la date demandée est une valeur de prévision.
    public static let ecartPrevision: TimeInterval = 90 * 60
    /// Au-delà de 48 h, une mesure d'eau est « ancienne ».
    public static let ageRecent: TimeInterval = 48 * 3600
    /// Au-delà de 30 jours, une mesure d'eau n'est plus montrée.
    public static let ageMax: TimeInterval = 30 * 86_400
    /// Station de température : la plus proche à moins de 10 km, comme la station hydrométrique.
    public static let rayonStationTemperatureM = MoteurConditions.rayonStationHydroM

    let geo: MoteurGeo?
    let stations: [StationTemperatureDonnee]

    /// `stationsTemperature` : les octets de `stations-temperature.json` ; absent, le moteur n'a pas de station (aucune ligne « Eau »).
    public init(geo: MoteurGeo? = nil, stationsTemperature: Data? = nil) {
        self.geo = geo
        self.stations = stationsTemperature.map(StationTemperatureDonnee.decoder) ?? []
    }

    // MARK: Contrat

    public func mesures(conditions: Conditions, eau: NiveauEau?, temperature: TemperatureEau?, date: Date) -> [MesureSourcee] {
        var liste: [MesureSourcee] = []
        if let m = mesurePression(conditions, date: date) { liste.append(m) }
        if let t = temperature, let m = mesureTemperature(t, date: date) { liste.append(m) }
        if let e = eau, let m = mesureDebit(e, date: date) { liste.append(m) }
        return liste
    }

    public func stationTemperature(pres coordonnee: Coordonnee, eau: StationHydro?) -> StationTemperature? {
        let codeSpot = geo?.lieu(de: coordonnee, choix: nil).eau?.codeSandre
        let nomRef = eau?.eau.map(cleEau)
        var meilleure: (StationTemperature, Double)?
        for s in stations where s.enService {
            let d = Geodesie.distanceM(coordonnee, s.station.coordonnee)
            guard d <= Self.rayonStationTemperatureM else { continue }
            // Même eau seulement : le code Sandre quand on l'a des deux côtés, sinon le nom du cours d'eau.
            if let a = codeSpot, let b = s.station.codeEau {
                if a != b { continue }
            } else if let a = nomRef, let b = s.station.eau.map(cleEau), a != b {
                continue
            }
            if d < (meilleure?.1 ?? .infinity) { meilleure = (s.station, d) }
        }
        guard var choisie = meilleure?.0, let d = meilleure?.1 else { return nil }
        choisie.distanceM = d.arrondi(0)
        return choisie
    }

    // MARK: Fraîcheur

    /// `nil` au-delà de 30 jours : la mesure ne se montre plus.
    public static func fraicheur(heure: Date, date: Date) -> FraicheurMesure? {
        let age = date.timeIntervalSince(heure)
        if age > ageMax { return nil }
        return age > ageRecent ? .ancienne : .recente
    }

    // MARK: Tendances

    static func sens(ecart: Double, seuil: Double) -> SensTendance {
        let e = ecart.arrondi(6)
        if e >= seuil { return .hausse }
        if e <= -seuil { return .baisse }
        return .stable
    }

    /// La valeur la plus proche de `heure − heures`, à 2 h près, parmi les points strictement avant `heure`. `nil` sinon.
    static func valeurAvant(heure: Date, points: [(Date, Double)], heures: Int) -> Double? {
        let cible = heure.addingTimeInterval(-Double(heures) * 3600)
        let candidats = points.filter { $0.0 < heure && $0.1.isFinite }
        guard let p = candidats.min(by: { abs($0.0.timeIntervalSince(cible)) < abs($1.0.timeIntervalSince(cible)) }),
              abs(p.0.timeIntervalSince(cible)) <= toleranceReference else { return nil }
        return p.1
    }

    // MARK: Mesures

    private func mesurePression(_ c: Conditions, date: Date) -> MesureSourcee? {
        guard let p = c.pressionHPa, p.isFinite else { return nil }
        let heure = c.heurePression ?? c.heure
        var tendance: Tendance?
        if let t = c.tendancePressionHPa6h, t.isFinite {
            tendance = Tendance(sens: Self.sens(ecart: t, seuil: Self.pressionStableHPa), ecart: t, surHeures: 6)
        }
        return MesureSourcee(grandeur: .pression, valeur: p, unite: "hPa", heure: heure, source: "Apple Weather", tendance: tendance,
                             prevue: abs(heure.timeIntervalSince(date)) > Self.ecartPrevision)
    }

    private func mesureTemperature(_ t: TemperatureEau, date: Date) -> MesureSourcee? {
        guard t.celsius.isFinite, let fraicheur = Self.fraicheur(heure: t.heureMesure, date: date) else { return nil }
        var tendance: Tendance?
        let points = t.serie48h.map { ($0.heure, $0.celsius) }
        if let avant = Self.valeurAvant(heure: t.heureMesure, points: points, heures: 24) {
            let ecart = t.celsius - avant
            tendance = Tendance(sens: Self.sens(ecart: ecart, seuil: Self.temperatureStableC), ecart: ecart.arrondi(1), surHeures: 24)
        }
        var source = "Hub'Eau, station \(t.station.nom)"
        if let d = t.station.distanceM, d.isFinite { source += ", \(max(1, Int((d / 1000).rounded()))) km" }
        return MesureSourcee(grandeur: .temperatureEau, valeur: t.celsius, unite: "°C", heure: t.heureMesure, source: source,
                             tendance: tendance, fraicheur: fraicheur)
    }

    private func mesureDebit(_ e: NiveauEau, date: Date) -> MesureSourcee? {
        guard let q = e.debitM3s, q.isFinite else { return nil }
        let points: [(Date, Double)] = e.serie48h.compactMap { m in m.debitM3s.map { (m.heure, $0) } }.sorted { $0.0 < $1.0 }
        let heure = points.last?.0 ?? e.heureMesure
        guard let fraicheur = Self.fraicheur(heure: heure, date: date) else { return nil }
        var tendance: Tendance?
        if let avant = Self.valeurAvant(heure: heure, points: points, heures: 6), avant > 0 {
            let fraction = (q - avant) / avant
            tendance = Tendance(sens: Self.sens(ecart: fraction, seuil: Self.debitStableFraction), ecart: (q - avant).arrondi(3), surHeures: 6)
        }
        return MesureSourcee(grandeur: .debit, valeur: q, unite: "m³/s", heure: heure, source: "Hub'Eau, station \(e.station.nom)",
                             tendance: tendance, fraicheur: fraicheur)
    }
}

public extension MoteurConditions {
    /// Le moteur de mesures de N3, avec la géographie de ce moteur (pour « même eau seulement »).
    func mesures(stationsTemperature: Data? = nil) -> MoteurMesures {
        MoteurMesures(geo: geo, stationsTemperature: stationsTemperature)
    }
}
