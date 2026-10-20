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

/// La conversation dans une feuille, avec un bouton « Fermer » de 44 points. À présenter avec `.sheet(item:)` depuis une page ami ou club.
struct FeuilleConversationView: View {
    let gestion: GestionChat
    let conversation: ConversationID
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ConversationView(gestion: gestion, conversation: conversation)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fermer") { dismiss() }
                            .frame(minHeight: Gabarit.zoneTactile)
                    }
                }
        }
        .task {
            await gestion.chargerListe()
            await gestion.actualiserListe()
        }
    }
}

#if DEBUG
#Preview {
    BoutonEcrire {}
        .padding(Espace.bord)
        .background(Palette.fond)
}
#endif
