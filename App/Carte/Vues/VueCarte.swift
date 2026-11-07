import MapKit
import Network
import SwiftUI
import UIKit
import Core

/// Le volet central : la carte Apple de toute la France avec les stations OFB (E1), la fiche d'un coin (E2),
/// le filtre « Choisir un autre spot » (E3), le cercle de 1 km du spot gratuit et la feuille « Mon spot ».
///
/// Deux états séparés (L17) : la caméra (où la carte regarde) et le spot (où le cercle est posé). La carte s'ouvre sur le pêcheur,
/// « Ma position » recentre la caméra, rien de cela ne déplace le cercle. Les feuilles du bas (fiche d'un coin, « Mon spot »)
/// ont trois hauteurs et la carte réserve leur hauteur : la mention légale de Plans reste lisible au-dessus d'elles.
///
/// Ce que A branche dans `RootView.swift` (tout ce qui est nouveau a une valeur par défaut : rien ne casse) :
/// - `services` : les services réels de L1 (en DEBUG, `ServicesCarte.faux()`) ;
/// - `spotFixe` et `sessionsTerminees` : le spot fixé par L5 et le nombre de sessions terminées ;
/// - `bandeauHaut` (vigilance de L12), `bandeauSession` (vue de L5) ;
/// - `emplacementMaintenant` (L12 : rangée « maintenant » ; sert aussi à la météo du moment de « Mon spot ») et `emplacementConseil` (L13) ;
/// - `onCommencerSession` (vers L5) et `onSpotChange` (le cercle posé avant la 1re session, à garder) ;
/// - `prisesDuPecheur` (nouveau) : la lecture des prises et de leurs photos, pour les vignettes (`CollectionCartes.cartes()` et `DepotCartes`) ;
/// - `ReglageNavigationView()` (nouveau) : à poser dans l'écran des réglages, la préférence de « Y aller ».
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
    /// Les prises du pêcheur et leurs photos, pour les vignettes de la fiche d'un coin. Elles restent sur l'iPhone.
    let prisesDuPecheur: PrisesDuPecheurCarte
    @Environment(\.dynamicTypeSize) private var tailleDuTexte
    /// Vrai quand la racine demande le « vol vers le spot » (« Voir mon spot » du swipe) : la caméra passe de la zone
    /// au cercle de 1 km, une bulle dit la distance, puis la feuille « Mon spot » monte. Une seule fois (`volFait`).
    let volVersLeSpot: Bool
    @AppStorage("carte.volVersLeSpotFait") private var volFait = false
    @State private var demandeVol = 0
    @State private var bulleSpot = false
    @State private var feuilleSpotMasquee = false
    @State private var afficherOuChercher = false
    /// La feuille « Mon spot » ne monte pas d'elle-même : elle s'ouvre d'un toucher sur la pastille « Mon spot » en haut.
    @State private var feuilleSpotOuverte = false
    @State private var detentSpot: DetentPanneau = .moyen
    @State private var departDemande = false
    @State private var detentFiche: DetentPanneau = .moyen
    /// Les poissons du spot, ouverts d'un toucher sur un poisson ou sur « + N » ; `especeOuverte` est le poisson touché.
    @State private var poissonsOuverts = false
    @State private var especeOuverte: Espece?
    @State private var reglesDuSpotOuvertes = false
    /// « Y aller » : le coin choisi, tant que la feuille « Y aller avec » demande l'application.
    @State private var destination: DestinationItineraire?
    @State private var apercu: ApercuSpot?
    @State private var reseauDisponible = true
    /// N6 : calque des repères privés, éteint au premier lancement (même clé que `InterrupteurCalqueReperes`).
    @AppStorage(InterrupteurCalqueReperes.cle) private var calqueReperes = false
    @State private var nouveauRepere: PointReperes?
    @State private var repereOuvert: Repere?
    @State private var listeReperesOuverte = false
    @State private var reglesRepere: PointReperes?

    /// Un point choisi sur la carte pour les repères (nouveau repère, règles à cette coordonnée). Reste sur l'iPhone.
    private struct PointReperes: Identifiable {
        let id = UUID()
        let position: Coordonnee
    }

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
         ouvrirProfil: @escaping () -> Void = {},
         prisesDuPecheur: PrisesDuPecheurCarte = .aucune) {
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
        self.prisesDuPecheur = prisesDuPecheur
    }

    var body: some View {
        GeometryReader { (geo: GeometryProxy) in
            ZStack(alignment: .bottom) {
                carteComplete(total: geo.size.height)
                feuilleDuBas(total: geo.size.height, reserveBas: 0)
            }
            // Une seule animation pour l'arrivée et le départ des feuilles et pour la réserve de la carte : pas d'artefact à la fermeture.
            .animation(.snappy(duration: 0.3), value: modele.selection?.id)
            .animation(.snappy(duration: 0.3), value: feuilleSpotVisible)
        }
        .sheet(isPresented: $poissonsOuverts) {
            if let apercu {
                PoissonsDuSpotView(lieu: apercu.lieu, lignes: apercu.toutes, pechable: { modele.pechable($0) },
                                   emplacementConseil: emplacementConseil, touchee: especeOuverte)
            }
        }
        .sheet(isPresented: $reglesDuSpotOuvertes) { feuilleReglesDuSpot }
        .sheet(item: $destination) { (cible: DestinationItineraire) in feuilleChoixNavigation(cible) }
        .sheet(item: $nouveauRepere) { (point: PointReperes) in feuilleNouveauRepere(point) }
        .sheet(item: $repereOuvert) { (repere: Repere) in feuilleRepere(repere) }
        .sheet(isPresented: $listeReperesOuverte) { feuilleListeReperes }
        .sheet(item: $reglesRepere) { (point: PointReperes) in feuilleReglesIci(point) }
        .task(id: calqueReperes) {
            // Éteint, la carte ne lit ni repère ni photo.
            if calqueReperes { await ModeleReperes.partage.chargerSiBesoin() }
        }
        .onAppear { ContexteReperes.courant.brancherReglesIci { (c: Coordonnee) in demanderReglesIci(c) } }
        .onDisappear { ContexteReperes.courant.brancherReglesIci(nil) }
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
        .onChange(of: modele.selection?.id) { _, nouvelle in
            // Une nouvelle fiche s'ouvre au cran moyen et range « Mon spot » : une seule feuille à la fois.
            if nouvelle != nil {
                detentFiche = .moyen
                feuilleSpotOuverte = false
            }
        }
        .task(id: demandeVol) { await volerVersLeSpot() }
    }

    // MARK: Vol vers le spot (parcours du 16 oct.)

    /// La carte s'ouvre sur la zone, la caméra vole ~2 s jusqu'au cercle de 1 km, la bulle dit la distance, la feuille monte.
    private func volerVersLeSpot() async {
        guard demandeVol > 0, !volFait else { return }
        feuilleSpotMasquee = true
        defer { feuilleSpotMasquee = false }
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

    /// « Mon spot, à 2,3 km. Touche la rivière pour le déplacer » ; sans position, sans distance.
    private var texteBulleSpot: String {
        let debut: String = distanceAuSpot.map { "Mon spot, à \($0)." } ?? "Mon spot."
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

    /// Pendant « Choisir un autre spot » : la consigne flotte au-dessus de la carte (toucher l'annule).
    private var bulleChoixDuSpot: some View {
        Button { modele.modeChoixDuSpot = false } label: {
            Text("Touche la rivière pour poser ton cercle de 1 km")
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Espace.l)
                .padding(.vertical, Espace.s)
                .frame(minHeight: Gabarit.zoneTactile)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Touche pour annuler")
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: La carte

    // Découpée en petites vues aux types simples : le compilateur ne vérifie jamais tout d'un seul bloc.

    private func carteComplete(total: CGFloat) -> some View {
        carteAvecFeuilles(total: total)
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

    private func carteAvecFeuilles(total: CGFloat) -> some View {
        carteAvecBarres(total: total)
            .sheet(isPresented: filtreOuvert) { feuilleFiltre }
            .sheet(isPresented: $afficherOuChercher) { feuilleOuChercher }
            .fullScreenCover(isPresented: choixDeZoneOuvert) { feuilleChoixDeZone }
    }

    /// La hauteur que la carte réserve en bas pour la feuille ouverte : la mention légale de Plans (Apple, en bas de la carte)
    /// reste au-dessus de la feuille, à chaque hauteur. Elle ne change qu'aux crans, jamais pendant le glissement.
    private func reservation(total: CGFloat) -> CGFloat {
        if modele.selection != nil { return CGFloat(detentFiche.reservation(dans: Double(total))) }
        if feuilleSpotVisible { return CGFloat(detentSpot.reservation(dans: Double(total))) }
        return 0
    }

    private var feuilleSpotVisible: Bool { feuilleSpotOuverte && !sessionEnCours && !feuilleSpotMasquee }

    private func carteAvecBarres(total: CGFloat) -> some View {
        let reserve: CGFloat = reservation(total: total)
        return carteSeule
            .safeAreaInset(edge: .top, spacing: 8) { haut }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear
                    .frame(height: reserve)
                    .animation(.snappy(duration: 0.28), value: reserve)
            }
            // Les boutons de droite flottent au-dessus de la mention légale (36 pt) et de la feuille : ils ne la poussent plus.
            .overlay(alignment: .bottom) { bas.padding(.bottom, reserve + 36) }
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
        // N6 : l'appui long pose un repère. Un geste à part du toucher qui pose le cercle : il ne déplace ni le spot ni la caméra.
        .simultaneousGesture(appuiLongPourReperer(proxy: proxy), including: .all)
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
            contenuStation(element)
        }
        // N6 : les repères du pêcheur, hors du plafond de 60 (jamais regroupés), cachés quand la carte est dézoomée.
        if !reperesAffiches.isEmpty {
            CalqueReperes(reperes: reperesAffiches,
                          afficherNoms: CalqueReperes.afficheLesNoms(spanLatitude: modele.regionVisible.spanLatitude),
                          ouvrir: { (repere: Repere) in repereOuvert = repere })
        }
    }

    private var reperesAffiches: [Repere] {
        ReperesSurCarte.visibles(ModeleReperes.partage.reperes, region: modele.regionVisible, calqueAllume: calqueReperes)
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

    /// Une station recalée : une épingle. Une station `recalee == false` : un halo de 1 km, jamais d'épingle.
    @MapContentBuilder
    private func contenuStation(_ element: ElementCarte) -> some MapContent {
        if let point = pointEnHalo(element) {
            haloDeStation(point)
        } else {
            annotation(element)
        }
    }

    private func pointEnHalo(_ element: ElementCarte) -> PointCarte? {
        if case .point(let p) = element, !p.recalee { return p }
        return nil
    }

    /// Le halo : la station n'est pas posée sur l'eau (arrondi à 0,01°), la carte ne prétend pas savoir où elle est à moins de 1 km.
    /// Une cible invisible de 44 pt au centre ouvre la fiche ; aucune épingle n'est dessinée.
    @MapContentBuilder
    private func haloDeStation(_ p: PointCarte) -> some MapContent {
        MapCircle(center: Self.cl(p.coordonnee), radius: 1000)
            .foregroundStyle(Palette.encreDouce.opacity(0.14))
            .stroke(Palette.encreDouce.opacity(0.55), lineWidth: 1.5)
        Annotation("", coordinate: Self.cl(p.coordonnee)) {
            cibleDuHalo(p)
        }
        .annotationTitles(.hidden)
    }

    private func cibleDuHalo(_ p: PointCarte) -> some View {
        Button { modele.toucher(.point(p)) } label: {
            Color.clear
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Zone de station OFB, position approximative")
        .accessibilityHint("Ouvre la fiche du coin")
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

    /// Appui long (0,6 s) puis relâchement presque au même endroit : le point touché devient un nouveau repère.
    private func appuiLongPourReperer(proxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.6)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onEnded { (valeur: SequenceGesture<LongPressGesture, DragGesture>.Value) in
                guard case .second(true, let doigt?) = valeur else { return }
                let glissement = Double(hypot(doigt.translation.width, doigt.translation.height))
                guard ReperesSurCarte.gestePoseUnRepere(glissement: glissement),
                      ReperesSurCarte.peutPoser(region: modele.regionVisible, modeChoixDuSpot: modele.modeChoixDuSpot),
                      nouveauRepere == nil, repereOuvert == nil,
                      let c = proxy.convert(doigt.startLocation, from: .local) else { return }
                nouveauRepere = PointReperes(position: Coordonnee(latitude: c.latitude, longitude: c.longitude))
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

    /// La feuille du bas : la fiche d'un coin si un coin est touché, sinon « Mon spot » s'il est ouvert. Une seule à la fois.
    @ViewBuilder
    private func feuilleDuBas(total: CGFloat, reserveBas: CGFloat) -> some View {
        if let selection = modele.selection {
            PanneauRedimensionnable(detent: $detentFiche, total: total, fermable: true, fermer: { modele.selection = nil },
                                    reserveBas: reserveBas) {
                feuilleFiche(selection)
                    .id(selection.id)
            }
            .transition(.move(edge: .bottom))
        } else if feuilleSpotVisible {
            PanneauRedimensionnable(detent: $detentSpot, total: total, fermable: true, fermer: fermerFeuilleSpot,
                                    reserveBas: reserveBas) {
                feuilleMonSpot
            }
            .transition(.move(edge: .bottom))
        }
    }

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
    /// B10 : un second toucher arrivé avant que l'écran ne change (appareil lent) ne relance pas le départ : une demande à la fois.
    private func commencer(_ spot: Spot) {
        guard !departDemande, !sessionEnCours else { return }
        departDemande = true
        Task { try? await Task.sleep(for: .seconds(1.5)); departDemande = false }
        modele.enregistrerPassage(spot: spot)
        onCommencerSession(spot)
    }

    private func feuilleFiche(_ selection: CoinSelectionne) -> some View {
        FicheCoinView(services: modele.services, selection: selection, pechables: modele.pechables,
                      detent: detentFiche,
                      emplacementMaintenant: emplacementMaintenant, emplacementConseil: emplacementConseil,
                      onCommencerSession: commencerDepuisLaFiche,
                      frequentation: modele.niveauxConnus[selection.id],
                      onCoinCalme: coinCalmeDeLaFiche(selection),
                      onYAller: yAller,
                      onPoserLeSpot: poserLeSpotDepuisLaFiche(selection),
                      prisesDuPecheur: prisesDuPecheur,
                      fermer: { modele.selection = nil })
            .task(id: selection.id) { await modele.rafraichirFrequentation(selection: selection) }
    }

    /// Le bouton « Coin plus calme » de la fiche : seulement si un coin plus calme existe et que le spot peut encore changer.
    private func coinCalmeDeLaFiche(_ selection: CoinSelectionne) -> (() -> Void)? {
        guard modele.peutChangerDeSpot, modele.tronconsAvecCoinCalme.contains(selection.id) else { return nil }
        return { modele.adopterCoinCalme(depuis: modele.spot(de: selection)) }
    }

    /// « Poser mon spot ici » : changer de spot depuis la fiche, tant que le spot peut changer. Pose le cercle sur la station.
    private func poserLeSpotDepuisLaFiche(_ selection: CoinSelectionne) -> (() -> Void)? {
        guard modele.peutChangerDeSpot, !sessionEnCours else { return nil }
        return {
            if let spot = modele.poserSpot(en: selection.coordonnee) {
                onSpotChange(spot)
                modele.selection = nil
            }
        }
    }

    /// Le bouton « Coin plus calme » de la feuille « Mon spot ».
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

    // MARK: Y aller (décision 9 du 19 oct.)

    /// Au premier toucher : la feuille demande l'application (Plans, Waze, Google Maps installés) avec « Toujours utiliser ».
    /// Ensuite, ou si seul Plans est là, l'itinéraire s'ouvre directement. La coordonnée envoyée est celle de la STATION.
    private func yAller(_ c: Coordonnee, _ nom: String) {
        switch LanceurItineraire.decision() {
        case .ouvrir(let application):
            LanceurItineraire.ouvrir(application, vers: c, nom: nom)
        case .demander:
            destination = DestinationItineraire(coordonnee: c, nom: nom)
        }
    }

    private func feuilleChoixNavigation(_ cible: DestinationItineraire) -> some View {
        ChoixNavigationView(applications: LanceurItineraire.installees()) { application, toujours in
            if toujours { PreferenceItineraire.ecrire(application) }
            destination = nil
            LanceurItineraire.ouvrir(application, vers: cible.coordonnee, nom: cible.nom)
        }
    }

    // MARK: Départ de la carte

    private func demarrerLaCarte() async {
        modele.spotFixe = spotFixe
        modele.sessionsTerminees = sessionsTerminees
        // Avant toute question de position : le spot fixé ou la dernière zone choisie posent la carte tout de suite ;
        // la première position qui arrive la reposera sur le pêcheur (le cercle du spot reste où il est).
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

    /// « Ma position » : la caméra va sur le pêcheur. Le cercle du spot ne bouge pas.
    private func autourDeMoi() {
        if position.estAutorisee {
            modele.demanderRecentrage()
            position.relire()
        } else {
            modele.afficherChoixDeZone = true
        }
    }

    /// Position approximative (réglage « Position précise » éteint) : demande la précision exacte, ou ouvre les réglages d'iOS.
    private func preciserLaPosition() {
        if Bundle.main.object(forInfoDictionaryKey: "NSLocationTemporaryUsageDescriptionDictionary") != nil {
            position.demanderPrecisionExacte()
        } else if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
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
            pastilleMonSpot
            if !reseauDisponible { BandeauPasDeReseauView() }
            if position.estAutorisee && position.precisionReduite { boutonPrecision }
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

    /// Le point de départ de la feuille « Mon spot » : une seule pastille en haut de la carte, aucun bouton retour.
    /// Un toucher ouvre ou range la feuille ; elle ne monte jamais d'elle-même.
    private var pastilleMonSpot: some View {
        Button { basculerFeuilleSpot() } label: {
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(Police.taille(18))
                    .foregroundStyle(Palette.marine)
                    .accessibilityHidden(true)
                // « Mon spot · La Marne · 94 » : la pastille dit que c'est le spot, pas la position de l'iPhone.
                Text(apercu.map { "Mon spot · \($0.lieu)" } ?? (modele.spotAffiche == nil ? "Choisir mon spot" : "Mon spot"))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if !sessionEnCours {
                    Image(systemName: feuilleSpotOuverte ? "chevron.down" : "chevron.up")
                        .font(Police.taille(14, .bold))
                        .foregroundStyle(Palette.encreDouce)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: Gabarit.zoneTactile)
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(sessionEnCours)
        .accessibilityHint(feuilleSpotOuverte ? "Ranger Mon spot" : "Ouvrir Mon spot")
    }

    /// Une pastille discrète quand iOS ne donne qu'une position approximative : elle propose la précision exacte.
    private var boutonPrecision: some View {
        Button(action: preciserLaPosition) {
            Label("Position approximative", systemImage: "location.viewfinder")
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .padding(.horizontal, Espace.l)
                .frame(minHeight: Gabarit.zoneTactile)
                .background(Palette.surface, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Active la position précise pour recentrer la carte au bon endroit")
    }

    /// Marine quand un filtre d'espèce est actif (le bouton le dit, sans bandeau en plus), encre sinon.
    private var couleurDuFiltre: Color {
        modele.filtre == nil ? Palette.encre : Palette.marine
    }

    // MARK: Boutons du bas (au-dessus de la mention légale et de la feuille)

    private var bas: some View {
        VStack(spacing: 8) {
            if bulleSpot {
                bulleDuSpot
            }
            if modele.modeChoixDuSpot {
                bulleChoixDuSpot
            }
            bandeauSession
            HStack(alignment: .bottom, spacing: 12) {
                Spacer(minLength: 0)
                ColonneBoutonsCarte(
                    positionAutorisee: position.estAutorisee,
                    teinteFiltre: couleurDuFiltre,
                    nomFiltre: modele.filtre?.nom,
                    effacerFiltre: { modele.choisirFiltre(nil) },
                    meteo: ouvrirMeteo,
                    autourDeMoi: autourDeMoi,
                    filtre: { modele.afficherFiltre = true },
                    reglages: ouvrirProfil,
                    reperes: { calqueReperes.toggle() },
                    reperesAllumes: calqueReperes)
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: Mon spot

    /// Ouvre ou range « Mon spot » ; ouvrir range la fiche d'un coin (une seule feuille à la fois).
    private func basculerFeuilleSpot() {
        withAnimation(.snappy(duration: 0.3)) {
            if feuilleSpotOuverte {
                feuilleSpotOuverte = false
            } else {
                modele.selection = nil
                detentSpot = .moyen
                feuilleSpotOuverte = true
            }
        }
    }

    private func fermerFeuilleSpot() {
        feuilleSpotOuverte = false
    }

    private var feuilleMonSpot: some View {
        MonSpotView(
            detent: detentSpot,
            apercu: apercu,
            niveau: modele.niveauDuSpot,
            distance: distanceAuSpot,
            spotEauChoisi: modele.spotEauChoisi,
            sansSpot: modele.spotAffiche == nil,
            meteo: meteoDuSpot,
            pechable: { modele.pechable($0) },
            peutChangerDeSpot: modele.peutChangerDeSpot,
            modeChoixDuSpot: modele.modeChoixDuSpot,
            commencer: commencerDepuisMonSpot,
            coinCalme: coinCalmeDuSpot,
            reglesDuSpot: { reglesDuSpotOuvertes = true },
            choisirUnAutreSpot: choisirUnAutreSpot,
            annulerChoix: { modele.modeChoixDuSpot = false },
            ouvrirPoissons: ouvrirPoissons,
            fermer: { withAnimation(.snappy(duration: 0.3)) { fermerFeuilleSpot() } },
            ouvrirReperes: { listeReperesOuverte = true })
    }

    // MARK: Repères privés (N6)

    /// « Nouveau repère » à l'endroit de l'appui long. Une fois posé, le calque s'allume pour que l'épingle se voie.
    private func feuilleNouveauRepere(_ point: PointReperes) -> some View {
        NouveauRepereView(position: point.position, surAjout: { (_: Repere) in calqueReperes = true })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }

    /// La fiche d'un repère touché : « Y aller » suit la règle de N6 (`AllerAuRepere`), sans « Toujours utiliser ».
    private func feuilleRepere(_ repere: Repere) -> some View {
        FicheRepereView(repere: repere)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
    }

    private var feuilleListeReperes: some View {
        ListeReperesView()
            .presentationDetents([.large])
    }

    /// « Règles ici » depuis un repère : les feuilles des repères se ferment d'abord (une feuille ne peut pas en ouvrir une autre
    /// par-dessus), puis les règles du lieu s'ouvrent. La coordonnée ne sert qu'à lire les règles sur l'iPhone.
    private func demanderReglesIci(_ c: Coordonnee) {
        repereOuvert = nil
        listeReperesOuverte = false
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            reglesRepere = PointReperes(position: c)
        }
    }

    private func feuilleReglesIci(_ point: PointReperes) -> some View {
        let geo = modele.services.geo
        let spot = Spot(centre: point.position, rayonM: 1000, departement: geo.departement(de: point.position))
        return ReglesDuSpotView(services: modele.services, spot: spot, lieu: geo.lieuFlou(point.position),
                                fermer: { reglesRepere = nil })
    }

    /// La météo du moment du spot : l'emplacement de L12 (rangée « maintenant »), vide tant que A ne l'a pas branché.
    private var meteoDuSpot: AnyView {
        guard let spot = modele.spotAffiche else { return AnyView(EmptyView()) }
        return emplacementMaintenant(spot.centre)
    }

    private var commencerDepuisMonSpot: (() -> Void)? {
        if sessionEnCours { return nil }
        guard modele.spotAffiche != nil else { return nil }
        return {
            guard let spot = modele.spotAffiche else { return }
            commencer(spot)
        }
    }

    /// « Choisir un autre spot » : la feuille se range pour laisser voir la carte, la consigne flotte, le prochain toucher sur l'eau pose le cercle.
    private func choisirUnAutreSpot() {
        guard modele.peutChangerDeSpot else { return }
        modele.modeChoixDuSpot = true
        withAnimation(.snappy(duration: 0.3)) { fermerFeuilleSpot() }
    }

    @ViewBuilder
    private var feuilleReglesDuSpot: some View {
        if let spot = modele.spotAffiche {
            ReglesDuSpotView(services: modele.services, spot: spot, lieu: apercu?.lieu ?? "Mon spot",
                             fermer: { reglesDuSpotOuvertes = false })
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

    /// Ouvre tous les poissons du spot, sur le poisson touché s'il y en a un.
    private func ouvrirPoissons(_ espece: Espece?) {
        especeOuverte = espece
        poissonsOuverts = true
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
