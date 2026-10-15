import Foundation

/// Une station de pêche électrique de l'OFB (`stations-especes.json`, fabriqué par D2 et jamais commité).
struct StationOFB: Sendable, Equatable {
    var id: String
    var coordonnee: Coordonnee
    var dep: String
    var eau: String?
    var codeEau: String?
    var peches: Int
    /// Année du dernier relevé de la station.
    var derniere: Int
    /// Code Sandre de l'espèce vers nombre de pêches où elle est vue.
    var vues: [String: Int]

    static func decoder(_ donnees: Data) -> [StationOFB] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [] }
        let liste: [[String: Any]]
        if let l = json as? [[String: Any]] { liste = l } else if let o = json as? [String: Any], let l = o["stations"] as? [[String: Any]] { liste = l } else { return [] }
        return liste.compactMap { s in
            guard let id = (s["id"] as? String) ?? (s["id"] as? NSNumber)?.stringValue,
                  let lat = (s["lat"] as? NSNumber)?.doubleValue, let lon = (s["lon"] as? NSNumber)?.doubleValue else { return nil }
            var vues: [String: Int] = [:]
            if let v = s["vues"] as? [String: Any] { for (k, n) in v { if let n = (n as? NSNumber)?.intValue { vues[k] = n } } }
            return StationOFB(id: id, coordonnee: Coordonnee(latitude: lat, longitude: lon), dep: (s["dep"] as? String) ?? "inconnu",
                              eau: s["eau"] as? String, codeEau: (s["code_eau"] as? String) ?? (s["code_eau"] as? NSNumber)?.stringValue,
                              peches: (s["peches"] as? NSNumber)?.intValue ?? 0, derniere: (s["derniere"] as? NSNumber)?.intValue ?? 0, vues: vues)
        }
    }
}

/// Une station hydrométrique (`stations-hydro.json`, fabriqué par D2) : métadonnées seulement, les niveaux sont lus en direct.
struct StationHydroDonnee: Sendable, Equatable {
    var station: StationHydro
    var codeEau: String?
    var dep: String?
    var enService: Bool
    var debit: Bool

    static func decoder(_ donnees: Data) -> [StationHydroDonnee] {
        guard let json = try? JSONSerialization.jsonObject(with: donnees) else { return [] }
        let liste: [[String: Any]]
        if let l = json as? [[String: Any]] { liste = l } else if let o = json as? [String: Any], let l = o["stations"] as? [[String: Any]] { liste = l } else { return [] }
        return liste.compactMap { s in
            guard let code = s["code"] as? String, let lat = (s["lat"] as? NSNumber)?.doubleValue, let lon = (s["lon"] as? NSNumber)?.doubleValue else { return nil }
            let station = StationHydro(code: code, nom: (s["nom"] as? String) ?? code, eau: s["eau"] as? String,
                                       coordonnee: Coordonnee(latitude: lat, longitude: lon))
            return StationHydroDonnee(station: station, codeEau: s["code_eau"] as? String, dep: s["dep"] as? String,
                                      enService: (s["en_service"] as? Bool) ?? true, debit: (s["debit"] as? Bool) ?? false)
        }
    }
}

/// Comptes de pêches d'une zone (département ou région) sur une fenêtre.
struct ComptesRarete: Sendable, Equatable {
    var peches: Int
    /// Code Sandre vers (pêches où l'espèce est vue, année du dernier relevé).
    var especes: [String: (peches: Int, derniere: Int?)]

    static func == (a: ComptesRarete, b: ComptesRarete) -> Bool {
        a.peches == b.peches && a.especes.mapValues { [$0.peches, $0.derniere ?? -1] } == b.especes.mapValues { [$0.peches, $0.derniere ?? -1] }
    }

    static let vide = ComptesRarete(peches: 0, especes: [:])
}

struct ZoneRarete: Sendable, Equatable {
    var region: String?
    var dixAns: ComptesRarete
    var historique: ComptesRarete
}

/// `rarete-departements.json` (fabriqué par D2, jamais commité).
struct DonneesRarete: Sendable, Equatable {
    var departements: [String: ZoneRarete]
    var regions: [String: ZoneRarete]

    static let vide = DonneesRarete(departements: [:], regions: [:])

    static func decoder(_ donnees: Data) -> DonneesRarete {
        guard let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any] else { return .vide }
        func comptes(_ v: Any?) -> ComptesRarete {
            guard let o = v as? [String: Any] else { return .vide }
            var esp: [String: (peches: Int, derniere: Int?)] = [:]
            if let e = o["especes"] as? [String: Any] {
                for (code, x) in e {
                    if let d = x as? [String: Any] {
                        esp[code] = ((d["peches"] as? NSNumber)?.intValue ?? 0, (d["derniere"] as? NSNumber)?.intValue)
                    } else if let n = x as? NSNumber {
                        esp[code] = (n.intValue, nil)
                    }
                }
            }
            return ComptesRarete(peches: (o["peches"] as? NSNumber)?.intValue ?? 0, especes: esp)
        }
        func zones(_ v: Any?) -> [String: ZoneRarete] {
            guard let o = v as? [String: Any] else { return [:] }
            var sortie: [String: ZoneRarete] = [:]
            for (code, x) in o {
                guard let z = x as? [String: Any] else { continue }
                let region = (z["region"] as? String) ?? (z["region"] as? NSNumber)?.stringValue
                sortie[code] = ZoneRarete(region: region, dixAns: comptes(z["dix_ans"]), historique: comptes(z["historique"]))
            }
            return sortie
        }
        return DonneesRarete(departements: zones(racine["departements"]), regions: zones(racine["regions"]))
    }
}

/// Le calcul de rareté : quatre niveaux sur les 10 dernières années, la région sous 20 pêches.
enum CalculRarete {
    /// Moins de pêches que cela dans le département : le calcul se fait sur la région.
    static let pechesMinimumDepartement = 20
    /// Parts des pêches (par défaut, à confirmer par Adem) : 50 % et plus commun, 20 % et plus peu commun, sinon rare.
    static let partCommunSurDix = 5
    static let partPeuCommunSurDix = 2

    static func calculer(code: String?, suiviOFB: Bool, departement: Departement, donnees: DonneesRarete) -> ResultatRarete {
        guard suiviOFB else {
            return ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: .departement)
        }
        guard let dep = donnees.departements[departement.code] else {
            return ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: .departement)
        }
        var zone = dep
        var echelle = EchelleCalcul.departement
        if dep.dixAns.peches < pechesMinimumDepartement, let r = dep.region, let reg = donnees.regions[r], reg.dixAns.peches > dep.dixAns.peches {
            zone = reg
            echelle = .region
        }
        let n = zone.dixAns.peches
        guard n > 0 else {
            return ResultatRarete(niveau: .nonMesuree, nPeches: 0, nTotal: 0, anneeDernierReleve: nil, echelle: echelle)
        }
        let vu = code.flatMap { zone.dixAns.especes[$0] }
        let c = vu?.peches ?? 0
        let niveau: NiveauRarete
        if c == 0 { niveau = .legendaire } else if c * 10 >= n * partCommunSurDix { niveau = .commun } else if c * 10 >= n * partPeuCommunSurDix { niveau = .peuCommun } else { niveau = .rare }
        let annee = vu?.derniere ?? code.flatMap { zone.historique.especes[$0]?.derniere }
        return ResultatRarete(niveau: niveau, nPeches: c, nTotal: n, anneeDernierReleve: annee, echelle: echelle)
    }
}
