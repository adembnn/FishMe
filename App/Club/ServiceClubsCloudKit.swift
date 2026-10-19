import CloudKit
import Foundation

/// Le vrai service des clubs : `Club`, `Membre` et les cartes (`Publication`) en base publique.
/// Même style que `ServiceProfilCloudKit` et `ServiceAmisCloudKit` : un `executer` qui traduit les erreurs, un conteneur absent sans iCloud.
///
/// Écrit de mémoire, NON COMPILÉ (pas de Mac pour ce lot). À VÉRIFIER SUR LE MAC :
///  - `CKDatabase.modifyRecords(saving:deleting:savePolicy:atomically:)` et ses `saveResults` / `deleteResults` (déjà utilisés par `ServiceProfilCloudKit`) ;
///  - `CKDatabase.records(for:desiredKeys:)` (async) pour lire plusieurs clubs d'un coup ;
///  - `serverRecordChanged` quand on réécrit un enregistrement neuf qui existe déjà : on le prend pour un succès (idempotence) ;
///  - index à créer dans le tableau de bord (Development puis Production, `schema.md`) : `Membre.club` et `Membre.profil` queryable ;
///    `Publication.club` et `Publication.auteurNom` queryable, `Publication.creeLe` sortable ; `recordName` queryable sur `Club` ;
///  - droits du type : « World » lit, « Authenticated » crée, le créateur seul modifie et supprime (R2, `schema.md`) ;
///  - un `Membre` est écrit par son membre, donc supprimé par lui seul : « quitter » le fait ; « écarter » passe par `Club.retires`.
actor ServiceClubsCloudKit: ServiceClubs {
    /// `nil` dans une archive de repli sans iCloud : créer un `CKContainer` sans le droit iCloud fait quitter l'app.
    private let conteneurPermis: CKContainer?
    private let dossierTemp: URL

    init(conteneur: String = ConfigurationAmis.conteneurParDefaut) {
        self.conteneurPermis = CloudKitPermis.actif ? CKContainer(identifier: conteneur) : nil
        self.dossierTemp = FileManager.default.temporaryDirectory.appendingPathComponent("ClubEnvoi", isDirectory: true)
    }

    private var publique: CKDatabase {
        get throws {
            guard let conteneurPermis else { throw ErreurClub.iCloudIndisponible }
            return conteneurPermis.publicCloudDatabase
        }
    }

    func iCloudDisponible() async -> Bool {
        guard let conteneurPermis else { return false }
        return (try? await conteneurPermis.accountStatus()) == .available
    }

    // MARK: Création et lecture

    func creer(id: String, nom: String, poissonId: String?, image: Data?, fondateur: String, le date: Date) async throws -> Club {
        try await executer {
            defer { try? FileManager.default.removeItem(at: dossierTemp) }
            let base = try publique
            let club = Club(id: id, nom: nom, poissonId: poissonId, image: image, fondateur: fondateur, creeLe: date)
            let recordClub = try FabriqueRecordsClub.recordClub(club, dossierTemp: dossierTemp)
            let adhesion = Membre(id: Membre.identifiant(club: id, profil: fondateur), club: id, profil: fondateur,
                                  role: .fondateur, depuis: date)
            // `atomically: false` : si le club existe déjà (migration rejouée), l'adhésion peut quand même s'écrire.
            try await ecrire([recordClub, FabriqueRecordsClub.recordMembre(adhesion)], dans: base)
            let relu = try await base.record(for: recordClub.recordID)
            guard let rendu = FabriqueRecordsClub.club(depuis: relu) else { throw ErreurClub.autre }
            return rendu
        }
    }

    func club(id: String) async throws -> Club? {
        try await executer {
            do {
                let record = try await publique.record(for: CKRecord.ID(recordName: id))
                return FabriqueRecordsClub.club(depuis: record)
            } catch let erreur as CKError where erreur.code == .unknownItem {
                return nil
            }
        }
    }

    func membres(deClub id: String) async throws -> [Membre] {
        try await executer {
            let requete = CKQuery(recordType: FabriqueRecordsClub.typeMembre, predicate: NSPredicate(format: "club == %@", id))
            return try await lire(requete).compactMap(FabriqueRecordsClub.membre(depuis:))
        }
    }

    func clubs(deProfil profil: String) async throws -> [Club] {
        try await executer {
            let requete = CKQuery(recordType: FabriqueRecordsClub.typeMembre, predicate: NSPredicate(format: "profil == %@", profil))
            let ids = try await lire(requete).compactMap(FabriqueRecordsClub.membre(depuis:)).map { CKRecord.ID(recordName: $0.club) }
            guard !ids.isEmpty else { return [] }
            let reponse = try await publique.records(for: ids)
            var clubs: [Club] = []
            for (_, resultat) in reponse {
                if case .success(let record) = resultat, let club = FabriqueRecordsClub.club(depuis: record) { clubs.append(club) }
            }
            return clubs.sorted { $0.creeLe < $1.creeLe }
        }
    }

    // MARK: Adhésion

    func rejoindre(club id: String, profil: String, le date: Date) async throws -> Membre {
        try await executer {
            let base = try publique
            let adhesion = Membre(id: Membre.identifiant(club: id, profil: profil), club: id, profil: profil, role: .membre, depuis: date)
            try await ecrire([FabriqueRecordsClub.recordMembre(adhesion)], dans: base)
            // Déjà membre : on rend l'adhésion qui existe (sa date d'origine), pas la nôtre.
            let relu = try await base.record(for: CKRecord.ID(recordName: adhesion.id))
            guard let rendu = FabriqueRecordsClub.membre(depuis: relu) else { throw ErreurClub.autre }
            return rendu
        }
    }

    func quitter(club id: String, profil: String) async throws {
        try await executer {
            let base = try publique
            var aSupprimer = try await idsDeMesCartes(club: id, profil: profil)
            aSupprimer.append(CKRecord.ID(recordName: Membre.identifiant(club: id, profil: profil)))
            try await supprimer(aSupprimer, dans: base)
        }
    }

    func fermer(club id: String, fondateur: String) async throws {
        try await executer {
            let base = try publique
            let record = try await base.record(for: CKRecord.ID(recordName: id))
            guard let club = FabriqueRecordsClub.club(depuis: record) else { throw ErreurClub.introuvable }
            guard club.fondateur == fondateur else { throw ErreurClub.refuse }
            record["ferme"] = 1
            try await ecrire([record], dans: base, politique: .changedKeys)
            var aSupprimer = try await idsDeMesCartes(club: id, profil: fondateur)
            aSupprimer.append(CKRecord.ID(recordName: Membre.identifiant(club: id, profil: fondateur)))
            try await supprimer(aSupprimer, dans: base)
        }
    }

    func supprimer(club id: String, fondateur: String) async throws {
        try await executer {
            let base = try publique
            var aSupprimer = try await idsDeMesCartes(club: id, profil: fondateur)
            aSupprimer.append(CKRecord.ID(recordName: Membre.identifiant(club: id, profil: fondateur)))
            aSupprimer.append(CKRecord.ID(recordName: id))
            try await supprimer(aSupprimer, dans: base)
        }
    }

    func ecarter(profil: String, deClub id: String) async throws {
        try await executer {
            let base = try publique
            let record = try await base.record(for: CKRecord.ID(recordName: id))
            guard let club = FabriqueRecordsClub.club(depuis: record) else { throw ErreurClub.introuvable }
            guard !club.retires.contains(profil) else { return }
            // Seul le créateur du `Club` (le fondateur) peut l'écrire : un autre reçoit `permissionFailure`, traduit en `.refuse`.
            record["retires"] = club.retires + [profil]
            try await ecrire([record], dans: base, politique: .changedKeys)
        }
    }

    // MARK: Cartes

    func partager(_ carte: CartePartageeClub) async throws {
        try await executer {
            defer { try? FileManager.default.removeItem(at: dossierTemp) }
            let record = try FabriqueRecordsClub.recordCarte(carte, dossierTemp: dossierTemp)
            try await ecrire([record], dans: try publique)
        }
    }

    func retirerCarte(id: String) async throws {
        try await executer {
            try await supprimer([CKRecord.ID(recordName: id)], dans: try publique)
        }
    }

    func cartes(deClub id: String) async throws -> [CartePartageeClub] {
        try await executer {
            let requete = CKQuery(recordType: FabriqueRecordsClub.typePublication, predicate: NSPredicate(format: "club == %@", id))
            requete.sortDescriptors = [NSSortDescriptor(key: "creeLe", ascending: false)]
            return try await lire(requete, limite: 100).compactMap(FabriqueRecordsClub.carte(depuis:))
        }
    }

    // MARK: Signalement

    func signaler(cible: String, typeCible: String, motif: MotifSignalement, par monID: String?) async throws {
        try await executer {
            let record = FabriqueRecordsClub.recordSignalement(cible: cible, typeCible: typeCible, motif: motif, par: monID, le: Date())
            try await ecrire([record], dans: try publique)
        }
    }

    // MARK: Aides

    /// Écrit ces enregistrements un par un en tolérant `serverRecordChanged` : l'enregistrement existe déjà, rejouer est un succès.
    private func ecrire(_ records: [CKRecord], dans base: CKDatabase, politique: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged) async throws {
        let resultat = try await base.modifyRecords(saving: records, deleting: [], savePolicy: politique, atomically: false)
        for record in records {
            if case .failure(let erreur)? = resultat.saveResults[record.recordID] {
                if politique == .ifServerRecordUnchanged, let ck = erreur as? CKError, ck.code == .serverRecordChanged { continue }
                throw erreur
            }
        }
    }

    private func supprimer(_ ids: [CKRecord.ID], dans base: CKDatabase) async throws {
        guard !ids.isEmpty else { return }
        let resultat = try await base.modifyRecords(saving: [], deleting: ids, savePolicy: .ifServerRecordUnchanged, atomically: false)
        for id in ids {
            if case .failure(let erreur)? = resultat.deleteResults[id] {
                if let ck = erreur as? CKError, ck.code == .unknownItem { continue }
                throw erreur
            }
        }
    }

    private func lire(_ requete: CKQuery, limite: Int = CKQueryOperation.maximumResults) async throws -> [CKRecord] {
        let reponse = try await publique.records(matching: requete, inZoneWith: nil, desiredKeys: nil, resultsLimit: limite)
        var records: [CKRecord] = []
        for (_, resultat) in reponse.matchResults {
            if case .success(let record) = resultat { records.append(record) }
        }
        return records
    }

    /// Les cartes de ce profil dans ce club : celles dont le `recordName` commence par `pc-<club>-` (jamais ses autres publications).
    private func idsDeMesCartes(club id: String, profil: String) async throws -> [CKRecord.ID] {
        let predicat = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "club == %@", id), NSPredicate(format: "auteurNom == %@", profil),
        ])
        let requete = CKQuery(recordType: FabriqueRecordsClub.typePublication, predicate: predicat)
        let prefixe = FabriqueRecordsClub.prefixeCarte(club: id)
        let reponse = try await publique.records(matching: requete, inZoneWith: nil, desiredKeys: ["club"],
                                                 resultsLimit: CKQueryOperation.maximumResults)
        var ids: [CKRecord.ID] = []
        for (identifiant, resultat) in reponse.matchResults {
            if case .success = resultat, identifiant.recordName.hasPrefix(prefixe) { ids.append(identifiant) }
        }
        return ids
    }

    /// Traduit toute erreur CloudKit en `ErreurClub` : le reste de l'app ne connaît pas CloudKit.
    private func executer<T>(_ travail: () async throws -> T) async throws -> T {
        do {
            return try await travail()
        } catch {
            throw Self.traduire(error)
        }
    }

    static func traduire(_ erreur: Error) -> ErreurClub {
        if let connue = erreur as? ErreurClub { return connue }
        if erreur is DecodingError { return .autre }
        guard let ck = erreur as? CKError else { return .autre }
        switch ck.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .internalError:
            return .reseau
        case .notAuthenticated, .accountTemporarilyUnavailable:
            return .iCloudIndisponible
        case .permissionFailure:
            return .refuse
        case .unknownItem, .zoneNotFound:
            return .introuvable
        case .partialFailure:
            let internes = (ck.partialErrorsByItemID ?? [:]).values.map(traduire)
            return internes.first(where: { $0 != .autre }) ?? .autre
        default:
            return .autre
        }
    }
}
