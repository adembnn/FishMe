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
    /// Vrai dès que la carte est posée sur une zone utile (spot, zone choisie, position ou dernière vue) : jamais la France entière.
    private(set) var cameraPlacee = false

    // Données
    var pechables: [EspecePechable] = []
    private(set) var stations: [StationCarte] = []
    /// La zone dont les stations sont chargées (ou en cours de chargement) : sert à ne pas relire ce qui est déjà là.
    private(set) var regionChargee: ZoneCarte?
    /// Vrai pendant la lecture des stations (la carte montre alors le sonar).
    private(set) var chargementEnCours = false

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

    // Fréquentation : le niveau connu de chaque tronçon lu (en mots, jamais un nombre).
    private(set) var niveauxConnus: [String: NiveauFrequentation] = [:]

    @ObservationIgnored private var tacheElements: Task<Void, Never>?
    @ObservationIgnored private var tacheStations: Task<Void, Never>?
    /// Le premier « fin de mouvement » de la caméra est l'affichage initial, pas un geste du pêcheur.
    @ObservationIgnored private var premiereCameraAttendue = true
    /// Dossier du cache des stations du dernier lancement (Caches de l'app). `nil` : pas de cache (tests).
    @ObservationIgnored private let dossierCache: URL?

    /// Où l'on garde la dernière zone choisie à la main (sur l'iPhone seulement). `nil` : rien n'est gardé (tests).
    @ObservationIgnored private let reglages: UserDefaults?
    private static let cleZone = "carte.derniereZoneChoisie"

    /// L'étendue d'ouverture autour d'un spot ou d'une position (environ 15 km) : les stations y sont lisibles une à une.
    static let etendueOuverture = 0.14
    /// L'étendue autour d'une zone choisie à la main (département ou commune).
    static let etendueZone = 0.35

    init(services: ServicesCarte, dossierCache: URL? = StockageCacheCarte.dossierParDefaut, reglages: UserDefaults? = .standard) {
        self.services = services
        self.dossierCache = dossierCache
        self.reglages = reglages
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

    /// La carte s'affiche tout de suite. On ne lit plus la France entière au départ : on montre les stations du dernier lancement
    /// (cache local), on les rafraîchit, et la position (ou la zone choisie) charge sa zone dès qu'elle arrive.
    func demarrer() async {
        placerALOuverture()
        pechables = await lirePechables()
        await restaurerDepuisCache()
    }

    /// La caméra d'ouverture : le spot fixé, sinon la dernière zone choisie à la main. La position, si elle arrive, prend le relais.
    func placerALOuverture() {
        guard !cameraPlacee else { return }
        if let spot = spotFixe {
            centrer(ZoneCarte(centre: spot.centre, spanLatitude: Self.etendueOuverture, spanLongitude: Self.etendueOuverture))
        } else if let zone = zoneGardee, !services.geo.departement(de: zone).estInconnu {
            depart = .zoneChoisie(zone)
            centrer(ZoneCarte(centre: zone, spanLatitude: Self.etendueZone, spanLongitude: Self.etendueZone))
            proposerSpot(pres: zone)
        }
    }

    /// Le spot fixé vient d'arriver (session ou fin de la 1re session) : la carte s'y pose.
    func recevoir(spotFixe nouveau: Spot?) {
        let avant = spotFixe
        spotFixe = nouveau
        if let nouveau, avant == nil {
            centrer(ZoneCarte(centre: nouveau.centre, spanLatitude: Self.etendueOuverture, spanLongitude: Self.etendueOuverture))
        }
    }

    private var zoneGardee: Coordonnee? {
        guard let reglages, let t = reglages.array(forKey: Self.cleZone) as? [Double], t.count == 2 else { return nil }
        return Coordonnee(latitude: t[0], longitude: t[1])
    }

    /// Aucune position ne vient (refus ou échec) et rien n'a posé la carte : le pêcheur choisit son département ou sa commune.
    func positionIndisponible() {
        guard !cameraPlacee, depart == .enAttente else { return }
        depart = .choixDeZone
        afficherChoixDeZone = true
    }

    private func restaurerDepuisCache() async {
        guard let dossier = dossierCache else { return }
        let cache = await Task.detached(priority: .userInitiated) {
            StockageCacheCarte.lire(dans: dossier, maintenant: Date())
        }.value
        // Si la position ou une zone est déjà là, elle est plus fraîche que le cache.
        guard let cache, depart == .enAttente, regionChargee == nil, !cameraPlacee else { return }
        cameraPlacee = true
        regionVisible = cache.region
        camera = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: cache.region.centre.latitude, longitude: cache.region.centre.longitude),
            span: MKCoordinateSpan(latitudeDelta: cache.region.spanLatitude, longitudeDelta: cache.region.spanLongitude)))
        stations = cache.stations
        regionChargee = cache.region
        recalculer(cache.region)
        charger(pour: cache.region)
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
                // Pendant une session (spot fixé), la carte reste sur le spot : la position ne la déplace pas.
                if spotFixe == nil {
                    centrer(ZoneCarte(centre: position, spanLatitude: Self.etendueOuverture, spanLongitude: Self.etendueOuverture))
                }
                proposerSpot(pres: position)
            }
        } else if refusee {
            switch depart {
            case .zoneChoisie, .horsDeFrance: return
            default: break
            }
            // Spot fixé ou dernière vue déjà à l'écran : rien à redemander.
            if cameraPlacee { return }
            depart = .choixDeZone
            afficherChoixDeZone = true
        }
    }

    /// « Autour de moi » : la carte va sur la position de l'iPhone, même quand un spot est fixé ailleurs.
    func centrerSurMaPosition(_ position: Coordonnee) {
        appliquer(position: position, refusee: false)
        if case .surLePecheur = depart {
            centrer(ZoneCarte(centre: position, spanLatitude: Self.etendueOuverture, spanLongitude: Self.etendueOuverture))
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
            reglages?.set([c.latitude, c.longitude], forKey: Self.cleZone)
            centrer(ZoneCarte(centre: c, spanLatitude: Self.etendueZone, spanLongitude: Self.etendueZone))
            proposerSpot(pres: c)
        }
        afficherChoixDeZone = false
    }

    private func centrer(_ region: ZoneCarte) {
        cameraPlacee = true
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
        let niveau = ReglagesFrequentation.niveauPecheur()
        let graine = ReglagesFrequentation.graine()
        Task {
            let spot = await Task.detached { () -> Spot? in
                // Répartition (docs/frequentation.md) : le spot est tiré parmi les meilleures stations, selon la graine de l'iPhone.
                if let reparti = (session as? any ServiceRepartition)?.spotPropose(coordonnee: c, date: Date(), niveau: niveau, graine: graine) {
                    return reparti
                }
                return session.spotPropose(coordonnee: c, date: Date())
            }.value
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

    // MARK: Fréquentation (gratuit, en mots seulement)

    private var repartition: (any ServiceRepartition)? { services.session as? any ServiceRepartition }

    /// Le tronçon d'un spot : la station OFB la plus proche (5 km au plus).
    func troncon(de spot: Spot) -> String? {
        repartition?.troncon(de: spot)
    }

    /// Lit le niveau d'un tronçon et le garde ; `nil` : rien n'est affiché.
    func chargerNiveau(troncon: String) async {
        let niveau = await services.compteur.niveau(troncon: troncon, aujourdhui: Date())
        niveauxConnus[troncon] = niveau
    }

    /// Le niveau du tronçon du spot affiché, quand on le connaît.
    var niveauDuSpot: NiveauFrequentation? {
        guard let spot = spotAffiche, let t = troncon(de: spot) else { return nil }
        return niveauxConnus[t]
    }

    /// Au démarrage d'une session : un passage anonyme (tronçon, jour, jeton du jour), gardé sur l'iPhone.
    func enregistrerPassage(spot: Spot, maintenant: Date = Date()) {
        guard let t = troncon(de: spot) else { return }
        let jour = JetonDuJour.jour(maintenant)
        let passage = Passage(troncon: t, jour: jour, jeton: JetonDuJour.jeton(graine: ReglagesFrequentation.graine(), jour: jour))
        let compteur = services.compteur
        Task { await compteur.enregistrer(passage) }
    }

    /// « Coin plus calme » : un spot éligible dont le tronçon n'est pas chargé ; `nil` : pas de bouton.
    func chercherCoinCalme(depuis spot: Spot) async -> Spot? {
        guard let reparti = repartition else { return nil }
        let connus = niveauxConnus
        let niveau = ReglagesFrequentation.niveauPecheur()
        let maintenant = Date()
        return await Task.detached { () -> Spot? in
            reparti.coinCalme(depuis: spot, date: maintenant, niveau: niveau, estCharge: { connus[$0] == .charge })
        }.value
    }

    /// Le spot calme devient le spot affiché, comme un toucher sur la rivière (avant la 1re session seulement).
    func adopterCoinCalme(depuis spot: Spot) {
        guard peutChangerDeSpot else { return }
        Task {
            guard let calme = await chercherCoinCalme(depuis: spot) else { return }
            spotLocal = calme
            selection = nil
            modeChoixDuSpot = false
            centrer(ZoneCarte(centre: calme.centre, spanLatitude: Self.etendueOuverture, spanLongitude: Self.etendueOuverture))
        }
    }

    /// Les tronçons chargés pour lesquels un coin plus calme existe : le bouton n'apparaît que pour eux.
    private(set) var tronconsAvecCoinCalme: Set<String> = []

    /// Vérifie, pour un tronçon chargé, qu'un coin plus calme existe avant d'afficher le bouton.
    func verifierCoinCalme(troncon: String, spot: Spot) async {
        guard peutChangerDeSpot, niveauxConnus[troncon] == .charge else {
            tronconsAvecCoinCalme.remove(troncon)
            return
        }
        if await chercherCoinCalme(depuis: spot) != nil {
            tronconsAvecCoinCalme.insert(troncon)
        } else {
            tronconsAvecCoinCalme.remove(troncon)
        }
    }

    /// Niveau et coin calme d'un spot : appelé quand le spot affiché change.
    func rafraichirFrequentation(spot: Spot) async {
        guard let t = troncon(de: spot) else { return }
        await chargerNiveau(troncon: t)
        await verifierCoinCalme(troncon: t, spot: spot)
    }

    /// Niveau et coin calme d'une station touchée sur la carte (la fiche d'un coin).
    func rafraichirFrequentation(selection: CoinSelectionne) async {
        await chargerNiveau(troncon: selection.id)
        await verifierCoinCalme(troncon: selection.id, spot: spot(de: selection))
    }

    /// Le spot d'une station touchée sur la carte, pour chercher un coin plus calme depuis la fiche.
    func spot(de selection: CoinSelectionne) -> Spot {
        Spot(centre: selection.coordonnee, rayonM: 1000,
             departement: selection.departement ?? services.geo.departement(de: selection.coordonnee))
    }

    // MARK: Stations, regroupement, poissons

    func chargerApresMouvement(_ region: ZoneCarte) {
        regionVisible = region
        let premiere = premiereCameraAttendue
        premiereCameraAttendue = false
        // Affichage initial sans position ni cache : on n'ira pas lire toute la France pour rien.
        if premiere, depart == .enAttente { return }
        // Zone déjà couverte par le dernier chargement : on regroupe seulement (calcul court, hors du fil principal).
        if let deja = regionChargee, region.estCouverte(parChargee: deja) {
            recalculer(region)
            return
        }
        charger(pour: region)
    }

    private func charger(pour region: ZoneCarte) {
        tacheStations?.cancel()
        regionChargee = region
        chargementEnCours = true
        let fournisseur = services.stations
        let dossier = dossierCache
        tacheStations = Task {
            let lues = await fournisseur.stations(dans: region)
            if Task.isCancelled { return }
            stations = lues
            chargementEnCours = false
            recalculer(region)
            // Pour le prochain lancement : seulement une vue assez proche (petit fichier), en tâche de fond.
            if let dossier, region.spanLatitude <= StockageCacheCarte.etendueMaximale, !lues.isEmpty {
                let cache = CacheCarte.pour(region: region, stations: lues)
                Task.detached(priority: .utility) { StockageCacheCarte.ecrire(cache, dans: dossier) }
            }
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
