//
//  RootView.swift
//  BuildChallenge
//
//  A seul. Seul endroit qui connaît plusieurs dossiers de l'app (docs/architecture.md, « RootView »).
//  3 volets (Pescedex, Carte, Mon club), ouverture sur Carte (docs/architecture.md l.13, docs/lots.md l.7).
//

import Core
import Observation
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

    var id: String {
        switch self {
        case .tunnel: "tunnel"
        case .consentement: "consentement"
        case .paywall(let d): "paywall-\(d.valeurMesure)"
        case .prise: "prise"
        case .carteAEssayer: "carte-a-essayer"
        }
    }
}

/// Une demande de paywall faite depuis une feuille déjà ouverte (fiche d'un coin) : la feuille la présente elle-même.
struct PaywallDemande: Identifiable {
    let declencheur: DeclencheurPaywall
    var id: String { declencheur.valeurMesure }
}

// MARK: - Assemblage et parcours

@MainActor @Observable
final class ParcoursApp {
    // Services
    @ObservationIgnored let core: MoteurCore
    @ObservationIgnored let servicesCarte: ServicesCarte
    @ObservationIgnored let servicesPrise: PriseServices
    @ObservationIgnored let conseils: any ServiceConseils
    @ObservationIgnored let conditions: ConditionsDuSpot
    @ObservationIgnored let marque: StockageMarque
    @ObservationIgnored let previensMoi: PreviensMoiModele
    @ObservationIgnored let mesure: CoucheMesure
    @ObservationIgnored let achats: AchatsStoreKit

    /// L4 : le dépôt des cartes, créé une seule fois (SwiftData local, photos sans GPS dans Application Support).
    /// `nil` seulement si SwiftData ne s'ouvre ni sur disque ni en mémoire : le volet Pescedex reste alors vide.
    @ObservationIgnored let depot: DepotCartes?
    let pescedex: PescedexModele?
    /// Cartes rendues par L4 pour le partage de L9 (recto seul, sans météo).
    var cartesAPartager: [CarteAPartager] = []

    let moteur: SuiviSession
    let suivi: SuiviAbonnement

    // État de navigation
    var onglet: Onglet = .carte
    var courant: Modal?
    private var attente: [Modal] = []
    var positionPassee = false
    var consentement: Consentement
    private var consentementPropose = false
    private var carteListeEnvoyee = false

    // Spot
    var spotCourant: Spot?
    private var spotSession: Spot?
    private var spotEnAttente: Spot?

    init(configurerMesure: @escaping @MainActor @Sendable () -> Void) {
        let core = MoteurCore(donnees: .embarque(reglesTelechargees: ReglesAJour.dossierCopies))
        self.core = core
        servicesCarte = ServicesCarte(geo: core.geo, regles: core.regles, especes: core.especes, session: core.session)
        // Reconnaissance : modèle DINOv2 embarqué (App/Prise/Modele), sous 0,4 de confiance la grille des espèces s'ouvre.
        servicesPrise = PriseServices(especes: core.especes, regles: core.regles, identification: IdentificationDino())
        // Repli sur le faux de Core si conseils.json ne se charge pas (à vérifier sur le Mac).
        conseils = (try? ConseilsParEspece.charger(regles: core.regles)) ?? ConseilsFaux()
        conditions = ConditionsDuSpot(meteo: SourceWeatherKit(), eau: core.niveauEau, noyau: core.conditions)
        marque = StockageMarque(source: SourceMarqueWeatherKit())
        previensMoi = PreviensMoiModele(notifieur: NotifieurSysteme())

        let servicesCollection = ServicesCollection(especes: core.especes, soleil: core.soleil, regles: core.regles)
        if let conteneur = (try? DepotCartes.creerConteneur()) ?? (try? DepotCartes.creerConteneur(enMemoire: true)) {
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
    }

    /// Au lancement : l'accord déjà donné configure le SDK, StoreKit écoute, la session est reprise.
    func demarrer() async {
        mesure.demarrerSiAccorde()
        achats.demarrerEcoute()
        suivi.demarrer()
        moteur.abonne = suivi.abonne
        moteur.reprendre()
        await rafraichirCollection()
        await marque.rafraichir()
        Task.detached(priority: .utility) { await ReglesAJour.lancer() }
    }

    // MARK: Collection (L4)

    /// Recharge le Pescedex et les cartes partageables de L9 après une écriture dans le dépôt.
    func rafraichirCollection() async {
        guard let depot else { return }
        await pescedex?.charger()
        let noms = Dictionary(core.especes.especesPechables().map { ($0.espece, $0.nom) }, uniquingKeysWith: { a, _ in a })
        var cartes: [CarteAPartager] = []
        for prise in await depot.cartes() {
            guard let png = await depot.imagePNG(de: prise) else { continue }
            cartes.append(CarteAPartager(id: prise.id.uuidString, titre: noms[prise.espece] ?? "Carte FishMe", png: png))
        }
        cartesAPartager = cartes
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
    var questionNiveauPermise: Bool { positionPassee && courant == nil && attente.isEmpty }

    func proposerSuitePremierLancement() {
        guard courant == nil, attente.isEmpty, questionVue else { return }
        if !tunnelVu {
            UserDefaults.standard.set(true, forKey: ClesConseils.tunnelVu)
            courant = .tunnel
        } else if consentement == .inconnu, !consentementPropose {
            consentementPropose = true
            courant = .consentement
        }
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
        spotCourant = spot
        Task { await conditions.lire(spot: spot.centre) }
    }

    var surSonSpot: Bool {
        guard let courant = spotCourant, let gratuit = moteur.spotGratuit else { return true }
        return distanceMetres(courant.centre, gratuit.centre) <= gratuit.rayonM
    }

    func autorise(_ fonction: FonctionPro) -> Bool {
        core.session.peutUtiliser(fonction, abonne: suivi.abonne, surSonSpot: surSonSpot)
    }

    // MARK: Session

    func commencer(_ spot: Spot) {
        spotCourant = spot
        let depart = ContexteDepart(coordonnee: spot.centre, departement: spot.departement, spotChoisi: spot,
                                    abonne: suivi.abonne, conditions: conditions.instantane(spot: spot.centre))
        switch moteur.commencer(depart) {
        case .demarree:
            spotSession = spot
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
        mesure.envoyer(.sessionFinie)
        if fin.sortie.prises.isEmpty {
            // Session sans prise : carte bredouille (L4). La révélation avant le paywall n'est pas ouverte ici : elle se voit dans le Pescedex.
            let sortie = fin.sortie
            let lieuFlou = coordonneeSession.map { core.geo.lieuFlou($0) }
            Task { _ = await ecrire { try await $0.enregistrerBredouille(sortie: sortie, lieuFlou: lieuFlou) } }
        }
        if fin.paywall == .quiSeFerme { montrer(.paywall(.finPremiereSession)) }
        moteur.acquitterFin()
        spotSession = nil
    }

    private var coordonneeSession: Coordonnee? { spotSession?.centre ?? moteur.spotGratuit?.centre }

    func ajouterPrise() {
        guard coordonneeSession != nil else { return }
        mesure.envoyer(.priseCommencee)
        montrer(.prise)
    }

    func contextePrise() -> PriseContexte {
        let c = coordonneeSession ?? Coordonnee(latitude: 0, longitude: 0)
        return PriseContexte(coordonnee: c, lieu: core.geo.lieu(de: c, choix: nil), lieuFlou: core.geo.lieuFlou(c),
                             date: moteur.maintenant(), prisesDuJour: moteur.prisesGardeesDuJour())
    }

    func terminerPrise(_ confirmee: PriseConfirmee?) {
        courant = nil
        guard let confirmee else { return }
        let instantane = coordonneeSession.flatMap { conditions.instantane(spot: $0) }
        moteur.ajouter(prise: confirmee.prise, conditions: instantane)
        let prise = confirmee.prise
        let photo = confirmee.photo
        let duree = moteur.enCours.map { moteur.maintenant().timeIntervalSince($0.sortie.debut) }
        Task {
            // `.carteCreee` ne part qu'une fois la carte réellement enregistrée.
            if await ecrire({ _ = try await $0.enregistrer(prise: prise, photo: photo, conditions: instantane, dureeSecondes: duree) }) {
                mesure.envoyer(.carteCreee)
            }
        }
    }

    /// Carte déclarée du swipe du premier lancement (L4) : sans photo, ne compte pas comme une prise.
    func declarer(_ prise: Prise) {
        Task { _ = await ecrire { _ = try await $0.enregistrerDeclaree(espece: prise.espece, date: prise.date) } }
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

// MARK: - Vue racine

struct RootView: View {
    @State private var app: ParcoursApp
    @AppStorage(ClesConseils.questionVue) private var questionVue = false

    /// `configurerMesure` : la seule fermeture qui appelle `Spark.configure` (dans `BuildChallengeApp.swift`), jamais avant l'accord.
    init(configurerMesure: @escaping @MainActor @Sendable () -> Void = {}) {
        _app = State(initialValue: ParcoursApp(configurerMesure: configurerMesure))
    }

    var body: some View {
        corps
            .task { await app.demarrer() }
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

    private var onglets: some View {
        TabView(selection: $app.onglet) {
            Tab("Pescedex", systemImage: "square.grid.2x2.fill", value: Onglet.pescedex) {
                pescedex
            }
            Tab("Carte", systemImage: "map.fill", value: Onglet.carte) {
                carte
            }
            Tab("Mon club", systemImage: "person.2.fill", value: Onglet.club) {
                club
            }
        }
        .sheet(item: $app.courant, onDismiss: { app.feuilleFermee() }) { modal in
            vue(de: modal)
        }
        .onChange(of: questionVue) { app.proposerSuitePremierLancement() }
        .onChange(of: app.suivi.abonne) { _, abonne in app.moteur.abonne = abonne }
        .task {
            try? await Task.sleep(for: .seconds(1))
            app.positionPassee = true
            app.proposerSuitePremierLancement()
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
                    meteoDuDos: { conditions in AnyView(BlocConditionsPriseView(conditions: conditions, marque: app.marque)) }))
        } else {
            ContentUnavailableView("Pescedex", systemImage: "square.grid.2x2.fill",
                                   description: Text("Tes cartes ne peuvent pas s'ouvrir pour l'instant."))
        }
    }

    // MARK: Volet Carte (L2) avec L5, L12, L13

    private var carte: some View {
        VueCarte(
            services: app.servicesCarte,
            spotFixe: app.moteur.spotGratuit,
            sessionsTerminees: app.moteur.sessionsTerminees,
            bandeauHaut: AnyView(VigilanceEmplacement(app: app)),
            bandeauSession: AnyView(
                BandeauSession(moteur: app.moteur, ajouterPrise: { app.ajouterPrise() }) {
                    LigneSessionEmplacement(app: app)
                }),
            emplacementMaintenant: { coordonnee in AnyView(ConditionsEmplacement(app: app, coordonnee: coordonnee)) },
            emplacementConseil: { espece in AnyView(ConseilEmplacement(app: app, espece: espece)) },
            onCommencerSession: { spot in app.commencer(spot) },
            onSpotChange: { spot in app.spotChange(spot) },
            ouChercher: { position in AnyView(OuChercherVue(especes: app.core.coins(), position: position)) })
            .questionNiveau(declenchee: app.questionNiveauPermise)
            .task { app.carteListe() }
    }

    // MARK: Volet Mon club (L9) avec L6

    private var club: some View {
        let departement = app.moteur.spotGratuit?.departement ?? .inconnu
        let federation = app.core.regles.liensFederation(departement: departement)
        let liens = LiensClub(
            federation: federation.siteFederation.flatMap { URL(string: $0) },
            association: nil,
            carteDePeche: federation.pageCarteDePeche.flatMap { URL(string: $0) } ?? LiensOfficiels.carteDePeche,
            confidentialite: nil)
        let sources = app.core.regles.credits().map { c in
            SourceClub(nom: c.nom, mention: c.mention ?? "", lien: c.url.flatMap { URL(string: $0) })
        }
        return ClubView(
            liens: liens, sources: sources,
            cartes: app.cartesAPartager,
            mesureUsage: Binding(get: { app.consentement == .accepte }, set: { app.reglerMesure($0) })
        ) {
            MarqueMeteoView(stockage: app.marque)
        }
        // « Tes conditions » (TesConditionsView, Pro) : ClubView n'a pas d'emplacement pour elle, non branchée.
    }

    // MARK: Écrans modaux

    @ViewBuilder private func vue(de modal: Modal) -> some View {
        switch modal {
        case .tunnel:
            let proches = app.spotCourant.map { app.core.especes.especesProches($0.centre) } ?? []
            TunnelPremiersPasView(
                especes: EspecesDuTunnel.choisir(pechables: app.core.especes.especesPechables(), proches: proches),
                maintenant: { app.moteur.maintenant() },
                declarer: { prise in app.declarer(prise) },
                pecherMaintenant: {
                    app.courant = nil
                    app.onglet = .carte
                    if let spot = app.spotCourant { app.attenteDepart(spot) }
                },
                choisirUnSpot: { app.courant = nil; app.onglet = .carte },
                passer: { app.courant = nil })

        case .consentement:
            FeuilleConsentement(accepter: { app.accorderOuRefuser(true) }, refuser: { app.accorderOuRefuser(false) })
                .presentationDetents([.medium])

        case .paywall(let declencheur):
            app.paywall(declencheur, fermer: { app.courant = nil })

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

    var body: some View {
        Group {
            if let alerte { BandeauVigilanceView(alerte: alerte) }
        }
        .task(id: app.spotCourant?.centre) {
            guard let spot = app.spotCourant?.centre else { alerte = nil; return }
            let lecture = await app.conditions.lire(spot: spot) ?? app.conditions.derniere(spot: spot)
            alerte = lecture?.alerte
        }
    }
}

/// Ligne de conditions du bandeau de session (L12 dans L5), seulement si une lecture existe.
private struct LigneSessionEmplacement: View {
    let app: ParcoursApp
    @State private var lecture: LectureConditions?

    var body: some View {
        Group {
            if let lecture { LigneConditionsSession(lecture: lecture, marque: app.marque) }
        }
        .task(id: app.moteur.enCours != nil) {
            guard let c = app.spotCourant?.centre ?? app.moteur.spotGratuit?.centre else { return }
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
    @State private var septJours = false
    @State private var courbe = false
    @State private var previens = false
    @State private var paywall: PaywallDemande?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let lecture {
                RangeeMaintenantView(lecture: lecture, marque: app.marque)
                JaugeRiviereView(lecture: lecture, ouvrirCourbe: { ouvrir(.courbeEtNormale) { courbe = true } })
                bouton("7 jours", "calendar", .septJours) { septJours = true }
                bouton("Préviens-moi", "bell", .prevenirMoi) { previens = true }
            } else {
                RangeeMaintenantVideView()
            }
        }
        .task(id: coordonnee) {
            lecture = app.conditions.derniere(spot: coordonnee)
            lecture = await app.conditions.lire(spot: coordonnee) ?? lecture
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
        if app.autorise(fonction) { action() } else { paywall = PaywallDemande(declencheur: .fonction(fonction)) }
    }

    @ViewBuilder private func bouton(_ titre: String, _ icone: String, _ fonction: FonctionPro, _ action: @escaping () -> Void) -> some View {
        if app.autorise(fonction) {
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

/// « Tes conditions » (L12, Pro) ouvert depuis le Pescedex : les comptes de ses propres sorties, ou le paywall.
private struct TesConditionsEmplacement: View {
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

#Preview {
    RootView()
}
