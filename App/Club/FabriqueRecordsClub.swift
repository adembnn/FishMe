import CloudKit
import Core
import Foundation

/// Fabrique les `CKRecord` des clubs (`Club`, `Membre`, carte partagée = `Publication`, `Signalement`) et les relit.
/// Seules les clés listées existent : un test le prouve. Aucune clé de lieu exact (latitude, longitude, altitude, plan d'eau) :
/// `schema.md`, « Règles qui valent pour tous les types ». Les noms de champs suivent R2 à la lettre.
nonisolated enum FabriqueRecordsClub {
    static let typeClub = "Club"
    static let typeMembre = "Membre"
    static let typePublication = "Publication"
    static let typeSignalement = "Signalement"

    static let clesClub: Set<String> = ["nom", "poissonId", "image", "fondateur", "retires", "ferme", "creeLe"]
    static let clesMembre: Set<String> = ["club", "profil", "role", "depuis"]
    /// Les clés de `Publication` qu'une carte de club remplit (un sous-ensemble de `FabriqueFeed.clesPublication`, L23).
    static let clesCarte: Set<String> = [
        "auteur", "auteurNom", "media", "genre", "dureeS", "legende", "lieuMode", "lieuTexte", "departement",
        "espece", "rarete", "tailleCm", "club", "creeLe",
    ]
    static let clesSignalement: Set<String> = ["cible", "typeCible", "motif", "signalePar", "creeLe"]

    /// Préfixe du `recordName` d'une carte de club : le reconnaît parmi les `Publication` du fil de L23.
    static func prefixeCarte(club: String) -> String { "pc-\(club)-" }

    // MARK: Écriture

    static func recordClub(_ club: Club, dossierTemp: URL) throws -> CKRecord {
        let record = CKRecord(recordType: typeClub, recordID: CKRecord.ID(recordName: club.id))
        remplir(record, avec: club)
        if let image = club.image { record["image"] = try asset(image, nom: "club-\(club.id)", extension: "jpg", dossierTemp: dossierTemp) }
        return record
    }

    /// Les champs simples d'un club (sans l'image), pour mettre à jour un enregistrement lu.
    static func remplir(_ record: CKRecord, avec club: Club) {
        record["nom"] = club.nom
        if let poisson = club.poissonId { record["poissonId"] = poisson }
        record["fondateur"] = club.fondateur
        record["retires"] = club.retires
        record["ferme"] = club.ferme ? 1 : 0
        record["creeLe"] = club.creeLe
    }

    static func recordMembre(_ membre: Membre) -> CKRecord {
        let record = CKRecord(recordType: typeMembre, recordID: CKRecord.ID(recordName: membre.id))
        record["club"] = membre.club
        record["profil"] = membre.profil
        record["role"] = membre.role.rawValue
        record["depuis"] = membre.depuis
        return record
    }

    /// L'image de la carte est le PNG de la collection, réécrit sans métadonnées. Sans département : `lieuMode` = `aucun` et
    /// `departement` reste vide (R2, point d'attention de `Publication`).
    static func recordCarte(_ carte: CartePartageeClub, dossierTemp: URL) throws -> CKRecord {
        let record = CKRecord(recordType: typePublication, recordID: CKRecord.ID(recordName: carte.id))
        record["auteur"] = CKRecord.Reference(recordID: CKRecord.ID(recordName: carte.auteur), action: .none)
        record["auteurNom"] = carte.auteur
        if let image = carte.image {
            let propre = try ImageSansGPS.nettoyer(image)
            record["media"] = try asset(propre, nom: "carte-\(carte.carteID)", extension: "png", dossierTemp: dossierTemp)
        }
        record["genre"] = "photo"
        record["dureeS"] = 0
        record["legende"] = ""
        record["lieuMode"] = carte.departement.isEmpty ? "aucun" : "departement"
        record["lieuTexte"] = ""
        record["departement"] = carte.departement
        record["espece"] = carte.espece
        if let rarete = carte.rarete { record["rarete"] = rarete.rawValue }
        if let taille = carte.tailleCm { record["tailleCm"] = taille }
        record["club"] = carte.club
        record["creeLe"] = carte.creeLe
        return record
    }

    static func recordSignalement(cible: String, typeCible: String, motif: MotifSignalement, par monID: String?, le date: Date) -> CKRecord {
        let record = CKRecord(recordType: typeSignalement, recordID: CKRecord.ID(recordName: UUID().uuidString))
        record["cible"] = cible
        record["typeCible"] = typeCible
        record["motif"] = motif.rawValue
        record["signalePar"] = monID ?? ""
        record["creeLe"] = date
        return record
    }

    static func asset(_ donnees: Data, nom: String, extension ext: String, dossierTemp: URL) throws -> CKAsset {
        try FileManager.default.createDirectory(at: dossierTemp, withIntermediateDirectories: true)
        let fichier = dossierTemp.appendingPathComponent("\(nom)-\(UUID().uuidString).\(ext)")
        try donnees.write(to: fichier, options: .atomic)
        return CKAsset(fileURL: fichier)
    }

    // MARK: Lecture

    static func club(depuis record: CKRecord) -> Club? {
        guard record.recordType == typeClub,
              let nom = record["nom"] as? String,
              let fondateur = record["fondateur"] as? String,
              let creeLe = record["creeLe"] as? Date else { return nil }
        let image = (record["image"] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf: $0) }
        return Club(id: record.recordID.recordName, nom: nom, poissonId: record["poissonId"] as? String, image: image,
                    fondateur: fondateur, retires: record["retires"] as? [String] ?? [],
                    ferme: (record["ferme"] as? Int ?? 0) == 1, creeLe: creeLe)
    }

    static func membre(depuis record: CKRecord) -> Membre? {
        guard record.recordType == typeMembre,
              let club = record["club"] as? String, let profil = record["profil"] as? String,
              let role = (record["role"] as? String).flatMap(RoleMembre.init(rawValue:)),
              let depuis = record["depuis"] as? Date else { return nil }
        return Membre(id: record.recordID.recordName, club: club, profil: profil, role: role, depuis: depuis)
    }

    /// `nil` si ce n'est pas une carte de club (une publication ordinaire du fil, sans le préfixe `pc-`).
    static func carte(depuis record: CKRecord) -> CartePartageeClub? {
        guard record.recordType == typePublication,
              let club = record["club"] as? String, !club.isEmpty,
              record.recordID.recordName.hasPrefix(prefixeCarte(club: club)),
              let auteur = record["auteurNom"] as? String,
              let creeLe = record["creeLe"] as? Date else { return nil }
        let id = record.recordID.recordName
        let image = (record["media"] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf: $0) }
        return CartePartageeClub(
            id: id, club: club, carteID: String(id.dropFirst(prefixeCarte(club: club).count)), auteur: auteur,
            espece: record["espece"] as? String ?? "", rarete: (record["rarete"] as? String).flatMap(NiveauRarete.init(rawValue:)),
            tailleCm: record["tailleCm"] as? Double, departement: record["departement"] as? String ?? "", image: image, creeLe: creeLe)
    }
}
