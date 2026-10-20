import Foundation
import Core

/// Les services de `Core` dont la carte a besoin, passés par A (réels depuis L1, faux de `Core` en DEBUG).
nonisolated struct ServicesCarte: Sendable {
    var geo: any ServiceGeo
    var regles: any ServiceRegles
    var especes: any ServiceEspeces
    var session: any ServiceSession
    var stations: any FournisseurStations
    /// Le niveau de fréquentation des tronçons (gratuit). Valeur par défaut : `compteurParDefaut()`.
    var compteur: any CompteurFrequentation
    /// Les spots d'eau (cours d'eau hors ligne, plans d'eau en ligne) : en plus des stations OFB.
    var spotsEau: any FournisseurSpotsEau

    /// `coinsPublics` : le moteur de coins publics OpenStreetMap de `Core` (`core.coins()`), pour que ces coins deviennent des spots d'eau.
    /// Sans lui, on regarde si `especes` en est un ; sinon la couche se passe des coins publics.
    init(geo: any ServiceGeo, regles: any ServiceRegles, especes: any ServiceEspeces, session: any ServiceSession,
         stations: (any FournisseurStations)? = nil, compteur: (any CompteurFrequentation)? = nil,
         spotsEau: (any FournisseurSpotsEau)? = nil, coinsPublics: (any ServiceCoinsPublics)? = nil) {
        self.compteur = compteur ?? ServicesCarte.compteurParDefaut()
        self.geo = geo
        self.regles = regles
        self.especes = especes
        self.session = session
        self.stations = stations ?? StationsViaCore(especes: especes)
        self.spotsEau = spotsEau ?? SpotsEauReels(coinsPublics: coinsPublics ?? (especes as? any ServiceCoinsPublics))
    }

#if DEBUG
    /// Les faux de `Core` : la carte et la fiche marchent seules, sans L1.
    static func faux() -> ServicesCarte {
        ServicesCarte(geo: GeoFaux(), regles: ReglesFaux(), especes: EspecesFaux(), session: SessionFaux())
    }
#endif
}

/// D'où viennent les stations de la carte.
nonisolated protocol FournisseurStations: Sendable {
    /// Les stations de la zone, hors du fil principal.
    func stations(dans region: ZoneCarte) async -> [StationCarte]
}

/// Adaptateur sur `stationsDans(_:)` de `Core` : une station par point, N pêches et année du dernier relevé tels que
/// `Core` les donne. Rien n'est arrondi ni recalculé ici : les coordonnées sont celles du fichier (recalées par D5, ou arrondies
/// à 0,01° pour une station `recalee == false`). `recalee` est lu quand `Core` le porte, sinon `true` (ancien fichier).
nonisolated final class StationsViaCore: FournisseurStations, Sendable {
    private let especes: any ServiceEspeces

    init(especes: any ServiceEspeces) {
        self.especes = especes
    }

    @concurrent
    func stations(dans region: ZoneCarte) async -> [StationCarte] {
        // Une demi-zone de marge de chaque côté : le glissement court ne recharge pas.
        let demiLat = region.spanLatitude / 2 * 1.5
        let demiLon = region.spanLongitude / 2 * 1.5
        let zone = RegionCarte(
            sudOuest: Coordonnee(latitude: region.centre.latitude - demiLat, longitude: region.centre.longitude - demiLon),
            nordEst: Coordonnee(latitude: region.centre.latitude + demiLat, longitude: region.centre.longitude + demiLon))
        return especes.stationsDans(zone).map { station in
            StationCarte(code: station.codeStation, eau: station.eau, departement: station.departement,
                         coordonnee: station.coordonnee,
                         releves: station.especes.map { ReleveEspece(espece: $0.espece, nPeches: $0.nPeches, annee: $0.annee) },
                         recalee: LectureRecalage.valeur(de: station))
        }
        .sorted { $0.code < $1.code }
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
