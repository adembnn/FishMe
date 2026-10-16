import PhotosUI
import SwiftUI
import UIKit

/// Fin d'une sortie sans prise : « Ajouter une photo de ma sortie ». Appareil photo ou photothèque ; la photo va sur la carte
/// « Eau calme » et repasse par le nettoyage (jamais de GPS) chez celui qui l'enregistre. Sans photo, la carte reste belle.
struct AjoutPhotoSortieView: View {
    /// Reçoit les octets de la photo choisie ; l'enregistrement et le nettoyage sont faits ailleurs.
    let surPhoto: (Data) -> Void

    @State private var apercu: UIImage?
    @State private var cameraOuverte = false
    @State private var photothequeOuverte = false
    @State private var choix: PhotosPickerItem?

    var body: some View {
        Menu {
            if PriseCamera.disponible {
                Button { cameraOuverte = true } label: { Label("Prendre une photo", systemImage: "camera") }
            }
            Button { photothequeOuverte = true } label: { Label("Choisir dans la photothèque", systemImage: "photo.on.rectangle") }
        } label: {
            HStack(spacing: 14) {
                vignette
                VStack(alignment: .leading, spacing: 2) {
                    Text(apercu == nil ? "Ajouter une photo de ma sortie" : "Photo ajoutée")
                        .font(Police.taille(17, .heavy))
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.leading)
                    Text(apercu == nil ? "Elle ira sur ta carte Eau calme." : "Elle est sur ta carte Eau calme. Touche pour la changer.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            .contentShape(Rectangle())
        }
        .accessibilityLabel(apercu == nil ? "Ajouter une photo de ma sortie" : "Changer la photo de ma sortie")
        .fullScreenCover(isPresented: $cameraOuverte) {
            PriseCamera(onImage: { image in
                cameraOuverte = false
                if let data = image.jpegData(compressionQuality: 0.9) { prendre(data, image) }
            }, onCancel: { cameraOuverte = false })
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: $photothequeOuverte, selection: $choix, matching: .images)
        .onChange(of: choix) { _, nouveau in
            guard let nouveau else { return }
            Task {
                if let data = try? await nouveau.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    prendre(data, image)
                }
                choix = nil
            }
        }
    }

    private func prendre(_ data: Data, _ image: UIImage) {
        apercu = image
        surPhoto(data)
    }

    private var vignette: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Palette.tuile)
            if let apercu {
                Image(uiImage: apercu).resizable().scaledToFill()
            } else {
                Image(systemName: "camera")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Palette.marine)
            }
        }
        .frame(width: 84, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}
