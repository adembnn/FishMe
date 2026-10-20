import SwiftUI

// Décors dessinés en code : la lumière et ce qui flotte dans l'eau (rais, reflets, poussières, feuilles, pollen, lueurs,
// bulles, brume), réglés par décor. Fichier PARTAGÉ app + widget (voir DecorsDessinesBase.swift). Tout est calculé à partir
// du seul temps `t` : aucun état. Dans le widget et avec « Réduire les animations », `t` est figé (`tFixe`) et seules les
// bulles (qui n'existent qu'en mouvement) disparaissent.
// Les coordonnées de cette couche sont des parts de la largeur et de la hauteur (comme `EffetsEau`), pas le cadre 390 x 844.

nonisolated extension DecorDessin {
    enum TypeParticule {
        case poussiere, feuille, pollen, lueur
    }

    struct Rais {
        var c: RVB
        var a: Double
        var large: Double = 1
        var n: Int = 5
    }

    struct Caustiques {
        var c: RVB
        var a: Double
        var portee: Double = 1
        var lignes: Int = 9
    }

    struct Particules {
        var type: TypeParticule
        var c: RVB
        var a: Double
        var vitesse: Double = 1
        var feuilles: [UInt32] = []
    }

    struct Bulles {
        var c: RVB
        var y: Double = 0.8
    }

    struct Ambiance {
        var rais: Rais?
        var caustiques: Caustiques?
        var particules: Particules?
        /// Opacité des particules proches (devant les poissons), par rapport à celles du fond.
        var proches: Double = 1
        var bulles: Bulles?
    }

    // MARK: Rais de lumière

    static func rais(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, _ o: Rais) {
        let l = taille.width
        let h = taille.height
        ctx.blendMode = .plusLighter
        for i in 0..<o.n {
            let f = Double(i)
            let centre: CGFloat = CGFloat(0.08 + 0.22 * f + 0.05 * sin(t * 0.045 + f * 1.7)) * l
            let pente: CGFloat = CGFloat(0.20 + 0.05 * sin(t * 0.03 + f)) * l
            let largeur: CGFloat = CGFloat((0.05 + 0.025 * bruit(i, 1)) * o.large) * l
            let force: Double = o.a * (0.45 + 0.55 * (0.5 + 0.5 * sin(t * 0.11 + f * 2.1)))
            var chemin = Path()
            chemin.move(to: CGPoint(x: centre - largeur * 0.5, y: -0.05 * h))
            chemin.addLine(to: CGPoint(x: centre + largeur * 0.5, y: -0.05 * h))
            chemin.addLine(to: CGPoint(x: centre + pente + largeur * 1.2, y: 0.85 * h))
            chemin.addLine(to: CGPoint(x: centre + pente - largeur * 1.2, y: 0.85 * h))
            chemin.closeSubpath()
            let g = degrade([(0, c(o.c, force)), (0.35, c(o.c, force * 0.35)), (1, c(o.c, 0))])
            ctx.fill(chemin, with: .linearGradient(g, startPoint: CGPoint(x: centre, y: 0),
                                                   endPoint: CGPoint(x: centre + pente, y: 0.85 * h)))
        }
        ctx.blendMode = .normal
    }

    // MARK: Reflets de surface

    static func caustiques(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, _ o: Caustiques) {
        let l = taille.width
        let h = taille.height
        ctx.blendMode = .plusLighter
        let segments = 16
        for famille in 0..<2 {
            for i in 0..<o.lignes {
                let f = Double(i)
                let ecart = 0.085 * f * (9.0 / Double(o.lignes))
                let base: CGFloat = CGFloat(0.04 + ecart + 0.012 * sin(t * 0.16 + f * 1.3 + Double(famille))) * h
                let part = min(max(Double(base / (0.8 * h)), 0), 1)
                let vue = 1 - part * o.portee
                let alpha = o.a * max(vue, 0)
                if alpha < 0.004 { continue }
                let k = famille == 0 ? 3.1 : 4.3
                let vitesse = famille == 0 ? 0.33 : -0.27
                let phase = f * 1.9 + Double(famille) * 2.4
                var chemin = Path()
                for s in 0...segments {
                    let u = Double(s) / Double(segments)
                    let x = CGFloat(u) * l
                    let d1 = 0.014 * sin(u * k * Double.pi * 2 + t * vitesse + phase)
                    let d2 = 0.008 * sin(u * (k * 2.3) * Double.pi * 2 - t * vitesse * 1.4 + phase * 0.7)
                    let pente: CGFloat = famille == 1 ? 0.03 * h * CGFloat(u) : 0
                    let y = base + CGFloat(d1 + d2) * h + pente
                    if s == 0 { chemin.move(to: CGPoint(x: x, y: y)) } else { chemin.addLine(to: CGPoint(x: x, y: y)) }
                }
                ctx.stroke(chemin, with: .color(c(o.c, alpha * 0.45)), lineWidth: 7)
                ctx.stroke(chemin, with: .color(c(o.c, alpha)), lineWidth: 1.6)
            }
        }
        ctx.blendMode = .normal
    }

    // MARK: Particules

    /// `de` ..< `jusqua` : les premières sont derrière les poissons, les suivantes devant (plus grosses).
    static func particules(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, de: Int, jusqua: Int, avant: Bool,
                           _ o: Particules, facteur: Double) {
        let l = taille.width
        let h = taille.height
        for i in de..<jusqua {
            let b: (Int) -> Double = { bruit(i, $0) }
            switch o.type {
            case .poussiere:
                let sens: Double = b(5) < 0.5 ? 1 : -1
                let vx: Double = (0.004 + 0.006 * b(2)) * sens * (avant ? 1.6 : 1) * o.vitesse
                let vy: Double = (b(6) - 0.5) * 0.004
                let x = frac(b(0) + t * vx + 0.012 * sin(t * 0.27 + b(3) * 6.28))
                let y = frac(b(1) + t * vy + 0.01 * sin(t * 0.21 + b(4) * 6.28))
                let rayon: Double = (avant ? 1.6 : 0.7) + (avant ? 1.6 : 1.3) * b(7)
                let scint: Double = 0.6 + 0.4 * sin(t * (0.5 + b(8)) + b(9) * 6.28)
                let al: Double = o.a * facteur * (avant ? 0.55 : 1) * (0.4 + 0.6 * b(10)) * scint
                let r = CGRect(x: x * l - rayon, y: y * h - rayon, width: rayon * 2, height: rayon * 2)
                ctx.fill(Path(ellipseIn: r), with: .color(c(o.c, al)))
            case .feuille:
                let x = frac(b(0) + 0.035 * sin(t * 0.35 + b(3) * 6.28) + t * 0.003 * (b(2) - 0.5))
                let y = frac(b(1) + t * (0.012 + 0.012 * b(6)) * (avant ? 1.4 : 1))
                let taillef: Double = (avant ? 9 : 5) + (avant ? 7 : 4) * b(7)
                let teinte = o.feuilles.isEmpty ? 0xB5561F : o.feuilles[min(Int(b(5) * Double(o.feuilles.count)), o.feuilles.count - 1)]
                let angle: Double = t * (b(2) - 0.5) * 1.4 + b(4) * 6.28
                var c2 = ctx
                c2.translateBy(x: x * l, y: y * h)
                c2.rotate(by: .radians(angle))
                c2.opacity = o.a * facteur * (avant ? 0.9 : 0.85)
                let s = CGFloat(taillef)
                var feuille = Path()
                feuille.move(to: CGPoint(x: -s, y: 0))
                feuille.addQuadCurve(to: CGPoint(x: s, y: 0), control: CGPoint(x: -s * 0.2, y: -s * 0.62))
                feuille.addQuadCurve(to: CGPoint(x: -s, y: 0), control: CGPoint(x: -s * 0.2, y: s * 0.62))
                c2.fill(feuille, with: .color(c(teinte)))
                var nerv = Path()
                nerv.move(to: CGPoint(x: -s, y: 0))
                nerv.addLine(to: CGPoint(x: s * 0.7, y: 0))
                c2.stroke(nerv, with: .color(.black.opacity(0.28)), lineWidth: 0.8)
            case .pollen, .lueur:
                let monte: Double = o.type == .pollen ? -1 : 0
                let x = frac(b(0) + 0.02 * sin(t * 0.25 + b(3) * 6.28) + t * (b(2) - 0.5) * 0.006)
                let y = frac(b(1) + monte * t * (0.006 + 0.01 * b(6)) + 0.014 * sin(t * 0.2 + b(4) * 6.28))
                let rayon: Double = (avant ? 1.8 : 1) + (avant ? 1.8 : 1.2) * b(7)
                let pulse: Double = 0.5 + 0.5 * sin(t * (0.4 + b(8) * 0.8) + b(9) * 6.28)
                let al: Double = o.a * facteur * (0.3 + 0.7 * pulse * pulse)
                let centre = CGPoint(x: x * l, y: y * h)
                let rr = CGFloat(rayon * 5)
                let g = degrade([(0, c(o.c, al)), (0.25, c(o.c, al * 0.35)), (1, c(o.c, 0))])
                ctx.fill(Path(ellipseIn: CGRect(x: centre.x - rr, y: centre.y - rr, width: rr * 2, height: rr * 2)),
                         with: .radialGradient(g, center: centre, startRadius: 0, endRadius: rr))
            }
        }
    }

    // MARK: Bulles

    static func bulles(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, _ o: Bulles) {
        let l = taille.width
        let h = taille.height
        let emetteurs: [(Double, Double)] = [(0.13, 27), (0.62, 33), (0.87, 24)]
        for (e, em) in emetteurs.enumerated() {
            for k in 0..<2 {
                let periode = em.1 + Double(k) * 5.5
                let local = (t + bruit(e, 20 + k) * periode).truncatingRemainder(dividingBy: periode)
                guard local < 7 else { continue }
                let u = local / 7
                let monte = 1 - pow(1 - u, 1.6)
                let y = CGFloat(o.y - monte * (o.y - 0.10)) * h
                let x = CGFloat(em.0 + 0.012 * sin(u * 11 + Double(k) * 2) * (0.3 + u)) * l
                let rayon = CGFloat(1.8 + 2.4 * u + bruit(e, 30 + k))
                let alpha = 0.55 * min(1, u * 10) * (1 - u * u * u)
                let cercle = CGRect(x: x - rayon, y: y - rayon, width: rayon * 2, height: rayon * 2)
                ctx.stroke(Path(ellipseIn: cercle), with: .color(c(o.c, alpha * 0.8)), lineWidth: 0.9)
                ctx.fill(Path(ellipseIn: cercle), with: .color(c(o.c, alpha * 0.08)))
                let reflet = CGRect(x: x - rayon * 0.45, y: y - rayon * 0.55, width: rayon * 0.5, height: rayon * 0.4)
                ctx.fill(Path(ellipseIn: reflet), with: .color(c(o.c, alpha * 0.9)))
            }
        }
    }

    // MARK: Lueurs et brume

    /// Une tache de lumière elliptique : `arrets` va du centre (0) au bord (1) de l'ellipse de rayons `rx`, `ry`.
    static func lueur(_ ctx: GraphicsContext, centre: CGPoint, rx: CGFloat, ry: CGFloat, arrets: [(Double, Color)]) {
        var c2 = ctx
        c2.translateBy(x: centre.x, y: centre.y)
        c2.scaleBy(x: 1, y: ry / max(rx, 0.001))
        let disque = Path(ellipseIn: CGRect(x: -rx, y: -rx, width: rx * 2, height: rx * 2))
        c2.fill(disque, with: .radialGradient(degrade(arrets), center: .zero, startRadius: 0, endRadius: rx))
    }

    /// Un voile sombre sur les bords : transparent au centre, plein au-delà de l'ellipse.
    static func vignette(_ ctx: GraphicsContext, taille: CGSize, cx: Double, cy: Double, rx: Double, ry: Double,
                         debut: Double, c couleur: RVB, a: Double) {
        let rxp = CGFloat(rx) * taille.width
        let ryp = CGFloat(ry) * taille.height
        var c2 = ctx
        c2.translateBy(x: CGFloat(cx) * taille.width, y: CGFloat(cy) * taille.height)
        c2.scaleBy(x: 1, y: ryp / max(rxp, 0.001))
        let g = degrade([(0, c(couleur, 0)), (debut, c(couleur, 0)), (1, c(couleur, a))])
        let grand = Path(CGRect(x: -6000, y: -6000, width: 12000, height: 12000))
        c2.fill(grand, with: .radialGradient(g, center: .zero, startRadius: 0, endRadius: rxp))
    }

    /// Une brume basse qui dérive très lentement d'un côté à l'autre (70 s l'aller).
    static func brume(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, c1: Color, c2: Color) {
        let l = taille.width
        let h = taille.height
        let kx = l / 390
        let ky = h / 844
        let u = (t / 70).truncatingRemainder(dividingBy: 2)
        let aller = u < 1 ? u : 2 - u
        let decalage = -l * CGFloat(aller)
        // (centre x, centre y, rayon x, rayon y, couleur 1 ou 2) en parts du cadre 390 x 844
        let taches: [(CGFloat, CGFloat, CGFloat, CGFloat, Int)] = [
            (0.25, 0.62, 120, 70, 1), (0.70, 0.70, 160, 80, 1), (1.00, 0.58, 130, 60, 2),
            (0.45, 0.80, 140, 70, 2), (0.88, 0.78, 150, 80, 1),
        ]
        for copie in 0..<2 {
            for tache in taches {
                let cx = tache.0 * l + CGFloat(copie) * l + decalage
                if cx < -tache.2 * kx || cx > l + tache.2 * kx { continue }
                let col = tache.4 == 1 ? c1 : c2
                lueur(ctx, centre: CGPoint(x: cx, y: tache.1 * h), rx: tache.2 * kx, ry: tache.3 * ky,
                      arrets: [(0, col), (0.7, col.opacity(0)), (1, col.opacity(0))])
            }
        }
    }

    // MARK: L'ensemble

    /// Rais, reflets, particules du fond, bulles : derrière les poissons.
    static func ambianceArriere(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, _ a: Ambiance) {
        if let r = a.rais { rais(&ctx, taille: taille, t: t, r) }
        if let k = a.caustiques { caustiques(&ctx, taille: taille, t: t, k) }
        if let p = a.particules { particules(&ctx, taille: taille, t: t, de: 0, jusqua: 26, avant: false, p, facteur: 1) }
    }

    /// Particules proches et bulles : devant les poissons.
    static func ambianceAvant(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, _ a: Ambiance, bulles avecBulles: Bool) {
        if let p = a.particules { particules(&ctx, taille: taille, t: t, de: 26, jusqua: 35, avant: true, p, facteur: a.proches) }
        if avecBulles, let b = a.bulles { bulles(&ctx, taille: taille, t: t, b) }
    }
}
