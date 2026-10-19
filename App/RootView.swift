//
//  RootView.swift
//  BuildChallenge
//
//  A seul. Seul endroit qui connaît plusieurs dossiers de l'app (docs/architecture.md, « RootView »).
//  3 volets (Pescedex, Carte, Mon club), ouverture sur Carte (docs/architecture.md l.13, docs/lots.md l.7).
//

import Core
import Observation
import SwiftData
import SwiftUI

// MARK: - Navigation

enum Onglet: Hashable {
    case pescedex, carte, club
}

/// Un seul écran modal à la fois, les suivants attendent : jamais deux feuilles ensemble (« jamais deux à la fois », docs/lots.md L0).
enum Modal: Identifiable, Equatable {
    case tunnel
    case consentement
    case paywall(DeclencheurPaywall)
    case prise
    case carteAEssayer(Spot)
    /// Fin de session (P16) ; la sortie montrée est `ParcoursApp.finAffichee`.
    case finSession
    case mesSorties
    case reglages

    var id: String {
        switch self {
        case .tunnel: "tunnel"
        case .consentement: "consentement"
        case .paywall(let d): "paywall-\(d.valeurMesure)"
        case .prise: "prise"
        case .carteAEssayer: "carte-a-essayer"
        case .finSession: "fin-session"
        case .mesSorties: "mes-sorties"
        case .reglages: "reglages"
        }
    }
}

/// Une demande de paywall faite depuis une feuille déjà ouverte (fiche d'un coin) : la feuille la présente elle-même.
struct PaywallDemande: Identifiable {
    let declencheur: DeclencheurPaywall
    var id: String { declencheur.valeurMesure }
}

/// La carte révélée après une prise (E6).
struct CarteRevelee: Identifiable {
    let id = UUID()
    let infos: InfosCarte
    let photo: Data?
}

// MARK: - Chargement hors du fil principal

/// Ce qui est lourd à construire au lancement : le moteur de Core (règles, espèces, stations) et le conteneur SwiftData.
nonisolated struct Chargement: Sendable {
    let core: MoteurCore
    let conteneur: ModelContainer?

    /// À appeler hors du fil principal.
    /// `dossierRegles` est lu sur le fil principal avant l'appel (`ReglesAJour` y est isolé).
    static func preparer(dossierRegles: URL?) -> Chargement {
        let core = MoteurCore(donnees: .embarque(dossierFabriques: Bundle.main.resourceURL, reglesTelechargees: dossierRegles))
        let conteneur = (try? DepotCartes.creerConteneur()) ?? (try? DepotCartes.creerConteneur(enMemoire: true))
        return Chargement(core: core, conteneur: conteneur)
    }
}

// MARK: - Assemblage et parcours

@MainActor @Observable
final class ParcoursApp {
    // Services
    @ObservationIgnored let core: MoteurCore
    /// L7 : un seul moteur de coins, pour garder son index chaud d'une ouverture à l'autre.
    @ObservationIgnored private(set) lazy var coins = core.coins()
    @ObservationIgnored let servicesCarte: ServicesCarte
    @ObservationIgnored let servicesPrise: PriseServices
    @ObservationIgnored let conseils: any ServiceConseils
    @ObservationIgnored let conditions: ConditionsDuSpot
    @ObservationIgnored let marque: StockageMarque
    @ObservationIgnored let previensMoi: PreviensMoiModele
    @ObservationIgnored let mesure: CoucheMesure
    @ObservationIgnored let achats: AchatsStoreKit
    /// L10 : Live Activity de l'écran verrouillé.
    @ObservationIgnored let ecranVerrouille = PilotageActivite()

    /// L4 : le dépôt des cartes, créé une seule fois (SwiftData local, photos sans GPS dans Application Support).
    /// `nil` seulement si SwiftData ne s'ouvre ni sur disque ni en mémoire : le volet Pescedex reste alors vide.
    @ObservationIgnored let depot: DepotCartes?
    let pescedex: PescedexModele?
    /// Cartes rendues par L4 pour le partage de L9 (recto seul, sans météo).
    var cartesAPartager: [CarteAPartager] = []

    /// L8 : les amis (CloudKit), créés au premier passage sur l'écran Amis, jamais au lancement.
    @ObservationIgnored private var gestionAmisCreee: GestionAmis?

    let moteur: SuiviSession
    let suivi: SuiviAbonnement

    /// Compte : la sauvegarde iCloud des cartes, des photos et du profil (App/Compte). `nil` sans dépôt.
    @ObservationIgnored private(set) lazy var sauvegarde: SauvegardeICloud? = SauvegardeICloud.actif ? depot.map { SauvegardeICloud(depot: $0) } : nil
    @ObservationIgnored private(set) lazy var compte: CompteModele? = sauvegarde.map { service in
        CompteModele(service: service,
                     restaurerAchats: { [weak self] in
                         guard let self else { return false }
                         let etat = await self.achats.restaurer()
                         self.etatAchatsLu(etat)
                         return etat.donneAcces
                     },
                     surRapatriement: { [weak self] in await self?.apresRapatriement() })
    }
    @ObservationIgnored private var sauvegardePrevue: Task<Void, Never>?

    // État de navigation
    var onglet: Onglet = .carte
    var courant: Modal?
    /// E6 : la carte d'une prise qui vient d'être enregistrée, révélée en plein écran.
    var carteRevelee: CarteRevelee?
    private var attente: [Modal] = []
    var positionPassee = false
    /// Le choix de zone (position refusée) ou la redemande est à l'écran : aucune autre feuille ne s'ouvre en même temps.
    var choixDeZoneOuvert = false
    var volDemande = false
    var sessionReduite = false
    var consentement: Consentement
    private var carteListeEnvoyee = false
    @ObservationIgnored private var rendu: Task<Void, Never>?

    /// P16 : la sortie que la feuille de fin montre (la dernière session, ou une ancienne choisie dans « Mes sorties »).
    var finAffichee: FinDeSession?
    var finLieu: String?
    /// P42 : la position était déjà refusée au lancement, l'écran « Ta zone » remplace la carte jusqu'à « Voir la carte ».
    var sansPositionAffiche = false

    // Spot
    var spotCourant: Spot?
    private var spotSession: Spot?
    private var spotEnAttente: Spot?
    /// Position GPS du moment, seulement pour le verdict d'une prise : jamais enregistrée.
    @ObservationIgnored let gps = GestionPosition()

    /// Le moteur de Core et le conteneur SwiftData sont construits hors du fil principal (`Chargement.preparer`), pas ici :
    /// la lecture des fichiers de règles et de stations bloquait le premier rendu 15 à 20 s.
    init(chargement: Chargement, configurerMesure: @escaping @MainActor @Sendable () -> Void) {
        let core = chargement.core
        self.core = core
        servicesCarte = ServicesCarte(geo: core.geo, regles: core.regles, especes: core.especes, session: core.session,
                                     coinsPublics: core.coins())
        // Reconnaissance : modèle DINOv2 embarqué (App/Prise/Modele), sous 0,4 de confiance la grille des espèces s'ouvre.
        servicesPrise = PriseServices(especes: core.especes, regles: core.regles, identification: IdentificationDino())
        // Si conseils.json ne se charge pas : aucun conseil en vrai, le faux seulement en DEBUG (à vérifier sur le Mac).
        #if DEBUG
        let repli: any ServiceConseils = ConseilsFaux()
        #else
        let repli: any ServiceConseils = ConseilsVides()
        #endif
        conseils = (try? ConseilsParEspece.charger(regles: core.regles)) ?? repli
        conditions = ConditionsDuSpot(meteo: SourceWeatherKit(), eau: core.niveauEau, noyau: core.conditions)
        marque = StockageMarque(source: SourceMarqueWeatherKit())
        previensMoi = PreviensMoiModele(notifieur: NotifieurSysteme())

        let servicesCollection = ServicesCollection(especes: core.especes, soleil: core.soleil, regles: core.regles)
        if let conteneur = chargement.conteneur {
            let depot = DepotCartes(conteneur: conteneur, dossierPhotos: DepotCartes.dossierParDefaut(), services: servicesCollection)
            self.depot = depot
            pescedex = PescedexModele(depot: depot, services: servicesCollection)
        } else {
            depot = nil
            pescedex = nil
        }

        let mesure = CoucheMesure(passerelle: PasserelleSpark(configuration: configurerMesure),
                                  coffre: CoffreConsentementReglages())
        self.mesure = mesure
        consentement = mesure.etatConsentement
        let achats = AchatsStoreKit(surAchat: { resultat in await mesure.enregistrerAchat(resultat) },
                                    surTransactions: { transactions in await mesure.enregistrerTransactions(transactions) })
        self.achats = achats
        suivi = SuiviAbonnement(achats: achats)
        moteur = SuiviSession(session: core.session, soleil: core.soleil, coffre: TrousseauSpotGratuit())

        moteur.surFin = { [weak self] fin in self?.sessionFinie(fin) }
        sansPositionAffiche = gps.estRefusee
        enregistrerEffaceurs()
    }

    /// Au lancement : l'accord déjà donné configure le SDK, StoreKit écoute, la session est reprise.
    func demarrer() async {
        mesure.demarrerSiAccorde()
        achats.demarrerEcoute()
        suivi.demarrer()
        moteur.abonne = suivi.abonne
        moteur.reprendre()
        if let c = moteur.enCours {
            await ecranVerrouille.reprendre(debut: c.sortie.debut, finLegale: c.finLegale, prises: moteur.nombrePrises)
        }
        // La météo ne retient plus la suite : réseau lent ou WeatherKit absent, on n'attend pas.
        Task { await marque.rafraichir() }
        await rafraichirCollection()
        Task.detached(priority: .utility) { await ReglesAJour.lancer() }
    }

    // MARK: Collection (L4)

    /// L8 : `nil` si le cache local des amis ne s'ouvre pas (l'écran Amis le dit alors).
    func gestionAmis() -> GestionAmis? {
        if let gestionAmisCreee { return gestionAmisCreee }
        // Sans iCloud à l'archivage (clé Info `FishMeICloud` à NO), aucun CKContainer : l'écran Amis dit qu'il est indisponible.
        guard SauvegardeICloud.actif, let depot,
              let conteneur = (try? CacheAmis.creerConteneur()) ?? (try? CacheAmis.creerConteneur(enMemoire: true)) else { return nil }
        let configuration = ConfigurationAmis(contact: ContactClub.adresse)
        let gestion = GestionAmis(service: ServiceAmisCloudKit(configuration: configuration),
                                  cache: CacheAmis(conteneur: conteneur, dossierImages: CacheAmis.dossierParDefaut()),
                                  file: FileEnvoi(dossier: FileEnvoi.dossierParDefaut()),
                                  collection: depot, especes: core.especes, configuration: configuration)
        gestionAmisCreee = gestion
        return gestion
    }

    // MARK: Communauté : profil, fil, messages (L21, L23, L24) // ⚠ à vérifier (écrit sans Mac)

    /// Le mode démo (« Mode démo » du profil, clé `demo.communaute`) : fil et messages d'exemple, lecture seule, rien n'est envoyé.
    var modeDemo: Bool { UserDefaults.standard.bool(forKey: "demo.communaute") }

    /// Ce que le fil et le chat lisent de la racine, en une fois (profil, amis déjà chargés, département du spot, mode démo).
    func instantaneRacine() -> InstantaneRacine {
        let profil = GestionProfil.partage
        let amis = (gestionAmisCreee?.amis ?? []).filter { !$0.enAttente }.map {
            InterlocuteurChat(id: GestionAmis.cleDeBlocage($0), surnom: $0.nom, idCloudKit: $0.id)
        }
        let departement = spotCourant.flatMap { $0.departement.estInconnu ? nil : $0.departement.code }
        return InstantaneRacine(monID: profil.monID, surnom: profil.surnomMemorise, aUnProfil: profil.aUnProfil,
                                amis: amis, departement: departement, demo: modeDemo)
    }

    /// L23 : le fil. Réel (base publique) ; sans compte iCloud ou en mode démo, le fil montre ses publications d'exemple.
    @ObservationIgnored private(set) lazy var feed: GestionFeed = GestionFeed.reel(
        source: SourceFeedRacine(lire: { [weak self] in self?.instantaneRacine() ?? .vide }))

    /// L24 : le vrai chat (CloudKit). La permission de notifier n'est demandée qu'au premier message envoyé.
    @ObservationIgnored private(set) lazy var chatReel: GestionChat = GestionChat(
        service: ServiceChatCloudKit(), annuaire: AnnuaireChatRacine(lire: { [weak self] in self?.instantaneRacine() ?? .vide }),
        stock: StockChat(dossier: StockChat.dossierParDefaut()), permission: PermissionSysteme())
    @ObservationIgnored private(set) lazy var chatExemple: GestionChat = GestionChat.exemple()

    /// Le chat à montrer : l'exemple en mode démo ou sans iCloud (le relecteur d'Apple voit toutes les fonctions), sinon le vrai.
    var chat: GestionChat { (modeDemo || !CloudKitPermisChat.actif) ? chatExemple : chatReel }

    /// « Supprimer mon profil » efface aussi les publications, commentaires et messages : les effaceurs sont enregistrés ici,
    /// créés à la demande (pas de base SwiftData du fil au lancement).
    private func enregistrerEffaceurs() {
        guard RegistreEffaceurs.partage.effaceurs.isEmpty else { return }
        RegistreEffaceurs.partage.ajouter(EffaceurParesseux { [weak self] in
            guard let self else { throw ErreurProfil.reseau }
            return EffaceurFeed(gestion: self.feed)
        })
        RegistreEffaceurs.partage.ajouter(EffaceurParesseux { [weak self] in
            guard let self else { throw ErreurProfil.reseau }
            return EffaceurChat(gestion: self.chatReel)
        })
    }

    /// Un message CloudKit silencieux est arrivé (délégué d'application) : le chat se rafraîchit, une alerte locale prévient si besoin.
    func notificationCloudKitRecue() async {
        guard !modeDemo, CloudKitPermisChat.actif else { return }
        await chatReel.traiterNotificationCloudKit()
    }

    /// Recharge le Pescedex et les cartes partageables de L9 après une écriture dans le dépôt.
    func rafraichirCollection() async {
        guard let depot else { return }
        // Mode démo : les cartes d'exemple (vraies photos sous licence libre) s'installent ou se retirent ici.
        _ = await DemoPescedex.synchroniser(demo: UserDefaults.standard.bool(forKey: DemoPescedex.cle), depot: depot)
        await pescedex?.charger()
        publierAquarium()
        rendrePartagesEnFond(depot: depot)
        prevoirSauvegarde()
    }

    // MARK: Compte (sauvegarde iCloud)

    /// Sauvegarde en fond quelques secondes après une écriture (et au lancement) ; un nouvel appel repousse la précédente.
    /// Sans iCloud, rien ne part et rien ne bloque : l'app marche pareil, hors ligne et sans compte.
    private func prevoirSauvegarde() {
        guard let sauvegarde else { return }
        sauvegardePrevue?.cancel()
        sauvegardePrevue = Task(priority: .utility) { [weak self] in
            try? await Task.sleep(for: .seconds(5))
            if Task.isCancelled || UserDefaults.standard.bool(forKey: SauvegardeICloud.cleCoupee) { return }
            guard await sauvegarde.etatCompte() == .disponible,
                  let bilan = try? await sauvegarde.synchroniser() else { return }
            if bilan.aRelire { await self?.apresRapatriement() }
        }
    }

    /// Des cartes ou un profil sont revenus d'iCloud (nouvel iPhone) : Pescedex, aquarium et sorties se relisent.
    func apresRapatriement() async {
        await pescedex?.charger()
        publierAquarium()
        if let depot { rendrePartagesEnFond(depot: depot) }
        moteur.reprendre()
    }

    /// Rend les PNG du partage (L9) en fond, une carte à la fois, quelques secondes après l'affichage :
    /// plus de rendu d'image au lancement. Un nouvel appel annule le rendu en cours.
    private func rendrePartagesEnFond(depot: DepotCartes) {
        rendu?.cancel()
        let especes = core.especes
        rendu = Task(priority: .utility) { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            let noms = Dictionary(especes.especesPechables().map { ($0.espece, $0.nom) }, uniquingKeysWith: { a, _ in a })
            var cartes: [CarteAPartager] = []
            for prise in await depot.cartes() {
                if Task.isCancelled { return }
                if let png = await depot.imagePNG(de: prise) {
                    cartes.append(CarteAPartager(id: prise.id.uuidString, titre: noms[prise.espece] ?? "Carte FishMe", png: png))
                }
                await Task.yield()
            }
            if Task.isCancelled { return }
            self?.cartesAPartager = cartes
        }
    }

    // MARK: Widget aquarium (L15)

    /// Donne au widget les poissons du Pescedex (les plus rares d'abord, sans carte d'exemple ni bredouille, 12 au plus),
    /// le nombre d'espèces et l'abonnement. Les cartes déclarées (swipe du tunnel) comptent comme les autres.
    func publierAquarium() {
        guard let pescedex else { return }
        let reelles = pescedex.detaillees.map(\.prise).filter { !$0.exemple }
        let poissons: [InstantaneAquarium.Poisson] = pescedex.emplacements.compactMap { e in
            guard let carte = e.carte, !carte.exemple else { return nil }
            let rarete: Int
            switch e.rarete.niveau {
            case .commun, .nonMesuree: rarete = 0
            case .peuCommun: rarete = 1
            case .rare: rarete = 2
            case .legendaire: rarete = 3
            }
            let nombre = reelles.filter { $0.espece.id == e.espece.espece.id }.count
            return InstantaneAquarium.Poisson(id: carte.id.uuidString, slug: e.espece.espece.id, rarete: rarete,
                                              relache: !carte.gardee, nombre: nombre)
        }
        .sorted { $0.rarete > $1.rarete }
        PontAquariumWidget.publier(poissons: Array(poissons.prefix(InstantaneAquarium.plafond)),
                                   especes: poissons.count, estPro: suivi.abonne)
    }

    // MARK: Décors de l'aquarium (N1) // ⚠ à vérifier (écrit sans Mac)

    /// Le contexte de la règle des décors : date (Paris), Pro, progression. Rien d'autre ne sort de l'iPhone (aucun lieu).
    func contexteSkin() -> ContexteSkin {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        let reelles = (pescedex?.emplacements ?? []).filter { e in e.carte.map { !$0.exemple } ?? false }
        let legendaires = reelles.filter { $0.rarete.niveau == .legendaire }.count
        return ContexteSkin(date: Date(), calendrier: calendrier, abonne: suivi.abonne,
                            progression: ProgressionPecheur(especesDifferentes: reelles.count,
                                                            sessions: moteur.sortiesTerminees.count,
                                                            legendairesPris: legendaires))
    }

    /// Le décor à dessiner et à publier : le choix enregistré, corrigé par la règle (un décor de saison fini ou le Pro perdu
    /// ramène au dernier décor gagné, sinon au décor de départ).
    func skinAffiche() -> IdentifiantSkin {
        ChoixSkin.affiche(brut: UserDefaults.standard.string(forKey: ChoixSkin.cle) ?? "", contexte: contexteSkin())
    }

    /// Liens `fishme://` du widget. `pro?source=widget` : paywall ; `aquarium` : le volet Pescedex (L14 absent).
    func ouvrir(url: URL) {
        guard url.scheme == "fishme" else { return }
        switch url.host() {
        case "pro":
            if !suivi.abonne { montrer(.paywall(.widget)) }
        case "aquarium":
            onglet = .pescedex
        case "ami":
            // L21 : fishme://ami/<id> ; la page Amis lit le relais et montre le profil.
            if RelaisLienAmi.partage.recevoir(url) { onglet = .club }
        default:
            break
        }
    }

    /// Écrit dans le dépôt puis recharge. Une erreur d'écriture est ignorée sans planter : la carte n'existe pas, rien n'est annoncé.
    /// Renvoie vrai si l'écriture a réussi.
    private func ecrire(_ operation: @escaping @Sendable (DepotCartes) async throws -> Void) async -> Bool {
        guard let depot else { return false }
        do { try await operation(depot) } catch { return false }
        await rafraichirCollection()
        return true
    }

    // MARK: Modales (file d'attente)

    func montrer(_ modal: Modal) {
        if courant == nil { courant = modal } else if courant != modal, !attente.contains(modal) { attente.append(modal) }
    }

    /// Ferme l'écran courant puis ouvre `modal` (jamais deux à la fois).
    func remplacerPar(_ modal: Modal) {
        attente.insert(modal, at: 0)
        courant = nil
    }

    /// Appelé quand une feuille se ferme : la suivante de la file, sinon la suite du premier lancement.
    func feuilleFermee() {
        if !attente.isEmpty { courant = attente.removeFirst(); return }
        proposerSuitePremierLancement()
    }

    // MARK: Premier lancement : position (carte), niveau (L13, sur la carte), tunnel (L13), consentement (L6)

    private var questionVue: Bool { UserDefaults.standard.bool(forKey: ClesConseils.questionVue) }
    private var tunnelVu: Bool { UserDefaults.standard.bool(forKey: ClesConseils.tunnelVu) }

    /// Vrai quand la carte peut ouvrir la question du niveau : position demandée et aucune autre feuille.
    var questionNiveauPermise: Bool { positionPassee && !choixDeZoneOuvert && courant == nil && attente.isEmpty }

    func proposerSuitePremierLancement() {
        guard courant == nil, attente.isEmpty, !choixDeZoneOuvert, questionVue else { return }
        if !tunnelVu {
            UserDefaults.standard.set(true, forKey: ClesConseils.tunnelVu)
            courant = .tunnel
        }
        // L25 (décision 7) : plus de feuille de consentement au premier lancement ; « Mesure d'usage » reste dans les réglages (L6).
    }

    func reglerMesure(_ actif: Bool) {
        if actif { mesure.accorder(); consentement = .accepte } else { mesure.retirer(); consentement = .refuse }
    }

    func accorderOuRefuser(_ accord: Bool) {
        reglerMesure(accord)
        courant = nil
    }

    // MARK: Carte et entonnoir

    func carteListe() {
        guard !carteListeEnvoyee else { return }
        carteListeEnvoyee = true
        mesure.envoyer(.carteListe)
    }

    func spotChange(_ spot: Spot) {
        // La carte peut le signaler deux fois (spot proposé puis toucher) : une seule lecture des conditions.
        guard spot != spotCourant else { return }
        spotCourant = spot
        Task { await conditions.lire(spot: spot.centre) }
    }

    var surSonSpot: Bool { surSonSpotEn(spotCourant?.centre) }

    /// Le point est-il dans le cercle du spot gratuit ? Sans point ou sans spot gratuit : oui.
    func surSonSpotEn(_ point: Coordonnee?) -> Bool {
        guard let point, let gratuit = moteur.spotGratuit else { return true }
        return distanceMetres(point, gratuit.centre) <= gratuit.rayonM
    }

    func autorise(_ fonction: FonctionPro) -> Bool {
        core.session.peutUtiliser(fonction, abonne: suivi.abonne, surSonSpot: surSonSpot)
    }

    /// Même règle, mais pour le coin montré (la fiche peut s'ouvrir loin du spot gratuit).
    func autorise(_ fonction: FonctionPro, en point: Coordonnee) -> Bool {
        core.session.peutUtiliser(fonction, abonne: suivi.abonne, surSonSpot: surSonSpotEn(point))
    }

    // MARK: Session

    func commencer(_ spot: Spot) {
        spotCourant = spot
        sessionReduite = false
        let depart = ContexteDepart(coordonnee: spot.centre, departement: spot.departement, spotChoisi: spot,
                                    abonne: suivi.abonne, conditions: conditions.instantane(spot: spot.centre))
        switch moteur.commencer(depart) {
        case .demarree:
            spotSession = spot
            if let c = moteur.enCours { ecranVerrouille.demarrer(debut: c.sortie.debut, finLegale: c.finLegale) }
            mesure.envoyer(.sessionCommencee)
            onglet = .carte
            Task { await conditions.lire(spot: spot.centre) }
            montrer(.carteAEssayer(spot))
        case .paywallQuiBloque:
            spotEnAttente = spot
            montrer(.paywall(.autreSpot))
        case .pointAToucher, .dejaEnCours:
            break
        }
    }

    private func sessionFinie(_ fin: FinDeSession) {
        sessionReduite = false
        Task { await ecranVerrouille.terminer() }
        PontAquariumWidget.ajouterRations(1)
        publierAquarium()
        mesure.envoyer(.sessionFinie)
        if fin.sortie.prises.isEmpty {
            // Session sans prise : carte bredouille (L4). La révélation avant le paywall n'est pas ouverte ici : elle se voit dans le Pescedex.
            let sortie = fin.sortie
            let lieuFlou = coordonneeSession.map { core.geo.lieuFlou($0) }
            Task { _ = await ecrire { try await $0.enregistrerBredouille(sortie: sortie, lieuFlou: lieuFlou) } }
        }
        // La fin de session passe d'abord (P16) ; le paywall qui se ferme suit dans `finTerminee`.
        finAffichee = fin
        finLieu = coordonneeSession.flatMap { core.geo.lieu(de: $0, choix: nil).eau?.nom }
        montrer(.finSession)
        spotSession = nil
    }

    /// « Terminer » de la fin de session : acquitte la fin, puis ouvre le paywall qui se ferme à la 1re session.
    /// Sortie sans prise : la photo de soi qu'on ajoute à la carte « Eau calme » (sans GPS, écrite à côté des photos de prises).
    func ajouterPhotoSortie(_ data: Data, pour id: UUID) {
        Task { _ = await ecrire { try await $0.ajouterPhotoBredouille(id: id, photo: data) } }
    }

    func finTerminee() {
        guard let fin = finAffichee else { courant = nil; return }
        if moteur.derniereFin == fin { moteur.acquitterFin() }
        if fin.paywall == .quiSeFerme { remplacerPar(.paywall(.finPremiereSession)) } else { courant = nil }
    }

    /// Une ancienne sortie de « Mes sorties », montrée avec la même feuille (jamais de paywall).
    func rouvrir(_ sortie: Sortie) {
        finAffichee = FinDeSession(sortie: sortie, paywall: .aucun)
        finLieu = lieuDuSpot()?.eau?.nom
        remplacerPar(.finSession)
    }

    /// Nom, image et latin d'une espèce, pour les écrans de sortie.
    func infosEspece() -> (Espece) -> EspecePechable? {
        let catalogue = Dictionary(core.especes.especesPechables().map { ($0.espece.id, $0) }, uniquingKeysWith: { a, _ in a })
        return { catalogue[$0.id] }
    }

    private var coordonneeSession: Coordonnee? { spotSession?.centre ?? moteur.spotGratuit?.centre }

    func ajouterPrise() {
        guard coordonneeSession != nil else { return }
        gps.relire()  // relit la position si elle est déjà autorisée, sans rien demander ni enregistrer
        mesure.envoyer(.priseCommencee)
        montrer(.prise)
    }

    func contextePrise() -> PriseContexte {
        // Le verdict part d'où le poisson est pris : la position du moment, sinon le centre du spot.
        // Au-delà de 3 km du spot, la position est celle d'un pêcheur qui n'est pas sur place : on garde le centre.
        let centre = coordonneeSession ?? Coordonnee(latitude: 0, longitude: 0)
        let c = gps.position.flatMap { distanceMetres($0, centre) <= 3000 ? $0 : nil } ?? centre
        // Le tronçon confirmé sur la fiche du coin s'applique à la prise (sinon les règles de tronçon sont perdues).
        let degre = 0.02
        let stations = core.especes.stationsDans(RegionCarte(
            sudOuest: Coordonnee(latitude: c.latitude - degre, longitude: c.longitude - degre),
            nordEst: Coordonnee(latitude: c.latitude + degre, longitude: c.longitude + degre)))
        let choix = PriseLogique.choixEnregistre(pres: c, stations: stations, lire: { StockageChoixLieu.lire($0) })
        return PriseContexte(coordonnee: c, lieu: core.geo.lieu(de: c, choix: choix), lieuFlou: core.geo.lieuFlou(c),
                             date: moteur.maintenant(), prisesDuJour: moteur.prisesGardeesDuJour())
    }

    /// Une prise ajoutée à la main depuis le Pescedex (photo importée) : une carte comme les autres, sans GPS.
    func ajouterPriseManuelle(photo: Data, espece: Espece, cm: Int?, date: Date, lieu: String?) async {
        let prise = Prise(espece: espece, origine: .priseReelle, longueurCm: cm.map(Double.init),
                          mesure: cm == nil ? nil : .saisie, date: date, lieuFlou: lieu, exemple: false)
        if await ecrire({ _ = try await $0.enregistrer(prise: prise, photo: photo) }) {
            await revelerCarte(prise, photoBrute: photo)
        }
    }

    func terminerPrise(_ confirmee: PriseConfirmee?) {
        courant = nil
        guard let confirmee else { return }
        let instantane = coordonneeSession.flatMap { conditions.instantane(spot: $0) }
        moteur.ajouter(prise: confirmee.prise, conditions: instantane)
        Task { await ecranVerrouille.mettreAJour(prises: moteur.nombrePrises) }
        let prise = confirmee.prise
        let photo = confirmee.photo
        let duree = moteur.enCours.map { moteur.maintenant().timeIntervalSince($0.sortie.debut) }
        Task {
            // `.carteCreee` ne part qu'une fois la carte réellement enregistrée.
            if await ecrire({ _ = try await $0.enregistrer(prise: prise, photo: photo, conditions: instantane, dureeSecondes: duree) }) {
                mesure.envoyer(.carteCreee)
                await revelerCarte(prise, photoBrute: photo)
            }
        }
    }

    /// Prépare la révélation (E6) une fois la carte rangée : `ecrire` a déjà rechargé le Pescedex.
    private func revelerCarte(_ prise: Prise, photoBrute: Data?) async {
        guard let modele = pescedex,
              var emplacement = modele.emplacements.first(where: { $0.id == prise.espece.id }) else { return }
        emplacement.carte = prise
        guard let infos = modele.infos(pour: emplacement) else { return }
        // La photo relue est celle sans métadonnées, comme dans le Pescedex.
        let photo = await modele.depot.photo(de: prise) ?? photoBrute
        carteRevelee = CarteRevelee(infos: infos, photo: photo)
    }

    /// Carte déclarée du swipe du premier lancement (L4) : sans photo, ne compte pas comme une prise.
    func declarer(_ prise: Prise) {
        Task { _ = await ecrire { _ = try await $0.enregistrerDeclaree(espece: prise.espece, date: prise.date) } }
    }

    /// L18 : « Déclarer un poisson déjà pêché » (grille `DeclarationView` du Pescedex) écrit la carte puis met l'aquarium à jour.
    func declarerEspece(_ espece: Espece) async {
        let reussi = await ecrire { _ = try await $0.enregistrerDeclaree(espece: espece) }
        if reussi { publierAquarium() }
    }

    // MARK: Abonnement

    func etatAchatsLu(_ etat: EtatAchats) {
        suivi.appliquer(etat)
        moteur.abonne = suivi.abonne
    }

    /// Après un achat depuis « autre spot » : le paywall se ferme, puis la session démarre sur ce spot.
    func achatTermine(_ declencheur: DeclencheurPaywall) {
        guard case .autreSpot = declencheur, let spot = spotEnAttente else { return }
        spotEnAttente = nil
        attenteDepart(spot)
    }

    /// Démarre la session une fois la feuille courante fermée (tunnel ou paywall).
    func attenteDepart(_ spot: Spot) {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            commencer(spot)
        }
    }

    // MARK: Conseils (L13)

    func contexteConseils(lieu: Lieu?, toutLeKit: @escaping (FonctionPro) -> Void) -> ContexteConseils {
        ContexteConseils(conseils: conseils, session: core.session, mois: Calendar.current.component(.month, from: Date()),
                         lieu: lieu, abonne: suivi.abonne, surSonSpot: surSonSpot, toutLeKit: toutLeKit)
    }

    func lieuDuSpot() -> Lieu? {
        spotCourant.map { core.geo.lieu(de: $0.centre, choix: nil) }
    }

    func paywall(_ declencheur: DeclencheurPaywall, fermer: @escaping () -> Void) -> PaywallVue {
        PaywallVue(
            declencheur: declencheur,
            produits: ProduitsMontres(offre: core.session.offreAffichee(date: moteur.maintenant())),
            achats: achats, mesure: mesure,
            liens: LiensLegaux(conditions: LiensLegaux.conditionsApple, confidentialite: Self.confidentialiteProvisoire),
            surEtat: { [weak self] etat in self?.etatAchatsLu(etat) },
            surAchatTermine: { [weak self] d in self?.achatTermine(d) },
            fermer: fermer)
    }

    /// PROVISOIRE : la page de confidentialité de MWM (serveur MCP) n'existe pas encore (LiensClub.confidentialite est nil).
    /// À remplacer par la vraie adresse avant l'envoi.
    static let confidentialiteProvisoire = URL(string: "https://www.apple.com/legal/privacy/fr-fr/")!
}

/// Repli de production si conseils.json ne se charge pas : aucun conseil, jamais un faux.
private nonisolated struct ConseilsVides: ServiceConseils {
    func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int) -> [Conseil] { [] }
    func conseils(espece: Espece, niveau: NiveauPecheur, mois: Int, lieu: Lieu) -> [Conseil] { [] }
}

// MARK: - Vue racine

struct RootView: View {
    /// `nil` le temps que le moteur se charge en fond : l'écran marine s'affiche alors tout de suite.
    @State private var app: ParcoursApp?
    /// Vrai tant que l'ouverture animée couvre l'écran (une fois par lancement).
    @State private var ouvertureAffichee = true
    private let configurerMesure: @MainActor @Sendable () -> Void

    /// `configurerMesure` : la seule fermeture qui appelle `Spark.configure` (dans `BuildChallengeApp.swift`), jamais avant l'accord.
    init(configurerMesure: @escaping @MainActor @Sendable () -> Void = {}) {
        self.configurerMesure = configurerMesure
    }

    var body: some View {
        Group {
            if let app {
                RacineContenu(app: app)
            } else {
                // Même marine que l'écran de lancement : rien de blanc pendant le chargement.
                Color(red: 13 / 255, green: 74 / 255, blue: 133 / 255).ignoresSafeArea()
            }
        }
        // Ouverture « Le bond » (choix d'Adem, 16 oct.) : le logo prend vie pendant le chargement, puis s'ouvre sur l'app.
        .overlay {
            if ouvertureAffichee {
                OuvertureView(pret: app != nil) { ouvertureAffichee = false }
            }
        }
        // DEBUG, avec -FishMeApercuWidget YES : l'animation du widget aquarium par-dessus l'app (vidéo sans écran d'accueil).
        #if DEBUG
        .apercuWidgetSiDemande()
        #endif
        .task {
            guard app == nil else { return }
            Sons.prechauffer()
            let dossierRegles = ReglesAJour.dossierCopies
            let chargement = await Task.detached(priority: .userInitiated) { Chargement.preparer(dossierRegles: dossierRegles) }.value
            let nouvelle = ParcoursApp(chargement: chargement, configurerMesure: configurerMesure)
            app = nouvelle
            await nouvelle.demarrer()
            // DEBUG seulement, avec -FishMeForcerPro YES : le widget aquarium s'affiche en Pro (vidéo de démo). Rien en Release.
            PontAquariumWidget.appliquerProForce()
        }
    }
}

/// Les 3 volets, une fois le moteur chargé.
private struct RacineContenu: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var app: ParcoursApp
    @AppStorage(ClesConseils.questionVue) private var questionVue = false
    @AppStorage("demo.communaute") private var demo = false
    /// L25 : le profil public (L21). Plus de nom saisi dans la racine : le surnom est le seul nom (décision 3).
    private let profil = GestionProfil.partage
    @State private var profilOuvert = false
    /// L24 : la liste des conversations (feuille de l'onglet Communauté).
    @State private var messagesOuverts = false
    /// « Tes conditions » (météo), ouvert par le bouton météo de la carte.
    @State private var meteoOuverte = false
    @State private var aquariumOuvert = false
    /// N1 : la galerie des décors, au-dessus de l'aquarium. Le choix est gardé dans `aquarium.skin`.
    @State private var decorsOuverts = false
    @AppStorage(ChoixSkin.cle) private var skinBrut = ChoixSkin.valeurParDefaut
    /// Vrai de l'apparition de la couverture de session jusqu'à la fin de son retrait.
    /// P03 « Où pêches-tu ? » : montré une seule fois, avant la première demande de position.
    @AppStorage("premierLancement.ouPechesTuVu") private var ouPechesTuVu = false

    var body: some View {
        if !ouPechesTuVu && app.gps.nAPasEteDemandee {
            // Les onglets ne sont pas encore construits : la carte ne demande donc pas la position derrière cet écran.
            OuPechesTuView(
                utiliserMaPosition: {
                    ouPechesTuVu = true
                    app.gps.demanderAuPremierEcran()
                },
                choisirSurLaCarte: {
                    ouPechesTuVu = true
                    app.choixDeZoneOuvert = true
                })
        } else {
            corps
        }
    }

    @ViewBuilder private var corps: some View {
#if DEBUG
        // Entrée de test du UI test de L3 (docs/relecture-ecrans-avant-mac.md, « Manques connus »).
        if ProcessInfo.processInfo.arguments.contains("-prise-test") {
            PriseRacineView(
                services: .faux,
                contexte: PriseContexte(coordonnee: Coordonnee(latitude: 48.82, longitude: 2.41),
                                        lieu: Lieu(departement: Departement(code: "94")),
                                        lieuFlou: "La Marne · 94", date: Date(), prisesDuJour: []),
                terminer: { _ in })
        } else {
            onglets
        }
#else
        onglets
#endif
    }

    // MARK: Les 3 volets

    /// Plein écran : fin de session, mes sorties, paywall « autre spot », prise et tunnel. Feuille : le reste.
    private func estPleinEcran(_ modal: Modal) -> Bool {
        switch modal {
        case .finSession, .mesSorties, .prise, .tunnel, .paywall(.autreSpot): true
        default: false
        }
    }

    /// Qui présente : la racine, toujours. La session est un calque (overlay) réductible, pas une couverture : les feuilles
    /// et pleins écrans posés sur la racine s'affichent par-dessus elle.
    private func actif(dansSession: Bool) -> Bool { !dansSession }

    /// Le modal courant, vu seulement par la présentation (feuille ou plein écran) qui le montre.
    private func liaison(pleinEcran: Bool, dansSession: Bool) -> Binding<Modal?> {
        Binding(
            get: { actif(dansSession: dansSession) ? app.courant.flatMap { estPleinEcran($0) == pleinEcran ? $0 : nil } : nil },
            set: { nouveau in
                if nouveau == nil, let c = app.courant, estPleinEcran(c) == pleinEcran { app.courant = nil }
            })
    }

    private func liaisonRevelee(dansSession: Bool) -> Binding<CarteRevelee?> {
        Binding(get: { actif(dansSession: dansSession) ? app.carteRevelee : nil },
                set: { if $0 == nil { app.carteRevelee = nil } })
    }

    /// Les mêmes présentations (feuille, plein écran, carte révélée) posées sur la racine et sur la couverture de session.
    private func avecModales<V: View>(_ contenu: V, dansSession: Bool) -> some View {
        contenu
            .sheet(item: liaison(pleinEcran: false, dansSession: dansSession), onDismiss: { app.feuilleFermee() }) { modal in
                vue(de: modal)
            }
            .fullScreenCover(item: liaison(pleinEcran: true, dansSession: dansSession), onDismiss: { app.feuilleFermee() }) { modal in
                vue(de: modal)
            }
            .fullScreenCover(item: liaisonRevelee(dansSession: dansSession)) { revelee in
                RevelationCarteView(infos: revelee.infos, photo: revelee.photo) { app.carteRevelee = nil }
            }
    }

    private var onglets: some View {
        avecModales(tabView, dansSession: false)
            // Bouton « Prise » de l'écran verrouillé (P15) : l'intent laisse l'action en attente, l'app la joue au retour.
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active, let action = ActionSessionEnAttente.lire() else { return }
                ActionSessionEnAttente.effacer()
                if action == "prise" { app.ajouterPrise() }
            }
            .onChange(of: questionVue) { app.proposerSuitePremierLancement() }
            .onChange(of: app.suivi.abonne) { _, abonne in
                app.moteur.abonne = abonne
                app.publierAquarium()
            }
            .onOpenURL { app.ouvrir(url: $0) }
            // La question du niveau et le tunnel attendent la réponse à la position (accordée ou refusée), puis le choix de zone.
            // Repli : si le système ne répond pas en 30 s, on continue sans elle.
            .task(id: app.gps.nAPasEteDemandee) {
                try? await Task.sleep(for: .seconds(app.gps.nAPasEteDemandee ? 30 : 1))
                if Task.isCancelled { return }
                app.positionPassee = true
                app.proposerSuitePremierLancement()
            }
    }

    private var tabView: some View {
        TabView(selection: $app.onglet) {
            Tab("Pescedex", systemImage: "square.grid.2x2.fill", value: Onglet.pescedex) {
                pescedex
            }
            Tab("Carte", systemImage: "map.fill", value: Onglet.carte) {
                carte
            }
            Tab("Communauté", systemImage: "person.2.fill", value: Onglet.club) {
                club
            }
        }
        // Pendant la session en plein écran, la barre d'onglets se range : l'écran du chrono est à lui seul.
        .toolbarVisibility(app.moteur.enCours != nil && !app.sessionReduite ? .hidden : .automatic, for: .tabBar)
        // Session en cours en plein écran réductible (P14 C) : le bouton « Carte » la range en bandeau sur la carte.
        .overlay {
            if app.moteur.enCours != nil && !app.sessionReduite {
                SessionEnCoursView(moteur: app.moteur, ajouterPrise: { app.ajouterPrise() },
                                   infosEspece: app.infosEspece(), eau: app.lieuDuSpot()?.eau?.nom,
                                   reduire: { withAnimation { app.sessionReduite = true } }) {
                    LigneSessionEmplacement(app: app)
                }
                .transition(.move(edge: .bottom))
            }
        }
        // `styleFishMe()` : App/Style/ n'existe pas sur cette branche, rien à poser ici.
    }

    // MARK: Volet Pescedex (L4) avec L12, L13

    @ViewBuilder private var pescedex: some View {
        if let modele = app.pescedex {
            PescedexView(
                modele: modele,
                emplacements: EmplacementsExternes(
                    commentLaPecher: { espece in AnyView(CommentLaPecherEmplacement(app: app, espece: espece)) },
                    tesConditions: { AnyView(TesConditionsEmplacement(app: app)) },
                    meteoDuDos: { conditions in AnyView(BlocConditionsPriseView(conditions: conditions, marque: app.marque)) }),
                voirAquarium: { aquariumOuvert = true },
                photographier: { app.ajouterPrise() },
                // L18 : "Déclarer" ouvre la grille `DeclarationView` dans le Pescedex ; le tunnel ne s'ouvre plus d'ici.
                declarerEspece: { espece in await app.declarerEspece(espece) },
                // P27 « Pour toi » : Appât, Hameçon, Technique, Moment, au mois le plus proche et à n'importe quel niveau
                // s'il le faut (jamais vide quand Core a un conseil). Sans abonnement : l'appât seul, le reste derrière Pro.
                conseilsParType: { espece, niveau in
                    let tout = app.contexteConseils(lieu: app.lieuDuSpot(), toutLeKit: { _ in })
                        .parType(espece: espece, niveau: niveau)
                    return app.autorise(.conseilsComplets) ? tout : tout.filter { $0.key == .appat }
                },
                changerZone: { app.onglet = .carte },
                ajouterManuellement: { photo, espece, cm, date, lieu in
                    await app.ajouterPriseManuelle(photo: photo, espece: espece, cm: cm, date: date, lieu: lieu)
                })
            .fullScreenCover(isPresented: $aquariumOuvert) {
                // N1 : le menu « Décors » est un bouton posé par la racine sur l'aquarium (AquariumView n'en a pas).
                ZStack(alignment: .topLeading) {
                    aquariumView(modele: modele, skin: ChoixSkin.affiche(brut: skinBrut, contexte: app.contexteSkin()),
                                 fermer: { aquariumOuvert = false })
                    Button { decorsOuverts = true } label: {
                        Label("Décors", systemImage: "paintpalette")
                            .font(Police.corps.weight(.semibold))
                            .padding(.horizontal, Espace.m)
                            .frame(minHeight: Gabarit.zoneTactile)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .padding(Espace.bord)
                }
                .sheet(isPresented: $decorsOuverts) {
                    SkinsGalerieView(
                        aquarium: { skin, fermer in aquariumView(modele: modele, skin: skin, fermer: fermer) },
                        contexte: app.contexteSkin(),
                        choisi: ChoixSkin.binding($skinBrut),
                        demanderPro: {
                            // Le paywall ne peut pas s'ouvrir sous l'aquarium : on ferme d'abord (pas de cas « Skins » dans DeclencheurPaywall).
                            decorsOuverts = false
                            aquariumOuvert = false
                            Task {
                                try? await Task.sleep(for: .milliseconds(500))
                                app.montrer(.paywall(.widget))
                            }
                        },
                        auChangement: { _ in app.publierAquarium() },
                        fermer: { decorsOuverts = false })
                }
            }
        } else {
            ContentUnavailableView("Pescedex", systemImage: "square.grid.2x2.fill",
                                   description: Text("Tes cartes ne peuvent pas s'ouvrir pour l'instant."))
        }
    }

    /// L'aquarium plein écran avec un décor (N1) et les emplacements habituels.
    private func aquariumView(modele: PescedexModele, skin: IdentifiantSkin, fermer: @escaping () -> Void) -> AquariumView {
        AquariumView(modele: modele, fermer: fermer,
                     emplacements: EmplacementsExternes(
                        commentLaPecher: { espece in AnyView(CommentLaPecherEmplacement(app: app, espece: espece)) },
                        tesConditions: { AnyView(TesConditionsEmplacement(app: app)) },
                        meteoDuDos: { conditions in AnyView(BlocConditionsPriseView(conditions: conditions, marque: app.marque)) }),
                     skin: skin)
    }

    // MARK: Volet Carte (L2) avec L5, L12, L13

    @ViewBuilder private var carte: some View {
        // Toujours la carte plein écran (démo ou non, position accordée ou non) : la pastille de profil est dans son en-tête.
        // `carteSansPosition` n'est plus affichée ici.
        vueCarte
            .sheet(isPresented: $profilOuvert) { ProfilEmplacement(app: app, reglages: reglagesClub) }
            .sheet(isPresented: $meteoOuverte) { TesConditionsEmplacement(app: app) }
            .onChange(of: demo) { _, _ in Task { await app.rafraichirCollection() } }
            .questionNiveau(declenchee: app.questionNiveauPermise)
    }

    private var carteSansPosition: some View {
        SansPositionView(
            zone: NomDeZone.texte(departement: app.spotCourant?.departement),
            changerDeZone: { app.choixDeZoneOuvert = true },
            autoriserPosition: {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            },
            voirLaCarte: { app.sansPositionAffiche = false },
            ouvrirPescedex: { app.onglet = .pescedex },
            ouvrirAmis: SauvegardeICloud.actif ? { app.onglet = .club } : nil,
            compteurPescedex: app.pescedex.map { m in "\(m.emplacements.filter { $0.carte != nil }.count)" },
            codeZone: app.spotCourant.flatMap { $0.departement.estInconnu ? nil : $0.departement.code })
    }

    private var vueCarte: some View {
        VueCarte(
            services: app.servicesCarte,
            spotFixe: app.moteur.spotGratuit,
            sessionsTerminees: app.moteur.sessionsTerminees,
            bandeauHaut: AnyView(VigilanceEmplacement(app: app)),
            bandeauSession: AnyView(Group {
                if app.moteur.enCours != nil && app.sessionReduite {
                    BandeauSessionView(moteur: app.moteur, ajouterPrise: { app.ajouterPrise() },
                                       rouvrir: { withAnimation { app.sessionReduite = false } })
                }
            }),
            sessionEnCours: app.moteur.enCours != nil,
            emplacementMaintenant: { coordonnee in AnyView(ConditionsEmplacement(app: app, coordonnee: coordonnee)) },
            emplacementConseil: { espece in AnyView(ConseilEmplacement(app: app, espece: espece)) },
            onCommencerSession: { spot in app.commencer(spot) },
            onSpotChange: { spot in app.spotChange(spot) },
            ouChercher: { position in AnyView(OuChercherVue(especes: app.coins, position: position)) },
            surChoixDeZone: { ouvert in
                app.choixDeZoneOuvert = ouvert
                if !ouvert { app.proposerSuitePremierLancement() }
            },
            demandeChoixDeZone: app.choixDeZoneOuvert, volVersLeSpot: app.volDemande,
            pastilleProfil: AnyView(
                ProfilPastille(nom: ProfilEmplacement<EmptyView>.nomAffiche(profil.surnomMemorise ?? ""),
                               nombreDeCartes: app.cartesAPartager.count) { profilOuvert = true }),
            ouvrirMeteo: { meteoOuverte = true },
            ouvrirProfil: { profilOuvert = true })
            .task { app.carteListe() }
    }

    // MARK: Volet Communauté (Amis et Club, L8 et L9) avec L6

    private var reglagesClub: some View {
        let departement = app.moteur.spotGratuit?.departement ?? .inconnu
        let federation = app.core.regles.liensFederation(departement: departement)
        let liens = LiensClub(
            federation: federation.siteFederation.flatMap { URL(string: $0) },
            association: nil,
            carteDePeche: federation.pageCarteDePeche.flatMap { URL(string: $0) } ?? LiensOfficiels.carteDePeche,
            confidentialite: ParcoursApp.confidentialiteProvisoire)
        var sources = app.core.regles.credits().map { c in
            SourceClub(nom: c.nom, mention: c.mention ?? "", lien: c.url.flatMap { URL(string: $0) })
        }
        sources.append(SourceClub(nom: "Photo d'exemple", mention: "Photo d'exemple : SpinfisherCRO, CC BY-SA",
                                  lien: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")))
        sources += DemoPescedex.credits().map { SourceClub(nom: $0.nom, mention: $0.mention, lien: $0.url) }
        return ReglagesClubView(
            liens: liens, sources: sources, cartes: app.cartesAPartager,
            mesureUsage: Binding(get: { app.consentement == .accepte }, set: { app.reglerMesure($0) }),
            marqueMeteo: MarqueMeteoView(stockage: app.marque))
    }

    private var club: some View {
        let poissons = app.core.especes.especesPechables().map { PoissonClub(id: $0.espece.id, nom: $0.nom, image: $0.image) }
        // L23 : la page principale est le fil. L21 : « Finis ton profil » au premier passage. L24 : les messages dans une feuille
        // (bouton en haut à droite) ; « Écrire » depuis un ami ou un club reste à poser dans leurs pages (voir branchements-l25.md).
        return CommunauteView(fil: FeedVue(gestion: app.feed)) {
            AmisPageView(gestion: app.gestionAmis(), profil: GestionProfil.partage)
        } club: {
            ClubPageView(cartes: app.cartesAPartager, poissons: poissons)
        }
        .finisTonProfil()
        .overlay(alignment: .topTrailing) { boutonMessages }
        .sheet(isPresented: $messagesOuverts) { ListeConversationsView(gestion: app.chat) }
    }

    private var boutonMessages: some View {
        Button { messagesOuverts = true } label: {
            Label("Messages", systemImage: "bubble.left.and.bubble.right")
                .labelStyle(.iconOnly)
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                .overlay(alignment: .topTrailing) {
                    if app.chat.nonLus > 0 {
                        Circle().fill(Color.red).frame(width: 10, height: 10).accessibilityHidden(true)
                    }
                }
        }
        .accessibilityLabel(app.chat.nonLus > 0 ? "Messages, nouveaux messages" : "Messages")
        .padding(.trailing, Espace.bord)
        .padding(.top, Espace.xs)
    }

    // MARK: Écrans modaux

    @ViewBuilder private func vue(de modal: Modal) -> some View {
        switch modal {
        case .tunnel:
            let proches = app.spotCourant.map { app.core.especes.especesProches($0.centre) } ?? []
            // La catégorie du coin décide si les truites complètent la liste (1re catégorie seulement).
            let categorie = app.spotCourant.map { app.core.geo.lieu(de: $0.centre, choix: nil).categorie.valeur }
            TunnelPremiersPasView(
                especes: EspecesDuTunnel.choisir(pechables: app.core.especes.especesPechables(), proches: proches,
                                                 categorie: categorie),
                maintenant: { app.moteur.maintenant() },
                declarer: { prise in app.declarer(prise) },
                pecherMaintenant: { app.courant = nil; app.onglet = .carte },
                choisirUnSpot: { app.courant = nil; app.onglet = .carte },
                passer: { app.courant = nil },
                rarete: { pechable in
                    guard let departement = app.spotCourant?.departement, !departement.estInconnu else { return nil }
                    let niveau = app.core.especes.rarete(espece: pechable.espece, departement: departement).niveau
                    let style = StyleRarete(niveau)
                    return (style.mot, style.couleur)
                },
                voirMonSpot: { app.courant = nil; app.onglet = .carte; app.volDemande = true },
                departement: app.spotCourant?.departement.estInconnu == false ? app.spotCourant?.departement.code : nil)

        case .consentement:
            FeuilleConsentement(accepter: { app.accorderOuRefuser(true) }, refuser: { app.accorderOuRefuser(false) })

        case .paywall(let declencheur):
            if case .autreSpot = declencheur {
                AutreSpotEmplacement(app: app)
            } else {
                app.paywall(declencheur, fermer: { app.courant = nil })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }

        case .finSession:
            if let fin = app.finAffichee {
                FinSessionView(fin: fin, infosEspece: app.infosEspece(), lieu: app.finLieu, surTerminer: { app.finTerminee() },
                               surPhotoSortie: fin.sortie.prises.isEmpty ? { data in app.ajouterPhotoSortie(data, pour: fin.sortie.id) } : nil,
                               rarete: { prise in
                                   guard let departement = Formats.departement(depuisLieuFlou: prise.lieuFlou) ?? app.spotCourant?.departement,
                                         !departement.estInconnu else { return nil }
                                   return app.core.especes.rarete(espece: prise.espece, departement: departement)
                               },
                               photoDe: { prise in
                                   prise.cheminPhoto.flatMap { try? Data(contentsOf: DepotCartes.dossierParDefaut().appendingPathComponent($0)) }
                               })
                    .interactiveDismissDisabled()
            }

        case .mesSorties:
            MesSortiesView(sorties: app.moteur.sortiesTerminees, infosEspece: app.infosEspece(), lieu: app.lieuDuSpot()?.eau?.nom,
                           surChoix: { app.rouvrir($0) }, surRetour: { app.courant = nil })
                .presentationDetents([.medium, .large])

        case .reglages:
            ReglagesEmplacement(app: app)

        case .prise:
            PriseRacineView(services: app.servicesPrise, contexte: app.contextePrise(),
                            terminer: { app.terminerPrise($0) })
                .interactiveDismissDisabled()

        case .carteAEssayer(let spot):
            CarteAEssayerView(
                especesProches: app.core.especes.especesProches(spot.centre),
                pechables: app.core.especes.especesPechables(),
                etatEau: app.conditions.derniere(spot: spot.centre)?.conditions.etatRiviere ?? .inconnu,
                contexte: app.contexteConseils(lieu: app.core.geo.lieu(de: spot.centre, choix: nil),
                                               toutLeKit: { app.remplacerPar(.paywall(.fonction($0))) }),
                fermer: { app.courant = nil })
        }
    }
}

// MARK: - Emplacements (vues passées aux écrans des autres lots)

/// Bandeau du haut de la carte : vigilance orage ou crue de L12, gratuite pour tous. Lue pour le dernier spot connu.
private struct VigilanceEmplacement: View {
    let app: ParcoursApp
    @State private var alerte: Alerte?
    @State private var lecture: LectureConditions?

    var body: some View {
        Group {
            if let alerte { BandeauVigilanceView(alerte: alerte, previensMoi: app.previensMoi, lecture: lecture, marque: app.marque) }
        }
        .task(id: app.spotCourant?.centre) {
            guard let spot = app.spotCourant?.centre else { alerte = nil; lecture = nil; return }
            let lue = await app.conditions.lire(spot: spot) ?? app.conditions.derniere(spot: spot)
            lecture = lue
            alerte = lue?.alerte
        }
    }
}

/// Ligne de conditions du bandeau de session (L12 dans L5), seulement si une lecture existe.
private struct LigneSessionEmplacement: View {
    let app: ParcoursApp
    @State private var lecture: LectureConditions?

    private var centre: Coordonnee? { app.spotCourant?.centre ?? app.moteur.spotGratuit?.centre }

    var body: some View {
        Group {
            if let lecture, let c = centre, app.autorise(.meteoDuJour, en: c) {
                LigneConditionsSession(lecture: lecture, marque: app.marque)
            }
        }
        .task(id: app.moteur.enCours != nil) {
            guard let c = centre else { return }
            lecture = app.conditions.derniere(spot: c)
            lecture = await app.conditions.lire(spot: c) ?? lecture
        }
    }
}

/// Rangée « maintenant », jauge de la rivière et fonctions Pro de L12, dans la fiche d'un coin (L2).
private struct ConditionsEmplacement: View {
    let app: ParcoursApp
    let coordonnee: Coordonnee
    @State private var lecture: LectureConditions?
    @State private var meteo = false
    @State private var septJours = false
    @State private var courbe = false
    @State private var previens = false
    @State private var paywall: PaywallDemande?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let lecture {
                bouton("Météo du moment", "cloud.sun", .meteoDuJour) { meteo = true }
                if !app.autorise(.niveauEau, en: coordonnee) {
                    bouton("Niveau de l'eau", "water.waves", .niveauEau) {}
                }
                bouton("7 jours", "calendar", .septJours) { septJours = true }
                bouton("Préviens-moi", "bell", .prevenirMoi) { previens = true }
            } else {
                RangeeMaintenantVideView(reessayer: {
                    Task { lecture = await app.conditions.lire(spot: coordonnee) ?? lecture }
                })
            }
        }
        .task(id: coordonnee) {
            lecture = app.conditions.derniere(spot: coordonnee)
            lecture = await app.conditions.lire(spot: coordonnee) ?? lecture
        }
        .sheet(isPresented: $meteo) {
            if let lecture {
                ConditionsDuJourView(lecture: lecture, marque: app.marque,
                                     montrerRiviere: app.autorise(.niveauEau, en: coordonnee),
                                     ouvrirCourbe: {
                                         // Une feuille à la fois : la courbe s'ouvre une fois la météo refermée.
                                         meteo = false
                                         Task {
                                             try? await Task.sleep(for: .milliseconds(450))
                                             ouvrir(.courbeEtNormale) { courbe = true }
                                         }
                                     })
            }
        }
        .sheet(isPresented: $septJours) {
            if let lecture { SeptJoursView(lecture: lecture, marque: app.marque) }
        }
        .sheet(isPresented: $courbe) {
            if let eau = lecture?.eau { CourbeRiviereView(eau: eau) }
        }
        .sheet(isPresented: $previens) {
            PreviensMoiView(modele: app.previensMoi, lecture: lecture)
        }
        .sheet(item: $paywall) { demande in
            app.paywall(demande.declencheur, fermer: { paywall = nil })
        }
    }

    private func ouvrir(_ fonction: FonctionPro, _ action: () -> Void) {
        if app.autorise(fonction, en: coordonnee) { action() } else { paywall = PaywallDemande(declencheur: .fonction(fonction)) }
    }

    @ViewBuilder private func bouton(_ titre: String, _ icone: String, _ fonction: FonctionPro, _ action: @escaping () -> Void) -> some View {
        if app.autorise(fonction, en: coordonnee) {
            Button(action: action) { Label(titre, systemImage: icone).frame(maxWidth: .infinity, alignment: .leading) }
                .buttonStyle(.plain)
        } else {
            VerrouPro(fonction: fonction, titre: titre, icone: icone,
                      porte: PorteConditions(autorise: { _ in false },
                                             ouvrirPaywall: { paywall = PaywallDemande(declencheur: .fonction($0)) }))
        }
    }
}

/// 1er conseil de l'espèce touchée dans la fiche d'un coin (L13 dans L2).
private struct ConseilEmplacement: View {
    let app: ParcoursApp
    let espece: Espece
    @State private var paywall: PaywallDemande?

    var body: some View {
        PremierConseilView(
            espece: espece,
            contexte: app.contexteConseils(lieu: app.lieuDuSpot(),
                                           toutLeKit: { paywall = PaywallDemande(declencheur: .fonction($0)) }))
            .sheet(item: $paywall) { demande in
                app.paywall(demande.declencheur, fermer: { paywall = nil })
            }
    }
}

/// « Comment la pêcher » (L13) au dos d'une espèce du Pescedex ; son paywall est présenté ici, pas sur la racine.
private struct CommentLaPecherEmplacement: View {
    let app: ParcoursApp
    let espece: Espece
    @State private var paywall: PaywallDemande?

    var body: some View {
        CommentLaPecherView(
            espece: espece,
            contexte: app.contexteConseils(lieu: app.lieuDuSpot(),
                                           toutLeKit: { paywall = PaywallDemande(declencheur: .fonction($0)) }))
            .sheet(item: $paywall) { demande in
                app.paywall(demande.declencheur, fermer: { paywall = nil })
            }
    }
}

/// « Tes conditions » ouvert depuis le Pescedex : la météo de l'iPhone (WeatherKit) pour ton spot.
private struct TesConditionsEmplacement: View {
    let app: ParcoursApp
    @State private var paywall: PaywallDemande?

    var body: some View {
        let centre = app.spotCourant?.centre ?? app.moteur.spotGratuit?.centre
        TesConditionsMeteoView(
            centre: centre, conditions: app.conditions, marque: app.marque,
            porte: PorteConditions(
                autorise: { fonction in centre.map { app.autorise(fonction, en: $0) } ?? false },
                ouvrirPaywall: { fonction in paywall = PaywallDemande(declencheur: .fonction(fonction)) }))
            .sheet(item: $paywall) { demande in
                app.paywall(demande.declencheur, fermer: { paywall = nil })
            }
    }
}

/// « Mes statistiques » (L12, Pro) : les comptes de ses propres sorties, ou le paywall.
private struct MesStatistiquesEmplacement: View {
    let app: ParcoursApp
    @Environment(\.dismiss) private var fermer

    var body: some View {
        if app.autorise(.analyseConditions) {
            TesConditionsView(constats: app.core.conditions.tesConditions(sorties: app.moteur.sortiesTerminees),
                              sortiesTerminees: app.moteur.sortiesTerminees.count, marque: app.marque)
        } else {
            app.paywall(.fonction(.analyseConditions), fermer: { fermer() })
        }
    }
}

/// Le profil (depuis la pastille de la page Carte) : nom, badge, mes statistiques, mes sorties, les réglages de l'app
/// et tout ce qui était dans « Mon club ». Compte simulé : rien n'est créé en ligne, tout reste sur l'iPhone.
private struct ProfilEmplacement<Reglages: View>: View {
    let app: ParcoursApp
    let reglages: Reglages
    @Environment(\.dismiss) private var fermer
    @AppStorage("demo.communaute") private var demo = false
    /// L25 (L21) : le surnom du profil public remplace l'ancien champ « nom de profil » (décision 3 : aucun nom ni prénom).
    private let profil = GestionProfil.partage
    @State private var finirOuvert = false

    private var nomAffiche: String { ProfilEmplacement.nomAffiche(profil.surnomMemorise ?? "") }
    static func nomAffiche(_ nom: String) -> String {
        let propre = nom.trimmingCharacters(in: .whitespaces)
        return propre.isEmpty ? "Pêcheur" : propre
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Espace.m) {
                        AvatarSurnom(surnom: nomAffiche, image: profil.profil?.avatar, taille: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(nomAffiche)
                                .font(Police.corps.weight(.semibold))
                                .foregroundStyle(Palette.encre)
                            let niveau = BadgeProfil.niveau(cartes: app.cartesAPartager.count)
                            Label("\(niveau.titre) · \(app.cartesAPartager.count) cartes", systemImage: niveau.symbole)
                                .font(Police.legende)
                                .foregroundStyle(Palette.marine)
                        }
                    }
                    .padding(.vertical, 4)
                    if profil.aUnProfil {
                        NavigationLink { ReglagesProfilView(gestion: profil) } label: {
                            Label("Mon profil public", systemImage: "person.crop.circle")
                        }
                    } else {
                        Button { finirOuvert = true } label: {
                            Label("Finis ton profil", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                } footer: {
                    Text("Ton surnom est le seul nom que les autres voient.")
                }
                Section {
                    Toggle(isOn: $demo) {
                        Label("Mode démo", systemImage: "sparkles.rectangle.stack")
                    }
                } footer: {
                    Text("Remplit le Pescedex, les amis, le club, le fil et les messages avec des exemples. Rien n'est envoyé.")
                }
                Section {
                    NavigationLink { MesStatistiquesEmplacement(app: app) } label: {
                        Label("Mes statistiques", systemImage: "chart.bar.xaxis")
                    }
                    Button { ouvrir(.mesSorties) } label: {
                        Label("Mes sorties", systemImage: "clock.arrow.circlepath")
                    }
                    Button { ouvrir(.reglages) } label: {
                        Label("Réglages", systemImage: "gearshape")
                    }
                }
                Section {
                    NavigationLink { reglages } label: {
                        Label("Ma pêche, sécurité et sources", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("Mon profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fermer") { fermer() } } }
            .task { await profil.charger() }
            .sheet(isPresented: $finirOuvert) { FinisTonProfilView(gestion: profil) }
        }
    }

    /// Ferme le profil d'abord : deux feuilles ne se superposent pas.
    private func ouvrir(_ modal: Modal) {
        fermer()
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            app.montrer(modal)
        }
    }
}

/// P10 : l'invitation Pro d'abord ; « Découvrir » montre le paywall dans la même feuille (jamais deux à la fois).
private struct AutreSpotEmplacement: View {
    let app: ParcoursApp
    @State private var decouvert = false

    var body: some View {
        if decouvert {
            app.paywall(.autreSpot, fermer: { app.courant = nil })
        } else {
            AutreSpotProView(decouvrir: { decouvert = true }, plusTard: { app.courant = nil })
        }
    }
}

/// P35 : les réglages, dans la feuille courante. « Sécurité » s'y empile ; le paywall la remplace.
private struct ReglagesEmplacement: View {
    let app: ParcoursApp
    @ObservedObject private var previens: PreviensMoiModele
    @AppStorage(ClesConseils.niveau) private var niveauBrut = NiveauPecheur.parDefaut.rawValue
    @State private var securite = false
    @State private var compteOuvert = false
    @Environment(\.openURL) private var ouvrir

    init(app: ParcoursApp) {
        self.app = app
        _previens = ObservedObject(wrappedValue: app.previensMoi)
    }

    var body: some View {
        NavigationStack {
            ReglagesView(
                niveau: Binding(get: { NiveauPecheur(rawValue: niveauBrut) ?? .parDefaut }, set: { niveauBrut = $0.rawValue }),
                alertes: $previens.vigilanceActive,
                mesureAudience: Binding(get: { app.consentement == .accepte }, set: { app.reglerMesure($0) }),
                abonne: app.suivi.abonne,
                achats: app.achats,
                liens: LiensLegaux(conditions: LiensLegaux.conditionsApple, confidentialite: ParcoursApp.confidentialiteProvisoire),
                surEtat: { app.etatAchatsLu($0) },
                ouvrirSource: { nom in if let url = Self.page(de: nom) { ouvrir(url) } },
                ouvrirSecurite: { securite = true },
                ouvrirPaywall: { app.remplacerPar(.paywall(.widget)) },
                ouvrirCompte: app.compte == nil ? nil : { compteOuvert = true })
                .navigationDestination(isPresented: $securite) { SecuriteView() }
                .navigationDestination(isPresented: $compteOuvert) {
                    if let compte = app.compte { CompteView(modele: compte, abonne: app.suivi.abonne) }
                }
        }
        .onChange(of: previens.vigilanceActive) {
            Task {
                _ = await previens.assurerPermission()
                if let spot = app.spotCourant?.centre { await previens.reprogrammer(avec: app.conditions.derniere(spot: spot)) }
            }
        }
    }

    private static func page(de source: String) -> URL? {
        switch source {
        case "OFB": URL(string: "https://www.ofb.gouv.fr")
        case "Hub'Eau": URL(string: "https://hubeau.eaufrance.fr")
        case "Météo-France": LiensOfficiels.vigilanceMeteoFrance
        case "Arrêtés": URL(string: "https://www.legifrance.gouv.fr")
        case "Apple Weather": URL(string: "https://developer.apple.com/weatherkit/data-source-attribution/")
        default: nil
        }
    }
}

#Preview {
    RootView()
}

/// Nom montré sur l'écran « Ta zone » : le département de la zone choisie, jamais inventé.
enum NomDeZone {
    static func texte(departement: Departement?) -> String? {
        guard let departement, !departement.estInconnu, !departement.code.isEmpty else { return nil }
        return "Département \(departement.code)"
    }
}

// MARK: Adaptateurs de la racine (L25) // ⚠ à vérifier (écrits sans Mac ni Xcode)

/// Ce que la racine sait au moment de la lecture, copié hors du fil principal pour le fil (L23) et le chat (L24).
nonisolated struct InstantaneRacine: Sendable {
    var monID: String?
    var surnom: String?
    var aUnProfil: Bool
    var amis: [InterlocuteurChat]
    /// Code du département du spot (« 94 »), `nil` s'il est inconnu.
    var departement: String?
    var demo: Bool

    static let vide = InstantaneRacine(monID: nil, surnom: nil, aUnProfil: false, amis: [], departement: nil, demo: false)
}

/// Ce que le fil attend des lots voisins (`SourceContexte`), branché sur le profil de L21, la page Amis et le spot.
/// Les clubs (L22) ne sont pas encore branchés : `mesClubs()` rend vide jusqu'à `ServiceClubs`.
nonisolated struct SourceFeedRacine: SourceContexte {
    let lire: @MainActor @Sendable () -> InstantaneRacine

    func monNom() async -> String? { await lire().monID }
    /// Un profil ne se crée qu'avec la déclaration « 15 ans ou plus » : avoir un profil vaut cette déclaration.
    func profilQuinzeAnsOuPlus() async -> Bool { await lire().aUnProfil }
    func nomsDesAmis() async -> [String] { await lire().amis.map(\.id).filter { $0.hasPrefix("p-") } }
    func mesClubs() async -> [ClubResume] { [] }
    func departementsDeMaRegion() async -> [String] {
        guard let code = await lire().departement else { return [] }
        return [code] + RegionsFrance.departementsDeLaRegion(de: code).filter { $0 != code }
    }
    func lieuCourant() async -> ContexteLieu {
        // Le type d'eau n'est pas connu ici : `planDEau: true` (pas de nom de lac, voulu par la règle de L23).
        ContexteLieu(eauNom: nil, planDEau: true, departement: await lire().departement)
    }
    func modeDemo() async -> Bool { await lire().demo }
}

/// L'annuaire du chat (`AnnuaireChat`) : mon profil de L21, mes amis de la page Amis, les blocages de L21. Pas de clubs (L22).
nonisolated struct AnnuaireChatRacine: AnnuaireChat {
    let lire: @MainActor @Sendable () -> InstantaneRacine

    func moi() async -> InterlocuteurChat? {
        let i = await lire()
        guard let id = i.monID, i.aUnProfil else { return nil }
        // `idCloudKit` de moi n'est pas lu par GestionChat ; l'identifiant de profil sert de repli.
        return InterlocuteurChat(id: id, surnom: i.surnom ?? "Pêcheur", idCloudKit: id, a15Ans: true)
    }
    func amis() async -> [InterlocuteurChat] { await lire().amis }
    func clubs() async -> [ClubChat] { [] }
    func bloques() async -> Set<String> { ListeBlocages.partage.profilsCaches() }
}

/// Un effaceur créé à la première suppression seulement (le fil ouvre une base SwiftData : pas au lancement).
nonisolated struct EffaceurParesseux: EffaceurContenu {
    let creer: @MainActor @Sendable () throws -> any EffaceurContenu

    func effacerContenu(deProfil profilID: String) async throws {
        let effaceur = try await MainActor.run { try creer() }
        try await effaceur.effacerContenu(deProfil: profilID)
    }
}
