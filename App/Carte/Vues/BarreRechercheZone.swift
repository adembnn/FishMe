import MapKit
import SwiftUI
import Core

/// La recherche « Commune ou département » en haut de la carte : même recherche (MKLocalSearch, France) que le choix de zone.
/// Les communes trouvées s'affichent sous la barre ; en toucher une centre la carte sur elle. Jamais de GPS.
struct BarreRechercheZone: View {
    /// Une commune est choisie : la carte s'y centre.
    let choisir: (Coordonnee) -> Void
    /// Le code du département d'un point (« 94 ») ; `nil` si inconnu.
    var codeDepartement: (Coordonnee) -> String? = { _ in nil }

    @State private var terme = ""
    @State private var trouvees: [ZoneTrouvee] = []
    @State private var resultatsVides = false
    /// Vrai juste après le choix d'une commune : le changement de `terme` qui suit ne relance pas la recherche.
    @State private var choixFait = false
    @FocusState private var active: Bool

    struct ZoneTrouvee: Identifiable, Equatable {
        let id: String
        let nom: String
        let latitude: Double
        let longitude: Double
        var code: String? = nil
    }

    var body: some View {
        VStack(spacing: Espace.xs) {
            champ
            if active || !trouvees.isEmpty || resultatsVides {
                resultats
            }
        }
        // Recherche au fil de la frappe : 300 ms après le dernier caractère, dès 3 caractères.
        .task(id: terme) {
            if choixFait { choixFait = false; return }
            let propre = terme.trimmingCharacters(in: .whitespaces)
            guard propre.count >= 3 else {
                trouvees = []
                resultatsVides = false
                return
            }
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await chercher()
        }
    }

    private var champ: some View {
        HStack(spacing: Espace.s) {
            Image(systemName: "magnifyingglass")
                .font(Police.taille(18, .heavy))
                .foregroundStyle(Palette.marine)
                .accessibilityHidden(true)
            TextField("Commune ou département", text: $terme)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .submitLabel(.search)
                .focused($active)
                .onSubmit { Task { await chercher() } }
            if !terme.isEmpty {
                Button {
                    terme = ""
                    trouvees = []
                    resultatsVides = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.encreDouce)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Effacer la recherche")
            }
        }
        .padding(.leading, Espace.l)
        .padding(.trailing, terme.isEmpty ? Espace.l : 0)
        .frame(minHeight: Gabarit.zoneTactile)
        .background {
            Capsule()
                .fill(.regularMaterial)
                .overlay(Capsule().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
        }
    }

    @ViewBuilder private var resultats: some View {
        if trouvees.isEmpty {
            if resultatsVides {
                Text("Aucune commune trouvée.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Espace.m)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
        } else {
            VStack(spacing: 0) {
                ForEach(trouvees) { zone in
                    Button {
                        choisir(Coordonnee(latitude: zone.latitude, longitude: zone.longitude))
                        choixFait = true
                        terme = zone.nom
                        trouvees = []
                        active = false
                    } label: {
                        HStack(spacing: Espace.m) {
                            Text(zone.nom)
                                .font(Police.corps)
                                .foregroundStyle(Palette.encre)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: Espace.s)
                            if let code = zone.code {
                                Text(code)
                                    .font(Police.corps)
                                    .foregroundStyle(Palette.encreDouce)
                            }
                        }
                        .padding(.horizontal, Espace.l)
                        .frame(minHeight: 48)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if zone.id != trouvees.last?.id {
                        Divider().overlay(Palette.filet).padding(.leading, Espace.l)
                    }
                }
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
        }
    }

    /// Recherche d'une commune, limitée à la France (trois résultats au plus).
    private func chercher() async {
        let requete = MKLocalSearch.Request()
        requete.naturalLanguageQuery = terme
        requete.resultTypes = .address
        requete.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.5),
                                            span: MKCoordinateSpan(latitudeDelta: 11, longitudeDelta: 13))
        do {
            let reponse = try await MKLocalSearch(request: requete).start()
            trouvees = reponse.mapItems.prefix(3).enumerated().compactMap { (i, item) -> ZoneTrouvee? in
                guard let nom = item.name else { return nil }
                let c = item.location.coordinate
                let code = codeDepartement(Coordonnee(latitude: c.latitude, longitude: c.longitude))
                return ZoneTrouvee(id: "\(i)-\(nom)", nom: nom, latitude: c.latitude, longitude: c.longitude, code: code)
            }
            resultatsVides = trouvees.isEmpty
        } catch {
            trouvees = []
            resultatsVides = true
        }
    }
}
