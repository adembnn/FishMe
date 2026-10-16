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

    /// Seuils mesurés le 16 oct. 2026 sur 13 vraies photos de toise lues par Vision (`reports/reconnaissance/toise.md`) :
    /// 3 toises lues, aucune fausse lecture. Avec 3 repères, un journal sous le poisson donnait une fausse toise.
    static let reperesMin = 4
    static let etendueMinCm = 15.0
    static let ecartMaxCm = 1.5
    /// Un centimètre occupe entre 0,25 % et 12 % de la longueur de l'image le long de la toise (poisson de 15 cm en gros plan
    /// jusqu'à un silure de 2 m). Hors de cette plage, la droite vient d'autres chiffres (prix, dates).
    static let cmMinFractionImage = 0.0025
    static let cmMaxFractionImage = 0.12

    /// Les nombres d'un texte lu, chacun à sa place. Vision rend souvent toute la graduation en un seul texte
    /// (« 10 11 12 13 »), d'où une position estimée par l'indice des caractères dans le rectangle.
    static func nombres(dans t: TexteLu) -> [(valeur: Double, centre: CGPoint)] {
        let caracteres = Array(t.texte)
        guard !caracteres.isEmpty else { return [] }
        let vertical = t.rect.height > 1.5 * t.rect.width && caracteres.count > 2
        var resultat: [(valeur: Double, centre: CGPoint)] = []
        var i = 0
        while i < caracteres.count {
            guard caracteres[i].isASCII, caracteres[i].isNumber else { i += 1; continue }
            var j = i
            while j < caracteres.count, caracteres[j].isASCII, caracteres[j].isNumber { j += 1 }
            if let v = Int(String(caracteres[i..<j])), (0...200).contains(v) {
                let f = CGFloat(i + j) / 2 / CGFloat(caracteres.count)
                let centre = vertical
                    ? CGPoint(x: t.rect.midX, y: t.rect.minY + t.rect.height * f)
                    : CGPoint(x: t.rect.minX + t.rect.width * f, y: t.rect.midY)
                resultat.append((valeur: Double(v), centre: centre))
            }
            i = j
        }
        return resultat
    }

    /// Cherche la toise dans les textes lus. `nil` si rien de cohérent : le pêcheur règle alors le curseur lui-même.
    /// `taille` : celle de l'image, pour écarter une droite impossible (nil dans les tests sans image).
    static func lire(_ textes: [TexteLu], taille: CGSize? = nil) -> ToiseCalibrage? {
        let chiffres = textes.flatMap { nombres(dans: $0) }
        var meilleur: (calibrage: ToiseCalibrage, reperes: Int, pire: Double)?
        for axe in [Axe.horizontal, Axe.vertical] {
            let reperes = chiffres.map { RepereToise(position: axe == .horizontal ? Double($0.centre.x) : Double($0.centre.y), valeurCm: $0.valeur) }
            let longueurImage = taille.map { Double(axe == .horizontal ? $0.width : $0.height) }
            guard let c = ajuster(reperes, axe: axe, longueurImage: longueurImage) else { continue }
            if meilleur == nil || c.reperes > meilleur!.reperes || (c.reperes == meilleur!.reperes && c.pire < meilleur!.pire) {
                meilleur = c
            }
        }
        return meilleur?.calibrage
    }

    /// Ajustement robuste : chaque paire de repères propose une droite, on garde celle qui explique le plus de repères
    /// (à `ecartMaxCm` près), puis les moindres carrés sur ces repères. Les chiffres parasites (marque, prix) sont ainsi ignorés.
    static func ajuster(_ reperes: [RepereToise], axe: Axe, longueurImage: Double? = nil) -> (calibrage: ToiseCalibrage, reperes: Int, pire: Double)? {
        var meilleur: (calibrage: ToiseCalibrage, reperes: Int, pire: Double)?
        for i in reperes.indices {
            for j in reperes.indices where j > i {
                let a = reperes[i], b = reperes[j]
                guard a.valeurCm != b.valeurCm, abs(a.position - b.position) > 1e-6 else { continue }
                let pente = (b.valeurCm - a.valeurCm) / (b.position - a.position)
                let origine = a.valeurCm - pente * a.position
                let retenus = reperes.filter { abs(pente * $0.position + origine - $0.valeurCm) <= ecartMaxCm }
                guard let c = moindresCarres(retenus, axe: axe, longueurImage: longueurImage) else { continue }
                if meilleur == nil || c.reperes > meilleur!.reperes || (c.reperes == meilleur!.reperes && c.pire < meilleur!.pire) {
                    meilleur = c
                }
            }
        }
        return meilleur
    }

    /// Droite des moindres carrés ; `nil` si elle n'est pas fiable (trop peu de repères, étendue courte, écart, échelle impossible).
    static func moindresCarres(_ reperes: [RepereToise], axe: Axe, longueurImage: Double?) -> (calibrage: ToiseCalibrage, reperes: Int, pire: Double)? {
        let uniques = Set(reperes.map { $0.valeurCm })
        guard uniques.count >= reperesMin else { return nil }
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
        if let l = longueurImage, l > 0 {
            let pixelsParCm = 1 / abs(pente)
            guard pixelsParCm >= cmMinFractionImage * l, pixelsParCm <= cmMaxFractionImage * l else { return nil }
        }
        let origine = (sy - pente * sx) / n
        let pire = reperes.map { abs(pente * $0.position + origine - $0.valeurCm) }.max() ?? Double.infinity
        guard pire <= ecartMaxCm else { return nil }
        return (ToiseCalibrage(axe: axe, pente: pente, origine: origine), uniques.count, pire)
    }

    /// La longueur du poisson : de la butée (0 cm) au bout de la queue touché par le pêcheur, en pixels.
    func longueurCm(boutDeLaQueue: CGPoint) -> Double {
        let p = axe == .horizontal ? Double(boutDeLaQueue.x) : Double(boutDeLaQueue.y)
        return max(0, cm(en: p))
    }
}
