// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// CONTRAT GELÉ : toute modification passe par docs/contrats.md.
import Foundation

/// Les cinq classes de rareté, de la plus fréquente à la plus rare.
public enum RarityTier: Int, Codable, CaseIterable, Comparable, Hashable, Sendable {
    case commune = 0
    case peuCommune = 1
    case rare = 2
    case epique = 3
    case legendaire = 4

    public static func < (lhs: RarityTier, rhs: RarityTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Libellé d'affichage (français).
    public var libelle: String {
        switch self {
        case .commune: return "Commune"
        case .peuCommune: return "Peu commune"
        case .rare: return "Rare"
        case .epique: return "Épique"
        case .legendaire: return "Légendaire"
        }
    }
}

/// Rareté d'une espèce dans un département + la phrase d'affichage officielle.
/// La rareté est une PRÉSENCE dans des relevés scientifiques, jamais une probabilité de capture. // wording-ok
public struct RarityInfo: Codable, Hashable, Sendable {
    public let tier: RarityTier
    /// Fréquence 0...1 (stations avec l'espèce / stations pêchées).
    public let frequence: Double
    public let stationsTotal: Int

    public init(tier: RarityTier, frequence: Double, stationsTotal: Int) {
        self.tier = tier
        self.frequence = min(max(frequence, 0), 1)
        self.stationsTotal = stationsTotal
    }

    public var pourcentageArrondi: Int {
        Int((frequence * 100).rounded())
    }

    /// Libellé EXACT imposé : « présent sur X % des stations scientifiques de l'OFB ».
    /// Cas limite : fréquence > 0 mais arrondie à 0 -> « moins de 1 ».
    public var libelle: String {
        let p = pourcentageArrondi
        if frequence > 0 && p < 1 {
            return "présent sur moins de 1 % des stations scientifiques de l'OFB"
        }
        return "présent sur \(p) % des stations scientifiques de l'OFB"
    }
}
