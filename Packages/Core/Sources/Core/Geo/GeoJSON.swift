import Foundation

/// Un contour décodé de GeoJSON : un ou plusieurs morceaux (MultiPolygon), chacun avec son anneau extérieur et ses trous.
/// Décodeur maison : `MKGeoJSONDecoder` n'existe ni sous Linux ni dans `Core`.
struct Contour: Sendable {
    struct Morceau: Sendable {
        /// Le premier anneau est l'extérieur, les suivants sont des trous.
        var anneaux: [[Coordonnee]]
        var minLat: Double, maxLat: Double, minLon: Double, maxLon: Double

        init(anneaux: [[Coordonnee]]) {
            self.anneaux = anneaux
            let ext = anneaux.first ?? []
            minLat = ext.map(\.latitude).min() ?? 0
            maxLat = ext.map(\.latitude).max() ?? 0
            minLon = ext.map(\.longitude).min() ?? 0
            maxLon = ext.map(\.longitude).max() ?? 0
        }

        func boiteContient(_ p: Coordonnee, marge: Double = 0) -> Bool {
            p.latitude >= minLat - marge && p.latitude <= maxLat + marge && p.longitude >= minLon - marge && p.longitude <= maxLon + marge
        }
    }

    var proprietes: [String: String]
    var morceaux: [Morceau]

    var code: String? { proprietes["code"] ?? proprietes["insee_dep"] ?? proprietes["code_dep"] ?? proprietes["id"] }
    var nom: String? { proprietes["nom"] ?? proprietes["name"] ?? proprietes["libelle"] }

    func contient(_ p: Coordonnee) -> Bool {
        for m in morceaux where m.boiteContient(p) {
            guard let ext = m.anneaux.first, Contour.dansAnneau(p, ext) else { continue }
            if m.anneaux.dropFirst().contains(where: { Contour.dansAnneau(p, $0) }) { continue }
            return true
        }
        return false
    }

    /// Centre approximatif (milieu de la boîte du plus grand morceau), pour calculer l'heure du soleil d'un département.
    var centre: Coordonnee? {
        guard let m = morceaux.max(by: { ($0.maxLat - $0.minLat) * ($0.maxLon - $0.minLon) < ($1.maxLat - $1.minLat) * ($1.maxLon - $1.minLon) })
        else { return nil }
        return Coordonnee(latitude: (m.minLat + m.maxLat) / 2, longitude: (m.minLon + m.maxLon) / 2)
    }

    /// Distance du point au bord le plus proche, en mètres (`.infinity` si le point est loin de la boîte du contour).
    func distanceAuBordM(_ p: Coordonnee, rayonM: Double) -> Double {
        let marge = rayonM / 111_000 * 1.5 + 0.001
        var meilleure = Double.infinity
        for m in morceaux where m.boiteContient(p, marge: marge) {
            for anneau in m.anneaux where anneau.count > 1 {
                for i in 0..<(anneau.count - 1) {
                    meilleure = min(meilleure, Geodesie.distanceSegmentM(p, anneau[i], anneau[i + 1]))
                }
            }
        }
        return meilleure
    }

    /// Lancer de rayon : vrai si le point est dans l'anneau.
    static func dansAnneau(_ p: Coordonnee, _ anneau: [Coordonnee]) -> Bool {
        var dedans = false
        var j = anneau.count - 1
        for i in 0..<anneau.count {
            let a = anneau[i], b = anneau[j]
            if (a.latitude > p.latitude) != (b.latitude > p.latitude),
               p.longitude < (b.longitude - a.longitude) * (p.latitude - a.latitude) / (b.latitude - a.latitude) + a.longitude {
                dedans.toggle()
            }
            j = i
        }
        return dedans
    }

    /// Lit un `FeatureCollection` (Polygon et MultiPolygon). Données illisibles : liste vide, jamais de plantage.
    static func decoder(_ donnees: Data) -> [Contour] {
        guard let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any],
              let features = racine["features"] as? [[String: Any]] else { return [] }
        var sortie: [Contour] = []
        for f in features {
            guard let geo = f["geometry"] as? [String: Any], let type = geo["type"] as? String else { continue }
            var props: [String: String] = [:]
            if let p = f["properties"] as? [String: Any] {
                for (k, v) in p {
                    if let s = v as? String { props[k] = s } else if let n = v as? NSNumber { props[k] = n.stringValue }
                }
            }
            if props["id"] == nil, let id = f["id"] as? String { props["id"] = id }
            var morceaux: [Morceau] = []
            if type == "Polygon", let c = geo["coordinates"] as? [Any], let m = polygone(c) { morceaux = [m] }
            if type == "MultiPolygon", let c = geo["coordinates"] as? [Any] { morceaux = c.compactMap { ($0 as? [Any]).flatMap(polygone) } }
            if !morceaux.isEmpty { sortie.append(Contour(proprietes: props, morceaux: morceaux)) }
        }
        return sortie
    }

    private static func polygone(_ anneaux: [Any]) -> Morceau? {
        let rings: [[Coordonnee]] = anneaux.compactMap { ring in
            guard let points = ring as? [Any] else { return nil }
            let c: [Coordonnee] = points.compactMap { pt in
                guard let a = pt as? [Any], a.count >= 2, let lon = (a[0] as? NSNumber)?.doubleValue, let lat = (a[1] as? NSNumber)?.doubleValue else { return nil }
                return Coordonnee(latitude: lat, longitude: lon)
            }
            return c.count >= 3 ? c : nil
        }
        return rings.isEmpty ? nil : Morceau(anneaux: rings)
    }
}
