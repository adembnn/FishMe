import SwiftUI

// Les décors d'aquarium DESSINÉS EN CODE (N1, suite) : briques communes. Ce fichier est PARTAGÉ : il est compilé dans
// l'app ET dans l'extension du widget (`WidgetAquarium/` est dans les deux cibles). Il ne dépend ni de `App/` ni de `Core`
// ni d'aucun état : seulement l'identifiant du décor (texte) et la taille. Aucun texte, aucune image, aucun emoji.
// Les dessins sont tracés dans un cadre de 390 x 844 points (la page de propositions de Titouan) puis mis à l'échelle :
// largeur ajustée, le sol reste en bas et le plafond en haut quelle que soit la hauteur (widget petit, moyen, grand).
// ⚠ à vérifier sur Mac : rendu des `Canvas` (rien n'a été compilé sur cette machine).

/// Le cadre de conception : 390 de large, 844 de haut, ajusté à la taille réelle.
nonisolated struct CadreDecor {
    let l: CGFloat
    let h: CGFloat
    /// Pixels par unité de conception (la largeur fait toujours 390 unités).
    let s: CGFloat
    /// Hauteur disponible en unités de conception (844 sur un iPhone, moins dans un widget).
    let hd: CGFloat

    init(_ taille: CGSize) {
        l = max(taille.width, 1)
        h = max(taille.height, 1)
        s = max(taille.width, 1) / 390
        hd = max(taille.height, 1) / (max(taille.width, 1) / 390)
    }

    /// Hauteur de conception -> hauteur de conception ajustée : le haut (jusqu'à 300) reste en haut, le bas (dès 600)
    /// reste en bas, le milieu s'écrase ou s'étire entre les deux. La fonction est continue.
    func unite(_ y: CGFloat) -> CGFloat {
        let delta = 844 - hd
        if y <= 300 { return y }
        if y >= 600 { return y - delta }
        return y - delta * (y - 300) / 300
    }

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: unite(y) * s) }

    /// Une longueur de conception en points.
    func r(_ v: CGFloat) -> CGFloat { v * s }

    func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        let c = p(cx, cy)
        return Path(ellipseIn: CGRect(x: c.x - rx * s, y: c.y - ry * s, width: rx * s * 2, height: ry * s * 2))
    }
}

/// Un générateur de nombres reproductible : le même décor donne toujours le même dessin (mulberry32).
nonisolated struct GraineDecor {
    private var etat: UInt32

    init(_ graine: UInt32) { etat = graine }

    /// De 0 (inclus) à 1 (exclu).
    mutating func suivant() -> CGFloat {
        etat = etat &+ 0x6D2B79F5
        var t: UInt32 = (etat ^ (etat >> 15)) &* (1 | etat)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        let v: UInt32 = t ^ (t >> 14)
        return CGFloat(v) / 4294967296.0
    }

    /// Un indice au hasard dans `0..<n`.
    mutating func indice(_ n: Int) -> Int {
        guard n > 0 else { return 0 }
        return min(Int(suivant() * CGFloat(n)), n - 1)
    }
}

nonisolated enum DecorDessin {
    typealias RVB = (Double, Double, Double)

    /// L'instant figé des décors immobiles (widget, « Réduire les animations ») : une image bien composée.
    static let tFixe: Double = 27

    // MARK: Couleurs et dégradés

    static func c(_ hex: UInt32, _ a: Double = 1) -> Color {
        Color(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255,
              blue: Double(hex & 255) / 255, opacity: a)
    }

    static func c(_ v: RVB, _ a: Double) -> Color {
        Color(.sRGB, red: v.0 / 255, green: v.1 / 255, blue: v.2 / 255, opacity: a)
    }

    static func degrade(_ arrets: [(Double, Color)]) -> Gradient {
        Gradient(stops: arrets.map { Gradient.Stop(color: $0.1, location: CGFloat($0.0)) })
    }

    /// Bruit déterministe 0...1 (même formule que `EffetsEau.bruit`, qui reste dans l'app).
    static func bruit(_ i: Int, _ k: Int) -> Double {
        let v = sin(Double(i) * 12.9898 + Double(k) * 78.233) * 43758.5453
        return v - v.rounded(.down)
    }

    static func frac(_ v: Double) -> Double { v - v.rounded(.down) }

    /// Un balancement lent, entre -1 et 1 (`periode` en secondes, `retard` en secondes).
    static func balance(_ t: Double, periode: Double, retard: Double) -> Double {
        sin(2 * Double.pi * (t - retard) / periode)
    }

    // MARK: Chemins

    /// Une courbe douce qui passe entre les points (quadratiques par les milieux).
    static func lisse(_ pts: [CGPoint]) -> Path {
        var chemin = Path()
        guard pts.count > 1 else { return chemin }
        chemin.move(to: pts[0])
        if pts.count > 2 {
            for i in 1..<(pts.count - 1) {
                let milieu = CGPoint(x: (pts[i].x + pts[i + 1].x) / 2, y: (pts[i].y + pts[i + 1].y) / 2)
                chemin.addQuadCurve(to: milieu, control: pts[i])
            }
        }
        chemin.addLine(to: pts[pts.count - 1])
        return chemin
    }

    /// Une polyligne fermée ou non, à partir de points de conception.
    static func ligne(_ cad: CadreDecor, _ pts: [(CGFloat, CGFloat)], ferme: Bool) -> Path {
        var chemin = Path()
        for (i, q) in pts.enumerated() {
            if i == 0 { chemin.move(to: cad.p(q.0, q.1)) } else { chemin.addLine(to: cad.p(q.0, q.1)) }
        }
        if ferme { chemin.closeSubpath() }
        return chemin
    }

    // MARK: Le sol, les galets, les roches

    /// Le lit du fond : une ligne irrégulière puis tout le bas de l'écran, rempli d'un dégradé vertical.
    static func sol(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor, y0: CGFloat,
                    amp: CGFloat, pas: CGFloat, arrets: [(Double, Color)]) {
        var pts: [CGPoint] = [cad.p(-20, y0)]
        var x: CGFloat = 0
        while x <= 410 {
            pts.append(cad.p(x, y0 + (g.suivant() - 0.5) * amp))
            x += pas
        }
        var chemin = lisse(pts)
        chemin.addLine(to: cad.p(410, 860))
        chemin.addLine(to: cad.p(-20, 860))
        chemin.closeSubpath()
        let haut = cad.p(0, y0 - amp / 2).y
        ctx.fill(chemin, with: .linearGradient(degrade(arrets), startPoint: CGPoint(x: 0, y: haut),
                                               endPoint: CGPoint(x: 0, y: cad.h)))
    }

    /// Des galets arrondis, plus gros et plus bas vers l'avant, avec un reflet clair en haut à gauche.
    static func galets(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor, n: Int,
                       y0: CGFloat, y1: CGFloat, palette: [UInt32], rmin: CGFloat, rmax: CGFloat,
                       ombre: Double = 0, reflet: Double = 0.2) {
        struct Galet { var x: CGFloat; var y: CGFloat; var rx: CGFloat; var ry: CGFloat; var couleur: UInt32 }
        var liste: [Galet] = []
        for _ in 0..<n {
            let x = g.suivant() * 410 - 10
            let k = Double(g.suivant())
            let y = y0 + (y1 - y0) * CGFloat(pow(k, 0.85))
            let rx = (rmin + (rmax - rmin) * g.suivant()) * (0.7 + 0.6 * (y - y0) / max(y1 - y0, 1))
            let ry = rx * (0.5 + 0.2 * g.suivant())
            let couleur = palette[g.indice(palette.count)]
            liste.append(Galet(x: x, y: y, rx: rx, ry: ry, couleur: couleur))
        }
        liste.sort { $0.y < $1.y }
        for gal in liste {
            if ombre > 0 {
                ctx.fill(cad.ellipse(gal.x + gal.rx * 0.16, gal.y + gal.ry * 0.45, gal.rx * 1.05, gal.ry * 0.8),
                         with: .color(c(0x0A140C, ombre)))
            }
            let corps = cad.ellipse(gal.x, gal.y, gal.rx, gal.ry)
            ctx.fill(corps, with: .color(c(gal.couleur)))
            ctx.stroke(corps, with: .color(c(0x0A141E, 0.35)), lineWidth: max(0.6, cad.r(1)))
            ctx.fill(cad.ellipse(gal.x - gal.rx * 0.22, gal.y - gal.ry * 0.32, gal.rx * 0.6, gal.ry * 0.42),
                     with: .color(.white.opacity(reflet)))
        }
    }

    /// Une roche en dôme (la grotte).
    static func roche(_ ctx: inout GraphicsContext, _ cad: CadreDecor, _ g: inout GraineDecor, cx: CGFloat,
                      cy: CGFloat, rx: CGFloat, ry: CGFloat, degrade g2: Gradient) {
        let n = 9
        var pts: [(CGFloat, CGFloat)] = []
        for i in 0..<n {
            let a = Double.pi * (1 + Double(i) / Double(n - 1))
            let k = 0.82 + g.suivant() * 0.3
            let kk = 0.9 + g.suivant() * 0.25
            pts.append((cx + rx * CGFloat(cos(a)) * k, cy + ry * CGFloat(sin(a)) * k * kk))
        }
        var liste: [(CGFloat, CGFloat)] = [(cx - rx, cy + 4)]
        liste.append(contentsOf: pts)
        liste.append((cx + rx, cy + 4))
        let corps = ligne(cad, liste, ferme: true)
        let haut = cad.p(cx, cy - ry).y
        let bas = cad.p(cx, cy + 4).y
        ctx.fill(corps, with: .linearGradient(g2, startPoint: CGPoint(x: 0, y: haut), endPoint: CGPoint(x: 0, y: bas)))
        ctx.stroke(corps, with: .color(c(0x00060C, 0.65)), style: StrokeStyle(lineWidth: max(0.8, cad.r(1.3)), lineJoin: .round))
        let crete = ligne(cad, pts.prefix(5).map { ($0.0, $0.1 + 2) }, ferme: false)
        ctx.stroke(crete, with: .color(c(0xAACDE6, 0.22)), lineWidth: max(0.8, cad.r(1.6)))
    }

    /// Un bouquet de cristaux (la grotte).
    static func cristaux(_ ctx: inout GraphicsContext, _ cad: CadreDecor, cx: CGFloat, cy: CGFloat, echelle: CGFloat,
                         couleur: UInt32) {
        let modeles: [(CGFloat, CGFloat, Double)] = [(-14, -30, -14), (0, -48, 0), (13, -34, 12), (24, -18, 26)]
        for m in modeles {
            let ox = cx + m.0 * echelle
            let oy = cy
            let ang = m.2 * Double.pi / 180
            let ca = CGFloat(cos(ang))
            let sa = CGFloat(sin(ang))
            func T(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                cad.p(ox + x * ca - y * sa, oy + x * sa + y * ca)
            }
            let h = m.1 * echelle
            var corps = Path()
            corps.move(to: T(-6, 0))
            corps.addLine(to: T(-5, h * 0.8))
            corps.addLine(to: T(0, h))
            corps.addLine(to: T(5, h * 0.8))
            corps.addLine(to: T(6, 0))
            corps.closeSubpath()
            ctx.fill(corps, with: .color(c(couleur, 0.78)))
            ctx.stroke(corps, with: .color(c(0xE6FAFF, 0.7)), lineWidth: max(0.6, cad.r(1)))
            var arete = Path()
            arete.move(to: T(0, h))
            arete.addLine(to: T(0, 0))
            ctx.stroke(arete, with: .color(.white.opacity(0.45)), lineWidth: max(0.6, cad.r(1)))
        }
    }

    // MARK: Plantes qui se balancent

    /// Des lames d'herbe ou de roseau. `t` pilote le balancement (période 12 s) ; dans un décor figé, `t` est fixe.
    static func herbes(_ ctx: inout GraphicsContext, _ cad: CadreDecor, graine: UInt32, t: Double, x0: CGFloat,
                       x1: CGFloat, n: Int, y0: CGFloat, hmin: CGFloat, hmax: CGFloat, couleurs: [UInt32],
                       pente: CGFloat, amp: Double, nervure: Bool = true) {
        var g = GraineDecor(graine)
        for _ in 0..<n {
            let x = x0 + (x1 - x0) * g.suivant()
            let h = hmin + (hmax - hmin) * g.suivant()
            let w = 2.6 + g.suivant() * 3.2
            let l = (g.suivant() - 0.5) * 2 * pente
            let col = couleurs[g.indice(couleurs.count)]
            let retard = Double(g.suivant()) * 6
            let a = amp * (0.6 + Double(g.suivant()) * 0.8)
            let angle: Double = a * Double.pi / 180 * balance(t, periode: 12, retard: retard)
            let k = h * CGFloat(angle)
            var lame = Path()
            lame.move(to: cad.p(x - w, y0))
            lame.addQuadCurve(to: cad.p(x + l + k, y0 - h),
                              control: cad.p(x - w * 0.3 + l * 0.3 + k * 0.55, y0 - h * 0.55))
            lame.addQuadCurve(to: cad.p(x + w, y0), control: cad.p(x + w * 0.4 + l * 0.3 + k * 0.5, y0 - h * 0.5))
            lame.closeSubpath()
            ctx.fill(lame, with: .color(c(col)))
            ctx.stroke(lame, with: .color(c(0x081810, 0.35)), lineWidth: max(0.5, cad.r(0.8)))
            if nervure {
                var v = Path()
                v.move(to: cad.p(x, y0))
                v.addQuadCurve(to: cad.p(x + l * 0.98 + k, y0 - h * 0.97), control: cad.p(x + l * 0.25 + k * 0.5, y0 - h * 0.5))
                ctx.stroke(v, with: .color(.white.opacity(0.22)), lineWidth: max(0.5, cad.r(1)))
            }
        }
    }

    /// De longs brins fins qui se balancent, avec ou sans petites fleurs blanches au bout.
    static func brins(_ ctx: inout GraphicsContext, _ cad: CadreDecor, graine: UInt32, t: Double, x0: CGFloat,
                      x1: CGFloat, n: Int, y0: CGFloat, hmin: CGFloat, hmax: CGFloat, couleur: Color, fleurs: Bool) {
        var g = GraineDecor(graine)
        for _ in 0..<n {
            let x = x0 + (x1 - x0) * g.suivant()
            let h = hmin + (hmax - hmin) * g.suivant()
            let l = (g.suivant() - 0.5) * 70
            let retard = Double(g.suivant()) * 6
            let amp = 2 + Double(g.suivant()) * 2.5
            let largeur = 1.4 + g.suivant() * 1.2
            let angle: Double = amp * Double.pi / 180 * balance(t, periode: 12, retard: retard)
            let k = h * CGFloat(angle)
            let ex = x + l + k
            let ey = y0 - h
            var brin = Path()
            brin.move(to: cad.p(x, y0))
            brin.addCurve(to: cad.p(ex, ey), control1: cad.p(x + l * 0.2 + k * 0.4, y0 - h * 0.4),
                          control2: cad.p(x + l * 0.9 + k * 0.8, y0 - h * 0.6))
            ctx.stroke(brin, with: .color(couleur), style: StrokeStyle(lineWidth: max(0.6, cad.r(largeur)), lineCap: .round))
            if fleurs && g.suivant() < 0.55 {
                for j in 0..<5 {
                    let a = Double(j) * 1.2566
                    let px = ex + CGFloat(cos(a)) * 4.2
                    let py = ey + CGFloat(sin(a)) * 4.2
                    let centre = cad.p(px, py)
                    var petale = Path(ellipseIn: CGRect(x: -3.6 * cad.s, y: -2.6 * cad.s, width: 7.2 * cad.s, height: 5.2 * cad.s))
                    petale = petale.applying(CGAffineTransform(rotationAngle: CGFloat(a))
                        .concatenating(CGAffineTransform(translationX: centre.x, y: centre.y)))
                    ctx.fill(petale, with: .color(c(0xFBFBF2)))
                    ctx.stroke(petale, with: .color(c(0x1E3214, 0.35)), lineWidth: max(0.4, cad.r(0.6)))
                }
                ctx.fill(cad.ellipse(ex, ey, 2.2, 2.2), with: .color(c(0xE6C34A)))
            }
        }
    }
}
