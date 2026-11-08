import Foundation

/// Décodage des tableaux compacts (une ligne = un tableau de valeurs). Toute ligne mal formée est ignorée.
extension DonneesGeoUS {
    private static func nombre(_ v: Any?) -> Double? {
        if let d = v as? Double { return d.isFinite ? d : nil }
        if let i = v as? Int { return Double(i) }
        if let n = v as? NSNumber { return n.doubleValue }
        return nil
    }

    private static func texte(_ v: Any?) -> String? {
        guard let s = v as? String else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    static func lireZones(_ racine: [String: Any]?) -> [ZoneEtatUS] {
        guard let liste = racine?["etats"] as? [[String: Any]] else { return [] }
        var zones: [ZoneEtatUS] = []
        for e in liste {
            guard let code = texte(e["etat"]), let b = e["bbox"] as? [Any], b.count == 4,
                  let x0 = nombre(b[0]), let y0 = nombre(b[1]), let x1 = nombre(b[2]), let y1 = nombre(b[3]) else { continue }
            var anneaux: [[(lon: Double, lat: Double)]] = []
            for a in (e["contour"] as? [[[Any]]]) ?? [] {
                let pts = a.compactMap { p -> (lon: Double, lat: Double)? in
                    guard p.count >= 2, let lon = nombre(p[0]), let lat = nombre(p[1]) else { return nil }
                    return (lon, lat)
                }
                if pts.count >= 4 { anneaux.append(pts) }
            }
            zones.append(ZoneEtatUS(etat: code, minLon: x0, minLat: y0, maxLon: x1, maxLat: y1, anneaux: anneaux))
        }
        return zones
    }

    static func lirePoints(_ racine: [String: Any]?, etat: String) -> [PointAccesUS] {
        guard let racine, let lignes = racine["points"] as? [[Any]] else { return [] }
        let sources = (racine["sources"] as? [[String: Any]]) ?? []
        let dateFichier = texte(racine["date"]) ?? ""
        var sortie: [PointAccesUS] = []
        sortie.reserveCapacity(lignes.count)
        for l in lignes {
            guard l.count >= 6, let id = texte(l[0]), let nom = texte(l[1]), let lat = nombre(l[2]), let lon = nombre(l[3]),
                  let type = texte(l[4]), let k = l[5] as? Int, k >= 0, k < sources.count,
                  let source = texte(sources[k]["jeu"]) else { continue }
            let genre = GenreSourceUS(rawValue: texte(sources[k]["genre"]) ?? "") ?? .agence
            let date = texte(sources[k]["date"]) ?? dateFichier
            sortie.append(PointAccesUS(id: id, nom: nom, etat: etat, latitude: lat, longitude: lon,
                                       type: TypeAccesUS(rawValue: type) ?? .autre, source: source, genreSource: genre, date: date))
        }
        return sortie
    }

    static func lirePlansEau(_ racine: [String: Any]?, etat: String) -> [PlanEauUS] {
        guard let racine, let lignes = racine["plans_eau"] as? [[Any]] else { return [] }
        let source = texte(racine["source"]) ?? "source non précisée"
        let date = texte(racine["date"]) ?? ""
        let lien = texte(racine["lien_agence"])
        var sortie: [PlanEauUS] = []
        sortie.reserveCapacity(lignes.count)
        for l in lignes {
            guard l.count >= 5, let id = texte(l[0]), let nom = texte(l[1]), let lat = nombre(l[2]), let lon = nombre(l[3]),
                  let rayon = nombre(l[4]) else { continue }
            sortie.append(PlanEauUS(id: id, nom: nom, etat: etat, latitude: lat, longitude: lon, rayonMetres: rayon,
                                    source: source, date: date, lienAgence: lien))
        }
        return sortie
    }

    static func lireLignes(_ racine: [String: Any]?, etat: String) -> [LigneEauUS] {
        guard let racine, let lignes = racine["lignes"] as? [[Any]] else { return [] }
        let source = texte(racine["source"]) ?? "source non précisée"
        let date = texte(racine["date"]) ?? ""
        var sortie: [LigneEauUS] = []
        sortie.reserveCapacity(lignes.count)
        for l in lignes {
            guard l.count >= 4, let id = texte(l[0]), let nom = texte(l[1]), let ordre = l[2] as? Int,
                  let brut = l[3] as? [[Any]] else { continue }
            let pts = brut.compactMap { p -> Coordonnee? in
                guard p.count >= 2, let lon = nombre(p[0]), let lat = nombre(p[1]) else { return nil }
                return Coordonnee(latitude: lat, longitude: lon)
            }
            if pts.count >= 2 { sortie.append(LigneEauUS(id: id, nom: nom, etat: etat, ordre: ordre, points: pts, source: source, date: date)) }
        }
        return sortie
    }

    static func lireAvis(_ racine: [String: Any]?) -> [AvisSanteEauUS] {
        guard let racine, let lignes = racine["avis"] as? [[Any]] else { return [] }
        let source = texte(racine["source"]) ?? "source non précisée"
        var sortie: [AvisSanteEauUS] = []
        for l in lignes {
            guard l.count >= 4, let txt = texte(l[1]), let date = texte(l[2]), let lien = texte(l[3]) else { continue }
            sortie.append(AvisSanteEauUS(planEauId: texte(l[0]), texte: txt, date: date, source: source, lien: lien))
        }
        return sortie
    }
}
