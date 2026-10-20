import Foundation

// Mode démo du chat, présent AUSSI dans le build envoyé à Apple (décision de Titouan, 19 oct. ; règle 2.1 : un relecteur seul,
// sans deuxième compte iCloud, doit voir toutes les fonctions). Rien ici n'appelle iCloud, rien ne part : conversations
// d'exemple marquées « Exemple », en lecture seule. Signaler et bloquer marchent en local pour que le relecteur les voie.
//
// A utilise `GestionChat.exemple()` à la place du vrai service quand le mode démo est actif (`demo.communaute`) ou qu'il n'y a pas
// de compte iCloud (voir le rapport L24). Le vrai service et les faux de test restent séparés (`FauxChat.swift`, sous DEBUG).

nonisolated enum DonneesExempleChat {
    static let moi = InterlocuteurChat(id: "p-exemple-moi", surnom: "Toi", idCloudKit: "_exemple_moi")
    static let lea = InterlocuteurChat(id: "p-exemple-lea", surnom: "Léa", idCloudKit: "_exemple_lea")
    static let hugo = InterlocuteurChat(id: "p-exemple-hugo", surnom: "Hugo", idCloudKit: "_exemple_hugo")
    static let club = ClubChat(id: "exemple-club", nom: "Les brochets", jeSuisFondateur: false, membres: [lea, hugo])

    static let conversationAmi = ConversationID.ami(lea.idCloudKit)
    static let conversationClub = ConversationID.club(club.id)

    /// Identifiants fixes : relire plusieurs fois ne double pas les messages dans le cache.
    private static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n)) ?? UUID()
    }

    static func messages(de conversation: ConversationID, maintenant: Date = Date()) -> [MessageChat] {
        func m(_ n: Int, _ auteur: InterlocuteurChat, _ texte: String, minutes: Double) -> MessageChat {
            MessageChat(id: id(n), conversation: conversation, auteurId: auteur.id, surnom: auteur.surnom, texte: texte,
                        date: maintenant.addingTimeInterval(-minutes * 60))
        }
        switch conversation {
        case conversationAmi:
            return [
                m(1, lea, "Exemple de message : ça mordait ce matin ?", minutes: 50),
                m(2, moi, "Exemple de réponse : un peu, au lever du jour.", minutes: 40),
            ]
        case conversationClub:
            return [
                m(11, hugo, "Exemple de message de club : sortie dimanche ?", minutes: 120),
                m(12, lea, "Exemple : je viens, j'apporte le café.", minutes: 90),
            ]
        default:
            return []
        }
    }
}

/// Le service du mode démo : tout en lecture, rien n'est écrit nulle part.
actor ServiceChatExemple: ServiceChat {
    func iCloudDisponible() async -> Bool { true }
    func messages(de conversation: ConversationID) async throws -> [MessageChat] { DonneesExempleChat.messages(de: conversation) }
    func changements(de conversation: ConversationID) async throws -> [MessageChat] { DonneesExempleChat.messages(de: conversation) }
    func envoyer(_ message: MessageChat, peutCreerLaZone: Bool) async throws { throw ErreurChat.autre }
    func abonner(_ conversation: ConversationID) async throws {}
    func lienDInvitation(pour conversation: ConversationID, participants: [String], peutCreerLaZone: Bool) async throws -> URL? { nil }
    func accepterInvitation(_ invitation: InvitationChat) async throws {}
    func enregistrerSignalement(_ signalement: SignalementMessageEnAttente) async throws {}
    func effacerMesMessages(auteurId: String) async throws {}
}

nonisolated struct AnnuaireExemple: AnnuaireChat {
    func moi() async -> InterlocuteurChat? { DonneesExempleChat.moi }
    func amis() async -> [InterlocuteurChat] { [DonneesExempleChat.lea] }
    func clubs() async -> [ClubChat] { [DonneesExempleChat.club] }
    func bloques() async -> Set<String> { [] }
}

/// Aucune permission demandée en mode démo.
nonisolated struct PermissionAucune: PermissionNotifications {
    func statut() async -> StatutNotifications { .refuse }
    func demander() async -> Bool { false }
    func publierLocale(_ texte: String) async {}
}

extension GestionChat {
    /// Un chat de démonstration : « Exemple » dans les titres, lecture seule. Son cache vit dans un dossier temporaire à part.
    static func exemple() -> GestionChat {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("ChatExemple", isDirectory: true)
        return GestionChat(service: ServiceChatExemple(), annuaire: AnnuaireExemple(), stock: StockChat(dossier: dossier),
                           permission: PermissionAucune(), exemple: true)
    }
}
