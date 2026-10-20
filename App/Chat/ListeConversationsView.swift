import SwiftUI

/// La liste des conversations : amis d'abord, puis clubs. Dernier message, heure, point pour un message pas encore vu.
/// A l'affiche dans la page Communauté (voir le rapport L24). Rien n'est demandé ici : pas de permission à l'ouverture.
struct ListeConversationsView: View {
    let gestion: GestionChat
    @Environment(\.scenePhase) private var phase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Espace.l) {
                    if let avis = gestion.avis {
                        BandeauAvisChat(avis: avis) { gestion.effacerAvis() }
                            .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                    }
                    if gestion.exemple {
                        Label("Exemples : lecture seule, rien n'est envoyé.", systemImage: "info.circle")
                            .font(Police.detail)
                            .foregroundStyle(Palette.encreDouce)
                    }
                    if gestion.resumes.isEmpty {
                        vide
                    } else {
                        section("Amis", symbole: "person.fill", type: .ami)
                        section("Clubs", symbole: "person.3.fill", type: .club)
                    }
                }
                .padding(.horizontal, Espace.bord)
                .padding(.vertical, Espace.m)
            }
            .scrollIndicators(.hidden)
            .refreshable { await gestion.actualiserListe() }
            .background(Palette.fond)
            .navigationTitle("Messages")
            .navigationDestination(for: ConversationID.self) { conversation in
                ConversationView(gestion: gestion, conversation: conversation)
            }
        }
        // Dans cet ordre : la liste d'abord (qui peut créer quelle zone), puis le réseau qui rejoue la file.
        .task {
            await gestion.chargerListe()
            await gestion.actualiserListe()
            await gestion.surveillerReseau()
        }
        .onAppear { gestion.definirActif(phase == .active) }
        .onChange(of: phase) { gestion.definirActif(phase == .active) }
    }

    private var vide: some View {
        VStack(spacing: Espace.s) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(Palette.silhouette)
            Text("Pas encore de conversation.")
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Espace.xxl)
    }

    @ViewBuilder
    private func section(_ titre: String, symbole: String, type: TypeConversation) -> some View {
        let lignes = gestion.resumes.filter { $0.conversation.type == type }
        if !lignes.isEmpty {
            VStack(alignment: .leading, spacing: Espace.s) {
                Text(titre)
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                ForEach(lignes) { ligne in
                    NavigationLink(value: ligne.conversation) {
                        LigneConversation(resume: ligne, symbole: symbole)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct LigneConversation: View {
    let resume: ResumeConversation
    let symbole: String

    @Environment(\.dynamicTypeSize) private var tailleTexte

    var body: some View {
        // Très grand texte : avatar et texte en colonne, l'heure sous le texte.
        Group {
            if tailleTexte.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Espace.s) {
                    avatar
                    textes
                    indicateurs(alignement: .leading)
                }
            } else {
                HStack(spacing: Espace.m) {
                    avatar
                    textes
                        .frame(maxWidth: .infinity, alignment: .leading)
                    indicateurs(alignement: .trailing)
                }
            }
        }
        .padding(Espace.m)
        .frame(minHeight: Gabarit.zoneTactile)
        .tuileFishMe()
        .contentShape(Rectangle())
    }

    // Avatar : un symbole en attendant l'avatar du profil (À aligner L21).
    private var avatar: some View {
        Image(systemName: symbole)
            .foregroundStyle(Palette.marine)
            .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
            .background(Palette.marineDoux, in: Circle())
    }

    private var textes: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            Text(resume.titre)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
            Text(resume.ferme ? "Conversation fermée" : (resume.dernier?.texte ?? "Aucun message"))
                .font(Police.detail)
                .foregroundStyle(Palette.encreDouce)
                .lineLimit(1)
        }
    }

    private func indicateurs(alignement: HorizontalAlignment) -> some View {
        VStack(alignment: alignement, spacing: Espace.xs) {
            if let date = resume.dernier?.date {
                Text(heure(date))
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
            if resume.nonLu && !resume.ferme {
                Circle()
                    .fill(Palette.marine)
                    .frame(width: 10, height: 10)
                    .accessibilityLabel("Nouveau message")
            }
        }
    }

    private func heure(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }
}

#if DEBUG
extension GestionChat {
    /// Une gestion toute faite pour les aperçus : faux service, faux annuaire, stock dans un dossier temporaire.
    static func apercu(fermee: Bool = false) -> GestionChat {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("ChatApercu-\(UUID().uuidString)")
        let stock = StockChat(dossier: dossier)
        let lea = FauxAnnuaire.amisParDefaut[0]
        let ami = ConversationID.ami(lea.idCloudKit)
        let club = ConversationID.club(FauxAnnuaire.clubsParDefaut[0].id)
        let messages: [ConversationID: [MessageChat]] = [
            ami: [MessageChat(id: UUID(), conversation: ami, auteurId: lea.id, surnom: lea.surnom,
                              texte: "On pêche samedi matin ?", date: Date().addingTimeInterval(-600))],
            club: [MessageChat(id: UUID(), conversation: club, auteurId: "p-hugo", surnom: "Hugo",
                               texte: "Brochet de 80 cm hier soir.", date: Date().addingTimeInterval(-3600))],
        ]
        let service = FauxServiceChat(messages: messages)
        let gestion = GestionChat(service: service, annuaire: FauxAnnuaire(), stock: stock, permission: FaussePermission())
        Task {
            for (conversation, liste) in messages { await stock.fusionner(liste, dans: conversation) }
            if fermee { await stock.bloquer(ami.id) }
            await gestion.chargerListe()
        }
        return gestion
    }
}

#Preview("Liste") {
    ListeConversationsView(gestion: GestionChat.apercu())
}

#Preview("Conversation d'ami") {
    NavigationStack {
        ConversationView(gestion: GestionChat.apercu(), conversation: .ami(FauxAnnuaire.amisParDefaut[0].idCloudKit))
    }
}

#Preview("Chat de club") {
    NavigationStack {
        ConversationView(gestion: GestionChat.apercu(), conversation: .club(FauxAnnuaire.clubsParDefaut[0].id))
    }
}

#Preview("Conversation fermée") {
    NavigationStack {
        ConversationView(gestion: GestionChat.apercu(fermee: true), conversation: .ami(FauxAnnuaire.amisParDefaut[0].idCloudKit))
    }
}
#endif
