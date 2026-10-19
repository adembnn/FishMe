import AVFoundation
import SwiftUI
import UIKit

/// La session de prise de vue : l'appareil arrière, un aperçu et une sortie photo. Rien ici ne lit la position :
/// la photo rendue est ré-encodée par `PriseCamera.imageSansGPS`, donc sans aucune métadonnée de lieu.
/// Le projet est en MainActor par défaut : cette classe est `nonisolated` parce qu'AVFoundation l'appelle depuis ses propres files.
/// Tout l'état mutable est touché sur `file` seulement (d'où `@unchecked Sendable`).
nonisolated final class PriseCapture: NSObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    let session = AVCaptureSession()
    private let sortie = AVCapturePhotoOutput()
    private let file = DispatchQueue(label: "fishme.prise.capture")
    private var appareil: AVCaptureDevice?
    private var configuree = false
    /// Ce qu'on fait de la photo : exécuté sur le fil principal.
    typealias Suite = @MainActor @Sendable (Data?) -> Void
    private var fin: Suite?

    /// Vrai si cet iPhone a un appareil arrière (faux sur le simulateur).
    static var disponible: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) != nil
    }

    /// Vrai si l'appareil arrière a une torche.
    static var torcheDisponible: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)?.hasTorch ?? false
    }

    /// Configure (une fois) puis lance la session, hors du fil principal : l'écran sombre est déjà affiché pendant ce temps.
    func demarrer() {
        file.async { [self] in
            if !configuree { configurer() }
            if configuree && !session.isRunning { session.startRunning() }
        }
    }

    /// Arrête la session et éteint la torche.
    func arreter() {
        file.async { [self] in
            reglerTorche(false)
            if session.isRunning { session.stopRunning() }
        }
    }

    func torche(_ allumee: Bool) {
        file.async { [self] in reglerTorche(allumee) }
    }

    /// Prend la photo. `fin` reçoit les données JPEG de l'appareil (qui peuvent porter des métadonnées) ou `nil` ; l'appelant les nettoie.
    func prendre(fin: @escaping Suite) {
        file.async { [self] in
            guard configuree, session.isRunning else { Task { @MainActor in fin(nil) }; return }
            self.fin = fin
            let reglages = AVCapturePhotoSettings()
            reglages.flashMode = .off   // la torche est le seul éclairage ; pas de flash qui effraie le poisson
            sortie.capturePhoto(with: reglages, delegate: self)
        }
    }

    // MARK: Privé, toujours sur `file`

    private func configurer() {
        guard let a = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let entree = try? AVCaptureDeviceInput(device: a) else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        if session.canAddInput(entree) { session.addInput(entree) }
        if session.canAddOutput(sortie) { session.addOutput(sortie) }
        // Portrait : 90 degrés. ⚠ à vérifier sur iPhone : si la photo sort couchée, c'est ici qu'on corrige.
        if let connexion = sortie.connection(with: .video), connexion.isVideoRotationAngleSupported(90) {
            connexion.videoRotationAngle = 90
        }
        session.commitConfiguration()
        appareil = a
        configuree = true
    }

    private func reglerTorche(_ allumee: Bool) {
        guard let a = appareil, a.hasTorch, a.isTorchAvailable else { return }
        do {
            try a.lockForConfiguration()
            a.torchMode = allumee ? .on : .off
            a.unlockForConfiguration()
        } catch {
            // Torche indisponible (appareil occupé) : on ne dit rien, le bouton reste sans effet.
        }
    }

    // MARK: AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let donnees = error == nil ? photo.fileDataRepresentation() : nil
        file.async { [self] in
            let suite = fin
            fin = nil
            if let suite { Task { @MainActor in suite(donnees) } }
        }
    }
}

/// L'aperçu vivant, plein cadre. Le calque d'aperçu est le calque de la vue elle-même.
struct PriseApercu: UIViewRepresentable {
    let capture: PriseCapture

    final class Vue: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var calque: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> Vue {
        let vue = Vue()
        vue.backgroundColor = .black
        vue.calque.session = capture.session
        vue.calque.videoGravity = .resizeAspectFill
        vue.isAccessibilityElement = false
        return vue
    }

    func updateUIView(_ uiView: Vue, context: Context) {}
}
