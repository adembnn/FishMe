import SwiftUI

/// Anciens noms de jetons du lot Collection : ils pointent maintenant vers `Palette`, `Police` et `Gabarit` (App/Style/Style.swift).
/// Rien n'est défini ici : pour changer une couleur, on change Style.swift.
enum Jeton {
    static let encre = Palette.encre
    static let encreDouce = Palette.encreDouce
    /// Fond d'une carte ou d'une tuile.
    static let papier = Palette.surface
    static let fondPage = Palette.fond
    /// Rareté commune.
    static let ardoise = Palette.commun
    /// Rareté peu commune.
    static let vert = Palette.peuCommun
    /// Rareté rare (violet).
    static let bleu = Palette.rare
    /// Rareté légendaire (or bruni).
    static let bordeaux = Palette.legendaire

    /// Police relative : suit Dynamic Type. La taille demandée choisit le style de texte le plus proche.
    static func police(_ taille: CGFloat, _ graisse: Font.Weight = .bold) -> Font {
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
        return .system(style, design: .rounded, weight: graisse == .semibold ? .bold : graisse)
    }

    /// Taille fixe, pour ce qui vit dans une forme de taille fixe (chiffre d'un badge).
    static func policeFixe(_ taille: CGFloat, _ graisse: Font.Weight = .heavy) -> Font {
        Police.taille(taille, graisse)
    }

    static let zoneTactile: CGFloat = Gabarit.zoneTactile
    /// Toutes les cartes, recto et verso : même rapport largeur sur hauteur.
    static let rapportCarte: CGFloat = Gabarit.rapportCarte
}
