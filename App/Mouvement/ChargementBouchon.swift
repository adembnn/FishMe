import SwiftUI

/// Petite attente : un bouchon de pêche qui flotte (« Bouchon qui flotte », attente-bouchon).
/// Il plonge de 6 points en 1,4 s, deux ondes s'élargissent à chaque plongée,
/// et la partie immergée se voit à travers l'eau.
struct ChargementBouchon: View {
    var taille: CGFloat = 56
    var texte: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @Environment(\.locale) private var locale
    /// Vrai quand la vue est à l'écran : sinon l'animation est en pause.
    @State private var visible = false

    private let duree = 1.4

    var body: some View {
        VStack(spacing: 6) {
            TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !visible)) { contexte in
                let t = contexte.date.timeIntervalSinceReferenceDate
                Canvas { gc, taille in
                    dessiner(&gc, taille: taille, t: t)
                }
                // Réduire les animations : bouchon immobile, léger fondu doux.
                .opacity(reduireAnimations ? Self.respiration(t) : 1)
            }
            .frame(width: taille * 1.9, height: taille * 1.1)

            if let texte {
                Text(AnglaisE.t(texte, locale))
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AnglaisE.t(texte ?? "Chargement", locale))
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// Opacité douce (0,5 à 1) pour « réduire les animations ».
    private static func respiration(_ t: Double) -> Double {
        let onde: Double = sin(t * 2 * Double.pi / 2.4)
        return 0.75 + 0.25 * onde
    }

    // MARK: Dessin

    private func dessiner(_ gc: inout GraphicsContext, taille zone: CGSize, t: Double) {
        let s = taille / 70
        let cx = zone.width / 2
        let eau = zone.height * 0.72
        let p: Double = reduireAnimations ? 0 : (t / duree).truncatingRemainder(dividingBy: 1)
        let dy: Double = 3 * (1 - cos(2 * Double.pi * p))
        let inclinaison: Double = reduireAnimations ? 0 : 0.075 * sin(2 * Double.pi * p + 0.5)
        let largeurEau = 56 * s

        let ages = reduireAnimations ? [] : agesOndes(t)

        // Ondes de derrière.
        for age in ages { ondulation(&gc, cx: cx, eau: eau, s: s, age: age, devant: false) }

        // Au-dessus de l'eau.
        do {
            var c = gc
            c.clip(to: Path(CGRect(x: 0, y: 0, width: zone.width, height: eau)))
            placer(&c, cx: cx, eau: eau, s: s, dy: dy, inclinaison: inclinaison)
            dessinerBouchon(&c)
        }

        // Sous l'eau : vu à travers, adouci.
        do {
            var c = gc
            var cuvette = Path()
            cuvette.move(to: CGPoint(x: cx - largeurEau, y: eau))
            cuvette.addLine(to: CGPoint(x: cx + largeurEau, y: eau))
            cuvette.addArc(center: CGPoint(x: cx, y: eau), radius: largeurEau,
                           startAngle: .zero, endAngle: .degrees(180), clockwise: false)
            cuvette.closeSubpath()
            c.clip(to: cuvette)
            c.clip(to: Path(CGRect(x: 0, y: eau, width: zone.width, height: 100 * s)))
            var b = c
            b.opacity = 0.62
            placer(&b, cx: cx, eau: eau, s: s, dy: dy, inclinaison: inclinaison)
            dessinerBouchon(&b)
            let voile = Gradient(stops: [
                .init(color: Palette.eau.opacity(0.62), location: 0),
                .init(color: Palette.eauClaire.opacity(0.55), location: 0.55),
                .init(color: Palette.eauClaire.opacity(0), location: 1)
            ])
            c.fill(Path(CGRect(x: cx - largeurEau, y: eau, width: largeurEau * 2, height: 26 * s)),
                   with: .linearGradient(voile, startPoint: CGPoint(x: 0, y: eau), endPoint: CGPoint(x: 0, y: eau + 24 * s)))
        }

        // Ligne d'eau, plus claire aux bords.
        do {
            var ligne = Path()
            var x = -largeurEau
            while x <= largeurEau {
                let amplitude: CGFloat = reduireAnimations ? 0 : 1
                let o1 = CGFloat(sin(Double(x) * 0.09 - t * 3))
                let o2 = CGFloat(sin(Double(x) * 0.21 + t * 2))
                let y: CGFloat = eau + o1 * 0.5 * s * amplitude + o2 * 0.3 * s * amplitude
                if x == -largeurEau { ligne.move(to: CGPoint(x: cx + x, y: y)) } else { ligne.addLine(to: CGPoint(x: cx + x, y: y)) }
                x += 3
            }
            let degrade = Gradient(stops: [
                .init(color: Palette.marine.opacity(0), location: 0),
                .init(color: Palette.marine.opacity(0.26), location: 0.25),
                .init(color: Palette.marine.opacity(0.26), location: 0.75),
                .init(color: Palette.marine.opacity(0), location: 1)
            ])
            gc.stroke(ligne, with: .linearGradient(degrade, startPoint: CGPoint(x: cx - largeurEau, y: 0), endPoint: CGPoint(x: cx + largeurEau, y: 0)),
                      lineWidth: 1.2)
        }

        // Ménisque autour du bouchon.
        let im = CGFloat(1 - min(1, dy / 6) * 0.2)
        let rx: CGFloat = 12.5 * s * im
        var menisque = Path()
        menisque.addArc(center: .zero, radius: 1, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
        menisque = menisque.applying(CGAffineTransform(scaleX: rx, y: 3 * s).concatenating(CGAffineTransform(translationX: cx, y: eau)))
        gc.stroke(menisque, with: .color(.white.opacity(0.9)), lineWidth: 1.1)

        // Ondes de devant.
        for age in ages { ondulation(&gc, cx: cx, eau: eau, s: s, age: age, devant: true) }
    }

    /// Âges (en secondes) des ondes en vie : deux par plongée, décalées de 0,2 s, vivantes 1,5 s.
    private func agesOndes(_ t: Double) -> [Double] {
        var liste: [Double] = []
        let n0 = floor((t - 0.7) / duree)
        for n in stride(from: n0 - 1, through: n0 + 1, by: 1) {
            for i in 0..<2 {
                let age = t - (n * duree + 0.7 + Double(i) * 0.2)
                if age >= 0 && age < 1.5 { liste.append(age) }
            }
        }
        return liste
    }

    private func ondulation(_ gc: inout GraphicsContext, cx: CGFloat, eau: CGFloat, s: CGFloat, age: Double, devant: Bool) {
        let k = age / 1.5
        let grandit: Double = 9 + 44 * (1 - pow(1 - k, 2.2))
        let rx: CGFloat = CGFloat(grandit) * s
        let ry: CGFloat = rx * 0.27
        let alpha: Double = pow(1 - k, 1.7) * 0.5
        let finesse: Double = 1.7 + (0.5 - 1.7) * k
        let epaisseur: CGFloat = CGFloat(finesse) * max(0.9, s * 0.9)
        var demi = Path()
        demi.addArc(center: .zero, radius: 1, startAngle: devant ? .zero : .degrees(180),
                    endAngle: devant ? .degrees(180) : .degrees(360), clockwise: false)
        let ellipse = demi.applying(CGAffineTransform(scaleX: rx, y: ry).concatenating(CGAffineTransform(translationX: cx, y: eau)))
        gc.stroke(ellipse, with: .color(Palette.marine.opacity(alpha)), lineWidth: epaisseur)
    }

    private func placer(_ c: inout GraphicsContext, cx: CGFloat, eau: CGFloat, s: CGFloat, dy: Double, inclinaison: Double) {
        c.translateBy(x: cx, y: eau - 5 * s + CGFloat(dy) * s)
        c.rotate(by: .radians(inclinaison))
        c.scaleBy(x: s, y: s)
    }

    /// Le bouchon dans son repère (haut -34, bas 22) : orange, bande blanche, marine, antenne fine.
    private func dessinerBouchon(_ gc: inout GraphicsContext) {
        var corps = Path()
        corps.move(to: CGPoint(x: 0, y: -21))
        corps.addCurve(to: CGPoint(x: 11.6, y: 0), control1: CGPoint(x: 9, y: -21), control2: CGPoint(x: 12.2, y: -8))
        corps.addCurve(to: CGPoint(x: 0, y: 22), control1: CGPoint(x: 11, y: 12), control2: CGPoint(x: 6, y: 22))
        corps.addCurve(to: CGPoint(x: -11.6, y: 0), control1: CGPoint(x: -6, y: 22), control2: CGPoint(x: -11, y: 12))
        corps.addCurve(to: CGPoint(x: 0, y: -21), control1: CGPoint(x: -12.2, y: -8), control2: CGPoint(x: -9, y: -21))
        corps.closeSubpath()

        do {
            var c = gc
            c.clip(to: corps)
            c.fill(Path(CGRect(x: -14, y: -24, width: 28, height: 17.5)), with: .color(Palette.bouchon))
            c.fill(Path(CGRect(x: -14, y: -6.5, width: 28, height: 11)), with: .color(.white))
            c.fill(Path(CGRect(x: -14, y: 4.5, width: 28, height: 20)), with: .color(Palette.marine))
            let ombre = Gradient(stops: [
                .init(color: .black.opacity(0.2), location: 0),
                .init(color: .clear, location: 0.32),
                .init(color: .clear, location: 0.62),
                .init(color: .black.opacity(0.24), location: 1)
            ])
            c.fill(Path(CGRect(x: -14, y: -24, width: 28, height: 48)),
                   with: .linearGradient(ombre, startPoint: CGPoint(x: -12, y: 0), endPoint: CGPoint(x: 12, y: 0)))
            c.fill(Path(ellipseIn: CGRect(x: -6.9, y: -18.2, width: 3.4, height: 10.4)), with: .color(.white.opacity(0.55)))
            c.fill(Path(ellipseIn: CGRect(x: -6.3, y: 7, width: 2.6, height: 8)), with: .color(.white.opacity(0.28)))
        }
        gc.stroke(corps, with: .color(Palette.marine.opacity(0.32)), lineWidth: 0.8)

        var antenne = Path()
        antenne.move(to: CGPoint(x: 0, y: -21))
        antenne.addLine(to: CGPoint(x: 0, y: -34))
        gc.stroke(antenne, with: .color(Palette.marine), style: StrokeStyle(lineWidth: 1.7, lineCap: .round))
        gc.fill(Path(ellipseIn: CGRect(x: -1.7, y: -35.9, width: 3.4, height: 3.4)), with: .color(Palette.bouchon))
    }
}

#if DEBUG
#Preview("Bouchon") {
    VStack(spacing: 32) {
        ChargementBouchon(texte: "Chargement du spot")
        ChargementBouchon(taille: 40)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.surface)
}

#Preview("Bouchon sombre") {
    ChargementBouchon(texte: "Chargement")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.surface)
        .preferredColorScheme(.dark)
}
#endif
