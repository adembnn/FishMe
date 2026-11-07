import Foundation

/// Lecture tolérante des JSON USGS (GeoJSON OGC), NWS (GeoJSON) et NWPS. Un champ absent donne `nil`, jamais un plantage.
enum DecodageUS {
    /// ISO 8601 avec décalage (« 2026-11-07T08:50:00+00:00 », « …-05:00 », « …Z »), avec ou sans fractions de seconde.
    static func date(_ texte: String?) -> Date? {
        guard let texte else { return nil }
        let avecFractions = ISO8601DateFormatter()
        avecFractions.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = avecFractions.date(from: texte) { return d }
        let simple = ISO8601DateFormatter()
        simple.formatOptions = [.withInternetDateTime]
        return simple.date(from: texte)
    }

    /// L'API USGS donne `value` en texte (« "2120" ») ; NWPS en nombre. Les deux sont acceptés.
    static func nombre(_ v: Any?) -> Double? {
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String { return Double(s.trimmingCharacters(in: .whitespaces)) }
        return nil
    }

    /// NWPS écrit -999 ou -9999 pour « pas de valeur ».
    static func nombreNWPS(_ v: Any?) -> Double? {
        guard let n = nombre(v), n > -900 else { return nil }
        return n
    }

    private static func objet(_ donnees: Data) -> [String: Any]? {
        (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any]
    }

    private static func proprietes(_ donnees: Data) -> [[String: Any]] {
        guard let racine = objet(donnees), let f = racine["features"] as? [[String: Any]] else { return [] }
        return f.map { feature in
            var p = (feature["properties"] as? [String: Any]) ?? [:]
            if p["_coordinates"] == nil, let g = feature["geometry"] as? [String: Any], let c = g["coordinates"] as? [Any], c.count >= 2 {
                p["_coordinates"] = c
            }
            if p["_id"] == nil { p["_id"] = feature["id"] }
            return p
        }
    }

    // MARK: USGS

    static func stationsUSGS(_ donnees: Data) -> [StationUSGS] {
        proprietes(donnees).compactMap { p in
            guard let id = p["id"] as? String ?? p["monitoring_location_id"] as? String else { return nil }
            let c = p["_coordinates"] as? [Any]
            return StationUSGS(id: id, nom: (p["monitoring_location_name"] as? String) ?? id,
                               latitude: c.flatMap { $0.count >= 2 ? nombre($0[1]) : nil }, longitude: c.flatMap { nombre($0[0]) },
                               etat: p["state_name"] as? String, comte: p["county_name"] as? String, typeDeSite: p["site_type"] as? String,
                               bassinMilesCarres: nombre(p["drainage_area"]), fuseau: p["time_zone_abbreviation"] as? String)
        }
    }

    static func mesuresUSGS(_ donnees: Data) -> [MesureUSGS] {
        proprietes(donnees).compactMap { p in
            guard let station = p["monitoring_location_id"] as? String,
                  let code = p["parameter_code"] as? String, let parametre = ParametreUSGS(rawValue: code),
                  let valeur = nombre(p["value"]), let heure = date(p["time"] as? String) else { return nil }
            let brute = p["unit_of_measure"] as? String
            let statut = (p["approval_status"] as? String).flatMap { StatutApprobationUSGS(rawValue: $0) } ?? .inconnu
            return MesureUSGS(stationId: station, parametre: parametre, valeur: valeur, unite: UniteUSGS(brute: brute), uniteBrute: brute,
                              heure: heure, statut: statut, serieId: p["time_series_id"] as? String)
        }
    }

    /// Lien « next » de la pagination OGC, s'il existe.
    static func pageSuivante(_ donnees: Data) -> URL? {
        guard let liens = objet(donnees)?["links"] as? [[String: Any]] else { return nil }
        return liens.first { ($0["rel"] as? String) == "next" }.flatMap { ($0["href"] as? String).flatMap(URL.init(string:)) }
    }

    // MARK: NWS

    static func alertesNWS(_ donnees: Data) -> [AlerteNWS] {
        proprietes(donnees).compactMap { p in
            guard let id = p["id"] as? String, let evenement = p["event"] as? String else { return nil }
            return AlerteNWS(id: id, evenement: evenement, gravite: (p["severity"] as? String) ?? "Unknown", urgence: p["urgency"] as? String,
                             certitude: p["certainty"] as? String, titre: p["headline"] as? String, description: p["description"] as? String,
                             consigne: p["instruction"] as? String, zone: p["areaDesc"] as? String, emetteur: p["senderName"] as? String,
                             debut: date((p["onset"] as? String) ?? (p["effective"] as? String)), fin: date(p["ends"] as? String),
                             expire: date(p["expires"] as? String))
        }
    }

    // MARK: NWPS

    private static func categorie(_ v: Any?) -> CategorieCrueNWPS {
        (v as? String).flatMap { CategorieCrueNWPS(rawValue: $0) } ?? .inconnue
    }

    private static func points(_ v: Any?) -> (points: [PointCrueNWPS], emise: Date?) {
        guard let o = v as? [String: Any], let data = o["data"] as? [[String: Any]] else { return ([], nil) }
        let pts = data.compactMap { d -> PointCrueNWPS? in
            guard let t = date(d["validTime"] as? String) else { return nil }
            return PointCrueNWPS(heure: t, hauteurPieds: nombreNWPS(d["primary"]), debitKcfs: nombreNWPS(d["secondary"]))
        }
        return (pts, date(o["issuedTime"] as? String))
    }

    /// `gauge` : réponse de `/gauges/{id}` ; `stageflow` : réponse de `/gauges/{id}/stageflow` (facultative).
    static func previsionCrueNWPS(gauge: Data, stageflow: Data?) -> PrevisionCrueNWPS? {
        guard let g = objet(gauge), let id = g["lid"] as? String else { return nil }
        let statut = g["status"] as? [String: Any]
        let cats = ((g["flood"] as? [String: Any])?["categories"] as? [String: Any]) ?? [:]
        func seuil(_ k: String) -> Double? { nombreNWPS((cats[k] as? [String: Any])?["stage"]) }
        let sf = stageflow.flatMap(objet)
        let obs = points(sf?["observed"]), prev = points(sf?["forecast"])
        let usgs = (g["usgsId"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        return PrevisionCrueNWPS(identifiant: id, nom: (g["name"] as? String) ?? id, usgsId: usgs, latitude: nombre(g["latitude"]),
                                 longitude: nombre(g["longitude"]), categorieObservee: categorie((statut?["observed"] as? [String: Any])?["floodCategory"]),
                                 categoriePrevue: categorie((statut?["forecast"] as? [String: Any])?["floodCategory"]),
                                 seuils: SeuilsCrueNWPS(actionPieds: seuil("action"), mineurePieds: seuil("minor"), modereePieds: seuil("moderate"),
                                                        majeurePieds: seuil("major")),
                                 observee: obs.points, prevue: prev.points, emisePrevision: prev.emise)
    }
}
