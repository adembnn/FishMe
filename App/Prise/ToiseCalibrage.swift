import CoreGraphics
import Foundation

/// Un chiffre lu sur la toise : sa position le long de l'axe (en pixels) et sa valeur en centimètres.
nonisolated struct RepereToise: Equatable, Sendable {
    var position: Double
    var valeurCm: Double
}

/// Un texte lu par Vision et son rectangle, en pixels de l'image, origine en haut à gauche.
nonisolated struct TexteLu: Equatable, Sendable {
    var texte: String
    var rect: CGRect
}

/// Droite « centimètres = pente × pixels + origine », ajustée sur les chiffres lus. Logique pure.
nonisolated struct ToiseCalibrage: Equatable, Sendable {
    nonisolated enum Axe: Equatable, Sendable { case horizontal, vertical }

    var axe: Axe
    var pente: Double
    var origine: Double

    func cm(en pixels: Double) -> Double { pente * pixels + origine }

    /// Seuils (à mesurer sur les 10 photos de toise) : au moins 3 chiffres distincts, étendue d'au moins 20 cm, écart maximal de 1,5 cm.
    static let reperesMin = 3
    static let etendueMinCm = 20.0
    static let ecartMaxCm = 1.5

    /// Cherche la toise dans les textes lus. `nil` si rien de cohérent : le pêcheur règle alors le curseur lui-même.
    static func lire(_ textes: [TexteLu]) -> ToiseCalibrage? {
        var chiffres: [(valeur: Double, centre: CGPoint)] = []
        for t in textes {
            let net = t.texte.trimmingCharacters(in: .whitespaces)
            if let v = Int(net), (0...200).contains(v) {
                chiffres.append((valeur: Double(v), centre: CGPoint(x: t.rect.midX, y: t.rect.midY)))
            }
        }
        var meilleur: (ToiseCalibrage, Double)?
        for axe in [Axe.horizontal, Axe.vertical] {
            let reperes = chiffres.map { RepereToise(position: axe == .horizontal ? Double($0.centre.x) : Double($0.centre.y), valeurCm: $0.valeur) }
            if let c = ajuster(reperes, axe: axe), meilleur == nil || c.1 < meilleur!.1 {
                meilleur = c
            }
        }
        return meilleur?.0
    }

    /// Régression des moindres carrés ; rend la droite et son pire écart, ou `nil` si elle n'est pas fiable.
    static func ajuster(_ reperes: [RepereToise], axe: Axe) -> (ToiseCalibrage, Double)? {
        let uniques = Set(reperes.map { $0.valeurCm })
        guard reperes.count >= reperesMin, uniques.count >= reperesMin else { return nil }
        guard let mini = uniques.min(), let maxi = uniques.max(), maxi - mini >= etendueMinCm else { return nil }
        let n = Double(reperes.count)
        let sx = reperes.reduce(0) { $0 + $1.position }
        let sy = reperes.reduce(0) { $0 + $1.valeurCm }
        let sxx = reperes.reduce(0) { $0 + $1.position * $1.position }
        let sxy = reperes.reduce(0) { $0 + $1.position * $1.valeurCm }
        let denom = n * sxx - sx * sx
        guard abs(denom) > 1e-9 else { return nil }
        let pente = (n * sxy - sx * sy) / denom
        guard abs(pente) > 1e-9 else { return nil }
        let origine = (sy - pente * sx) / n
        let pire = reperes.map { abs(pente * $0.position + origine - $0.valeurCm) }.max() ?? Double.infinity
        guard pire <= ecartMaxCm else { return nil }
        return (ToiseCalibrage(axe: axe, pente: pente, origine: origine), pire)
    }

    /// La longueur du poisson : de la butée (0 cm) au bout de la queue touché par le pêcheur, en pixels.
    func longueurCm(boutDeLaQueue: CGPoint) -> Double {
        let p = axe == .horizontal ? Double(boutDeLaQueue.x) : Double(boutDeLaQueue.y)
        return max(0, cm(en: p))
    }
}
