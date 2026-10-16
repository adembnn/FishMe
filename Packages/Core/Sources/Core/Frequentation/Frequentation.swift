import Foundation

/// Niveau de fréquentation d'un tronçon, comparé à sa moyenne des 8 semaines d'avant.
public enum NiveauFrequentation: String, Sendable, Equatable, Hashable, Codable {
    case calme, normal, charge

    public var libelle: String {
        switch self {
        case .calme: return "Calme"
        case .normal: return "Normal"
        case .charge: return "Chargé"
        }
    }
}

/// Un passage anonyme : tronçon, jour (AAAA-MM-JJ, UTC) et jeton du jour.
public struct Passage: Sendable, Equatable, Hashable, Codable {
    public var troncon: String
    public var jour: String
    public var jeton: String

    public init(troncon: String, jour: String, jeton: String) {
        self.troncon = troncon
        self.jour = jour
        self.jeton = jeton
    }
}

/// Jeton qui change chaque jour : stable dans la journée, impossible à relier d'un jour à l'autre sans la graine.
public enum JetonDuJour {
    /// FNV-1a 64 bits sur graine + jour, en hexadécimal (16 caractères).
    public static func jeton(graine: UInt64, jour: String) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        var octets: [UInt8] = []
        var g = graine
        for _ in 0..<8 { octets.append(UInt8(g & 0xff)); g >>= 8 }
        octets.append(contentsOf: Array(jour.utf8))
        for o in octets {
            h ^= UInt64(o)
            h = h &* 0x100000001b3
        }
        let s = String(h, radix: 16)
        return String(repeating: "0", count: 16 - s.count) + s
    }

    /// Le jour UTC au format AAAA-MM-JJ.
    public static func jour(_ date: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let c = cal.dateComponents([.year, .month, .day], from: date)
        let a = c.year ?? 1970, m = c.month ?? 1, j = c.day ?? 1
        func deux(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }
        return "\(a)-\(deux(m))-\(deux(j))"
    }
}

/// Règle de calcul du niveau (docs/frequentation.md, règle 6).
public enum CalculFrequentation {
    public static let seuilPecheurs = 5
    public static let fenetreJours = 7
    public static let semainesHistorique = 8
    public static let facteurCharge = 1.5

    /// nil sous le seuil ; sans historique, « normal ».
    public static func niveau(pecheurs7Jours: Int, moyenneHebdoHistorique: Double?) -> NiveauFrequentation? {
        guard pecheurs7Jours >= seuilPecheurs else { return nil }
        guard let moyenne = moyenneHebdoHistorique, moyenne > 0 else { return .normal }
        let n = Double(pecheurs7Jours)
        if n < moyenne { return .calme }
        if n <= facteurCharge * moyenne { return .normal }
        return .charge
    }

    /// Compte les jetons distincts des 7 derniers jours (aujourd'hui compris) et la moyenne hebdo des 8 semaines d'avant.
    public static func niveau(passages: [Passage], troncon: String, aujourdhui: Date) -> NiveauFrequentation? {
        let fin = JetonDuJour.jour(aujourdhui)
        let debutFenetre = JetonDuJour.jour(aujourdhui.addingTimeInterval(-Double(fenetreJours - 1) * 86_400))
        let debutHistorique = JetonDuJour.jour(
            aujourdhui.addingTimeInterval(-Double(fenetreJours - 1 + 7 * semainesHistorique) * 86_400))
        // Les dates AAAA-MM-JJ se comparent comme du texte.
        var recents = Set<String>()
        var parSemaine: [Int: Set<String>] = [:]
        let debutHistoDate = debutHistorique
        for p in passages where p.troncon == troncon {
            if p.jour >= debutFenetre && p.jour <= fin {
                recents.insert(p.jeton)
            } else if p.jour >= debutHistoDate && p.jour < debutFenetre, let d = date(p.jour) {
                let ecart = Int((aujourdhui.timeIntervalSince(d) / 86_400).rounded(.down))
                let semaine = (ecart - (fenetreJours - 1)) / 7
                if semaine >= 0 && semaine < semainesHistorique { parSemaine[semaine, default: []].insert(p.jeton) }
            }
        }
        let total = parSemaine.values.reduce(0) { $0 + $1.count }
        let moyenne: Double? = total > 0 ? Double(total) / Double(semainesHistorique) : nil
        return niveau(pecheurs7Jours: recents.count, moyenneHebdoHistorique: moyenne)
    }

    private static func date(_ jour: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: jour)
    }
}

public protocol CompteurFrequentation: Sendable {
    func enregistrer(_ p: Passage) async
    func niveau(troncon: String, aujourdhui: Date) async -> NiveauFrequentation?
}

/// Version de la release sans iCloud : ne connaît que les passages de CET iPhone, un par tronçon et par jour.
/// Seul, il ne dépasse jamais le seuil de 5 pêcheurs : il ne montre rien, et c'est voulu
/// (aucune fausse donnée dans la release). L'app sauvegarde `passages` et les redonne à l'init.
public actor CompteurLocal: CompteurFrequentation {
    public private(set) var passages: [Passage]

    public init(passages: [Passage] = []) {
        self.passages = passages
    }

    public func enregistrer(_ p: Passage) {
        if passages.contains(where: { $0.troncon == p.troncon && $0.jour == p.jour }) { return }
        passages.append(p)
    }

    public func niveau(troncon: String, aujourdhui: Date) -> NiveauFrequentation? {
        CalculFrequentation.niveau(passages: passages, troncon: troncon, aujourdhui: aujourdhui)
    }
}

#if DEBUG
/// Pour la démo dans le simulateur seulement : niveaux fixés par tronçon.
public struct CompteurDemo: CompteurFrequentation {
    public let niveaux: [String: NiveauFrequentation]

    public init(niveaux: [String: NiveauFrequentation]) {
        self.niveaux = niveaux
    }

    public func enregistrer(_ p: Passage) async {}

    public func niveau(troncon: String, aujourdhui: Date) async -> NiveauFrequentation? {
        niveaux[troncon]
    }
}
#endif
