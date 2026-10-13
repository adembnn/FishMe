// NON COMPILÉ : écrit sans compilateur Swift. Stub : signatures seulement.
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Prépare une photo avant identification et stockage : redimensionne (côté long 1024 px) et encode en JPEG.
/// Les métadonnées EXIF de position sont supprimées (règle B10 : lieu jamais exact dans un partage).
public struct PhotoPreprocessor: Sendable {
    public static let maxSide: Double = 1024
    public static let jpegQuality: Double = 0.8   // ⚠ valeur de départ non testée

    public init() {}

    /// Renvoie un JPEG redimensionné, ou nil si les données ne sont pas une image.
    public func prepare(_ data: Data) -> Data? {
        #if canImport(UIKit)
        // TODO(Adem) : UIImage(data:) -> redimensionner (UIGraphicsImageRenderer) -> jpegData sans EXIF GPS.
        return nil
        #else
        return nil
        #endif
    }
}

/// Accès à la caméra (aperçu + obturateur). L'app s'ouvre sur la caméra ; la permission n'est
/// demandée qu'au premier tap qui en a besoin (règle B9).
public protocol CameraControlling: AnyObject {
    /// TODO(Adem) : AVCaptureSession, aperçu, bouton volume / Camera Control comme déclencheur (⚠).
    func capturePhoto() async throws -> Data
}
