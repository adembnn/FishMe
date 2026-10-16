import Foundation
import MapKit
import Observation
import SwiftUI
import Core

@MainActor
@Observable
final class ModeleCarte {
    let services: ServicesCarte

    // Départ
    var depart: DepartCarte = .enAttente
    var message: String?
    var afficherChoixDeZone = false
    var afficherRedemande = false

    // Carte
    var camera: MapCameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
                                                                span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13)))
    var regionVisible: ZoneCarte = .france
    var elements: [ElementCarte] = []
    var animees: [StationAnimee] = []
    var enMouvement = false

    // Données
    var pechables: [EspecePechable] = []
    private(set) var stations: [StationCarte] = []

    // Filtre « Choisir un autre spot »
    var filtre: EspecePechable?
    var coinsFiltres: [Coin] = []
    var afficherFiltre = false

    // Spot gratuit
    var spotFixe: Spot?
    var sessionsTerminees = 0
    private(set) var spotLocal: Spot?
    var modeChoixDuSpot = false

    var selection: CoinSelectionne?

    @ObservationIgnored private var tacheElements: Task<Void, Never>?
    @ObservationIgnored private var tacheAnimees: Task<Void, Never>?
    @ObservationIgnored private var tacheStations: Task<Void, Never>?

    init(services: ServicesCarte) {
        self.services = services
    }

    var spotAffiche: Spot? { spotFixe ?? spotLocal }
    /// « changer de spot » n'existe qu'avant la 1re session : après, le cercle reste (L5 le fixe).
    var peutChangerDeSpot: Bool { sessionsTerminees == 0 && spotFixe == nil }

    var imagesParEspece: [String: String] {
        Dictionary(pechables.map { ($0.espece.id, $0.image) }, uniquingKeysWith: { premier, _ in premier })
    }

    func pechable(_ espece: Espece) -> EspecePechable? {
        pechables.first { $0.espece == espece }
    }

    // MARK: Démarrage

    func demarrer() async {
        pechables = await lirePechables()
        charger(pour: regionVisible)
    }

    private func lirePechables() async -> [EspecePechable] {
        let especes = services.especes
        return await Task.detached { especes.especesPechables() }.value
    }

    /// Une position arrive (ou n'arrive pas) : on centre la carte, on propose le spot, ou on tombe sur Paris hors de France.
    func appliquer(position: Coordonnee?, refusee: Bool) {
        if let position {
            if services.geo.departement(de: position).estInconnu {
                depart = .horsDeFrance
                message = "Pas de relevé OFB près de toi : voici Paris et l'Île-de-France."
                centrer(.parisIleDeFrance)
                proposerSpot(pres: ZoneCarte.parisIleDeFrance.centre)
            } else {
                depart = .surLePecheur(position)
                message = nil
                centrer(ZoneCarte(centre: position, spanLatitude: 0.15, spanLongitude: 0.15))
                proposerSpot(pres: position)
            }
        } else if refusee {
            switch depart {
            case .zoneChoisie, .horsDeFrance: return
            default: break
            }
            depart = .choixDeZone
            afficherChoixDeZone = true
        }
    }

    /// Le pêcheur a posé sa zone à la main (sans GPS) : département ou commune.
    func choisirZone(_ c: Coordonnee) {
        if services.geo.departement(de: c).estInconnu {
            depart = .horsDeFrance
            message = "Pas de relevé OFB près de toi : voici Paris et l'Île-de-France."
            centrer(.parisIleDeFrance)
            proposerSpot(pres: ZoneCarte.parisIleDeFrance.centre)
        } else {
            depart = .zoneChoisie(c)
            message = nil
            centrer(ZoneCarte(centre: c, spanLatitude: 0.3, spanLongitude: 0.3))
            proposerSpot(pres: c)
        }
        afficherChoixDeZone = false
    }

    private func centrer(_ region: ZoneCarte) {
        regionVisible = region
        camera = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: region.centre.latitude, longitude: region.centre.longitude),
                                            span: MKCoordinateSpan(latitudeDelta: region.spanLatitude, longitudeDelta: region.spanLongitude)))
        charger(pour: region)
    }

    // MARK: Spot gratuit

    /// Le cercle de 1 km que propose `Core`, près d'une station aux relevés récents. L'écran ne choisit rien lui-même.
    private func proposerSpot(pres c: Coordonnee) {
        guard spotFixe == nil else { return }
        let session = services.session
        Task {
            let spot = await Task.detached { session.spotPropose(coordonnee: c, date: Date()) }.value
            spotLocal = spot
            if spot == nil, message == nil { message = "Aucun relevé OFB à proximité." }
        }
    }

    /// Un toucher sur la rivière pose le cercle (avant la 1re session). Rend le spot pour que A le garde.
    func poserSpot(en c: Coordonnee) -> Spot? {
        guard peutChangerDeSpot else { return nil }
        let departement = services.geo.departement(de: c)
        guard !departement.estInconnu else {
            message = "Hors de France : aucune règle française."
            return nil
        }
        let spot = Spot(centre: c, rayonM: 1000, departement: departement)
        spotLocal = spot
        modeChoixDuSpot = false
        return spot
    }

    // MARK: Stations, regroupement, poissons

    func chargerApresMouvement(_ region: ZoneCarte) {
        regionVisible = region
        enMouvement = false
        charger(pour: region)
    }

    private func charger(pour region: ZoneCarte) {
        tacheStations?.cancel()
        let fournisseur = services.stations
        tacheStations = Task {
            let lues = await fournisseur.stations(dans: region)
            if Task.isCancelled { return }
            stations = lues
            recalculer(region)
        }
    }

    private func recalculer(_ region: ZoneCarte) {
        let points: [PointCarte]
        if filtre != nil {
            points = coinsFiltres.map { PointCarte(id: $0.codeStation, coordonnee: $0.coordonnee) }
        } else {
            points = stations.map { PointCarte(id: $0.code, coordonnee: $0.coordonnee) }
        }
        tacheElements?.cancel()
        tacheElements = Task {
            let calcules = await calculerElements(points: points, region: region)
            if Task.isCancelled { return }
            elements = calcules
        }

        tacheAnimees?.cancel()
        guard filtre == nil else { animees = []; return }
        let toutes = stations
        let especes = services.especes
        let images = imagesParEspece
        tacheAnimees = Task {
            let calculees = await calculerAnimees(stations: toutes, region: region, especes: especes, images: images)
            if Task.isCancelled { return }
            animees = calculees
        }
    }

    // MARK: Sélection

    func toucher(_ element: ElementCarte) {
        switch element {
        case .groupe(_, let c, _):
            centrer(Regroupeur.zoom(sur: c, depuis: regionVisible))
        case .point(let p):
            if let coin = coinsFiltres.first(where: { $0.codeStation == p.id }), filtre != nil {
                selection = CoinSelectionne(id: coin.codeStation, coordonnee: coin.coordonnee, eau: coin.eau, departement: coin.departement, coin: coin)
            } else if let station = stations.first(where: { $0.code == p.id }) {
                selection = CoinSelectionne(id: station.code, coordonnee: station.coordonnee, eau: station.eau, departement: station.departement, coin: nil)
            }
        }
    }

    // MARK: Filtre d'espèce (E3)

    func choisirFiltre(_ espece: EspecePechable?) {
        afficherFiltre = false
        filtre = espece
        guard let espece else {
            coinsFiltres = []
            recalculer(regionVisible)
            return
        }
        let service = services.especes
        let centre = pointDeReference
        Task {
            let coins = await lireCoins(especes: service, espece: espece.espece, pres: centre)
            coinsFiltres = coins
            if coins.isEmpty {
                message = "Aucun relevé de cette espèce près d'ici."
            } else {
                message = nil
                if !coins.contains(where: { regionVisible.contient($0.coordonnee) }), let premier = coins.first {
                    centrer(ZoneCarte(centre: premier.coordonnee, spanLatitude: 0.6, spanLongitude: 0.6))
                }
            }
            recalculer(regionVisible)
        }
    }

    /// Le point autour duquel on cherche : la position ou la zone choisie, sinon le centre de la carte.
    var pointDeReference: Coordonnee {
        switch depart {
        case .surLePecheur(let c), .zoneChoisie(let c): return c
        case .horsDeFrance: return ZoneCarte.parisIleDeFrance.centre
        default: return regionVisible.centre
        }
    }

    /// Les espèces relevées près d'ici d'abord : pour la grille du filtre.
    func especesProchesDIci() -> [Espece] {
        services.especes.especesProches(pointDeReference).map(\.espece)
    }
}
