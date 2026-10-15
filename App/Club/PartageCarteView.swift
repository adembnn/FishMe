import SwiftUI
import UIKit

/// Choisir une carte déjà rendue par L4, puis la feuille de partage d'iOS. L'image part sans aucune métadonnée.
struct PartageCarteView: View {
    let cartes: [CarteAPartager]

    var body: some View {
        Group {
            if cartes.isEmpty {
                ContentUnavailableView("Aucune carte", systemImage: "rectangle.stack",
                                       description: Text("Ta première prise crée ta première carte."))
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 12)], spacing: 12) {
                        ForEach(cartes) { carte in
                            ShareLink(item: carte, preview: SharePreview(carte.titre, image: apercu(carte))) {
                                apercu(carte)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .accessibilityLabel(Text("Partager \(carte.titre)"))
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Partager une carte")
    }

    private func apercu(_ carte: CarteAPartager) -> Image {
        if let image = UIImage(data: carte.png) { return Image(uiImage: image) }
        return Image(systemName: "photo")
    }
}
