import Foundation

/// La liste fermée des symboles SF permis pour un conseil. L13 vérifie sur l'iPhone que chacun existe.
public enum IconesConseils {
    public static let autorisees: [String] = [
        "fish", "fish.fill", "fork.knife", "scope", "figure.fishing", "calendar", "sun.max", "moon",
        "cloud.sun", "water.waves", "drop", "thermometer.medium", "tortoise", "hare", "eye", "leaf",
        "tree", "sparkles", "clock",
    ]

    /// Une icône par type par défaut.
    public static func parDefaut(_ type: TypeConseil) -> String {
        switch type {
        case .appat: return "fork.knife"
        case .hamecon: return "scope"
        case .technique: return "figure.fishing"
        case .moment: return "calendar"
        }
    }

    public static func estAutorisee(_ nom: String) -> Bool {
        autorisees.contains(nom)
    }
}
