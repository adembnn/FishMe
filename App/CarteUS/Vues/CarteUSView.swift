import MapKit
import SwiftUI
import Core

/// La carte quand la région est les États-Unis (décision 7 du 7 nov.) : le même fond de carte que la France, les plans d'eau et
/// les accès publics listés par les agences d'État, la fiche d'un lieu avec sa source et le lien de l'agence, "Y aller".
/// Une zone sans données chargées le dit honnêtement, avec le lien de l'agence de l'État.
///
/// Performance : au plus 196 éléments dessinés (regroupés au-delà de 200 lieux visibles) ; la lecture et le tri des fichiers se font
/// hors du thread principal (voir ModeleCarteUS).
struct CarteUSView: View {
    let position: GestionPosition
    let pastilleProfil: AnyView
    let bandeauHaut: AnyView
    let ouvrirMeteo: () -> Void
    let ouvrirProfil: () -> Void
    /// Point d'insertion du bloc de règles US12 : reçoit le code USPS de l'État du lieu et rend la vue du bloc.
    let blocReglesUS: (String) -> AnyView

    @State private var modele: ModeleCarteUS
    @State private var camera: MapCameraPosition
    @State private var zoneVisible: ZoneCarte?
    @State private var destination: DestinationItineraire?
    @State private var centreeSurLePecheur = false
    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    private var t: TraducteurCarteUS { TraducteurCarteUS(locale: regionCourante?.locale ?? Locale(identifier: "en_US")) }

    init(position: GestionPosition,
         source: any SourceCarteUS = SourceCarteUSParDefaut.creer(),
         pastilleProfil: AnyView = AnyView(EmptyView()),
         bandeauHaut: AnyView = AnyView(EmptyView()),
         ouvrirMeteo: @escaping () -> Void = {},
         ouvrirProfil: @escaping () -> Void = {},
         blocReglesUS: @escaping (String) -> AnyView = { _ in AnyView(EmptyView()) }) {
        self.position = position
        self.pastilleProfil = pastilleProfil
        self.bandeauHaut = bandeauHaut
        self.ouvrirMeteo = ouvrirMeteo
        self.ouvrirProfil = ouvrirProfil
        self.blocReglesUS = blocReglesUS
        _modele = State(initialValue: ModeleCarteUS(source: source))
        _camera = State(initialValue: .region(Self.regionDepart(position.position)))
    }

    /// Autour du pêcheur s'il est aux États-Unis ; sinon les États-Unis entiers (région choisie à la main, ou position à l'étranger).
    static func regionDepart(_ p: Coordonnee?) -> MKCoordinateRegion {
        if let p, RegionCourante.region(pour: p) == .etatsUnis {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: p.latitude, longitude: p.longitude),
                                      span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3))
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35),
                                  span: MKCoordinateSpan(latitudeDelta: 28, longitudeDelta: 50))
    }

    var body: some View {
        carte
            .safeAreaInset(edge: .top, spacing: 8) { haut }
            .overlay(alignment: .bottom) { bas.padding(.bottom, 36) }
            .sheet(item: $modele.fiche) { (fiche: FicheUS) in feuilleFiche(fiche) }
            .task { await modele.chargerAgences() }
            .task { position.relire() }
            .onChange(of: position.position) { _, nouvelle in
                // La première position connue centre la carte sur le pêcheur, une seule fois : ensuite la carte lui appartient.
                guard let nouvelle, !centreeSurLePecheur, RegionCourante.region(pour: nouvelle) == .etatsUnis else { return }
                centreeSurLePecheur = true
                camera = .region(Self.regionDepart(nouvelle))
            }
    }

    // MARK: Carte

    private var carte: some View {
        Map(position: $camera) {
            UserAnnotation()
            ForEach(modele.resultat.elements) { (element: ElementCarteUS) in
                annotation(element)
            }
        }
        // Le même fond clair et sobre que la carte de France : routes et eau, ni commerces ni relief.
        .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
        .mapControls { MapCompass() }
        .onMapCameraChange(frequency: .onEnd) { (contexte: MapCameraUpdateContext) in
            let r = contexte.region
            let zone = ZoneCarte(centre: Coordonnee(latitude: r.center.latitude, longitude: r.center.longitude),
                                 spanLatitude: r.span.latitudeDelta, spanLongitude: r.span.longitudeDelta)
            zoneVisible = zone
            modele.zoneChangee(zone)
        }
    }

    @MapContentBuilder
    private func annotation(_ element: ElementCarteUS) -> some MapContent {
        let c = CLLocationCoordinate2D(latitude: element.coordonnee.latitude, longitude: element.coordonnee.longitude)
        switch element {
        case .point(let p):
            Annotation("", coordinate: c, anchor: .bottom) {
                pastille(symbole: p.type.symbole, teinte: Palette.marine, libelle: p.nom + ", " + t(p.type.libelle)) { modele.ouvrir(element) }
            }
        case .planEau(let e):
            Annotation("", coordinate: c, anchor: .bottom) {
                pastille(symbole: "drop.fill", teinte: Palette.marineFonce, libelle: e.nom + ", " + t("plan d'eau")) { modele.ouvrir(element) }
            }
        case .groupe(_, _, let nombre):
            Annotation("", coordinate: c, anchor: .center) {
                Button { zoomer(sur: element.coordonnee) } label: {
                    Text(String(nombre))
                        .font(Police.detail)
                        .foregroundStyle(Palette.surMarine)
                        .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                        .background(Palette.marine, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(nombre) + t(" lieux, touche pour zoomer"))
            }
        }
    }

    private func pastille(symbole: String, teinte: Color, libelle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbole)
                .font(Police.taille(15))
                .foregroundStyle(Palette.surMarine)
                .frame(width: 32, height: 32)
                .background(teinte, in: Circle())
                .overlay(Circle().strokeBorder(Palette.surface, lineWidth: 2))
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }

    private func zoomer(sur c: Coordonnee) {
        let span = max(0.02, (zoneVisible?.spanLatitude ?? 0.3) / 3)
        withAnimation(.easeInOut(duration: 0.4)) {
            camera = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude),
                                                span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)))
        }
    }

    // MARK: Haut et bas

    private var haut: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                pastilleProfil.frame(maxWidth: 170, alignment: .leading)
                Spacer(minLength: 0)
            }
            bandeauHaut
            messageDeCarte
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var messageDeCarte: some View {
        if let message = modele.message {
            BandeauSansDonneesUSView(message: message, etats: modele.etatsChoisissables) { code in modele.etatChoisi = code }
        } else if modele.resultat.tropLoin {
            petitMessage(t(TextesCarteUS.tropLoin))
        } else if modele.resultat.donneesChargees && modele.resultat.elements.isEmpty {
            petitMessage(t(TextesCarteUS.aucunLieu))
        }
    }

    private func petitMessage(_ texte: String) -> some View {
        Text(texte)
            .font(Police.detail)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(Palette.encre)
            .padding(.horizontal, Espace.m)
            .padding(.vertical, Espace.s)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    private var bas: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Spacer(minLength: 0)
            GlassEffectContainer(spacing: 4) {
                VStack(spacing: 4) {
                    BoutonLibelleCarte(symbole: "cloud.sun", libelle: t("Météo"), action: ouvrirMeteo)
                    BoutonLibelleCarte(symbole: "location.fill", libelle: t("Ma position"), teinte: Palette.marine, action: recentrer)
                    BoutonLibelleCarte(symbole: "gearshape", libelle: t("Réglages"), action: ouvrirProfil)
                }
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 8)
    }

    private func recentrer() {
        position.relire()
        if let p = position.position {
            withAnimation(.easeInOut(duration: 0.4)) { camera = .region(Self.regionDepart(p)) }
        }
    }

    // MARK: Fiche et "Y aller"

    private func feuilleFiche(_ fiche: FicheUS) -> some View {
        FicheUSView(fiche: fiche, yAller: yAller, blocRegles: blocReglesUS)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .sheet(item: $destination) { (cible: DestinationItineraire) in
                ChoixNavigationView(applications: LanceurItineraire.installees()) { application, toujours in
                    if toujours { PreferenceItineraire.ecrire(application) }
                    destination = nil
                    LanceurItineraire.ouvrir(application, vers: cible.coordonnee, nom: cible.nom)
                }
            }
    }

    /// Même règle que la carte de France : préférence mémorisée ou Plans seul, ouverture directe ; sinon la feuille de choix.
    /// La coordonnée envoyée est celle du lieu, jamais celle du pêcheur.
    private func yAller(_ c: Coordonnee, _ nom: String) {
        switch LanceurItineraire.decision() {
        case .ouvrir(let application):
            LanceurItineraire.ouvrir(application, vers: c, nom: nom)
        case .demander:
            destination = DestinationItineraire(coordonnee: c, nom: nom)
        }
    }
}

/// "Pas encore de données pour cet État" : le texte, le lien de l'agence et, si l'État n'est pas connu, le choix de l'État.
struct BandeauSansDonneesUSView: View {
    let message: MessageSansDonneesUS
    let etats: [InfoAgenceUS]
    let choisir: (String) -> Void

    @Environment(RegionCourante.self) private var regionCourante: RegionCourante?
    private var t: TraducteurCarteUS { TraducteurCarteUS(locale: regionCourante?.locale ?? Locale(identifier: "en_US")) }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(t.sansDonnees(message.texte))
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
            if let lien = message.lien {
                Link(destination: lien) {
                    Label(t.libelleLien(message.libelleLien), systemImage: "arrow.up.right.square")
                        .font(Police.detail)
                        .foregroundStyle(Palette.marine)
                        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                }
            }
            if message.proposerChoixEtat && !etats.isEmpty {
                Menu {
                    ForEach(etats) { (etat: InfoAgenceUS) in
                        Button(etat.nomEtat) { choisir(etat.code) }
                    }
                } label: {
                    Label(t(TextesCarteUS.choisirEtat), systemImage: "list.bullet")
                        .font(Police.detail)
                        .frame(minHeight: Gabarit.zoneTactile, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Espace.m)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}
