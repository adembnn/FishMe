import Foundation

/// Tout ce que le chat demande à iCloud, derrière un protocole : le vrai service (`ServiceChatCloudKit`) et le faux des tests.
nonisolated protocol ServiceChat: Sendable {
    /// `false` : pas connecté à iCloud, ou iCloud restreint. Le chat se lit encore (cache), il n'envoie plus.
    func iCloudDisponible() async -> Bool
    /// Les messages de la conversation, tels qu'iCloud les a. Lève `.reseau` hors ligne.
    func messages(de conversation: ConversationID) async throws -> [MessageChat]
    /// Les messages nouveaux ou modifiés depuis la dernière lecture (jeton de changement CloudKit, gardé en mémoire par le service).
    /// Sert au rafraîchissement périodique : pas de relecture complète de la zone toutes les 10 s. Sans jeton : tout, comme `messages`.
    func changements(de conversation: ConversationID) async throws -> [MessageChat]
    /// Écrit un message (idempotent : même `id`, même enregistrement). Lève `.reseau` hors ligne : l'appelant garde le message à rejouer.
    /// `peutCreerLaZone` : ami, seulement celui dont l'identifiant de profil (`p-…`) est le plus petit dans l'ordre alphabétique
    /// (un seul créateur par paire, l'autre attend l'invitation) ; club, le fondateur seulement.
    func envoyer(_ message: MessageChat, peutCreerLaZone: Bool) async throws
    /// Crée, si besoin, l'abonnement qui couvre cette conversation : abonnement de zone (base privée) si la zone est à moi,
    /// abonnement de base (`CKDatabaseSubscription`, base partagée) si elle m'est partagée. Lève `.introuvable` tant que la zone n'existe pas
    /// chez moi (l'appelant réessaie plus tard). N'est appelé qu'après la permission.
    func abonner(_ conversation: ConversationID) async throws
    /// Le lien de la conversation à envoyer tant qu'un participant ne l'a pas accepté. `participants` : identifiants CloudKit des
    /// personnes à admettre (l'ami ; pour un club, ses membres, et seul le fondateur peut les ajouter).
    /// `nil` : rien à envoyer (tous ont accepté, ou la zone n'est pas à moi). `peutCreerLaZone` : le créateur de la paire (ou le
    /// fondateur du club) crée la zone et son partage dès l'ouverture, sans attendre un premier message.
    func lienDInvitation(pour conversation: ConversationID, participants: [String], peutCreerLaZone: Bool) async throws -> URL?
    /// Un ami m'a envoyé le lien de sa conversation : je l'accepte (une fois).
    func accepterInvitation(_ invitation: InvitationChat) async throws
    /// Écrit le `Signalement` en base publique (lu par la personne de garde). Le texte du message signalé y est copié (500 caractères
    /// au plus, champ `texte`) : sans cela l'équipe ne peut pas le lire, les conversations étant en zone partagée. À dire dans la
    /// politique de confidentialité.
    func enregistrerSignalement(_ signalement: SignalementMessageEnAttente) async throws
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
    /// Une alerte locale « Nouveau message » (sans texte ni nom), après filtrage des blocages, quand une notification silencieuse
    /// a ramené un message alors que l'app n'est pas au premier plan. Sans effet si la permission n'est pas accordée.
    func publierLocale(_ texte: String) async
}
