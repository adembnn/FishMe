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
         surChoixDeZone: @escaping (Bool) -> Void = { _ in }) {
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

    private var carteComplete: some View {
        @Bindable var m = modele
        return MapReader { proxy in
            ZStack {
                Map(position: $m.camera) {
                    UserAnnotation()
                    if let spot = modele.spotAffiche {
                        MapCircle(center: CLLocationCoordinate2D(latitude: spot.centre.latitude, longitude: spot.centre.longitude),
                                  radius: spot.rayonM)
                            .foregroundStyle(Palette.marine.opacity(0.15))
                            .stroke(Palette.marine, lineWidth: 2)
                    }
                    ForEach(modele.elements) { element in
                        Annotation("", coordinate: CLLocationCoordinate2D(latitude: element.coordonnee.latitude,
                                                                          longitude: element.coordonnee.longitude)) {
                            marque(element)
                        }
                        .annotationTitles(.hidden)
                    }
                }
                // Jamais la France entière : au plus quelques départements à l'écran, et seulement au-dessus de la France.
                .mapCameraBounds(MapCameraBounds(centerCoordinateBounds: Self.franceEtVoisins,
                                                 minimumDistance: 300, maximumDistance: Self.altitudeMaximale))
                .mapControls { MapCompass() }
                .onMapCameraChange(frequency: .onEnd) { contexte in
                    let r = contexte.region
                    modele.chargerApresMouvement(ZoneCarte(
                        centre: Coordonnee(latitude: r.center.latitude, longitude: r.center.longitude),
                        spanLatitude: r.span.latitudeDelta, spanLongitude: r.span.longitudeDelta))
                }
                // Le toucher qui pose le cercle n'existe qu'en mode « poser mon spot » : le reste du temps,
                // la carte garde tous ses gestes (pincer, double toucher, glisser) sans rien qui les retienne.
                .simultaneousGesture(SpatialTapGesture().onEnded { valeur in
                    guard let c = proxy.convert(valeur.location, from: .local) else { return }
                    if let spot = modele.poserSpot(en: Coordonnee(latitude: c.latitude, longitude: c.longitude)) {
                        onSpotChange(spot)
                    }
                }, including: modele.modeChoixDuSpot ? .all : .subviews)

                // Sonar pendant la première lecture des relevés OFB (carte encore vide), fondu de 0,3 s à l'arrivée.
                // Pas de sonar quand on déplace une carte déjà remplie : les stations restent, les nouvelles s'ajoutent.
                Group {
                    if modele.chargementEnCours && modele.stations.isEmpty {
                        ChargementSonar().transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.3), value: modele.chargementEnCours && modele.stations.isEmpty)
            }
        }
        .safeAreaInset(edge: .top, spacing: 8) { haut }
        .safeAreaInset(edge: .bottom, spacing: 8) { bas }
        .sheet(item: $m.selection) { selection in
            FicheCoinView(services: modele.services, selection: selection, pechables: modele.pechables,
                          emplacementMaintenant: emplacementMaintenant, emplacementConseil: emplacementConseil,
                          onCommencerSession: (sessionEnCours || modele.spotAffiche == nil) ? nil : {
                              if let spot = modele.spotAffiche {
                                  modele.selection = nil
                                  onCommencerSession(spot)
                              }
                          })
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $m.afficherFiltre) {
            FiltreEspeceView(pechables: modele.pechables, procheDIci: modele.especesProchesDIci(),
                             filtreActuel: modele.filtre, choisir: { modele.choisirFiltre($0) },
                             raretes: raretesDuSecteur())
                .presentationDetents([.large])
        }
        .sheet(isPresented: $afficherOuChercher) {
            if let ouChercher {
                ouChercher(modele.spotAffiche?.centre ?? modele.regionVisible.centre)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $m.afficherChoixDeZone) {
            ChoixDeZoneView(choisir: { modele.choisirZone($0) },
                            codeDepartement: { c in
                                let d = modele.services.geo.departement(de: c)
                                return d.estInconnu ? nil : d.code
                            })
        }
        .alert("Ta position aide à centrer la carte", isPresented: $m.afficherRedemande) {
            Button("Ouvrir les réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                modele.appliquer(position: nil, refusee: true)
            }
            Button("Choisir à la main", role: .cancel) { modele.appliquer(position: nil, refusee: true) }
        } message: {
            Text("Sans elle, tu choisis ton département ou ta commune sur la carte. Rien ne bloque.")
        }
        .task {
            modele.spotFixe = spotFixe
            modele.sessionsTerminees = sessionsTerminees
            // Avant toute question de position : le spot fixé ou la dernière zone choisie posent la carte tout de suite.
            modele.placerALOuverture()
            // La position se demande tout de suite : elle n'attend ni les espèces ni le cache.
            position.demanderAuPremierEcran()
            reagirAuStatut()
            await modele.demarrer()
        }
        .onChange(of: spotFixe) { _, nouveau in modele.recevoir(spotFixe: nouveau) }
        .onChange(of: sessionsTerminees) { _, nouveau in modele.sessionsTerminees = nouveau }
        .onChange(of: position.position) { _, nouvelle in
            if let nouvelle { modele.appliquer(position: nouvelle, refusee: false) }
        }
        .onChange(of: position.statut) { _, _ in reagirAuStatut() }
        .onChange(of: position.echec) { _, echec in if echec { modele.positionIndisponible() } }
        .onChange(of: modele.afficherChoixDeZone || modele.afficherRedemande) { _, ouvert in surChoixDeZone(ouvert) }
        // Le spot proposé (zone choisie ou position) est connu de la racine : tunnel, conseils et conditions s'en servent.
        .onChange(of: modele.spotLocal) { _, nouveau in if let nouveau { onSpotChange(nouveau) } }
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
            VStack(alignment: .leading, spacing: Espace.l) {
                Text("Carte")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                if !reseauDisponible { BandeauPasDeReseauView() }
                Text("Ton spot")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .textCase(.uppercase)
                    .padding(.horizontal, Espace.s)
                    .accessibilityAddTraits(.isHeader)
                PasDeSpotView(choisirUnSpot: { ouvrirLaCarte(poserLeSpot: true) })
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
    }

    /// P06 C : le lieu, le poisson le plus rare en grand, trois autres, « Commencer une session », « Choisir un autre spot ».
    private var ecranAvecSpot: some View {
        VStack(spacing: Espace.l) {
            HStack {
                HStack(spacing: Espace.s) {
                    Image(systemName: "mappin")
                        .foregroundStyle(Palette.marine)
                        .accessibilityHidden(true)
                    Text(apercu?.lieu ?? " ")
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                        .lineLimit(1)
                }
                Spacer(minLength: Espace.s)
                Button { ouvrirLaCarte() } label: {
                    Image(systemName: "map")
                        .font(Police.taille(18))
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
                VStack(spacing: Espace.xs) {
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
                            .font(Police.corps)
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
            VStack(spacing: Espace.m) {
                Text(apercu.vedetteEstRare ? "Le plus rare de ton spot" : "Le plus pêché de ton spot")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                ImageEspeceCarte(nom: fiche?.image)
                    .frame(maxWidth: .infinity)
                    .frame(height: 170)
                    .padding(.horizontal, Espace.xs)
                VStack(spacing: Espace.s) {
                    Text(fiche?.nom ?? ligne.espece.id)
                        .font(Police.grandTitre)
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    if apercu.vedetteEstRare, niveau != .nonMesuree {
                        Label(niveau.libelle, systemImage: niveau.symboleSF)
                            .font(Police.detail)
                            .foregroundStyle(CouleursCarte.rarete(niveau))
                    }
                    if apercu.vedetteEstRare, let rarete = ligne.rarete {
                        Text(texteVedette(rarete, annee: ligne.annee))
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .multilineTextAlignment(.center)
                    } else if !apercu.vedetteEstRare {
                        let mot = ligne.nPeches > 1 ? "pêches" : "pêche"
                        Text("\(ligne.nPeches) \(mot) OFB · \(String(ligne.annee))")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                            .multilineTextAlignment(.center)
                    }
                }
                autresPoissons(apercu)
                    .padding(.top, Espace.xl)
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
    private func texteVedette(_ rarete: ResultatRarete, annee: Int) -> String {
        let mot = rarete.nPeches > 1 ? "pêches" : "pêche"
        let an = rarete.anneeDernierReleve ?? annee
        let base = "\(rarete.nPeches) \(mot) sur \(rarete.nTotal) · OFB \(an)"
        return rarete.echelle == .region ? base + " · région" : base
    }

    private func autresPoissons(_ apercu: ApercuSpot) -> some View {
        HStack(spacing: Espace.l) {
            ForEach(apercu.autres) { ligne in
                ImageEspeceCarte(nom: modele.pechable(ligne.espece)?.image)
                    .frame(width: 72, height: 34)
                    .accessibilityLabel(modele.pechable(ligne.espece)?.nom ?? ligne.espece.id)
            }
            if apercu.reste > 0 {
                Text("+ \(apercu.reste)")
                    .font(Police.detail)
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
            bandeauHaut
            if let message = modele.message {
                Text(message)
                    .font(PolicesCarte.detail())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.s)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
            if modele.modeChoixDuSpot {
                Text("Touche la rivière pour poser ton cercle de 1 km.")
                    .font(PolicesCarte.detail())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.s)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
            if let filtre = modele.filtre {
                Button { modele.choisirFiltre(nil) } label: {
                    HStack(spacing: 8) {
                        ImageEspeceCarte(nom: filtre.image).frame(width: 34, height: 20)
                        Text(filtre.nom).font(PolicesCarte.detail())
                        Image(systemName: "xmark.circle.fill").accessibilityHidden(true)
                    }
                    .foregroundStyle(Palette.encre)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.s)
                    .background(Palette.surface, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Filtre : \(filtre.nom)")
                .accessibilityHint("Retire le filtre")
            }
        }
        .padding(.horizontal, 16)
    }

    /// En haut de la carte : retour à « Ton spot », le lieu, le filtre par espèce (maquette P06 A).
    private var enTeteCarte: some View {
        HStack(spacing: 8) {
            BoutonRond(role: .retour, rendu: .verre, action: retourAuSpot)
            HStack(spacing: 8) {
                Image(systemName: "mappin")
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
            BoutonVerreCarte(symbole: "line.3.horizontal.decrease", libelle: "Filtrer par espèce") {
                modele.afficherFiltre = true
            }
        }
    }

    private func retourAuSpot() {
        modele.modeChoixDuSpot = false
        afficherCarte = false
    }

    // MARK: Boutons du bas (au-dessus de la barre d'onglets)

    private var bas: some View {
        VStack(spacing: 10) {
            bandeauSession
            HStack(spacing: 10) { Spacer(minLength: 0); boutonsSecondaires }
            if !sessionEnCours {
                Button {
                    if let spot = modele.spotAffiche { onCommencerSession(spot) }
                } label: {
                    Label("Commencer une session", systemImage: "play.fill")
                }
                .buttonStyle(.principal)
                .disabled(modele.spotAffiche == nil)
                .opacity(modele.spotAffiche == nil ? 0.5 : 1)
                if modele.spotAffiche == nil {
                    Text(modele.modeChoixDuSpot ? "Touche la rivière pour poser ton spot"
                                                : "Pose ton spot pour commencer")
                        .font(PolicesCarte.legende())
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var boutonsSecondaires: some View {
        Button(action: autourDeMoi) {
            Image(systemName: "location.fill")
                .font(Police.taille(17))
                .foregroundStyle(Palette.marine)
                .frame(width: 44, height: 44)
                .background(Palette.marineDoux, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Autour de moi")

        if ouChercher != nil || modele.peutChangerDeSpot {
            Menu {
                if ouChercher != nil {
                    Button { afficherOuChercher = true } label: {
                        Label("Où chercher près d'ici", systemImage: "mappin.and.ellipse")
                    }
                }
                if modele.peutChangerDeSpot {
                    Button { modele.modeChoixDuSpot.toggle() } label: {
                        Label(modele.modeChoixDuSpot ? "Annuler" : (modele.spotAffiche == nil ? "Poser mon spot" : "Changer de spot"),
                              systemImage: "scope")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(Police.taille(17))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 44, height: 44)
                    .background(Palette.marineDoux, in: Circle())
                    .contentShape(Circle())
            }
            .accessibilityLabel("Plus")
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
