import SwiftUI

// L'ambiance de l'aquarium : rais de lumière, caustiques de surface, particules en suspension, bulles rares et
// ondes de toucher. Tout est dessiné dans des `Canvas` à partir du seul temps `t` (formules fermées : aucun état,
// aucune allocation d'image à image) et reste discret pour ne jamais cacher les poissons.
// Avec « Réduire les animations », la vue n'affiche aucune de ces couches (tout est statique comme avant).

/// Réglages de l'ambiance (les valeurs d'opacité sont volontairement basses).
nonisolated enum ReglagesEffets {
  static let nombreRais = 5
  static let opaciteRais = 0.075
  static let opaciteCaustiques = 0.05
  static let lignesCaustiques = 9
  static let particulesFond = 26
  static let particulesAvant = 9
  static let opaciteParticules = 0.32
  /// Parallaxe de la caméra en points : amplitude du balancement.
  static let parallaxe = 2.6
  /// Émetteurs de bulles : position x (part de la largeur), période de base (s). Une bulle monte 7 s.
  static let emetteurs: [(x: Double, periode: Double)] = [(0.13, 27), (0.62, 33), (0.87, 24)]
  static let bullesParEmetteur = 2
  static let dureeMontee = 7.0
  static let yBulles = 0.80
}

nonisolated enum EffetsEau {
  /// Bruit déterministe 0...1 pour une graine entière et un canal.
  static func bruit(_ i: Int, _ k: Int) -> Double {
    let v = sin(Double(i) * 12.9898 + Double(k) * 78.233) * 43758.5453
    return v - v.rounded(.down)
  }

  private static func frac(_ v: Double) -> Double { v - v.rounded(.down) }

  // MARK: Rais de lumière

  /// De longs faisceaux inclinés qui ondulent très lentement depuis la surface.
  static func raisLumiere(_ ctx: inout GraphicsContext, taille: CGSize, t: Double) {
    let l = taille.width
    let h = taille.height
    ctx.blendMode = .plusLighter
    for i in 0..<ReglagesEffets.nombreRais {
      let f = Double(i)
      let centre = (0.08 + 0.22 * f + 0.05 * sin(t * 0.045 + f * 1.7)) * l
      let pente = (0.20 + 0.05 * sin(t * 0.03 + f)) * l
      let largeur = (0.05 + 0.025 * bruit(i, 1)) * l
      let force = ReglagesEffets.opaciteRais * (0.45 + 0.55 * (0.5 + 0.5 * sin(t * 0.11 + f * 2.1)))
      var chemin = Path()
      chemin.move(to: CGPoint(x: centre - largeur * 0.5, y: -0.05 * h))
      chemin.addLine(to: CGPoint(x: centre + largeur * 0.5, y: -0.05 * h))
      chemin.addLine(to: CGPoint(x: centre + pente + largeur * 1.2, y: 0.85 * h))
      chemin.addLine(to: CGPoint(x: centre + pente - largeur * 1.2, y: 0.85 * h))
      chemin.closeSubpath()
      let degrade = Gradient(colors: [
        .white.opacity(force), .white.opacity(force * 0.35), .white.opacity(0),
      ])
      ctx.fill(
        chemin,
        with: .linearGradient(
          degrade, startPoint: CGPoint(x: centre, y: 0),
          endPoint: CGPoint(x: centre + pente, y: 0.85 * h)))
    }
    ctx.blendMode = .normal
  }

  // MARK: Caustiques

  /// Deux familles de lignes ondulantes qui se croisent : les croisements s'éclairent, comme la lumière
  /// qui danse sur le fond sous la surface. Dans la moitié haute surtout.
  static func caustiques(_ ctx: inout GraphicsContext, taille: CGSize, t: Double) {
    let l = taille.width
    let h = taille.height
    ctx.blendMode = .plusLighter
    let segments = 16
    for famille in 0..<2 {
      for i in 0..<ReglagesEffets.lignesCaustiques {
        let f = Double(i)
        let base = (0.04 + 0.085 * f + 0.012 * sin(t * 0.16 + f * 1.3 + Double(famille))) * h
        let vue = 1 - min(max(base / (0.8 * h), 0), 1)
        let alpha = ReglagesEffets.opaciteCaustiques * vue
        if alpha < 0.004 { continue }
        let k = famille == 0 ? 3.1 : 4.3
        let vitesse = famille == 0 ? 0.33 : -0.27
        let phase = f * 1.9 + Double(famille) * 2.4
        var chemin = Path()
        for s in 0...segments {
          let u = Double(s) / Double(segments)
          let x = u * l
          let decalage =
            0.014 * h * sin(u * k * .pi * 2 + t * vitesse + phase)
            + 0.008 * h * sin(u * (k * 2.3) * .pi * 2 - t * vitesse * 1.4 + phase * 0.7)
          let y = base + decalage + (famille == 1 ? 0.03 * h * u : 0)
          if s == 0 {
            chemin.move(to: CGPoint(x: x, y: y))
          } else {
            chemin.addLine(to: CGPoint(x: x, y: y))
          }
        }
        ctx.stroke(chemin, with: .color(.white.opacity(alpha * 0.45)), lineWidth: 7)
        ctx.stroke(chemin, with: .color(.white.opacity(alpha)), lineWidth: 1.6)
      }
    }
    ctx.blendMode = .normal
  }

  // MARK: Particules

  /// Poussières en suspension : un courant très lent, un léger tremblement, un scintillement.
  /// `de` ..< `jusqua` : les premières sont derrière les poissons, les suivantes devant (plus grosses).
  static func particules(
    _ ctx: inout GraphicsContext, taille: CGSize, t: Double, de: Int, jusqua: Int,
    avant: Bool
  ) {
    let l = taille.width
    let h = taille.height
    for i in de..<jusqua {
      let sens = bruit(i, 5) < 0.5 ? 1.0 : -1.0
      let vx = (0.004 + 0.006 * bruit(i, 2)) * sens * (avant ? 1.6 : 1)
      let vy = (bruit(i, 6) - 0.5) * 0.004
      let x = frac(bruit(i, 0) + t * vx + 0.012 * sin(t * 0.27 + bruit(i, 3) * 6.28))
      let y = frac(bruit(i, 1) + t * vy + 0.010 * sin(t * 0.21 + bruit(i, 4) * 6.28))
      let rayon = (avant ? 1.6 : 0.7) + (avant ? 1.6 : 1.3) * bruit(i, 7)
      let scint = 0.6 + 0.4 * sin(t * (0.5 + bruit(i, 8)) + bruit(i, 9) * 6.28)
      let alpha =
        ReglagesEffets.opaciteParticules * (avant ? 0.55 : 1) * (0.4 + 0.6 * bruit(i, 10)) * scint
      let r = CGRect(x: x * l - rayon, y: y * h - rayon, width: rayon * 2, height: rayon * 2)
      ctx.fill(Path(ellipseIn: r), with: .color(.white.opacity(alpha)))
    }
  }

  // MARK: Bulles

  /// Quelques bulles rares qui montent de la végétation, avec un léger balancement.
  static func bulles(_ ctx: inout GraphicsContext, taille: CGSize, t: Double) {
    let l = taille.width
    let h = taille.height
    for (e, em) in ReglagesEffets.emetteurs.enumerated() {
      for k in 0..<ReglagesEffets.bullesParEmetteur {
        let periode = em.periode + Double(k) * 5.5
        let local = (t + bruit(e, 20 + k) * periode).truncatingRemainder(dividingBy: periode)
        guard local < ReglagesEffets.dureeMontee else { continue }
        let u = local / ReglagesEffets.dureeMontee
        let monte = 1 - pow(1 - u, 1.6)
        let y = (ReglagesEffets.yBulles - monte * (ReglagesEffets.yBulles - 0.10)) * h
        let x = (em.x + 0.012 * sin(u * 11 + Double(k) * 2) * (0.3 + u)) * l
        let rayon = 1.8 + 2.4 * u + bruit(e, 30 + k)
        let alpha = 0.55 * min(1, u * 10) * (1 - u * u * u)
        let cercle = CGRect(x: x - rayon, y: y - rayon, width: rayon * 2, height: rayon * 2)
        ctx.stroke(
          Path(ellipseIn: cercle), with: .color(.white.opacity(alpha * 0.8)), lineWidth: 0.9)
        ctx.fill(Path(ellipseIn: cercle), with: .color(.white.opacity(alpha * 0.08)))
        let reflet = CGRect(
          x: x - rayon * 0.45, y: y - rayon * 0.55, width: rayon * 0.5, height: rayon * 0.4)
        ctx.fill(Path(ellipseIn: reflet), with: .color(.white.opacity(alpha * 0.9)))
      }
    }
  }

  // MARK: Ondes de toucher

  /// Un cercle de lumière qui s'élargit et s'efface, deux anneaux décalés. `t` : temps de la simulation.
  static func ondes(_ ctx: inout GraphicsContext, taille: CGSize, t: Double, ondes: [Onde]) {
    let l = taille.width
    let h = taille.height
    ctx.blendMode = .plusLighter
    for onde in ondes {
      let age = t - onde.debut
      guard age >= 0, age < Onde.duree else { continue }
      let centre = CGPoint(x: onde.x * l, y: onde.y * h)
      for (rang, retard) in [0.0, 0.35].enumerated() {
        let a = age - retard
        guard a > 0 else { continue }
        let u = a / (Onde.duree - retard)
        let sortie = 1 - pow(1 - u, 2.2)
        let rayon = (0.02 + 0.13 * sortie) * l
        let alpha = 0.5 * pow(1 - u, 2) * (rang == 0 ? 1 : 0.6)
        let ellipse = CGRect(
          x: centre.x - rayon, y: centre.y - rayon * 0.62, width: rayon * 2, height: rayon * 1.24)
        ctx.stroke(
          Path(ellipseIn: ellipse), with: .color(.white.opacity(alpha)), lineWidth: 2.2 - 1.2 * u)
      }
      // Un halo doux au départ.
      if age < 0.9 {
        let u = age / 0.9
        let rayon = 0.09 * l
        let halo = Gradient(colors: [.white.opacity(0.28 * (1 - u)), .white.opacity(0)])
        let ellipse = CGRect(
          x: centre.x - rayon, y: centre.y - rayon * 0.62, width: rayon * 2, height: rayon * 1.24)
        ctx.fill(
          Path(ellipseIn: ellipse),
          with: .radialGradient(halo, center: centre, startRadius: 0, endRadius: rayon))
      }
    }
    ctx.blendMode = .normal
  }
}

/// Les couches derrière les poissons : rais de lumière, caustiques, poussières du fond.
/// Ces couches bougent très lentement : elles ont leur propre horloge à 20 images par seconde (au lieu de suivre les poissons
/// à chaque image de l'écran) et se dessinent hors du fil principal.
struct CoucheFondEau: View {
  var body: some View {
    TimelineView(.animation(minimumInterval: 1.0 / 20)) { contexte in
      let t = contexte.date.timeIntervalSinceReferenceDate
      Canvas(rendersAsynchronously: true) { ctx, taille in
        EffetsEau.raisLumiere(&ctx, taille: taille, t: t)
        EffetsEau.caustiques(&ctx, taille: taille, t: t)
        EffetsEau.particules(
          &ctx, taille: taille, t: t, de: 0, jusqua: ReglagesEffets.particulesFond, avant: false)
      }
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}

/// Les couches devant les poissons : quelques poussières proches, bulles, ondes de toucher.
struct CoucheAvantEau: View {
  let t: Double
  let tempsMoteur: Double
  let ondes: [Onde]
  /// Faux : un décor dessiné en code apporte sa propre ambiance (poussières proches, bulles) ; ici seules les ondes restent.
  var ambiance: Bool = true

  var body: some View {
    Canvas(rendersAsynchronously: true) { ctx, taille in
      let debut = ReglagesEffets.particulesFond
      if ambiance {
        EffetsEau.particules(
          &ctx, taille: taille, t: t, de: debut, jusqua: debut + ReglagesEffets.particulesAvant,
          avant: true)
        EffetsEau.bulles(&ctx, taille: taille, t: t)
      }
      EffetsEau.ondes(&ctx, taille: taille, t: tempsMoteur, ondes: ondes)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }
}
