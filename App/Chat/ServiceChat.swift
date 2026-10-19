import Foundation

/// Tout ce que le chat demande à iCloud, derrière un protocole : le vrai service (`ServiceChatCloudKit`) et le faux des tests.
nonisolated protocol ServiceChat: Sendable {
    /// `false` : pas connecté à iCloud, ou iCloud restreint. Le chat se lit encore (cache), il n'envoie plus.
    func iCloudDisponible() async -> Bool
    /// Les messages de la conversation, tels qu'iCloud les a. Lève `.reseau` hors ligne.
    func messages(de conversation: ConversationID) async throws -> [MessageChat]
    /// Écrit un message (idempotent : même `id`, même enregistrement). Lève `.reseau` hors ligne : l'appelant garde le message à rejouer.
    /// `peutCreerLaZone` : ami, toujours ; club, le fondateur seulement (lui seul possède la zone partagée du club).
    func envoyer(_ message: MessageChat, peutCreerLaZone: Bool) async throws
    /// Crée, si besoin, l'abonnement de cette conversation (notification quand un message arrive). N'est appelé qu'après la permission.
    func abonner(_ conversation: ConversationID) async throws
    /// Le lien de la conversation à envoyer tant qu'un participant ne l'a pas accepté. `participants` : identifiants CloudKit des
    /// personnes à admettre (l'ami ; pour un club, ses membres, et seul le fondateur peut les ajouter).
    /// `nil` : rien à envoyer (tous ont accepté, ou la zone n'est pas à moi).
    func lienDInvitation(pour conversation: ConversationID, participants: [String]) async throws -> URL?
    /// Un ami m'a envoyé le lien de sa conversation : je l'accepte (une fois).
    func accepterInvitation(_ invitation: InvitationChat) async throws
    /// Efface tous mes messages (clubs et amis) : « Supprimer mon profil ».
    func effacerMesMessages(auteurId: String) async throws
}

/// Ce que la fenêtre de permission de notification a décidé.
nonisolated enum StatutNotifications: Sendable, Equatable {
    case nonDemande
    case accorde
    case refuse
}

/// La permission de notifier. Demandée au PREMIER message envoyé, jamais au lancement ni à l'ouverture de l'onglet.
nonisolated protocol PermissionNotifications: Sendable {
    func statut() async -> StatutNotifications
    /// Ouvre la fenêtre d'iOS. Rend `true` si accordée.
    func demander() async -> Bool
}
