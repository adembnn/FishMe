import SwiftUI

/// Les textes du bandeau du fil, un seul endroit. Jamais « signalé » sans preuve, jamais « envoyé » pour un e-mail.
enum TexteFeed {
    static func texte(pour message: MessageFeed?) -> String? {
        switch message {
        case .none: nil
        case .horsLigne: "Hors ligne : le dernier fil lu est affiché."
        case .iCloudIndisponible: "Connecte-toi à iCloud pour voir les nouvelles publications."
        case .iCloudPlein: "Ton iCloud est plein."
        case .profilRequis: "Finis ton profil (15 ans ou plus) pour participer."
        case .echec: "Ça n'a pas marché. Tire pour réessayer."
        case .modeExemple: "Publications d'exemple, en lecture seule. Elles ne viennent d'aucun pêcheur."
        case .signale: "Signalé, merci. Le contenu est masqué chez toi."
        case .signalementEnAttente: "Pas enregistré, réessaie. Masqué chez toi ; renvoi automatique au prochain chargement."
        }
    }

    static func symbole(pour message: MessageFeed?) -> String {
        switch message {
        case .signale: "checkmark.circle"
        case .signalementEnAttente: "exclamationmark.circle"
        case .modeExemple: "sparkles"
        case .echec: "exclamationmark.triangle"
        default: "wifi.slash"
        }
    }
}

/// Le bandeau d'information du fil et des commentaires.
struct BandeauFeed: View {
    let message: MessageFeed?

    var body: some View {
        if let texte = TexteFeed.texte(pour: message) {
            Label(texte, systemImage: TexteFeed.symbole(pour: message))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Espace.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                .accessibilityElement(children: .combine)
        }
    }
}

/// La page principale de Communauté : Tes clubs, Tes amis, Dans ta région. 20 publications par section, « Voir plus »,
/// tirer pour rafraîchir. Hors ligne, le dernier fil lu reste affiché.
/// Paresseux : les publications sont des enfants directs du `LazyVStack` (pas de `VStack` par section), donc construites à l'affichage.
struct FeedVue: View {
    let gestion: GestionFeed
    @State private var publier = false
    @State private var lieu = ContexteLieu.inconnu

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Espace.m) {
                if gestion.peutPublier { barre } else { lectureSeule }
                BandeauFeed(message: gestion.message)
                ForEach(SectionFeed.allCases) { section in
                    EnteteSectionFeed(section: section, etat: gestion.etat(section))
                    ForEach(gestion.etat(section).publications) { PublicationVue(publication: $0, gestion: gestion) }
                    if gestion.etat(section).encore {
                        Button("Voir plus") { Task { await gestion.voirPlus(section) } }
                            .buttonStyle(.secondaire)
                    }
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
    /// Fil d'exemple : on lit aussi, et le bandeau l'explique.
    @ViewBuilder
    private var lectureSeule: some View {
        if !gestion.exemples {
            Label("Finis ton profil (15 ans ou plus) pour publier et commenter.", systemImage: "person.crop.circle.badge.exclamationmark")
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
                .padding(Espace.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
        }
    }
}

/// Le titre d'une section et, tant qu'elle est vide, ce qu'elle attend.
struct EnteteSectionFeed: View {
    let section: SectionFeed
    let etat: EtatSection

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Label(section.titre, systemImage: section.symbole)
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Espace.l)
            if etat.publications.isEmpty {
                Text(etat.charge ? vide : "Chargement…")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
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

#Preview("Mode démo") {
    FeedVue(gestion: GestionFeed.pourApercu(sansCompte: true))
        .background(Palette.fond)
}
#endif
