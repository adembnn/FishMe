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
    @State private var afficherOuChercher = false
    /// Faux : on arrive sur « Ton spot » (maquette P06 C). Vrai : la carte, ouverte d'un toucher sur le bouton carte.
    @State private var afficherCarte = false
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
         demandeChoixDeZone: Bool = false) {
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
        .task(id: modele.spotAffiche) {
            apercu = nil
            guard let spot = modele.spotAffiche else { return }
            apercu = await calculerApercuSpot(services: modele.services, spot: spot, date: Date())
        }
        .task {
            for await connecte in fluxReseauCarte() { reseauDisponible = connecte }
        }
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
        ForEach(modele.elements) { (element: ElementCarte) in
            annotation(element)
        }
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
            onCommencerSession(spot)
        }
    }

    private func feuilleFiche(_ selection: CoinSelectionne) -> some View {
        FicheCoinView(services: modele.services, selection: selection, pechables: modele.pechables,
                      emplacementMaintenant: emplacementMaintenant, emplacementConseil: emplacementConseil,
                      onCommencerSession: commencerDepuisLaFiche)
            .presentationDragIndicator(.visible)
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
                        if let spot = modele.spotAffiche { onCommencerSession(spot) }
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
                ImageEspeceCarte(nom: modele.pechable(ligne.espece)?.image)
                    .frame(width: 72, height: 34)
                    .accessibilityLabel(modele.pechable(ligne.espece)?.nom ?? ligne.espece.id)
            }
            if apercu.reste > 0 {
                Text("+ \(apercu.reste)")
                    .font(Police.taille(15))
                    .foregroundStyle(Palette.encreDouce)
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
            if let p = position.position { modele.appliquer(position: p, refusee: false) }
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

    // MARK: Bandeaux du haut

    private var haut: some View {
        VStack(spacing: 8) {
            enTeteCarte
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                boutonsSecondaires
            }
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

    /// En haut de la carte : retour à « Ton spot », le lieu, le filtre par espèce (maquette P06 A).
    private var enTeteCarte: some View {
        HStack(spacing: 8) {
            BoutonRond(role: .retour, rendu: .verre, action: retourAuSpot)
            HStack(spacing: 8) {
                Image(systemName: "mappin")
                    .font(Police.taille(18))
                    .foregroundStyle(Palette.marine)
                    .accessibilityHidden(true)
                Text(apercu?.lieu ?? "Carte")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Espace.l)
            .frame(height: Gabarit.zoneTactile)
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
            }
            BoutonVerreCarte(symbole: "line.3.horizontal.decrease", libelle: "Filtrer par espèce",
                             teinte: couleurDuFiltre) {
                modele.afficherFiltre = true
            }
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
            bandeauSession
            if !sessionEnCours {
                feuilleSpotCarte
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
                .accessibilityHidden(true)
            titreFeuilleCarte
            tuilesFeuilleCarte
                .padding(.top, 14)
                .padding(.bottom, 18)
            boutonCommencerCarte
            lienAutreSpotCarte
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
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
        return VStack(spacing: 6) {
            ImageEspeceCarte(nom: fiche?.image)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 7)
                .padding(.vertical, 6)
                .frame(height: 52)
                .background(Palette.tuile, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            marqueRareteCarte(niveau)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
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
    }

    private var boutonCommencerCarte: some View {
        Button {
            if let spot = modele.spotAffiche { onCommencerSession(spot) }
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

    /// Le bouton « me localiser » : rond de verre sous la pastille, flèche marine (maquette P06 A).
    @ViewBuilder
    private var boutonsSecondaires: some View {
        BoutonVerreCarte(symbole: "location.fill", libelle: "Autour de moi", teinte: Palette.marine, action: autourDeMoi)
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
