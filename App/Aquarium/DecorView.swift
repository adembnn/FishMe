import SwiftUI

/// Le fond de l'aquarium, dessiné en code (aucune image à fournir) : eau, rayons de lumière, sol, plantes, bulles,
/// ondes de la vitre et rations. `anime` faux (« Réduire les animations ») : rien ne bouge, ni onde ni bulles.
struct DecorView: View {
    let decor: Decor
    let temps: Double
    let anime: Bool
    let ondes: [OndeVitre]
    let rations: [RationTombee]

    var body: some View {
        Canvas { contexte, taille in
            let palette = PaletteDecor.pour(decor)
            dessinerEau(&contexte, taille, palette)
            dessinerRayons(&contexte, taille, palette)
            dessinerDecoupe(&contexte, taille, palette)
            dessinerSol(&contexte, taille, palette)
            dessinerPlantes(&contexte, taille, palette)
            if anime {
                dessinerBulles(&contexte, taille)
                dessinerOndes(&contexte, taille)
            }
            dessinerRations(&contexte, taille)
        }
        .accessibilityHidden(true)
    }

    private func dessinerEau(_ c: inout GraphicsContext, _ taille: CGSize, _ p: PaletteDecor) {
        let rect = CGRect(origin: .zero, size: taille)
        c.fill(Path(rect), with: .linearGradient(Gradient(colors: [p.haut, p.bas]), startPoint: .zero,
                                                 endPoint: CGPoint(x: 0, y: taille.height)))
    }

    private func dessinerRayons(_ c: inout GraphicsContext, _ taille: CGSize, _ p: PaletteDecor) {
        guard p.rayons > 0 else { return }
        for i in 0..<4 {
            let balancement = anime ? sin(temps * 0.25 + Double(i) * 1.7) * 14 : 0
            let x = taille.width * (0.12 + 0.26 * Double(i)) + balancement
            var chemin = Path()
            chemin.move(to: CGPoint(x: x, y: 0))
            chemin.addLine(to: CGPoint(x: x + 46, y: 0))
            chemin.addLine(to: CGPoint(x: x + 46 + taille.height * 0.28, y: taille.height * 0.8))
            chemin.addLine(to: CGPoint(x: x - 40 + taille.height * 0.28, y: taille.height * 0.8))
            chemin.closeSubpath()
            c.fill(chemin, with: .linearGradient(Gradient(colors: [.white.opacity(p.rayons), .white.opacity(0)]),
                                                 startPoint: CGPoint(x: x, y: 0),
                                                 endPoint: CGPoint(x: x, y: taille.height * 0.8)))
        }
    }

    /// Ce qui est propre à chaque décor : nénuphars, stalactites, lune.
    private func dessinerDecoupe(_ c: inout GraphicsContext, _ taille: CGSize, _ p: PaletteDecor) {
        switch decor {
        case .etang:
            for i in 0..<5 {
                let x = taille.width * (0.1 + 0.2 * Double(i))
                let derive = anime ? sin(temps * 0.4 + Double(i)) * 5 : 0
                let rect = CGRect(x: x + derive - 34, y: taille.height * 0.03 + Double(i % 2) * 10, width: 68, height: 18)
                c.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.24, green: 0.55, blue: 0.28).opacity(0.85)))
            }
        case .grotte:
            for i in 0..<6 {
                let x = taille.width * (0.04 + 0.19 * Double(i))
                let longueur = 40 + Double((i * 37) % 70)
                var pic = Path()
                pic.move(to: CGPoint(x: x - 24, y: 0))
                pic.addLine(to: CGPoint(x: x + 24, y: 0))
                pic.addLine(to: CGPoint(x: x, y: longueur))
                pic.closeSubpath()
                c.fill(pic, with: .color(Color(red: 0.07, green: 0.09, blue: 0.16)))
            }
            for i in 0..<3 {
                let x = taille.width * (0.2 + 0.3 * Double(i))
                let lueur = anime ? 0.55 + 0.25 * sin(temps * 1.1 + Double(i) * 2) : 0.65
                let rect = CGRect(x: x - 22, y: taille.height * 0.8 - 8, width: 44, height: 44)
                c.fill(Path(ellipseIn: rect), with: .radialGradient(
                    Gradient(colors: [Color(red: 0.55, green: 0.9, blue: 1).opacity(lueur), .clear]),
                    center: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endRadius: 24))
            }
        case .nocturne:
            let lune = CGRect(x: taille.width * 0.72, y: taille.height * 0.06, width: 90, height: 90)
            c.fill(Path(ellipseIn: lune), with: .radialGradient(
                Gradient(colors: [Color.white.opacity(0.85), Color(red: 0.7, green: 0.8, blue: 1).opacity(0.25), .clear]),
                center: CGPoint(x: lune.midX, y: lune.midY), startRadius: 4, endRadius: 56))
            for i in 0..<14 {
                let x = Double((i * 97) % 100) / 100 * taille.width
                let y = Double((i * 53) % 40) / 100 * taille.height * 0.6
                let eclat = anime ? 0.5 + 0.4 * sin(temps * 1.3 + Double(i)) : 0.7
                c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2.4, height: 2.4)), with: .color(.white.opacity(eclat)))
            }
        case .torrent:
            for i in 0..<9 {
                let x = Double((i * 61) % 100) / 100 * taille.width
                let decalage = anime ? (temps * 60 + Double(i) * 70).truncatingRemainder(dividingBy: taille.height) : Double(i) * 70
                var trait = Path()
                trait.move(to: CGPoint(x: x, y: decalage))
                trait.addLine(to: CGPoint(x: x + 4, y: decalage + 26))
                c.stroke(trait, with: .color(.white.opacity(0.28)), lineWidth: 1.6)
            }
        case .bassin, .riviere:
            break
        }
    }

    private func dessinerSol(_ c: inout GraphicsContext, _ taille: CGSize, _ p: PaletteDecor) {
        let sol = CGRect(x: -40, y: taille.height * 0.9, width: taille.width + 80, height: taille.height * 0.2)
        c.fill(Path(ellipseIn: sol), with: .linearGradient(Gradient(colors: [p.sol, p.sol.opacity(0.7)]),
                                                           startPoint: CGPoint(x: 0, y: sol.minY), endPoint: CGPoint(x: 0, y: sol.maxY)))
        if decor == .riviere || decor == .torrent || decor == .grotte {
            for i in 0..<7 {
                let x = taille.width * (0.04 + 0.15 * Double(i))
                let rayon = 9 + Double((i * 13) % 14)
                let pierre = CGRect(x: x, y: taille.height * 0.93 - rayon * 0.3, width: rayon * 2.2, height: rayon * 1.3)
                c.fill(Path(ellipseIn: pierre), with: .color(p.sol.opacity(0.95)))
                c.stroke(Path(ellipseIn: pierre), with: .color(.black.opacity(0.12)), lineWidth: 1)
            }
        }
    }

    private func dessinerPlantes(_ c: inout GraphicsContext, _ taille: CGSize, _ p: PaletteDecor) {
        guard let couleur = p.plantes else { return }
        let nombre = 9
        for i in 0..<nombre {
            let x = taille.width * (0.03 + 0.11 * Double(i))
            let hauteur = taille.height * (0.12 + 0.08 * Double((i * 5) % 4))
            let base = CGPoint(x: x, y: taille.height * 0.94)
            var tige = Path()
            tige.move(to: base)
            let balancement = anime ? sin(temps * 0.9 + Double(i) * 0.8) * 10 : 0
            tige.addCurve(to: CGPoint(x: x + balancement, y: base.y - hauteur),
                          control1: CGPoint(x: x - 12 + balancement * 0.3, y: base.y - hauteur * 0.35),
                          control2: CGPoint(x: x + 14 + balancement * 0.7, y: base.y - hauteur * 0.7))
            c.stroke(tige, with: .color(couleur.opacity(0.9)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }

    private func dessinerBulles(_ c: inout GraphicsContext, _ taille: CGSize) {
        for i in 0..<9 {
            let graine = Double(i) * 1.7
            let vitesse = 0.05 + 0.02 * Double(i % 3)
            let avance = (temps * vitesse + graine).truncatingRemainder(dividingBy: 1)
            let x = taille.width * (0.08 + 0.1 * Double(i)) + sin(temps * 0.8 + graine) * 5
            let y = taille.height * (1 - avance)
            let r = 2.0 + Double(i % 3) * 1.6
            let cercle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
            c.stroke(cercle, with: .color(.white.opacity(0.55)), lineWidth: 1.2)
        }
    }

    private func dessinerOndes(_ c: inout GraphicsContext, _ taille: CGSize) {
        for onde in ondes {
            let dt = temps - onde.debut
            guard dt >= 0, dt < OndeVitre.duree else { continue }
            let progres = dt / OndeVitre.duree
            let centre = CGPoint(x: onde.centre.x * taille.width, y: onde.centre.y * taille.height)
            for anneau in 0..<3 {
                let retard = Double(anneau) * 0.12
                let p = max(progres - retard, 0)
                guard p > 0 else { continue }
                let rayon = 14 + p * 170
                let cercle = Path(ellipseIn: CGRect(x: centre.x - rayon, y: centre.y - rayon, width: rayon * 2, height: rayon * 2))
                c.stroke(cercle, with: .color(.white.opacity((1 - p) * 0.7)), lineWidth: 2.4 - Double(anneau) * 0.6)
            }
        }
    }

    private func dessinerRations(_ c: inout GraphicsContext, _ taille: CGSize) {
        for ration in rations {
            let dt = temps - ration.debut
            guard dt >= 0, dt < Nage.dureeRation() else { continue }
            let y = Nage.hauteurRation(dt: dt) * taille.height
            for k in 0..<5 {
                let dx = Double(k - 2) * 6
                let dy = Double((k * 7) % 5) * 3
                let point = CGRect(x: ration.x * taille.width + dx - 2.5, y: y + dy - 2.5, width: 5, height: 5)
                c.fill(Path(ellipseIn: point), with: .color(Color(red: 0.95, green: 0.72, blue: 0.3)))
            }
        }
    }
}

struct PaletteDecor {
    var haut: Color
    var bas: Color
    var sol: Color
    var plantes: Color?
    var rayons: Double

    static func pour(_ decor: Decor) -> PaletteDecor {
        switch decor {
        case .bassin:
            return PaletteDecor(haut: Color(red: 0.55, green: 0.83, blue: 0.93), bas: Color(red: 0.08, green: 0.36, blue: 0.54),
                                sol: Color(red: 0.82, green: 0.74, blue: 0.55), plantes: Color(red: 0.2, green: 0.6, blue: 0.4), rayons: 0.22)
        case .riviere:
            return PaletteDecor(haut: Color(red: 0.62, green: 0.86, blue: 0.78), bas: Color(red: 0.07, green: 0.38, blue: 0.36),
                                sol: Color(red: 0.55, green: 0.55, blue: 0.5), plantes: Color(red: 0.3, green: 0.62, blue: 0.3), rayons: 0.26)
        case .etang:
            return PaletteDecor(haut: Color(red: 0.6, green: 0.8, blue: 0.6), bas: Color(red: 0.09, green: 0.28, blue: 0.22),
                                sol: Color(red: 0.4, green: 0.34, blue: 0.22), plantes: Color(red: 0.15, green: 0.5, blue: 0.3), rayons: 0.18)
        case .grotte:
            return PaletteDecor(haut: Color(red: 0.2, green: 0.28, blue: 0.46), bas: Color(red: 0.03, green: 0.04, blue: 0.11),
                                sol: Color(red: 0.2, green: 0.2, blue: 0.27), plantes: nil, rayons: 0.08)
        case .torrent:
            return PaletteDecor(haut: Color(red: 0.8, green: 0.94, blue: 0.99), bas: Color(red: 0.12, green: 0.45, blue: 0.62),
                                sol: Color(red: 0.5, green: 0.52, blue: 0.5), plantes: nil, rayons: 0.34)
        case .nocturne:
            return PaletteDecor(haut: Color(red: 0.08, green: 0.14, blue: 0.34), bas: Color(red: 0.01, green: 0.02, blue: 0.09),
                                sol: Color(red: 0.16, green: 0.18, blue: 0.26), plantes: Color(red: 0.12, green: 0.4, blue: 0.4), rayons: 0.1)
        }
    }
}
