import PhotosUI
import SwiftUI

/// Rond avec l'avatar du pêcheur (JPEG 256 px), ou l'initiale de son surnom s'il n'en a pas.
struct AvatarSurnom: View {
    let surnom: String
    var image: Data? = nil
    var taille: CGFloat = Gabarit.zoneTactile

    private var initiale: String {
        String(surnom.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            Palette.marine
            if let image, let ui = UIImage(data: image) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initiale)
                    .font(Police.taille(taille * 0.45, .heavy))
                    .foregroundStyle(Palette.surMarine)
            }
        }
        .frame(width: taille, height: taille)
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

/// Choisir son avatar : une photo de la galerie (recadrée ronde, 256 px) ou un poisson de l'app.
struct ChoixAvatar: View {
    let surnom: String
    @Binding var donnees: Data?
    @State private var choixPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: Espace.m) {
            AvatarSurnom(surnom: surnom.isEmpty ? "?" : surnom, image: donnees, taille: 88)
            PhotosPicker(selection: $choixPhoto, matching: .images) {
                Label("Choisir une photo", systemImage: "photo")
                    .font(Police.corps)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: Espace.s)], spacing: Espace.s) {
                ForEach(AvatarImage.poissons, id: \.self) { nom in
                    Button {
                        donnees = AvatarImage.depuisPoisson(nom)
                    } label: {
                        Image(nom)
                            .resizable()
                            .scaledToFit()
                            .padding(Espace.xs)
                            .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                            .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.s, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Poisson : \(nom.replacingOccurrences(of: "-", with: " "))")
                }
            }
        }
        .onChange(of: choixPhoto) { _, nouveau in
            guard let nouveau else { return }
            Task {
                if let brut = try? await nouveau.loadTransferable(type: Data.self), let pret = AvatarImage.preparer(brut) {
                    donnees = pret
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var avatar: Data? = nil
    ChoixAvatar(surnom: "gros-brochet", donnees: $avatar)
        .padding()
        .background(Palette.fond)
}
