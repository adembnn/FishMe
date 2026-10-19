#if DEBUG
import Foundation

/// Faux service de chat pour les tests et les aperçus : tout en mémoire, un interrupteur « hors ligne », aucun appel à iCloud.
actor FauxServiceChat: ServiceChat {
    private(set) var parConversation: [ConversationID: [MessageChat]]
    private(set) var tentatives = 0
    private(set) var abonnes: [ConversationID] = []
    private(set) var acceptees = 0
    private(set) var effaces: [String] = []
    private(set) var signalements: [SignalementEnAttente] = []
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

    func lienDInvitation(pour conversation: ConversationID, participants: [String]) async throws -> URL? {
        if horsLigne { throw ErreurChat.reseau }
        return lien
    }

    func accepterInvitation(_ invitation: InvitationChat) async throws {
        acceptees += 1
    }

    func enregistrerSignalement(_ signalement: SignalementEnAttente) async throws {
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

    static let moiParDefaut = InterlocuteurChat(id: "p-moi", surnom: "Moi", idCloudKit: "_moi")
    static let amisParDefaut = [
        InterlocuteurChat(id: "p-lea", surnom: "Léa", idCloudKit: "_lea"),
        InterlocuteurChat(id: "p-hugo", surnom: "Hugo", idCloudKit: "_hugo"),
    ]
    static let clubsParDefaut = [ClubChat(id: "club-1", nom: "Les brochets du 94", jeSuisFondateur: true, membres: amisParDefaut)]

    func moi() async -> InterlocuteurChat? { profil }
    func amis() async -> [InterlocuteurChat] { mesAmis }
    func clubs() async -> [ClubChat] { mesClubs }
    func bloques() async -> Set<String> { mesBloques }
}
#endif
