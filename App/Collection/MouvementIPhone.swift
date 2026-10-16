import CoreMotion
import Observation
import SwiftUI

/// Inclinaison de l'iPhone, de -1 à 1 sur chaque axe, pour le reflet des cartes rares et légendaires.
/// À démarrer seulement quand la carte est ouverte en plein écran, jamais sur toute la grille.
@MainActor
@Observable
final class MouvementIPhone {
    var inclinaison: CGSize = .zero
    private let gestionnaire = CMMotionManager()

    func demarrer() {
        guard gestionnaire.isDeviceMotionAvailable, !gestionnaire.isDeviceMotionActive else { return }
        gestionnaire.deviceMotionUpdateInterval = 1.0 / 30.0
        gestionnaire.startDeviceMotionUpdates(to: .main) { [weak self] mouvement, _ in
            guard let attitude = mouvement?.attitude else { return }
            let roulis = attitude.roll
            let tangage = attitude.pitch
            Task { @MainActor [weak self] in
                self?.appliquer(roulis: roulis, tangage: tangage)
            }
        }
    }

    func arreter() {
        gestionnaire.stopDeviceMotionUpdates()
    }

    private func appliquer(roulis: Double, tangage: Double) {
        let x = max(-1, min(1, roulis / 0.6))
        let y = max(-1, min(1, (tangage - 0.8) / 0.6))
        inclinaison = CGSize(width: x, height: y)
    }
}

/// Un dégradé linéaire à l'angle CSS (0° vers le haut, 90° vers la droite), sur toute la boîte : même géométrie que `linear-gradient(125deg, …)` de la maquette.
struct DegradeAngle: View {
    let angle: Double
    let arrets: [Gradient.Stop]

    var body: some View {
        GeometryReader { geo in
            let rad = angle * .pi / 180
            let dx = sin(rad), dy = -cos(rad)
            let l = abs(geo.size.width * dx) + abs(geo.size.height * dy)
            let ux = geo.size.width > 0 ? l * dx / geo.size.width / 2 : 0
            let uy = geo.size.height > 0 ? l * dy / geo.size.height / 2 : 0
            LinearGradient(stops: arrets, startPoint: UnitPoint(x: 0.5 - ux, y: 0.5 - uy), endPoint: UnitPoint(x: 0.5 + ux, y: 0.5 + uy))
        }
    }
}

/// Le reflet des cartes rares et légendaires (`.fc.r .win::after` de la maquette) : une bande bleu clair et rose pâle, en lumière douce,
/// qui glisse quand on incline l'iPhone. Sans mouvement (`fixe`), la bande reste au centre.
struct RefletHolographique: View {
    let inclinaison: CGSize
    let fixe: Bool

    private static func p(_ decalage: Double, _ v: Double) -> Double { min(1, max(0, v + decalage)) }

    var body: some View {
        let dx = fixe ? 0.0 : Double(inclinaison.width)
        let dy = fixe ? 0.0 : Double(inclinaison.height)
        let decalage = dx * 0.2
        DegradeAngle(
            angle: 125 + dy * 12,
            arrets: [
                .init(color: .clear, location: Self.p(decalage, 0.30)),
                .init(color: Color(red: 170 / 255, green: 215 / 255, blue: 1).opacity(0.55), location: max(Self.p(decalage, 0.30), Self.p(decalage, 0.45))),
                .init(color: Color(red: 1, green: 210 / 255, blue: 230 / 255).opacity(0.25), location: max(Self.p(decalage, 0.45), Self.p(decalage, 0.52))),
                .init(color: .clear, location: max(Self.p(decalage, 0.52), Self.p(decalage, 0.62))),
            ]
        )
        .blendMode(.softLight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
