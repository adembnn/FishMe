import MapKit
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
        @Bindable var m = modele
        MapReader { proxy in
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
                .mapControls { MapCompass() }
                .onMapCameraChange(frequency: .continuous) { _ in
                    if !modele.enMouvement { modele.enMouvement = true }
                }
                .onMapCameraChange(frequency: .onEnd) { contexte in
                    let r = contexte.region
                    modele.chargerApresMouvement(ZoneCarte(
                        centre: Coordonnee(latitude: r.center.latitude, longitude: r.center.longitude),
                        spanLatitude: r.span.latitudeDelta, spanLongitude: r.span.longitudeDelta))
                }
                .onTapGesture { point in
                    guard modele.modeChoixDuSpot, let c = proxy.convert(point, from: .local) else { return }
                    if let spot = modele.poserSpot(en: Coordonnee(latitude: c.latitude, longitude: c.longitude)) {
                        onSpotChange(spot)
                    }
                }

                PoissonsNageurs(animees: modele.animees, proxy: proxy, enMouvement: modele.enMouvement, region: modele.regionVisible)
            }
        }
        .safeAreaInset(edge: .top, spacing: 8) { haut }
        .safeAreaInset(edge: .bottom, spacing: 8) { bas }
        .sheet(item: $m.selection) { selection in
            FicheCoinView(services: modele.services, selection: selection, pechables: modele.pechables,
                          emplacementMaintenant: emplacementMaintenant, emplacementConseil: emplacementConseil)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $m.afficherFiltre) {
            FiltreEspeceView(pechables: modele.pechables, procheDIci: modele.especesProchesDIci(),
                             filtreActuel: modele.filtre, choisir: { modele.choisirFiltre($0) })
                .presentationDetents([.large])
        }
        .sheet(isPresented: $afficherOuChercher) {
            if let ouChercher {
                ouChercher(modele.spotAffiche?.centre ?? modele.regionVisible.centre)
                    .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $m.afficherChoixDeZone) {
            ChoixDeZoneView { modele.choisirZone($0) }
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
            // La position se demande tout de suite : elle n'attend ni les espèces ni le cache.
            position.demanderAuPremierEcran()
            reagirAuStatut()
            await modele.demarrer()
        }
        .onChange(of: spotFixe) { _, nouveau in modele.spotFixe = nouveau }
        .onChange(of: sessionsTerminees) { _, nouveau in modele.sessionsTerminees = nouveau }
        .onChange(of: position.position) { _, nouvelle in
            if let nouvelle { modele.appliquer(position: nouvelle, refusee: false) }
        }
        .onChange(of: position.statut) { _, _ in reagirAuStatut() }
        .onChange(of: modele.afficherChoixDeZone || modele.afficherRedemande) { _, ouvert in surChoixDeZone(ouvert) }
        // Le spot proposé (zone choisie ou position) est connu de la racine : tunnel, conseils et conditions s'en servent.
        .onChange(of: modele.spotLocal) { _, nouveau in if let nouveau { onSpotChange(nouveau) } }
    }

    // MARK: Départ

    /// Position refusée : une seule redemande, puis le choix à la main. Rien ne bloque.
    private func reagirAuStatut() {
        guard position.estRefusee else { return }
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

    // MARK: Boutons du bas (au-dessus de la barre d'onglets)

    private var bas: some View {
        VStack(spacing: 10) {
            bandeauSession
            HStack(spacing: 10) { boutonsSecondaires }
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

        Button { modele.afficherFiltre = true } label: {
            Text("Choisir un autre spot")
                .font(Police.corps)
                .foregroundStyle(Palette.encre)
                .padding(.horizontal, Espace.m)
                .frame(minHeight: Gabarit.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

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

#if DEBUG
#Preview {
    VueCarte(services: .faux())
}
#endif
