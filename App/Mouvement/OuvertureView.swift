import SwiftUI

// MARK: - Ouverture « Le bond »
//
// Après l'écran de lancement (marine uni), la lune apparaît, le poisson bondit hors du disque,
// replonge avec trois gouttes et trois ondes, puis la lune grandit jusqu'à remplir l'écran
// et le tout s'efface sur l'app. Référence : docs/design/mouvement/sources/anim-lancement.js (variation A).
// Tout est piloté par un seul temps (secondes depuis l'apparition de la vue).

struct OuvertureView: View {
    /// Vrai quand l'app est prête (moteur chargé) : l'ouverture se termine alors, jamais avant que le bond ait replongé.
    var pret: Bool
    /// Appelé quand l'écran s'est ouvert sur l'app (la vue peut alors être retirée).
    var termine: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduireLesAnimations
    @State private var debut = Date()
    @State private var pretDepuis: Double?   // instant (en secondes depuis le début) où l'app est devenue prête
    @State private var fini = false
    @State private var fondu = false         // Réduire les animations : fondu de sortie

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Bond.marine
                if reduireLesAnimations {
                    scene(taille: geo.size, etat: Bond.etat(t: 1, pretDepuis: nil, reduit: true))
                } else {
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: fini)) { contexte in
                        let t = contexte.date.timeIntervalSince(debut)
                        scene(taille: geo.size, etat: Bond.etat(t: t, pretDepuis: pretDepuis, reduit: false))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .opacity(fondu ? 0 : 1)
        .animation(.easeInOut(duration: 0.3), value: fondu)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("FishMe")
        .task {
            // Le son part au début du bond (après l'apparition douce de la lune).
            try? await Task.sleep(for: .seconds(0.2))
            Sons.jouer(.lancement)
        }
        .onChange(of: pret, initial: true) { _, estPret in
            guard estPret, pretDepuis == nil else { return }
            let tp = Date().timeIntervalSince(debut)
            pretDepuis = tp
            if reduireLesAnimations {
                fondu = true
                terminer(dans: 0.3)
            } else {
                terminer(dans: Bond.debutOuverture(apresPret: tp) + Bond.dureeOuverture - tp)
            }
        }
    }

    private func terminer(dans secondes: Double) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(max(0, secondes)))
            fini = true
            termine()
        }
    }

    private func scene(taille: CGSize, etat: Bond.Etat) -> some View {
        let echelle = taille.width / 390
        let centreY = taille.height * 388 / 844
        // Le mot est posé sous la lune, comme dans la référence.
        let ligneDeBase = centreY + (52 * 1.6 + 25) * echelle
        return ZStack {
            Text("FishMe")
                .font(.system(size: 34 * echelle, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .opacity(etat.mot)
                .position(x: taille.width / 2, y: ligneDeBase - 12 * echelle)
                .accessibilityHidden(true)
            Canvas { contexte, taille in
                Bond.dessiner(&contexte, taille, etat)
            }
            .accessibilityHidden(true)
        }
        .opacity(etat.global)
    }
}

// MARK: - Choréographie et dessin (sans acteur : appelé depuis le Canvas)

private nonisolated enum Bond {
    static let marine = Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255)
    static let cycle = 2.4            // la scène boucle au plus toutes les 2,4 s si l'app tarde
    static let plongeeOK = 0.7        // le poisson a le nez dans l'eau : on peut ouvrir
    static let dureeOuverture = 0.47  // de l'agrandissement au fondu final

    struct Etat: Sendable {
        var intro: Double   // apparition douce de la lune (0 à 1)
        var mot: Double     // opacité du mot FishMe
        var b: Double       // lune qui s'éclaire (0 à 1)
        var tl: Double      // temps du bond courant (négatif : avant le bond)
        var ouvert: Bool    // l'ouverture est lancée
        var temps: Double   // temps de la référence pendant l'ouverture (0 sinon)
        var global: Double  // opacité de tout l'écran
        var pulse: Double   // petit battement du halo
        var vague: Double   // petit mouvement de l'eau
    }

    // MARK: Utilitaires

    static func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    static func seg(_ t: Double, _ a: Double, _ b: Double) -> Double { clamp((t - a) / (b - a)) }

    /// Courbe de Bézier d'accélération, comme `cubic-bezier` en CSS.
    static func bez(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        let cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx
        let cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by
        var t = x
        for _ in 0..<8 {
            let e = ((ax * t + bx) * t + cx) * t - x
            if abs(e) < 1e-6 { break }
            let d = (3 * ax * t + 2 * bx) * t + cx
            if abs(d) < 1e-6 { break }
            t -= e / d
        }
        t = clamp(t)
        return ((ay * t + by) * t + cy) * t
    }
    static func eIO(_ x: Double) -> Double { bez(0.65, 0, 0.35, 1, x) }
    static func eOut(_ x: Double) -> Double { bez(0.16, 1, 0.3, 1, x) }
    static func eStd(_ x: Double) -> Double { bez(0.4, 0, 0.2, 1, x) }
    static func eIn(_ x: Double) -> Double { bez(0.5, 0, 0.85, 0.45, x) }

    static func couleur(_ hex: UInt32, _ alpha: Double = 1) -> Color {
        Color(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255).opacity(alpha)
    }

    // MARK: Hauteur de l'eau (courbe statique du logo)

    static let tableEau: [(x: Double, y: Double)] = {
        var table: [(x: Double, y: Double)] = []
        let segments: [[(Double, Double)]] = [
            [(0, 74), (20, 70), (34, 72), (50, 76)],
            [(50, 76), (66, 72), (80, 70), (100, 74)]
        ]
        for p in segments {
            for i in 0...100 {
                let t = Double(i) / 100, u = 1 - t
                let c0: Double = u * u * u, c1: Double = 3 * u * u * t, c2: Double = 3 * u * t * t, c3: Double = t * t * t
                let x: Double = c0 * p[0].0 + c1 * p[1].0 + c2 * p[2].0 + c3 * p[3].0
                let y: Double = c0 * p[0].1 + c1 * p[1].1 + c2 * p[2].1 + c3 * p[3].1
                table.append((x: x, y: y))
            }
        }
        return table
    }()

    static func eauY(_ x: Double) -> Double {
        if x <= 0 || x >= 100 { return 74 }
        for i in 1..<tableEau.count where tableEau[i].x >= x {
            let a = tableEau[i - 1], b = tableEau[i]
            let d = b.x - a.x
            return d < 1e-9 ? b.y : lerp(a.y, b.y, (x - a.x) / d)
        }
        return 74
    }

    // MARK: Trajectoire du poisson (montée freinée, puis chute accélérée)

    static func poisson(_ t: Double) -> (dx: Double, dy: Double, th: Double) {
        let q1 = seg(t, 0.08, 0.34), q2 = seg(t, 0.34, 0.9)
        let dy: Double = q2 > 0 ? -23 + 80 * q2 * q2 : -23 * bez(0.3, 0.5, 0.6, 1, q1)
        let dx: Double = -4 * eStd(seg(t, 0.08, 0.8))
        let th: Double = t < 0.34 ? -28 - 12 * eOut(seg(t, 0.08, 0.34)) : -40 + 112 * eIO(seg(t, 0.34, 0.8))
        return (dx, dy, th)
    }

    /// Instant et lieu où le nez touche l'eau.
    static let entree: (t: Double, x: Double, y: Double) = {
        var tt = 0.4
        while tt < 0.9 {
            let s = poisson(tt)
            let a: Double = s.th * Double.pi / 180
            let nx: Double = 50 + s.dx + 27.36 * cos(a)
            let ny: Double = 46 + s.dy + 27.36 * sin(a)
            if ny >= eauY(nx) + 0.5 { return (tt, nx, eauY(nx)) }
            tt += 0.002
        }
        return (0.6, 78, 73)
    }()

    // MARK: Temps

    /// Quand lancer l'ouverture si l'app est prête à l'instant `tp` : le poisson doit avoir replongé.
    static func debutOuverture(apresPret tp: Double) -> Double {
        let tj = tp - 0.2
        if tj < plongeeOK { return 0.2 + plongeeOK }
        let k = (tj / cycle).rounded(.down)
        let phase = tj - k * cycle
        return phase >= plongeeOK ? tp : 0.2 + k * cycle + plongeeOK
    }

    static func etat(t: Double, pretDepuis: Double?, reduit: Bool) -> Etat {
        if reduit {
            return Etat(intro: 1, mot: 1, b: 0, tl: -1, ouvert: false, temps: 0, global: 1, pulse: 0, vague: 0)
        }
        let tj = t - 0.2
        let intro = eStd(seg(t, 0, 0.2))
        let b = eStd(seg(tj, 0, 0.24))
        let mot = intro * (1 - eStd(seg(tj, 0.12, 0.42)))
        var tl = tj < 0 ? tj : tj.truncatingRemainder(dividingBy: cycle)
        var ouvert = false
        var temps = 0.0
        var global = 1.0
        if let tp = pretDepuis {
            let debutO = debutOuverture(apresPret: tp)
            if t >= debutO {
                ouvert = true
                let phase = (debutO - 0.2).truncatingRemainder(dividingBy: cycle)
                tl = phase + (t - debutO)
                temps = 0.84 + (t - debutO) * 1.25
                global = 1 - eStd(seg(t - debutO, 0.27, 0.47))
            }
        }
        let pulse: Double = sin(t * 2 * Double.pi / 1.8) * 0.012 * b
        let vague: Double = sin(t * 2 * Double.pi / cycle) * 0.6
        return Etat(intro: intro, mot: mot, b: b, tl: tl, ouvert: ouvert, temps: temps, global: global,
                    pulse: pulse, vague: vague)
    }

    // MARK: Formes du logo (repère 0 à 100)

    static func formePoisson() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 86, y: 50))
        p.addCurve(to: CGPoint(x: 59, y: 72), control1: CGPoint(x: 86, y: 62.5), control2: CGPoint(x: 74, y: 72))
        p.addCurve(to: CGPoint(x: 37, y: 59), control1: CGPoint(x: 49, y: 72), control2: CGPoint(x: 42, y: 66))
        p.addCurve(to: CGPoint(x: 12, y: 70), control1: CGPoint(x: 34, y: 55), control2: CGPoint(x: 25, y: 63))
        p.addCurve(to: CGPoint(x: 18.5, y: 50), control1: CGPoint(x: 15.5, y: 63), control2: CGPoint(x: 18, y: 56.5))
        p.addCurve(to: CGPoint(x: 12, y: 30), control1: CGPoint(x: 18, y: 43.5), control2: CGPoint(x: 15.5, y: 37))
        p.addCurve(to: CGPoint(x: 34.5, y: 41.5), control1: CGPoint(x: 23, y: 35), control2: CGPoint(x: 31, y: 45.5))
        p.addCurve(to: CGPoint(x: 66, y: 20), control1: CGPoint(x: 38, y: 37.5), control2: CGPoint(x: 48, y: 24))
        p.addCurve(to: CGPoint(x: 61, y: 28.4), control1: CGPoint(x: 63, y: 22.5), control2: CGPoint(x: 61.5, y: 25.2))
        p.addCurve(to: CGPoint(x: 86, y: 50), control1: CGPoint(x: 75, y: 29.4), control2: CGPoint(x: 86, y: 38))
        p.closeSubpath()
        return p
    }

    /// L'eau du logo ; `vague` bouge un peu les points de contrôle quand on attend.
    static func formeEau(vague: Double) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 74))
        p.addCurve(to: CGPoint(x: 50, y: 76), control1: CGPoint(x: 20, y: 70 + vague), control2: CGPoint(x: 34, y: 72 - vague))
        p.addCurve(to: CGPoint(x: 100, y: 74), control1: CGPoint(x: 66, y: 72 - vague), control2: CGPoint(x: 80, y: 70 + vague))
        p.addLine(to: CGPoint(x: 100, y: 100))
        p.addLine(to: CGPoint(x: 0, y: 100))
        p.closeSubpath()
        return p
    }

    /// Tout ce qui est au-dessus de l'eau (le poisson n'est visible qu'au-dessus).
    static func formeAuDessus() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: -200, y: 74))
        p.addLine(to: CGPoint(x: 0, y: 74))
        p.addCurve(to: CGPoint(x: 50, y: 76), control1: CGPoint(x: 20, y: 70), control2: CGPoint(x: 34, y: 72))
        p.addCurve(to: CGPoint(x: 100, y: 74), control1: CGPoint(x: 66, y: 72), control2: CGPoint(x: 80, y: 70))
        p.addLine(to: CGPoint(x: 300, y: 74))
        p.addLine(to: CGPoint(x: 300, y: -300))
        p.addLine(to: CGPoint(x: -200, y: -300))
        p.closeSubpath()
        return p
    }

    static func transfoPoisson(dx: Double, dy: Double, th: Double) -> CGAffineTransform {
        // Dans l'ordre où elles s'appliquent : la pose du logo, puis le bond.
        var m = CGAffineTransform(translationX: -50, y: -50)
        m = m.concatenating(CGAffineTransform(scaleX: 0.76, y: 0.46))
        m = m.concatenating(CGAffineTransform(rotationAngle: -28 * .pi / 180))
        m = m.concatenating(CGAffineTransform(translationX: 50, y: 46))
        m = m.concatenating(CGAffineTransform(translationX: -50, y: -46))
        m = m.concatenating(CGAffineTransform(rotationAngle: (th + 28) * .pi / 180))
        m = m.concatenating(CGAffineTransform(translationX: 50, y: 46))
        m = m.concatenating(CGAffineTransform(translationX: dx, y: dy))
        return m
    }

    static func cercle(_ cx: Double, _ cy: Double, _ r: Double) -> Path {
        Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: 2 * r, height: 2 * r))
    }

    // MARK: Dessin

    static func dessiner(_ ctx: inout GraphicsContext, _ taille: CGSize, _ e: Etat) {
        let k = 52.0 / 32.0 * Double(taille.width) / 390
        let mx = Double(taille.width) / 2
        let my = Double(taille.height) * 388 / 844
        let ix = mx - 50 * k, iy = my - 48 * k
        let mr = 32 * k
        let a = e.intro

        // Pendant l'ouverture : la lune grandit depuis son centre.
        let x = bez(0.55, 0, 0.2, 1, seg(e.temps, 0.84, 1.28))
        let echelle = 1 + 9.2 * x
        let fonduEau = 1 - eStd(seg(e.temps, 0.88, 1.05))
        let glow = e.b * 0.34 + eIn(seg(e.temps, 1.0, 1.3)) * 0.66

        var c = ctx
        c.translateBy(x: mx, y: my)
        c.scaleBy(x: echelle, y: echelle)
        c.translateBy(x: -mx, y: -my)
        c.translateBy(x: ix, y: iy)
        c.scaleBy(x: k, y: k)

        // Halo : deux couches, la seconde apparaît quand la lune s'éclaire.
        let hs = (0.92 + 0.08 * e.intro) * (1 + e.b * 0.07 + e.pulse)
        for (alpha, rayon) in [(a, 46 * hs), (a * e.b * 0.75, 46 * hs)] where alpha > 0 {
            let degrade = Gradient(stops: [
                .init(color: couleur(0x6FC3FF, 0.35 * alpha), location: 0.6),
                .init(color: couleur(0x6FC3FF, 0), location: 1)
            ])
            c.fill(cercle(50, 48, rayon),
                   with: .radialGradient(degrade, center: CGPoint(x: 50, y: 48), startRadius: 0, endRadius: rayon))
        }

        // Le disque : lune, lueur, eau, ondes, gouttes de la queue.
        c.drawLayer { l in
            l.clip(to: cercle(50, 48, 32))
            let lune = Gradient(stops: [
                .init(color: couleur(0xF4FBFF, a), location: 0),
                .init(color: couleur(0xBFE6FF, a), location: 0.8),
                .init(color: couleur(0x8FD0FF, a), location: 1)
            ])
            l.fill(cercle(50, 48, 32),
                   with: .radialGradient(lune, center: CGPoint(x: 46.8, y: 41.6), startRadius: 0, endRadius: 38.4))
            l.fill(cercle(50, 48, 32), with: .color(couleur(0xF4FBFF, glow * a)))
            l.fill(formeEau(vague: e.vague), with: .color(couleur(0x04122B, fonduEau * a)))

            // Trois ondes concentriques qui s'élargissent et s'effacent, sur l'eau seulement.
            l.drawLayer { o in
                o.clip(to: formeEau(vague: 0))
                let retards = [0.0, 0.09, 0.19]
                for i in 0..<3 {
                    let p = seg(e.tl, entree.t + retards[i], entree.t + retards[i] + 0.6)
                    if p <= 0 || p >= 1 { continue }
                    let rx = 2 + 17 * eOut(p)
                    let ellipse = Path(ellipseIn: CGRect(x: entree.x - rx, y: entree.y + 6 - rx * 0.2,
                                                         width: 2 * rx, height: 2 * rx * 0.2))
                    let decroit: Double = pow(1 - p, 1.35)
                    let alpha: Double = 0.85 * decroit * clamp(p / 0.08) * fonduEau * a
                    o.stroke(ellipse, with: .color(couleur(0x9CC7EA, alpha)), lineWidth: 0.9 * (1 - p) + 0.25)
                }
            }

            // Gouttes qui se détachent de la queue et retombent dans l'eau.
            let depart: [(x: Double, y: Double, r: Double)] = [(20.5, 69, 1.7), (16.5, 65, 1.2), (36, 68.5, 1.2)]
            let vitesse: [(Double, Double)] = [(-7, -22), (-9, -30), (3, -13)]
            let td = max(0, e.tl - 0.08)
            let retour = e.tl < 1.2 ? 1 : seg(e.tl, 1.2, 2.0)
            let alphaGoutte = (1 - seg(td, 0.45, 0.7)) * retour * fonduEau * a
            if alphaGoutte > 0 {
                for i in 0..<3 {
                    let d = depart[i]
                    let gx: Double = d.x + vitesse[i].0 * td * 0.5
                    let gy: Double = d.y + vitesse[i].1 * td + 150 * td * td
                    let gr = d.r * (td > 0 ? 1 - 0.25 * seg(td, 0, 0.3) : 1)
                    l.fill(cercle(gx, gy, gr), with: .color(couleur(0x04122B, alphaGoutte)))
                }
            }
        }

        // Le poisson : visible seulement au-dessus de l'eau, il peut sortir du disque.
        var visibilite = 1.0
        if e.tl >= 0.9 { visibilite = e.ouvert ? 0 : seg(e.tl, 1.5, 2.0) }
        let alphaPoisson = visibilite * a
        if alphaPoisson > 0 {
            let s = poisson(e.tl)
            let m = transfoPoisson(dx: s.dx, dy: s.dy, th: s.th)
            c.drawLayer { l in
                l.clip(to: formeAuDessus())
                l.fill(formePoisson().applying(m), with: .color(couleur(0x04122B, alphaPoisson)))
                let oeil = Path(ellipseIn: CGRect(x: 74 - 3.6, y: 45 - 3.6, width: 7.2, height: 7.2)).applying(m)
                l.fill(oeil, with: .color(couleur(0xBFE6FF, alphaPoisson)))
            }
        }

        // Éclaboussure : trois gouttes en parabole, par-dessus tout (hors du disque aussi).
        let gravite = 330.0
        let jets: [(vx: Double, vy: Double, r: Double)] = [(-15, -54, 1.2), (4, -72, 1.4), (17, -46, 0.95)]
        for j in jets {
            let tau = e.tl - entree.t
            let duree = 2 * -j.vy / gravite
            if tau < 0 || tau > duree { continue }
            let gx: Double = entree.x + j.vx * tau
            let gy: Double = entree.y + j.vy * tau + 0.5 * gravite * tau * tau
            let vy = j.vy + gravite * tau
            let angle = atan2(vy, j.vx)
            let allonge = min(1.7, 1 + abs(vy) / 90)
            let rx = j.r * allonge, ry = j.r / allonge.squareRoot()
            let ellipse = Path(ellipseIn: CGRect(x: gx - rx, y: gy - ry, width: 2 * rx, height: 2 * ry))
            let rotation = CGAffineTransform(translationX: -gx, y: -gy)
                .concatenating(CGAffineTransform(rotationAngle: angle))
                .concatenating(CGAffineTransform(translationX: gx, y: gy))
            let forme = ellipse.applying(rotation)
            c.fill(forme, with: .color(couleur(0x04122B, fonduEau * a)))
            c.stroke(forme, with: .color(couleur(0x8FD0FF, fonduEau * a)), lineWidth: 0.3)
        }

        // La lumière pâle qui devient l'écran de l'app (dans le repère de l'écran).
        let lumiere = clamp(seg(e.temps, 1.0, 1.1))
        if lumiere > 0 {
            let lg = bez(0.3, 0, 0.25, 1, seg(e.temps, 1.0, 1.4))
            let r = mr * echelle + 160 * lg
            let degrade = Gradient(stops: [
                .init(color: couleur(0xF4FBFF, lumiere), location: 0),
                .init(color: couleur(0xEEF5FB, lumiere), location: 0.7),
                .init(color: couleur(0xF2F5F9, lumiere), location: 1)
            ])
            ctx.fill(cercle(mx, my, r),
                     with: .radialGradient(degrade, center: CGPoint(x: mx, y: my - 0.1 * r),
                                           startRadius: 0, endRadius: 1.2 * r))
        }
    }
}

#if DEBUG
#Preview("Ouverture") {
    struct Essai: View {
        @State private var pret = false
        @State private var fini = false
        var body: some View {
            ZStack {
                Color(red: 0.95, green: 0.96, blue: 0.98).ignoresSafeArea()
                Text("L'app").font(.largeTitle.bold())
                if !fini {
                    OuvertureView(pret: pret) { fini = true }
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(0.5))
                pret = true
            }
        }
    }
    return Essai()
}
#endif
