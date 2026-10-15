import Foundation

/// Lever et coucher du soleil (algorithme NOAA, sans réseau) et phase de la lune.
public struct MoteurSoleil: ServiceSoleil {
    /// Fin légale = coucher + 30 min (R436-13), moins 1 min de marge.
    public static let prolongationLegaleMin = 30.0
    public static let margeDeSecuriteMin = 1.0

    public init() {}

    // MARK: Soleil

    /// Lever et coucher du soleil (UTC) du jour local du point. `nil` si le soleil ne se lève ou ne se couche pas (nuit ou jour polaire).
    public func leverEtCoucher(date: Date, coordonnee: Coordonnee) -> (lever: Date, coucher: Date)? {
        let lon = coordonnee.longitude, lat = coordonnee.latitude
        // Jour local : décalage solaire de 4 min par degré de longitude, indépendant de tout fuseau de la machine.
        let jourLocal = ((date.timeIntervalSince1970 + lon / 15 * 3600) / 86400).rounded(.down)
        let debutUTC = jourLocal * 86400
        guard let lever = evenement(lever: true, debutUTC: debutUTC, lat: lat, lon: lon),
              let coucher = evenement(lever: false, debutUTC: debutUTC, lat: lat, lon: lon) else { return nil }
        return (lever, coucher)
    }

    public func finLegale(date: Date, coordonnee: Coordonnee) -> Date? {
        guard let (_, coucher) = leverEtCoucher(date: date, coordonnee: coordonnee) else { return nil }
        return coucher.addingTimeInterval((Self.prolongationLegaleMin - Self.margeDeSecuriteMin) * 60)
    }

    /// Début de la fenêtre légale : lever du soleil moins 30 min.
    public func debutLegal(date: Date, coordonnee: Coordonnee, avantLeverMin: Double = 30) -> Date? {
        guard let (lever, _) = leverEtCoucher(date: date, coordonnee: coordonnee) else { return nil }
        return lever.addingTimeInterval(-avantLeverMin * 60)
    }

    private func evenement(lever: Bool, debutUTC: Double, lat: Double, lon: Double) -> Date? {
        let jd0 = debutUTC / 86400 + 2_440_587.5
        var minutes = lever ? 360.0 : 1080.0
        for _ in 0..<4 {
            let (eq, decl) = Self.eclairage(jd: jd0 + minutes / 1440)
            let phi = lat * .pi / 180
            let cosHA = cos(90.833 * .pi / 180) / (cos(phi) * cos(decl)) - tan(phi) * tan(decl)
            if cosHA > 1 || cosHA < -1 { return nil }
            let ha = acos(cosHA) * 180 / .pi
            minutes = 720 - 4 * lon - eq + (lever ? -4 : 4) * ha
        }
        return Date(timeIntervalSince1970: debutUTC + minutes * 60)
    }

    /// Équation du temps (minutes) et déclinaison du soleil (radians) au jour julien donné.
    static func eclairage(jd: Double) -> (eq: Double, decl: Double) {
        let rad = Double.pi / 180
        let t = (jd - 2_451_545.0) / 36525
        let l0 = (280.46646 + t * (36000.76983 + 0.0003032 * t)).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)
        let c = sin(m * rad) * (1.914602 - t * (0.004817 + 0.000014 * t)) + sin(2 * m * rad) * (0.019993 - 0.000101 * t) + sin(3 * m * rad) * 0.000289
        let vraieLong = l0 + c
        let omega = 125.04 - 1934.136 * t
        let lambda = vraieLong - 0.00569 - 0.00478 * sin(omega * rad)
        let eps0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
        let eps = eps0 + 0.00256 * cos(omega * rad)
        let decl = asin(sin(eps * rad) * sin(lambda * rad))
        let y = pow(tan(eps * rad / 2), 2)
        let eq = 4 / rad * (y * sin(2 * l0 * rad) - 2 * e * sin(m * rad) + 4 * e * y * sin(m * rad) * cos(2 * l0 * rad)
                            - 0.5 * y * y * sin(4 * l0 * rad) - 1.25 * e * e * sin(2 * m * rad))
        return (eq, decl)
    }

    // MARK: Lune

    /// Mois synodique moyen, en jours. Référence : nouvelle lune du 6 janvier 2000, 18 h 14 UTC.
    static let moisSynodique = 29.530588853
    static let jourJulienReference = 2_451_550.26

    /// Âge de la lune en jours depuis la nouvelle lune moyenne (0 à 29,53).
    public func ageLune(date: Date) -> Double {
        let jd = date.timeIntervalSince1970 / 86400 + 2_440_587.5
        let age = (jd - Self.jourJulienReference).truncatingRemainder(dividingBy: Self.moisSynodique)
        return age < 0 ? age + Self.moisSynodique : age
    }

    public func phaseLune(date: Date) -> PhaseLune {
        let rang = Int((ageLune(date: date) / Self.moisSynodique * 8 + 0.5).rounded(.down)) % 8
        return PhaseLune.allCases[rang]
    }
}
