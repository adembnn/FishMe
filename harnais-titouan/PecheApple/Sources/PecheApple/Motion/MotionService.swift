// NON COMPILÉ : écrit sans compilateur Swift. Stub : signatures seulement.
import Foundation
#if canImport(CoreMotion)
import CoreMotion
#endif

/// Inclinaison de l'appareil, normalisée -1...1, pour l'effet holographique de la carte (lot L17).
public struct TiltSample: Sendable, Hashable {
    public let x: Double
    public let y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
    public static let flat = TiltSample(x: 0, y: 0)
}

/// Flux d'inclinaison. Replis : pas de capteur (simulateur) ou « Réduire les animations » -> `.flat`
/// et un geste de glissement côté vue. Le mouvement n'est actif que quand la carte est visible.
public final class MotionService: @unchecked Sendable {
    public init() {}

    public var isAvailable: Bool {
        #if canImport(CoreMotion)
        // TODO(Adem) : CMMotionManager().isDeviceMotionAvailable
        return false
        #else
        return false
        #endif
    }

    /// TODO(Adem) : AsyncStream alimenté par CMMotionManager (≈ 30 Hz ⚠), arrêt à la fin du flux.
    public func tilt() -> AsyncStream<TiltSample> {
        AsyncStream { continuation in
            continuation.yield(.flat)
            continuation.finish()
        }
    }
}
