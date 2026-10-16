import SwiftUI

/// Carte qui charge : un sonar (« Sonar », carte-sonar). Transparent, il se pose sur la carte.
/// Un faisceau marine tourne autour du centre de la vue (la position du pêcheur) ;
/// chaque station qu'il croise fait un petit écho de 0,3 s. Un tour dure 2,4 s.
struct ChargementSonar: View {
    /// Positions relatives (0…1) dans la vue. Facultatives : sans elles, six points fixes.
    var stations: [CGPoint] = []

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var visible = false

    private let dureeTour = 2.4
    private let dureeEcho = 0.3

    /// Six points agréables et fixes, quand on ne donne pas de stations.
    private static let pointsParDefaut: [CGPoint] = [
        CGPoint(x: 0.24, y: 0.30), CGPoint(x: 0.72, y: 0.22), CGPoint(x: 0.84, y: 0.52),
        CGPoint(x: 0.58, y: 0.74), CGPoint(x: 0.22, y: 0.66), CGPoint(x: 0.40, y: 0.46)
    ]

    private var points: [CGPoint] { stations.isEmpty ? Self.pointsParDefaut : stations }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !visible || reduireAnimations)) { contexte in
            let t = contexte.date.timeIntervalSinceReferenceDate
            Canvas { gc, taille in
                dessiner(&gc, taille: taille, t: t)
            }
        }
        .overlay(alignment: .bottom) {
            Text("Je cherche les relevés OFB")
                .font(Police.legende)
                .foregroundStyle(Palette.encre)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 120)
        }
        .allowsHitTesting(false)
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Je cherche les relevés OFB")
        .accessibilityAddTraits(.updatesFrequently)
    }

    // MARK: Dessin

    private func dessiner(_ gc: inout GraphicsContext, taille: CGSize, t: Double) {
        let centre = CGPoint(x: taille.width / 2, y: taille.height / 2)
        let portee = max(taille.width, taille.height)
        let depart = -Double.pi / 2
        let tour = 2 * Double.pi
        let phase = (t / dureeTour).truncatingRemainder(dividingBy: 1)
        let angle = depart + tour * phase

        // Anneaux de portée.
        for rayon in [0.14, 0.28, 0.42, 0.56] {
            var anneau = Path()
            anneau.addEllipse(in: CGRect(x: centre.x - portee * rayon, y: centre.y - portee * rayon,
                                         width: portee * rayon * 2, height: portee * rayon * 2))
            gc.stroke(anneau, with: .color(Palette.marine.opacity(0.08)), lineWidth: 1)
        }

        // Faisceau : un secteur en dégradé angulaire, plus dense à son bord avant.
        if !reduireAnimations {
            let ouverture = 1.35
            let part = ouverture / tour
            let degrade = Gradient(stops: [
                .init(color: Palette.marine.opacity(0), location: 0),
                .init(color: Palette.marine.opacity(0.04), location: part * 0.6),
                .init(color: Palette.marine.opacity(0.12), location: part),
                .init(color: Palette.marine.opacity(0), location: min(0.999, part + 0.0006)),
                .init(color: Palette.marine.opacity(0), location: 1)
            ])
            var disque = Path()
            disque.addEllipse(in: CGRect(x: centre.x - portee, y: centre.y - portee, width: portee * 2, height: portee * 2))
            gc.fill(disque, with: .conicGradient(degrade, center: centre, angle: .radians(angle - ouverture)))

            var trait = Path()
            trait.move(to: centre)
            trait.addLine(to: CGPoint(x: centre.x + cos(angle) * portee, y: centre.y + sin(angle) * portee))
            let fil = Gradient(colors: [Palette.marine.opacity(0.4), Palette.marine.opacity(0)])
            gc.stroke(trait, with: .linearGradient(fil, startPoint: centre,
                                                    endPoint: CGPoint(x: centre.x + cos(angle) * portee, y: centre.y + sin(angle) * portee)),
                      style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }

        // Stations : un point, qui fait un écho quand le faisceau passe.
        for point in points {
            let x = point.x * taille.width
            let y = point.y * taille.height
            let phi = atan2(y - centre.y, x - centre.x)
            var tours = (phi - depart).truncatingRemainder(dividingBy: tour)
            if tours < 0 { tours += tour }
            // Temps écoulé depuis le dernier passage du faisceau sur ce point.
            var age = (phase - tours / tour) * dureeTour
            if age < 0 { age += dureeTour }

            var luminosite = 0.9
            if !reduireAnimations {
                luminosite = 0.35 + 0.65 * (1 - age / dureeTour)
                if age < dureeEcho {
                    let q = age / dureeEcho
                    let e = 1 - pow(1 - q, 3)
                    let r = 6 + 22 * e
                    var echo = Path()
                    echo.addEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                    gc.stroke(echo, with: .color(Palette.marine.opacity(0.6 * (1 - q))), lineWidth: 2.4 - 1.8 * q)
                }
            }
            var pastille = Path()
            pastille.addEllipse(in: CGRect(x: x - 5, y: y - 5, width: 10, height: 10))
            gc.fill(pastille, with: .color(Palette.marine.opacity(luminosite)))
            gc.stroke(pastille, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
        }

        // Position du pêcheur au centre.
        var halo = Path()
        halo.addEllipse(in: CGRect(x: centre.x - 14, y: centre.y - 14, width: 28, height: 28))
        gc.fill(halo, with: .color(Palette.marine.opacity(0.15)))
        var moi = Path()
        moi.addEllipse(in: CGRect(x: centre.x - 6, y: centre.y - 6, width: 12, height: 12))
        gc.fill(moi, with: .color(Palette.marine))
        gc.stroke(moi, with: .color(.white), lineWidth: 2)
    }
}

#if DEBUG
#Preview("Sonar") {
    ZStack {
        Palette.eauClaire
        ChargementSonar()
    }
    .ignoresSafeArea()
}

#Preview("Sonar sombre") {
    ZStack {
        Palette.eauClaire
        ChargementSonar(stations: [CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.7, y: 0.6)])
    }
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
}
#endif
