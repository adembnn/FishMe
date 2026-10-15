import SwiftUI

/// Jetons provisoires du lot L13, dans UN fichier : style « Natif », SF Pro Rounded en gras (Adem, 15 oct.).
/// Quand App/Style/ existera, ce fichier disparaît et les vues lisent les jetons communs.
enum JetonsConseils {
    static let accent = Color(red: 0x1E / 255, green: 0x7F / 255, blue: 0x4F / 255)   // vert des maquettes
    static let marne = Color(red: 0x17 / 255, green: 0x40 / 255, blue: 0x3F / 255)
    static let alerte = Color(red: 0xB4 / 255, green: 0x3A / 255, blue: 0x1F / 255)
    static let tailleToucher: CGFloat = 44

    static func police(_ style: Font.TextStyle) -> Font {
        .system(style, design: .rounded, weight: .bold)
    }
}
