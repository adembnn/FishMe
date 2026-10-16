import Foundation

/// Les stations OFB d'une espèce rangées en cases de 0,05° de latitude sur 0,1° de longitude : trouver la plus proche d'un coin
/// ne regarde que les cases voisines, au lieu de toutes les stations. Même résultat que le balayage complet : à distance égale,
/// la station qui vient la première dans le fichier gagne.
struct GrilleStations: Sendable {
    private static let pasLat = 0.05
    private static let pasLon = 0.1

    private struct Case: Hashable, Sendable { var i: Int32; var j: Int32 }

    private let cases: [Case: [(rang: Int, station: StationBrute)]]
    let estVide: Bool

    init(_ stations: [StationBrute]) {
        var cases: [Case: [(rang: Int, station: StationBrute)]] = [:]
        for (rang, s) in stations.enumerated() {
            cases[Self.case(s.coordonnee.latitude, s.coordonnee.longitude), default: []].append((rang, s))
        }
        self.cases = cases
        self.estVide = stations.isEmpty
    }

    private static func `case`(_ lat: Double, _ lon: Double) -> Case {
        Case(i: Int32((lat / pasLat).rounded(.down)), j: Int32((lon / pasLon).rounded(.down)))
    }

    /// La station la plus proche à moins de `MoteurCoins.rayonStationM`, ou `nil`.
    func laPlusProche(de c: Coordonnee) -> (station: StationBrute, distanceM: Double)? {
        let rayon = MoteurCoins.rayonStationM
        let dLat = rayon / 111_000 + 0.001
        // Un degré de longitude est plus court quand on monte en latitude : on élargit en conséquence (marge de 0,2°).
        let cosLat = max(cos((min(abs(c.latitude) + 0.2, 89)) * .pi / 180), 0.01)
        let dLon = rayon / (111_000 * cosLat) + 0.001
        let i0 = Int32(((c.latitude - dLat) / Self.pasLat).rounded(.down)), i1 = Int32(((c.latitude + dLat) / Self.pasLat).rounded(.down))
        let j0 = Int32(((c.longitude - dLon) / Self.pasLon).rounded(.down)), j1 = Int32(((c.longitude + dLon) / Self.pasLon).rounded(.down))
        var meilleure: (rang: Int, station: StationBrute, d: Double)?
        for i in i0...i1 {
            for j in j0...j1 {
                guard let liste = cases[Case(i: i, j: j)] else { continue }
                for (rang, s) in liste where abs(s.coordonnee.latitude - c.latitude) <= dLat {
                    let d = Geodesie.distanceM(c, s.coordonnee)
                    guard d <= rayon else { continue }
                    if let m = meilleure, (d, rang) >= (m.d, m.rang) { continue }
                    meilleure = (rang, s, d)
                }
            }
        }
        return meilleure.map { (station: $0.station, distanceM: $0.d) }
    }
}

/// Ce que `MoteurCoins` garde entre deux appels : le fichier OpenStreetMap lu une fois (au premier besoin), une grille de stations par
/// espèce, et le département et le lieu de chaque coin. Partagé par toutes les copies du moteur ; verrou court, calculs hors verrou.
final class IndexCoins: @unchecked Sendable {
    private let donnees: Data?
    private let stations: [StationBrute]
    private let verrou = NSLock()
    private var coinsLus: [CoinOSM]?
    private var grilles: [String: GrilleStations] = [:]
    private var grilleComplete: GrilleStations?
    private var lieux: [Int: (Departement, Lieu)] = [:]

    init(donnees: Data?, stations: [StationBrute]) {
        self.donnees = donnees
        self.stations = stations
    }

    var coins: [CoinOSM] {
        verrou.lock()
        if let coinsLus { verrou.unlock(); return coinsLus }
        verrou.unlock()
        let lus = CoinOSM.decoder(donnees)
        verrou.lock()
        defer { verrou.unlock() }
        if let deja = coinsLus { return deja }
        coinsLus = lus
        return lus
    }

    /// Les stations où l'espèce (code Sandre) a été vue au moins une fois, rangées en grille.
    func grille(code: String) -> GrilleStations {
        verrou.lock()
        if let g = grilles[code] { verrou.unlock(); return g }
        verrou.unlock()
        let g = GrilleStations(stations.filter { ($0.vues[code] ?? 0) > 0 })
        verrou.lock()
        defer { verrou.unlock() }
        if let deja = grilles[code] { return deja }
        grilles[code] = g
        return g
    }

    /// Toutes les stations, pour les pastilles de la carte.
    func grilleToutes() -> GrilleStations {
        verrou.lock()
        if let g = grilleComplete { verrou.unlock(); return g }
        verrou.unlock()
        let g = GrilleStations(stations)
        verrou.lock()
        defer { verrou.unlock() }
        if let deja = grilleComplete { return deja }
        grilleComplete = g
        return g
    }

    /// Département du coin (celui du fichier à défaut de polygone) et lieu calculé depuis sa coordonnée, une seule fois par coin.
    func lieu(deCoin i: Int, geo: MoteurGeo) -> (Departement, Lieu) {
        verrou.lock()
        if let l = lieux[i] { verrou.unlock(); return l }
        verrou.unlock()
        let c = coins[i]
        let calcule = geo.departement(de: c.coordonnee)
        let departement = calcule.estInconnu ? (c.dep.map { Departement(code: $0) } ?? calcule) : calcule
        let resultat = (departement, geo.lieu(de: c.coordonnee, choix: nil))
        verrou.lock()
        lieux[i] = resultat
        verrou.unlock()
        return resultat
    }
}
