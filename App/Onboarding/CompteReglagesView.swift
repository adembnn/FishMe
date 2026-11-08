import SwiftUI

/// « Mon compte FishMe » dans Réglages : le surnom et l'e-mail gardés sur l'iPhone, et leur suppression (Apple 5.1.1(v)).
struct CompteReglagesView: View {
    let compte: CompteOnboarding
    @Environment(RegionCourante.self) private var region
    @State private var confirmation: Confirmation?

    enum Confirmation: Identifiable {
        case email, compte
        var id: Int { self == .email ? 0 : 1 }
    }

    private var fr: Bool { region.langue == .francais }
    private func t(_ francais: String, _ anglais: String) -> String { fr ? francais : anglais }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ligne(t("Surnom", "Nickname"), valeur: compte.surnom ?? t("Aucun", "None"))
            Divider().overlay(Palette.filet)
            ligne("E-mail", valeur: compte.email ?? t("Aucun", "None"))
            if compte.email != nil {
                Divider().overlay(Palette.filet)
                bouton(t("Supprimer mon e-mail", "Delete my email"), id: "reglages.compte.supprimer-email") { confirmation = .email }
            }
            if compte.aUnCompte {
                Divider().overlay(Palette.filet)
                bouton(t("Supprimer mon compte", "Delete my account"), id: "reglages.compte.supprimer-compte") { confirmation = .compte }
            }
        }
        .confirmationDialog(titre, isPresented: Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } }),
                            titleVisibility: .visible) {
            Button(t("Supprimer", "Delete"), role: .destructive) {
                let choix = confirmation
                confirmation = nil
                Task { if choix == .email { await compte.supprimerEmail() } else { await compte.supprimerCompte() } }
            }
            Button(t("Annuler", "Cancel"), role: .cancel) { confirmation = nil }
        } message: {
            Text(confirmation == .email
                 ? t("Ton adresse est effacée de cet iPhone, et de nos listes si elle y était.", "Your address is erased from this iPhone, and from our lists if it was there.")
                 : t("Ton surnom et ton e-mail sont effacés de cet iPhone. Tes cartes restent.", "Your nickname and email are erased from this iPhone. Your cards stay."))
        }
    }

    private var titre: String {
        confirmation == .email ? t("Supprimer ton e-mail ?", "Delete your email?") : t("Supprimer ton compte ?", "Delete your account?")
    }

    private func ligne(_ nom: String, valeur: String) -> some View {
        HStack {
            Text(nom).foregroundStyle(Palette.encre)
            Spacer()
            Text(valeur).foregroundStyle(Palette.encreDouce).lineLimit(1)
        }
        .font(Police.corps)
        .padding(.horizontal, 16)
        .frame(minHeight: 46)
    }

    private func bouton(_ titre: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titre).font(Police.corps).foregroundStyle(Palette.bouchon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(minHeight: 46)
        }
        .accessibilityIdentifier(id)
    }
}
