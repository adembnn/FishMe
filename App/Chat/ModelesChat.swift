import Foundation

// Types du chat (lot L24). Ce dossier n'importe que Foundation, SwiftUI et lui-même.
// Tout est `nonisolated` : le projet est en MainActor par défaut, et ces types voyagent entre acteurs.

nonisolated enum TypeConversation: String, Codable, Sendable {
    case ami
    case club
}

/// Une conversation. Pour un ami, `cible` est l'identifiant CloudKit de l'ami (le même que `Ami.id` du lot Amis) ;
/// pour un club, l'identifiant du club.
nonisolated struct ConversationID: Hashable, Codable, Sendable, Identifiable {
    var type: TypeConversation
    var cible: String

    var id: String { "\(type.rawValue):\(cible)" }

    static func ami(_ identifiantCloudKit: String) -> ConversationID { ConversationID(type: .ami, cible: identifiantCloudKit) }
    static func club(_ identifiant: String) -> ConversationID { ConversationID(type: .club, cible: identifiant) }
}

/// Où en est un message que j'ai écrit. Jamais « lu » : CloudKit ne sait pas si l'autre a lu.
nonisolated enum EtatMessage: String, Codable, Sendable {
    /// Arrivé sur iCloud.
    case envoye
    /// Écrit, pas encore parti (file d'envoi, tentative en cours ou à venir).
    case enAttente
    /// Une tentative a échoué (hors ligne, iCloud indisponible) : il repartira au retour du réseau, ou au toucher de « Renvoyer ».
    case pasParti
}

nonisolated struct MessageChat: Codable, Hashable, Identifiable, Sendable {
    /// Aussi le `recordName` CloudKit : renvoyer deux fois le même message l'écrase au lieu de le doubler.
    var id: UUID
    var conversation: ConversationID
    /// Identifiant de l'auteur (celui de `InterlocuteurChat.id`). Sert à bloquer et à signaler.
    var auteurId: String
    /// Surnom affiché au moment de l'écriture.
    var surnom: String
    var texte: String
    var date: Date
    var etat: EtatMessage = .envoye
    /// Qui a RÉELLEMENT écrit l'enregistrement, selon iCloud (`creatorUserRecordID`), jamais selon un champ que le client remplit.
    /// `createurMoi` : c'est moi. `nil` : message écrit ici, pas encore relu depuis iCloud, ou message du faux service.
    /// `GestionChat` en déduit `auteurId` et `surnom` depuis l'annuaire (profil de l'expéditeur) : le nom reçu n'est pas cru.
    var createurCloudKit: String? = nil

    /// Marque posée par le service quand le créateur de l'enregistrement est le compte de cet iPhone.
    static let createurMoi = "__moi__"
}

/// Une ligne de la liste des conversations.
nonisolated struct ResumeConversation: Identifiable, Hashable, Sendable {
    var conversation: ConversationID
    var titre: String
    var dernier: MessageChat?
    var nonLu: Bool
    var ferme: Bool = false

    var id: String { conversation.id }
}

/// Un signalement à écrire dans la base lue par la personne de garde (type `Signalement` de R2 `schema.md`).
/// Gardé sur disque tant qu'il n'est pas parti : un signalement fait hors ligne n'est pas perdu.
nonisolated struct SignalementEnAttente: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    /// `recordName` du message signalé.
    var cible: UUID
    var motif: String
    var signalePar: String
    var date: Date
    /// Texte du message signalé, copié dans l'enregistrement pour que l'équipe puisse le lire (décision de Titouan, 19 oct. :
    /// chat d'ami et de club en zone partagée, l'équipe n'y a pas accès autrement). 500 caractères au plus. Optionnel : les
    /// fichiers écrits avant cette version n'ont pas ce champ.
    var texte: String? = nil
}

nonisolated enum ErreurChat: Error, Equatable, Sendable {
    case iCloudIndisponible
    /// Pas de réseau, ou service occupé : le message reste dans la file.
    case reseau
    case iCloudPlein
    /// Le service ne trouve pas la conversation (l'ami n'a pas encore ouvert la sienne, club inconnu).
    case introuvable
    case autre
}
