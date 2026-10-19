import Foundation

/// Un jour du calendrier (année, mois, jour), sans heure ni fuseau.
/// Sert à la date d'expiration d'une carte : une `Date` décalerait d'un jour selon le fuseau et l'heure d'été.
/// Calendrier grégorien, calculs en jours entiers. Aucune horloge ici : le jour d'aujourd'hui est un paramètre.
public struct JourCivil: Sendable, Codable, Hashable, Comparable {
    public let annee: Int
    public let mois: Int
    public let jour: Int

    /// `nil` si le jour n'existe pas (30/02, 29/02 d'une année non bissextile, mois 13…).
    public init?(annee: Int, mois: Int, jour: Int) {
        guard (1...9999).contains(annee), (1...12).contains(mois),
              jour >= 1, jour <= Self.joursDansMois(annee: annee, mois: mois) else { return nil }
        self.annee = annee
        self.mois = mois
        self.jour = jour
    }

    /// Le jour civil d'une `Date`, lu dans le calendrier donné (le calendrier de l'iPhone côté app).
    public init(date: Date, calendrier: Calendar) {
        let c = calendrier.dateComponents([.year, .month, .day], from: date)
        // Un calendrier grégorien rend toujours ces trois champs ; le repli (1970) ne sert qu'à éviter un `!`.
        if let jour = JourCivil(annee: c.year ?? 1970, mois: c.month ?? 1, jour: c.day ?? 1) {
            self = jour
        } else {
            self = Self.depuisNumero(0)
        }
    }

    /// « 2026-12-31 ».
    public init?(iso: String) {
        let morceaux = iso.split(separator: "-", omittingEmptySubsequences: false)
        guard morceaux.count == 3, morceaux[0].count == 4, morceaux[1].count == 2, morceaux[2].count == 2,
              let a = Int(morceaux[0]), let m = Int(morceaux[1]), let j = Int(morceaux[2]) else { return nil }
        self.init(annee: a, mois: m, jour: j)
    }

    // MARK: Codable (refuse un jour qui n'existe pas)

    private enum CodingKeys: String, CodingKey { case annee, mois, jour }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let a = try c.decode(Int.self, forKey: .annee)
        let m = try c.decode(Int.self, forKey: .mois)
        let j = try c.decode(Int.self, forKey: .jour)
        guard let existant = JourCivil(annee: a, mois: m, jour: j) else {
            throw DecodingError.dataCorruptedError(forKey: .jour, in: c, debugDescription: "Ce jour n'existe pas.")
        }
        self = existant
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(annee, forKey: .annee)
        try c.encode(mois, forKey: .mois)
        try c.encode(jour, forKey: .jour)
    }

    // MARK: Calendrier

    public static func estBissextile(_ annee: Int) -> Bool {
        (annee % 4 == 0 && annee % 100 != 0) || annee % 400 == 0
    }

    public static func joursDansMois(annee: Int, mois: Int) -> Int {
        switch mois {
        case 2: return estBissextile(annee) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// Nombre de jours depuis le 01/01/1970 (négatif avant). Algorithme « days from civil » (grégorien proleptique).
    var numeroDeJour: Int {
        let y = mois <= 2 ? annee - 1 : annee
        let ere = (y >= 0 ? y : y - 399) / 400
        let anneeDeLEre = y - ere * 400
        let jourDeLAnnee = (153 * (mois + (mois > 2 ? -3 : 9)) + 2) / 5 + jour - 1
        let jourDeLEre = anneeDeLEre * 365 + anneeDeLEre / 4 - anneeDeLEre / 100 + jourDeLAnnee
        return ere * 146_097 + jourDeLEre - 719_468
    }

    static func depuisNumero(_ numero: Int) -> JourCivil {
        let z = numero + 719_468
        let ere = (z >= 0 ? z : z - 146_096) / 146_097
        let jourDeLEre = z - ere * 146_097
        let anneeDeLEre = (jourDeLEre - jourDeLEre / 1460 + jourDeLEre / 36_524 - jourDeLEre / 146_096) / 365
        let y = anneeDeLEre + ere * 400
        let jourDeLAnnee = jourDeLEre - (365 * anneeDeLEre + anneeDeLEre / 4 - anneeDeLEre / 100)
        let mp = (5 * jourDeLAnnee + 2) / 153
        let j = jourDeLAnnee - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        let a = m <= 2 ? y + 1 : y
        // Le résultat est toujours un jour qui existe ; le repli ne sert qu'à éviter un `!`.
        return JourCivil(annee: a, mois: m, jour: j) ?? JourCivil(annee: 1970, mois: 1, jour: 1)!
    }

    /// Ce jour plus (ou moins, si négatif) `jours` jours.
    public func ajouter(jours: Int) -> JourCivil {
        Self.depuisNumero(numeroDeJour + jours)
    }

    /// Nombre de jours de ce jour-ci jusqu'à `autre` : positif si `autre` est après, négatif s'il est avant.
    public func jours(jusqua autre: JourCivil) -> Int {
        autre.numeroDeJour - numeroDeJour
    }

    public static func < (a: JourCivil, b: JourCivil) -> Bool {
        (a.annee, a.mois, a.jour) < (b.annee, b.mois, b.jour)
    }

    // MARK: Texte

    /// « 2026-12-31 ».
    public var iso: String {
        String(format: "%04d-%02d-%02d", annee, mois, jour)
    }

    /// « 31/12/2026 ».
    public var texte: String {
        String(format: "%02d/%02d/%04d", jour, mois, annee)
    }

    // MARK: Pont vers Date (pour un sélecteur de date)

    /// Midi de ce jour dans le calendrier donné (midi évite les bords d'heure d'été).
    public func date(calendrier: Calendar) -> Date? {
        calendrier.date(from: DateComponents(year: annee, month: mois, day: jour, hour: 12))
    }
}
