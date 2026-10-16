import Foundation

// Logique PURE de la nage des poissons du widget aquarium : Foundation seulement, testable sous Linux.
// Tout est déterministe (même entrée, même sortie, d'un lancement à l'autre) : pas de Hasher, pas de hasard.
// Fichier à ajouter à la cible widget (et au paquet de tests, voir AppTests/WidgetAquarium/lancer-tests.sh).

/// Où un poisson se tient dans la zone d'eau à un instant donné.
nonisolated public struct PlacementPoisson: Hashable, Sendable, Identifiable {
    /// = `Poisson.id`.
    public var id: String
    /// 0...1, gauche → droite de la zone d'eau (centre du poisson).
    public var x: Double
    /// 0...1, 0 = surface, 1 = fond.
    public var y: Double
    /// Les images regardent vers la droite ; `false` = image en miroir.
    public var versLaDroite: Bool
    /// 0.75...1.25.
    public var echelle: Double
    public var auRepas: Bool

    public init(id: String, x: Double, y: Double, versLaDroite: Bool, echelle: Double, auRepas: Bool) {
        self.id = id
        self.x = x
        self.y = y
        self.versLaDroite = versLaDroite
        self.echelle = echelle
        self.auRepas = auRepas
    }
}

nonisolated public enum NageWidget {
    /// Un poisson change de place toutes les 20 minutes.
    public static let pas: TimeInterval = 20 * 60
    /// Pendant 10 minutes après une ration, les poissons restent en surface.
    public static let dureeRepas: TimeInterval = 10 * 60
    /// La timeline couvre 6 heures.
    public static let horizon: TimeInterval = 6 * 3600

    // MARK: - Positions

    public static func placements(_ poissons: [InstantaneAquarium.Poisson], a instant: Date,
                                  dernierRepas: Date?, limite: Int, colonnes: Int = 1) -> [PlacementPoisson] {
        let gardes = Array(poissons.prefix(max(limite, 0)))
        let n = gardes.count
        guard n > 0 else { return [] }
        let creneau = creneauDe(instant)
        let repas = repasEnCours(a: instant, dernierRepas: dernierRepas)
        // Widgets larges : les poissons se partagent 2 colonnes (et changent de côté à chaque créneau),
        // ce qui double la hauteur de chaque couloir et évite qu'ils se chevauchent.
        let c = min(max(colonnes, 1), n)
        let rangees = (n + c - 1) / c

        return gardes.enumerated().map { index, poisson in
            let echelle = echelleDe(poisson)
            // Les poissons nagent au-dessus des galets du fond (le bas du décor). Au repas, ils gardent leurs couloirs
            // mais montent dans la moitié haute, vers la nourriture.
            let haut = repas ? 0.08 : 0.14
            let bas = repas ? 0.50 : 0.70
            let x = xNage(poisson.id, creneau, colonne: (index + creneau) % c, sur: c)
            let avant = xNage(poisson.id, creneau - 1, colonne: (index + creneau - 1) % c, sur: c)
            let versLaDroite = repas ? x < 0.5 : x > avant
            return PlacementPoisson(id: poisson.id, x: x,
                                    y: yNage(poisson.id, creneau, index: index / c, sur: rangees, de: haut, a: bas),
                                    versLaDroite: versLaDroite, echelle: echelle, auRepas: repas)
        }
    }

    public static func dates(depuis: Date, dernierRepas: Date?) -> [Date] {
        let fin = depuis.addingTimeInterval(horizon)
        var resultat = [depuis]
        var k = creneauDe(depuis) + 1
        while true {
            let frontiere = Date(timeIntervalSince1970: Double(k) * pas)
            if frontiere > fin { break }
            resultat.append(frontiere)
            k += 1
        }
        if let dernierRepas, repasEnCours(a: depuis, dernierRepas: dernierRepas) {
            resultat.append(dernierRepas.addingTimeInterval(dureeRepas))
        }
        resultat.sort()
        var sansDoublon: [Date] = []
        for date in resultat where sansDoublon.last != date { sansDoublon.append(date) }
        return sansDoublon
    }

    // MARK: - Nage (la boucle de 10 s)

    /// Où est le poisson, vers où il regarde et quelle image de battement montrer, à la copie j d'une boucle.
    public struct PoseNage: Equatable, Sendable {
        /// Centre, en part de la largeur et de la hauteur du widget.
        public let x: Double
        public let y: Double
        /// Échelle horizontale : 1 = regarde à droite, −1 = à gauche ; entre les deux pendant un demi-tour.
        public let sens: Double
        /// Image du cycle de battement de queue (0..<imagesCycle).
        public let image: Int
    }

    /// Part de la boucle passée à nager d'un bord à l'autre ; le reste est le demi-tour (0,5 s sur 10 s).
    static let partTraversee = 0.45

    /// Le poisson traverse l'aquarium, fait demi-tour, revient, fait demi-tour : une boucle de 10 s.
    /// Chaque poisson a sa phase (ils ne tournent pas ensemble) et sa portée (les gros vont moins loin).
    /// `demiLargeur` : moitié de la largeur du poisson, en part de la largeur du widget (pour ne jamais sortir).
    public static func pose(_ placement: PlacementPoisson, copie j: Int, nombre: Int, imagesCycle: Int = 8,
                            demiLargeur: Double) -> PoseNage {
        let n = max(nombre, 1)
        let phase = hasard(placement.id, 0, "phase")
        let u = (Double(j) / Double(n) + phase).truncatingRemainder(dividingBy: 1)
        let marge = demiLargeur + 0.02
        let portee = max((0.5 - marge) * (0.65 + 0.35 * hasard(placement.id, 0, "portee")), 0.02)
        let gauche = 0.5 - portee, droite = 0.5 + portee
        let demiTour = 0.5 - partTraversee

        let x: Double
        var sens: Double
        if u < partTraversee {
            x = gauche + (droite - gauche) * glisse(u / partTraversee)
            sens = 1
        } else if u < 0.5 {
            x = droite
            sens = cos(.pi * (u - partTraversee) / demiTour)
        } else if u < 0.5 + partTraversee {
            x = droite - (droite - gauche) * glisse((u - 0.5) / partTraversee)
            sens = -1
        } else {
            x = gauche
            sens = -cos(.pi * (u - 0.5 - partTraversee) / demiTour)
        }
        // Pendant le demi-tour, le poisson se voit presque de face : jamais tout à fait plat.
        if abs(sens) < 0.18 { sens = sens < 0 ? -0.18 : 0.18 }
        let houle = 0.025 * sin(2 * .pi * (u + hasard(placement.id, 0, "houle")))
        let decalageImage = Int(hasard(placement.id, 0, "battement") * Double(imagesCycle))
        let image = ((j + decalageImage) % max(imagesCycle, 1) + max(imagesCycle, 1)) % max(imagesCycle, 1)
        return PoseNage(x: x, y: placement.y + houle, sens: sens, image: image)
    }

    /// Avance douce : un peu plus lent au départ et à l'arrivée (le poisson accélère puis freine avant de tourner).
    static func glisse(_ v: Double) -> Double {
        let v = min(max(v, 0), 1)
        return v - 0.3 * sin(2 * .pi * v) / (2 * .pi)
    }

    // MARK: - Détails

    private static func creneauDe(_ instant: Date) -> Int {
        Int((instant.timeIntervalSince1970 / pas).rounded(.down))
    }

    private static func repasEnCours(a instant: Date, dernierRepas: Date?) -> Bool {
        guard let dernierRepas else { return false }
        let ecart = instant.timeIntervalSince(dernierRepas)
        return ecart >= 0 && ecart < dureeRepas
    }

    /// Position horizontale entre 0.18 et 0.82. Sur 2 colonnes, chaque poisson reste près du centre de sa moitié
    /// (0.25 ou 0.75, à ±0.06 près) : deux voisins de rangée sont à 0.38 l'un de l'autre au moins, plus qu'un poisson.
    private static func xNage(_ id: String, _ creneau: Int, colonne: Int, sur c: Int) -> Double {
        guard c > 1 else { return 0.18 + 0.64 * hasard(id, creneau, "x") }
        let centre = (Double((colonne % c + c) % c) + 0.5) / Double(c)
        let x = centre + (hasard(id, creneau, "x") - 0.5) * 0.12
        return min(max(x, 0.18), 0.82)
    }

    /// Couloir vertical de l'index `index` parmi `sur`, réparti entre `haut` et `bas`, avec un petit décalage dedans.
    private static func yNage(_ id: String, _ creneau: Int, index: Int, sur n: Int, de haut: Double, a bas: Double) -> Double {
        let largeur = (bas - haut) / Double(n)
        let centre = haut + largeur * (Double(index) + 0.5)
        return centre + (hasard(id, creneau, "y") - 0.5) * largeur * 0.3
    }

    private static func echelleDe(_ poisson: InstantaneAquarium.Poisson) -> Double {
        let ecart = (hasard(poisson.id, 0, "echelle") - 0.5) * 0.1
        return min(max(0.9 + 0.1 * Double(poisson.rarete) + ecart, 0.75), 1.25)
    }

    /// Nombre pseudo-aléatoire dans [0, 1), stable : FNV-1a 64 bits sur « id, sel, créneau », puis mélange final.
    static func hasard(_ id: String, _ creneau: Int, _ sel: String) -> Double {
        var h: UInt64 = 0xcbf29ce484222325
        func melanger(_ octet: UInt8) {
            h ^= UInt64(octet)
            h = h &* 0x100000001b3
        }
        for o in id.utf8 { melanger(o) }
        melanger(0xff)
        for o in sel.utf8 { melanger(o) }
        melanger(0xff)
        let c = UInt64(bitPattern: Int64(creneau))
        for i in 0..<8 { melanger(UInt8(truncatingIfNeeded: c >> (8 * UInt64(i)))) }
        // Mélange final (FNV varie peu sur les derniers octets).
        h ^= h >> 33
        h = h &* 0xff51afd7ed558ccd
        h ^= h >> 33
        return Double(h >> 11) / 9007199254740992.0
    }
}
