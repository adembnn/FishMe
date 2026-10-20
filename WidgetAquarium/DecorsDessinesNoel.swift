import SwiftUI

// Noël : la proposition B « Sapin immergé » de la page noel-ete choisie par Titouan. Glace givrée vue d'en dessous, flocons doux,
// lumière froide bleutée, lit de graviers et de galets poudrés de givre avec reflets, un sapin stylisé à peine éclairé (étoile,
// quelques boules, guirlande discrète) et un second sapin flou au loin. Fichier PARTAGÉ app + widget (voir DecorsDessinesBase.swift).
// Le filtre, les calques et l'ambiance (flocons, rais froids) sont dans `DecorDessin.reglage("noel")`.
// ⚠ à vérifier sur Mac : proportions du sapin, lisibilité des poissons devant lui.

nonisolated extension DecorDessin {
    /// Fil de la guirlande et ses quinze ampoules (position, rayon, couleur, rayon du halo), réparties sur sa longueur.
    private static func ampoulesNoel() -> (fil: [CGPoint], ampoules: [(CGPoint, CGFloat, UInt32, CGFloat)]) {
        let pts: [CGPoint] = [CGPoint(x: 226, y: 500), CGPoint(x: 350, y: 548), CGPoint(x: 232, y: 606),
                              CGPoint(x: 360, y: 664), CGPoint(x: 222, y: 724), CGPoint(x: 356, y: 774)]
        var longueurs: [CGFloat] = []
        for i in 0..<(pts.count - 1) {
            longueurs.append(hypot(pts[i + 1].x - pts[i].x, pts[i + 1].y - pts[i].y))
        }
        let total = longueurs.reduce(0, +)
        var g = GraineDecor(103)
        let couleurs: [UInt32] = [0xFFE1B0, 0xFFD08A, 0xFFE9C8]
        var liste: [(CGPoint, CGFloat, UInt32, CGFloat)] = []
        let n = 15
        for k in 0..<n {
            var d0 = (CGFloat(k) + 0.5) / CGFloat(n) * total
            var q = 0
            while q < longueurs.count - 1 && d0 > longueurs[q] {
                d0 -= longueurs[q]
                q += 1
            }
            let u = d0 / max(longueurs[q], 1)
            let a = pts[q]
            let b = pts[q + 1]
            let pos = CGPoint(x: a.x + (b.x - a.x) * u, y: a.y + (b.y - a.y) * u + 3)
            let rayon = 2.4 * (0.8 + 0.4 * g.suivant())
            let halo = 13 * (0.8 + 0.4 * g.suivant())
            liste.append((pos, rayon, couleurs[k % couleurs.count], halo))
        }
        return (pts, liste)
    }

    /// Un sapin stylisé : des étages de branches festonnés, sans contour, un reflet clair sur chaque étage.
    private static func sapinNoel(_ ctx: inout GraphicsContext, _ cad: CadreDecor, graine: UInt32, cx: CGFloat, base: CGFloat,
                                  h: CGFloat, w: CGFloat, c0: UInt32, c1: UInt32, c2: UInt32, etages: Int) {
        var g = GraineDecor(graine)
        ctx.fill(cad.ellipse(cx + 6, base + 2, w * 0.55, 9), with: .color(c(0x000000, 0.35)))
        let tronc = Path(CGRect(x: (cx - 5) * cad.s, y: cad.p(0, base - 18).y, width: 10 * cad.s, height: 20 * cad.s))
        ctx.fill(tronc, with: .color(c(c0)))
        let peau = degrade([(0, c(c2)), (0.55, c(c1)), (1, c(c0))])
        let haut = cad.p(cx, base - h).y
        let bas = cad.p(cx, base).y
        for i in 0..<etages {
            let t = CGFloat(i) / CGFloat(max(etages - 1, 1))
            let yb = base - 14 - h * 0.8 * t
            let hw = w * (0.5 - 0.36 * t) + 4
            let hh = h * (0.3 - 0.07 * t)
            let pointe = yb - hh
            var etage = Path()
            etage.move(to: cad.p(cx, pointe))
            etage.addLine(to: cad.p(cx + hw, yb))
            let m = 5
            for k in 0..<m {
                let x1 = cx + hw - 2 * hw * (CGFloat(k) + 0.5) / CGFloat(m)
                let x2 = cx + hw - 2 * hw * CGFloat(k + 1) / CGFloat(m)
                let yc = yb + 6 + g.suivant() * 5
                let ye = yb - 1 + g.suivant() * 2
                etage.addQuadCurve(to: cad.p(x2, ye), control: cad.p(x1, yc))
            }
            etage.closeSubpath()
            ctx.fill(etage, with: .linearGradient(peau, startPoint: CGPoint(x: 0, y: haut), endPoint: CGPoint(x: 0, y: bas)))
            var arete = Path()
            arete.move(to: cad.p(cx - hw * 0.55, yb - hh * 0.35))
            arete.addLine(to: cad.p(cx, pointe + 3))
            ctx.stroke(arete, with: .color(.white.opacity(0.14)),
                       style: StrokeStyle(lineWidth: max(0.6, cad.r(1.6)), lineCap: .round))
        }
    }

    /// Une boule de verre posée sur le lit : ombre, sphère, reflet, culot.
    private static func bouleNoel(_ ctx: inout GraphicsContext, _ cad: CadreDecor, cx: CGFloat, cy: CGFloat, R: CGFloat,
                                  c1: UInt32, c2: UInt32) {
        ctx.fill(cad.ellipse(cx + R * 0.2, cy + R * 0.92, R * 1.05, R * 0.22), with: .color(c(0x000000, 0.4)))
        let verre = degrade([(0, Color.white.opacity(0.95)), (0.16, c(c1)), (0.7, c(c2)), (1, c(0x000000, 0.55))])
        ctx.fill(cad.ellipse(cx, cy, R, R),
                 with: .radialGradient(verre, center: cad.p(cx - R * 0.32, cy - R * 0.44), startRadius: 0,
                                       endRadius: cad.r(R * 1.55)))
        var reflet = Path(ellipseIn: CGRect(x: -R * 0.2 * cad.s, y: -R * 0.12 * cad.s, width: R * 0.4 * cad.s, height: R * 0.24 * cad.s))
        let rc = cad.p(cx - R * 0.36, cy - R * 0.4)
        reflet = reflet.applying(CGAffineTransform(rotationAngle: -35 * CGFloat.pi / 180)
            .concatenating(CGAffineTransform(translationX: rc.x, y: rc.y)))
        ctx.fill(reflet, with: .color(.white.opacity(0.7)))
        let culot = Path(CGRect(x: (cx - R * 0.2) * cad.s, y: cad.p(0, cy - R * 1.12).y, width: R * 0.4 * cad.s, height: R * 0.2 * cad.s))
        ctx.fill(culot, with: .color(c(0xB99B55)))
    }

    /// Le dessin qui ne bouge pas : glace, lit givré, sapins, boules, étoile, guirlande.
    static func fixeNoel(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(102)
        // La glace vue d'en dessous : voile clair qui s'efface vers le bas, bord irrégulier, fissures, lumière transmise.
        let hGlace: CGFloat = 110
        var pts: [CGPoint] = [cad.p(-10, hGlace * 0.8)]
        var x: CGFloat = 0
        while x <= 410 {
            pts.append(cad.p(x, hGlace * (0.74 + 0.16 * g.suivant())))
            x += 45
        }
        var bord = lisse(pts)
        bord.addLine(to: cad.p(410, -10))
        bord.addLine(to: cad.p(-10, -10))
        bord.closeSubpath()
        let peauGlace = degrade([(0, c(0xE8F3FC, 0.97)), (0.45, c(0xBCD6EA, 0.7)), (0.82, c(0x9CC0DA, 0.22)), (1, c(0x9CC0DA, 0))])
        var fissures: [Path] = []
        for _ in 0..<5 {
            var px = g.suivant() * 390
            var py = g.suivant() * hGlace * 0.3
            var f = Path()
            f.move(to: cad.p(px, py))
            let m = 3 + Int(g.suivant() * 2)
            for _ in 0..<m {
                let nx = px + (g.suivant() - 0.5) * 90
                let ny = py + 10 + g.suivant() * 16
                let cx = (px + nx) / 2 + (g.suivant() - 0.5) * 20
                f.addQuadCurve(to: cad.p(nx, ny), control: cad.p(cx, (py + ny) / 2))
                px = nx
                py = ny
            }
            fissures.append(f)
        }
        let eclat: CGFloat = 100 + g.suivant() * 190
        let hautGlace = cad.p(0, -10).y
        let basGlace = cad.p(0, hGlace).y
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: cad.r(2.2)))
            couche.fill(bord, with: .linearGradient(peauGlace, startPoint: CGPoint(x: 0, y: hautGlace),
                                                    endPoint: CGPoint(x: 0, y: basGlace)))
            for f in fissures {
                couche.stroke(f, with: .color(.white.opacity(0.18)),
                              style: StrokeStyle(lineWidth: max(0.6, cad.r(0.9)), lineCap: .round))
            }
        }
        lueur(ctx, centre: cad.p(eclat, hGlace * 0.3), rx: cad.r(170), ry: cad.r(170),
              arrets: [(0, c(0xFFFFFF, 0.8)), (0.4, c(0xEAF5FF, 0.28)), (1, c(0xEAF5FF, 0))])
        // Le lit : collines floues au loin, sol, grains, galets avec leur ombre, givre.
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: cad.r(6)))
            var lointain = GraineDecor(1022)
            sol(&couche, cad, &lointain, y0: 690, amp: 22, pas: 30,
                arrets: [(0, c(0x142330, 0)), (0.5, c(0x142330, 0.8)), (1, c(0x142330, 0.95))])
        }
        sol(&ctx, cad, &g, y0: 748, amp: 14, pas: 28,
            arrets: [(0, c(0x243847, 0)), (0.16, c(0x243847, 0.94)), (1, c(0x0A141D))])
        let grains: [UInt32] = [0x6C7F90, 0x4C5E71, 0x8999AB, 0x364759, 0xA3B3C0]
        for _ in 0..<480 {
            let v = CGFloat(pow(Double(g.suivant()), 0.8))
            let y = 754 + 90 * v
            let gx = g.suivant() * 410 - 10
            let rx = (1.4 + 3.2 * g.suivant()) * (0.55 + 1.0 * v)
            let ry = rx * (0.55 + 0.2 * g.suivant())
            let col = grains[g.indice(grains.count)]
            let opacite = Double(0.3 + 0.55 * g.suivant())
            ctx.fill(cad.ellipse(gx, y, rx, ry), with: .color(c(col, opacite)))
        }
        galets(&ctx, cad, &g, n: 26, y0: 758, y1: 838, palette: [0x5E7284, 0x485B6D, 0x7487A0, 0x3A4B5E, 0x8EA0B2],
               rmin: 12, rmax: 24, ombre: 0.3, reflet: 0.16)
        for _ in 0..<70 {
            let v = CGFloat(pow(Double(g.suivant()), 0.9))
            let y = 752 + 92 * v
            let gx = g.suivant() * 400 - 5
            let rx = (2 + 6 * g.suivant()) * (0.5 + v)
            let opacite = Double(0.45 * (0.4 + 0.6 * g.suivant()))
            ctx.fill(cad.ellipse(gx, y, rx, rx * 0.4), with: .color(c(0xEAF4FF, opacite)))
        }
        // Le sapin lointain (flou, dans la brume), puis le sapin, à peine éclairé.
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: cad.r(3)))
            couche.opacity = 0.55
            sapinNoel(&couche, cad, graine: 1023, cx: 66, base: 776, h: 200, w: 116, c0: 0x112A33, c1: 0x21424C,
                      c2: 0x3D6772, etages: 5)
        }
        sapinNoel(&ctx, cad, graine: 1024, cx: 292, base: 806, h: 400, w: 236, c0: 0x0A1D23, c1: 0x22484F,
                  c2: 0x4C7E86, etages: 7)
        // La brume de l'eau devant le sapin : il reste en retrait.
        ctx.fill(Path(CGRect(x: 0, y: cad.p(0, 300).y, width: cad.l, height: cad.h)), with: .color(c(0x0E2233, 0.16)))
        bouleNoel(&ctx, cad, cx: 252, cy: 600, R: 7.5, c1: 0xE8DCC0, c2: 0x8F7F5A)
        bouleNoel(&ctx, cad, cx: 342, cy: 672, R: 8, c1: 0xC98A55, c2: 0x6E3E22)
        bouleNoel(&ctx, cad, cx: 254, cy: 736, R: 8.5, c1: 0x6F93B8, c2: 0x27425F)
        bouleNoel(&ctx, cad, cx: 330, cy: 540, R: 6.5, c1: 0xE8DCC0, c2: 0x8F7F5A)
        // L'étoile, au sommet.
        lueur(ctx, centre: cad.p(292, 392), rx: cad.r(34), ry: cad.r(34),
              arrets: [(0, c(0xFFF3D6)), (0.3, c(0xFFD79A, 0.5)), (1, c(0xFFC070, 0))])
        let sommets: [(CGFloat, CGFloat)] = [(0, -13), (3.4, -4), (13, -4), (5.4, 2), (8.2, 11), (0, 5.6), (-8.2, 11),
                                             (-5.4, 2), (-13, -4), (-3.4, -4)]
        let etoile = ligne(cad, sommets.map { (292 + $0.0 * 0.8, 396 + $0.1 * 0.8) }, ferme: true)
        ctx.fill(etoile, with: .color(c(0xFFE7B8)))
        // La guirlande : fil et ampoules (le halo qui respire est dans la partie qui bouge).
        let guir = ampoulesNoel()
        let fil = ligne(cad, guir.fil.map { ($0.x, $0.y) }, ferme: false)
        ctx.stroke(fil, with: .color(c(0x0A1A1F, 0.8)), style: StrokeStyle(lineWidth: max(0.6, cad.r(1.2)), lineCap: .round))
        for ampoule in guir.ampoules {
            ctx.fill(cad.ellipse(ampoule.0.x, ampoule.0.y, ampoule.1 * 0.78, ampoule.1 * 1.05), with: .color(c(ampoule.2)))
        }
    }

    /// Ce qui bouge : plaques de lumière froide sur le lit, halos des ampoules qui respirent, herbes sombres.
    static func mobileNoel(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ t: Double) {
        for i in 0..<7 {
            let x = CGFloat(bruit(i, 70)) * 410 + CGFloat(8 * sin(t * 0.19 + Double(i)))
            let y = 760 + CGFloat(bruit(i, 71)) * 76
            let rx = 26 + CGFloat(bruit(i, 72)) * 38
            let alpha = 0.10 + 0.06 * sin(t * 0.37 + Double(i) * 1.9)
            lueur(ctx, centre: cad.p(x, y), rx: cad.r(rx), ry: cad.r(rx * 0.24),
                  arrets: [(0, c(0xBEDEFF, alpha)), (0.7, c(0xBEDEFF, 0)), (1, c(0xBEDEFF, 0))])
        }
        let guir = ampoulesNoel()
        for (i, ampoule) in guir.ampoules.enumerated() {
            var c2 = ctx
            c2.opacity = 0.725 + 0.275 * balance(t, periode: 3.2, retard: Double(i) * 0.7)
            lueur(c2, centre: cad.p(ampoule.0.x, ampoule.0.y), rx: cad.r(ampoule.3), ry: cad.r(ampoule.3),
                  arrets: [(0, c(0xFFD8A0, 0.85)), (0.3, c(0xFFC57A, 0.32)), (1, c(0xFFB060, 0))])
        }
        herbes(&ctx, cad, graine: 1025, t: t, x0: -14, x1: 100, n: 7, y0: 796, hmin: 90, hmax: 200, couleurs: [0x16303B],
               pente: 14, amp: 2.2, nervure: false)
    }

    /// Devant les poissons : des galets flous au premier plan, hors champ, pour la profondeur.
    static func avantNoel(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(1021)
        let couleurs: [UInt32] = [0x1D2D3C, 0x16232F, 0x25364A]
        for _ in 0..<5 {
            let x = g.suivant() * 420 - 15
            let y = 795 + g.suivant() * 55
            let rx = 26 + g.suivant() * 40
            let col = couleurs[g.indice(couleurs.count)]
            lueur(ctx, centre: cad.p(x, y), rx: cad.r(rx), ry: cad.r(rx * 0.5),
                  arrets: [(0, c(col)), (0.75, c(col, 0.95)), (1, c(col, 0))])
        }
    }
}
