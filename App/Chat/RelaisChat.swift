import CloudKit
import Observation

/// Garde le lien de conversation reçu (ami ou club) jusqu'à ce que `RootView` l'accepte avec `GestionChat.accepter`.
/// `SceneDuPartage` y route les partages dont `InvitationChat.estUneConversation` est vrai : ils ne passent PAS par
/// `RelaisInvitations` (qui est l'invitation d'ami du lot Amis). // ⚠ à vérifier (écrit sans Mac)
@MainActor
@Observable
final class RelaisChat {
    static let partage = RelaisChat()

    private(set) var enAttente: InvitationChat?

    func recevoir(_ metadata: CKShare.Metadata) {
        enAttente = InvitationChat(metadata: metadata)
    }

    func solder() {
        enAttente = nil
    }
}
