import Foundation

/// Conditions : lecture de la météo en nombres, alertes, stations. La météo vient de l'app (WeatherKit), jamais d'ici.
/// Convention : `PointMeteo.codeTemps` est un code WMO ; 95, 96 et 99 sont des orages.
public struct MoteurConditions: ServiceConditions {
    /// « Haut » quand le débit dépasse 2 fois la normale du mois (par défaut, à confirmer par Adem).
    public static let facteurHaut = 2.0
    /// « Crue » quand la hauteur monte de plus de 50 cm en 24 h (par défaut, à confirmer par Adem).
    public static let hausseCrueM = 0.5
    /// Un orage prévu dans les 3 heures donne l'alerte (par défaut, à confirmer par Adem).
    public static let fenetreOrage: TimeInterval = 3 * 3600
    public static let codesOrage: Set<Int> = [95, 96, 99]
    /// Station hydrométrique : la plus proche à moins de 10 km (par défaut).
    public static let rayonStationHydroM = 10_000.0
    /// Point météo : la station OFB du spot si elle est à moins de 5 km (par défaut).
    public static let rayonPointMeteoM = 5_000.0
    /// « Tes conditions » : rien avant 10 sorties.
    public static let sortiesMinimum = 10
    /// Un constat ne se montre qu'avec au moins ce nombre de sorties dans la condition.
    public static let sortiesParConstatMinimum = 3
    static let toleranceMeteo: TimeInterval = 90 * 60

    let soleil: MoteurSoleil
    let geo: MoteurGeo?
    let stationsHydro: [StationHydroDonnee]
    let stationsOFB: [StationBrute]
    let position: Coordonnee?
    let horloge: @Sendable () -> Date

    init(soleil: MoteurSoleil = MoteurSoleil(), geo: MoteurGeo? = nil, stationsHydro: [StationHydroDonnee] = [], stationsOFB: [StationBrute] = [],
         position: Coordonnee? = nil, horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.soleil = soleil
        self.geo = geo
        self.stationsHydro = stationsHydro
        self.stationsOFB = stationsOFB
        self.position = position
        self.horloge = horloge
    }

    /// Le moteur pour un spot : `lireConditions` n'a pas de coordonnée, donc l'aube, le crépuscule et la fin légale se calculent ici.
    public func pour(spot: Coordonnee) -> MoteurConditions {
        MoteurConditions(soleil: soleil, geo: geo, stationsHydro: stationsHydro, stationsOFB: stationsOFB, position: spot, horloge: horloge)
    }

    // MARK: Lecture

    private func plusProche(_ meteo: MeteoBrute, _ cible: Date) -> PointMeteo? {
        meteo.heures.min { abs($0.heure.timeIntervalSince(cible)) < abs($1.heure.timeIntervalSince(cible)) }
            .flatMap { abs($0.heure.timeIntervalSince(cible)) <= Self.toleranceMeteo ? $0 : nil }
    }

    public func lireConditions(meteo: MeteoBrute, eau: NiveauEau?, date: Date) -> Conditions {
        let maintenant = plusProche(meteo, date)
        var tendance: Double?
        if let p = maintenant, let avant = plusProche(meteo, date.addingTimeInterval(-6 * 3600)), avant.heure < p.heure {
            tendance = (p.pressionHPa - avant.pressionHPa).arrondi(1)
        }
        let lieu = position ?? eau?.station.coordonnee
        let jour = lieu.flatMap { soleil.leverEtCoucher(date: date, coordonnee: $0) }
        var sources: [String] = []
        if !meteo.heures.isEmpty { sources.append("Apple Weather") }
        if let eau { sources.append("Hub'Eau, station \(eau.station.nom), \(heureUTC(eau.heureMesure))") }
        return Conditions(
            heure: date, ventKmh: maintenant?.ventKmh, pluieMm: maintenant?.pluieMm, pressionHPa: maintenant?.pressionHPa,
            tendancePressionHPa6h: tendance, aube: jour?.lever, crepuscule: jour?.coucher,
            finLegale: lieu.flatMap { soleil.finLegale(date: date, coordonnee: $0) },
            etatRiviere: eau.map(etat) ?? .inconnu, septJours: septJours(meteo, depuis: date), sources: sources)
    }

    private func heureUTC(_ d: Date) -> String {
        let c = Calendar.utcGregorien.dateComponents([.hour, .minute], from: d)
        return String(format: "%02d:%02d UTC", c.hour ?? 0, c.minute ?? 0)
    }

    func etat(_ eau: NiveauEau) -> EtatRiviere {
        if crue(eau) != nil { return .crue }
        guard let debit = eau.debitM3s, let normale = eau.normaleDebitM3s, normale > 0 else { return .inconnu }
        return debit > Self.facteurHaut * normale ? .haut : .normal
    }

    private func septJours(_ meteo: MeteoBrute, depuis date: Date) -> [JourConditions] {
        let cal = Calendar.utcGregorien
        let debut = cal.startOfDay(for: date)
        let parJour = Dictionary(grouping: meteo.heures.filter { $0.heure >= debut }) { cal.startOfDay(for: $0.heure) }
        return parJour.keys.sorted().prefix(7).compactMap { jour in
            guard let h = parJour[jour], !h.isEmpty else { return nil }
            let midi = jour.addingTimeInterval(12 * 3600)
            let code = h.min { abs($0.heure.timeIntervalSince(midi)) < abs($1.heure.timeIntervalSince(midi)) }?.codeTemps ?? 0
            return JourConditions(jour: jour, ventKmh: h.map(\.ventKmh).max() ?? 0, pluieMm: h.map(\.pluieMm).reduce(0, +).arrondi(1),
                                  temperatureMinC: h.map(\.temperatureC).min() ?? 0, temperatureMaxC: h.map(\.temperatureC).max() ?? 0, codeTemps: code)
        }
    }

    // MARK: Alertes

    /// Vigilance jaune ou plus, ou plus de 50 cm de hausse en 24 h.
    func crue(_ eau: NiveauEau) -> (mesure: String, source: String)? {
        let source = "Hub'Eau, station \(eau.station.nom)"
        if let v = eau.vigilance, v != .vert {
            return ("Vigilance crues \(v.rawValue)", "Vigicrues, \(eau.station.nom)")
        }
        let serie = eau.serie48h.compactMap { m in m.hauteurM.map { (m.heure, $0) } }.sorted { $0.0 < $1.0 }
        guard let actuelle = eau.hauteurM ?? serie.last?.1 else { return nil }
        let cible = eau.heureMesure.addingTimeInterval(-24 * 3600)
        guard let avant = serie.min(by: { abs($0.0.timeIntervalSince(cible)) < abs($1.0.timeIntervalSince(cible)) }),
              abs(avant.0.timeIntervalSince(cible)) <= 2 * 3600 else { return nil }
        let hausse = actuelle - avant.1
        guard hausse > Self.hausseCrueM else { return nil }
        return ("+\(Int((hausse * 100).rounded())) cm en 24 h", source)
    }

    public func alerte(meteo: MeteoBrute, eau: NiveauEau?) -> Alerte? {
        let maintenant = horloge()
        if let officielle = meteo.alertesOfficielles.first(where: { $0.texte.folding(options: .diacriticInsensitive, locale: nil).lowercased().contains("orage") }) {
            return Alerte(type: .orage, mesure: officielle.texte, source: officielle.source, heure: officielle.debut ?? maintenant)
        }
        if let eau, let c = crue(eau) {
            return Alerte(type: .crue, mesure: c.mesure, source: c.source, heure: eau.heureMesure)
        }
        let prevu = meteo.heures.filter { $0.heure >= maintenant.addingTimeInterval(-1800) && $0.heure <= maintenant.addingTimeInterval(Self.fenetreOrage) }
            .first { Self.codesOrage.contains($0.codeTemps) }
        if let p = prevu {
            return Alerte(type: .orage, mesure: "Orage prévu à \(heureUTC(p.heure))", source: "Apple Weather", heure: p.heure)
        }
        return nil
    }

    // MARK: Stations

    public func stationHydro(pres coordonnee: Coordonnee) -> StationHydro? {
        let codeEau = geo?.lieu(de: coordonnee, choix: nil).eau?.codeSandre
        var meilleure: (StationHydroDonnee, Double)?
        for s in stationsHydro where s.enService {
            let d = Geodesie.distanceM(coordonnee, s.station.coordonnee)
            guard d <= Self.rayonStationHydroM else { continue }
            if let a = codeEau, let b = s.codeEau, a != b { continue }
            if d < (meilleure?.1 ?? .infinity) { meilleure = (s, d) }
        }
        return meilleure?.0.station
    }

    public func pointMeteo(spot: Coordonnee) -> Coordonnee {
        var meilleure: (StationBrute, Double)?
        for s in stationsOFB {
            let d = Geodesie.distanceM(spot, s.coordonnee)
            if d <= Self.rayonPointMeteoM, d < (meilleure?.1 ?? .infinity) { meilleure = (s, d) }
        }
        let p = meilleure?.0.coordonnee ?? Geodesie.arrondi(spot)
        // Jamais la coordonnée exacte du spot : si le point retenu tombe pile dessus, on le décale d'une demi-case de 0,01°.
        return p == spot ? Coordonnee(latitude: spot.latitude + 0.005, longitude: spot.longitude + 0.005) : p
    }

    // MARK: Tes conditions

    public func tesConditions(sorties: [Sortie]) -> [Constat]? {
        let finies = sorties.filter { $0.fin != nil }
        guard finies.count >= Self.sortiesMinimum else { return nil }
        func etiquettes(_ c: Conditions) -> [String] {
            var l: [String] = []
            if let v = c.ventKmh { l.append(v >= 20 ? "vent fort" : "vent faible") }
            if let p = c.pluieMm { l.append(p > 0.2 ? "pluie" : "temps sec") }
            if let t = c.tendancePressionHPa6h { l.append(t <= -2 ? "pression en baisse" : t >= 2 ? "pression en hausse" : "pression stable") }
            return l
        }
        var sortiesParCondition: [String: [Sortie]] = [:]
        for s in finies {
            guard let c = s.conditions.first else { continue }
            for e in etiquettes(c) { sortiesParCondition[e, default: []].append(s) }
        }
        var constats: [Constat] = []
        for (condition, liste) in sortiesParCondition where liste.count >= Self.sortiesParConstatMinimum {
            var especes: [String: Int] = [:]
            for s in liste {
                for id in Set(s.prises.filter { !$0.estDeclaree && !$0.exemple }.map(\.espece.id)) { especes[id, default: 0] += 1 }
            }
            for (id, n) in especes {
                let nom = id.replacingOccurrences(of: "-", with: " ")
                constats.append(Constat(texte: "\(n) sorties sur \(liste.count) avec \(nom) par \(condition)", nPeches: n, surSorties: liste.count))
            }
        }
        return constats.sorted { ($0.nPeches, $0.texte) > ($1.nPeches, $1.texte) }.prefix(6).map { $0 }
    }
}
