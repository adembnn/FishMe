import SwiftUI

/// Jetons de la session : tout pointe vers `App/Style/` (Palette, Police).
enum JetonsSession {
    static let marine = Palette.encre
    static let vert = Palette.marine
    static let papier = Palette.fond
    static let alerte = Palette.alerte

    static func police(_ taille: Font.TextStyle) -> Font { .system(taille, design: .rounded, weight: .heavy) }
}

/// La feuille de la maquette (`.feuille`) : posée à 8 pt des bords et du bas, coins de 38 pt, poignée, ombre douce.
/// À poser en bas d'un écran qui ignore la zone sûre du bas.
struct FeuilleFlottante<Contenu: View>: View {
    var basPadding: CGFloat = 24
    @ViewBuilder let contenu: Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Palette.filet)
                .frame(width: 36, height: 5)
                .padding(.top, 7)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            contenu
        }
        .padding(.horizontal, 20)
        .padding(.bottom, basPadding)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Le fond de carte des maquettes P17 et P47 : rivière bleue sur fond clair (dessin simple, sans position exacte).
struct FondCarteSession: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.fond
                Palette.eauClaire.frame(height: geo.size.height * 0.2).rotationEffect(.degrees(-12)).offset(y: geo.size.height * 0.05)
                Palette.eau.frame(height: geo.size.height * 0.1).rotationEffect(.degrees(-12)).offset(y: geo.size.height * 0.05)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
