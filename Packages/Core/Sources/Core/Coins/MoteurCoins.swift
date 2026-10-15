import Foundation

/// Les coins publics OpenStreetMap, par espèce, par zone ou autour d'un point (L7). Ajout du 15 oct. au contrat.
public protocol ServiceCoinsPublics: Sendable {
    /// Les coins publics où l'espèce a été relevée à proximité, du plus proche au plus loin du point (au plus `MoteurCoins.coinsMaximum`).
    /// `[]` sans couche OpenStreetMap, sans relevé à proximité, ou pour une espèce inconnue : jamais de coin inventé.
    func coinsProches(ou espece: Espece, pres coordonnee: Coordonnee) -> [CoinProche]
    /// Tous les coins publics du rectangle, avec les espèces de leur station OFB (pastilles de la carte). Triés par identifiant.
    func coinsPublicsDans(_ region: RegionCarte) -> [CoinPublic]
    /// Les coins publics à moins de `rayonM` mètres du point, du plus proche au plus loin.
    func coinsPublics(pres coordonnee: Coordonnee, rayonM: Double) -> [CoinPublic]
}

/// Moteur des coins publics : la couche OpenStreetMap (`coins-osm.geojson`) reliée aux stations et aux règles du moteur d'espèces.
/// Il remplit aussi `ServiceEspeces` : `coins(ou:pres:)` rend de vrais coins quand la couche en a, sinon les stations OFB comme avant,
/// donc les appelants existants ne changent pas.
public struct MoteurCoins: ServiceCoinsPublics, ServiceEspeces {
    /// Distance maximale entre un coin public et la station OFB à laquelle on le relie (par défaut, à confirmer par Adem).
    /// Au-delà, le coin n'a « aucun relevé à proximité » : on ne lui prête pas les poissons d'une station lointaine.
    public static let rayonStationM: Double = 5_000
    /// Nombre maximal de coins rendus par `coinsProches(ou:pres:)`.
    public static let coinsMaximum = MoteurEspeces.coinsMaximum

    let base: MoteurEspeces
    let coinsOSM: [CoinOSM]

    /// `donneesOSM` : le contenu de `coins-osm.geojson`. Absent, vide ou illisible : aucun coin, et `coins(ou:pres:)` rend les stations.
    public init(especes: MoteurEspeces, donneesOSM: Data?) {
        self.base = especes
        self.coinsOSM = CoinOSM.decoder(donneesOSM)
    }

    /// Vrai si la couche OpenStreetMap contient au moins un coin.
    public var aDesCoins: Bool { !coinsOSM.isEmpty }

    // MARK: Coins publics

    private func stationLaPlusProche(de c: Coordonnee, parmi candidates: [StationBrute]) -> (station: StationBrute, distanceM: Double)? {
        let dLat = Self.rayonStationM / 111_000 + 0.001
        var meilleure: (StationBrute, Double)?
        for s in candidates where abs(s.coordonnee.latitude - c.latitude) <= dLat {
            let d = Geodesie.distanceM(c, s.coordonnee)
            if d <= Self.rayonStationM, d < (meilleure?.1 ?? .infinity) { meilleure = (s, d) }
        }
        return meilleure.map { (station: $0.0, distanceM: $0.1) }
    }

    private func departement(de c: CoinOSM) -> Departement {
        let calcule = base.geo.departement(de: c.coordonnee)
        if !calcule.estInconnu { return calcule }
        return c.dep.map { Departement(code: $0) } ?? calcule
    }

    public func coinsProches(ou espece: Espece, pres coordonnee: Coordonnee) -> [CoinProche] {
        guard !coinsOSM.isEmpty,
              let code = espece.codeSandre ?? base.liste.first(where: { $0.espece.id == espece.id })?.espece.codeSandre else { return [] }
        let date = base.horloge()
        let candidates = base.stations.filter { ($0.vues[code] ?? 0) > 0 }
        guard !candidates.isEmpty else { return [] }
        let tries = coinsOSM.map { ($0, Geodesie.distanceM(coordonnee, $0.coordonnee)) }.sorted { ($0.1, $0.0.id) < ($1.1, $1.0.id) }
        var coins: [CoinProche] = []
        for (c, d) in tries {
            guard let (s, ds) = stationLaPlusProche(de: c.coordonnee, parmi: candidates) else { continue }
            var lieu = base.geo.lieu(de: c.coordonnee, choix: nil)
            if lieu.departement.estInconnu { lieu = base.geo.lieu(station: s) }
            coins.append(CoinProche(id: c.id, nom: c.nom, type: c.type, acces: c.acces, payant: c.payant, departement: departement(de: c),
                                    coordonnee: c.coordonnee, distanceM: d, codeStation: s.id, eauStation: s.eau, distanceStationM: ds,
                                    nPeches: s.vues[code] ?? 0, annee: s.derniere,
                                    ouverture: base.regles.ouverture(espece: espece, lieu: lieu, date: date)))
            if coins.count >= Self.coinsMaximum { break }
        }
        return coins
    }

    private func coinPublic(_ c: CoinOSM) -> CoinPublic {
        let proche = stationLaPlusProche(de: c.coordonnee, parmi: base.stations)
        let especes: [EspeceRelevee] = (proche?.station).map { s in
            s.vues.compactMap { code, n -> EspeceRelevee? in
                guard n > 0, let esp = base.liste.first(where: { $0.espece.codeSandre == code })?.espece else { return nil }
                return EspeceRelevee(espece: esp, nPeches: n, annee: s.derniere)
            }.sorted { ($0.nPeches, $1.espece.id) > ($1.nPeches, $0.espece.id) }
        } ?? []
        return CoinPublic(id: c.id, nom: c.nom, type: c.type, acces: c.acces, payant: c.payant, departement: departement(de: c),
                          coordonnee: c.coordonnee, codeStation: proche?.station.id, eauStation: proche?.station.eau,
                          distanceStationM: proche?.distanceM, especes: especes)
    }

    public func coinsPublicsDans(_ region: RegionCarte) -> [CoinPublic] {
        coinsOSM.filter { region.contient($0.coordonnee) }.sorted { $0.id < $1.id }.map(coinPublic)
    }

    public func coinsPublics(pres coordonnee: Coordonnee, rayonM: Double) -> [CoinPublic] {
        coinsOSM.compactMap { c -> (CoinOSM, Double)? in
            let d = Geodesie.distanceM(coordonnee, c.coordonnee)
            return d <= rayonM ? (c, d) : nil
        }.sorted { ($0.1, $0.0.id) < ($1.1, $1.0.id) }.map { coinPublic($0.0) }
    }

    // MARK: ServiceEspeces

    /// Avec une couche de coins publics : seuls de vrais coins sont rendus (`eau` porte le nom du coin, à défaut l'eau de la station),
    /// jamais complétés par des stations. Sans couche : les stations OFB, comme avant.
    public func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin] {
        guard aDesCoins else { return base.coins(ou: espece, pres: coordonnee) }
        return coinsProches(ou: espece, pres: coordonnee).map {
            Coin(codeStation: $0.codeStation, eau: $0.nom ?? $0.eauStation, departement: $0.departement, coordonnee: $0.coordonnee,
                 distanceM: $0.distanceM, nPeches: $0.nPeches, annee: $0.annee, ouverture: $0.ouverture)
        }
    }

    public func rarete(espece: Espece, departement: Departement) -> ResultatRarete { base.rarete(espece: espece, departement: departement) }
    public func especesProches(_ coordonnee: Coordonnee) -> [EspeceProche] { base.especesProches(coordonnee) }
    public func stationsDans(_ region: RegionCarte) -> [StationOFB] { base.stationsDans(region) }
    public func especesPechables() -> [EspecePechable] { base.especesPechables() }
    public func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] {
        base.classer(scores: scores, especesProches: especesProches)
    }
    public func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? { base.poidsEstime(espece: espece, longueurCm: longueurCm) }
}

extension MoteurCore {
    /// Les coins publics des données embarquées : `Resources/coins-osm.geojson`.
    /// L'app branche L7 sur ce moteur : `OuChercherVue(coins: core.coins(), ...)`. Il remplace `core.especes` là où E3 veut de vrais coins.
    public func coins() -> MoteurCoins {
        MoteurCoins(especes: especes, donneesOSM: Ressources.donnees("coins-osm", extension: "geojson"))
    }

    /// Les mêmes coins à partir des octets d'un `coins-osm.geojson` donné (tests).
    public func coins(donneesOSM: Data?) -> MoteurCoins {
        MoteurCoins(especes: especes, donneesOSM: donneesOSM)
    }
}

/// Faux de coins publics pour les aperçus et les tests d'écran : un seul coin d'essai, les espèces du faux d'espèces.
public struct CoinsFaux: ServiceEspeces, ServiceCoinsPublics {
    private let base = EspecesFaux()

    public init() {}

    public func coinsProches(ou espece: Espece, pres coordonnee: Coordonnee) -> [CoinProche] {
        [CoinProche(id: "node/essai", nom: "Quai d'essai", type: .peche, acces: .libre, payant: false, departement: Departement(code: "94"),
                    coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4), distanceM: 1200, codeStation: "STATION-ESSAI",
                    eauStation: "La Marne", distanceStationM: 400, nPeches: 9, annee: 2024, ouverture: .ouverte)]
    }

    public func coinsPublicsDans(_ region: RegionCarte) -> [CoinPublic] { [] }
    public func coinsPublics(pres coordonnee: Coordonnee, rayonM: Double) -> [CoinPublic] { [] }

    public func rarete(espece: Espece, departement: Departement) -> ResultatRarete { base.rarete(espece: espece, departement: departement) }
    public func especesProches(_ coordonnee: Coordonnee) -> [EspeceProche] { base.especesProches(coordonnee) }
    public func coins(ou espece: Espece, pres coordonnee: Coordonnee) -> [Coin] { base.coins(ou: espece, pres: coordonnee) }
    public func especesPechables() -> [EspecePechable] { base.especesPechables() }
    public func classer(scores: [String: Double], especesProches: [Espece]) -> [Proposition] {
        base.classer(scores: scores, especesProches: especesProches)
    }
    public func poidsEstime(espece: Espece, longueurCm: Double) -> PoidsEstime? { base.poidsEstime(espece: espece, longueurCm: longueurCm) }
}
