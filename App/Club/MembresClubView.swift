import SwiftUI

/// La liste des membres d'un club en ligne : surnom et avatar (L21). Le fondateur peut retirer un membre ; chacun peut bloquer un membre
/// (masqué pour lui seul). Dit les limites en clair : pas de transfert du rôle de fondateur, et retirer ne ferme pas l'accès au chat.
struct MembresClubView: View {
    let club: Club
    let gestion: GestionClubs

    @Environment(\.dismiss) private var fermer
    @State private var aRetirer: Membre?

    private var etat: EtatClub { gestion.etat(de: club) }

    var body: some View {
        VStack(spacing: 0) {
            barre
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if etat == .sansFondateur {
                        note("Ce club n'a plus de fondateur. On peut encore y partager des cartes et le quitter, mais plus y entrer ni retirer un membre.")
                    }
                    EnteteGroupeClub(titre: "Membres", haut: Espace.m)
                    GroupeClub {
                        ForEach(Array(gestion.membresVisibles(de: club).enumerated()), id: \.element.id) { rang, membre in
                            if rang > 0 { FiletClub(retrait: Espace.l + 36 + Espace.m) }
                            ligne(membre)
                        }
                    }
                    if gestion.jeSuisFondateur(de: club) {
                        note("Retirer un membre l'efface du club. Il garde pour l'instant l'accès à la conversation du club : seul le fondateur peut l'en retirer, depuis le chat.")
                    }
                }
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.xl)
            }
            .scrollIndicators(.hidden)
        }
        .background(Palette.fond.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Retirer ce membre ?", isPresented: Binding(get: { aRetirer != nil }, set: { if !$0 { aRetirer = nil } }),
                            titleVisibility: .visible, presenting: aRetirer) { membre in
            Button("Retirer \(gestion.surnom(de: membre.profil))", role: .destructive) {
                Task { await gestion.ecarter(membre.profil, de: club) }
            }
            Button("Annuler", role: .cancel) {}
        } message: { _ in
            Text("Il disparaît de la liste et ses cartes ne sont plus montrées.")
        }
    }

    private func ligne(_ membre: Membre) -> some View {
        let moi = membre.profil == gestion.monID
        return HStack(spacing: Espace.m) {
            AvatarSurnom(surnom: gestion.surnom(de: membre.profil), image: gestion.avatar(de: membre.profil), taille: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text(moi ? "Moi" : gestion.surnom(de: membre.profil)).font(Police.corps).foregroundStyle(Palette.encre).lineLimit(1)
                if membre.role == .fondateur {
                    Text("Fondateur").font(Police.legende).foregroundStyle(Palette.encreDouce)
                }
            }
            Spacer(minLength: 0)
            if !moi {
                Menu {
                    if RegleAdhesion.peutEcarter(club: club, membres: gestion.membres[club.id] ?? [],
                                                 moi: gestion.monID ?? "", cible: membre.profil) {
                        Button("Retirer du club", systemImage: "person.badge.minus", role: .destructive) { aRetirer = membre }
                    }
                    Button("Bloquer", systemImage: "hand.raised", role: .destructive) { gestion.bloquer(membre.profil) }
                } label: {
                    Image(systemName: "ellipsis.circle").font(Police.taille(20)).foregroundStyle(Palette.encreDouce)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile).contentShape(Rectangle())
                }
                .accessibilityLabel("Options de \(gestion.surnom(de: membre.profil))")
            }
        }
        .frame(minHeight: 56)
        .padding(.horizontal, Espace.l)
    }

    private func note(_ texte: String) -> some View {
        Text(texte).font(Police.legende).foregroundStyle(Palette.encreDouce)
            .padding(.horizontal, Espace.l).padding(.top, Espace.m)
    }

    private var barre: some View {
        HStack(spacing: 0) {
            BoutonRond(role: .retour) { fermer() }
            Spacer(minLength: 0)
            Text("Membres").font(Police.sousTitre).foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
            Color.clear.frame(width: Gabarit.zoneTactile, height: 1)
        }
        .padding(.horizontal, Espace.bord)
    }
}
