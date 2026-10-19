import SwiftUI

/// « Écrire » : à poser sur la page d'un ami (L21) et la page d'un club (L22). A passe la fermeture qui ouvre
/// `ConversationView(gestion:conversation:)` (par exemple dans une feuille avec un `NavigationStack`).
struct BoutonEcrire: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Écrire", systemImage: "bubble.left")
        }
        .buttonStyle(.secondaire)
        .frame(minHeight: Gabarit.zoneTactile)
    }
}

#if DEBUG
#Preview {
    BoutonEcrire {}
        .padding(Espace.bord)
        .background(Palette.fond)
}
#endif
