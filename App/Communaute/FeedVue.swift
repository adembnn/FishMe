import SwiftUI

/// La page principale de Communauté : Tes clubs, Tes amis, Dans ta région. 20 publications par section, « Voir plus »,
/// tirer pour rafraîchir. Hors ligne, le dernier fil lu reste affiché.
struct FeedVue: View {
    let gestion: GestionFeed
    @State private var publier = false
    @State private var lieu = ContexteLieu.inconnu

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Espace.xl) {
                if gestion.peutPublier { barre } else { lectureSeule }
                if let texte = texte(pour: gestion.message) { bandeau(texte) }
                ForEach(SectionFeed.allCases) { section in
                    SectionFeedVue(section: section, etat: gestion.etat(section), gestion: gestion)
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, Espace.xxl)
        }
        .scrollIndicators(.hidden)
        .refreshable { await gestion.actualiser() }
        .task { await gestion.ouvrir() }
        .sheet(isPresented: $publier) {
            PublierVue(gestion: gestion, contexteLieu: lieu)
        }
    }

    private var barre: some View {
        HStack {
            Spacer()
            Button {
                Task {
                    lieu = await gestion.lieuCourant()
                    publier = true
                }
            } label: {
                Label("Publier", systemImage: "plus")
                    .font(Police.corps)
                    .padding(.horizontal, Espace.l)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .foregroundStyle(Palette.surMarine)
                    .background(Palette.marine, in: Capsule())
            }
        }
    }

    /// Sans profil « 15 ans ou plus » : on lit, on ne publie pas. La feuille « Finis ton profil » (L21) est branchée par A.
    private var lectureSeule: some View {
        Label("Finis ton profil (15 ans ou plus) pour publier et commenter.", systemImage: "person.crop.circle.badge.exclamationmark")
            .font(Police.detail)
            .foregroundStyle(Palette.encre)
            .padding(Espace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    private func bandeau(_ texte: String) -> some View {
        Label(texte, systemImage: "wifi.slash")
            .font(Police.detail)
            .foregroundStyle(Palette.encreDouce)
            .padding(Espace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }

    private func texte(pour message: MessageFeed?) -> String? {
        switch message {
        case .none: nil
        case .horsLigne: "Hors ligne : le dernier fil lu est affiché."
        case .iCloudIndisponible: "Connecte-toi à iCloud pour voir les nouvelles publications."
        case .iCloudPlein: "Ton iCloud est plein."
        case .profilRequis: "Finis ton profil (15 ans ou plus) pour participer."
        case .echec: "Un souci est survenu. Tire pour réessayer."
        }
    }
}

struct SectionFeedVue: View {
    let section: SectionFeed
    let etat: EtatSection
    let gestion: GestionFeed

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Label(section.titre, systemImage: section.symbole)
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)
            if etat.publications.isEmpty {
                Text(etat.charge ? vide : "Chargement…")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
            }
            ForEach(etat.publications) { PublicationVue(publication: $0, gestion: gestion) }
            if etat.encore {
                Button("Voir plus") { Task { await gestion.voirPlus(section) } }
                    .buttonStyle(.secondaire)
            }
        }
    }

    private var vide: String {
        switch section {
        case .clubs: "Rejoins un club pour voir ses publications."
        case .amis: "Invite un ami pour voir ses publications."
        case .region: "Rien pour l'instant dans ta région."
        }
    }
}

#if DEBUG
#Preview {
    FeedVue(gestion: GestionFeed.pourApercu())
        .background(Palette.fond)
}

#Preview("Très grand texte") {
    FeedVue(gestion: GestionFeed.pourApercu())
        .background(Palette.fond)
        .environment(\.dynamicTypeSize, .accessibility5)
}
#endif
