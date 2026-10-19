import SwiftUI
import UIKit

/// Une photo lue au moment de l'afficher (jamais à l'ouverture de la liste). Le carré fait au moins 44 pt.
struct VignettePhotoRepere: View {
    let charger: () async -> Data?
    var cote: CGFloat = 96
    var surRetrait: (() -> Void)?
    @State private var image: UIImage?
    @State private var tentee = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(Palette.tuile)
                        .overlay {
                            Image(systemName: tentee ? "photo" : "hourglass")
                                .foregroundStyle(Palette.encreDouce)
                        }
                }
            }
            .frame(width: cote, height: cote)
            .clipShape(RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
            .accessibilityLabel("Photo")

            if let surRetrait {
                Button(action: surRetrait) {
                    Image(systemName: "xmark.circle.fill")
                        .font(Police.taille(22, .heavy))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Palette.surface, Palette.encre)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Retirer la photo")
            }
        }
        .task {
            if let donnees = await charger() { image = UIImage(data: donnees) }
            tentee = true
        }
    }
}
