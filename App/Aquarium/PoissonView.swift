import SwiftUI
import UIKit

/// Un poisson de l'aquarium : l'illustration de profil de sa carte (ou, à défaut d'illustration, une silhouette),
/// qui ondule en nageant. Rare : un halo. Légendaire : un reflet irisé sur les écailles. Relâché : un petit badge.
struct PoissonView: View {
    let entree: EntreeAquarium
    let largeur: CGFloat
    let temps: Double
    let anime: Bool
    let versLaDroite: Bool

    private var hauteur: CGFloat { largeur / 2.4 }
    private var style: StyleNage { StyleNage.pour(especeId: entree.especeId) }
    private var shaders: Bool { ShadersAquarium.disponibles }

    var body: some View {
        ZStack {
            if entree.estRare { halo }
            corps
                .scaleEffect(x: versLaDroite ? 1 : -1, y: 1)
            if entree.relachee {
                BadgeRelache()
                    .offset(y: hauteur * 0.5 + 12)
            }
        }
        .frame(width: largeur, height: hauteur)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entree.texteVoixOff)
    }

    private var halo: some View {
        let pulsation = anime ? 0.5 + 0.18 * sin(temps * 1.6) : 0.55
        return Ellipse()
            .fill(RadialGradient(colors: [Color(red: 0.55, green: 0.8, blue: 1).opacity(pulsation), .clear],
                                 center: .center, startRadius: 0, endRadius: largeur * 0.62))
            .frame(width: largeur * 1.5, height: hauteur * 2.1)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var corps: some View {
        let base = illustration
        if anime && shaders {
            if entree.estLegendaire {
                base
                    .distortionEffect(onde, maxSampleOffset: CGSize(width: 0, height: 12))
                    .colorEffect(ShadersAquarium.bibliotheque.aquarium_irise(.float(temps), .float2(largeur, hauteur)))
            } else {
                base.distortionEffect(onde, maxSampleOffset: CGSize(width: 0, height: 12))
            }
        } else if entree.estLegendaire {
            // Immobile (ou shaders absents) : un reflet fixe, sans mouvement.
            base.overlay(refletFixe.mask(base))
        } else {
            base
        }
    }

    private var onde: Shader {
        ShadersAquarium.bibliotheque.aquarium_ondeNage(.float(temps), .float(largeur), .float(style.amplitudeOnde),
                                                       .float(style.vitesseOnde))
    }

    private var refletFixe: some View {
        LinearGradient(colors: [Color(red: 1, green: 0.6, blue: 0.85), Color(red: 0.6, green: 0.9, blue: 1),
                                Color(red: 0.9, green: 1, blue: 0.6)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .opacity(0.45)
            .blendMode(.plusLighter)
    }

    @ViewBuilder
    private var illustration: some View {
        if UIImage(named: entree.image) != nil {
            Image(entree.image)
                .resizable()
                .scaledToFit()
                .frame(width: largeur, height: hauteur)
        } else {
            SilhouettePoisson(teinte: Self.teinte(pour: entree.especeId))
                .frame(width: largeur, height: hauteur)
        }
    }

    /// Couleur stable d'une silhouette, tirée de l'identifiant de l'espèce.
    static func teinte(pour especeId: String) -> Color {
        let h = Nage.empreinte(especeId)
        let teinte = Double(h % 360) / 360
        return Color(hue: teinte, saturation: 0.45, brightness: 0.68)
    }
}

/// Repli quand l'illustration de l'espèce n'est pas dans les ressources : une silhouette de profil, tête à droite.
struct SilhouettePoisson: View {
    let teinte: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: w * 0.04, y: h * 0.12))
                    p.addLine(to: CGPoint(x: w * 0.24, y: h * 0.5))
                    p.addLine(to: CGPoint(x: w * 0.04, y: h * 0.88))
                    p.addQuadCurve(to: CGPoint(x: w * 0.1, y: h * 0.5), control: CGPoint(x: w * 0.1, y: h * 0.7))
                    p.addQuadCurve(to: CGPoint(x: w * 0.04, y: h * 0.12), control: CGPoint(x: w * 0.1, y: h * 0.3))
                }
                .fill(teinte.opacity(0.85))
                Ellipse()
                    .fill(LinearGradient(colors: [teinte, teinte.opacity(0.75)], startPoint: .top, endPoint: .bottom))
                    .frame(width: w * 0.78, height: h * 0.8)
                    .position(x: w * 0.6, y: h * 0.5)
                Circle()
                    .fill(.white)
                    .frame(width: h * 0.17, height: h * 0.17)
                    .overlay(Circle().fill(.black).frame(width: h * 0.08, height: h * 0.08))
                    .position(x: w * 0.85, y: h * 0.42)
            }
        }
    }
}

/// « relâché » : petit badge sous le poisson. Le mot est écrit, la couleur ne porte pas seule le sens.
struct BadgeRelache: View {
    var body: some View {
        Label("relâché", systemImage: "arrow.uturn.down")
            .font(.system(.caption2, design: .rounded, weight: .heavy))
            .foregroundStyle(.primary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(.regularMaterial, in: Capsule())
            .fixedSize()
            .accessibilityHidden(true)
    }
}
