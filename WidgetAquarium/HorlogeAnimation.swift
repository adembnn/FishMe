import Foundation

// Logique PURE (Foundation seulement) de l'animation continue du widget : testée sous Linux.
// Technique de Bryce Bostwick (MIT, github.com/brycebostwick/WidgetAnimation) : un chrono
// `Text(date, style: .timer)` est redessiné par le système chaque seconde, même dans un widget. Les polices
// `FishMeClignoteChiffreK` remplacent les secondes du chrono par un carré plein seulement quand leur chiffre des
// unités vaut K : la vue est pleine 1 s toutes les 10 s. Deux masques imbriqués (chiffre q décalé de r/8 s,
// chiffre q−1 décalé de (r+1)/8 s) ne laissent passer qu'une fenêtre de 1/8 s : 80 images à 8 images/s,
// en boucle de 10 s, une seule visible à la fois.
enum HorlogeAnimation {
    static let imagesParSeconde = 8
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

    /// Numéro (0..<80) de l'image visible à cet instant, par le calcul direct.
    static func imageVisible(reference: Date, a instant: Date, parSeconde: Int = imagesParSeconde) -> Int {
        let nombre = parSeconde * 10
        let t = instant.timeIntervalSince(reference)
        let reste = t - (t / dureeBoucle).rounded(.down) * dureeBoucle
        return min(max(Int((reste * Double(parSeconde)).rounded(.down)), 0), nombre - 1)
    }
}
