import SwiftUI

/// Jetons du lot L13 : ils pointent vers les jetons communs de `App/Style/Style.swift`.
/// Les vues du dossier gardent ces noms ; la couleur, la police et la taille viennent de `Palette`, `Police`, `Gabarit`.
enum JetonsConseils {
    static let accent = Palette.marine
    static let marne = Palette.encre
    static let alerte = Palette.alerte
    static let tailleToucher: CGFloat = Gabarit.zoneTactile

    static func police(_ style: Font.TextStyle) -> Font {
        .system(style, design: .rounded, weight: .bold)
    }
}
