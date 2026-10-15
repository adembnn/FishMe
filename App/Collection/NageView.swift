import SwiftUI

/// L'illustration du poisson qui nage dans l'eau de sa carte : une onde (shader Metal) et quelques bulles.
/// Seulement sur la carte ouverte en plein écran. Immobile avec « Réduire les animations ».
struct NageView: View {
    let nomImage: String
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    var body: some View {
        GeometryReader { geo in
            if reduireAnimations {
                poisson
            } else {
                TimelineView(.animation) { contexte in
                    let t = contexte.date.timeIntervalSinceReferenceDate
                    ZStack {
                        BullesView(temps: t, taille: geo.size)
                        poisson
                            .distortionEffect(
                                ShaderLibrary.ondeNage(.float(t), .float(geo.size.width), .float(6)),
                                maxSampleOffset: CGSize(width: 0, height: 8)
                            )
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private var poisson: some View {
        Image(nomImage)
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BullesView: View {
    let temps: Double
    let taille: CGSize

    var body: some View {
        Canvas { contexte, size in
            for i in 0..<6 {
                let graine = Double(i) * 1.7
                let vitesse = 0.08 + 0.02 * Double(i % 3)
                let avance = (temps * vitesse + graine).truncatingRemainder(dividingBy: 1)
                let x = size.width * (0.12 + 0.15 * Double(i)) + sin(temps + graine) * 4
                let y = size.height * (1 - avance)
                let r = 2.0 + Double(i % 3) * 1.5
                let cercle = Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
                contexte.stroke(cercle, with: .color(.white.opacity(0.7)), lineWidth: 1.2)
            }
        }
        .allowsHitTesting(false)
    }
}
