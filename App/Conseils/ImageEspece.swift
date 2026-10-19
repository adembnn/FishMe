import SwiftUI
import UIKit

/// L'illustration d'une espèce (posée dans App/Assets.xcassets par A, livrée par D1) ; un poisson générique si elle manque.
struct ImageEspece: View {
    let nom: String
    let libelle: String
    /// Vrai : l'image est rendue en aplat de la couleur « silhouette » (poisson pas encore trouvé).
    var silhouette: Bool = false

    var body: some View {
        Group {
            if UIImage(named: nom) != nil {
                if silhouette {
                    Image(nom).renderingMode(.template).resizable().scaledToFit().foregroundStyle(Palette.silhouette)
                } else {
                    Image(nom).resizable().scaledToFit()
                }
            } else if silhouette {
                Image(systemName: "fish.fill").resizable().scaledToFit().padding(12).foregroundStyle(Palette.silhouette)
            } else {
                Image(systemName: "fish.fill").resizable().scaledToFit().padding(12).foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(libelle)
    }
}

/// Une icône de conseil : le nom SF Symbols donné par Core, ou un poisson si le nom est inconnu.
struct IconeConseil: View {
    let nom: String

    var body: some View {
        Image(systemName: UIImage(systemName: nom) != nil ? nom : "fish")
            .font(.title3.weight(.bold))
            .foregroundStyle(JetonsConseils.accent)
            .frame(width: JetonsConseils.tailleToucher, height: JetonsConseils.tailleToucher)
            .background(JetonsConseils.accent.opacity(0.12), in: Circle())
            .accessibilityHidden(true)
    }
}
