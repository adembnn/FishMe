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
    let emplacementMaintenant: (Coordonnee) -> AnyView
    let emplacementConseil: (Espece) -> AnyView
    let onCommencerSession: (Spot) -> Void
    let onSpotChange: (Spot) -> Void

    init(services: ServicesCarte,
         spotFixe: Spot? = nil,
         sessionsTerminees: Int = 0,
         bandeauHaut: AnyView = AnyView(EmptyView()),
         bandeauSession: AnyView = AnyView(EmptyView()),
         emplacementMaintenant: @escaping (Coordonnee) -> AnyView = { _ in AnyView(EmptyView()) },
         emplacementConseil: @escaping (Espece) -> AnyView = { _ in AnyView(EmptyView()) },
         onCommencerSession: @escaping (Spot) -> Void = { _ in },
         onSpotChange: @escaping (Spot) -> Void = { _ in }) {
        _modele = State(initialValue: ModeleCarte(services: services))
        self.spotFixe = spotFixe
        self.sessionsTerminees = sessionsTerminees
        self.bandeauHaut = bandeauHaut
        self.bandeauSession = bandeauSession
        self.emplacementMaintenant = emplacementMaintenant
        self.emplacementConseil = emplacementConseil
        self.onCommencerSession = onCommencerSession
        self.onSpotChange = onSpotChange
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
                            .foregroundStyle(CouleursCarte.accent.opacity(0.18))
                            .stroke(CouleursCarte.accent, lineWidth: 2)
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
                    modele.chargerApresMouvement(RegionCarte(
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
            await modele.demarrer()
            position.demanderAuPremierEcran()
            reagirAuStatut()
        }
        .onChange(of: spotFixe) { _, nouveau in modele.spotFixe = nouveau }
        .onChange(of: sessionsTerminees) { _, nouveau in modele.sessionsTerminees = nouveau }
        .onChange(of: position.position) { _, nouvelle in
            if let nouvelle { modele.appliquer(position: nouvelle, refusee: false) }
        }
        .onChange(of: position.statut) { _, _ in reagirAuStatut() }
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
                    .foregroundStyle(.white)
                    .frame(minWidth: 36, minHeight: 36)
                    .background(CouleursCarte.accent, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
            }
            .accessibilityLabel("\(nombre) stations OFB")
            .accessibilityHint("Zoomer pour les voir")
        case .point:
            Button { modele.toucher(element) } label: {
                Image(systemName: "fish.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(CouleursCarte.accent, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 2))
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
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            if modele.modeChoixDuSpot {
                Text("Touche la rivière pour poser ton cercle de 1 km.")
                    .font(PolicesCarte.detail())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
            if let filtre = modele.filtre {
                Button { modele.choisirFiltre(nil) } label: {
                    HStack(spacing: 8) {
                        ImageEspece(nom: filtre.image).frame(width: 34, height: 20)
                        Text(filtre.nom).font(PolicesCarte.detail())
                        Image(systemName: "xmark.circle.fill").accessibilityHidden(true)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
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
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { boutonsSecondaires }
                VStack(spacing: 10) { boutonsSecondaires }
            }
            Button {
                if let spot = modele.spotAffiche { onCommencerSession(spot) }
            } label: {
                Text("Commencer une session")
                    .font(PolicesCarte.corps())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(CouleursCarte.accent)
            .disabled(modele.spotAffiche == nil)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var boutonsSecondaires: some View {
        Button(action: autourDeMoi) {
            Label("Autour de moi", systemImage: "location.fill")
                .font(PolicesCarte.detail())
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)

        Button { modele.afficherFiltre = true } label: {
            Label("Choisir un autre spot", systemImage: "fish")
                .font(PolicesCarte.detail())
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
        }
        .buttonStyle(.plain)

        if modele.peutChangerDeSpot, modele.spotAffiche != nil {
            Button { modele.modeChoixDuSpot.toggle() } label: {
                Label(modele.modeChoixDuSpot ? "Annuler" : "changer de spot", systemImage: "scope")
                    .font(PolicesCarte.detail())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
#Preview {
    VueCarte(services: .faux())
}
#endif
