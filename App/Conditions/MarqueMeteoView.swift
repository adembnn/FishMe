import Combine
import SwiftUI
import Core

/// Garde sur l'iPhone la marque Apple Weather (liens et images) pour l'afficher sans réseau.
@MainActor
final class StockageMarque: ObservableObject {
    @Published private(set) var marque: MarqueApple?
    @Published private(set) var imageClaire: Data?
    @Published private(set) var imageSombre: Data?

    private let source: any SourceMarque
    private let dossier: URL?

    init(source: any SourceMarque,
         dossier: URL? = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("marque-apple-weather")) {
        self.source = source
        self.dossier = dossier
        chargerLocal()
    }

    func rafraichir() async {
        guard let m = await source.marque() else { return }
        marque = m
        async let c = telecharger(m.claireURL)
        async let s = telecharger(m.sombreURL)
        let (clair, sombre) = await (c, s)
        if let clair { imageClaire = clair }
        if let sombre { imageSombre = sombre }
        enregistrer()
    }

    private func telecharger(_ url: URL) async -> Data? {
        try? await URLSession.shared.data(from: url).0
    }

    private func chargerLocal() {
        guard let dossier else { return }
        if let d = try? Data(contentsOf: dossier.appendingPathComponent("marque.json")) {
            marque = try? JSONDecoder().decode(MarqueApple.self, from: d)
        }
        imageClaire = try? Data(contentsOf: dossier.appendingPathComponent("claire.png"))
        imageSombre = try? Data(contentsOf: dossier.appendingPathComponent("sombre.png"))
    }

    private func enregistrer() {
        guard let dossier else { return }
        try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        if let marque, let d = try? JSONEncoder().encode(marque) { try? d.write(to: dossier.appendingPathComponent("marque.json")) }
        if let imageClaire { try? imageClaire.write(to: dossier.appendingPathComponent("claire.png")) }
        if let imageSombre { try? imageSombre.write(to: dossier.appendingPathComponent("sombre.png")) }
    }
}

/// Un seul composant « marque », posé sous chaque bloc qui montre un chiffre météo (rangée, 7 jours, ligne de session,
/// dos de carte, « tes conditions ») et dans la page Sources de L9. Jamais sur l'image partagée.
struct MarqueMeteoView: View {
    @ObservedObject var stockage: StockageMarque
    /// Texte du lien (maquettes : « Sources des données »). Le lien légal d'Apple Weather reste le lien par défaut.
    var libelleLien: String = "Sources des données"
    /// Si l'appelant fournit une action (écran d'alerte : ses propres sources), elle remplace l'ouverture de la page légale.
    var action: (() -> Void)? = nil
    /// Texte en plus après le lien, par exemple « Hub'Eau ».
    var mention: String? = nil
    @Environment(\.colorScheme) private var schema
    @Environment(\.openURL) private var ouvrir

    var body: some View {
        HStack(spacing: 6) {
            image
            Text("·").accessibilityHidden(true)
            if stockage.marque?.legaleURL != nil || action != nil {
                Button {
                    if let action { action() } else if let lien = stockage.marque?.legaleURL { ouvrir(lien) }
                } label: {
                    Text(AnglaisF.t(libelleLien))
                        .foregroundStyle(Palette.marine)
                        .underline()
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AnglaisF.t(action == nil ? "Source météo : page légale d'Apple Weather" : libelleLien))
            }
            if let mention {
                Text("·").accessibilityHidden(true)
                Text(mention)
            }
        }
        .font(Police.taille(13, .heavy))
        .foregroundStyle(Palette.encreDouce)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("marque-apple-weather")
        .task { await stockage.rafraichir() }
    }

    @ViewBuilder private var image: some View {
        let data = schema == .dark ? stockage.imageSombre : stockage.imageClaire
        if let data, let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFit()
                .frame(height: 14)
                .accessibilityLabel("Apple Weather")
        } else {
            // Première ouverture sans réseau : le nom seul, en attendant la marque.
            Text(stockage.marque?.nom ?? "Apple Weather")
        }
    }
}
