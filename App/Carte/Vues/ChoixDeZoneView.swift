import MapKit
import SwiftUI
import Core

/// Position refusée : le pêcheur choisit son département ou sa commune sur la carte, sans GPS.
/// Un toucher sur la carte pose la zone ; une recherche par nom de commune ou de département la trouve (MKLocalSearch).
struct ChoixDeZoneView: View {
    let choisir: (Coordonnee) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var camera: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5), span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13)))
    @State private var terme = ""
    @State private var posee: CLLocationCoordinate2D?
    @State private var resultatsVides = false
    /// Les communes trouvées par la recherche (trois au plus) : nom et centre. Jamais de GPS.
    @State private var trouvees: [ZoneTrouvee] = []
    @State private var choisieId: String?

    struct ZoneTrouvee: Identifiable, Equatable {
        let id: String
        let nom: String
        let latitude: Double
        let longitude: Double
        var coordonnee: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
    }

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $camera) {
                    if let posee {
                        // Cercle de zone : la même forme que le spot, en marine.
                        MapCircle(center: posee, radius: 1000)
                            .foregroundStyle(Palette.marine.opacity(0.15))
                            .stroke(Palette.marine, lineWidth: 2)
                    }
                }
                .onTapGesture { point in
                    if let c = proxy.convert(point, from: .local) {
                        posee = c
                        choisieId = nil
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { feuille }
            .navigationTitle("Où pêches-tu ?")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $terme, prompt: "Commune ou département")
            .onSubmit(of: .search) { Task { await chercher() } }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Plus tard") { dismiss() }
                }
            }
        }
    }

    /// La feuille du bas, façon Plans : « Ta zone », les communes trouvées, un seul bouton « Valider ».
    private var feuille: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Ta zone")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            if trouvees.isEmpty {
                Text(resultatsVides ? "Aucune commune trouvée. Touche la carte à la place."
                                    : "Touche la carte sur ton département ou ta commune.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(spacing: 0) {
                    ForEach(trouvees) { zone in
                        Button {
                            posee = zone.coordonnee
                            choisieId = zone.id
                            camera = .region(MKCoordinateRegion(center: zone.coordonnee,
                                                                span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)))
                        } label: {
                            HStack {
                                Text(zone.nom)
                                    .font(Police.corps)
                                    .foregroundStyle(Palette.encre)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: Espace.s)
                                if choisieId == zone.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Palette.marine)
                                        .accessibilityHidden(true)
                                }
                            }
                            .frame(minHeight: Gabarit.zoneTactile)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(choisieId == zone.id ? .isSelected : [])
                        if zone.id != trouvees.last?.id { Divider().overlay(Palette.filet) }
                    }
                }
            }
            Button("Valider") {
                if let posee { choisir(Coordonnee(latitude: posee.latitude, longitude: posee.longitude)) }
            }
            .buttonStyle(.principal)
            .disabled(posee == nil)
            .opacity(posee == nil ? 0.5 : 1)
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .padding(.horizontal, Espace.s)
        .padding(.bottom, Espace.s)
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
                return ZoneTrouvee(id: "\(i)-\(nom)", nom: nom, latitude: c.latitude, longitude: c.longitude)
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
