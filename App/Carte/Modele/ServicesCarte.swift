import Foundation
import Core

/// Les services de `Core` dont la carte a besoin, passés par A (réels depuis L1, faux de `Core` en DEBUG).
nonisolated struct ServicesCarte: Sendable {
    var geo: any ServiceGeo
    var regles: any ServiceRegles
    var especes: any ServiceEspeces
    var session: any ServiceSession
    var stations: any FournisseurStations

    init(geo: any ServiceGeo, regles: any ServiceRegles, especes: any ServiceEspeces, session: any ServiceSession,
         stations: (any FournisseurStations)? = nil) {
        self.geo = geo
        self.regles = regles
        self.especes = especes
        self.session = session
        self.stations = stations ?? StationsViaCore(especes: especes)
    }

#if DEBUG
    /// Les faux de `Core` : la carte et la fiche marchent seules, sans L1.
    static func faux() -> ServicesCarte {
        ServicesCarte(geo: GeoFaux(), regles: ReglesFaux(), especes: EspecesFaux(), session: SessionFaux())
    }
#endif
}

/// D'où viennent les stations de la carte. `Core` ne donne pas encore « les stations dans une zone » :
/// l'adaptateur par défaut les rassemble depuis `coins(ou:pres:)` (voir `StationsViaCore`).
nonisolated protocol FournisseurStations: Sendable {
    /// Les stations de la zone, hors du fil principal.
    func stations(dans region: RegionCarte) async -> [StationCarte]
}

/// Adaptateur sur les contrats de `Core` : toutes les espèces suivies par l'OFB, un appel de `coins(ou:pres:)` chacune,
/// fusionnés par station. Gardé en mémoire après la première lecture. Hypothèse à vérifier : `coins` rend toutes les stations
/// de l'espèce, pas seulement les plus proches (sinon il faut `stationsDans(region)` dans `Core`, à demander à B).
nonisolated final class StationsViaCore: FournisseurStations, @unchecked Sendable {
    private let especes: any ServiceEspeces
    private let verrou = NSLock()
    private var cache: [StationCarte]?

    init(especes: any ServiceEspeces) {
        self.especes = especes
    }

    @concurrent
    func stations(dans region: RegionCarte) async -> [StationCarte] {
        let toutes = chargerOuLire()
        return toutes.filter { region.contient($0.coordonnee, marge: 0.5) }
    }

    private func chargerOuLire() -> [StationCarte] {
        verrou.lock()
        if let cache { verrou.unlock(); return cache }
        verrou.unlock()

        let centre = RegionCarte.france.centre
        var parStation: [String: StationCarte] = [:]
        for pechable in especes.especesPechables() where pechable.suiviOFB {
            for coin in especes.coins(ou: pechable.espece, pres: centre) {
                let releve = ReleveEspece(espece: pechable.espece, nPeches: coin.nPeches, annee: coin.annee, ouverture: coin.ouverture)
                if var existante = parStation[coin.codeStation] {
                    existante.releves.append(releve)
                    parStation[coin.codeStation] = existante
                } else {
                    parStation[coin.codeStation] = StationCarte(code: coin.codeStation, eau: coin.eau, departement: coin.departement,
                                                                coordonnee: coin.coordonnee, releves: [releve])
                }
            }
        }
        let resultat = parStation.values.sorted { $0.code < $1.code }
        verrou.lock()
        cache = resultat
        verrou.unlock()
        return resultat
    }
}

/// Distance en mètres entre deux points (formule de haversine) : de la géométrie, pas de la logique métier.
nonisolated func distanceMetres(_ a: Coordonnee, _ b: Coordonnee) -> Double {
    let rayon = 6_371_000.0
    let p1 = a.latitude * .pi / 180
    let p2 = b.latitude * .pi / 180
    let dp = (b.latitude - a.latitude) * .pi / 180
    let dl = (b.longitude - a.longitude) * .pi / 180
    let h = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2)
    return 2 * rayon * asin(min(1, sqrt(h)))
}
