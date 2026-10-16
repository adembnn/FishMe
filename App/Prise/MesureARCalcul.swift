import Foundation
import simd

/// La fourchette d'une mesure en réalité augmentée, en centimètres entiers. Aucune position du monde n'y figure.
nonisolated struct PlageMesureAR: Equatable, Sendable {
    var basCm: Int
    var centreCm: Int
    var hautCm: Int
    var lidar: Bool

    /// « 52 à 56 cm », jamais un chiffre sec.
    var texte: String { "\(basCm) à \(hautCm) cm" }
}

/// Le calcul pur de la mesure en réalité augmentée : marge, fourchette, plausibilité, poids aux deux bornes.
nonisolated enum MesureARCalcul {
    /// Plage plausible quand l'espèce n'en donne pas.
    static let plageParDefaut: ClosedRange<Double> = 3...200

    /// Marge de chaque côté : la plus grande de 2 cm et 4 % avec LiDAR, de 4 cm et 8 % sans.
    static func margeCm(longueurCm: Double, lidar: Bool) -> Double {
        lidar ? max(2, longueurCm * 0.04) : max(4, longueurCm * 0.08)
    }

    static func plage(longueurCm: Double, lidar: Bool) -> PlageMesureAR {
        let marge = margeCm(longueurCm: longueurCm, lidar: lidar)
        let bas = max(0, (longueurCm - marge).rounded())
        let haut = (longueurCm + marge).rounded()
        return PlageMesureAR(basCm: Int(bas), centreCm: Int(longueurCm.rounded()), hautCm: Int(haut), lidar: lidar)
    }

    /// Distance 3D entre deux points du monde (en mètres) → centimètres.
    static func distanceCm(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Double {
        Double(simd_distance(a, b)) * 100
    }

    /// Au-delà de ce multiple du p95 des longueurs mesurées pour l'espèce, la mesure est à refaire.
    static let facteurP95 = 1.2

    /// Plage plausible d'une espèce : 3 cm jusqu'à 1,2 × p95 (`longueurPlausibleMax`) ; la plage par défaut sans référence.
    static func plageEspece(p95Cm: Double?) -> ClosedRange<Double> {
        guard let p95 = p95Cm, p95.isFinite, p95 > 0 else { return plageParDefaut }
        return plageParDefaut.lowerBound...max(plageParDefaut.lowerBound, p95 * facteurP95)
    }

    static func plausible(_ longueurCm: Double, plage: ClosedRange<Double> = plageParDefaut) -> Bool {
        longueurCm.isFinite && plage.contains(longueurCm)
    }

    static let aRemesurer = "Mesure peu plausible pour ce poisson : recommence."

    /// « ≈ 1,6 à 2,0 kg, estimé ».
    static func textePoids(minKilos: Double, maxKilos: Double) -> String {
        "≈ \(kilos(minKilos)) à \(kilos(maxKilos)) kg, estimé"
    }

    private static func kilos(_ valeur: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f.string(from: NSNumber(value: valeur)) ?? String(format: "%.1f", valeur)
    }
}
