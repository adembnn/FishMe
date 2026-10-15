import Foundation

/// Version d'un fichier de règles : « 2026-10-15.1 » (jour de lecture, puis numéro du jour).
public struct VersionRegles: Sendable, Equatable, Hashable, Comparable {
    public let jour: String
    public let numero: Int

    public init?(_ texte: String) {
        let morceaux = texte.split(separator: ".", omittingEmptySubsequences: false)
        guard morceaux.count == 2, let numero = Int(morceaux[1]), numero >= 0,
              Jours.date(iso: String(morceaux[0])) != nil else { return nil }
        self.jour = String(morceaux[0])
        self.numero = numero
    }

    public var texte: String { "\(jour).\(numero)" }

    public static func < (a: VersionRegles, b: VersionRegles) -> Bool {
        a.jour != b.jour ? a.jour < b.jour : a.numero < b.numero
    }
}

/// Les dates des fichiers de règles sont des jours « aaaa-mm-jj » comptés à Paris.
enum Jours {
    static let calendrier: Calendar = {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "Europe/Paris") ?? .gmt
        return calendrier
    }()

    /// Début du jour (Paris), ou `nil` si le texte n'est pas une vraie date « aaaa-mm-jj ».
    static func date(iso: String) -> Date? {
        let morceaux = iso.split(separator: "-", omittingEmptySubsequences: false)
        guard morceaux.count == 3, morceaux[0].count == 4, morceaux[1].count == 2, morceaux[2].count == 2,
              let a = Int(morceaux[0]), let m = Int(morceaux[1]), let j = Int(morceaux[2]) else { return nil }
        var composantes = DateComponents()
        composantes.year = a; composantes.month = m; composantes.day = j
        guard let date = calendrier.date(from: composantes) else { return nil }
        // Refuse le 31 février, que le calendrier corrigerait en silence.
        let relu = calendrier.dateComponents([.year, .month, .day], from: date)
        guard relu.year == a, relu.month == m, relu.day == j else { return nil }
        return date
    }

    /// Le jour de `date`, à Paris, en « aaaa-mm-jj ».
    static func iso(_ date: Date) -> String {
        let c = calendrier.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func annee(_ date: Date) -> Int { calendrier.component(.year, from: date) }

    /// « 2026-12-31 » devient « 31/12/2026 ».
    static func francais(iso: String) -> String {
        let m = iso.split(separator: "-")
        return m.count == 3 ? "\(m[2])/\(m[1])/\(m[0])" : iso
    }

    /// Nombre de jours entiers de `de` à `iso` (négatif si `iso` est passé).
    static func jours(de date: Date, jusquA iso: String) -> Int? {
        guard let fin = Jours.date(iso: iso), let debut = Jours.date(iso: Jours.iso(date)) else { return nil }
        return calendrier.dateComponents([.day], from: debut, to: fin).day
    }
}
