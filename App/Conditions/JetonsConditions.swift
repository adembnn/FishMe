import SwiftUI

// Jetons provisoires du lot L12 (style « Natif », SF Pro Rounded gras). À remplacer par App/Style/ quand il existe.
enum JetonsConditions {
    static func police(_ style: Font.TextStyle) -> Font { .system(style, design: .rounded).weight(.bold) }

    static var encre: Color { Color(red: 0x14 / 255, green: 0x18 / 255, blue: 0x1B / 255) }
    static var encre2: Color { Color(red: 0x4F / 255, green: 0x57 / 255, blue: 0x5D / 255) }
    static var filet: Color { Color(red: 0xC9 / 255, green: 0xCE / 255, blue: 0xD2 / 255) }
    static var accent: Color { Color(red: 0x1E / 255, green: 0x7F / 255, blue: 0x4F / 255) }
    static var haut: Color { .orange }
    static var crue: Color { .red }
}
