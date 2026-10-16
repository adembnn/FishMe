import Core
import SwiftUI

// Les pièces de la révélation « Le dos de la carte » (variation B, `anim-arrivee-b.js`).
// Tout est une fonction pure du temps écoulé (en millisecondes), comme dans le JS de référence :
// `ChronoRevelation.etat(t)` donne l'état de chaque effet à l'instant t, les vues ne font que le dessiner.

// MARK: - Petites courbes

/// Les courbes d'adoucissement du JS, en Swift. `u` va de 0 à 1.
enum CourbesRevelation {
    static func c01(_ x: Double) -> Double { x < 0 ? 0 : (x > 1 ? 1 : x) }
    static func lerp(_ a: Double, _ b: Double, _ u: Double) -> Double { a + (b - a) * u }
    /// Avancement de t entre a et b, borné à 0...1.
    static func prog(_ t: Double, _ a: Double, _ b: Double) -> Double { c01((t - a) / (b - a)) }
    static func sstep(_ x: Double) -> Double { let u = c01(x); return u * u * (3 - 2 * u) }
    static func eIO(_ x: Double) -> Double {
        let u = c01(x)
        return u < 0.5 ? 4 * u * u * u : 1 - pow(-2 * u + 2, 3) / 2
    }
    static func eO3(_ x: Double) -> Double { let u = c01(x); return 1 - pow(1 - u, 3) }
    /// Ressort sous-amorti de 0 vers 1 (z : amortissement, w : pulsation).
    static func ressort(_ u: Double, _ z: Double, _ w: Double) -> Double {
        if u <= 0 { return 0 }
        let s: Double = (1 - z * z).squareRoot()
        let wd: Double = w * s
        let amorti: Double = exp(-z * w * u)
        let oscille: Double = cos(wd * u) + (z / s) * sin(wd * u)
        return 1 - amorti * oscille
    }
}

/// Petit générateur de hasard répétable (mulberry32), pour que les braises soient les mêmes à chaque fois.
struct AleaRevelation {
    private var graine: UInt32
    init(_ graine: UInt32) { self.graine = graine }

    mutating func suivant() -> Double {
        graine = graine &+ 0x6D2B79F5
        var t = graine
        t = (t ^ (t >> 15)) &* (1 | t)
        t = (t &+ ((t ^ (t >> 7)) &* (61 | t))) ^ t
        return Double(t ^ (t >> 14)) / 4294967296.0
    }
}

extension Color {
    /// Couleur depuis un nombre hexadécimal 0xRRGGBB (nom propre à ce fichier pour ne pas heurter les autres).
    init(rev hex: UInt32, opacite: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacite)
    }
}

// MARK: - Niveau de rareté de la révélation

/// Les quatre niveaux de la révélation ; « rareté non mesurée » se traite comme commun.
enum NiveauRevelation {
    case commun, peuCommun, rare, legendaire

    init(_ style: StyleRarete) {
        switch style {
        case .commun, .nonMesuree: self = .commun
        case .peuCommun: self = .peuCommun
        case .rare: self = .rare
        case .legendaire: self = .legendaire
        }
    }

    var rang: Int {
        switch self {
        case .commun: return 1
        case .peuCommun: return 2
        case .rare: return 3
        case .legendaire: return 4
        }
    }

    /// Le mot de rareté, éclairci pour rester lisible sur le fond marine.
    var texteSurNuit: Color {
        switch self {
        case .commun: return Color(rev: 0xB9C4CD)
        case .peuCommun: return Color(rev: 0x46CC8C)
        case .rare: return Color(rev: 0x9B90FF)
        case .legendaire: return Color(rev: 0xEDB944)
        }
    }

    /// Teinte claire de la ligne de lumière.
    var teinte: Color {
        switch self {
        case .commun: return Color(rev: 0xDCEBF7)
        case .peuCommun: return Color(rev: 0xA6F0CF)
        case .rare: return Color(rev: 0xC6BEFF)
        case .legendaire: return Color(rev: 0xFFE7A6)
        }
    }

    /// Couleur de la lueur autour de la carte.
    var lueur: Color {
        switch self {
        case .commun: return Color(rev: 0x9CAAB6)
        case .peuCommun: return Color(rev: 0x3EC88C)
        case .rare: return Color(rev: 0x7C6BFF)
        case .legendaire: return Color(rev: 0xF0B842)
        }
    }

    var duree: Double {
        switch self {
        case .commun: return 1600
        case .peuCommun: return 2200
        case .rare: return 3000
        case .legendaire: return 4500
        }
    }

    var moment: MomentSonore {
        switch self {
        case .commun: return .carteCommun
        case .peuCommun: return .cartePeuCommun
        case .rare: return .carteRare
        case .legendaire: return .carteLegendaire
        }
    }

    /// Vrai si des effets continuent de bouger une fois la carte posée (rayons, braises, flottement).
    var animeAuRepos: Bool { self == .rare || self == .legendaire }
}

// MARK: - Le chronomètre

/// Un son ou une vibration à jouer à un instant précis de la révélation.
struct EvenementRevelation {
    let t: Double
    let moment: MomentSonore
    /// Vrai pour le son de la carte : c'est lui qu'on joue quand le pêcheur saute l'attente.
    let estCarte: Bool
}

/// Tout ce que la scène a besoin de savoir à l'instant t.
struct EtatRevelation {
    var angle: Double = 0
    var tremblement: Double = 0
    var decalageX: Double = 0
    var echelle: Double = 1
    var soulevement: Double = 0
    var opaciteDos: Double = 0
    var opaciteSol: Double = 0
    var echelleSol: Double = 1
    var aura: Double = 0
    var lueurBord: Double = 0
    var ecart: Double = 0
    var ligne: Double = 0
    var hauteurLigne: Double = 0
    var fente: Double = 0
    var photo: Double = 0
    var photoFondu: Double = 0
    var photoEchelle: Double = 1
    var ombreFace: Double = 0
    var eclat: Double = 0
    var progressionEclat: Double = 0
    var rayons: Double = 0
    var rayonsLongueur: Double = 1
    var flash: Double = 0
    var burst: Double = 0
    var tension: Double = 0
    var inclinaison: Double = 0
    var arrive: Bool = false
    // Interface finale.
    var motOpacite: Double = 0
    var motDecalage: Double = 0
    var motEchelle: Double = 1
    var boutonOpacite: Double = 0
    var boutonDecalage: Double = 0
}

/// Les phases d'une révélation, par rareté (durées et amplitudes de `BT` dans le JS).
struct ChronoRevelation {
    struct Tremblement {
        let debut: Double
        let fin: Double
        let amplitude: Double
        let cycles: Double
    }

    let niveau: NiveauRevelation
    let rapide: Bool
    let duree: Double
    let photo: Double
    let fenteA: Double
    let fenteB: Double
    let retourneA: Double
    let retourneB: Double
    let ecartMax: Double
    let tremblement: Tremblement?
    /// Instant où la carte passe à 90 degrés : le recto apparaît.
    let croisement: Double
    /// Instant où l'interface finale commence à apparaître.
    let debutInterface: Double

    init(niveau: NiveauRevelation, rapide: Bool) {
        self.niveau = niveau
        self.rapide = rapide
        if rapide {
            duree = 600
            photo = 120
            fenteA = 90
            fenteB = 160
            retourneA = 150
            retourneB = 520
            ecartMax = 0.8
            tremblement = nil
        } else {
            switch niveau {
            case .commun:
                duree = 1600; photo = 420; fenteA = 700; fenteB = 870; retourneA = 820; retourneB = 1420
                ecartMax = 1.6; tremblement = nil
            case .peuCommun:
                duree = 2200; photo = 450; fenteA = 1110; fenteB = 1390; retourneA = 1330; retourneB = 1980
                ecartMax = 2.2; tremblement = Tremblement(debut: 520, fin: 1020, amplitude: 1.6, cycles: 1)
            case .rare:
                duree = 3000; photo = 450; fenteA = 1690; fenteB = 2050; retourneA = 2000; retourneB = 2720
                ecartMax = 3.2; tremblement = Tremblement(debut: 620, fin: 1650, amplitude: 3, cycles: 2)
            case .legendaire:
                duree = 4500; photo = 520; fenteA = 2840; fenteB = 3300; retourneA = 3250; retourneB = 4020
                ecartMax = 4.4; tremblement = Tremblement(debut: 680, fin: 2780, amplitude: 6.2, cycles: 4)
            }
        }
        var cross = retourneB
        for q in 0...400 {
            let u = Double(q) / 400
            if 180 * CourbesRevelation.ressort(u, 0.62, 10) >= 90 {
                cross = CourbesRevelation.lerp(retourneA, retourneB, u)
                break
            }
        }
        croisement = cross
        debutInterface = min(retourneB - 150, duree - 330)
    }

    /// Les sons et vibrations, aux mêmes instants que le JS.
    var evenements: [EvenementRevelation] {
        var liste: [EvenementRevelation] = []
        if let tr = tremblement, niveau == .rare || niveau == .legendaire {
            liste.append(EvenementRevelation(t: tr.debut, moment: .montee, estCarte: false))
        }
        liste.append(EvenementRevelation(t: retourneA + 20, moment: .retournement, estCarte: false))
        liste.append(EvenementRevelation(t: croisement, moment: niveau.moment, estCarte: true))
        return liste
    }

    /// L'état de la scène à l'instant t (en millisecondes).
    func etat(_ t: Double) -> EtatRevelation {
        typealias C = CourbesRevelation
        var e = EtatRevelation()
        let leg = niveau == .legendaire
        let rare = niveau == .rare
        let forte = leg || rare

        // Tremblement du dos de la carte pendant l'attente.
        var tens = 0.0
        var ang = 0.0
        var sx = 0.0
        var scl = 1.0
        if let tr = tremblement {
            let us = C.prog(t, tr.debut, tr.fin)
            if t >= tr.debut && t <= tr.fin {
                let env: Double = leg
                    ? (0.32 + 0.68 * us) * (1 - C.sstep((us - 0.9) / 0.1))
                    : pow(sin(Double.pi * us), 0.8)
                let avance: Double = leg ? us * (0.7 + 0.6 * us) : us
                let phase: Double = Double.pi * 2 * tr.cycles * avance
                ang = tr.amplitude * env * sin(phase)
                sx = ang * 0.22
                if leg { scl = 1 + 0.028 * C.sstep(us) }
            }
            tens = niveau == .peuCommun ? 0 : C.sstep(C.prog(t, tr.debut, tr.fin))
        }
        e.tension = tens
        e.tremblement = ang
        e.decalageX = sx

        let cross = croisement
        let burst: Double = t >= cross ? exp(-(t - cross) / (leg ? 900 : 650)) : 0
        e.burst = burst
        let build: Double = leg ? tens * (0.8 + 0.2 * sin(t / 95 * (1 + tens))) : (rare ? tens * 0.55 : 0)
        let repos: Double = forte ? 0.28 : (niveau == .peuCommun ? 0.12 : 0.06)
        let eAura = max(build * (1 - C.sstep(C.prog(t, retourneA, cross))), 0)
        let retour: Double = t >= retourneA ? C.sstep(C.prog(t, retourneA, retourneB)) * repos + burst * 0.8 : 0
        let auraT: Double = eAura + retour
        e.aura = C.c01(auraT)
        e.lueurBord = build * (1 - C.sstep(C.prog(t, retourneA - 60, retourneA + 140)))

        // Ligne de lumière et écartement des deux moitiés du dos.
        let us2 = C.prog(t, fenteA, fenteB)
        let ferme = 1 - C.sstep(C.prog(t, retourneA, retourneA + 110))
        e.ecart = ecartMax * C.sstep(C.prog(us2, 0.35, 1)) * ferme
        let sy = C.eO3(C.prog(us2, 0, 0.55)) * (t < retourneA + 140 ? 1 : 0)
        let ligneActive = t >= fenteA && t < retourneA + 200
        e.hauteurLigne = max(0.001, sy)
        e.ligne = ligneActive ? min(1, sy * 1.4) * (1 - C.sstep(C.prog(t, retourneA + 20, retourneA + 170))) : 0
        e.fente = ligneActive ? C.sstep(C.prog(us2, 0.15, 1)) * (1 - C.sstep(C.prog(t, retourneA + 30, retourneA + 190))) : 0

        // La photo qui rétrécit vers le dos.
        e.photo = C.eIO(C.prog(t, 0, photo))
        e.photoFondu = 1 - C.sstep(C.prog(t, photo - 40, photo + 130))
        e.photoEchelle = 1 - 0.04 * C.sstep(C.prog(t, photo - 40, photo + 130))
        e.opaciteDos = C.sstep(C.prog(t, photo * 0.55, photo + 80))
        let dt = t - photo
        let pose: Double = t > photo ? 1 + 0.035 * exp(-dt / 120) * cos(dt / 40) : 1

        // Le retournement : ressort, la face change à 90 degrés.
        let milieu = C.c01((t - retourneA) / (retourneB - retourneA))
        e.angle = t < retourneA ? 0 : 180 * C.ressort(C.prog(t, retourneA, retourneB), 0.62, 10)
        e.arrive = t >= cross
        e.inclinaison = C.sstep(C.prog(t, retourneB - 200, retourneB + 500))
        let ampleur: Double = niveau == .commun ? 0.6 : 1
        let pop: Double = 1 + 0.075 * sin(Double.pi * milieu) * ampleur
        e.soulevement = -(sin(Double.pi * milieu) * 1.8)
        e.echelle = scl * pop * pose
        e.ombreFace = (1 - abs(cos(e.angle * Double.pi / 180))) * 0.5
        e.opaciteSol = e.opaciteDos * (0.9 - 0.25 * sin(Double.pi * milieu))
        e.echelleSol = 1 - 0.1 * sin(Double.pi * milieu)

        // Éclat qui balaie le recto à l'arrivée.
        let sw = C.prog(t, cross - 40, cross + 700)
        e.progressionEclat = sw
        let forceEclat: Double = niveau == .commun ? 0.45 : 0.8
        e.eclat = (sw > 0 && sw < 1) ? sin(Double.pi * sw) * forceEclat : 0

        // Rayons violets (rare) : montent pendant le tremblement, éclatent à l'arrivée.
        if rare {
            let montee: Double = max(0.34 * tens * (1 - C.sstep(C.prog(t, retourneA, cross))), 0)
            let plus: Double = t >= retourneA ? C.sstep(C.prog(t, retourneA, cross)) * 0.3 : 0
            var ray: Double = montee + plus
            let apres: Double = t >= cross ? 0.12 * (1 - burst) : 0
            ray = max(ray, burst * 1.15) + apres
            e.rayons = C.c01(ray)
            e.rayonsLongueur = 0.9 + 0.55 * max(burst, tens * 0.6)
        } else if leg {
            e.rayons = 0.12 * tens * (1 - C.sstep(C.prog(t, retourneA, cross)))
            e.rayonsLongueur = 0.8
        }

        // Éclat d'arrivée (rare et légendaire).
        if forte {
            let fa: Double
            if t < cross - 90 { fa = 0 } else if t < cross { fa = (t - (cross - 90)) / 90 } else { fa = exp(-(t - cross) / (leg ? 360 : 240)) }
            e.flash = fa * (leg ? 0.95 : 0.5)
        }

        // Interface finale : mot, badge, points, bouton.
        let a = debutInterface
        let b = duree
        e.motOpacite = C.sstep(C.prog(t, a, a + (b - a) * 0.55))
        e.motDecalage = (1 - C.eO3(C.prog(t, a, a + (b - a) * 0.55))) * 14
        e.motEchelle = C.lerp(0.9, 1, C.eO3(C.prog(t, a, a + (b - a) * 0.7)))
        let pb = C.prog(t, a + (b - a) * 0.35, b)
        e.boutonOpacite = C.sstep(pb)
        e.boutonDecalage = (1 - C.eO3(pb)) * 18
        return e
    }

    /// Avancement d'un des quatre points de rareté (0 à 1) et son échelle.
    func point(_ i: Int, _ t: Double) -> (opacite: Double, echelle: Double) {
        typealias C = CourbesRevelation
        let a = debutInterface + 60 + Double(i) * 90
        let p = C.prog(t, a, a + 260)
        let plein = i < niveau.rang
        let echelle: Double = (plein && p < 1) ? C.lerp(0.2, 1, C.ressort(p, 0.5, 10)) : 1
        let opacite = plein ? C.c01(p * 2) : C.c01(p * 2) * 0.9
        return (opacite, echelle)
    }
}

// MARK: - Le dos gravé

/// Le dessin du dos : eau guillochée, rosette, lune et poisson gravés, cadres, coins (repère 100 x 144,93 du JS).
struct ArtDosCarte: View {
    private static let haut: Double = 144.93

    var body: some View {
        Canvas { contexte, taille in
            var c = contexte
            c.scaleBy(x: taille.width / 100, y: taille.height / CGFloat(Self.haut))
            Self.dessiner(&c)
        }
        .drawingGroup()
        .accessibilityHidden(true)
    }

    private static func dessiner(_ c: inout GraphicsContext) {
        let h = CGFloat(haut)
        // Fond.
        let fond = Gradient(stops: [
            .init(color: Color(rev: 0x14609F), location: 0),
            .init(color: Color(rev: 0x0B3D6B), location: 0.45),
            .init(color: Color(rev: 0x06284A), location: 1)
        ])
        c.fill(Path(CGRect(x: 0, y: 0, width: 100, height: h)),
               with: .radialGradient(fond, center: CGPoint(x: 50, y: 66.7), startRadius: 0, endRadius: 100))

        // Guilloché : deux jeux de vagues qui se croisent.
        var vagues1 = Path()
        var vagues2 = Path()
        for k in 0..<46 {
            let kd = Double(k)
            var x = -2.0
            var premier = true
            while x <= 102 {
                let base: Double = 1.6 + kd * 3.2
                let y1: Double = base + 1.9 * sin(x * 0.17 + kd * 0.36)
                let y2: Double = base + 1.9 * sin(x * 0.17 - kd * 0.36 + 1.2)
                if premier {
                    vagues1.move(to: CGPoint(x: x, y: y1))
                    vagues2.move(to: CGPoint(x: x, y: y2))
                    premier = false
                } else {
                    vagues1.addLine(to: CGPoint(x: x, y: y1))
                    vagues2.addLine(to: CGPoint(x: x, y: y2))
                }
                x += 2
            }
        }
        c.stroke(vagues1, with: .color(Color(rev: 0x9CC7EA, opacite: 0.17)), lineWidth: 0.15)
        c.stroke(vagues2, with: .color(Color(rev: 0xC7DFF3, opacite: 0.10)), lineWidth: 0.12)

        // Rosette.
        c.fill(Path(ellipseIn: CGRect(x: 13, y: 33, width: 74, height: 74)), with: .color(Color(rev: 0x062442, opacite: 0.48)))
        var rosette = Path()
        let ellipse = Path(ellipseIn: CGRect(x: 15, y: 59.5, width: 70, height: 21))
        for k in 0..<54 {
            let angle = Double(k) * Double.pi / 54
            let t = CGAffineTransform(translationX: 50, y: 70).rotated(by: CGFloat(angle)).translatedBy(x: -50, y: -70)
            rosette.addPath(ellipse.applying(t))
        }
        c.stroke(rosette, with: .color(Color(rev: 0x9CC7EA, opacite: 0.30)), lineWidth: 0.12)
        c.stroke(Path(ellipseIn: CGRect(x: 13.8, y: 33.8, width: 72.4, height: 72.4)),
                 with: .color(Color(rev: 0xC7DFF3, opacite: 0.30)), lineWidth: 0.28)
        c.stroke(Path(ellipseIn: CGRect(x: 20.6, y: 40.6, width: 58.8, height: 58.8)),
                 with: .color(Color(rev: 0xC7DFF3, opacite: 0.38)), lineWidth: 0.3)
        let medaillon = Gradient(colors: [Color(rev: 0x0E4F8C), Color(rev: 0x082F57)])
        c.fill(Path(ellipseIn: CGRect(x: 21.6, y: 41.6, width: 56.8, height: 56.8)),
               with: .radialGradient(medaillon, center: CGPoint(x: 50, y: 70), startRadius: 0, endRadius: 28.4))

        // Logo gravé : lune, eau, poisson bondissant (dans le médaillon).
        c.drawLayer { l in
            l.clip(to: Path(ellipseIn: CGRect(x: 22.4, y: 42.4, width: 55.2, height: 55.2)))
            l.translateBy(x: 20, y: 40)
            l.scaleBy(x: 0.6, y: 0.6)
            dessinerLogo(&l)
        }
        c.stroke(Path(ellipseIn: CGRect(x: 22.4, y: 42.4, width: 55.2, height: 55.2)),
                 with: .color(Color(rev: 0xDFF1FF, opacite: 0.5)), lineWidth: 0.4)

        // Cadres et coins.
        c.stroke(Path(roundedRect: CGRect(x: 3.4, y: 3.4, width: 93.2, height: 138.13), cornerRadius: 4.4),
                 with: .color(Color(rev: 0x9CC7EA, opacite: 0.5)), lineWidth: 0.36)
        c.stroke(Path(roundedRect: CGRect(x: 5.2, y: 5.2, width: 89.6, height: 134.53), cornerRadius: 3.2),
                 with: .color(Color(rev: 0x9CC7EA, opacite: 0.22)), lineWidth: 0.22)
        let coins: [(CGFloat, CGFloat, Double)] = [(8.6, 8.6, 0), (91.4, 8.6, 90), (91.4, 136.33, 180), (8.6, 136.33, 270)]
        for coin in coins {
            c.drawLayer { l in
                l.translateBy(x: coin.0, y: coin.1)
                l.rotate(by: .degrees(coin.2))
                var marque = Path()
                marque.move(to: CGPoint(x: -2.6, y: -2.6))
                marque.addLine(to: CGPoint(x: -2.6, y: 2.6))
                marque.move(to: CGPoint(x: -2.6, y: -2.6))
                marque.addLine(to: CGPoint(x: 2.6, y: -2.6))
                marque.addEllipse(in: CGRect(x: -1.1, y: -1.1, width: 2.2, height: 2.2))
                l.stroke(marque, with: .color(Color(rev: 0xC7DFF3, opacite: 0.5)), lineWidth: 0.3)
            }
        }
        let nom = Text("FISHME").font(.system(size: 3.6, weight: .heavy, design: .rounded)).kerning(1.6)
            .foregroundStyle(Color(rev: 0x9CC7EA, opacite: 0.62))
        c.draw(c.resolve(nom), at: CGPoint(x: 50, y: 129.8), anchor: .center)
        let pescedex = Text("PESCEDEX").font(.system(size: 2.6, weight: .heavy, design: .rounded)).kerning(1.4)
            .foregroundStyle(Color(rev: 0x9CC7EA, opacite: 0.4))
        c.draw(c.resolve(pescedex), at: CGPoint(x: 50, y: 15.6), anchor: .center)
    }

    /// Le logo (repère 0 à 100) : halo, lune rayée, eau, poisson, bulles. La silhouette du logo ne change jamais.
    private static func dessinerLogo(_ l: inout GraphicsContext) {
        let halo = Gradient(stops: [
            .init(color: Color(rev: 0x6FC3FF, opacite: 0.30), location: 0),
            .init(color: Color(rev: 0x6FC3FF, opacite: 0.30), location: 0.55),
            .init(color: Color(rev: 0x6FC3FF, opacite: 0), location: 1)
        ])
        l.fill(Path(ellipseIn: CGRect(x: 4, y: 2, width: 92, height: 92)),
               with: .radialGradient(halo, center: CGPoint(x: 50, y: 48), startRadius: 0, endRadius: 46))
        let lune = Gradient(stops: [
            .init(color: Color(rev: 0xB9DDF6, opacite: 0.92), location: 0),
            .init(color: Color(rev: 0x6EA8D6, opacite: 0.92), location: 0.7),
            .init(color: Color(rev: 0x3F7DB4, opacite: 0.92), location: 1)
        ])
        l.fill(Path(ellipseIn: CGRect(x: 18, y: 16, width: 64, height: 64)),
               with: .radialGradient(lune, center: CGPoint(x: 44.9, y: 40.3), startRadius: 0, endRadius: 43.5))
        var anneaux = Path()
        for k in 1...9 {
            let r = 32 - Double(k) * 3.1
            anneaux.addEllipse(in: CGRect(x: 50 - r, y: 48 - r, width: r * 2, height: r * 2))
        }
        l.stroke(anneaux, with: .color(Color(rev: 0xEAF6FF, opacite: 0.22)), lineWidth: 0.42)

        // L'eau.
        var eau = Path()
        eau.move(to: CGPoint(x: 0, y: 74))
        eau.addCurve(to: CGPoint(x: 50, y: 76), control1: CGPoint(x: 20, y: 70), control2: CGPoint(x: 34, y: 72))
        eau.addCurve(to: CGPoint(x: 100, y: 74), control1: CGPoint(x: 66, y: 72), control2: CGPoint(x: 80, y: 70))
        var surface = eau
        eau.addLine(to: CGPoint(x: 100, y: 100))
        eau.addLine(to: CGPoint(x: 0, y: 100))
        eau.closeSubpath()
        l.fill(eau, with: .color(Color(rev: 0x051D3A)))
        var lignes = Path()
        for k in 0..<5 {
            let d = Double(k) * 4.4
            lignes.move(to: CGPoint(x: 0, y: 78 + d))
            lignes.addCurve(to: CGPoint(x: 50, y: 80 + d), control1: CGPoint(x: 20, y: 74 + d), control2: CGPoint(x: 34, y: 76 + d))
            lignes.addCurve(to: CGPoint(x: 100, y: 78 + d), control1: CGPoint(x: 66, y: 76 + d), control2: CGPoint(x: 80, y: 74 + d))
        }
        l.stroke(surface, with: .color(Color(rev: 0xBFE6FF, opacite: 0.6)), lineWidth: 0.8)
        surface = lignes
        l.stroke(surface, with: .color(Color(rev: 0x9CC7EA, opacite: 0.28)), lineWidth: 0.5)

        // Le poisson : ombre claire décalée, puis silhouette sombre au liseré clair.
        let poisson = Self.poisson
        l.drawLayer { f in
            f.translateBy(x: 50, y: 46)
            f.rotate(by: .degrees(-28))
            f.scaleBy(x: 0.76, y: 0.46)
            f.translateBy(x: -50, y: -50)
            f.fill(poisson.applying(CGAffineTransform(translationX: 1.6, y: 2.4)),
                   with: .color(Color(rev: 0xEAF6FF, opacite: 0.22)))
            f.fill(poisson, with: .color(Color(rev: 0x03142B)))
            f.stroke(poisson, with: .color(Color(rev: 0xBFE6FF, opacite: 0.7)), lineWidth: 1.4)
            f.fill(Path(ellipseIn: CGRect(x: 70.4, y: 41.4, width: 7.2, height: 7.2)), with: .color(Color(rev: 0xBFE6FF)))
        }
        var bulles = Path()
        bulles.addEllipse(in: CGRect(x: 18.8, y: 67.3, width: 3.4, height: 3.4))
        bulles.addEllipse(in: CGRect(x: 15.3, y: 63.8, width: 2.4, height: 2.4))
        bulles.addEllipse(in: CGRect(x: 34.8, y: 67.3, width: 2.4, height: 2.4))
        l.fill(bulles, with: .color(Color(rev: 0xBFE6FF, opacite: 0.8)))
    }

    /// La silhouette du poisson du logo (repère 0 à 100), recopiée de `poissonPath` dans `assets.js`.
    static let poisson: Path = {
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
    }()
}

/// Le dos de la carte : deux moitiés qui s'écartent sur une ligne de lumière, lueur de bord pendant la tension.
/// Mêmes cadre et taille que le recto (`CarteCadre`).
struct DosCarteGravee: View {
    let niveau: NiveauRevelation
    let etat: EtatRevelation

    private static var rayon: CGFloat { Rayon.l + 2 }

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: Self.rayon, style: .continuous)
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let em = w / 100
            let ecart = CGFloat(etat.ecart) * em
            ZStack {
                LigneDeLumiere(teinte: niveau.teinte)
                    .frame(width: ecart + 0.5 * em, height: h)
                    .scaleEffect(x: 1, y: CGFloat(etat.hauteurLigne))
                    .opacity(etat.ligne)
                ArtDosCarte()
                    .frame(width: w, height: h)
                    .mask(alignment: .leading) { Rectangle().frame(width: w / 2) }
                    .offset(x: -ecart / 2)
                ArtDosCarte()
                    .frame(width: w, height: h)
                    .mask(alignment: .trailing) { Rectangle().frame(width: w / 2) }
                    .offset(x: ecart / 2)
                LinearGradient(colors: [niveau.teinte.opacity(0), niveau.teinte.opacity(0.5), niveau.teinte.opacity(0)],
                               startPoint: .leading, endPoint: .trailing)
                    .frame(width: 16 * em, height: h)
                    .opacity(etat.fente)
                forme
                    .strokeBorder(niveau.lueur.opacity(etat.lueurBord * 0.9), lineWidth: (2 + etat.lueurBord * 5) * em)
                    .blur(radius: (1.5 + etat.lueurBord * 3) * em)
                Color.black.opacity(etat.ombreFace * 0.8)
            }
            .frame(width: w, height: h)
        }
        .clipShape(forme)
        .shadow(color: Palette.encre.opacity(0.35), radius: 14, y: 8)
        .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
    }
}

/// La ligne de lumière du milieu : claire au centre, teintée de la rareté sur les bords.
struct LigneDeLumiere: View {
    let teinte: Color

    var body: some View {
        LinearGradient(stops: [
            .init(color: teinte.opacity(0), location: 0),
            .init(color: teinte.opacity(0.95), location: 0.22),
            .init(color: .white, location: 0.5),
            .init(color: teinte.opacity(0.95), location: 0.78),
            .init(color: teinte.opacity(0), location: 1)
        ], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Éclats sur le recto

/// L'éclat qui balaie le recto à l'arrivée, et (légendaire) le balayage lent sur le bord.
struct EclatsSurRecto: View {
    let niveau: NiveauRevelation
    let etat: EtatRevelation
    let t: Double
    let chrono: ChronoRevelation
    let anime: Bool

    var body: some View {
        let forme = RoundedRectangle(cornerRadius: Rayon.l + 2, style: .continuous)
        ZStack {
            if anime && etat.eclat > 0.005 {
                LinearGradient(stops: bandeau(centre: CourbesRevelation.lerp(1.2, -0.2, CourbesRevelation.eIO(etat.progressionEclat)),
                                              largeur: 0.18, couleur: .white),
                               startPoint: UnitPoint(x: 0, y: 0.2), endPoint: UnitPoint(x: 1, y: 0.8))
                    .opacity(etat.eclat)
                    .blendMode(.plusLighter)
            }
            if anime && niveau == .legendaire && t >= chrono.croisement {
                balayageDeBord(forme)
            }
        }
        .clipShape(forme)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func balayageDeBord(_ forme: RoundedRectangle) -> some View {
        let reste = (t - (chrono.croisement + 260)) / 1600
        let sp = reste >= 0 ? reste.truncatingRemainder(dividingBy: 3.4) : -1
        let intensite: Double = (sp >= 0 && sp < 1) ? sin(Double.pi * sp) : 0
        if intensite > 0.01 {
            let centre = CourbesRevelation.lerp(0.86, 0.14, CourbesRevelation.eIO(sp))
            forme
                .strokeBorder(
                    LinearGradient(stops: bandeau(centre: centre, largeur: 0.2, couleur: Color(rev: 0xFFE7A6)),
                                   startPoint: .leading, endPoint: .trailing),
                    lineWidth: 5)
                .opacity(intensite)
                .blendMode(.plusLighter)
        }
    }

    /// Un bandeau de lumière centré en `centre` (0 à 1), aux emplacements bornés et dans l'ordre.
    private func bandeau(centre: Double, largeur: Double, couleur: Color) -> [Gradient.Stop] {
        func borne(_ x: Double) -> CGFloat { CGFloat(min(1, max(0, x))) }
        let g = borne(centre - largeur)
        let m = max(g, borne(centre))
        let d = max(m, borne(centre + largeur))
        return [
            .init(color: couleur.opacity(0), location: 0),
            .init(color: couleur.opacity(0), location: g),
            .init(color: couleur.opacity(0.9), location: m),
            .init(color: couleur.opacity(0), location: d),
            .init(color: couleur.opacity(0), location: 1)
        ]
    }
}

// MARK: - Fond et avant-scène (Canvas)

/// Une grande lueur douce (un disque dégradé).
private func lueurDouce(_ c: inout GraphicsContext, rgb: (Double, Double, Double), x: CGFloat, y: CGFloat, rayon: CGFloat, alpha: Double) {
    guard alpha > 0.003, rayon > 0.5 else { return }
    let couleur = Color(.sRGB, red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255, opacity: 1)
    let g = Gradient(stops: [
        .init(color: couleur.opacity(alpha), location: 0),
        .init(color: couleur.opacity(alpha * 0.35), location: 0.5),
        .init(color: couleur.opacity(0), location: 1)
    ])
    c.fill(Path(ellipseIn: CGRect(x: x - rayon, y: y - rayon, width: rayon * 2, height: rayon * 2)),
           with: .radialGradient(g, center: CGPoint(x: x, y: y), startRadius: 0, endRadius: rayon))
}

/// Une gerbe de rayons qui tourne autour de la carte.
private func gerbeDeRayons(_ c: inout GraphicsContext, centre: CGPoint, rotation: Double, longueur: CGFloat, intensite: Double,
                           rgb: (Double, Double, Double), nombre: Int) {
    guard intensite > 0.003 else { return }
    let couleur = Color(.sRGB, red: rgb.0 / 255, green: rgb.1 / 255, blue: rgb.2 / 255, opacity: 1)
    c.drawLayer { l in
        l.blendMode = .plusLighter
        for i in 0..<nombre {
            let a: Double = rotation + Double(i) * Double.pi * 2 / Double(nombre)
            let base: Double = i % 2 == 1 ? 0.05 : 0.085
            let w: Double = base * (0.7 + 0.3 * sin(rotation * 3 + Double(i)))
            let facteur: CGFloat = i % 3 == 0 ? 1 : (i % 3 == 1 ? 0.78 : 0.6)
            let long = longueur * facteur
            var triangle = Path()
            triangle.move(to: .zero)
            triangle.addLine(to: CGPoint(x: long, y: -long * CGFloat(w)))
            triangle.addLine(to: CGPoint(x: long, y: long * CGFloat(w)))
            triangle.closeSubpath()
            l.drawLayer { r in
                r.translateBy(x: centre.x, y: centre.y)
                r.rotate(by: .radians(a))
                let g = Gradient(stops: [
                    .init(color: couleur.opacity(0.55 * intensite), location: 0),
                    .init(color: couleur.opacity(0.2 * intensite), location: 0.55),
                    .init(color: couleur.opacity(0), location: 1)
                ])
                r.fill(triangle, with: .linearGradient(g, startPoint: .zero, endPoint: CGPoint(x: long, y: 0)))
            }
        }
    }
}

/// Derrière la carte : poussière d'eau, ombre au sol, rayons et lueurs (rare et légendaire).
struct FondRevelation: View {
    let niveau: NiveauRevelation
    let etat: EtatRevelation
    let t: Double
    /// Centre et taille de la carte, dans le repère de ce calque.
    let centre: CGPoint
    let tailleCarte: CGSize
    let echelle: CGFloat
    let particules: Bool

    var body: some View {
        Canvas { contexte, taille in
            var c = contexte
            let cw = tailleCarte.width
            let ch = tailleCarte.height

            // Poussière d'eau qui monte doucement.
            if particules {
                var alea = AleaRevelation(91)
                for _ in 0..<24 {
                    let px = alea.suivant(), py = alea.suivant(), pr = 0.5 + alea.suivant() * 1.3
                    let pa = 0.15 + alea.suivant() * 0.35, pph = alea.suivant() * 6.28, psp = 0.3 + alea.suivant()
                    let scintille = 0.5 + 0.5 * sin(t / 1000 * psp * 2 + pph)
                    let derive = CGFloat(sin(t / 4000 + pph)) * 6 * echelle
                    let x: CGFloat = CGFloat(px) * taille.width + derive
                    let montee = CGFloat(t / 1000 * psp) * 6 * echelle
                    let brut: CGFloat = CGFloat(py) * taille.height - montee
                    let y = brut.truncatingRemainder(dividingBy: taille.height)
                    let yy: CGFloat = y < 0 ? y + taille.height : y
                    let r: CGFloat = CGFloat(pr) * echelle
                    c.fill(Path(ellipseIn: CGRect(x: x - r, y: yy - r, width: r * 2, height: r * 2)),
                           with: .color(Color(rev: 0xC7DFF3, opacite: pa * scintille)))
                }
            }

            // Ombre au sol.
            let largeurSol = cw * 1.05 * CGFloat(etat.echelleSol)
            let hautSol = cw * 0.26 * CGFloat(etat.echelleSol)
            let solCentre = CGPoint(x: centre.x, y: centre.y + ch / 2 + cw * 0.11 + cw * 0.13)
            let sol = Gradient(colors: [Color(rev: 0x020916, opacite: 0.62), Color(rev: 0x020916, opacite: 0)])
            c.drawLayer { l in
                l.opacity = max(0, etat.opaciteSol)
                l.translateBy(x: solCentre.x, y: solCentre.y)
                l.scaleBy(x: 1, y: hautSol / max(largeurSol, 1))
                l.fill(Path(ellipseIn: CGRect(x: -largeurSol / 2, y: -largeurSol / 2, width: largeurSol, height: largeurSol)),
                       with: .radialGradient(sol, center: .zero, startRadius: 0, endRadius: largeurSol / 2))
            }

            guard particules else { return }
            if niveau == .rare {
                let rot = t / 5200 + 0.3
                gerbeDeRayons(&c, centre: centre, rotation: rot, longueur: ch * CGFloat(etat.rayonsLongueur),
                              intensite: etat.rayons, rgb: (160, 140, 255), nombre: 14)
                lueurDouce(&c, rgb: (124, 107, 255), x: centre.x, y: centre.y,
                           rayon: cw * CGFloat(0.9 + etat.burst * 0.5), alpha: CourbesRevelation.c01(etat.rayons * 0.55))
            }
            if niveau == .legendaire {
                lueurDouce(&c, rgb: (240, 184, 66), x: centre.x, y: centre.y,
                           rayon: cw * CGFloat(0.95 + etat.burst * 0.6), alpha: CourbesRevelation.c01(etat.aura * 0.5))
                if etat.tension > 0 {
                    gerbeDeRayons(&c, centre: centre, rotation: t / 7000, longueur: ch * 0.8,
                                  intensite: etat.rayons, rgb: (255, 220, 130), nombre: 10)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Devant la carte : éclat doré, ondes de choc et braises qui montent (légendaire seulement pour les deux derniers).
struct AvantRevelation: View {
    let niveau: NiveauRevelation
    let etat: EtatRevelation
    let t: Double
    let chrono: ChronoRevelation
    let centre: CGPoint
    let tailleCarte: CGSize
    let echelle: CGFloat
    let particules: Bool

    var body: some View {
        Canvas { contexte, taille in
            var c = contexte
            let cw = tailleCarte.width
            let ch = tailleCarte.height

            // Éclat de l'arrivée (rare : violet ; légendaire : or).
            if etat.flash > 0.004 && niveau != .commun && niveau != .peuCommun {
                let leg = niveau == .legendaire
                let g: Gradient
                if leg {
                    let arrets: [Gradient.Stop] = [
                        .init(color: Color(rev: 0xFFF8DE, opacite: 1), location: 0),
                        .init(color: Color(rev: 0xFFD678, opacite: 0.78), location: 0.24),
                        .init(color: Color(rev: 0xF0B842, opacite: 0.28), location: 0.52),
                        .init(color: Color(rev: 0xF0B842, opacite: 0), location: 0.78)
                    ]
                    g = Gradient(stops: arrets)
                } else {
                    let arrets: [Gradient.Stop] = [
                        .init(color: Color(rev: 0xECE6FF, opacite: 0.9), location: 0),
                        .init(color: Color(rev: 0x9682FF, opacite: 0.45), location: 0.3),
                        .init(color: Color(rev: 0x7C6BFF, opacite: 0), location: 0.7)
                    ]
                    g = Gradient(stops: arrets)
                }
                let rayon = max(taille.width, taille.height) * 0.9
                c.drawLayer { l in
                    l.opacity = min(1, etat.flash)
                    l.fill(Path(CGRect(origin: .zero, size: taille)),
                           with: .radialGradient(g, center: centre, startRadius: 0, endRadius: rayon))
                }
            }

            guard particules, niveau == .legendaire, t >= chrono.croisement else { return }
            c.drawLayer { l in
                l.blendMode = .plusLighter
                // Deux ondes de choc dorées.
                for w in 0..<2 {
                    let wd = Double(w)
                    let p = CourbesRevelation.prog(t, chrono.croisement + wd * 130, chrono.croisement + wd * 130 + 1000)
                    guard p > 0 && p < 1 else { continue }
                    let rr = CGFloat(CourbesRevelation.lerp(Double(cw * 0.35), Double(max(taille.width, taille.height) * 0.85),
                                                            CourbesRevelation.eO3(p)))
                    let vif = Color(rev: 0xFFD678, opacite: (1 - p) * (w == 1 ? 0.5 : 0.95))
                    let base: CGFloat = w == 1 ? 5 : 9
                    let epais: CGFloat = max(0.6, base * echelle * CGFloat(1 - p))
                    l.stroke(Path(ellipseIn: CGRect(x: centre.x - rr, y: centre.y - rr * 1.04, width: rr * 2, height: rr * 2.08)),
                             with: .color(vif), lineWidth: epais)
                    let rr2 = rr * 0.985
                    let fin = Color(rev: 0xFFF4CD, opacite: (1 - p) * 0.35)
                    l.stroke(Path(ellipseIn: CGRect(x: centre.x - rr2, y: centre.y - rr2 * 1.04, width: rr2 * 2, height: rr2 * 2.08)),
                             with: .color(fin), lineWidth: max(0.4, 2.4 * echelle * CGFloat(1 - p)))
                }
                // Braises qui montent.
                var alea = AleaRevelation(91)
                for _ in 0..<30 {
                    let mx0 = (alea.suivant() - 0.5) * 1.2
                    let my0 = 0.1 + alea.suivant() * 0.5
                    let v = 28 + alea.suivant() * 70
                    let sw = 6 + alea.suivant() * 14
                    let f = 0.7 + alea.suivant() * 1.4
                    let r = 1.4 + alea.suivant() * 3.4
                    let vie = 2300 + alea.suivant() * 2400
                    let b = alea.suivant() * 1500
                    let ph = alea.suivant() * 6.28
                    let age = t - chrono.croisement - b * 0.5
                    if age < 0 { continue }
                    let reste = age.truncatingRemainder(dividingBy: vie)
                    let fr = reste / vie
                    let al: Double = sin(Double.pi * fr) * (0.55 + 0.45 * sin(age / 130 * f + ph))
                    let balance = CGFloat(sin(age / 1000 * f * 2 + ph) * sw) * echelle
                    let x: CGFloat = centre.x + CGFloat(mx0) * cw * 0.6 + balance
                    let hauteur = CGFloat(reste / 1000 * v * 1.7) * echelle
                    let y: CGFloat = centre.y + ch * CGFloat(my0 - 0.15) - hauteur
                    var calque = l
                    lueurDouce(&calque, rgb: (255, 222, 140), x: x, y: y, rayon: CGFloat(r * 3.4) * echelle,
                               alpha: CourbesRevelation.c01(al))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
