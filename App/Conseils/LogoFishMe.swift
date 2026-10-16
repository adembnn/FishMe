import SwiftUI

// Le logo FishMe dessiné en vectoriel (maquettes P01 et P44) : une lune claire, le poisson qui saute, l'eau en bas.
// Les couleurs du logo sont fixes (elles ne changent pas en mode sombre), comme celles de l'icône de l'app.

/// Les mesures du dessin, dans la boîte de 100 × 100 des maquettes (lune de rayon 32 centrée en 50, 40).
private enum DessinFishMe {
    static let nuit = Color(red: 8 / 255, green: 42 / 255, blue: 76 / 255)
    static let abysses = Color(red: 6 / 255, green: 18 / 255, blue: 43 / 255)
    static let lueur = Color(red: 111 / 255, green: 195 / 255, blue: 255 / 255)
    static let luneCentre = Color(red: 244 / 255, green: 251 / 255, blue: 255 / 255)
    static let luneMilieu = Color(red: 191 / 255, green: 230 / 255, blue: 255 / 255)
    static let luneBord = Color(red: 143 / 255, green: 208 / 255, blue: 255 / 255)

    /// Le poisson (tête à droite), dans sa boîte de 100 × 100.
    static func poisson() -> Path {
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

    /// La vague qui coupe le bas de la lune (clippée par la lune).
    static func vague() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 10, y: 64))
        p.addCurve(to: CGPoint(x: 50, y: 67), control1: CGPoint(x: 26, y: 60), control2: CGPoint(x: 38, y: 63))
        p.addCurve(to: CGPoint(x: 90, y: 64), control1: CGPoint(x: 62, y: 63), control2: CGPoint(x: 74, y: 60))
        p.addLine(to: CGPoint(x: 90, y: 80))
        p.addLine(to: CGPoint(x: 10, y: 80))
        p.closeSubpath()
        return p
    }

    /// Lune, poisson et (si `onde`) vague, dans la boîte de 100 × 100 ; le contexte est déjà mis à l'échelle.
    static func scene(_ c: inout GraphicsContext, halo: Bool, onde: Bool) {
        if halo {
            let gradient = Gradient(stops: [
                .init(color: lueur.opacity(0.30), location: 0),
                .init(color: lueur.opacity(0.30), location: 0.62),
                .init(color: lueur.opacity(0), location: 1),
            ])
            let cercle = Path(ellipseIn: CGRect(x: 4, y: -6, width: 92, height: 92))
            c.fill(cercle, with: .radialGradient(gradient, center: CGPoint(x: 50, y: 40), startRadius: 0, endRadius: 46))
        }
        let lune = Path(ellipseIn: CGRect(x: 18, y: 8, width: 64, height: 64))
        let luneDegrade = Gradient(stops: [
            .init(color: luneCentre, location: 0),
            .init(color: luneMilieu, location: 0.8),
            .init(color: luneBord, location: 1),
        ])
        c.fill(lune, with: .radialGradient(luneDegrade, center: CGPoint(x: 46.8, y: 33.6), startRadius: 0, endRadius: 38.4))

        var poisson = c
        poisson.translateBy(x: 50, y: 36)
        poisson.rotate(by: .degrees(-28))
        poisson.scaleBy(x: 0.76, y: 0.46)
        poisson.translateBy(x: -50, y: -50)
        poisson.fill(Self.poisson(), with: .color(nuit))
        poisson.fill(Path(ellipseIn: CGRect(x: 70.4, y: 41.4, width: 7.2, height: 7.2)), with: .color(luneMilieu))

        if onde {
            var clip = c
            clip.clip(to: lune)
            clip.fill(vague(), with: .color(nuit))
        }
    }
}

/// Le logo seul (P44, écran de lancement) : lune avec sa lueur, poisson, vague. Boîte de maquette 120 × 100.
struct MarqueFishMe: View {
    var largeur: CGFloat = 170

    var body: some View {
        Canvas { contexte, taille in
            let echelle = taille.width / 120
            contexte.translateBy(x: 10 * echelle, y: 10 * echelle)
            contexte.scaleBy(x: echelle, y: echelle)
            DessinFishMe.scene(&contexte, halo: true, onde: true)
        }
        .frame(width: largeur, height: largeur * 100 / 120)
        .accessibilityElement()
        .accessibilityLabel("FishMe")
    }
}

/// L'icône de l'app en grand (P01) : carré marine profond à coins arrondis, lune, poisson, eau sombre en bas.
struct IconeFishMe: View {
    var cote: CGFloat = 168

    var body: some View {
        Canvas { contexte, taille in
            let echelle = taille.width / 168
            contexte.scaleBy(x: echelle, y: echelle)
            // Lune de rayon 53,5 centrée à 84 / 80 : 32 unités de dessin × 1,672.
            var dessin = contexte
            dessin.translateBy(x: 84, y: 80)
            dessin.scaleBy(x: 1.672, y: 1.672)
            dessin.translateBy(x: -50, y: -40)
            DessinFishMe.scene(&dessin, halo: false, onde: false)
            var eau = Path()
            eau.move(to: CGPoint(x: 0, y: 124))
            eau.addCurve(to: CGPoint(x: 84, y: 127), control1: CGPoint(x: 40, y: 118), control2: CGPoint(x: 60, y: 121))
            eau.addCurve(to: CGPoint(x: 168, y: 124), control1: CGPoint(x: 110, y: 121), control2: CGPoint(x: 130, y: 118))
            eau.addLine(to: CGPoint(x: 168, y: 168))
            eau.addLine(to: CGPoint(x: 0, y: 168))
            eau.closeSubpath()
            contexte.fill(eau, with: .color(DessinFishMe.abysses))
        }
        .frame(width: cote, height: cote)
        .background {
            RadialGradient(
                colors: [
                    Color(red: 15 / 255, green: 76 / 255, blue: 147 / 255),
                    Color(red: 9 / 255, green: 43 / 255, blue: 120 / 255),
                ],
                center: .center, startRadius: 0, endRadius: cote * 0.7)
        }
        .clipShape(RoundedRectangle(cornerRadius: cote * 38 / 168, style: .continuous))
        .shadow(color: DessinFishMe.nuit.opacity(0.55), radius: 18, y: 14)
        .accessibilityHidden(true)
    }
}

/// P44 (direction B) : le logo seul, centré sur la marine ; « FishMe » en blanc dessous. Aucun autre élément.
/// À brancher dans `RootView.swift` : `ZStack { … }.overlay { if !pret { EcranLancementView().transition(.opacity) } }`
/// puis `pret = true` avec un `withAnimation` dès que l'état de départ est lu. L'écran de lancement système
/// (Info.plist, couleur `FondLancement`) est du ressort de A.
struct EcranLancementView: View {
    var body: some View {
        VStack(spacing: 20) {
            MarqueFishMe(largeur: 170)
            Text("FishMe")
                .font(Police.taille(34, .black))
                .tracking(-0.68)
                .foregroundStyle(.white)
        }
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("FondLancement").ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("FishMe")
    }
}
