import SwiftUI

/// Jetons de style PROVISOIRES de l'écran Prise, tous ici : quand App/Style (lot D0, posé par A) existera,
/// ce fichier seul change. Style « Natif », SF Pro Rounded en gras.
enum PriseJetons {
    static let encre = Color(red: 0.024, green: 0.220, blue: 0.302)       // #06384D
    static let accent = Color(red: 0.082, green: 0.478, blue: 0.306)      // #157A4E
    static let papier = Color(red: 0.965, green: 0.992, blue: 1.0)        // #F6FDFF
    static let fond = Color(red: 0.796, green: 0.937, blue: 0.969)        // #CBEFF7
    static let discret = Color(red: 0.310, green: 0.400, blue: 0.451)     // #4F6673
    static let mise = Color(red: 0.118, green: 0.357, blue: 0.722)        // #1E5BB8

    static let rayon: CGFloat = 20
    static let cibleMin: CGFloat = 44

    static func titre() -> Font { .system(.title2, design: .rounded, weight: .heavy) }
    static func corps() -> Font { .system(.body, design: .rounded, weight: .bold) }
    static func legende() -> Font { .system(.footnote, design: .rounded, weight: .bold) }
    static func chiffre() -> Font { .system(.largeTitle, design: .rounded, weight: .heavy) }
}

/// Bouton principal : pleine largeur, au moins 44 points de haut.
struct PriseBoutonPrincipal: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PriseJetons.corps())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 16)
            .background(PriseJetons.accent.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
    }
}

struct PriseBoutonSecondaire: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PriseJetons.corps())
            .foregroundStyle(PriseJetons.encre)
            .frame(maxWidth: .infinity, minHeight: PriseJetons.cibleMin + 8)
            .padding(.horizontal, 16)
            .background(PriseJetons.papier.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .overlay(Capsule().stroke(PriseJetons.encre.opacity(0.15), lineWidth: 1))
    }
}
