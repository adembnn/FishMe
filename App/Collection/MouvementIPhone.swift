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

/// Reflet holographique : des bandes claires qui glissent avec l'inclinaison. Fixe avec « Réduire les animations ».
struct RefletHolographique: View {
    let inclinaison: CGSize
    let fixe: Bool

    var body: some View {
        let dx = fixe ? 0.0 : Double(inclinaison.width)
        let dy = fixe ? 0.0 : Double(inclinaison.height)
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.0),
                .init(color: Color.white.opacity(0.55), location: 0.35 + dx * 0.18),
                .init(color: Color(red: 0.62, green: 0.95, blue: 0.88).opacity(0.45), location: 0.46 + dx * 0.18),
                .init(color: Color(red: 0.70, green: 0.84, blue: 1.0).opacity(0.45), location: 0.56 + dx * 0.18),
                .init(color: .clear, location: 1.0),
            ],
            startPoint: UnitPoint(x: 0.0 + dy * 0.2, y: 0.0),
            endPoint: UnitPoint(x: 1.0 - dy * 0.2, y: 1.0)
        )
        .blendMode(.plusLighter)
        .opacity(0.8)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
