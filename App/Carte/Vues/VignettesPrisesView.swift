import SwiftUI
import UIKit
import Core

/// Une rangée de vignettes : tes propres prises faites sur ce coin. Elles viennent de ta collection, sur ton iPhone,
/// et ne sont partagées nulle part. Aucune phrase : un petit titre à icône, puis les photos.
struct VignettesPrisesView: View {
    let prises: [Prise]
    let photo: @Sendable (Prise) -> Data?
    /// Le nom de l'espèce, pour le libellé VoiceOver de chaque vignette.
    let nomEspece: (Espece) -> String

    var body: some View {
        if !prises.isEmpty {
            VStack(alignment: .leading, spacing: Espace.s) {
                Label("Mes prises ici", systemImage: "photo.on.rectangle")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .accessibilityAddTraits(.isHeader)
                ScrollView(.horizontal) {
                    HStack(spacing: Espace.s) {
                        ForEach(prises) { prise in
                            VignettePriseView(prise: prise, photo: photo, nomEspece: nomEspece(prise.espece))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
}

/// Une vignette carrée de 72 pt. La photo est lue hors du fil principal ; sans photo lisible, un poisson générique.
struct VignettePriseView: View {
    let prise: Prise
    let photo: @Sendable (Prise) -> Data?
    let nomEspece: String
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Rayon.s, style: .continuous).fill(Palette.tuile)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "fish")
                    .font(Police.taille(22))
                    .foregroundStyle(Palette.silhouette)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
        .accessibilityElement()
        .accessibilityLabel("Ma prise : \(nomEspece), \(prise.date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "fr_FR"))))")
        .task(id: prise.id) {
            let source = photo
            let p = prise
            let donnees = await Task.detached(priority: .utility) { source(p) }.value
            if let donnees { image = UIImage(data: donnees) }
        }
    }
}
