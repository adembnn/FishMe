import CloudKit
import Foundation

/// Fabrique les `CKRecord` du profil (et du signalement) et les relit. Seules les clés de `cles` existent : un test le prouve.
/// Nom, prénom, e-mail, identifiant Apple, lieu : aucun de ces champs n'existe ici (décision 3).
nonisolated enum FabriqueProfil {
    static let typeProfil = "Profil"
    static let typeSignalement = "Signalement"
    static let cles: Set<String> = ["surnomAffiche", "surnomNorm", "avatar", "creeLe", "version"]
    static let clesSignalement: Set<String> = ["cible", "typeCible", "motif", "signalePar", "creeLe"]

    /// `dossierTemp` reçoit le JPEG de l'avatar (`CKAsset`).
    static func record(surnom: String, avatar: Data?, creeLe: Date, dossierTemp: URL) throws -> CKRecord {
        let propre = surnom.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = Surnom.identifiant(pour: propre)
        let record = CKRecord(recordType: typeProfil, recordID: CKRecord.ID(recordName: id))
        record["surnomAffiche"] = propre
        record["surnomNorm"] = Surnom.normaliser(propre)
        record["creeLe"] = creeLe
        record["version"] = 1
        if let avatar { record["avatar"] = try asset(avatar, nom: id, dossierTemp: dossierTemp) }
        return record
    }

    static func asset(_ donnees: Data, nom: String, dossierTemp: URL) throws -> CKAsset {
        try FileManager.default.createDirectory(at: dossierTemp, withIntermediateDirectories: true)
        let fichier = dossierTemp.appendingPathComponent("\(nom)-\(UUID().uuidString).jpg")
        try donnees.write(to: fichier, options: .atomic)
        return CKAsset(fileURL: fichier)
    }

    static func profil(depuis record: CKRecord) -> ProfilModele? {
        guard record.recordType == typeProfil,
              let surnom = record["surnomAffiche"] as? String,
              let creeLe = record["creeLe"] as? Date else { return nil }
        let avatar = (record["avatar"] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf: $0) }
        return ProfilModele(id: record.recordID.recordName, surnom: surnom, avatar: avatar, creeLe: creeLe)
    }

    static func signalement(profilID: String, motif: MotifSignalement, par monID: String?, le date: Date) -> CKRecord {
        let record = CKRecord(recordType: typeSignalement, recordID: CKRecord.ID(recordName: UUID().uuidString))
        record["cible"] = profilID
        record["typeCible"] = "profil"
        record["motif"] = motif.rawValue
        record["signalePar"] = monID ?? ""
        record["creeLe"] = date
        return record
    }
}

/// Le vrai service : l'enregistrement `Profil` en base publique. Le `recordName` dérive du surnom, donc deux iPhones qui prennent
/// le même surnom écrivent le même enregistrement : avec `.ifServerRecordUnchanged`, le second est refusé (R2, `schema.md`).
///
/// À VÉRIFIER SUR LE MAC (écrit de mémoire, non compilé) : `serverRecordChanged` pour un enregistrement neuf qui existe déjà ;
/// l'index « queryable » de `surnomNorm` dans le tableau de bord ; `records(matching:inZoneWith:desiredKeys:resultsLimit:)` sur `BEGINSWITH` ;
/// les droits « World lit, Authenticated crée » du type `Profil` ; la création automatique des types en Development.
actor ServiceProfilCloudKit: ServiceProfil {
    /// `nil` dans une archive de repli sans iCloud (même règle que `ServiceAmisCloudKit`).
    private let conteneurPermis: CKContainer?
    private let dossierTemp: URL

    init(conteneur: String) {
        self.conteneurPermis = CloudKitPermis.actif ? CKContainer(identifier: conteneur) : nil
        self.dossierTemp = FileManager.default.temporaryDirectory.appendingPathComponent("ProfilEnvoi", isDirectory: true)
    }

    private var publique: CKDatabase {
        get throws {
            guard let conteneurPermis else { throw ErreurProfil.iCloudIndisponible }
            return conteneurPermis.publicCloudDatabase
        }
    }

    func profil(id: String) async throws -> ProfilModele? {
        try await executer {
            do {
                let record = try await publique.record(for: CKRecord.ID(recordName: id))
                return FabriqueProfil.profil(depuis: record)
            } catch let erreur as CKError where erreur.code == .unknownItem {
                return nil
            }
        }
    }

    func surnomEstLibre(_ surnom: String) async throws -> Bool {
        try await profil(id: Surnom.identifiant(pour: surnom)) == nil
    }

    func creer(surnom: String, avatar: Data?) async throws -> ProfilModele {
        try await executer {
            defer { try? FileManager.default.removeItem(at: dossierTemp) }
            let base = try publique
            let creeLe = Date()
            let record = try FabriqueProfil.record(surnom: surnom, avatar: avatar, creeLe: creeLe, dossierTemp: dossierTemp)
            // Première barrière : un enregistrement neuf ne s'écrase jamais.
            let resultat = try await base.modifyRecords(saving: [record], deleting: [], savePolicy: .ifServerRecordUnchanged,
                                                        atomically: true)
            guard let sauvegarde = resultat.saveResults[record.recordID] else { throw ErreurProfil.autre }
            if case .failure(let erreur) = sauvegarde { throw erreur }
            // Seconde barrière (fiche L21) : on relit. Si l'enregistrement n'est pas celui qu'on vient d'écrire, on a perdu la course.
            let relu = try await base.record(for: record.recordID)
            guard let date = relu["creeLe"] as? Date, abs(date.timeIntervalSince(creeLe)) < 1,
                  let profil = FabriqueProfil.profil(depuis: relu) else { throw ErreurProfil.surnomPris }
            return profil
        }
    }

    func changerAvatar(id: String, avatar: Data?) async throws -> ProfilModele {
        try await executer {
            defer { try? FileManager.default.removeItem(at: dossierTemp) }
            let base = try publique
            let record = try await base.record(for: CKRecord.ID(recordName: id))
            if let avatar {
                record["avatar"] = try FabriqueProfil.asset(avatar, nom: id, dossierTemp: dossierTemp)
            } else {
                record["avatar"] = nil
            }
            let resultat = try await base.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys, atomically: true)
            guard let sauvegarde = resultat.saveResults[record.recordID] else { throw ErreurProfil.autre }
            if case .failure(let erreur) = sauvegarde { throw erreur }
            let relu = try await base.record(for: record.recordID)
            guard let profil = FabriqueProfil.profil(depuis: relu) else { throw ErreurProfil.autre }
            return profil
        }
    }

    func chercher(prefixe: String) async throws -> [ProfilModele] {
        let cle = Surnom.normaliser(prefixe)
        guard cle.count >= 3 else { return [] }
        return try await executer {
            let requete = CKQuery(recordType: FabriqueProfil.typeProfil, predicate: NSPredicate(format: "surnomNorm BEGINSWITH %@", cle))
            let reponse = try await publique.records(matching: requete, inZoneWith: nil, desiredKeys: nil, resultsLimit: 20)
            var profils: [ProfilModele] = []
            for (_, resultat) in reponse.matchResults {
                if case .success(let record) = resultat, let profil = FabriqueProfil.profil(depuis: record) { profils.append(profil) }
            }
            return profils.sorted { $0.id < $1.id }
        }
    }

    func supprimer(id: String) async throws {
        try await executer {
            let identifiant = CKRecord.ID(recordName: id)
            let resultat = try await publique.modifyRecords(saving: [], deleting: [identifiant], savePolicy: .ifServerRecordUnchanged,
                                                            atomically: true)
            if case .failure(let erreur)? = resultat.deleteResults[identifiant] {
                if let ck = erreur as? CKError, ck.code == .unknownItem { return }
                throw erreur
            }
        }
    }

    func signaler(profilID: String, motif: MotifSignalement, par monID: String?) async throws {
        try await executer {
            let record = FabriqueProfil.signalement(profilID: profilID, motif: motif, par: monID, le: Date())
            let resultat = try await publique.modifyRecords(saving: [record], deleting: [], savePolicy: .ifServerRecordUnchanged,
                                                            atomically: true)
            if case .failure(let erreur)? = resultat.saveResults[record.recordID] { throw erreur }
        }
    }

    // MARK: Aides

    private func executer<T>(_ travail: () async throws -> T) async throws -> T {
        do {
            return try await travail()
        } catch {
            throw Self.traduire(error)
        }
    }

    static func traduire(_ erreur: Error) -> ErreurProfil {
        if let connue = erreur as? ErreurProfil { return connue }
        guard let ck = erreur as? CKError else { return .autre }
        switch ck.code {
        case .serverRecordChanged, .constraintViolation:
            return .surnomPris
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .internalError:
            return .reseau
        case .notAuthenticated, .accountTemporarilyUnavailable, .permissionFailure:
            return .iCloudIndisponible
        case .unknownItem:
            return .introuvable
        case .partialFailure:
            let internes = (ck.partialErrorsByItemID ?? [:]).values.map(traduire)
            return internes.first(where: { $0 != .autre }) ?? .autre
        default:
            return .autre
        }
    }
}
