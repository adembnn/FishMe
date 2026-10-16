import Foundation

// Logique PURE (Foundation seulement) de l'animation continue du widget : testée sous Linux.
// Technique : un chrono `Text(date, style: .timer)` est redessiné par le système chaque seconde, même dans un widget.
// Deux polices de masque (`FishMeMasquePair` : chiffre pair = carré plein ; `FishMeMasqueImpair` : l'inverse) font
// d'un chrono dont on ne garde que le dernier chiffre une vue pleine 1 s sur 2. Deux masques imbriqués décalés
// de 1/8 s ne laissent passer qu'une fenêtre de 1/8 s : 16 images à 8 images/s, en boucle de 2 s.
enum HorlogeAnimation {
    /// Date de référence commune à TOUS les masques : fixe, passée, multiple entier de secondes.
    /// Le chrono d'une date passée compte vers le haut : chiffre des secondes = floor(t − date) mod 10.
    static let dateReference = Date(timeIntervalSince1970: 1_700_000_000)

    static let imagesParSeconde = 8
    static let nombreImages = 16

    /// Durée de la boucle : 16 images à 8 images/s = 2 s (une période du masque pair/impair).
    static func dureeBoucle(nombre: Int = nombreImages, parSeconde: Int = imagesParSeconde) -> TimeInterval {
        Double(nombre) / Double(parSeconde)
    }

    /// Décalage du masque PAIR de la copie j : la copie j s'ouvre quand (t − ref − j/8) mod 2 vaut 0.
    static func decalagePair(copie j: Int, parSeconde: Int = imagesParSeconde) -> TimeInterval {
        Double(j) / Double(parSeconde)
    }

    /// Décalage du masque IMPAIR de la copie j : (j+1)/8, soit une fenêtre de 1/8 s après l'ouverture du premier.
    static func decalageImpair(copie j: Int, parSeconde: Int = imagesParSeconde) -> TimeInterval {
        Double(j + 1) / Double(parSeconde)
    }

    /// Le chiffre des secondes qu'afficherait `Text(dateReference + decalage, style: .timer)` à cet instant.
    static func dernierChiffre(decalage: TimeInterval, a instant: Date) -> Int {
        let ecoule = Int((instant.timeIntervalSince(dateReference) - decalage).rounded(.down))
        return ((ecoule % 10) + 10) % 10
    }

    /// Le masque est-il plein à cet instant ? Police paire : plein si le chiffre est pair ; impaire : s'il est impair.
    static func masquePlein(pair: Bool, decalage: TimeInterval, a instant: Date) -> Bool {
        let chiffrePair = dernierChiffre(decalage: decalage, a: instant) % 2 == 0
        return chiffrePair == pair
    }

    /// La copie j est-elle visible (les deux masques pleins) à cet instant ?
    static func copieVisible(_ j: Int, a instant: Date, parSeconde: Int = imagesParSeconde) -> Bool {
        masquePlein(pair: true, decalage: decalagePair(copie: j, parSeconde: parSeconde), a: instant)
            && masquePlein(pair: false, decalage: decalageImpair(copie: j, parSeconde: parSeconde), a: instant)
    }

    /// Numéro (0..<nombre) de l'image visible à cet instant, par le calcul direct.
    /// Valable pour nombre ≤ 2 × parSeconde (la fenêtre de 1/8 s tient dans la période de 2 s des masques).
    static func imageVisible(a instant: Date, nombre: Int = nombreImages, parSeconde: Int = imagesParSeconde) -> Int {
        guard nombre > 0, parSeconde > 0 else { return 0 }
        let duree = dureeBoucle(nombre: nombre, parSeconde: parSeconde)
        let t = instant.timeIntervalSince(dateReference)
        let reste = t - (t / duree).rounded(.down) * duree
        let numero = Int((reste * Double(parSeconde)).rounded(.down))
        return min(max(numero, 0), nombre - 1)
    }
}
