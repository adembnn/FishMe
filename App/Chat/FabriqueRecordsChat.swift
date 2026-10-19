import CloudKit
import Foundation

/// La seule porte par où un message devient un `CKRecord` : une liste blanche de champs, que les tests comparent.
/// Aucune latitude, longitude, altitude, ni nom de plan d'eau n'y entre (règle d'or, R2 `schema.md`).
/// Noms de champs de R2 `schema.md` ; ajout de L24 : `surnom` (affichage sans relire le profil).
nonisolated enum FabriqueRecordsChat {
    static let typeClub = "MessageClub"
    static let typeAmi = "MessageAmi"

    /// Dans R2 le champ `auteurNom` porte l'identifiant du profil de l'auteur (pas son nom). ATTENTION : ce champ est écrit par le
    /// client, donc falsifiable. Il n'est JAMAIS lu pour savoir qui a écrit : on se fie à `creatorUserRecordID` (voir `message`).
    static let champsClub: Set<String> = ["club", "auteurNom", "surnom", "texte", "creeLe"]
    static let champsAmi: Set<String> = ["auteurNom", "surnom", "texte", "creeLe"]

    static let typeSignalement = "Signalement"
    static let champsSignalement: Set<String> = ["cible", "typeCible", "motif", "signalePar", "creeLe", "texte"]

    /// Taille maximale du texte copié dans un signalement.
    static let texteSignalementMax = 500

    /// Signalement d'un message (R2 `schema.md`, type 8) : un identifiant, un motif de la liste fermée (mêmes valeurs que le
    /// `MotifSignalement` de L21), et le TEXTE du message signalé (champ `texte`, 500 caractères au plus, à ajouter au schéma) :
    /// décision de Titouan du 19 oct., pour que l'équipe puisse lire le message. Jamais de coordonnée : le filtre de saisie les a refusées.
    static func recordSignalement(_ s: SignalementMessageEnAttente) -> CKRecord {
        let record = CKRecord(recordType: typeSignalement, recordID: CKRecord.ID(recordName: s.id.uuidString))
        record["cible"] = s.cible.uuidString
        record["typeCible"] = "message"
        record["motif"] = s.motif
        record["signalePar"] = s.signalePar
        record["creeLe"] = s.date
        if let texte = s.texte, !texte.isEmpty { record["texte"] = String(texte.prefix(texteSignalementMax)) }
        return record
    }

    /// Message de club, dans la zone partagée du club (jamais la base publique : décision de Titouan, réservé aux membres).
    static func recordClub(_ message: MessageChat, zone: CKRecordZone.ID) -> CKRecord {
        let record = CKRecord(recordType: typeClub, recordID: CKRecord.ID(recordName: message.id.uuidString, zoneID: zone))
        record["club"] = message.conversation.cible
        remplir(record, message)
        return record
    }

    /// Message d'ami, dans la zone partagée de la conversation.
    static func recordAmi(_ message: MessageChat, zone: CKRecordZone.ID) -> CKRecord {
        let record = CKRecord(recordType: typeAmi, recordID: CKRecord.ID(recordName: message.id.uuidString, zoneID: zone))
        remplir(record, message)
        return record
    }

    private static func remplir(_ record: CKRecord, _ message: MessageChat) {
        record["auteurNom"] = message.auteurId
        record["surnom"] = message.surnom
        record["texte"] = message.texte
        record["creeLe"] = message.date
    }

    /// Vrai si le créateur CloudKit d'un enregistrement est ce compte : iCloud rend `__defaultOwner__` pour le compte courant dans sa
    /// propre base, et son vrai identifiant ailleurs ; on accepte les deux (⚠ comportement à vérifier sur appareil).
    static func createurEstMoi(_ createur: String?, monIdentifiant: String?) -> Bool {
        guard let createur else { return false }
        return createur == CKCurrentUserDefaultName || createur == monIdentifiant
    }

    /// Relit un enregistrement. `nil` si un champ manque (enregistrement abîmé : on l'ignore plutôt que d'afficher du vide).
    /// L'auteur vient de `creatorUserRecordID` (posé par iCloud, non falsifiable), jamais du champ `auteurNom` ni de `surnom` :
    /// `GestionChat` en déduit le profil de l'expéditeur depuis l'annuaire. Un membre ne peut donc pas écrire « en tant que » un autre.
    static func message(depuis record: CKRecord, conversation: ConversationID, monIdentifiant: String? = nil) -> MessageChat? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let texte = record["texte"] as? String,
              let date = record["creeLe"] as? Date else { return nil }
        let createur: String
        if let brut = record.creatorUserRecordID?.recordName {
            createur = createurEstMoi(brut, monIdentifiant: monIdentifiant) ? MessageChat.createurMoi : brut
        } else {
            createur = "inconnu"
        }
        return MessageChat(id: id, conversation: conversation, auteurId: "ck:\(createur)", surnom: "Un pêcheur",
                           texte: String(texte.prefix(FiltreMessage.longueurMax)), date: date, etat: .envoye,
                           createurCloudKit: createur)
    }
}
