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
                                  dernierRepas: Date?, limite: Int) -> [PlacementPoisson] {
        let gardes = Array(poissons.prefix(max(limite, 0)))
        let n = gardes.count
        guard n > 0 else { return [] }
        let creneau = creneauDe(instant)
        let repas = repasEnCours(a: instant, dernierRepas: dernierRepas)

        return gardes.enumerated().map { index, poisson in
            let echelle = echelleDe(poisson)
            if repas {
                let x = 0.5 + (hasard(poisson.id, creneau, "repas-x") - 0.5) * 0.5
                let y = 0.08 + 0.17 * hasard(poisson.id, creneau, "repas-y")
                return PlacementPoisson(id: poisson.id, x: x, y: y, versLaDroite: x < 0.5,
                                        echelle: echelle, auRepas: true)
            }
            let x = xNage(poisson.id, creneau)
            let avant = xNage(poisson.id, creneau - 1)
            return PlacementPoisson(id: poisson.id, x: x, y: yNage(poisson.id, creneau, index: index, sur: n),
                                    versLaDroite: x > avant, echelle: echelle, auRepas: false)
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

    // MARK: - Détails

    private static func creneauDe(_ instant: Date) -> Int {
        Int((instant.timeIntervalSince1970 / pas).rounded(.down))
    }

    private static func repasEnCours(a instant: Date, dernierRepas: Date?) -> Bool {
        guard let dernierRepas else { return false }
        let ecart = instant.timeIntervalSince(dernierRepas)
        return ecart >= 0 && ecart < dureeRepas
    }

    private static func xNage(_ id: String, _ creneau: Int) -> Double {
        0.18 + 0.64 * hasard(id, creneau, "x")
    }

    /// Couloir vertical de l'index `index` parmi `sur`, réparti entre 0.15 et 0.85, avec un petit décalage dedans.
    private static func yNage(_ id: String, _ creneau: Int, index: Int, sur n: Int) -> Double {
        let largeur = 0.70 / Double(n)
        let centre = 0.15 + largeur * (Double(index) + 0.5)
        return centre + (hasard(id, creneau, "y") - 0.5) * largeur * 0.6
    }

    private static func echelleDe(_ poisson: InstantaneAquarium.Poisson) -> Double {
        let ecart = (hasard(poisson.id, 0, "echelle") - 0.5) * 0.1
        return min(max(0.9 + 0.1 * Double(poisson.rarete) + ecart, 0.75), 1.25)
    }

    /// Nombre pseudo-aléatoire dans [0, 1), stable : FNV-1a 64 bits sur « id, sel, créneau », puis mélange final.
    private static func hasard(_ id: String, _ creneau: Int, _ sel: String) -> Double {
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
