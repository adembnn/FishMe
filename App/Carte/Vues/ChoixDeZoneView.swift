import MapKit
import SwiftUI
import Core

/// Position refusée : le pêcheur choisit son département ou sa commune sur la carte, sans GPS.
/// Un toucher sur la carte pose la zone ; une recherche par nom de commune ou de département la trouve (MKLocalSearch).
struct ChoixDeZoneView: View {
    let choisir: (Coordonnee) -> Void
    /// Le code du département d'un point (« 94 ») ; `nil` si inconnu. Vide par défaut : la rangée n'affiche alors aucun code.
    var codeDepartement: (Coordonnee) -> String? = { _ in nil }
    @Environment(\.dismiss) private var dismiss

    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5), span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13)))
    @State private var terme = ""
    @State private var posee: CLLocationCoordinate2D?
    @State private var resultatsVides = false
    /// Les communes trouvées par la recherche (trois au plus) : nom, centre et code. Jamais de GPS.
    @State private var trouvees: [ZoneTrouvee] = []
    @State private var choisieId: String?
    @FocusState private var rechercheActive: Bool

    struct ZoneTrouvee: Identifiable, Equatable {
        let id: String
        let nom: String
        let latitude: Double
        let longitude: Double
        var code: String? = nil
        var coordonnee: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    }

    /// P04 A : la carte en plein écran, le retour et la recherche en verre en haut, la feuille « Ta zone » en bas.
    var body: some View {
        ZStack(alignment: .top) {
            MapReader { proxy in
                Map(position: $camera) {
                    if let posee {
                        // Cercle de zone : la même forme que le spot, en marine.
                        MapCircle(center: posee, radius: 1000)
                            .foregroundStyle(Palette.marine.opacity(0.12))
                            .stroke(Palette.marine, lineWidth: 2.5)
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
                .onTapGesture { point in
                    if let c = proxy.convert(point, from: .local) {
                        posee = c
                        choisieId = nil
                        rechercheActive = false
                    }
                }
            }
            .ignoresSafeArea()

            enTete
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { feuille }
        // La feuille du bas fait partie de l'écran : un glissement ne doit pas la fermer par mégarde.
        .interactiveDismissDisabled()
        // Recherche au fil de la frappe : 300 ms après le dernier caractère, dès 3 caractères.
        .task(id: terme) {
            let propre = terme.trimmingCharacters(in: .whitespaces)
            guard propre.count >= 3 else { return }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await chercher()
        }
    }

    private var enTete: some View {
        HStack(spacing: Espace.s) {
            BoutonRond(role: .fermer, rendu: .verre) { dismiss() }
            HStack(spacing: Espace.s) {
                Image(systemName: "magnifyingglass")
                    .font(Police.taille(18, .heavy))
                    .foregroundStyle(Palette.marine)
                    .accessibilityHidden(true)
                TextField("Commune ou département", text: $terme)
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .submitLabel(.search)
                    .focused($rechercheActive)
                    .onSubmit { Task { await chercher() } }
            }
            .padding(.horizontal, Espace.l)
            .frame(height: Gabarit.zoneTactile)
            .background {
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                    .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.top, Espace.s)
    }

    /// La feuille du bas, façon Plans : « Ta zone », les communes trouvées avec leur code, un seul bouton « Valider ».
    private var feuille: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Palette.filet)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 7)
                .padding(.bottom, 12)
                .accessibilityHidden(true)
            Text("Ta zone")
                .font(Police.taille(22, .heavy))
                .foregroundStyle(Palette.encre)
                .padding(.leading, Espace.xs)
                .padding(.bottom, 6)
                .accessibilityAddTraits(.isHeader)
            if trouvees.isEmpty {
                if let posee {
                    let code = codeDepartement(Coordonnee(latitude: posee.latitude, longitude: posee.longitude))
                    rangee(nom: code.map { "Département \($0)" } ?? "Ma zone", code: code, choisie: true, action: {})
                } else {
                    Text(resultatsVides ? "Aucune commune trouvée. Touche la carte à la place."
                                        : "Touche la carte sur ton département ou ta commune.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, Espace.xs)
                        .padding(.vertical, Espace.s)
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(trouvees) { zone in
                        rangee(nom: zone.nom, code: zone.code, choisie: choisieId == zone.id) {
                            posee = zone.coordonnee
                            choisieId = zone.id
                            camera = .region(MKCoordinateRegion(center: zone.coordonnee,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)))
                        }
                        if zone.id != trouvees.last?.id {
                            Divider().overlay(Palette.filet).padding(.leading, 16)
                        }
                    }
                }
            }
            Button("Valider") {
                if let posee { choisir(Coordonnee(latitude: posee.latitude, longitude: posee.longitude)) }
            }
            .buttonStyle(.principal)
            .disabled(posee == nil)
            .opacity(posee == nil ? 0.5 : 1)
            .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 38, style: .continuous))
        .shadow(color: Palette.encre.opacity(0.16), radius: 15, y: -2)
        .padding(.horizontal, Espace.s)
        .padding(.bottom, Espace.s)
    }

    private func rangee(nom: String, code: String?, choisie: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Espace.m) {
                Text(nom)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Espace.s)
                if let code {
                    Text(code)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encreDouce)
                }
                if choisie {
                    Image(systemName: "checkmark")
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.marine)
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Espace.xs)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(choisie ? .isSelected : [])
    }

    /// Recherche d'une commune, limitée à la France.
    private func chercher() async {
        let requete = MKLocalSearch.Request()
        requete.naturalLanguageQuery = terme
        requete.resultTypes = .address
        requete.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
                                            span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13))
        do {
            let reponse = try await MKLocalSearch(request: requete).start()
            let zones = reponse.mapItems.prefix(3).enumerated().compactMap { (i, item) -> ZoneTrouvee? in
                guard let nom = item.name else { return nil }
                let c = item.location.coordinate
                let code = codeDepartement(Coordonnee(latitude: c.latitude, longitude: c.longitude))
                return ZoneTrouvee(id: "\(i)-\(nom)", nom: nom, latitude: c.latitude, longitude: c.longitude, code: code)
            }
            trouvees = zones
            guard let premiere = zones.first else { resultatsVides = true; return }
            resultatsVides = false
            choisieId = premiere.id
            posee = premiere.coordonnee
            camera = .region(MKCoordinateRegion(center: premiere.coordonnee,
                                                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)))
        } catch {
            trouvees = []
            resultatsVides = true
        }
    }
}
