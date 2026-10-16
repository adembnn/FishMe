import SwiftUI
import UIKit

/// Une attente en page entière : le bouchon en grand, au milieu de l'écran, et une phrase dessous.
/// Jamais une petite fenêtre en haut : l'animation prend toute la page (Adem, 16 oct.).
/// `photo` : la photo du pêcheur floutée derrière (lecture d'une prise), sinon le fond clair de l'app.
struct EcranChargement: View {
    var texte: String? = nil
    var photo: UIImage? = nil

    var body: some View {
        ZStack {
            fond
            VStack(spacing: Espace.l) {
                ChargementBouchon(taille: 96)
                if let texte {
                    Text(texte)
                        .font(Police.titre)
                        .foregroundStyle(Palette.encre)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Espace.bord)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(texte ?? "Chargement")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private var fond: some View {
        if let photo {
            Color.clear
                .overlay(Image(uiImage: photo).resizable().scaledToFill().blur(radius: 24))
                .clipped()
                .overlay(Palette.fond.opacity(0.82))
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else {
            Palette.fond.ignoresSafeArea()
        }
    }
}

#if DEBUG
#Preview("Page entière") {
    EcranChargement(texte: "Chargement du spot")
}
#endif
