import SwiftUI

// Été : la proposition C « Fête sur l'eau » choisie par Titouan sur la page de propositions d'été (scenes_c.js).
// Vue d'en dessous : trois bouées de corail, de jaune et de turquoise à des distances différentes (de plus en plus floues),
// un ballon de plage, des rubans de lumière colorés qui descendent de la surface, du bokeh multicolore, un sol en trois plans
// (lointain flou, gravier fin, galets) de sable clair, de graviers et de galets colorés, et des reflets dorés qui glissent
// sur le sable. Même vignette et mêmes rais que les décors validés. Fichier PARTAGÉ app + widget (voir DecorsDessinesBase.swift).
//
// PERFORMANCE (exigence n°1 : fluide, même sur un iPhone ancien ; budget dans BudgetDecor.swift) :
//  - tout ce qui est statique (sol, galets, rides, bouées floues, ballon, herbes, rais, ombres colorées) est dessiné UNE fois
//    dans `fixeEte` ; le flou y est appliqué une fois (`drawLayer` + `.blur`), puis `CacheDecor` garde l'image ;
//  - ce qui bouge est léger et SANS flou : 4 rubans de lumière (chemins calculés une fois, déplacés par transformation),
//    6 anneaux autour des bouées, 12 disques de bokeh pleins, un peu de pollen et des bulles (partagés avec les autres décors) ;
//  - les reflets du sol sont deux IMAGES pré-rendues (`refletsSol`) que la vue fait glisser par `offset` : jamais recalculées.
// Différence assumée avec la page : les rubans de lumière ne changent plus de forme à chaque image (leur onde est figée,
// ils se balancent et respirent) et les herbes des bords ne bougent plus (elles sont dans l'image fixe).
// ⚠ à vérifier sur Mac : couleurs, flou des bouées, lisibilité des poissons, fluidité sur un iPhone ancien (Instruments).

nonisolated extension DecorDessin {
    // MARK: Réglage (filtre sur le fond d'origine, lumière, ambiance)

    /// Le réglage de l'Été : `hue-rotate(-30deg) saturate(1.05) brightness(.98)` de la page, teinte turquoise (soft-light),
    /// soleil en haut à droite, vignette de la page. Les rais sont dans l'image fixe (`fixeEte`), pas dans l'ambiance.
    static let reglageEte = Reglage(
        filtre: Filtre(teinte: -30, saturation: 1.05, multiplicateur: (1, 1, 1), eclat: -0.02),
        calques: [.aplat((70, 185, 180), 0.16),
                  .lueur(0.62, -0.04, 0.8, 0.44, (255, 246, 205), 0.5),
                  .aplat((255, 226, 160), 0.06),
                  .vignette(0.5, 0.42, 0.92, 0.7, 0.55, (3, 22, 26), 0.5)],
        ambiance: Ambiance(
            rais: nil,
            caustiques: nil,
            particules: Particules(type: .pollen, c: (255, 240, 190), a: 0.55, fond: 12, proches: 6),
            bulles: Bulles(c: (255, 252, 240), y: 0.8)))

    private static let paletteSable: [UInt32] = [0xD0C59C, 0xB5AA85, 0xE2D8B0, 0x8E8566, 0xBDB290, 0x9FB09A, 0xC6A98C]
    private static let paletteGravier: [UInt32] = [0xE2A692, 0x8FCBC2, 0xEBD48C, 0xD3C79F, 0xB8AD8A, 0xC9D6B0]
    /// Les herbes aquatiques : (pied, pointe).
    private static let couleursHerbes: [(UInt32, UInt32)] = [(0x1F5A33, 0x8FCB55), (0x17482F, 0x5CB058), (0x2C6A3A, 0xA8D663)]

    // MARK: Dessin fixe (rendu une fois, mis en cache)

    /// Derrière les poissons : le sol en trois plans, les herbes des bords, les bouées et le ballon flous, la lueur de la surface,
    /// les rais. Rien ici ne bouge ni ne dépend de `t`.
    static func fixeEte(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(333)
        // Plan lointain : une bande verte floue, avec quelques galets flous.
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(6)))
            var h = GraineDecor(334)
            sol(&l, cad, &h, y0: 668, amp: 22, pas: 30,
                arrets: [(0, c(0x4F8A78, 0)), (0.5, c(0x4F8A78, 0.8)), (1, c(0x4F8A78, 0.95))])
        }
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(3)))
            for _ in 0..<9 {
                let x = g.suivant() * 410 - 10
                let y = 692 + g.suivant() * 34
                let rx = 10 + g.suivant() * 16
                l.fill(cad.ellipse(x, y, rx, rx * 0.5), with: .color(c(paletteSable[g.indice(paletteSable.count)], 0.5)))
            }
        }
        // Plan moyen : le sable, éclairé d'en haut, puis un gravier fin de toutes les couleurs.
        sol(&ctx, cad, &g, y0: 726, amp: 16, pas: 28,
            arrets: [(0, c(0xC9BD94, 0)), (0.16, c(0xC9BD94, 0.94)), (1, c(0x6E6544))])
        for _ in 0..<760 {
            let v = pow(Double(g.suivant()), 0.8)
            let y = 732 + 118 * CGFloat(v)
            let x = g.suivant() * 410 - 10
            let rx = (1.4 + 3.2 * g.suivant()) * (0.55 + 1.0 * CGFloat(v))
            let ry = rx * (0.55 + 0.2 * g.suivant())
            let col = paletteGravier[g.indice(paletteGravier.count)]
            ctx.fill(cad.ellipse(x, y, rx, ry), with: .color(c(col, 0.3 + 0.55 * Double(g.suivant()))))
        }
        // Plan proche : les galets, avec leur ombre et un reflet doux.
        galetsEte(&ctx, cad, &g)
        // Les rides du sable : des traits longs et doux, floutés une fois.
        ridesEte(&ctx, cad, &g)
        // Les herbes des bords, de chaque côté.
        herbesEte(&ctx, cad, &g, n: 8, x0: -16, x1: 80, y0: 778, jy: 14, hmin: 70, hmax: 160, w0: 3, w1: 6, lean: 16, op: 0.9)
        herbesEte(&ctx, cad, &g, n: 8, x0: 310, x1: 406, y0: 778, jy: 14, hmin: 70, hmax: 160, w0: 3, w1: 6, lean: -16, op: 0.9)
        // Les ombres colorées des bouées sur le sable.
        var lumiere = ctx
        lumiere.blendMode = .screen
        lumiere.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(6)))
            l.stroke(cad.ellipse(140, 790, 110, 20), with: .color(c(0xE56F7B, 0.16)), lineWidth: cad.r(20))
            l.stroke(cad.ellipse(290, 768, 56, 10), with: .color(c(0xF0C444, 0.18)), lineWidth: cad.r(12))
        }
        herbesEte(&ctx, cad, &g, n: 7, x0: -12, x1: 76, y0: 814, jy: 10, hmin: 100, hmax: 210, w0: 3.5, w1: 7, lean: 14, op: 0.95)
        herbesEte(&ctx, cad, &g, n: 7, x0: 314, x1: 404, y0: 814, jy: 10, hmin: 100, hmax: 210, w0: 3.5, w1: 7, lean: -14, op: 0.95)
        // La lueur de la surface, en haut : le contre-jour.
        var haut = ctx
        haut.blendMode = .screen
        haut.fill(Path(CGRect(x: 0, y: cad.p(0, 0).y, width: cad.l, height: cad.r(190))),
                  with: .linearGradient(degrade([(0, c(0xFFF8D8, 0.55)), (0.5, c(0xFFF1BE, 0.1925)), (1, c(0xFFF1BE, 0))]),
                                        startPoint: CGPoint(x: 0, y: cad.p(0, 0).y), endPoint: CGPoint(x: 0, y: cad.p(0, 190).y)))
        // Les bouées, de la plus lointaine (très floue) à la plus proche (presque nette), puis le ballon.
        bouee(&ctx, cad, cx: 70, cy: 178, rx: 36, ry: 12, couleurs: [0x3AB0C2, 0xF2EDE0], n: 10, flou: 2.6, opacite: 0.85, sombre: 0.28)
        bouee(&ctx, cad, cx: 268, cy: 152, rx: 56, ry: 18, couleurs: [0xEDB82C, 0xF9EFD2], n: 12, flou: 1.8, opacite: 0.95, sombre: 0.28)
        ballon(&ctx, cad, cx: 318, cy: 70, r: 34, couleurs: [0xE0483E, 0xF6F0E4, 0xF0BE30, 0xF6F0E4, 0x3E9BC6, 0xF6F0E4])
        bouee(&ctx, cad, cx: 128, cy: 78, rx: 94, ry: 31, couleurs: [0xE0506A, 0xF28E88], n: 16, flou: 0.7, opacite: 1, sombre: 0.3)
        // Les rais de lumière fixes (à l'instant figé).
        rais(&ctx, taille: CGSize(width: cad.l, height: cad.h), t: tFixe,
             Rais(c: (255, 248, 214), a: 0.2, large: 1.4, n: 5))
    }

    /// Devant les poissons : des galets flous au premier plan, hors champ, pour la profondeur (flous une fois, dans l'image).
    static func avantEte(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(335)
        let couleurs: [UInt32] = [0xA39878, 0x8A7F62, 0xBBAF8C]
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(3)))
            for _ in 0..<4 {
                let x = g.suivant() * 420 - 15
                let y = 814 + g.suivant() * 36
                let rx = 26 + g.suivant() * 40
                let col = couleurs[g.indice(couleurs.count)]
                l.fill(cad.ellipse(x, y, rx, rx * 0.5), with: .color(c(col)))
                l.fill(cad.ellipse(x, y, rx, rx * 0.5),
                       with: .radialGradient(degrade([(0, c(0xFFFFFF, 0.22)), (0.38, c(0xFFFFFF, 0)), (0.6, c(0x000000, 0)), (1, c(0x000000, 0.46))]),
                                             center: cad.p(x - rx * 0.28, y - rx * 0.2), startRadius: 0, endRadius: cad.r(rx * 1.5)))
            }
        }
    }

    // MARK: Le sol

    private static func galetsEte(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor) {
        struct Galet { var x: CGFloat; var y: CGFloat; var rx: CGFloat; var ry: CGFloat; var rot: Double; var couleur: UInt32 }
        var liste: [Galet] = []
        for _ in 0..<34 {
            let v = CGFloat(pow(Double(g.suivant()), 0.9))
            let y = 736 + 94 * v
            let x = g.suivant() * 410 - 10
            let rx = (12 + 14 * g.suivant()) * (0.5 + 0.9 * v)
            let ry = rx * (0.5 + 0.2 * g.suivant())
            let rot = Double(g.suivant() - 0.5) * 24
            liste.append(Galet(x: x, y: y, rx: rx, ry: ry, rot: rot, couleur: paletteSable[g.indice(paletteSable.count)]))
        }
        liste.sort { $0.y < $1.y }
        let relief = degrade([(0, c(0xFFFFFF, 0.22)), (0.38, c(0xFFFFFF, 0)), (0.6, c(0x000000, 0)), (1, c(0x000000, 0.46))])
        for q in liste {
            ctx.fill(cad.ellipse(q.x + q.rx * 0.12, q.y + q.ry * 0.62, q.rx * 1.08, q.ry * 0.5), with: .color(c(0x000000, 0.3)))
            var l = ctx
            let centre = cad.p(q.x, q.y)
            l.translateBy(x: centre.x, y: centre.y)
            l.rotate(by: .degrees(q.rot))
            let forme = Path(ellipseIn: CGRect(x: -q.rx * cad.s, y: -q.ry * cad.s, width: q.rx * cad.s * 2, height: q.ry * cad.s * 2))
            l.fill(forme, with: .color(c(q.couleur)))
            l.fill(forme, with: .radialGradient(relief, center: CGPoint(x: -q.rx * 0.28 * cad.s, y: -q.ry * 0.4 * cad.s),
                                                startRadius: 0, endRadius: q.rx * 1.5 * cad.s))
        }
    }

    private static func ridesEte(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor) {
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(1)))
            for i in 0..<22 {
                let v = CGFloat(pow(Double(g.suivant()), 0.8))
                let y = 736 + 106 * v
                let sc = 0.5 + 1.1 * v
                let x0 = -30 + g.suivant() * 200
                let len = 150 + g.suivant() * 230
                let a = (g.suivant() - 0.5) * 5 * sc
                let alpha = 0.12 + 0.14 * Double(g.suivant())
                let e1 = (x0 + len * 0.5, y + a)
                var chemin = Path()
                chemin.move(to: cad.p(x0, y))
                chemin.addQuadCurve(to: cad.p(e1.0, e1.1), control: cad.p(x0 + len * 0.25, y - 7 * sc))
                chemin.addQuadCurve(to: cad.p(e1.0 + len * 0.5, e1.1 - a * 0.6), control: cad.p(x0 + len * 0.75, y + 2 * a + 7 * sc))
                l.stroke(chemin, with: .color(c(i % 2 == 1 ? 0xFFF3D0 : 0x5A5036, alpha)),
                         style: StrokeStyle(lineWidth: max(0.5, cad.r(1.2 * sc + 0.6)), lineCap: .round))
            }
        }
    }

    /// Des herbes aquatiques en rubans effilés, avec un dégradé du pied vers la pointe.
    private static func herbesEte(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor, n: Int, x0: CGFloat,
                                  x1: CGFloat, y0: CGFloat, jy: CGFloat, hmin: CGFloat, hmax: CGFloat, w0: CGFloat, w1: CGFloat,
                                  lean: CGFloat, op: Double) {
        for _ in 0..<n {
            let x = x0 + (x1 - x0) * g.suivant()
            let h = hmin + (hmax - hmin) * g.suivant()
            let w = w0 + (w1 - w0) * g.suivant()
            let l = (g.suivant() - 0.5) * 2 * lean
            let ondule = (g.suivant() - 0.5) * 12
            let couleurs = couleursHerbes[g.indice(couleursHerbes.count)]
            let y = y0 + jy * g.suivant()
            let bout = (x: x + l, y: y - h)
            var lame = Path()
            lame.move(to: cad.p(x - w, y))
            lame.addCurve(to: cad.p(bout.x, bout.y), control1: cad.p(x - w * 0.7 + l * 0.15, y - h * 0.35),
                          control2: cad.p(x + l * 0.8 + ondule - w * 0.3, y - h * 0.72))
            lame.addCurve(to: cad.p(x + w, y), control1: cad.p(x + l * 0.8 + ondule + w * 0.3, y - h * 0.72),
                          control2: cad.p(x + w * 0.7 + l * 0.15, y - h * 0.35))
            lame.closeSubpath()
            var c2 = ctx
            c2.opacity = op
            c2.fill(lame, with: .linearGradient(degrade([(0, c(couleurs.0)), (1, c(couleurs.1))]),
                                                startPoint: cad.p(x, y), endPoint: cad.p(bout.x, bout.y)))
        }
    }

    // MARK: Les bouées et le ballon

    /// Des points sur une ellipse, de l'angle `a0` à l'angle `a1` (radians).
    private static func arc(_ cad: CadreDecor, _ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ a0: Double, _ a1: Double,
                            pas: Int) -> [CGPoint] {
        (0...pas).map { k in
            let a = a0 + (a1 - a0) * Double(k) / Double(pas)
            return cad.p(cx + rx * CGFloat(cos(a)), cy + ry * CGFloat(sin(a)))
        }
    }

    /// Une bouée ronde vue d'en dessous, à contre-jour : secteurs alternés, lumière qui la traverse, halo à la ligne d'eau.
    /// `flou` : flou gaussien appliqué UNE fois (dans l'image mise en cache), jamais sur une couche animée.
    private static func bouee(_ ctx: inout GraphicsContext, _ cad: CadreDecor, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat,
                              couleurs: [UInt32], n: Int, flou: CGFloat, opacite: Double, sombre: Double) {
        let irx = rx * 0.5
        let iry = ry * 0.5
        let icy = cy - ry * 0.16
        var halo = ctx
        halo.blendMode = .screen
        halo.opacity = opacite
        halo.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(4)))
            l.stroke(cad.ellipse(cx, cy - ry * 0.12, rx * 1.05, ry * 1.12), with: .color(c(0xFFF2C0, 0.4)), lineWidth: cad.r(ry * 0.3))
        }
        var corps = ctx
        corps.opacity = opacite
        corps.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(flou)))
            var lc = l
            lc.opacity = 0.7 * opacite
            lc.fill(cad.ellipse(cx, icy, irx, iry),
                    with: .radialGradient(degrade([(0, c(0xFFFBE6, 0.9)), (0.6, c(0xFFF1BE, 0.45)), (1, c(0xFFE9A0, 0))]),
                                          center: cad.p(cx, icy), startRadius: 0, endRadius: cad.r(irx)))
            for i in 0..<n {
                let a0 = 2 * Double.pi * Double(i) / Double(n)
                let a1 = 2 * Double.pi * Double(i + 1) / Double(n)
                var secteur = Path()
                let dehors = arc(cad, cx, cy, rx, ry, a0, a1, pas: 6)
                secteur.move(to: dehors[0])
                for q in dehors.dropFirst() { secteur.addLine(to: q) }
                for q in arc(cad, cx, icy, irx, iry, a1, a0, pas: 6) { secteur.addLine(to: q) }
                secteur.closeSubpath()
                l.fill(secteur, with: .color(c(couleurs[i % couleurs.count])))
            }
            var anneau = cad.ellipse(cx, cy, rx, ry)
            anneau.addPath(cad.ellipse(cx, icy, irx, iry))
            let evenOdd = FillStyle(eoFill: true)
            l.fill(anneau, with: .color(c(0x0B3238, sombre)), style: evenOdd)
            l.fill(anneau, with: .linearGradient(degrade([(0, c(0xFFFFFF, 0.5)), (0.4, c(0xFFFFFF, 0)), (1, c(0x041C24, 0.55))]),
                                                 startPoint: cad.p(cx, cy - ry), endPoint: cad.p(cx, cy + ry)), style: evenOdd)
            var reflet = Path()
            let r = arc(cad, cx, cy, rx * 0.98, ry * 0.98, Double.pi * 1.12, Double.pi * 1.88, pas: 10)
            reflet.move(to: r[0])
            for q in r.dropFirst() { reflet.addLine(to: q) }
            l.stroke(reflet, with: .color(.white.opacity(0.5)),
                     style: StrokeStyle(lineWidth: max(1.2, cad.r(max(1.2, ry * 0.08))), lineCap: .round, lineJoin: .round))
        }
    }

    /// Le ballon de plage vu d'en dessous : un dôme à six panneaux, la lumière qui le traverse.
    private static func ballon(_ ctx: inout GraphicsContext, _ cad: CadreDecor, cx: CGFloat, cy: CGFloat, r R: CGFloat,
                               couleurs: [UInt32]) {
        let cyc = cy + R * 0.5
        let ligne = cy + R * 0.12
        let px = cx + R * 0.08
        let py = cyc + R * 0.2
        var halo = ctx
        halo.blendMode = .screen
        halo.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(4)))
            l.stroke(cad.ellipse(cx, ligne, R * 0.98, R * 0.3), with: .color(c(0xFFF2C0, 0.5)), lineWidth: cad.r(R * 0.16))
        }
        ctx.drawLayer { l in
            l.addFilter(.blur(radius: cad.r(0.7)))
            var dome = l
            dome.clip(to: cad.ellipse(cx, cyc, R, R))
            let n = couleurs.count
            for i in 0..<n {
                let a0 = 2 * Double.pi * Double(i) / Double(n) - Double.pi / 2
                let a1 = 2 * Double.pi * Double(i + 1) / Double(n) - Double.pi / 2
                let am = (a0 + a1) / 2
                let L = R * 3
                var panneau = Path()
                panneau.move(to: cad.p(px, py))
                for a in [a0, am, a1] {
                    panneau.addLine(to: cad.p(px + L * CGFloat(cos(a)), py + L * CGFloat(sin(a))))
                }
                panneau.closeSubpath()
                dome.fill(panneau, with: .color(c(couleurs[i])))
            }
            dome.fill(cad.ellipse(cx, cyc, R, R), with: .color(c(0x0B3238, 0.12)))
            dome.fill(cad.ellipse(cx, cyc, R, R),
                      with: .radialGradient(degrade([(0, c(0xFFFFFF, 0.5)), (0.45, c(0xFFFFFF, 0)), (1, c(0x031A22, 0.5))]),
                                            center: cad.p(cx - R * 0.24, cyc - R * 0.44), startRadius: 0, endRadius: cad.r(R * 1.9)))
            let hautLumiere = CGRect(x: cad.p(cx - R, 0).x, y: cad.p(0, cyc - R).y, width: cad.r(R * 2),
                                     height: cad.p(0, ligne + R * 0.2).y - cad.p(0, cyc - R).y)
            dome.fill(Path(hautLumiere),
                      with: .linearGradient(degrade([(0, c(0xFFF6D8, 0.7)), (0.4, c(0xFFF0C0, 0.25)), (1, c(0xFFF0C0, 0))]),
                                            startPoint: CGPoint(x: 0, y: hautLumiere.minY), endPoint: CGPoint(x: 0, y: hautLumiere.maxY)))
            var brille = l
            let bc = cad.p(cx - R * 0.38, cyc + R * 0.05)
            brille.translateBy(x: bc.x, y: bc.y)
            brille.rotate(by: .degrees(-35))
            brille.fill(Path(ellipseIn: CGRect(x: -R * 0.14 * cad.s, y: -R * 0.08 * cad.s, width: R * 0.28 * cad.s, height: R * 0.16 * cad.s)),
                        with: .color(.white.opacity(0.55)))
        }
    }

    // MARK: Ce qui bouge (léger, sans flou, budget dans BudgetDecor)

    /// Un ruban de lumière : le chemin est calculé UNE fois (en unités du cadre 390 x 844), puis seulement déplacé.
    struct RubanLumiere {
        let chemin: Path
        let c: RVB
        let a: Double
        let w: CGFloat
        let vitesse: Double
        let phase: Double
        let amplitude: CGFloat
    }

    /// Les quatre rubans de la page (rose, jaune, turquoise, orangé), descendant en oblique depuis la surface.
    static let rubansLumiere: [RubanLumiere] = {
        let defs: [(x: CGFloat, pente: CGFloat, amp: CGFloat, f: Double, v: Double, ph: Double, c: RVB, a: Double, w: CGFloat)] = [
            (0.12, 0.2, 20, 1.6, 0.3, 0, (255, 150, 175), 0.55, 4),
            (0.38, 0.16, 24, 1.3, -0.26, 1.9, (255, 214, 110), 0.55, 4.4),
            (0.62, 0.14, 22, 1.8, 0.34, 3.3, (120, 235, 225), 0.5, 4),
            (0.86, 0.1, 18, 1.4, -0.3, 4.4, (255, 176, 130), 0.45, 3.4),
        ]
        let hauteur: CGFloat = 0.84 * 844
        return defs.prefix(BudgetDecor.rubansMax).map { d in
            var pts: [CGPoint] = []
            for k in 0...26 {
                let u = Double(k) / 26
                let y = CGFloat(u) * hauteur
                let x = d.x * 390 + d.pente * y + d.amp * CGFloat(sin(u * d.f * 2 * Double.pi + d.ph)) * CGFloat(0.35 + u * 0.9)
                pts.append(CGPoint(x: x, y: y))
            }
            return RubanLumiere(chemin: lisse(pts), c: d.c, a: d.a, w: d.w, vitesse: d.v, phase: d.ph, amplitude: d.amp)
        }
    }()

    /// Les trois points d'eau des bouées : (centre x, centre y, rayon x, rayon y, retard en secondes).
    static let anneauxBouees: [(CGFloat, CGFloat, CGFloat, CGFloat, Double)] = [
        (128, 92, 118, 30, 0), (318, 82, 50, 12, -0.9), (268, 158, 66, 16, -1.8),
    ]

    /// Derrière les poissons : les rubans de lumière qui se balancent et respirent, les anneaux autour des bouées.
    static func mobileEte(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ t: Double) {
        var c2 = ctx
        c2.blendMode = .plusLighter
        c2.scaleBy(x: cad.s, y: cad.s)
        let fin = CGPoint(x: 0, y: 0.82 * 844)
        for ruban in rubansLumiere {
            var r = c2
            let oscille = sin(t * ruban.vitesse + ruban.phase)
            r.concatenate(CGAffineTransform(a: 1, b: 0, c: CGFloat(0.02 * oscille), d: 1,
                                            tx: ruban.amplitude * 0.5 * CGFloat(oscille), ty: 0))
            let force = ruban.a * (0.85 + 0.15 * sin(t * 0.4 + ruban.phase))
            let fondu = degrade([(0, c(ruban.c, force)), (0.55, c(ruban.c, force * 0.45)), (1, c(ruban.c, 0))])
            let peinture = GraphicsContext.Shading.linearGradient(fondu, startPoint: .zero, endPoint: fin)
            r.opacity = 0.22
            r.stroke(ruban.chemin, with: peinture,
                     style: StrokeStyle(lineWidth: ruban.w * 3.2, lineCap: .round, lineJoin: .round))
            r.opacity = 1
            r.stroke(ruban.chemin, with: peinture, style: StrokeStyle(lineWidth: ruban.w, lineCap: .round, lineJoin: .round))
        }
        // Les anneaux : deux ondes par bouée, qui s'élargissent et s'effacent (3,4 s).
        for a in anneauxBouees.prefix(BudgetDecor.anneauxMax / 2) {
            for k in 0..<2 {
                let u = frac((t - a.4 - Double(k) * 1.7) / 3.4)
                let e = 1 - (1 - u) * (1 - u)
                let echelle = CGFloat(0.3 + 1.2 * e)
                ctx.stroke(cad.ellipse(a.0, a.1, a.2 * echelle, a.3 * echelle), with: .color(c(0xE8F6FF, 0.7 * (1 - u))),
                           lineWidth: max(0.5, cad.r(k == 0 ? 1.4 : 1)))
            }
        }
    }

    /// Devant les poissons : le bokeh multicolore, douze disques pleins qui dérivent à peine.
    static func bokehEte(_ ctx: inout GraphicsContext, taille: CGSize, t: Double) {
        let cols: [RVB] = [(255, 205, 125), (255, 175, 195), (150, 235, 225), (255, 240, 170)]
        let s: CGFloat = taille.width / 390
        var c2 = ctx
        c2.blendMode = .plusLighter
        for i in 0..<BudgetDecor.bokehMax {
            let dx: Double = bruit(i, 40) + 0.012 * sin(t * 0.12 + Double(i))
            let dy: Double = 0.04 + 0.34 * bruit(i, 41)
            let x: CGFloat = CGFloat(dx) * taille.width
            let y: CGFloat = CGFloat(dy) * taille.height + 6 * s * CGFloat(sin(t * 0.15 + Double(i) * 2))
            let r: CGFloat = CGFloat(16 + 34 * bruit(i, 42)) * s
            let col = cols[min(Int(bruit(i, 43) * Double(cols.count)), cols.count - 1)]
            let a: Double = 0.16 * (0.5 + 0.5 * sin(t * 0.5 + Double(i) * 1.9)) * (0.5 + 0.5 * bruit(i, 44))
            c2.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(c(col, a * 0.75)))
        }
    }

    // MARK: Les reflets dorés du sol (deux images pré-rendues, que la vue fait glisser)

    /// Le haut de la zone des reflets, dans le cadre de conception.
    private static let hautReflets: CGFloat = 690

    /// Largeur de l'image de reflets : une fois et demie l'écran, pour pouvoir glisser sans révéler de bord.
    static func dimensionsReflets(ecran: CGSize) -> CGSize {
        let cad = CadreDecor(ecran)
        return CGSize(width: ecran.width * 1.5, height: max(1, ecran.height - cad.p(0, hautReflets).y))
    }

    /// Où poser l'image de reflets sur l'écran (coin haut gauche, sans glissement).
    static func origineReflets(ecran: CGSize) -> CGPoint {
        CGPoint(x: -ecran.width * 0.25, y: CadreDecor(ecran).p(0, hautReflets).y)
    }

    /// Dessine une famille de reflets dans son image (`origine` = (0, 0)), ou directement sur l'écran (`origineReflets`).
    /// Famille 0 : réseau doré ; famille 1 : réseau rosé plus large et plus discret.
    static func reflets(_ ctx: inout GraphicsContext, ecran: CGSize, famille: Int, origine: CGPoint) {
        let cad = CadreDecor(ecran)
        let haut = cad.p(0, hautReflets).y
        let largeur: CGFloat = 585
        let (y0, a, col, cell, fadeTop, t): (CGFloat, Double, RVB, CGFloat, Double, Double) =
            famille == 0 ? (694, 0.5, (255, 244, 206), 34, 0.25, 3) : (700, 0.18, (255, 200, 210), 43, 0.3, 3 * 0.8)
        let rangs = 7
        let colonnes = Int((largeur / cell).rounded(.up)) + 2
        var noeuds: [[(p: CGPoint, v: Double)]] = []
        for rw in 0...rangs {
            let v = Double(rw) / Double(rangs)
            let yy = y0 + (844 - y0 + 30) * CGFloat(pow(v, 1.15))
            let sc = 0.55 + 0.95 * v
            var rang: [(p: CGPoint, v: Double)] = []
            for k in -1..<(colonnes - 1) {
                let i = rw * 91 + k + 5
                let dx: CGFloat = (CGFloat(k) + 0.5 + CGFloat(bruit(i, 60) - 0.5) * 0.9) * cell * CGFloat(0.8 + 0.4 * v)
                let ondeX: CGFloat = 7 * CGFloat(sin(t * 0.5 + Double(i) * 1.7) * sc)
                let dy: CGFloat = CGFloat(bruit(i, 61) - 0.5) * cell * 0.34 * CGFloat(sc)
                let ondeY: CGFloat = 3.5 * CGFloat(sin(t * 0.43 + Double(i) * 2.3) * sc)
                let x = dx + ondeX
                let y = yy + dy + ondeY
                rang.append((CGPoint(x: origine.x + x * cad.s, y: origine.y + (cad.unite(y) * cad.s - haut)), v))
            }
            noeuds.append(rang)
        }
        func arete(_ p: (p: CGPoint, v: Double), _ q: (p: CGPoint, v: Double), _ k: Int) {
            let v = (p.v + q.v) / 2
            let masque = fadeTop + (1 - fadeTop) * v
            let al = a * masque * (0.25 + 0.75 * bruit(k, 63)) * (0.7 + 0.3 * sin(t * 0.9 + Double(k) * 1.9))
            if al < 0.012 { return }
            let dx = q.p.x - p.p.x
            let dy = q.p.y - p.p.y
            let bd = CGFloat(bruit(k, 64) - 0.5) * 0.9
            var chemin = Path()
            chemin.move(to: p.p)
            chemin.addQuadCurve(to: q.p, control: CGPoint(x: (p.p.x + q.p.x) / 2 - dy * bd, y: (p.p.y + q.p.y) / 2 + dx * bd * 0.45))
            ctx.stroke(chemin, with: .color(c(col, al * 0.22)), style: StrokeStyle(lineWidth: cad.r(9 * CGFloat(0.45 + v)), lineCap: .round))
            ctx.stroke(chemin, with: .color(c(col, al * 0.9)),
                       style: StrokeStyle(lineWidth: cad.r(CGFloat(1.3 + 1.6 * v)), lineCap: .round))
        }
        for rw in 0..<rangs {
            for k in 0..<colonnes {
                let idx = rw * 131 + k
                let p = noeuds[rw][k]
                if k + 1 < colonnes { arete(p, noeuds[rw][k + 1], idx) }
                arete(p, noeuds[rw + 1][k], idx + 7)
                if bruit(idx, 66) > 0.55 && k + 1 < colonnes {
                    arete(p, noeuds[rw + 1][k + 1], idx + 13)
                } else if bruit(idx, 67) > 0.6 && k > 0 {
                    arete(p, noeuds[rw + 1][k - 1], idx + 19)
                }
            }
        }
    }
}
