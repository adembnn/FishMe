import CoreGraphics
import Foundation

/// Position d'un poisson dans l'aquarium, en fractions de la vitre (0 à 1), et sens de nage.
nonisolated struct PositionNage: Equatable {
    var x: Double
    var y: Double
    /// Vrai quand le poisson va vers la droite. Les illustrations ont la tête à droite ; vers la gauche, on les retourne en miroir.
    var versLaDroite: Bool
}

/// La façon de nager d'une espèce. Sans table pour une espèce, un style est tiré de son identifiant (toujours le même).
nonisolated struct StyleNage: Equatable {
    /// Périodes d'un aller-retour, en secondes.
    var periodeX: Double
    var periodeY: Double
    /// Étendue de la balade, en fractions de la vitre.
    var etendueX: Double
    var etendueY: Double
    /// Hauteur moyenne dans l'eau (0 en haut, 1 au fond).
    var profondeur: Double
    /// Ondulation du corps (pixels d'amplitude de la queue) et fréquence.
    var amplitudeOnde: Double
    var vitesseOnde: Double

    static func pour(especeId: String) -> StyleNage {
        switch especeId {
        case "brochet": return StyleNage(periodeX: 34, periodeY: 41, etendueX: 0.34, etendueY: 0.05, profondeur: 0.55, amplitudeOnde: 4, vitesseOnde: 2.2)
        case "sandre": return StyleNage(periodeX: 30, periodeY: 37, etendueX: 0.30, etendueY: 0.07, profondeur: 0.68, amplitudeOnde: 4, vitesseOnde: 2.6)
        case "perche-commune", "perche": return StyleNage(periodeX: 17, periodeY: 23, etendueX: 0.26, etendueY: 0.12, profondeur: 0.5, amplitudeOnde: 5, vitesseOnde: 4.4)
        case "truite-fario": return StyleNage(periodeX: 14, periodeY: 19, etendueX: 0.34, etendueY: 0.10, profondeur: 0.42, amplitudeOnde: 5, vitesseOnde: 5.2)
        case "carpe-commune": return StyleNage(periodeX: 38, periodeY: 47, etendueX: 0.28, etendueY: 0.06, profondeur: 0.74, amplitudeOnde: 3, vitesseOnde: 1.8)
        case "anguille-jaune", "anguille-argentee", "anguille": return StyleNage(periodeX: 26, periodeY: 29, etendueX: 0.32, etendueY: 0.05, profondeur: 0.82, amplitudeOnde: 9, vitesseOnde: 3.4)
        case "black-bass": return StyleNage(periodeX: 22, periodeY: 31, etendueX: 0.26, etendueY: 0.09, profondeur: 0.6, amplitudeOnde: 4, vitesseOnde: 3.0)
        default:
            let h = Nage.empreinte(especeId)
            func entre(_ bas: Double, _ haut: Double, _ rang: UInt64) -> Double {
                bas + (haut - bas) * Double((h >> (rang * 8)) & 0xFF) / 255.0
            }
            return StyleNage(periodeX: entre(16, 40, 0), periodeY: entre(18, 48, 1), etendueX: entre(0.22, 0.34, 2),
                             etendueY: entre(0.05, 0.12, 3), profondeur: entre(0.4, 0.78, 4),
                             amplitudeOnde: entre(3, 6, 5), vitesseOnde: entre(2, 5, 6))
        }
    }
}

/// Les mathématiques de la nage, sans SwiftUI : une position ne dépend que du temps, de l'identifiant et de l'espèce.
/// Rien ici ne bouge au hasard, donc tout se teste.
nonisolated enum Nage {
    /// Empreinte stable (FNV-1a) : `hashValue` change à chaque lancement, pas celle-ci.
    static func empreinte(_ texte: String) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for octet in texte.utf8 {
            h ^= UInt64(octet)
            h = h &* 0x100000001b3
        }
        return h
    }

    static func empreinte(_ id: UUID) -> UInt64 {
        empreinte(id.uuidString)
    }

    /// Une fraction stable entre 0 et 1 tirée d'une empreinte.
    static func fraction(_ h: UInt64, _ rang: UInt64) -> Double {
        Double((h >> ((rang % 8) * 8)) & 0xFF) / 255.0
    }

    /// Position au temps `t` (secondes), sans effet des gestes.
    static func position(id: UUID, especeId: String, t: Double) -> PositionNage {
        let style = StyleNage.pour(especeId: especeId)
        let h = empreinte(id)
        let phaseX = fraction(h, 0) * 2 * .pi
        let phaseY = fraction(h, 1) * 2 * .pi
        let decalageProfondeur = (fraction(h, 2) - 0.5) * 0.18
        let wx = 2 * Double.pi / style.periodeX
        let wy = 2 * Double.pi / style.periodeY
        let x = 0.5 + style.etendueX * sin(wx * t + phaseX) + (fraction(h, 3) - 0.5) * 0.12
        let y = style.profondeur + decalageProfondeur + style.etendueY * sin(wy * t + phaseY)
        let vitesseX = cos(wx * t + phaseX)
        return PositionNage(x: min(max(x, 0.1), 0.9), y: min(max(y, 0.14), 0.84), versLaDroite: vitesseX >= 0)
    }

    /// Largeur d'affichage d'un poisson, en points, pour une vitre de 390 pt de large. Un brochet de 80 cm est plus grand
    /// qu'un gardon de 15 cm. Sans taille connue (rare), une taille moyenne : jamais une taille inventée à l'écran.
    static func largeur(longueurCm: Double?, largeurVitre: Double = 390) -> Double {
        let cm = min(max(longueurCm ?? 30, 5), 120)
        let base = 40 + 1.3 * cm
        return min(max(base, 48), 176) * largeurVitre / 390
    }

    /// Poussée d'un toucher sur la vitre : 0 avant le toucher, vive tout de suite, qui retombe en 2 secondes.
    static func forceOnde(depuis dt: Double) -> Double {
        guard dt > 0 else { return 0 }
        return (1 - exp(-dt * 12)) * exp(-dt * 1.4)
    }

    /// Déplacement d'un poisson écarté par un toucher à `centre` (fractions de la vitre), au bout de `dt` secondes.
    static func ecart(poisson: CGPoint, centre: CGPoint, dt: Double, rayon: Double = 0.35) -> CGVector {
        let dx = poisson.x - centre.x
        let dy = poisson.y - centre.y
        let d = max((dx * dx + dy * dy).squareRoot(), 0.001)
        guard d < rayon else { return .zero }
        let proximite = (1 - d / rayon)
        let poussee = proximite * 0.16 * forceOnde(depuis: dt)
        return CGVector(dx: dx / d * poussee, dy: dy / d * poussee)
    }

    /// Hauteur d'une ration qui tombe depuis le haut (fraction de la vitre) ; elle s'arrête sur le fond.
    static func hauteurRation(dt: Double, fond: Double = 0.9) -> Double {
        min(0.04 + dt * 0.11, fond)
    }

    /// Durée pendant laquelle une ration reste visible (chute, puis 2 secondes au fond).
    static func dureeRation(fond: Double = 0.9) -> Double {
        (fond - 0.04) / 0.11 + 2
    }
}
