import CloudKit
import Foundation

/// La seule porte par où un message devient un `CKRecord` : une liste blanche de champs, que les tests comparent.
/// Aucune latitude, longitude, altitude, ni nom de plan d'eau n'y entre (règle d'or, R2 `schema.md`).
/// Noms de champs de R2 `schema.md` ; ajout de L24 : `surnom` (affichage sans relire le profil).
nonisolated enum FabriqueRecordsChat {
    static let typeClub = "MessageClub"
    static let typeAmi = "MessageAmi"

    /// Dans R2 le champ `auteurNom` porte l'identifiant du profil de l'auteur (pas son nom).
    static let champsClub: Set<String> = ["club", "auteurNom", "surnom", "texte", "creeLe"]
    static let champsAmi: Set<String> = ["auteurNom", "surnom", "texte", "creeLe"]

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

    /// Relit un enregistrement. `nil` si un champ manque (enregistrement abîmé : on l'ignore plutôt que d'afficher du vide).
    static func message(depuis record: CKRecord, conversation: ConversationID) -> MessageChat? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let auteur = record["auteurNom"] as? String,
              let texte = record["texte"] as? String,
              let date = record["creeLe"] as? Date else { return nil }
        let surnom = (record["surnom"] as? String) ?? "Un pêcheur"
        return MessageChat(id: id, conversation: conversation, auteurId: auteur, surnom: surnom,
                           texte: String(texte.prefix(FiltreMessage.longueurMax)), date: date, etat: .envoye)
    }
}
