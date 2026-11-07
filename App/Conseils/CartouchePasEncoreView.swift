import SwiftUI

/// Le contour du poisson de la carte à débloquer (dessin de référence : viewBox 138 × 200, poisson posé à (7, 46) à l'échelle 0,62).
/// Un dessin générique, pas l'image de l'espèce : un contour en pointillés ne se tire pas d'une image.
nonisolated struct PoissonContour: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // Corps
        p.move(to: CGPoint(x: 20, y: 40))
        p.addCurve(to: CGPoint(x: 140, y: 35), control1: CGPoint(x: 38, y: 22), control2: CGPoint(x: 92, y: 16))
        p.addLine(to: CGPoint(x: 180, y: 21))
        p.addQuadCurve(to: CGPoint(x: 180, y: 59), control: CGPoint(x: 170, y: 40))
        p.addLine(to: CGPoint(x: 140, y: 45))
        p.addCurve(to: CGPoint(x: 20, y: 40), control1: CGPoint(x: 92, y: 64), control2: CGPoint(x: 38, y: 58))
        p.closeSubpath()
        // Dorsale
        p.move(to: CGPoint(x: 72, y: 24))
        p.addQuadCurve(to: CGPoint(x: 110, y: 27), control: CGPoint(x: 88, y: 8))
        p.closeSubpath()
        // Ventrale
        p.move(to: CGPoint(x: 82, y: 56))
        p.addQuadCurve(to: CGPoint(x: 108, y: 52), control: CGPoint(x: 94, y: 70))
        p.closeSubpath()
        let echelle = rect.width / 138
        let t = CGAffineTransform(translationX: rect.minX + 7 * echelle, y: rect.minY + 46 * echelle)
            .scaledBy(x: 0.62 * echelle, y: 0.62 * echelle)
        return p.applying(t)
    }
}

/// Deux vaguelettes au bas de la carte (dessin de référence).
private nonisolated struct Vaguelettes: Shape {
    var y: CGFloat
    func path(in rect: CGRect) -> Path {
        let e = rect.width / 138
        var p = Path()
        let y0 = rect.minY + y * e
        p.move(to: CGPoint(x: rect.minX + 8 * e, y: y0))
        for i in 0..<6 {
            let x = rect.minX + (8 + 16 * CGFloat(i)) * e
            p.addQuadCurve(to: CGPoint(x: x + 16 * e, y: y0),
                           control: CGPoint(x: x + 8 * e, y: y0 + (i.isMultiple(of: 2) ? -10 : 10) * e))
        }
        return p
    }
}

/// « Cartouche nuit » (choisie par Titouan, proposition C) : la carte « Pas encore de carte ».
/// Fond de nuit dans les deux modes, contour de poisson en pointillés, cadenas en coin, pastille « À débloquer ».
/// Format de la carte à collectionner (69:100). Aux tailles de texte d'accessibilité, les mots passent sous la carte
/// (une carte de ratio fixe ne peut pas les contenir). Code écrit sans Mac. // ⚠ à vérifier
struct CartouchePasEncoreView: View {
    let espece: String
    /// Le mot de rareté, seulement s'il est connu (jamais inventé).
    var rarete: String?
    var largeur: CGFloat = 176

    @Environment(\.dynamicTypeSize) private var tailleTexte

    /// Couleurs du dessin de référence : la carte reste « nuit » en clair comme en sombre.
    private let fondNuit = Palette.nuit
    private let trait = Color(red: 0x9C / 255, green: 0xC7 / 255, blue: 0xEA / 255)   // Palette.eau (clair)
    private let texte = Color(red: 0xE7 / 255, green: 0xED / 255, blue: 0xF3 / 255)   // Palette.encre (sombre)

    /// Ce que dit VoiceOver pour toute la carte.
    static func libelleVoiceOver(espece: String) -> String { "Carte à débloquer : \(espece), verrouillée" }

    private var hauteur: CGFloat { largeur / Gabarit.rapportCarte }
    private var echelle: CGFloat { largeur / 138 }
    private var motsDehors: Bool { tailleTexte.isAccessibilitySize }

    var body: some View {
        VStack(spacing: Espace.m) {
            carte
            if motsDehors { mots(sombre: false) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.libelleVoiceOver(espece: espece))
        .accessibilityIdentifier("tunnel-carte-a-debloquer")
    }

    private var carte: some View {
        let coin = largeur * Gabarit.coinCarte
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: coin, style: .continuous).fill(fondNuit)
            RoundedRectangle(cornerRadius: coin, style: .continuous)
                .strokeBorder(trait.opacity(0.5), lineWidth: 1.5 * echelle)
            Vaguelettes(y: 178).stroke(trait.opacity(0.3), lineWidth: echelle)
            Vaguelettes(y: 188).stroke(trait.opacity(0.2), lineWidth: echelle)
            PoissonContour()
                .stroke(trait, style: StrokeStyle(lineWidth: 2 * echelle, lineJoin: .round,
                                                  dash: [3.1 * echelle, 3.1 * echelle]))
            // Cadenas en coin haut droit : rond de 28 pt-dessin, centré en (111, 27).
            ZStack {
                Circle().strokeBorder(trait, lineWidth: 1.5 * echelle)
                Image(systemName: "lock.fill")
                    .font(.system(size: 14 * echelle, weight: .bold))
                    .foregroundStyle(trait)
            }
            .frame(width: 28 * echelle, height: 28 * echelle)
            .offset(x: 97 * echelle, y: 13 * echelle)
            if !motsDehors { mots(sombre: true).frame(maxWidth: .infinity).padding(.top, 110 * echelle) }
        }
        .frame(width: largeur, height: hauteur)
        .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
    }

    /// Titre, pastille « À débloquer » et, si connue, la rareté.
    private func mots(sombre: Bool) -> some View {
        VStack(spacing: Espace.s) {
            Text("Pas encore de carte")
                .font(Police.legende)
                .foregroundStyle(sombre ? texte : Palette.encre)
                .multilineTextAlignment(.center)
            Text("À débloquer")
                .font(Police.legende)
                .foregroundStyle(sombre ? trait : Palette.marine)
                .padding(.horizontal, Espace.m)
                .frame(minHeight: 22 * echelle)
                .overlay(Capsule().strokeBorder(sombre ? trait : Palette.marine, lineWidth: 1.5))
            if let rarete {
                Text(rarete)
                    .font(Police.legende)
                    .foregroundStyle(sombre ? texte : Palette.encreDouce)
            }
        }
        .padding(.horizontal, Espace.s)
    }
}
