import SwiftUI

/// Les réglages de mon profil : avatar, partage du lien, « Supprimer mon profil » en deux temps.
/// Juste un pseudonyme (décision 3) : aucun champ nom ni prénom.
/// Hors ligne, avec un identifiant gardé mais sans profil relu, l'écran reste utile : « Mon profil », réessayer, supprimer.
struct ReglagesProfilView: View {
    let gestion: GestionProfil
    @Environment(\.dismiss) private var fermer
    @State private var avatar: Data?
    @State private var premiereQuestion = false
    @State private var secondeQuestion = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                entete
                if let profil = gestion.profil {
                    ChoixAvatar(surnom: profil.surnom, donnees: $avatar)
                        .frame(maxWidth: .infinity)
                    if let lien = LienAmi.url(profilID: profil.id) {
                        ShareLink(item: lien, message: Text("Retrouve-moi sur FishMe : \(profil.surnom)")) {
                            Label("Partager le lien à mes acolytes", systemImage: "square.and.arrow.up")
                                .font(Police.corps)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
                        }
                        .buttonStyle(.secondaire)
                    }
                    messageEtSuppression
                } else if gestion.aUnProfil {
                    // Hors ligne (ou lecture en échec) : l'iPhone sait qu'un profil existe, sans pouvoir le relire.
                    Text("Ton profil n'a pas pu être relu pour l'instant. Tu peux réessayer, ou le supprimer.")
                        .font(Police.corps)
                        .foregroundStyle(Palette.encreDouce)
                    Button("Réessayer") { Task { await gestion.charger() } }
                        .buttonStyle(.secondaire)
                        .frame(minHeight: Gabarit.zoneTactile)
                    messageEtSuppression
                } else {
                    Text("Tu n'as pas de profil. Tu peux en créer un depuis Amis.")
                        .font(Police.corps)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.vertical, Espace.xl)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .onAppear { avatar = gestion.profil?.avatar }
        .onChange(of: avatar) { ancien, nouveau in
            guard ancien != nouveau, nouveau != gestion.profil?.avatar else { return }
            Task {
                await gestion.changerAvatar(nouveau)
                // Si l'envoi a échoué, l'avatar affiché redevient celui du serveur (pas de faux avatar local).
                avatar = gestion.profil?.avatar
            }
        }
    }

    private var entete: some View {
        HStack {
            if let surnom = gestion.surnomMemorise {
                Text(surnom)
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
            }
            Spacer()
            Button("Fermer") { fermer() }
                .font(Police.corps)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
        }
    }

    @ViewBuilder private var messageEtSuppression: some View {
        if let message = gestion.message {
            Text(message.texte).font(Police.detail).foregroundStyle(Palette.alerte)
        }
        suppression
    }

    // MARK: Supprimer mon profil, en deux temps

    private var suppression: some View {
        Button("Supprimer mon profil", role: .destructive) { premiereQuestion = true }
            .font(Police.corps)
            .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            .accessibilityIdentifier("profil.supprimer")
            .confirmationDialog("Supprimer ton profil ?", isPresented: $premiereQuestion, titleVisibility: .visible) {
                Button("Continuer", role: .destructive) { secondeQuestion = true }
                Button("Garder mon profil", role: .cancel) {}
            } message: {
                // Jamais plus que ce qui sera vraiment effacé : le texte suit les effaceurs branchés (L23, L24).
                Text(gestion.phraseSuppression)
            }
            .alert("Dernière vérification", isPresented: $secondeQuestion) {
                Button("Tout effacer", role: .destructive) {
                    Task {
                        if await gestion.supprimer() { fermer() }
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cela ne peut pas être annulé. Ton Pescedex reste sur ton iPhone. Les cartes que tu as partagées avec tes amis restent partagées : arrête-les dans Amis.")
            }
    }
}

#if DEBUG
#Preview("Mon profil") {
    let profil = ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date())
    ReglagesProfilView(gestion: GestionProfil(service: FauxServiceProfil(profils: [profil])))
}
#endif
