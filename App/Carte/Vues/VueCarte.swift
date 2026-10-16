import MapKit
import Network
import SwiftUI
import UIKit
import Core

/// Le volet central : la carte Apple de toute la France avec les stations OFB (E1), la fiche d'un coin (E2),
/// le filtre « Choisir un autre spot » (E3) et le cercle de 1 km du spot gratuit.
///
/// Ce que A branche dans `RootView.swift` :
/// - `services` : les services réels de L1 (en DEBUG, `ServicesCarte.faux()`) ;
/// - `spotFixe` et `sessionsTerminees` : le spot fixé par L5 et le nombre de sessions terminées ;
/// - `bandeauHaut` (vigilance de L12), `bandeauSession` (vue de L5) ;
/// - `emplacementMaintenant` (L12 : rangée « maintenant » et jauge) et `emplacementConseil` (L13 : 1er conseil), vides par défaut ;
/// - `onCommencerSession` (vers L5) et `onSpotChange` (le cercle posé avant la 1re session, à garder).
struct VueCarte: View {
    @State private var modele: ModeleCarte
    @State private var position = GestionPosition()

    let spotFixe: Spot?
    let sessionsTerminees: Int
    let bandeauHaut: AnyView
    let bandeauSession: AnyView
    /// Vrai pendant une session : « Commencer une session » disparaît (le bandeau a « Ajouter une prise »). A le branche sur le moteur de session.
    let sessionEnCours: Bool
    let emplacementMaintenant: (Coordonnee) -> AnyView
    let emplacementConseil: (Espece) -> AnyView
    let onCommencerSession: (Spot) -> Void
    let onSpotChange: (Spot) -> Void
    /// L7 « Où chercher » : la liste des coins proches d'une position, présentée à côté du filtre d'espèce.
    let ouChercher: ((Coordonnee) -> AnyView)?
    /// Vrai tant que le choix de zone ou la redemande est à l'écran : la racine attend avant d'ouvrir une autre feuille.
    let surChoixDeZone: (Bool) -> Void
    /// Vrai quand la racine demande le choix de zone (« Choisir sur la carte » de « Où pêches-tu ? ») :
    /// la feuille s'ouvre, et sa fermeture repasse par `surChoixDeZone(false)`.
    let demandeChoixDeZone: Bool
    /// La pastille de profil (posée par la racine) : à gauche de la barre de recherche de zone, en haut de la carte.
    let pastilleProfil: AnyView
    /// La colonne de boutons à droite : « Tes conditions » (météo) et le profil/réglages, ouverts par la racine.
    let ouvrirMeteo: () -> Void
    let ouvrirProfil: () -> Void
    @Environment(\.dynamicTypeSize) private var tailleDuTexte
    /// Vrai quand la racine demande le « vol vers le spot » (« Voir mon spot » du swipe) : la caméra passe de la zone
    /// au cercle de 1 km, une bulle dit la distance, puis la feuille « Ton spot » monte. Une seule fois (`volFait`).
    let volVersLeSpot: Bool
    @AppStorage("carte.volVersLeSpotFait") private var volFait = false
    @State private var demandeVol = 0
    @State private var bulleSpot = false
    @State private var feuilleSpotMasquee = false
    @State private var afficherOuChercher = false
    /// Vrai : on arrive sur la carte seule (Adem, 16 oct. : « on veut juste la carte », rien qui surgit).
    /// Faux : « Ton spot » (maquette P06 C), ouvert d'un toucher sur le bouton retour de la carte.
    @State private var afficherCarte = true
    /// La feuille « Ton spot » (P06 A) ne monte plus d'elle-même : elle s'ouvre d'un toucher sur la pastille « Ton spot » en haut.
    @State private var feuilleSpotOuverte = false
    /// Les poissons du spot, ouverts d'un toucher sur un poisson ou sur « + N » ; `especeOuverte` est le poisson touché.
    @State private var poissonsOuverts = false
    @State private var especeOuverte: Espece?
    @State private var apercu: ApercuSpot?
    @State private var reseauDisponible = true

    init(services: ServicesCarte,
         spotFixe: Spot? = nil,
         sessionsTerminees: Int = 0,
         bandeauHaut: AnyView = AnyView(EmptyView()),
         bandeauSession: AnyView = AnyView(EmptyView()),
         sessionEnCours: Bool = false,
         emplacementMaintenant: @escaping (Coordonnee) -> AnyView = { _ in AnyView(EmptyView()) },
         emplacementConseil: @escaping (Espece) -> AnyView = { _ in AnyView(EmptyView()) },
         onCommencerSession: @escaping (Spot) -> Void = { _ in },
         onSpotChange: @escaping (Spot) -> Void = { _ in },
         ouChercher: ((Coordonnee) -> AnyView)? = nil,
         surChoixDeZone: @escaping (Bool) -> Void = { _ in },
         demandeChoixDeZone: Bool = false,
         volVersLeSpot: Bool = false,
         pastilleProfil: AnyView = AnyView(EmptyView()),
         ouvrirMeteo: @escaping () -> Void = {},
         ouvrirProfil: @escaping () -> Void = {}) {
        self.pastilleProfil = pastilleProfil
        _modele = State(initialValue: ModeleCarte(services: services))
        self.spotFixe = spotFixe
        self.sessionsTerminees = sessionsTerminees
        self.bandeauHaut = bandeauHaut
        self.bandeauSession = bandeauSession
        self.sessionEnCours = sessionEnCours
        self.emplacementMaintenant = emplacementMaintenant
        self.emplacementConseil = emplacementConseil
        self.onCommencerSession = onCommencerSession
        self.onSpotChange = onSpotChange
        self.ouChercher = ouChercher
        self.surChoixDeZone = surChoixDeZone
        self.demandeChoixDeZone = demandeChoixDeZone
        self.volVersLeSpot = volVersLeSpot
        self.ouvrirMeteo = ouvrirMeteo
        self.ouvrirProfil = ouvrirProfil
    }

    var body: some View {
        ZStack {
            carteComplete
                .accessibilityHidden(!afficherCarte)
            if !afficherCarte {
                ecranSpot
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: afficherCarte)
        .sheet(isPresented: $poissonsOuverts) {
            if let apercu {
                PoissonsDuSpotView(lieu: apercu.lieu, lignes: apercu.toutes, pechable: { modele.pechable($0) },
                                   emplacementConseil: emplacementConseil, touchee: especeOuverte)
            }
        }
        .task(id: modele.spotAffiche) {
            apercu = nil
            guard let spot = modele.spotAffiche else { return }
            apercu = await calculerApercuSpot(services: modele.services, spot: spot, date: Date())
            await modele.rafraichirFrequentation(spot: spot)
        }
        .task {
            for await connecte in fluxReseauCarte() { reseauDisponible = connecte }
        }
        .onChange(of: volVersLeSpot) { _, demande in
            if demande && !volFait { demandeVol += 1 }
        }
        .task(id: demandeVol) { await volerVersLeSpot() }
    }

    // MARK: Vol vers le spot (parcours du 16 oct.)

    /// La carte s'ouvre sur la zone, la caméra vole ~2 s jusqu'au cercle de 1 km, la bulle dit la distance, la feuille monte.
    private func volerVersLeSpot() async {
        guard demandeVol > 0, !volFait else { return }
        feuilleSpotMasquee = true
        defer { feuilleSpotMasquee = false }
        afficherCarte = true
        // Le spot proposé arrive de Core : on l'attend 3 s au plus.
        var essais = 0
        while modele.spotAffiche == nil && essais < 30 {
            try? await Task.sleep(for: .milliseconds(100))
            essais += 1
        }
        try? await Task.sleep(for: .milliseconds(600))
        guard !Task.isCancelled else { return }
        guard let spot = modele.spotAffiche else { volFait = true; return }
        let but = MapCamera(centerCoordinate: Self.cl(spot.centre), distance: 3500)
        modele.marquerDeplacementProgramme(duree: 4.5)
        withAnimation(.easeInOut(duration: 2)) { modele.camera = .camera(but) }
        try? await Task.sleep(for: .milliseconds(2200))
        guard !Task.isCancelled else { return }
        volFait = true
        bulleSpot = true
        feuilleSpotMasquee = false
        try? await Task.sleep(for: .seconds(6))
        withAnimation { bulleSpot = false }
    }

    /// « Ton spot, à 2,3 km. Touche la rivière pour le déplacer » ; sans position, sans distance.
    private var texteBulleSpot: String {
        let debut: String = distanceAuSpot.map { "Ton spot, à \($0)." } ?? "Ton spot."
        return modele.peutChangerDeSpot ? debut + " Touche la rivière pour le déplacer" : debut
    }

    private var bulleDuSpot: some View {
        Text(texteBulleSpot)
            .font(Police.detail)
            .foregroundStyle(Palette.encre)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Espace.l)
            .padding(.vertical, Espace.s)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
            .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
            .onTapGesture { withAnimation { bulleSpot = false } }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: La carte

    // Découpée en petites vues aux types simples : le compilateur ne vérifie jamais tout d'un seul bloc.

    private var carteComplete: some View {
        carteAvecFeuilles
            .alert("Ta position aide à centrer la carte", isPresented: redemandeOuverte) {
                Button("Ouvrir les réglages") { ouvrirLesReglages() }
                Button("Choisir à la main", role: .cancel) { modele.appliquer(position: nil, refusee: true) }
            } message: {
                Text("Sans elle, tu choisis ton département ou ta commune sur la carte. Rien ne bloque.")
            }
            .task { await demarrerLaCarte() }
            .onChange(of: spotFixe) { _, nouveau in modele.recevoir(spotFixe: nouveau) }
            .onChange(of: sessionsTerminees) { _, nouveau in modele.sessionsTerminees = nouveau }
            .onChange(of: position.position) { _, nouvelle in recevoirPosition(nouvelle) }
            .onChange(of: position.statut) { _, _ in reagirAuStatut() }
            .onChange(of: position.echec) { _, echec in if echec { modele.positionIndisponible() } }
            .onChange(of: choixOuRedemandeOuvert) { _, ouvert in surChoixDeZone(ouvert) }
            // La racine demande le choix de zone (« Choisir sur la carte » au premier lancement).
            .onChange(of: demandeChoixDeZone) { _, demande in if demande { modele.afficherChoixDeZone = true } }
            // Le spot proposé (zone choisie ou position) est connu de la racine : tunnel, conseils et conditions s'en servent.
            .onChange(of: modele.spotLocal) { _, nouveau in if let nouveau { onSpotChange(nouveau) } }
    }

    private var carteAvecFeuilles: some View {
        carteAvecBarres
            .sheet(item: selectionOuverte) { selection in feuilleFiche(selection) }
            .sheet(isPresented: filtreOuvert) { feuilleFiltre }
            .sheet(isPresented: $afficherOuChercher) { feuilleOuChercher }
            .fullScreenCover(isPresented: choixDeZoneOuvert) { feuilleChoixDeZone }
    }

    private var carteAvecBarres: some View {
        carteSeule
            .safeAreaInset(edge: .top, spacing: 8) { haut }
            .safeAreaInset(edge: .bottom, spacing: 8) { bas }
    }

    private var carteSeule: some View {
        MapReader { (proxy: MapProxy) in
            carteMapKit(proxy: proxy)
        }
    }

    private func carteMapKit(proxy: MapProxy) -> some View {
        // Les bornes se passent à l'initialiseur de Map : il n'y a pas de modificateur .mapCameraBounds.
        Map(position: cameraLiee, bounds: Self.limitesCamera) {
            contenuCarte
        }
        // Fond clair et sobre de la maquette P06 A : routes et eau, ni commerces ni relief.
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls { MapCompass() }
        .onMapCameraChange(frequency: .onEnd) { (contexte: MapCameraUpdateContext) in
            chargerApresMouvement(contexte.region)
        }
        // Le toucher qui pose le cercle n'existe qu'en mode « poser mon spot » : le reste du temps,
        // la carte garde tous ses gestes (pincer, double toucher, glisser) sans rien qui les retienne.
        .simultaneousGesture(toucherPourPoser(proxy: proxy), including: masqueDuToucher)
    }

    @MapContentBuilder
    private var contenuCarte: some MapContent {
        UserAnnotation()
        if let spot = modele.spotAffiche {
            cercleDuSpot(spot)
        }
        // L'eau d'abord : les stations OFB (poissons relevés) passent par-dessus.
        ForEach(modele.elementsEau) { (element: ElementCarte) in
            annotationEau(element)
        }
        ForEach(modele.elements) { (element: ElementCarte) in
            annotation(element)
        }
    }

    private func annotationEau(_ element: ElementCarte) -> some MapContent {
        Annotation("", coordinate: Self.cl(element.coordonnee)) {
            marqueEau(element)
        }
        .annotationTitles(.hidden)
    }

    private func cercleDuSpot(_ spot: Spot) -> some MapContent {
        MapCircle(center: Self.cl(spot.centre), radius: spot.rayonM)
            .foregroundStyle(Palette.marine.opacity(0.12))
            .stroke(Palette.marine, lineWidth: 2.5)
    }

    private func annotation(_ element: ElementCarte) -> some MapContent {
        Annotation("", coordinate: Self.cl(element.coordonnee)) {
            marque(element)
        }
        .annotationTitles(.hidden)
    }

    private static func cl(_ c: Coordonnee) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
    }

    private static let limitesCamera = MapCameraBounds(centerCoordinateBounds: franceEtVoisins,
                                                       minimumDistance: 300, maximumDistance: altitudeMaximale)

    private var masqueDuToucher: GestureMask {
        modele.modeChoixDuSpot ? .all : .subviews
    }

    private func toucherPourPoser(proxy: MapProxy) -> some Gesture {
        SpatialTapGesture().onEnded { (valeur: SpatialTapGesture.Value) in
            poserSpot(au: valeur.location, proxy: proxy)
        }
    }

    private func poserSpot(au point: CGPoint, proxy: MapProxy) {
        // Le toucher d'une épingle d'eau a déjà posé le cercle, au bon endroit : celui de la carte ne le déplace pas.
        if modele.toucherEauRecent { return }
        guard let c = proxy.convert(point, from: .local) else { return }
        if let spot = modele.poserSpot(en: Coordonnee(latitude: c.latitude, longitude: c.longitude)) {
            onSpotChange(spot)
        }
    }

    private func chargerApresMouvement(_ r: MKCoordinateRegion) {
        let zone = ZoneCarte(centre: Coordonnee(latitude: r.center.latitude, longitude: r.center.longitude),
                             spanLatitude: r.span.latitudeDelta, spanLongitude: r.span.longitudeDelta)
        modele.chargerApresMouvement(zone)
    }

    // MARK: Liaisons (des Binding simples, sans @Bindable dans un long bloc)

    private var cameraLiee: Binding<MapCameraPosition> {
        Binding(get: { modele.camera }, set: { modele.camera = $0 })
    }

    private var selectionOuverte: Binding<CoinSelectionne?> {
        Binding(get: { modele.selection }, set: { modele.selection = $0 })
    }

    private var filtreOuvert: Binding<Bool> {
        Binding(get: { modele.afficherFiltre }, set: { modele.afficherFiltre = $0 })
    }

    private var choixDeZoneOuvert: Binding<Bool> {
        Binding(get: { modele.afficherChoixDeZone }, set: { modele.afficherChoixDeZone = $0 })
    }

    private var redemandeOuverte: Binding<Bool> {
        Binding(get: { modele.afficherRedemande }, set: { modele.afficherRedemande = $0 })
    }

    private var choixOuRedemandeOuvert: Bool {
        modele.afficherChoixDeZone || modele.afficherRedemande
    }

    // MARK: Feuilles de la carte

    /// `nil` pendant une session ou sans spot : la fiche n'a alors pas de bouton « Commencer une session ».
    private var commencerDepuisLaFiche: (() -> Void)? {
        if sessionEnCours { return nil }
        guard modele.spotAffiche != nil else { return nil }
        return {
            guard let spot = modele.spotAffiche else { return }
            modele.selection = nil
            commencer(spot)
        }
    }

    /// Un passage anonyme est enregistré juste avant que la session démarre (tronçon, jour, jeton du jour).
    private func commencer(_ spot: Spot) {
        modele.enregistrerPassage(spot: spot)
        onCommencerSession(spot)
    }

    private func feuilleFiche(_ selection: CoinSelectionne) -> some View {
        FicheCoinView(services: modele.services, selection: selection, pechables: modele.pechables,
                      emplacementMaintenant: emplacementMaintenant, emplacementConseil: emplacementConseil,
                      onCommencerSession: commencerDepuisLaFiche,
                      frequentation: modele.niveauxConnus[selection.id],
                      onCoinCalme: coinCalmeDeLaFiche(selection))
            .presentationDragIndicator(.visible)
            .task(id: selection.id) { await modele.rafraichirFrequentation(selection: selection) }
    }

    /// Le bouton « Coin plus calme » de la fiche : seulement si un coin plus calme existe et que le spot peut encore changer.
    private func coinCalmeDeLaFiche(_ selection: CoinSelectionne) -> (() -> Void)? {
        guard modele.peutChangerDeSpot, modele.tronconsAvecCoinCalme.contains(selection.id) else { return nil }
        return { modele.adopterCoinCalme(depuis: modele.spot(de: selection)) }
    }

    /// Le bouton « Coin plus calme » de la feuille « Ton spot ».
    private var coinCalmeDuSpot: (() -> Void)? {
        guard modele.peutChangerDeSpot, let spot = modele.spotAffiche,
              let t = modele.troncon(de: spot), modele.tronconsAvecCoinCalme.contains(t) else { return nil }
        return { modele.adopterCoinCalme(depuis: spot) }
    }

    private var feuilleFiltre: some View {
        let raretes: [String: NiveauRarete] = raretesDuSecteur()
        return FiltreEspeceView(pechables: modele.pechables, procheDIci: modele.especesProchesDIci(),
                                filtreActuel: modele.filtre, choisir: choisirFiltre, raretes: raretes)
            .presentationDetents([.large])
    }

    private func choisirFiltre(_ espece: EspecePechable?) {
        modele.choisirFiltre(espece)
    }

    @ViewBuilder
    private var feuilleOuChercher: some View {
        if let ouChercher {
            let centre: Coordonnee = modele.spotAffiche?.centre ?? modele.regionVisible.centre
            ouChercher(centre)
                .presentationDetents([.medium, .large])
        }
    }

    private var feuilleChoixDeZone: some View {
        ChoixDeZoneView(choisir: choisirZone, codeDepartement: codeDepartement)
    }

    private func choisirZone(_ coordonnee: Coordonnee) {
        modele.choisirZone(coordonnee)
    }

    private func codeDepartement(_ c: Coordonnee) -> String? {
        let d: Departement = modele.services.geo.departement(de: c)
        return d.estInconnu ? nil : d.code
    }

    // MARK: Départ de la carte

    private func demarrerLaCarte() async {
        modele.spotFixe = spotFixe
        modele.sessionsTerminees = sessionsTerminees
        // Avant toute question de position : le spot fixé ou la dernière zone choisie posent la carte tout de suite.
        modele.placerALOuverture()
        // La permission de position se demande au premier lancement (« Où pêches-tu ? », au toucher
        // « Utiliser ma position »), jamais ici : la carte lit seulement la position si elle est déjà permise.
        position.relire()
        reagirAuStatut()
        if demandeChoixDeZone { modele.afficherChoixDeZone = true }
        await modele.demarrer()
    }

    private func recevoirPosition(_ nouvelle: Coordonnee?) {
        if let nouvelle { modele.appliquer(position: nouvelle, refusee: false) }
    }

    private func ouvrirLesReglages() {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        modele.appliquer(position: nil, refusee: true)
    }

    /// La rareté de chaque espèce dans le département du spot, sinon de la région visible (`Core` donne le verdict).
    private func raretesDuSecteur() -> [String: NiveauRarete] {
        let departement = modele.spotAffiche?.departement ?? modele.services.geo.departement(de: modele.regionVisible.centre)
        guard !departement.estInconnu else { return [:] }
        var resultat: [String: NiveauRarete] = [:]
        for e in modele.pechables {
            resultat[e.espece.id] = modele.services.especes.rarete(espece: e.espece, departement: departement).niveau
        }
        return resultat
    }

    // MARK: Caméra

    /// Le centre de la carte reste au-dessus de la France (Corse comprise) et de ses frontières.
    static let franceEtVoisins = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.4, longitude: 2.6),
                                                    span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 14))
    /// Environ 250 km de large à l'écran au plus dézoomé : un ou deux départements, jamais un pays de bulles.
    static let altitudeMaximale: CLLocationDistance = 400_000

    // MARK: Ton spot (maquette P06 C) et états vides (P46 B)

    private var ecranSpot: some View {
        Group {
            if modele.spotAffiche == nil && modele.depart != .enAttente {
                ecranSansSpot
            } else {
                ecranAvecSpot
            }
        }
        .background(Palette.fond.ignoresSafeArea())
        // Le profil reste atteignable depuis « Ton spot » (la pastille de la racine).
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack { pastilleProfil.frame(maxWidth: 170, alignment: .leading); Spacer(minLength: 0) }
                .padding(.horizontal, 16)
        }
    }

    private func ouvrirLaCarte(poserLeSpot: Bool = false) {
        if poserLeSpot, modele.peutChangerDeSpot { modele.modeChoixDuSpot = true }
        afficherCarte = true
    }

    /// P46 B : « Carte », le bandeau « Pas de réseau » s'il manque, puis « Pas de spot » avec un seul chemin.
    private var ecranSansSpot: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Carte")
                    .font(Police.taille(34, .heavy))
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                if !reseauDisponible {
                    BandeauPasDeReseauView()
                        .padding(.top, 12)
                }
                Text("Ton spot")
                    .font(Police.taille(13, .heavy))
                    .foregroundStyle(Palette.encreDouce)
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .padding(.horizontal, Espace.l)
                    .padding(.top, reseauDisponible ? 12 : 22)
                    .padding(.bottom, Espace.s)
                    .accessibilityAddTraits(.isHeader)
                PasDeSpotView(choisirUnSpot: { ouvrirLaCarte(poserLeSpot: true) })
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
    }

    /// P06 C : le lieu, le poisson le plus pêché en grand, trois autres, « Commencer une session », « Choisir un autre spot ».
    private var ecranAvecSpot: some View {
        VStack(spacing: Espace.l) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(Police.taille(16))
                        .foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                    Text(apercu?.lieu ?? " ")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(1)
                }
                Spacer(minLength: Espace.s)
                Button { ouvrirLaCarte() } label: {
                    Image(systemName: "map")
                        .font(Police.taille(20))
                        .foregroundStyle(Palette.marine)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(Palette.tuile, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voir la carte")
            }
            if !reseauDisponible { BandeauPasDeReseauView() }
            bandeauHaut

            ScrollView {
                vedette
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Espace.s)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: Espace.s) {
                bandeauSession
                if !sessionEnCours {
                VStack(spacing: 2) {
                    Button {
                        if let spot = modele.spotAffiche { commencer(spot) }
                    } label: {
                        Label("Commencer une session", systemImage: "play.fill")
                    }
                    .buttonStyle(.principal)
                    .disabled(modele.spotAffiche == nil)
                    .opacity(modele.spotAffiche == nil ? 0.5 : 1)
                    Button { ouvrirLaCarte(poserLeSpot: true) } label: {
                        Text("Choisir un autre spot")
                            .font(Police.taille(17, .heavy))
                            .foregroundStyle(Palette.encre)
                            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.s)
            .background(Palette.fond)
        }
    }

    @ViewBuilder
    private var vedette: some View {
        if let apercu, let ligne = apercu.vedette {
            let fiche = modele.pechable(ligne.espece)
            let niveau = ligne.rarete?.niveau ?? .nonMesuree
            VStack(spacing: 0) {
                Text("Le plus pêché de ton spot")
                    .font(Police.taille(13))
                    .foregroundStyle(Palette.encreDouce)
                ImageEspeceCarte(nom: fiche?.image)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .padding(.horizontal, Espace.xs)
                    .padding(.top, 40)
                    .contentShape(Rectangle())
                    .onTapGesture { ouvrirPoissons(ligne.espece) }
                    .accessibilityAddTraits(.isButton)
                VStack(spacing: Espace.s) {
                    Text(fiche?.nom ?? ligne.espece.id)
                        .font(Police.taille(34, .heavy))
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if niveau != .nonMesuree {
                        Label(niveau.libelle, systemImage: niveau.symboleSF)
                            .font(Police.taille(13, .heavy))
                            .foregroundStyle(CouleursCarte.rarete(niveau))
                    }
                    Text(texteVedette(ligne))
                        .font(Police.taille(15))
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                autresPoissons(apercu)
                    .padding(.top, 48)
            }
            .accessibilityElement(children: .contain)
        } else if apercu != nil {
            // Un spot sans espèce relevée : le poisson générique, une phrase.
            VStack(spacing: Espace.m) {
                Image(systemName: "fish")
                    .font(Police.taille(64))
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
                Text("Pas encore de relevé ici")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
            }
        } else {
            ProgressView()
                .accessibilityLabel("Lecture des relevés")
        }
    }

    /// « 3 pêches sur 29 · OFB 2024 » : le nombre de pêches et l'année vont toujours ensemble.
    private func texteVedette(_ ligne: LigneEspece) -> String {
        guard let rarete = ligne.rarete else {
            let mot = ligne.nPeches > 1 ? "pêches" : "pêche"
            return "\(ligne.nPeches) \(mot) · OFB \(String(ligne.annee))"
        }
        let mot = rarete.nPeches > 1 ? "pêches" : "pêche"
        let an = rarete.anneeDernierReleve ?? ligne.annee
        let base = "\(rarete.nPeches) \(mot) sur \(rarete.nTotal) · OFB \(an)"
        return rarete.echelle == .region ? base + " · région" : base
    }

    private func autresPoissons(_ apercu: ApercuSpot) -> some View {
        HStack(spacing: 18) {
            ForEach(apercu.autres) { ligne in
                Button { ouvrirPoissons(ligne.espece) } label: {
                    ImageEspeceCarte(nom: modele.pechable(ligne.espece)?.image)
                        .frame(width: 72, height: 34)
                        .frame(minHeight: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(modele.pechable(ligne.espece)?.nom ?? ligne.espece.id)
            }
            if apercu.reste > 0 {
                Button { ouvrirPoissons(nil) } label: {
                    Text("+ \(apercu.reste)")
                        .font(Police.taille(15))
                        .foregroundStyle(Palette.encreDouce)
                        .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Voir les \(apercu.reste) autres poissons du spot")
            }
        }
    }

    // MARK: Départ

    /// Position refusée : une seule redemande, puis le choix à la main. Rien ne bloque.
    private func reagirAuStatut() {
        guard position.estRefusee else { return }
        // La carte est déjà posée (spot fixé ou zone gardée) : pas de redemande qui couvre l'écran.
        if modele.cameraPlacee { return }
        if position.doitRedemanderUneFois() {
            modele.afficherRedemande = true
        } else {
            modele.appliquer(position: nil, refusee: true)
        }
    }

    private func autourDeMoi() {
        if position.estAutorisee {
            if let p = position.position { modele.centrerSurMaPosition(p) }
            position.relire()
        } else {
            modele.afficherChoixDeZone = true
        }
    }

    // MARK: Marques sur la carte

    @ViewBuilder
    private func marque(_ element: ElementCarte) -> some View {
        switch element {
        case .groupe(_, _, let nombre):
            Button { modele.toucher(element) } label: {
                Text("\(nombre)")
                    .font(PolicesCarte.detail())
                    .foregroundStyle(Palette.surMarine)
                    .frame(minWidth: 36, minHeight: 36)
                    .background(Palette.marine, in: Circle())
                    .overlay(Circle().stroke(Palette.surface, lineWidth: 2))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("\(nombre) stations OFB")
            .accessibilityHint("Zoomer pour les voir")
        case .point:
            Button { modele.toucher(element) } label: {
                Image(systemName: "fish.fill")
                    .font(Police.taille(13))
                    .foregroundStyle(Palette.surMarine)
                    .frame(width: 28, height: 28)
                    .background(Palette.marine, in: Circle())
                    .overlay(Circle().stroke(Palette.surface, lineWidth: 2))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Station OFB")
            .accessibilityHint("Ouvre la fiche du coin")
        }
    }

    /// Une épingle d'eau (cours d'eau, plan d'eau, coin public) ou un regroupement. Aucun chiffre : l'eau n'est pas un relevé.
    @ViewBuilder
    private func marqueEau(_ element: ElementCarte) -> some View {
        switch element {
        case .groupe(_, _, let nombre):
            MarqueGroupeEauView(nombre: nombre) { modele.zoomerSurGroupeEau(element) }
        case .point(let p):
            if let spot = modele.spotsEauAffiches[p.id] {
                MarqueEauView(spot: spot, poseLeSpot: modele.peutChangerDeSpot) { toucherEau(spot) }
            }
        }
    }

    private func toucherEau(_ spot: SpotEau) {
        if let pose = modele.toucherEau(spot) { onSpotChange(pose) }
    }

    // MARK: Bandeaux du haut

    private var haut: some View {
        VStack(spacing: 8) {
            ligneProfilEtRecherche
            enTeteCarte
            bandeauHaut
            messageDeCarte
        }
        .padding(.horizontal, 16)
    }

    /// Un message d'état de la carte (aucun relevé, erreur) : seulement quand il y en a un.
    @ViewBuilder
    private var messageDeCarte: some View {
        if let message = modele.message {
            Text(message)
                .font(Police.detail)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(Palette.encre)
                .padding(.horizontal, Espace.m)
                .padding(.vertical, Espace.s)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
    }

    /// Première ligne : la pastille de profil à gauche, la recherche de zone sur le reste de la largeur.
    /// En texte très agrandi, la recherche passe sous la pastille : rien ne se chevauche.
    @ViewBuilder
    private var ligneProfilEtRecherche: some View {
        if tailleDuTexte.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                pastilleProfil.frame(maxWidth: .infinity, alignment: .leading)
                rechercheDeZone
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                pastilleProfil
                    .frame(maxWidth: 170, alignment: .leading)
                rechercheDeZone
                    .frame(minWidth: 140)
            }
        }
    }

    private var rechercheDeZone: some View {
        BarreRechercheZone(choisir: choisirZone, codeDepartement: codeDepartement)
    }

    /// En haut de la carte : retour à « Ton spot », le lieu, le filtre par espèce (maquette P06 A).
    private var enTeteCarte: some View {
        HStack(spacing: 8) {
            BoutonRond(role: .retour, rendu: .verre, action: retourAuSpot)
            // Un toucher sur la pastille ouvre (ou range) la feuille « Ton spot » : elle ne monte jamais d'elle-même.
            Button {
                withAnimation(.spring) { feuilleSpotOuverte.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                        .font(Police.taille(18))
                        .foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                    // « Ton spot · La Marne · 94 » : la pastille dit que c'est le spot, pas la position de l'iPhone.
                    Text(apercu.map { "Ton spot · \($0.lieu)" } ?? "Carte")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if modele.spotAffiche != nil && !sessionEnCours {
                        Image(systemName: feuilleSpotOuverte ? "chevron.down" : "chevron.up")
                            .font(Police.taille(14, .bold))
                            .foregroundStyle(Palette.encreDouce)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, Espace.l)
                .frame(height: Gabarit.zoneTactile)
                .background {
                    Capsule()
                        .fill(.regularMaterial)
                        .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                        .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
                }
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(modele.spotAffiche == nil || sessionEnCours)
            .accessibilityHint(feuilleSpotOuverte ? "Ranger Ton spot" : "Ouvrir Ton spot")
        }
    }

    /// Marine quand un filtre d'espèce est actif (le bouton le dit, sans bandeau en plus), encre sinon.
    private var couleurDuFiltre: Color {
        modele.filtre == nil ? Palette.encre : Palette.marine
    }

    private func retourAuSpot() {
        modele.modeChoixDuSpot = false
        afficherCarte = false
    }

    // MARK: Boutons du bas (au-dessus de la barre d'onglets)

    private var bas: some View {
        VStack(spacing: 8) {
            if bulleSpot {
                bulleDuSpot
            }
            bandeauSession
            HStack(alignment: .bottom, spacing: 12) {
                Spacer(minLength: 0)
                ColonneBoutonsCarte(
                    teinteFiltre: couleurDuFiltre,
                    meteo: ouvrirMeteo,
                    autourDeMoi: autourDeMoi,
                    filtre: { modele.afficherFiltre = true },
                    reglages: ouvrirProfil)
                .padding(.trailing, 8)
            }
            if !sessionEnCours && !feuilleSpotMasquee && feuilleSpotOuverte {
                feuilleSpotCarte
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 0)
    }

    /// Maquette P06 A : la feuille « Ton spot » (poignée, titre et distance, 3 poissons + « + N »,
    /// « Commencer une session », « Choisir un autre spot »), 8 pt de chaque bord, coins de 32 pt.
    private var feuilleSpotCarte: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Palette.filet)
                .frame(width: 36, height: 5)
                .padding(.top, 7)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { fermerFeuilleSpot() }
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("Fermer Ton spot")
            titreFeuilleCarte
            badgeFrequentationSpot
            tuilesFeuilleCarte
                .padding(.top, 14)
                .padding(.bottom, legendeSpotPresente ? 8 : 18)
            legendeSpot
                .padding(.bottom, legendeSpotPresente ? 14 : 0)
            boutonCommencerCarte
            lienAutreSpotCarte
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
        // Glisser vers le bas range la feuille : la carte redevient seule.
        .simultaneousGesture(DragGesture(minimumDistance: 20).onEnded { valeur in
            if valeur.translation.height > 60 { fermerFeuilleSpot() }
        })
    }

    private func fermerFeuilleSpot() {
        withAnimation(.spring) { feuilleSpotOuverte = false }
    }

    private var titreFeuilleCarte: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Ton spot")
                .font(Police.taille(22, .heavy))
                .foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: Espace.s)
            // Seulement quand la position de l'iPhone est connue : jamais de distance inventée.
            if let distance = distanceAuSpot {
                Text(distance)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
            }
        }
    }

    @ViewBuilder
    private var tuilesFeuilleCarte: some View {
        if let apercu {
            let lignes: [LigneEspece] = lignesDeLaFeuille(apercu)
            HStack(alignment: .top, spacing: 10) {
                ForEach(lignes) { (ligne: LigneEspece) in
                    tuilePoissonCarte(ligne)
                }
                if resteDeLaFeuille(apercu) > 0 {
                    tuileResteCarte(resteDeLaFeuille(apercu))
                }
            }
        } else {
            // Relevés en cours de lecture : la place des tuiles reste, sans rien inventer.
            Color.clear.frame(height: 52 + 6 + 14)
        }
    }

    /// Calme, Normal ou Chargé sous le titre (en mots, gratuit) ; rien tant que le niveau n'est pas connu.
    @ViewBuilder
    private var badgeFrequentationSpot: some View {
        if let niveau = modele.niveauDuSpot {
            FrequentationFicheView(niveau: niveau, onCoinCalme: coinCalmeDuSpot)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
        }
    }

    /// « 2,4 km » entre l'iPhone et le centre du spot ; `nil` sans position ou sans spot.
    private var distanceAuSpot: String? {
        guard let moi = position.position, let spot = modele.spotAffiche else { return nil }
        let a = CLLocation(latitude: moi.latitude, longitude: moi.longitude)
        let b = CLLocation(latitude: spot.centre.latitude, longitude: spot.centre.longitude)
        let metres: Double = a.distance(from: b)
        if metres < 1000 { return "\(Int(metres.rounded())) m" }
        let km: Double = (metres / 100).rounded() / 10
        let nombre: String = km.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "fr_FR")))
        return "\(nombre) km"
    }

    private var legendeSpotPresente: Bool {
        modele.spotEauChoisi != nil || apercu?.noteHonnete != nil
    }

    /// Sous les tuiles : le spot d'eau touché et sa source, puis la vérité sur les relevés (jamais un chiffre sans N ni année).
    @ViewBuilder
    private var legendeSpot: some View {
        if legendeSpotPresente {
            VStack(spacing: 4) {
                if let eau = modele.spotEauChoisi {
                    Label(eau.nom, systemImage: eau.origine.symboleSF)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    Text("\(eau.origine.libelle) · source \(eau.origine.source)")
                        .font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
                if let apercu, let note = apercu.noteHonnete {
                    Text(note)
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if let ligne = apercu.vedette, let code = apercu.codeDepartement {
                        let nom = modele.pechable(ligne.espece)?.nom ?? ligne.espece.id
                        Text("\(nom) : présent dans le \(code), \(texteVedette(ligne))")
                            .font(Police.legende)
                            .foregroundStyle(Palette.encreDouce)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    /// Les trois premières espèces du spot : la plus pêchée, puis les suivantes.
    private func lignesDeLaFeuille(_ apercu: ApercuSpot) -> [LigneEspece] {
        var toutes: [LigneEspece] = []
        if let vedette = apercu.vedette { toutes.append(vedette) }
        toutes.append(contentsOf: apercu.autres)
        return Array(toutes.prefix(3))
    }

    private func resteDeLaFeuille(_ apercu: ApercuSpot) -> Int {
        let total: Int = (apercu.vedette == nil ? 0 : 1) + apercu.autres.count + apercu.reste
        return max(0, total - 3)
    }

    private func tuilePoissonCarte(_ ligne: LigneEspece) -> some View {
        let fiche = modele.pechable(ligne.espece)
        let niveau: NiveauRarete = ligne.rarete?.niveau ?? .nonMesuree
        return Button { ouvrirPoissons(ligne.espece) } label: {
            VStack(spacing: 6) {
                ImageEspeceCarte(nom: fiche?.image)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 6)
                    .frame(height: 52)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                marqueRareteCarte(niveau)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(fiche?.nom ?? ligne.espece.id)
        .accessibilityValue(niveau == .nonMesuree ? "" : niveau.libelle)
    }

    @ViewBuilder
    private func marqueRareteCarte(_ niveau: NiveauRarete) -> some View {
        if niveau == .nonMesuree {
            Color.clear.frame(width: 14, height: 14)
        } else {
            Image(systemName: niveau.symboleSF)
                .font(Police.taille(13, .heavy))
                .foregroundStyle(CouleursCarte.rarete(niveau))
                .frame(height: 14)
        }
    }

    private func tuileResteCarte(_ reste: Int) -> some View {
        Button { ouvrirPoissons(nil) } label: {
            VStack(spacing: 6) {
                Text("+ \(reste)")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Palette.filet, lineWidth: 1.5))
                Color.clear.frame(width: 14, height: 14)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Voir les \(reste) autres poissons du spot")
    }

    /// Ouvre tous les poissons du spot, sur le poisson touché s'il y en a un.
    private func ouvrirPoissons(_ espece: Espece?) {
        especeOuverte = espece
        poissonsOuverts = true
    }

    private var boutonCommencerCarte: some View {
        Button {
            if let spot = modele.spotAffiche { commencer(spot) }
        } label: {
            Label("Commencer une session", systemImage: "play.fill")
        }
        .buttonStyle(.principal)
        .disabled(modele.spotAffiche == nil)
        .opacity(modele.spotAffiche == nil ? 0.5 : 1)
    }

    /// « Choisir un autre spot » ; pendant le choix, la consigne prend sa place (toucher l'annule).
    @ViewBuilder
    private var lienAutreSpotCarte: some View {
        if modele.modeChoixDuSpot {
            Button { modele.modeChoixDuSpot = false } label: {
                Text("Touche la rivière pour poser ton cercle de 1 km")
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Touche pour annuler")
        } else if modele.peutChangerDeSpot {
            Button { modele.modeChoixDuSpot = true } label: {
                Text("Choisir un autre spot")
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

/// Le réseau, lu une fois ici : sert seulement à montrer « Pas de réseau ».
nonisolated func fluxReseauCarte() -> AsyncStream<Bool> {
    AsyncStream { continuation in
        let moniteur = NWPathMonitor()
        moniteur.pathUpdateHandler = { chemin in continuation.yield(chemin.status == .satisfied) }
        continuation.onTermination = { _ in moniteur.cancel() }
        moniteur.start(queue: DispatchQueue(label: "carte.reseau"))
    }
}

#if DEBUG
#Preview {
    VueCarte(services: .faux())
}
#endif
