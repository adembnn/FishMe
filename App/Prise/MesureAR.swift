import ARKit
import Combine
import Observation
import RealityKit
import SwiftUI
import UIKit
import simd

/// Vrai seulement sur un iPhone qui sait suivre le monde (jamais dans le simulateur).
enum MesureAR {
    static var disponible: Bool { ARWorldTrackingConfiguration.isSupported }
    static var lidar: Bool { ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) }
}

/// L'état éphémère de la mesure : deux points du monde, jamais gardés dans la prise.
@MainActor
@Observable
final class MesureAREtat {
    let lidar: Bool
    let plausible: ClosedRange<Double>
    var museau: SIMD3<Float>?
    var queue: SIMD3<Float>?
    /// Positions à l'écran des deux points, remises à jour à chaque image.
    var museauEcran: CGPoint?
    var queueEcran: CGPoint?

    init(lidar: Bool, plausible: ClosedRange<Double> = MesureARCalcul.plageParDefaut) {
        self.lidar = lidar
        self.plausible = plausible
    }

    var longueurCm: Double? {
        guard let museau, let queue else { return nil }
        return MesureARCalcul.distanceCm(museau, queue)
    }

    var estPlausible: Bool { longueurCm.map { MesureARCalcul.plausible($0, plage: plausible) } ?? false }
    var plage: PlageMesureAR? { longueurCm.map { MesureARCalcul.plage(longueurCm: $0, lidar: lidar) } }

    var consigne: String {
        if museau == nil { return "Touche le museau" }
        if queue == nil { return "Touche le bout de la queue" }
        return estPlausible ? "C'est bon ?" : MesureARCalcul.aRemesurer
    }

    func recommencer() {
        museau = nil; queue = nil; museauEcran = nil; queueEcran = nil
    }
}

/// Mesure plein écran : deux touchers, un trait, la fourchette en direct.
struct MesureARView: View {
    @State private var etat: MesureAREtat
    let surValider: (PlageMesureAR) -> Void
    let surAnnuler: () -> Void

    init(plausible: ClosedRange<Double> = MesureARCalcul.plageParDefaut,
         surValider: @escaping (PlageMesureAR) -> Void, surAnnuler: @escaping () -> Void) {
        _etat = State(initialValue: MesureAREtat(lidar: MesureAR.lidar, plausible: plausible))
        self.surValider = surValider
        self.surAnnuler = surAnnuler
    }

    var body: some View {
        ZStack {
            MesureARConteneur(etat: etat).ignoresSafeArea()
            traitEtPoints.allowsHitTesting(false)
            VStack(spacing: 12) {
                HStack {
                    Button(action: surAnnuler) {
                        Image(systemName: "xmark").font(.system(.body, design: .rounded, weight: .bold))
                            .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Fermer")
                    Spacer()
                }
                Text(etat.consigne)
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                Spacer()
                if let plage = etat.plage, etat.estPlausible {
                    Text(plage.texte)
                        .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                HStack(spacing: 12) {
                    Button("Recommencer") { etat.recommencer() }
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(.ultraThinMaterial, in: Capsule())
                    Button("Valider") { if let plage = etat.plage { surValider(plage) } }
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(PriseJetons.accent.opacity(etat.estPlausible ? 1 : 0.4), in: Capsule())
                        .disabled(!etat.estPlausible)
                }
            }
            .foregroundStyle(PriseJetons.encre)
            .padding(20)
        }
    }

    private var traitEtPoints: some View {
        ZStack {
            if let a = etat.museauEcran, let b = etat.queueEcran {
                Path { p in p.move(to: a); p.addLine(to: b) }
                    .stroke(PriseJetons.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            if let a = etat.museauEcran { point(a) }
            if let b = etat.queueEcran { point(b) }
        }
    }

    private func point(_ lieu: CGPoint) -> some View {
        Circle().fill(.white).frame(width: 18, height: 18)
            .overlay(Circle().stroke(PriseJetons.accent, lineWidth: 4))
            .position(lieu)
    }
}

/// Enveloppe UIKit de `ARView` : session de suivi du monde, LiDAR si disponible, sinon plan horizontal.
private struct MesureARConteneur: UIViewRepresentable {
    let etat: MesureAREtat

    func makeCoordinator() -> Coordinateur { Coordinateur(etat: etat) }

    func makeUIView(context: Context) -> ARView {
        let vue = ARView(frame: .zero)
        vue.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        if MesureAR.lidar {
            configuration.sceneReconstruction = .mesh
        } else {
            configuration.planeDetection = [.horizontal]
        }
        vue.session.run(configuration)
        vue.addGestureRecognizer(UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinateur.toucher(_:))))
        context.coordinator.vue = vue
        context.coordinator.abonnement = vue.scene.subscribe(to: SceneEvents.Update.self) { [weak coordinateur = context.coordinator] _ in
            MainActor.assumeIsolated { coordinateur?.projeter() }
        }
        return vue
    }

    func updateUIView(_ vue: ARView, context: Context) {}

    static func dismantleUIView(_ vue: ARView, coordinator: Coordinateur) {
        vue.session.pause()
        coordinator.abonnement?.cancel()
    }

    @MainActor
    final class Coordinateur: NSObject {
        let etat: MesureAREtat
        weak var vue: ARView?
        var abonnement: (any Cancellable)?

        init(etat: MesureAREtat) { self.etat = etat }

        @objc func toucher(_ geste: UITapGestureRecognizer) {
            guard let vue, etat.queue == nil else { return }
            let lieu = geste.location(in: vue)
            guard let monde = pointDuMonde(sous: lieu, dans: vue) else { return }
            if etat.museau == nil { etat.museau = monde } else { etat.queue = monde }
            projeter()
        }

        /// Raycast sur le maillage (LiDAR) ou le plan horizontal détecté, sinon plan estimé.
        private func pointDuMonde(sous lieu: CGPoint, dans vue: ARView) -> SIMD3<Float>? {
            let cibles: [ARRaycastQuery.Target] = etat.lidar ? [.estimatedPlane] : [.existingPlaneGeometry, .estimatedPlane]
            for cible in cibles {
                let alignement: ARRaycastQuery.TargetAlignment = etat.lidar ? .any : .horizontal
                if let requete = vue.makeRaycastQuery(from: lieu, allowing: cible, alignment: alignement),
                   let touche = vue.session.raycast(requete).first {
                    let t = touche.worldTransform.columns.3
                    return SIMD3<Float>(t.x, t.y, t.z)
                }
            }
            return nil
        }

        func projeter() {
            guard let vue else { return }
            etat.museauEcran = etat.museau.flatMap { vue.project($0) }
            etat.queueEcran = etat.queue.flatMap { vue.project($0) }
        }
    }
}
