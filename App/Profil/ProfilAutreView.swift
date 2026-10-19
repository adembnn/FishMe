import SwiftUI

/// La page d'un autre pêcheur : avatar, surnom, inviter, signaler, bloquer (règle 1.2 d'Apple, décision 5).
struct ProfilAutreView: View {
    let profil: ProfilModele
    let gestion: GestionProfil
    /// Le partage de MA collection : le même que celui de la page Amis. `nil` si iCloud est indisponible.
    let invitation: InvitationPescedex?
    /// Appelé après un blocage, pour que la page Amis retire aussi la relation de partage.
    /// L'e-mail prérempli vers le contact publié (circuit principal de `moderation.md`) ; `nil` : seule la trace CloudKit part.
    var urlSignalement: (MotifSignalement) -> URL? = { _ in nil }
    var apresBlocage: (ProfilModele) async -> Void = { _ in }

    @Environment(\.dismiss) private var fermer
    @Environment(\.openURL) private var ouvrirURL
    @State private var choisirMotif = false
    @State private var confirmerBlocage = false
    @State private var signale = false

    var body: some View {
        ScrollView {
            VStack(spacing: Espace.l) {
                AvatarSurnom(surnom: profil.surnom, image: profil.avatar, taille: 96)
                Text(profil.surnom)
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                if signale {
                    Text("Merci. Ce profil est masqué chez toi.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                } else {
                    if let invitation {
                        ShareLink(item: invitation, preview: SharePreview("Mon Pescedex")) {
                            Label("Inviter \(profil.surnom)", systemImage: "person.badge.plus")
                                .font(Police.corps)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
                        }
                        .buttonStyle(.principal)
                        .accessibilityIdentifier("profil.inviter")
                    }
                    HStack(spacing: Espace.m) {
                        Button { choisirMotif = true } label: {
                            Label("Signaler", systemImage: "flag")
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                        }
                        .buttonStyle(.secondaire)
                        Button(role: .destructive) { confirmerBlocage = true } label: {
                            Label("Bloquer", systemImage: "hand.raised")
                                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
                        }
                        .buttonStyle(.secondaire)
                    }
                }
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .confirmationDialog("Pourquoi signaler ce profil ?", isPresented: $choisirMotif, titleVisibility: .visible) {
            ForEach(MotifSignalement.allCases) { motif in
                Button(motif.titre) {
                    Task {
                        await gestion.signaler(profil, motif: motif)
                        if let url = urlSignalement(motif) { ouvrirURL(url) }
                        signale = true
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        }
        .confirmationDialog("Bloquer \(profil.surnom) ? Ce profil n'apparaît plus dans ta recherche ni dans ton fil.",
                            isPresented: $confirmerBlocage, titleVisibility: .visible) {
            Button("Bloquer", role: .destructive) {
                gestion.bloquer(profil.id)
                Task {
                    await apresBlocage(profil)
                    fermer()
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }
}

#if DEBUG
#Preview("Profil d'un autre") {
    ProfilAutreView(profil: ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date()),
                    gestion: GestionProfil(service: FauxServiceProfil()), invitation: nil)
}
#endif
