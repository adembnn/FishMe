import Foundation

/// Outils de géométrie sur la sphère, sans réseau ni framework d'Apple (Linux compris).
enum Geodesie {
    static let rayonTerreM = 6_371_008.8

    /// Distance entre deux points, en mètres (formule de haversine).
    static func distanceM(_ a: Coordonnee, _ b: Coordonnee) -> Double {
        let p1 = a.latitude * .pi / 180, p2 = b.latitude * .pi / 180
        let dp = p2 - p1
        let dl = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2)
        return 2 * rayonTerreM * asin(min(1, sqrt(h)))
    }

    /// Distance d'un point à un segment, en mètres (projection locale à plat, juste à quelques km).
    static func distanceSegmentM(_ p: Coordonnee, _ a: Coordonnee, _ b: Coordonnee) -> Double {
        let k = cos(p.latitude * .pi / 180)
        let mParDegre = rayonTerreM * .pi / 180
        func xy(_ c: Coordonnee) -> (Double, Double) { ((c.longitude - p.longitude) * k * mParDegre, (c.latitude - p.latitude) * mParDegre) }
        let (ax, ay) = xy(a), (bx, by) = xy(b)
        let dx = bx - ax, dy = by - ay
        let l2 = dx * dx + dy * dy
        var t = l2 == 0 ? 0 : (-ax * dx - ay * dy) / l2
        t = max(0, min(1, t))
        let qx = ax + t * dx, qy = ay + t * dy
        return (qx * qx + qy * qy).squareRoot()
    }

    /// Arrondi à 0,01° (environ 1 km).
    static func arrondi(_ c: Coordonnee) -> Coordonnee {
        Coordonnee(latitude: (c.latitude * 100).rounded() / 100, longitude: (c.longitude * 100).rounded() / 100)
    }
}

extension Calendar {
    /// Calendrier grégorien en UTC : jamais le fuseau ni le calendrier de la machine.
    static let utcGregorien: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()
}

/// Lit une date « AAAA-MM-JJ » (ou « AAAA-MM-JJTHH:MM:SSZ ») à minuit UTC, sans `DateFormatter`.
func dateAAAAMMJJ(_ texte: String?) -> Date? {
    guard let texte, texte.count >= 10 else { return nil }
    let p = texte.prefix(10).split(separator: "-")
    guard p.count == 3, let a = Int(p[0]), let m = Int(p[1]), let j = Int(p[2]) else { return nil }
    return Calendar.utcGregorien.date(from: DateComponents(year: a, month: m, day: j))
}

/// Lit un instant ISO 8601 UTC (« 2026-10-15T14:00:00Z »), sans `DateFormatter`.
func instantISO(_ texte: String?) -> Date? {
    guard let texte, texte.count >= 19 else { return nil }
    let c = Array(texte.utf8)
    func n(_ i: Int, _ l: Int) -> Int? { Int(String(decoding: c[i..<(i + l)], as: UTF8.self)) }
    guard let a = n(0, 4), let m = n(5, 2), let j = n(8, 2), let h = n(11, 2), let mi = n(14, 2), let s = n(17, 2) else { return nil }
    return Calendar.utcGregorien.date(from: DateComponents(year: a, month: m, day: j, hour: h, minute: mi, second: s))
}

/// Clé normalisée d'une eau (« La Marne » donne `marne`), comme `nom_eau` de `outils/regles/consensus.py`.
public func cleEau(_ nom: String) -> String {
    let ascii = nom.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
    var mots: [String] = []
    var courant = ""
    for u in ascii.unicodeScalars {
        if (u.value >= 97 && u.value <= 122) || (u.value >= 48 && u.value <= 57) {
            courant.unicodeScalars.append(u)
        } else if !courant.isEmpty {
            mots.append(courant)
            courant = ""
        }
    }
    if !courant.isEmpty { mots.append(courant) }
    let articles: Set<String> = ["la", "le", "les", "l"]
    while let premier = mots.first, articles.contains(premier), mots.count > 1 { mots.removeFirst() }
    return mots.joined(separator: " ")
}

extension Double {
    func arrondi(_ decimales: Int) -> Double {
        let f = pow(10.0, Double(decimales))
        return (self * f).rounded() / f
    }
}
