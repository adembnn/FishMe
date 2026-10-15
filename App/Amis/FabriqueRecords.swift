import CloudKit
import Core
import Foundation

/// Fabrique des `CKRecord` d'une carte partagée, et les relit. Seules les clés de `cles` existent : un test le prouve.
nonisolated enum FabriqueRecords {
    static let typeCarte = "Carte"
    static let cles: Set<String> = ["cardID", "espece", "rarete", "datePrise", "taille", "bredouille", "zone", "image"]

    /// `dossierTemp` reçoit le fichier PNG de la pièce jointe (`CKAsset`).
    static func record(pour carte: CartePartagee, zone: CKRecordZone.ID, dossierTemp: URL) throws -> CKRecord {
        let record = CKRecord(recordType: typeCarte, recordID: CKRecord.ID(recordName: carte.id.uuidString, zoneID: zone))
        record["cardID"] = carte.id.uuidString
        record["espece"] = carte.espece
        record["rarete"] = carte.rarete.rawValue
        record["datePrise"] = carte.date
        if let taille = carte.tailleCm { record["taille"] = taille }
        record["bredouille"] = carte.bredouille ? 1 : 0
        if let departement = carte.departement { record["zone"] = departement }
        if let image = carte.image {
            guard let propre = PngSansGPS.nettoyer(image) else { throw ErreurAmis.imageRefusee }
            try FileManager.default.createDirectory(at: dossierTemp, withIntermediateDirectories: true)
            let fichier = dossierTemp.appendingPathComponent("\(carte.id.uuidString).png")
            try propre.write(to: fichier, options: .atomic)
            record["image"] = CKAsset(fileURL: fichier)
        }
        return record
    }

    static func carte(depuis record: CKRecord) -> CartePartagee? {
        guard record.recordType == typeCarte,
              let id = (record["cardID"] as? String).flatMap(UUID.init(uuidString:)),
              let espece = record["espece"] as? String,
              let rareteBrute = record["rarete"] as? String,
              let rarete = NiveauRarete(rawValue: rareteBrute),
              let date = record["datePrise"] as? Date else { return nil }
        let image = (record["image"] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf: $0) }
        return CartePartagee(id: id, espece: espece, rarete: rarete, date: date, tailleCm: record["taille"] as? Double,
                             bredouille: (record["bredouille"] as? Int ?? 0) == 1, departement: record["zone"] as? String,
                             image: image)
    }
}
