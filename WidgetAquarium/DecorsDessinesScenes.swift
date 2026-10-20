import SwiftUI

// Les cinq décors dessinés en code, d'après la direction « Ambiance » (C) choisie par Titouan sur la page de propositions :
//   sous-bois         la rivière sous les arbres : berge qui surplombe, lumière dorée en rais, poussières
//   etang             l'étang vu d'en dessous : couvert de nénuphars, eau verte et sombre, filaments qui pendent
//   grotte            la grotte : parois de roche, une ouverture claire en haut à gauche, cristaux qui luisent
//   noel              le sapin immergé (DecorsDessinesNoel.swift) : glace givrée, flocons, graviers poudrés de givre
//   halloween         la nuit : lune, citrouilles lumineuses, racines tordues, toiles, brume et feuilles mortes
//   ouverture-truite  la rivière claire du printemps : lumière vive, pollen, hautes herbes fleuries ET un sol
//                     (lit de graviers, galets, herbes basses) que la page de propositions n'avait pas
// Noël est la proposition B « Sapin immergé » de la page noel-ete. Été n'a PAS de dessin (nouvelles propositions en cours) :
// `reglage` rend `nil`, le fond d'origine reste. Fichier PARTAGÉ app + widget : aucune dépendance à `App/`, `Core` ou à l'état de l'app.
// Chaque décor se compose de quatre temps : filtre sur le fond d'origine, calques de lumière, dessin fixe (sol, roches…),
// dessin qui bouge (plantes, lueurs, brume, rais, particules). Le dessin qui bouge ne dépend que de `t`.
// ⚠ à vérifier sur Mac : couleurs, positions et lisibilité des poissons devant chaque décor.

nonisolated extension DecorDessin {
    /// Le filtre posé sur le fond d'origine (l'image `fond-<format>`) : teinte, saturation, et un multiplicateur par canal
    /// (assombrissement + teinte « multiplier » de la page), plus un éclat ajouté pour les décors plus clairs que le fond.
    struct Filtre {
        var teinte: Double
        var saturation: Double
        var multiplicateur: RVB
        var eclat: Double = 0
    }

    /// Un calque de lumière ou d'ombre posé sur le fond filtré, sous le dessin.
    enum Calque {
        case aplat(RVB, Double)
        /// Dégradé qui part du haut (opacité donnée) et s'efface à `fin` (part de la hauteur).
        case haut(RVB, Double, Double)
        /// Dégradé qui part du bas et s'efface à `fin` (part de la hauteur).
        case bas(RVB, Double, Double)
        /// Tache de lumière : centre et rayons en parts de la largeur / hauteur, couleur, opacité.
        case lueur(Double, Double, Double, Double, RVB, Double)
        /// Bords sombres : centre, rayons, début (part du rayon où le voile commence), couleur, opacité.
        case vignette(Double, Double, Double, Double, Double, RVB, Double)
    }

    struct Reglage {
        var filtre: Filtre
        var calques: [Calque]
        var ambiance: Ambiance
    }

    /// Le réglage d'un décor, ou `nil` s'il n'a pas de dessin (le décor de départ, Noël, Été, un identifiant inconnu).
    static func reglage(_ id: String) -> Reglage? {
        switch id {
        case "sous-bois":
            return Reglage(
                filtre: Filtre(teinte: -30, saturation: 0.7, multiplicateur: (0.454, 0.484, 0.454)),
                calques: [.vignette(0.5, 0.45, 0.8, 0.6, 0.45, (2, 10, 6), 0.65)],
                ambiance: Ambiance(
                    rais: Rais(c: (255, 236, 170), a: 0.2, large: 1.5, n: 5),
                    caustiques: Caustiques(c: (255, 245, 200), a: 0.06),
                    particules: Particules(type: .poussiere, c: (225, 240, 200), a: 0.4, vitesse: 3.2),
                    bulles: Bulles(c: (235, 250, 235), y: 0.82)))
        case "etang":
            return Reglage(
                filtre: Filtre(teinte: -40, saturation: 0.75, multiplicateur: (0.361, 0.390, 0.342)),
                calques: [.haut((6, 12, 4), 0.5, 0.28), .vignette(0.5, 0.5, 0.85, 0.65, 0.5, (3, 8, 2), 0.6)],
                ambiance: Ambiance(
                    rais: Rais(c: (230, 255, 170), a: 0.22, large: 0.8, n: 4),
                    caustiques: Caustiques(c: (225, 255, 190), a: 0.05),
                    particules: Particules(type: .poussiere, c: (200, 230, 130), a: 0.5, vitesse: 0.8),
                    proches: 1.1,
                    bulles: Bulles(c: (225, 245, 215), y: 0.82)))
        case "grotte":
            return Reglage(
                filtre: Filtre(teinte: 12, saturation: 0.75, multiplicateur: (0.127, 0.137, 0.162)),
                calques: [.lueur(0.18, 0.12, 0.6, 0.5, (190, 225, 255), 0.32),
                          .vignette(0.5, 0.42, 0.8, 0.62, 0.38, (0, 2, 6), 0.8)],
                ambiance: Ambiance(
                    rais: Rais(c: (205, 230, 255), a: 0.11, large: 0.6, n: 3),
                    caustiques: Caustiques(c: (190, 220, 255), a: 0.04, portee: 0.8),
                    particules: Particules(type: .lueur, c: (130, 225, 240), a: 0.7),
                    bulles: Bulles(c: (205, 230, 255), y: 0.84)))
        case "halloween":
            return Reglage(
                filtre: Filtre(teinte: -30, saturation: 0.5, multiplicateur: (0.247, 0.263, 0.274)),
                calques: [.lueur(0.5, 0.98, 0.8, 0.55, (255, 130, 30), 0.5),
                          .vignette(0.5, 0.45, 0.82, 0.62, 0.42, (2, 3, 6), 0.7)],
                ambiance: Ambiance(
                    rais: Rais(c: (255, 225, 170), a: 0.1, large: 0.7, n: 4),
                    caustiques: Caustiques(c: (255, 230, 190), a: 0.03),
                    particules: Particules(type: .feuille, c: (0, 0, 0), a: 0.95, feuilles: [0x9A4A18, 0x6E3412, 0xB3732A, 0x4E2A10]),
                    bulles: Bulles(c: (255, 235, 205), y: 0.84)))
        case "noel":
            return Reglage(
                filtre: Filtre(teinte: 4, saturation: 0.6, multiplicateur: (0.307, 0.346, 0.382)),
                calques: [.aplat((60, 100, 150), 0.08), .haut((190, 225, 250), 0.18, 0.28),
                          .vignette(0.5, 0.44, 0.88, 0.66, 0.46, (2, 8, 18), 0.72)],
                ambiance: Ambiance(
                    rais: Rais(c: (220, 238, 255), a: 0.1, large: 1, n: 4),
                    caustiques: Caustiques(c: (225, 238, 255), a: 0.04),
                    particules: Particules(type: .flocon, c: (236, 246, 255), a: 0.5, taille: 0.8),
                    proches: 1.1,
                    bulles: Bulles(c: (235, 245, 255), y: 0.84)))
        case "ouverture-truite":
            return Reglage(
                filtre: Filtre(teinte: -34, saturation: 1, multiplicateur: (1, 1, 1), eclat: 0.05),
                calques: [.aplat((170, 255, 150), 0.10), .lueur(0.35, 0, 0.7, 0.4, (255, 250, 190), 0.4),
                          .bas((40, 70, 20), 0.3, 0.4)],
                ambiance: Ambiance(
                    rais: Rais(c: (255, 250, 200), a: 0.2, large: 1.5, n: 5),
                    caustiques: Caustiques(c: (240, 255, 215), a: 0.09),
                    particules: Particules(type: .pollen, c: (255, 245, 170), a: 0.85),
                    proches: 1.06,
                    bulles: Bulles(c: (245, 255, 240), y: 0.82)))
        default:
            return nil
        }
    }

    // MARK: Les calques

    static func calque(_ ctx: inout GraphicsContext, taille: CGSize, _ k: Calque) {
        let l = taille.width
        let h = taille.height
        let plein = Path(CGRect(origin: .zero, size: taille))
        switch k {
        case .aplat(let col, let a):
            ctx.fill(plein, with: .color(c(col, a)))
        case .haut(let col, let a, let fin):
            ctx.fill(plein, with: .linearGradient(degrade([(0, c(col, a)), (1, c(col, 0))]),
                                                  startPoint: .zero, endPoint: CGPoint(x: 0, y: h * CGFloat(fin))))
        case .bas(let col, let a, let fin):
            ctx.fill(plein, with: .linearGradient(degrade([(0, c(col, a)), (1, c(col, 0))]),
                                                  startPoint: CGPoint(x: 0, y: h),
                                                  endPoint: CGPoint(x: 0, y: h * CGFloat(1 - fin))))
        case .lueur(let cx, let cy, let rx, let ry, let col, let a):
            lueur(ctx, centre: CGPoint(x: CGFloat(cx) * l, y: CGFloat(cy) * h), rx: CGFloat(rx) * l, ry: CGFloat(ry) * h,
                  arrets: [(0, c(col, a)), (0.7, c(col, 0)), (1, c(col, 0))])
        case .vignette(let cx, let cy, let rx, let ry, let debut, let col, let a):
            vignette(ctx, taille: taille, cx: cx, cy: cy, rx: rx, ry: ry, debut: debut, c: col, a: a)
        }
    }

    // MARK: Les quatre temps d'un décor

    /// Les calques de lumière puis le dessin qui ne bouge pas (sol, roches, berges, lune…). Dessiné une seule fois.
    static func fixeArriere(_ ctx: inout GraphicsContext, taille: CGSize, skin: String) {
        guard let r = reglage(skin) else { return }
        for k in r.calques { calque(&ctx, taille: taille, k) }
        let cad = CadreDecor(taille)
        switch skin {
        case "sous-bois": fixeSousBois(&ctx, cad)
        case "etang": fixeEtang(&ctx, cad)
        case "grotte": fixeGrotte(&ctx, cad)
        case "halloween": fixeHalloween(&ctx, cad)
        case "noel": fixeNoel(&ctx, cad)
        case "ouverture-truite": fixeOuverture(&ctx, cad)
        default: break
        }
    }

    /// Ce qui bouge derrière les poissons : plantes, lueurs, brume, puis rais, reflets et poussières.
    static func mobileArriere(_ ctx: inout GraphicsContext, taille: CGSize, skin: String, t: Double) {
        guard let r = reglage(skin) else { return }
        let cad = CadreDecor(taille)
        switch skin {
        case "sous-bois": mobileSousBois(&ctx, cad, t)
        case "etang": mobileEtang(&ctx, cad, t)
        case "grotte": mobileGrotte(&ctx, cad, t)
        case "halloween": mobileHalloween(&ctx, cad, taille, t)
        case "noel": mobileNoel(&ctx, cad, t)
        case "ouverture-truite": mobileOuverture(&ctx, cad, t)
        default: break
        }
        ambianceArriere(&ctx, taille: taille, t: t, r.ambiance)
    }

    /// Devant les poissons : végétation de l'avant-plan, poussières proches et bulles (bulles seulement en mouvement).
    static func mobileAvant(_ ctx: inout GraphicsContext, taille: CGSize, skin: String, t: Double, bulles: Bool) {
        guard let r = reglage(skin) else { return }
        let cad = CadreDecor(taille)
        switch skin {
        case "sous-bois":
            ctx.opacity = 0.95
            herbes(&ctx, cad, graine: 121, t: t, x0: -20, x1: 70, n: 8, y0: 850, hmin: 120, hmax: 230,
                   couleurs: [0x0D1A10, 0x14251A], pente: 24, amp: 2.2, nervure: false)
            herbes(&ctx, cad, graine: 122, t: t, x0: 320, x1: 420, n: 8, y0: 850, hmin: 110, hmax: 210,
                   couleurs: [0x0D1A10, 0x14251A], pente: -24, amp: 2.2, nervure: false)
            ctx.opacity = 1
        case "etang":
            brins(&ctx, cad, graine: 221, t: t, x0: -10, x1: 400, n: 16, y0: 860, hmin: 40, hmax: 150,
                  couleur: Color(.sRGB, red: 60 / 255, green: 80 / 255, blue: 30 / 255, opacity: 0.85), fleurs: false)
        case "noel":
            avantNoel(&ctx, cad)
        case "ouverture-truite":
            brins(&ctx, cad, graine: 621, t: t, x0: -30, x1: 90, n: 6, y0: 860, hmin: 150, hmax: 320,
                  couleur: c(0x4F8A3A), fleurs: true)
            brins(&ctx, cad, graine: 622, t: t, x0: 300, x1: 430, n: 6, y0: 860, hmin: 150, hmax: 320,
                  couleur: c(0x4F8A3A), fleurs: true)
        default: break
        }
        ambianceAvant(&ctx, taille: taille, t: t, r.ambiance, bulles: bulles)
    }

    // MARK: Sous-bois

    private static func fixeSousBois(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(12)
        sol(&ctx, cad, &g, y0: 740, amp: 22, pas: 26,
            arrets: [(0, c(0x1A2A1C, 0)), (0.3, c(0x1D2E1F, 0.9)), (1, c(0x0A140D))])
        galets(&ctx, cad, &g, n: 22, y0: 760, y1: 840, palette: [0x3E4636, 0x2D352B, 0x4A4C3A, 0x38402F], rmin: 16, rmax: 32)
        // La berge qui surplombe, en haut à gauche et à droite.
        let degradeBerge = degrade([(0, c(0x0B1A12)), (1, c(0x122318))])
        let depart = CGPoint(x: 0, y: cad.p(0, -10).y)
        let fin = CGPoint(x: 0, y: cad.p(0, 190).y)
        var gauche = Path()
        gauche.move(to: cad.p(-10, -10))
        gauche.addLine(to: cad.p(260, -10))
        gauche.addQuadCurve(to: cad.p(190, 52), control: cad.p(230, 40))
        gauche.addQuadCurve(to: cad.p(120, 98), control: cad.p(150, 60))
        gauche.addQuadCurve(to: cad.p(60, 120), control: cad.p(96, 128))
        gauche.addQuadCurve(to: cad.p(-10, 190), control: cad.p(34, 150))
        gauche.closeSubpath()
        ctx.fill(gauche, with: .linearGradient(degradeBerge, startPoint: depart, endPoint: fin))
        var droite = Path()
        droite.move(to: cad.p(400, -10))
        droite.addLine(to: cad.p(260, -10))
        droite.addQuadCurve(to: cad.p(322, 40), control: cad.p(290, 30))
        droite.addQuadCurve(to: cad.p(372, 90), control: cad.p(352, 50))
        droite.addLine(to: cad.p(400, 118))
        droite.closeSubpath()
        ctx.fill(droite, with: .linearGradient(degradeBerge, startPoint: depart, endPoint: fin))
    }

    private static func mobileSousBois(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ t: Double) {
        // Les racines de la berge pendent dans l'eau et se balancent (point d'attache en haut).
        let racines: [(CGFloat, CGFloat, CGFloat)] = [(60, 120, 70), (120, 98, 56), (182, 54, 40), (330, 42, 62), (360, 84, 48)]
        for (i, rac) in racines.enumerated() {
            let angle: Double = 2.5 * Double.pi / 180 * balance(t, periode: 14, retard: Double(i))
            let k = rac.2 * CGFloat(angle)
            let versLaFin: CGFloat = i % 2 == 1 ? -4 : 6
            let versLeCentre: CGFloat = i % 2 == 1 ? 10 : -8
            var racine = Path()
            racine.move(to: cad.p(rac.0, rac.1))
            racine.addQuadCurve(to: cad.p(rac.0 + versLaFin + k, rac.1 + rac.2),
                                control: cad.p(rac.0 + versLeCentre + k * 0.5, rac.1 + rac.2 * 0.5))
            ctx.stroke(racine, with: .color(c(0x16261A)),
                       style: StrokeStyle(lineWidth: max(1, cad.r(CGFloat(3 + i % 3))), lineCap: .round))
        }
    }

    // MARK: Étang

    private static func fixeEtang(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(22)
        let feuille = [(0.0, c(0x5E6E24)), (0.7, c(0x3E4E1B)), (1.0, c(0x202B0E))]
        // Le couvert de nénuphars en haut : la surface vue d'en dessous, tiges qui descendent.
        for i in 0..<16 {
            let cx = g.suivant() * 410 - 10
            let cy = -6 + g.suivant() * 92
            let rx = 34 + g.suivant() * 34
            let ry = 10 + g.suivant() * 8
            let tige: CGFloat = i % 3 == 0 ? 200 + g.suivant() * 300 : 0
            nenuphar(&ctx, cad, &g, cx: cx, cy: cy, rx: rx, ry: ry, tige: tige, arrets: feuille, couleurTige: 0x34411A)
        }
        sol(&ctx, cad, &g, y0: 745, amp: 20, pas: 26,
            arrets: [(0, c(0x141A0C, 0)), (0.3, c(0x161E0E, 0.95)), (1, c(0x080B05))])
    }

    private static func mobileEtang(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ t: Double) {
        herbes(&ctx, cad, graine: 222, t: t, x0: -10, x1: 400, n: 22, y0: 800, hmin: 60, hmax: 170,
               couleurs: [0x2C3A18, 0x364520, 0x25311A], pente: 26, amp: 2.6)
    }

    /// Un nénuphar vu d'en dessous : un disque échancré, des nervures, une tige.
    private static func nenuphar(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor, cx: CGFloat,
                                 cy: CGFloat, rx: CGFloat, ry: CGFloat, tige: CGFloat, arrets: [(Double, Color)],
                                 couleurTige: UInt32) {
        let encoche = Double(g.suivant()) * 6.28
        var pts: [CGPoint] = []
        var centreAjoute = false
        var a = 0.0
        while a <= Double.pi * 2 + 0.01 {
            var d = (a - encoche).truncatingRemainder(dividingBy: 2 * Double.pi)
            if d > Double.pi { d -= 2 * Double.pi }
            if d < -Double.pi { d += 2 * Double.pi }
            if abs(d) < 0.13 {
                if !centreAjoute {
                    pts.append(cad.p(cx, cy))
                    centreAjoute = true
                }
            } else {
                pts.append(cad.p(cx + rx * CGFloat(cos(a)), cy + ry * CGFloat(sin(a))))
                centreAjoute = false
            }
            a += Double.pi / 20
        }
        if tige > 0 {
            var t = Path()
            t.move(to: cad.p(cx, cy))
            t.addCurve(to: cad.p(cx + 6, tige), control1: cad.p(cx + 14, cy + (tige - cy) * 0.3),
                       control2: cad.p(cx - 16, cy + (tige - cy) * 0.62))
            ctx.stroke(t, with: .color(c(couleurTige, 0.85)), style: StrokeStyle(lineWidth: max(1, cad.r(3.4)), lineCap: .round))
        }
        var disque = Path()
        for (i, q) in pts.enumerated() {
            if i == 0 { disque.move(to: q) } else { disque.addLine(to: q) }
        }
        disque.closeSubpath()
        let centre = cad.p(cx, cy - ry * 0.1)
        ctx.fill(disque, with: .radialGradient(degrade(arrets), center: centre, startRadius: 0, endRadius: cad.r(rx * 1.2)))
        ctx.stroke(disque, with: .color(c(0x141E0A, 0.5)), lineWidth: max(0.8, cad.r(1.2)))
        for i in 0..<9 {
            let ang = encoche + 0.4 + Double(i) * 0.65
            var nerv = Path()
            nerv.move(to: cad.p(cx, cy))
            nerv.addLine(to: cad.p(cx + rx * 0.92 * CGFloat(cos(ang)), cy + ry * 0.92 * CGFloat(sin(ang))))
            ctx.stroke(nerv, with: .color(c(0xFFF0AA, 0.25)), lineWidth: max(0.5, cad.r(1)))
        }
    }

    // MARK: Grotte

    private static func fixeGrotte(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(32)
        let paroi = degrade([(0, c(0x1F2B36)), (1, c(0x080D12))])
        let haut = CGPoint(x: 0, y: cad.p(0, -10).y)
        let bas = CGPoint(x: 0, y: cad.h)
        var gauche = Path()
        gauche.move(to: cad.p(-10, -10))
        gauche.addLine(to: cad.p(10, -10))
        for (c1, p) in [((40, 60), (20, 140)), ((10, 220), (40, 300)), ((60, 380), (24, 460)), ((0, 540), (30, 640))] as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
            gauche.addQuadCurve(to: cad.p(p.0, p.1), control: cad.p(c1.0, c1.1))
        }
        gauche.addLine(to: cad.p(30, 860))
        gauche.addLine(to: cad.p(-10, 860))
        gauche.closeSubpath()
        ctx.fill(gauche, with: .linearGradient(paroi, startPoint: haut, endPoint: bas))
        var droite = Path()
        droite.move(to: cad.p(400, -10))
        droite.addLine(to: cad.p(360, -10))
        for (c1, p) in [((340, 80), (370, 160)), ((392, 240), (350, 330)), ((330, 420), (372, 520)), ((392, 600), (350, 700))] as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
            droite.addQuadCurve(to: cad.p(p.0, p.1), control: cad.p(c1.0, c1.1))
        }
        droite.addLine(to: cad.p(340, 860))
        droite.addLine(to: cad.p(400, 860))
        droite.closeSubpath()
        ctx.fill(droite, with: .linearGradient(paroi, startPoint: haut, endPoint: bas))
        // Le plafond, déchiqueté, avec l'ouverture claire en haut à gauche.
        var plafond = Path()
        plafond.move(to: cad.p(60, -10))
        plafond.addLine(to: cad.p(360, -10))
        for (c1, p) in [((330, 20), (300, 14)), ((270, 48), (240, 24)), ((210, 56), (180, 26)), ((150, 66), (120, 30)), ((96, 52), (60, -10))] as [((CGFloat, CGFloat), (CGFloat, CGFloat))] {
            plafond.addQuadCurve(to: cad.p(p.0, p.1), control: cad.p(c1.0, c1.1))
        }
        plafond.closeSubpath()
        ctx.opacity = 0.96
        ctx.fill(plafond, with: .linearGradient(paroi, startPoint: haut, endPoint: bas))
        ctx.opacity = 1
        let roche = degrade([(0, c(0x1F2B36)), (1, c(0x080D12))])
        self.roche(&ctx, cad, &g, cx: 90, cy: 826, rx: 120, ry: 80, degrade: roche)
        self.roche(&ctx, cad, &g, cx: 300, cy: 834, rx: 130, ry: 86, degrade: roche)
        // Le rai de lumière qui entre par l'ouverture, flou.
        var rai = Path()
        rai.move(to: cad.p(70, -10))
        rai.addLine(to: cad.p(150, -10))
        rai.addLine(to: cad.p(330, 760))
        rai.addLine(to: cad.p(210, 760))
        rai.closeSubpath()
        let degradeRai = degrade([(0, c(0xEAF6FF, 0.55)), (0.5, c(0xBFE3FA, 0.18)), (1, c(0xBFE3FA, 0))])
        let hautRai = CGPoint(x: 0, y: cad.p(0, -10).y)
        let basRai = CGPoint(x: 0, y: cad.p(0, 760).y)
        ctx.drawLayer { couche in
            couche.addFilter(.blur(radius: cad.r(10)))
            couche.fill(rai, with: .linearGradient(degradeRai, startPoint: hautRai, endPoint: basRai))
        }
        cristaux(&ctx, cad, cx: 304, cy: 748, echelle: 1.2, couleur: 0xA8E6EF)
    }

    private static func mobileGrotte(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ t: Double) {
        // La lueur des cristaux palpite doucement.
        let palpite = 0.725 + 0.275 * balance(t, periode: 3.2, retard: 0)
        let lueurCristaux = [(0.0, c(0x8FE4EE, 0.6)), (1.0, c(0x8FE4EE, 0))]
        var c2 = ctx
        c2.opacity = palpite
        lueur(c2, centre: cad.p(304, 738), rx: cad.r(62), ry: cad.r(62), arrets: lueurCristaux)
    }

    // MARK: Halloween

    private static func fixeHalloween(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(42)
        // La lune et son halo, en haut à droite.
        var halo = ctx
        halo.opacity = 0.7
        lueur(halo, centre: cad.p(300, 96), rx: cad.r(130), ry: cad.r(130),
              arrets: [(0, c(0xFFF3D6, 0.95)), (0.5, c(0xFFE9BD, 0.5)), (1, c(0xFFE9BD, 0))])
        ctx.fill(cad.ellipse(300, 96, 30, 30), with: .color(c(0xFFF1CC, 0.92)))
        ctx.fill(cad.ellipse(291, 90, 6, 6), with: .color(c(0xE8D5A8, 0.6)))
        ctx.fill(cad.ellipse(310, 106, 4, 4), with: .color(c(0xE8D5A8, 0.6)))
        sol(&ctx, cad, &g, y0: 758, amp: 18, pas: 26,
            arrets: [(0, c(0x0B0807, 0)), (0.3, c(0x0C0908, 0.95)), (1, c(0x030202))])
        citrouille(&ctx, cad, cx: 290, cy: 806, R: 38)
        citrouille(&ctx, cad, cx: 106, cy: 786, R: 52)
        // Les racines tordues, en silhouette.
        let racines: [[CGFloat]] = [[-10, 844, 60, 640, 30, 540], [26, 844, 50, 700, 100, 600],
                                    [400, 844, 340, 660, 372, 560], [366, 844, 330, 720, 290, 640]]
        for (i, q) in racines.enumerated() {
            var tronc = Path()
            tronc.move(to: cad.p(q[0], q[1]))
            tronc.addQuadCurve(to: cad.p(q[4], q[5]), control: cad.p(q[2], q[3]))
            ctx.stroke(tronc, with: .color(c(0x06100F)),
                       style: StrokeStyle(lineWidth: max(1, cad.r(CGFloat(16 - i * 2))), lineCap: .round))
            let dx: CGFloat = i % 2 == 1 ? -30 : 30
            let fx: CGFloat = i % 2 == 1 ? -40 : 42
            let bx = q[2] * 0.9 + q[4] * 0.1
            let by = q[3] * 0.8 + q[5] * 0.2
            var branche = Path()
            branche.move(to: cad.p(bx, by))
            branche.addQuadCurve(to: cad.p(bx + fx, by - 70), control: cad.p(bx + dx, by - 26))
            ctx.stroke(branche, with: .color(c(0x06100F)), style: StrokeStyle(lineWidth: max(1, cad.r(6)), lineCap: .round))
        }
        toile(&ctx, cad, x: 0, y: 0, sens: 1)
        toile(&ctx, cad, x: 390, y: 0, sens: -1)
    }

    private static func mobileHalloween(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ taille: CGSize, _ t: Double) {
        visageCitrouille(&ctx, cad, t: t, cx: 290, cy: 806, R: 38, retard: 0.7)
        visageCitrouille(&ctx, cad, t: t, cx: 106, cy: 786, R: 52, retard: 2.1)
        brume(&ctx, taille: taille, t: t, c1: c(0xFFEBD2, 0.16), c2: c(0xB4C8D2, 0.12))
    }

    /// Le corps d'une citrouille : cinq lobes, un reflet, une queue.
    private static func citrouille(_ ctx: inout GraphicsContext, _ cad: CadreDecor, cx: CGFloat, cy: CGFloat, R: CGFloat) {
        let peau = degrade([(0, c(0xE08A3A)), (0.6, c(0xB9561B)), (1, c(0x7A3410))])
        let centre = cad.p(cx, cy - R * 0.15)
        let lobes: [(CGFloat, CGFloat)] = [(-0.62, 0.58), (0.62, 0.58), (-0.32, 0.8), (0.32, 0.8), (0, 0.9)]
        for lobe in lobes {
            let forme = cad.ellipse(cx + lobe.0 * R, cy, lobe.1 * R, R * 0.84)
            ctx.fill(forme, with: .radialGradient(peau, center: centre, startRadius: 0, endRadius: cad.r(R * 1.2)))
            ctx.stroke(forme, with: .color(c(0x3C1606, 0.55)), lineWidth: max(0.8, cad.r(1.2)))
        }
        var reflet = Path(ellipseIn: CGRect(x: -R * 0.18 * cad.s, y: -R * 0.3 * cad.s, width: R * 0.36 * cad.s, height: R * 0.6 * cad.s))
        let rc = cad.p(cx - R * 0.5, cy - R * 0.4)
        reflet = reflet.applying(CGAffineTransform(rotationAngle: -25 * CGFloat.pi / 180)
            .concatenating(CGAffineTransform(translationX: rc.x, y: rc.y)))
        ctx.fill(reflet, with: .color(.white.opacity(0.16)))
        var queue = Path()
        queue.move(to: cad.p(cx - R * 0.1, cy - R * 0.8))
        queue.addQuadCurve(to: cad.p(cx + R * 0.2, cy - R * 1.12), control: cad.p(cx - R * 0.05, cy - R * 1.1))
        queue.addLine(to: cad.p(cx + R * 0.28, cy - R * 0.98))
        queue.addQuadCurve(to: cad.p(cx + R * 0.12, cy - R * 0.78), control: cad.p(cx + R * 0.1, cy - R * 0.95))
        queue.closeSubpath()
        ctx.fill(queue, with: .color(c(0x4A4A1C)))
        ctx.stroke(queue, with: .color(c(0x141406, 0.6)), lineWidth: max(0.6, cad.r(1)))
    }

    /// Le visage lumineux : un halo et des yeux et une bouche clairs, qui vacillent comme une bougie.
    private static func visageCitrouille(_ ctx: inout GraphicsContext, _ cad: CadreDecor, t: Double, cx: CGFloat,
                                         cy: CGFloat, R: CGFloat, retard: Double) {
        let vacille = 0.875 + 0.125 * balance(t, periode: 5.2, retard: retard)
        var c2 = ctx
        c2.opacity = vacille
        lueur(c2, centre: cad.p(cx, cy), rx: cad.r(R * 1.5), ry: cad.r(R * 1.5),
              arrets: [(0, c(0xFFD98A, 0.95)), (0.4, c(0xFFB347, 0.45)), (1, c(0xFF8A1E, 0))])
        func yeux(_ x1: CGFloat, _ x2: CGFloat, _ x3: CGFloat) -> Path {
            var p = Path()
            p.move(to: cad.p(cx + x1 * R, cy - R * 0.3))
            p.addLine(to: cad.p(cx + x2 * R, cy - R * 0.3))
            p.addLine(to: cad.p(cx + x3 * R, cy - R * 0.02))
            p.closeSubpath()
            return p
        }
        var visage = yeux(-0.5, -0.18, -0.34)
        visage.addPath(yeux(0.18, 0.5, 0.34))
        let bouche: [(CGFloat, CGFloat)] = [(-0.52, 0.14), (-0.28, 0.3), (-0.12, 0.16), (0, 0.32), (0.12, 0.16), (0.28, 0.3),
                                            (0.52, 0.14), (0.3, 0.5), (-0.3, 0.5)]
        var m = Path()
        for (i, q) in bouche.enumerated() {
            let pt = cad.p(cx + q.0 * R, cy + q.1 * R)
            if i == 0 { m.move(to: pt) } else { m.addLine(to: pt) }
        }
        m.closeSubpath()
        visage.addPath(m)
        c2.fill(visage, with: .color(c(0xFFE2A0)))
    }

    /// Une toile d'araignée dans un coin (`sens` 1 : coin gauche, -1 : coin droit).
    private static func toile(_ ctx: inout GraphicsContext, _ cad: CadreDecor, x: CGFloat, y: CGFloat, sens: CGFloat) {
        let l: [(CGFloat, CGFloat)] = [(0, 0), (110, 0), (95, 60), (60, 105), (0, 120)]
        for i in 1..<l.count {
            var rayon = Path()
            rayon.move(to: cad.p(x, y))
            rayon.addLine(to: cad.p(x + sens * l[i].0, y + l[i].1))
            ctx.stroke(rayon, with: .color(c(0xE6EBF0, 0.55)), lineWidth: max(0.5, cad.r(1)))
        }
        for k in 1...4 {
            let f = CGFloat(k) / 4
            var fil = Path()
            for i in 1..<l.count {
                let px = x + sens * l[i].0 * f
                let py = y + l[i].1 * f
                if i == 1 {
                    fil.move(to: cad.p(px, py))
                } else {
                    let qx = x + sens * l[i - 1].0 * f
                    let qy = y + l[i - 1].1 * f
                    fil.addQuadCurve(to: cad.p(px, py), control: cad.p((qx + px) / 2 - sens * 3, (qy + py) / 2 + 3))
                }
            }
            ctx.stroke(fil, with: .color(c(0xE6EBF0, 0.4)), lineWidth: max(0.5, cad.r(0.9)))
        }
    }

    // MARK: Ouverture de la truite (avec un sol)

    private static func fixeOuverture(_ ctx: inout GraphicsContext, _ cad: CadreDecor) {
        var g = GraineDecor(62)
        // Le lit de la rivière : un fond de graviers clair, éclairé d'en haut, plus sombre vers l'avant.
        sol(&ctx, cad, &g, y0: 742, amp: 14, pas: 24,
            arrets: [(0, c(0xA39C74, 0)), (0.08, c(0xA9A27A, 0.95)), (0.45, c(0x84855D)), (1, c(0x4A5033))])
        // Le gravier fin : une semis de petits cailloux.
        let gravier: [UInt32] = [0xD9D3B3, 0xB8B290, 0x9A9A7C, 0xC9C3A4, 0x7F8468]
        for _ in 0..<150 {
            let x = g.suivant() * 410 - 10
            let k = Double(g.suivant())
            let y = 748 + 96 * CGFloat(pow(k, 0.8))
            let rx = (1.2 + g.suivant() * 3.2) * (0.6 + 0.8 * (y - 748) / 96)
            let col = gravier[g.indice(gravier.count)]
            ctx.fill(cad.ellipse(x, y, rx, rx * 0.62), with: .color(c(col, 0.85)))
            if rx > 3 {
                ctx.fill(cad.ellipse(x - rx * 0.2, y - rx * 0.25, rx * 0.5, rx * 0.3), with: .color(.white.opacity(0.25)))
            }
        }
        // Les galets, avec leur ombre portée, éclairés par le haut gauche comme le reste de la scène.
        galets(&ctx, cad, &g, n: 30, y0: 756, y1: 838, palette: [0xB9B496, 0x9DA286, 0xC9C3A4, 0x8A9078, 0xA7A084],
               rmin: 11, rmax: 28, ombre: 0.28, reflet: 0.28)
        galets(&ctx, cad, &g, n: 3, y0: 798, y1: 832, palette: [0x8A9078, 0x9DA286], rmin: 30, rmax: 40, ombre: 0.32, reflet: 0.3)
    }

    private static func mobileOuverture(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ t: Double) {
        // Des plaques de lumière dansent sur le fond, comme sous une eau peu profonde.
        for i in 0..<7 {
            let x = CGFloat(bruit(i, 50)) * 410 + CGFloat(8 * sin(t * 0.21 + Double(i)))
            let y = 758 + CGFloat(bruit(i, 51)) * 76
            let rx = 28 + CGFloat(bruit(i, 52)) * 40
            let alpha = 0.10 + 0.05 * sin(t * 0.4 + Double(i) * 1.7)
            lueur(ctx, centre: cad.p(x, y), rx: cad.r(rx), ry: cad.r(rx * 0.24),
                  arrets: [(0, c(0xFFFADC, alpha)), (0.7, c(0xFFFADC, 0)), (1, c(0xFFFADC, 0))])
        }
        // Les herbes basses du sol, puis les hautes herbes fleuries du fond.
        herbes(&ctx, cad, graine: 623, t: t, x0: -10, x1: 400, n: 26, y0: 846, hmin: 26, hmax: 66,
               couleurs: [0x79B050, 0x5E9440, 0x8CC25E], pente: 8, amp: 2.4)
        brins(&ctx, cad, graine: 624, t: t, x0: -20, x1: 200, n: 16, y0: 790, hmin: 110, hmax: 260, couleur: c(0x79B050), fleurs: true)
        brins(&ctx, cad, graine: 625, t: t, x0: 200, x1: 420, n: 16, y0: 790, hmin: 110, hmax: 260, couleur: c(0x79B050), fleurs: true)
    }
}
