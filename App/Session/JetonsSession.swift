import SwiftUI

/// Jetons de la session : tout pointe vers `App/Style/` (Palette, Police).
enum JetonsSession {
    static let marine = Palette.encre
    static let vert = Palette.marine
    static let papier = Palette.fond
    static let alerte = Palette.alerte

    static func police(_ taille: Font.TextStyle) -> Font { .system(taille, design: .rounded, weight: .heavy) }
}
