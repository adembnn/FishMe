import SwiftUI
import Core

// Jetons provisoires du lot Carte : un seul fichier, à remplacer par App/Style/ quand il existera.
// Cible : « Natif » façon Plans d'Apple, SF Pro Rounded gras, un vert d'eau (#1E7F4F) comme seule audace.

enum CouleursCarte {
    static let accent = Color(red: 0.118, green: 0.498, blue: 0.310)
    static let encreDouce = Color.secondary
    static let filet = Color.primary.opacity(0.12)
    static let alerte = Color(red: 0.78, green: 0.25, blue: 0.16)
    static let attention = Color(red: 0.80, green: 0.50, blue: 0.05)

    static func rarete(_ niveau: NiveauRarete) -> Color {
        switch niveau {
        case .commun: return Color(red: 0.42, green: 0.47, blue: 0.50)
        case .peuCommun: return Color(red: 0.16, green: 0.45, blue: 0.70)
        case .rare: return Color(red: 0.50, green: 0.30, blue: 0.70)
        case .legendaire: return Color(red: 0.80, green: 0.50, blue: 0.05)
        case .nonMesuree: return Color.secondary
        }
    }
}

enum PolicesCarte {
    static func titre() -> Font { .system(.title2, design: .rounded, weight: .bold) }
    static func corps() -> Font { .system(.body, design: .rounded, weight: .bold) }
    static func detail() -> Font { .system(.subheadline, design: .rounded, weight: .bold) }
    static func legende() -> Font { .system(.caption, design: .rounded, weight: .bold) }
}

extension NiveauRarete {
    var libelle: String {
        switch self {
        case .commun: return "Commun"
        case .peuCommun: return "Peu commun"
        case .rare: return "Rare"
        case .legendaire: return "Légendaire"
        case .nonMesuree: return "Rareté non mesurée"
        }
    }
}

extension OuvertureDuJour {
    /// « ouverte aujourd'hui » ou « fermée jusqu'au 25/04 » ; sans date connue, « fermée ».
    var texte: String {
        switch self {
        case .ouverte: return "ouverte aujourd'hui"
        case .fermee(let date):
            guard let date else { return "fermée" }
            return "fermée jusqu'au " + date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).locale(Locale(identifier: "fr_FR")))
        }
    }

    var estOuverte: Bool {
        if case .ouverte = self { return true }
        return false
    }
}

/// « N pêches, dernier relevé AAAA » : chaque chiffre OFB porte son nombre de pêches et son année (aucune fausse donnée).
nonisolated func texteReleve(nPeches: Int, annee: Int?) -> String {
    let mot = nPeches > 1 ? "pêches" : "pêche"
    guard let annee else { return "\(nPeches) \(mot)" }
    return "\(nPeches) \(mot), dernier relevé \(annee)"
}
