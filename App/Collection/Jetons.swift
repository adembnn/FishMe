import SwiftUI

/// Jetons provisoires du lot L4 (piste « Natif », SF Pro Rounded gras). À remplacer par App/Style/ quand il existera.
enum Jeton {
    static let encre = Color(red: 0.024, green: 0.220, blue: 0.302)
    static let encreDouce = Color(red: 0.176, green: 0.318, blue: 0.392)
    static let papier = Color(red: 0.965, green: 0.992, blue: 1.0)
    static let fondPage = Color(red: 0.88, green: 0.95, blue: 0.97)
    static let ardoise = Color(red: 0.31, green: 0.40, blue: 0.45)
    static let vert = Color(red: 0.082, green: 0.478, blue: 0.306)
    static let bleu = Color(red: 0.118, green: 0.357, blue: 0.722)
    static let bordeaux = Color(red: 0.48, green: 0.12, blue: 0.24)

    /// Police relative : suit Dynamic Type. La taille demandée choisit le style de texte le plus proche.
    static func police(_ taille: CGFloat, _ graisse: Font.Weight = .heavy) -> Font {
        let style: Font.TextStyle
        switch taille {
        case ..<11.5: style = .caption2
        case ..<12.5: style = .caption
        case ..<14: style = .footnote
        case ..<15.5: style = .subheadline
        case ..<16.5: style = .callout
        case ..<19: style = .body
        case ..<21: style = .title3
        case ..<26: style = .title2
        case ..<32: style = .title
        default: style = .largeTitle
        }
        return .system(style, design: .rounded, weight: graisse)
    }

    /// Taille fixe, pour ce qui vit dans une forme de taille fixe (chiffre d'un badge).
    static func policeFixe(_ taille: CGFloat, _ graisse: Font.Weight = .heavy) -> Font {
        .system(size: taille, weight: graisse, design: .rounded)
    }

    /// Hauteur minimale d'une zone touchable.
    static let zoneTactile: CGFloat = 44
    /// Toutes les cartes, recto et verso : même rapport largeur sur hauteur.
    static let rapportCarte: CGFloat = 5.0 / 7.0
}
