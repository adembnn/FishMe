import SwiftUI

/// L'avis court en haut d'un écran de chat. Une croix de 44 points le ferme.
struct BandeauAvisChat: View {
    let avis: GestionChat.Avis
    let fermer: () -> Void

    var body: some View {
        HStack(spacing: Espace.s) {
            Image(systemName: symbole)
                .foregroundStyle(Palette.marine)
            Text(texte)
                .font(Police.detail)
                .foregroundStyle(Palette.encre)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: fermer) {
                Image(systemName: "xmark")
                    .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
            }
            .accessibilityLabel("Fermer")
        }
        .padding(.leading, Espace.m)
        .background(Palette.marineDoux)
    }

    private var symbole: String {
        switch avis {
        case .horsLigne: return "wifi.slash"
        case .iCloudIndisponible, .iCloudPlein: return "icloud.slash"
        case .echec: return "exclamationmark.circle"
        case .notificationsRefusees: return "bell.slash"
        case .pasDeProfil: return "person.crop.circle.badge.plus"
        }
    }

    private var texte: String {
        switch avis {
        case .horsLigne: return "Pas de réseau. Tes messages partiront au retour."
        case .iCloudIndisponible: return "Connecte-toi à iCloud pour écrire."
        case .iCloudPlein: return "Ton iCloud est plein."
        case .echec: return "Ça n'a pas marché. Réessaie."
        case .notificationsRefusees: return "Notifications coupées : tu verras les messages en ouvrant l'app."
        case .pasDeProfil: return "Finis ton profil (15 ans ou plus) pour écrire."
        }
    }
}

/// Une conversation : bulles, champ d'envoi, tirer pour rafraîchir, rafraîchissement toutes les 10 s tant qu'elle est ouverte.
struct ConversationView: View {
    let gestion: GestionChat
    let conversation: ConversationID

    @State private var texte = ""
    @State private var aSignaler: MessageChat?
    @Environment(\.openURL) private var openURL

    private var dialogueOuvert: Binding<Bool> {
        Binding(get: { aSignaler != nil }, set: { if !$0 { aSignaler = nil } })
    }

    var body: some View {
        VStack(spacing: 0) {
            if let avis = gestion.avis {
                BandeauAvisChat(avis: avis) { gestion.effacerAvis() }
            }
            if conversation.type == .club {
                Label("Réservé aux membres du club", systemImage: "lock")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .padding(.vertical, Espace.xs)
            }
            if let lien = gestion.lienAPartager {
                invitation(lien)
            }
            messages
            if gestion.ouverteFermee {
                fermee
            } else {
                saisie
            }
        }
        .background(Palette.fond)
        .navigationTitle(gestion.titreOuverte)
        .navigationBarTitleDisplayMode(.inline)
        .task { await gestion.ouvrir(conversation) }
        .task { await gestion.surveillerOuverte() }
        .onDisappear { gestion.fermer() }
        .confirmationDialog("Pourquoi signaler ce message ?", isPresented: dialogueOuvert, titleVisibility: .visible,
                            presenting: aSignaler) { message in
            ForEach(MotifSignalementMessage.allCases) { motif in
                Button(motif.rawValue) {
                    Task {
                        if let url = await gestion.signaler(message, motif: motif) { openURL(url) }
                    }
                }
            }
        }
    }

    // MARK: Pièces

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if gestion.messagesOuverts.isEmpty && !gestion.ouverteFermee {
                    VStack(spacing: Espace.s) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .foregroundStyle(Palette.silhouette)
                        Text("Écris le premier message.")
                            .font(Police.corps)
                            .foregroundStyle(Palette.encreDouce)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Espace.xxl)
                }
                LazyVStack(spacing: Espace.m) {
                    ForEach(gestion.messagesOuverts) { message in
                        BulleMessageView(
                            message: message,
                            estMoi: message.auteurId == gestion.moi?.id,
                            afficheAuteur: conversation.type == .club,
                            renvoyer: { Task { await gestion.renvoyer() } },
                            signaler: { aSignaler = message },
                            bloquer: { Task { await gestion.bloquer(message) } }
                        )
                        .id(message.id)
                    }
                }
                .padding(.horizontal, Espace.bord)
                .padding(.vertical, Espace.m)
            }
            .scrollIndicators(.hidden)
            .defaultScrollAnchor(.bottom)
            .refreshable { await gestion.actualiser() }
            .onChange(of: gestion.messagesOuverts.last?.id) {
                if let dernier = gestion.messagesOuverts.last?.id {
                    withAnimation { proxy.scrollTo(dernier, anchor: .bottom) }
                }
            }
        }
    }

    private func invitation(_ lien: URL) -> some View {
        VStack(spacing: Espace.xs) {
            ShareLink(item: lien) {
                Label("Envoyer le lien de la conversation", systemImage: "link")
            }
            .buttonStyle(.secondaire)
            Text("Il ne s'ouvre que pour les personnes invitées.")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.vertical, Espace.s)
    }

    private var fermee: some View {
        VStack(spacing: Espace.s) {
            Label("Conversation fermée", systemImage: "nosign")
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
            Button("Débloquer") { Task { await gestion.debloquer(conversation) } }
                .buttonStyle(.secondaire)
        }
        .padding(Espace.bord)
        .frame(maxWidth: .infinity)
        .background(Palette.surface)
    }

    private var saisie: some View {
        VStack(alignment: .leading, spacing: Espace.xs) {
            if let refus = gestion.verdictSaisie, let phrase = phrase(refus) {
                Text(phrase)
                    .font(Police.legende)
                    .foregroundStyle(Palette.alerte)
            }
            HStack(alignment: .bottom, spacing: Espace.s) {
                TextField("Message", text: $texte, axis: .vertical)
                    .font(Police.corps)
                    .lineLimit(1...4)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.s)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .background(Palette.tuile, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                Button {
                    Task { if await gestion.envoyer(texte) { texte = "" } }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.largeTitle)
                        .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                }
                .disabled(texte.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Envoyer")
            }
            if texte.count > FiltreMessage.longueurMax - 50 {
                Text("\(texte.count) / \(FiltreMessage.longueurMax)")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.vertical, Espace.s)
        .background(Palette.surface)
    }

    private func phrase(_ verdict: FiltreMessage.Verdict) -> String? {
        switch verdict {
        case .motInterdit: return "Ce mot n'est pas accepté."
        case .position: return "Pas de coordonnées ni de lien de carte."
        case .tropLong: return "\(FiltreMessage.longueurMax) caractères au plus."
        case .vide, .accepte: return nil
        }
    }
}
