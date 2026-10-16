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

/// Le fond de carte des maquettes P17 et P47 : un parc, des rues blanches et la rivière qui serpente, dessinés sans aucun lieu réel
/// (aucune position exacte). Les formes suivent les maquettes, mesurées sur 390 × 844.
struct FondCarteSession: View {
    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 390
            let sy = size.height / 844
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Palette.fond))
            // Parc en haut à droite.
            ctx.fill(Path(ellipseIn: CGRect(x: 270 * sx, y: 10 * sy, width: 200 * sx, height: 190 * sy)),
                     with: .color(Palette.ouvertDoux))
            // Rues.
            var rues = Path()
            rues.move(to: pt(60, 0)); rues.addQuadCurve(to: pt(105, 330), control: pt(70, 200))
            rues.move(to: pt(150, 60)); rues.addLine(to: pt(340, 40))
            rues.move(to: pt(0, 300)); rues.addQuadCurve(to: pt(160, 325), control: pt(80, 295))
            rues.move(to: pt(300, 430)); rues.addQuadCurve(to: pt(390, 450), control: pt(340, 430))
            ctx.stroke(rues, with: .color(Palette.surface), style: StrokeStyle(lineWidth: 8 * sx, lineCap: .round))
            // Rivière : large trait clair dessous, trait plus étroit dessus.
            var riviere = Path()
            riviere.move(to: pt(-20, 185))
            riviere.addCurve(to: pt(215, 235), control1: pt(80, 165), control2: pt(180, 170))
            riviere.addCurve(to: pt(280, 420), control1: pt(310, 300), control2: pt(330, 350))
            riviere.addCurve(to: pt(250, 880), control1: pt(240, 540), control2: pt(230, 700))
            ctx.stroke(riviere, with: .color(Palette.eauClaire), style: StrokeStyle(lineWidth: 64 * sx, lineCap: .round, lineJoin: .round))
            ctx.stroke(riviere, with: .color(Palette.eau), style: StrokeStyle(lineWidth: 50 * sx, lineCap: .round, lineJoin: .round))
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
