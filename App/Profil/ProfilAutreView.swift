import SwiftUI

/// La page d'un autre pêcheur : avatar, surnom, inviter, signaler, bloquer (règle 1.2 d'Apple, décision 5).
/// Si le profil est le MIEN (lien `fishme://ami/…` vers moi), la page ne propose ni inviter, ni signaler, ni bloquer.
struct ProfilAutreView: View {
    let profil: ProfilModele
    let gestion: GestionProfil
    /// Le partage de MA collection : le même que celui de la page Amis. `nil` si iCloud est indisponible.
    let invitation: InvitationPescedex?
    /// L'e-mail prérempli vers le contact publié (complément du signalement en base) ; `nil` : aucun brouillon.
    var urlSignalement: (MotifSignalement) -> URL? = { _ in nil }
    /// Appelé après un blocage, pour que la page Amis retire aussi la relation de partage.
    var apresBlocage: (ProfilModele) async -> Void = { _ in }

    @Environment(\.dismiss) private var fermer
    @State private var aSignaler: ProfilModele?
    @State private var confirmerBlocage = false
    /// Le profil est masqué chez moi dès le premier choix de motif, même si l'enregistrement a échoué.
    @State private var masqueIci = false
    @State private var dernierResultat: ResultatSignalement?

    private var estMoi: Bool { profil.id == gestion.monID }

    private var boutonSignaler: some View {
        Button { aSignaler = profil } label: {
            Label("Signaler", systemImage: "flag")
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.secondaire)
        .accessibilityIdentifier("profil.signaler")
    }

    private var boutonBloquer: some View {
        Button(role: .destructive) { confirmerBlocage = true } label: {
            Label("Bloquer", systemImage: "hand.raised")
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.secondaire)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Espace.l) {
                AvatarSurnom(surnom: profil.surnom, image: profil.avatar, taille: 96)
                Text(profil.surnom)
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                if estMoi {
                    Text("C'est ton profil.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                } else if masqueIci {
                    Text(dernierResultat == .enregistre ? "Merci. Ce profil est masqué chez toi."
                         : "Ce profil est masqué chez toi. Ton signalement n'est pas enregistré.")
                        .font(Police.detail)
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                    if dernierResultat == .nonEnregistre {
                        Button("Signaler de nouveau") { aSignaler = profil }
                            .buttonStyle(.secondaire)
                            .frame(minHeight: Gabarit.zoneTactile)
                    }
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
                    // Côte à côte, ou l'un sous l'autre quand la place manque (très grand texte).
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: Espace.m) {
                            boutonSignaler
                            boutonBloquer
                        }
                        VStack(spacing: Espace.m) {
                            boutonSignaler
                            boutonBloquer
                        }
                    }
                }
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .signalerAvecMotifs(
            cible: $aSignaler,
            question: { _ in "Pourquoi signaler ce profil ?" },
            masque: { _ in true },
            envoyer: { cible, motif in
                // Masqué chez moi tout de suite ; l'écran ne dira « signalé » qu'après l'écriture en base.
                masqueIci = true
                return await gestion.signaler(cible, motif: motif)
            },
            courriel: { _, motif in urlSignalement(motif) },
            apres: { _, resultat in dernierResultat = resultat })
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
