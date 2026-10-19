import SwiftUI

/// Les commentaires d'une publication : 20 d'abord, « Voir plus », un champ filtré en bas.
struct CommentairesVue: View {
    @State private var modele: ModeleCommentaires
    @Environment(\.openURL) private var ouvrirURL
    @Environment(\.dismiss) private var fermer
    private let gestion: GestionFeed

    init(publication: PublicationFeed, gestion: GestionFeed) {
        self.gestion = gestion
        _modele = State(initialValue: ModeleCommentaires(publication: publication, gestion: gestion))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Commentaires").font(Police.titre).foregroundStyle(Palette.encre).accessibilityAddTraits(.isHeader)
                Spacer()
                BoutonRond(role: .fermer)
            }
            .padding(Espace.bord)
            BandeauFeed(message: gestion.message)
                .padding(.horizontal, Espace.bord)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Espace.m) {
                    if modele.commentaires.isEmpty {
                        Text(modele.erreur ?? "Aucun commentaire pour l'instant.")
                            .font(Police.detail).foregroundStyle(Palette.encreDouce)
                    }
                    ForEach(modele.commentaires) { ligne($0) }
                    if modele.encore {
                        Button("Voir plus") { Task { await modele.charger(plus: true) } }
                            .buttonStyle(.secondaire)
                    }
                }
                .padding(.horizontal, Espace.bord)
            }
            .scrollIndicators(.hidden)
            saisie
        }
        .background(Palette.fond.ignoresSafeArea())
        .task { await modele.charger() }
    }

    private func ligne(_ c: CommentaireFeed) -> some View {
        HStack(alignment: .top, spacing: Espace.s) {
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text(c.auteurAffiche).font(Police.detail).foregroundStyle(Palette.marine)
                Text(c.texte).font(Police.corps).foregroundStyle(Palette.encre).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            MenuModeration(
                estMien: gestion.estMienne(c.auteurNom),
                onSignaler: { motif in
                    Task {
                        let issue = await modele.signaler(c, motif: motif)
                        if let url = issue.courriel { ouvrirURL(url) }
                    }
                },
                onBloquer: { Task { await modele.bloquer(c) } },
                onSupprimer: { Task { await modele.supprimer(c) } })
        }
        .padding(Espace.m)
        .tuileFishMe()
    }

    private var saisie: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            if let refus = modele.refus {
                Text(refus.message).font(Police.legende).foregroundStyle(Palette.alerte)
            } else if gestion.exemples {
                Text("Publications d'exemple : lecture seule.").font(Police.legende).foregroundStyle(Palette.encreDouce)
            } else if !gestion.peutPublier {
                Text("Finis ton profil (15 ans ou plus) pour commenter.").font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
            HStack(alignment: .bottom, spacing: Espace.s) {
                TextField("Ton commentaire", text: $modele.texte, axis: .vertical)
                    .font(Police.corps)
                    .lineLimit(1...4)
                    .padding(Espace.m)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .tuileFishMe()
                Button {
                    Task { await modele.envoyer() }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .foregroundStyle(Palette.surMarine)
                        .background(modele.peutEnvoyer ? Palette.marine : Palette.silhouette, in: Circle())
                }
                .disabled(!modele.peutEnvoyer)
                .accessibilityLabel("Envoyer")
            }
        }
        .padding(Espace.bord)
    }
}

#if DEBUG
#Preview {
    CommentairesVue(publication: DemoFeed.publications[0], gestion: GestionFeed.pourApercu())
}
#endif
