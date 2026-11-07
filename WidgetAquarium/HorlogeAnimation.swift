import Foundation

// Logique PURE (Foundation seulement) de l'animation continue du widget : testée sous Linux.
// Technique de Bryce Bostwick (MIT, github.com/brycebostwick/WidgetAnimation) : un chrono
// `Text(date, style: .timer)` est redessiné par le système chaque seconde, même dans un widget. Les polices
// `FishMeClignoteChiffreK` remplacent les secondes du chrono par un carré plein seulement quand leur chiffre des
// unités vaut K : la vue est pleine 1 s toutes les 10 s. Deux masques imbriqués (chiffre q décalé de r/8 s,
// chiffre q−1 décalé de (r+1)/16 s) ne laissent passer qu'une fenêtre de 1/16 s : 160 images à 16 images/s,
// en boucle de 10 s, une seule visible à la fois. Adem (16 oct. 06h) : 8 images/s paraissait saccadé.
nonisolated enum HorlogeAnimation {
    static let imagesParSeconde = 16
    /// Une boucle = un tour complet du chiffre des unités des secondes.
    static let dureeBoucle: TimeInterval = 10
    static let nombreImages = imagesParSeconde * 10

    /// Date de référence d'une entrée de timeline : 60 s avant elle (le chrono reste court, « 1:00 »,
    /// comme dans l'exemple de Bryce Bostwick ; un multiple de 10 s garde la boucle calée sur l'entrée).
    static func reference(pour date: Date) -> Date {
        date.addingTimeInterval(-60)
    }

    /// Les deux masques de la copie j : (chiffre de la police, décalage en secondes).
    static func masques(copie j: Int, parSeconde: Int = imagesParSeconde) -> (a: (chiffre: Int, decalage: TimeInterval),
                                                                            b: (chiffre: Int, decalage: TimeInterval)) {
        let q = (j / parSeconde) % 10
        let r = j % parSeconde
        return ((q, Double(r) / Double(parSeconde)), ((q + 9) % 10, Double(r + 1) / Double(parSeconde)))
    }

    /// Le chiffre des unités des secondes qu'affiche `Text(reference + decalage, style: .timer)` à cet instant.
    static func dernierChiffre(reference: Date, decalage: TimeInterval, a instant: Date) -> Int {
        let ecoule = Int((instant.timeIntervalSince(reference) - decalage).rounded(.down))
        return ((ecoule % 10) + 10) % 10
    }

    /// La copie j est-elle visible (ses deux masques pleins) à cet instant ?
    static func copieVisible(_ j: Int, reference: Date, a instant: Date, parSeconde: Int = imagesParSeconde) -> Bool {
        let (a, b) = masques(copie: j, parSeconde: parSeconde)
        return dernierChiffre(reference: reference, decalage: a.decalage, a: instant) == a.chiffre
            && dernierChiffre(reference: reference, decalage: b.decalage, a: instant) == b.chiffre
    }

    // MARK: - Boucle courte (widget allégé)

    /// Boucle courte du vrai widget : 2 s à 8 images/s = 16 copies (au lieu de 160). La durée doit diviser 10 :
    /// le masque d'une copie est alors l'UNION des chiffres s, s+P, s+2P… (5 chronos pour P = 2 s).
    public struct Boucle: Equatable, Sendable {
        public let parSeconde: Int
        public let duree: Int
        public init(parSeconde: Int, duree: Int) {
            precondition(duree > 0 && 10 % duree == 0 && parSeconde > 0)
            self.parSeconde = parSeconde
            self.duree = duree
        }
        public var copies: Int { parSeconde * duree }
        /// Chronos par copie (deux masques, chacun union de 10 / P chiffres).
        public var chronosParCopie: Int { 2 * (10 / duree) }
        public static let battement = Boucle(parSeconde: 8, duree: 2)
    }

    /// Les deux masques (union de chiffres, décalage) de la copie k d'une boucle courte.
    public static func masques(copie k: Int, boucle: Boucle) -> (a: (chiffres: [Int], decalage: TimeInterval),
                                                                 b: (chiffres: [Int], decalage: TimeInterval)) {
        let f = boucle.parSeconde
        let s = (k / f) % boucle.duree
        let r = k % f
        let tours = 10 / boucle.duree
        let a = (0..<tours).map { (s + $0 * boucle.duree) % 10 }
        let b = (0..<tours).map { (s + 9 + $0 * boucle.duree) % 10 }
        return ((a, Double(r) / Double(f)), (b, Double(r + 1) / Double(f)))
    }

    public static func copieVisible(_ k: Int, boucle: Boucle, reference: Date, a instant: Date) -> Bool {
        let (a, b) = masques(copie: k, boucle: boucle)
        return a.chiffres.contains(dernierChiffre(reference: reference, decalage: a.decalage, a: instant))
            && b.chiffres.contains(dernierChiffre(reference: reference, decalage: b.decalage, a: instant))
    }

    /// Copie attendue à l'écran à cet instant (calcul direct).
    public static func imageVisible(boucle: Boucle, reference: Date, a instant: Date) -> Int {
        let t = instant.timeIntervalSince(reference)
        let n = Int((t * Double(boucle.parSeconde)).rounded(.down))
        return ((n % boucle.copies) + boucle.copies) % boucle.copies
    }

    /// Numéro (0..<nombreImages) de l'image visible à cet instant, par le calcul direct.
    static func imageVisible(reference: Date, a instant: Date, parSeconde: Int = imagesParSeconde) -> Int {
        let nombre = parSeconde * 10
        let t = instant.timeIntervalSince(reference)
        let reste = t - (t / dureeBoucle).rounded(.down) * dureeBoucle
        return min(max(Int((reste * Double(parSeconde)).rounded(.down)), 0), nombre - 1)
    }
}
