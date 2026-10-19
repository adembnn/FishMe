import SwiftUI

/// Les réglages de mon profil : avatar, nom et prénom privés (facultatifs), « Supprimer mon profil » en deux temps.
struct ReglagesProfilView: View {
    let gestion: GestionProfil
    @Environment(\.dismiss) private var fermer
    @State private var avatar: Data?
    @State private var nom = ""
    @State private var prenom = ""
    @State private var premiereQuestion = false
    @State private var secondeQuestion = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.xl) {
                entete
                if let profil = gestion.profil {
                    ChoixAvatar(surnom: profil.surnom, donnees: $avatar)
                        .frame(maxWidth: .infinity)
                    privee
                    if let lien = LienAmi.url(profilID: profil.id) {
                        ShareLink(item: lien, message: Text("Retrouve-moi sur FishMe : \(profil.surnom)")) {
                            Label("Partager le lien à mes acolytes", systemImage: "square.and.arrow.up")
                                .font(Police.corps)
                                .frame(maxWidth: .infinity, minHeight: Gabarit.bouton)
                        }
                        .buttonStyle(.secondaire)
                    }
                    if let message = gestion.message {
                        Text(message.texte).font(Police.detail).foregroundStyle(Palette.alerte)
                    }
                    suppression
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
        .onAppear {
            avatar = gestion.profil?.avatar
            let prive = gestion.identitePrivee()
            nom = prive.nom
            prenom = prive.prenom
        }
        .onChange(of: avatar) { ancien, nouveau in
            guard ancien != nouveau, nouveau != gestion.profil?.avatar else { return }
            Task { await gestion.changerAvatar(nouveau) }
        }
    }

    private var entete: some View {
        HStack {
            if let profil = gestion.profil {
                Text(profil.surnom)
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
            }
            Spacer()
            Button("Fermer") { fermer() }
                .font(Police.corps)
                .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
        }
    }

    /// Nom et prénom : restent dans la base privée, ne s'affichent chez personne.
    private var privee: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Label("Nom et prénom (facultatif)", systemImage: "lock")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            Text("Privés : personne ne les voit, ni les amis ni le réseau.")
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
            champ("Prénom", texte: $prenom)
            champ("Nom", texte: $nom)
        }
    }

    private func champ(_ titre: String, texte: Binding<String>) -> some View {
        TextField(titre, text: texte)
            .textContentType(titre == "Nom" ? .familyName : .givenName)
            .font(Police.corps)
            .padding(Espace.m)
            .frame(minHeight: Gabarit.zoneTactile)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            .onChange(of: texte.wrappedValue) { _, _ in gestion.enregistrerIdentitePrivee(nom: nom, prenom: prenom) }
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
                Text("Ton surnom, ton avatar, tes publications et tes commentaires seront effacés.")
            }
            .alert("Dernière vérification", isPresented: $secondeQuestion) {
                Button("Tout effacer", role: .destructive) {
                    Task {
                        if await gestion.supprimer() { fermer() }
                    }
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Cela ne peut pas être annulé. Ton Pescedex reste sur ton iPhone.")
            }
    }
}

#if DEBUG
#Preview("Mon profil") {
    let profil = ProfilModele(id: "p-gros-brochet", surnom: "Gros-Brochet", avatar: nil, creeLe: Date())
    ReglagesProfilView(gestion: GestionProfil(service: FauxServiceProfil(profils: [profil])))
}
#endif
