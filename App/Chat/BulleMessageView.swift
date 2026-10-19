import SwiftUI

/// Une bulle de message. À droite et marine : moi. À gauche et claire : l'autre, avec un menu « Signaler / Bloquer » de 44 points.
/// Sous mon message : « Envoyé », « En attente » ou « Pas parti » avec « Renvoyer ». Aucun accusé de lecture : CloudKit ne le sait pas.
struct BulleMessageView: View {
    let message: MessageChat
    let estMoi: Bool
    /// En club on nomme l'auteur ; entre amis, on sait qui parle.
    let afficheAuteur: Bool
    var renvoyer: () -> Void = {}
    var signaler: () -> Void = {}
    var bloquer: () -> Void = {}

    var body: some View {
        VStack(alignment: estMoi ? .trailing : .leading, spacing: Espace.xs) {
            if afficheAuteur && !estMoi {
                Text(message.surnom)
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
            }
            HStack(alignment: .top, spacing: Espace.xs) {
                if estMoi { Spacer(minLength: Espace.xxl) }
                Text(message.texte)
                    .font(Police.corps)
                    .foregroundStyle(estMoi ? Palette.surMarine : Palette.encre)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.s)
                    .background(estMoi ? Palette.marine : Palette.surface,
                                in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                    .fixedSize(horizontal: false, vertical: true)
                if !estMoi {
                    Menu {
                        Button(action: signaler) { Label("Signaler", systemImage: "flag") }
                        Button(role: .destructive, action: bloquer) { Label("Bloquer", systemImage: "nosign") }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Palette.encreDouce)
                            .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Options du message")
                    Spacer(minLength: 0)
                }
            }
            if estMoi { etat }
        }
        .frame(maxWidth: .infinity, alignment: estMoi ? .trailing : .leading)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var etat: some View {
        switch message.etat {
        case .envoye:
            Label("Envoyé", systemImage: "checkmark")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        case .enAttente:
            Label("En attente", systemImage: "clock")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
        case .pasParti:
            HStack(spacing: Espace.s) {
                Label("Pas parti", systemImage: "exclamationmark.circle")
                    .font(Police.legende)
                    .foregroundStyle(Palette.alerte)
                Button("Renvoyer", action: renvoyer)
                    .font(Police.legende)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
    }
}

#if DEBUG
#Preview("Bulles") {
    let conversation = ConversationID.club("club-1")
    let base = MessageChat(id: UUID(), conversation: conversation, auteurId: "p-lea", surnom: "Léa", texte: "Tu étais où ce matin ?",
                           date: Date())
    return VStack(spacing: Espace.m) {
        BulleMessageView(message: base, estMoi: false, afficheAuteur: true)
        BulleMessageView(message: MessageChat(id: UUID(), conversation: conversation, auteurId: "p-moi", surnom: "Moi",
                                              texte: "Au bord de l'eau, rien ne mord.", date: Date()),
                         estMoi: true, afficheAuteur: true)
        BulleMessageView(message: MessageChat(id: UUID(), conversation: conversation, auteurId: "p-moi", surnom: "Moi",
                                              texte: "Je repars demain.", date: Date(), etat: .pasParti),
                         estMoi: true, afficheAuteur: true)
    }
    .padding(Espace.bord)
    .background(Palette.fond)
}
#endif
