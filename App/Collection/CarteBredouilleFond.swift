import SwiftUI

/// Le décor de la carte « Eau calme » : une eau lisse à l'aube, dessinée en SwiftUI (aucune image à embarquer, nette à toutes les tailles).
/// Ciel aqua, horizon rose pâle, soleil bas, sa colonne de lumière sur l'eau, cercles d'ondes autour d'un bouchon, un peu de brume.
/// Les tailles sont en pourcentage de la largeur, comme le reste des cartes.
struct EauCalmeFond: View {
    /// Dessine le bouchon et ses ondes (sans photo). Avec une photo de soi, on garde seulement la lumière.
    var avecBouchon = true

    var body: some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: Color(carte: 0xB7E3EC), location: 0),
                .init(color: Color(carte: 0xE3F0EA), location: 0.20),
                .init(color: Color(carte: 0xF8DFC6), location: 0.285),
                .init(color: Color(carte: 0xF2C3A4), location: 0.31),
                .init(color: Color(carte: 0x8FCBD2), location: 0.34),
                .init(color: Color(carte: 0x4F9DB4), location: 0.62),
                .init(color: Color(carte: 0x20677F), location: 1),
            ], startPoint: .top, endPoint: .bottom)
            Canvas { contexte, taille in
                dessiner(&contexte, taille)
            }
        }
        .accessibilityHidden(true)
    }

    private func dessiner(_ c: inout GraphicsContext, _ t: CGSize) {
        let w = t.width, h = t.height
        guard w > 0 else { return }
        let u = w / 100
        let horizon = h * 0.31
        let soleil = CGPoint(x: w * 0.70, y: horizon)

        // Lueur du soleil bas.
        let lueur = Path(ellipseIn: CGRect(x: soleil.x - 46 * u, y: soleil.y - 30 * u, width: 92 * u, height: 60 * u))
        c.fill(lueur, with: .radialGradient(
            Gradient(colors: [Color(carte: 0xFFF3D6).opacity(0.85), Color(carte: 0xFFD9A8).opacity(0.35), .clear]),
            center: soleil, startRadius: 0, endRadius: 46 * u))
        c.fill(Path(ellipseIn: CGRect(x: soleil.x - 6 * u, y: soleil.y - 6 * u, width: 12 * u, height: 12 * u)),
               with: .color(Color(carte: 0xFFF8E8).opacity(0.95)))

        // Rive lointaine, très douce.
        var rive = Path()
        rive.move(to: CGPoint(x: 0, y: horizon))
        rive.addCurve(to: CGPoint(x: w * 0.55, y: horizon - 1.4 * u),
                      control1: CGPoint(x: w * 0.15, y: horizon - 3.2 * u), control2: CGPoint(x: w * 0.35, y: horizon - 0.2 * u))
        rive.addCurve(to: CGPoint(x: w, y: horizon - 0.6 * u),
                      control1: CGPoint(x: w * 0.72, y: horizon - 2.6 * u), control2: CGPoint(x: w * 0.9, y: horizon - 1.2 * u))
        rive.addLine(to: CGPoint(x: w, y: horizon))
        rive.closeSubpath()
        c.fill(rive, with: .color(Color(carte: 0x6FA6A8).opacity(0.45)))

        // Colonne de lumière sur l'eau : traits courts qui s'élargissent vers le bas.
        var y = horizon + 1.4 * u
        var i = 0
        while y < h * 0.80 {
            let progression = (y - horizon) / (h * 0.5)
            let demi = (3 + progression * 16) * u * (i % 2 == 0 ? 1 : 0.62)
            let decalage = (i % 3 == 0 ? -1.2 : (i % 3 == 1 ? 0.8 : 0)) * u
            let trait = Path(roundedRect: CGRect(x: soleil.x + decalage - demi, y: y, width: demi * 2, height: 0.5 * u), cornerRadius: 0.25 * u)
            c.fill(trait, with: .color(Color(carte: 0xFFF1D2).opacity(max(0.06, 0.5 - progression * 0.7))))
            y += (1.8 + progression * 2.2) * u
            i += 1
        }

        // Légères rides sur toute l'eau.
        var r = 0
        var yr = horizon + 5 * u
        while yr < h {
            let x0 = (CGFloat((r * 37) % 70) + 4) * u
            let longueur = (10 + CGFloat((r * 13) % 16)) * u
            c.stroke(Path { p in
                p.move(to: CGPoint(x: x0, y: yr))
                p.addQuadCurve(to: CGPoint(x: x0 + longueur, y: yr), control: CGPoint(x: x0 + longueur / 2, y: yr - 0.8 * u))
            }, with: .color(.white.opacity(0.16)), lineWidth: 0.35 * u)
            yr += 5.5 * u
            r += 1
        }

        // Cercles d'ondes autour du bouchon (ou du point de chute), aplatis par la perspective.
        let centre = CGPoint(x: w * 0.40, y: h * 0.455)
        let aplat: CGFloat = 0.26
        for k in 1...6 {
            let rayon = CGFloat(k) * 8.5 * u
            let ellipse = Path(ellipseIn: CGRect(x: centre.x - rayon, y: centre.y - rayon * aplat, width: rayon * 2, height: rayon * 2 * aplat))
            c.stroke(ellipse, with: .color(.white.opacity(0.6 - Double(k) * 0.08)), lineWidth: max(0.5, 0.55 * u - CGFloat(k) * 0.04 * u))
        }

        if avecBouchon {
            // Le bouchon : rouge au-dessus de l'eau, blanc dessous, avec un reflet.
            let b = CGPoint(x: centre.x, y: centre.y - 1.2 * u)
            c.fill(Path(ellipseIn: CGRect(x: b.x - 4 * u, y: b.y + 3.2 * u, width: 8 * u, height: 2.2 * u)),
                   with: .color(Color(carte: 0x1D5E75).opacity(0.35)))
            c.fill(Path(ellipseIn: CGRect(x: b.x - 3 * u, y: b.y - 4.4 * u, width: 6 * u, height: 8 * u)),
                   with: .color(Color(carte: 0xFFFFFF)))
            var haut = c
            haut.clip(to: Path(CGRect(x: b.x - 4 * u, y: b.y - 6 * u, width: 8 * u, height: 5.2 * u)))
            haut.fill(Path(ellipseIn: CGRect(x: b.x - 3 * u, y: b.y - 4.4 * u, width: 6 * u, height: 8 * u)),
                      with: .color(Color(carte: 0xE8571C)))
            var antenne = Path()
            antenne.move(to: CGPoint(x: b.x, y: b.y - 4.4 * u))
            antenne.addLine(to: CGPoint(x: b.x, y: b.y - 8.4 * u))
            c.stroke(antenne, with: .color(Color(carte: 0x0E1A26).opacity(0.8)), lineWidth: 0.5 * u)
        }

        // Brume à l'horizon.
        for (x, ep, a) in [(0.18, 0.5, 0.40), (0.62, 0.44, 0.34), (0.95, 0.40, 0.30)] as [(Double, Double, Double)] {
            let ellipse = Path(ellipseIn: CGRect(x: w * x - 34 * u, y: horizon - 3 * u, width: 68 * u, height: 7 * u))
            c.fill(ellipse, with: .radialGradient(Gradient(colors: [.white.opacity(a), .clear]),
                                                  center: CGPoint(x: w * x, y: horizon + 0.5 * u), startRadius: 0, endRadius: 34 * u * ep * 2))
        }
    }
}
