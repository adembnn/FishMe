import SwiftUI

/// Anciens noms des jetons du paywall et du consentement : ils pointent maintenant vers `App/Style/Style.swift`.
enum JetonsAbonnement {
    static let marine = Palette.encre
    static let vert = Palette.marine
    static let papier = Palette.surface

    static func police(_ taille: Font.TextStyle) -> Font { .system(taille, design: .rounded, weight: .heavy) }
    static func texte(_ taille: Font.TextStyle) -> Font { .system(taille, design: .rounded, weight: .bold) }
}
