import SwiftUI

/// Jetons provisoires du paywall et du consentement (style « Natif », SF Pro Rounded gras) : à remplacer par `App/Style/` quand il existera.
enum JetonsAbonnement {
    static let marine = Color(red: 0.024, green: 0.220, blue: 0.302)
    static let vert = Color(red: 0.082, green: 0.478, blue: 0.306)
    static let papier = Color(red: 0.965, green: 0.992, blue: 1.0)

    static func police(_ taille: Font.TextStyle) -> Font { .system(taille, design: .rounded).weight(.heavy) }
    static func texte(_ taille: Font.TextStyle) -> Font { .system(taille, design: .rounded).weight(.medium) }
}
