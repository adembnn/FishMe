#if DEBUG
import Foundation

/// Faux service de chat pour les tests et les aperçus : tout en mémoire, un interrupteur « hors ligne », aucun appel à iCloud.
actor FauxServiceChat: ServiceChat {
    private(set) var parConversation: [ConversationID: [MessageChat]]
    private(set) var tentatives = 0
    private(set) var lecturesLegeres = 0
    /// Les conversations dont on m'a demandé de créer la zone et le lien (`peutCreerLaZone` vrai).
    private(set) var creations: [ConversationID] = []
    private(set) var abonnes: [ConversationID] = []
    /// Les comptes demandés à l'invitation de chaque conversation (le dernier appel).
    private(set) var participantsDemandes: [ConversationID: [String]] = [:]
    private(set) var acceptees = 0
    private(set) var effaces: [String] = []
    private(set) var signalements: [SignalementMessageEnAttente] = []
    private var horsLigne: Bool
    private var compte: Bool
    private var lien: URL?
    /// Conversations dont la zone existe déjà (un membre non fondateur ne peut écrire que dans une zone déjà là).
    var zonesConnues: Set<ConversationID> = []

    init(horsLigne: Bool = false, compte: Bool = true, lien: URL? = nil, messages: [ConversationID: [MessageChat]] = [:]) {
        self.horsLigne = horsLigne
        self.compte = compte
        self.lien = lien
        self.parConversation = messages
    }

    func regler(horsLigne: Bool) { self.horsLigne = horsLigne }
    func regler(lien: URL?) { self.lien = lien }

    /// Un message qui arrive de l'autre iPhone.
    func recevoir(_ message: MessageChat) {
        parConversation[message.conversation, default: []].append(message)
    }

    func iCloudDisponible() async -> Bool { compte }

    func messages(de conversation: ConversationID) async throws -> [MessageChat] {
        if horsLigne { throw ErreurChat.reseau }
        return (parConversation[conversation] ?? []).sorted { $0.date < $1.date }
    }

    /// Le faux service rend tout à chaque fois (pas de jeton) ; `lectures` compte les appels pour les tests du rafraîchissement.
    func changements(de conversation: ConversationID) async throws -> [MessageChat] {
        lecturesLegeres += 1
        return try await messages(de: conversation)
    }

    func envoyer(_ message: MessageChat, peutCreerLaZone: Bool) async throws {
        tentatives += 1
        if horsLigne { throw ErreurChat.reseau }
        if !peutCreerLaZone && !zonesConnues.contains(message.conversation) { throw ErreurChat.introuvable }
        var parti = message
        parti.etat = .envoye
        var liste = parConversation[message.conversation] ?? []
        liste.removeAll { $0.id == message.id }
        liste.append(parti)
        parConversation[message.conversation] = liste
    }

    func abonner(_ conversation: ConversationID) async throws {
        if horsLigne { throw ErreurChat.reseau }
        if !abonnes.contains(conversation) { abonnes.append(conversation) }
    }

    func lienDInvitation(pour conversation: ConversationID, participants: [String], peutCreerLaZone: Bool) async throws -> URL? {
        if horsLigne { throw ErreurChat.reseau }
        participantsDemandes[conversation] = participants
        if peutCreerLaZone {
            if !creations.contains(conversation) { creations.append(conversation) }
            zonesConnues.insert(conversation)
        }
        return lien
    }

    func accepterInvitation(_ invitation: InvitationChat) async throws {
        acceptees += 1
    }

    func enregistrerSignalement(_ signalement: SignalementMessageEnAttente) async throws {
        if horsLigne { throw ErreurChat.reseau }
        signalements.append(signalement)
    }

    func effacerMesMessages(auteurId: String) async throws {
        if horsLigne { throw ErreurChat.reseau }
        effaces.append(auteurId)
        for (cle, liste) in parConversation {
            parConversation[cle] = liste.filter { $0.auteurId != auteurId }
        }
    }
}

/// Fausse permission : compte les fenêtres ouvertes, pour prouver qu'elle n'apparaît qu'au premier message envoyé.
actor FaussePermission: PermissionNotifications {
    private(set) var demandes = 0
    private(set) var alertesLocales = 0
    private(set) var statutActuel: StatutNotifications
    private let reponse: Bool

    init(statut: StatutNotifications = .nonDemande, accepte: Bool = true) {
        self.statutActuel = statut
        self.reponse = accepte
    }

    func statut() async -> StatutNotifications { statutActuel }

    func demander() async -> Bool {
        demandes += 1
        statutActuel = reponse ? .accorde : .refuse
        return reponse
    }

    func publierLocale(_ texte: String) async {
        alertesLocales += 1
    }
}

/// Faux annuaire : deux amis, un club, moi avec un surnom fictif.
actor FauxAnnuaire: AnnuaireChat {
    var profil: InterlocuteurChat?
    var mesAmis: [InterlocuteurChat]
    var mesClubs: [ClubChat]
    var mesBloques: Set<String>

    init(profil: InterlocuteurChat? = FauxAnnuaire.moiParDefaut, amis: [InterlocuteurChat] = FauxAnnuaire.amisParDefaut,
         clubs: [ClubChat] = FauxAnnuaire.clubsParDefaut, bloques: Set<String> = []) {
        self.profil = profil
        self.mesAmis = amis
        self.mesClubs = clubs
        self.mesBloques = bloques
    }

    static let moiParDefaut = InterlocuteurChat(id: "p-alice", surnom: "Alice", idCloudKit: "_alice")
    static let amisParDefaut = [
        InterlocuteurChat(id: "p-lea", surnom: "Léa", idCloudKit: "_lea"),
        InterlocuteurChat(id: "p-hugo", surnom: "Hugo", idCloudKit: "_hugo"),
    ]
    static let clubsParDefaut = [ClubChat(id: "club-1", nom: "Les brochets du 94", jeSuisFondateur: true, membres: amisParDefaut)]

    func moi() async -> InterlocuteurChat? { profil }
    func amis() async -> [InterlocuteurChat] { mesAmis }
    func clubs() async -> [ClubChat] { mesClubs }
    func bloques() async -> Set<String> { mesBloques }

    /// Combien de fois la liste a demandé à l'annuaire de retenter de trouver les comptes manquants.
    private(set) var actualisationsClubs = 0
    func actualiserClubs() async { actualisationsClubs += 1 }
    /// Les clubs changent (un profil manquant vient d'être lu).
    func definir(clubs: [ClubChat]) { mesClubs = clubs }
}
#endif
