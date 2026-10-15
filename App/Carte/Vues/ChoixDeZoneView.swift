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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MapReader { proxy in
                    Map(position: $camera) {
                        if let posee {
                            Marker("Ma zone", coordinate: posee).tint(CouleursCarte.accent)
                        }
                    }
                    .onTapGesture { point in
                        if let c = proxy.convert(point, from: .local) { posee = c }
                    }
                }
                VStack(spacing: 10) {
                    Text("Touche la carte sur ton département ou ta commune.")
                        .font(PolicesCarte.detail())
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if resultatsVides {
                        Text("Aucune commune trouvée. Touche la carte à la place.")
                            .font(PolicesCarte.legende())
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        if let posee { choisir(Coordonnee(latitude: posee.latitude, longitude: posee.longitude)) }
                    } label: {
                        Text("C'est ici")
                            .font(PolicesCarte.corps())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CouleursCarte.accent)
                    .disabled(posee == nil)
                }
                .padding(16)
                .background(.bar)
            }
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

    /// Recherche d'une commune, limitée à la France.
    private func chercher() async {
        let requete = MKLocalSearch.Request()
        requete.naturalLanguageQuery = terme
        requete.resultTypes = .address
        requete.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
                                            span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13))
        do {
            let reponse = try await MKLocalSearch(request: requete).start()
            guard let premier = reponse.mapItems.first else { resultatsVides = true; return }
            resultatsVides = false
            let c = premier.location.coordinate
            posee = c
            camera = .region(MKCoordinateRegion(center: c, span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)))
        } catch {
            resultatsVides = true
        }
    }
}
