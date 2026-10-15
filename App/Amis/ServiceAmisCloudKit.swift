import CloudKit
import Foundation

/// Le vrai service d'amis : une zone `Pescedex` dans la base privée, partagée en entier par une seule `CKShare`
/// (`publicPermission = .none` : le lien n'ouvre que pour les personnes invitées). SwiftData ne partage pas : tout est à la main.
actor ServiceAmisCloudKit: ServiceAmis {
    private let conteneur: CKContainer
    private let zone = CKRecordZone.ID(zoneName: "Pescedex", ownerName: CKCurrentUserDefaultName)
    private let dossierTemp: URL

    init(configuration: ConfigurationAmis) {
        self.conteneur = CKContainer(identifier: configuration.conteneur)
        self.dossierTemp = FileManager.default.temporaryDirectory.appendingPathComponent("AmisEnvoi", isDirectory: true)
    }

    private var privee: CKDatabase { conteneur.privateCloudDatabase }
    private var partagee: CKDatabase { conteneur.sharedCloudDatabase }
    private var idPartage: CKRecord.ID { CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone) }

    // MARK: Compte

    func etatCompte() async -> EtatCompte {
        (try? await conteneur.accountStatus()) == .available ? .disponible : .indisponible
    }

    // MARK: Mes cartes

    func publier(_ cartes: [CartePartagee]) async throws {
        guard !cartes.isEmpty else { return }
        try await executer {
            try await creerLaZone()
            defer { try? FileManager.default.removeItem(at: dossierTemp) }
            var debut = 0
            while debut < cartes.count {
                let lot = Array(cartes[debut..<min(debut + 20, cartes.count)])
                debut += 20
                let records = try lot.map { try FabriqueRecords.record(pour: $0, zone: zone, dossierTemp: dossierTemp) }
                let resultat = try await privee.modifyRecords(saving: records, deleting: [], savePolicy: .changedKeys, atomically: false)
                for (_, sauvegarde) in resultat.saveResults {
                    if case .failure(let erreur) = sauvegarde { throw erreur }
                }
            }
        }
    }

    func supprimerMesCartes() async throws {
        try await executer {
            do {
                _ = try await privee.modifyRecordZones(saving: [], deleting: [zone])
            } catch let erreur as CKError where erreur.code == .zoneNotFound || erreur.code == .unknownItem {
                return
            }
        }
    }

    // MARK: Partage

    func partagePret() async throws -> PartagePret {
        try await executer {
            try await creerLaZone()
            if let existant = try? await privee.record(for: idPartage) as? CKShare {
                return PartagePret(share: existant)
            }
            let share = CKShare(recordZoneID: zone)
            share.publicPermission = .none
            share[CKShare.SystemFieldKey.title] = "Pescedex"
            let resultat = try await privee.modifyRecords(saving: [share], deleting: [], savePolicy: .ifServerRecordUnchanged,
                                                          atomically: true)
            guard case .success(let enregistre)? = resultat.saveResults[share.recordID], let final = enregistre as? CKShare else {
                throw ErreurAmis.autre
            }
            return PartagePret(share: final)
        }
    }

    func amisInvites() async throws -> [Ami] {
        try await executer {
            guard let share = try await monPartage() else { return [] }
            return share.participants.filter { $0.role != .owner }.map { participant in
                Ami(id: Self.identifiant(de: participant), nom: Self.nom(de: participant.userIdentity), sens: .invite,
                    enAttente: participant.acceptanceStatus != .accepted)
            }
        }
    }

    func retirerInvite(_ ami: Ami) async throws {
        try await executer {
            guard let share = try await monPartage(),
                  let participant = share.participants.first(where: { Self.identifiant(de: $0) == ami.id }) else { return }
            share.removeParticipant(participant)
            _ = try await privee.modifyRecords(saving: [share], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
        }
    }

    private func monPartage() async throws -> CKShare? {
        do {
            return try await privee.record(for: idPartage) as? CKShare
        } catch let erreur as CKError where erreur.code == .unknownItem || erreur.code == .zoneNotFound {
            return nil
        }
    }

    private func creerLaZone() async throws {
        let resultat = try await privee.modifyRecordZones(saving: [CKRecordZone(zoneID: zone)], deleting: [])
        if case .failure(let erreur)? = resultat.saveResults[zone] { throw erreur }
    }

    // MARK: Cartes des amis

    func collectionsRecues() async throws -> [CollectionAmi] {
        try await executer {
            var collections: [CollectionAmi] = []
            for zoneRecue in try await partagee.allRecordZones() {
                let proprietaire = zoneRecue.zoneID.ownerName
                let partage = try? await partagee.record(for: CKRecord.ID(recordName: CKRecordNameZoneWideShare,
                                                                            zoneID: zoneRecue.zoneID)) as? CKShare
                let nom = partage.map { Self.nom(de: $0.owner.userIdentity) } ?? "Un ami"
                var cartes: [CartePartagee] = []
                var jeton: CKServerChangeToken?
                var encore = true
                while encore {
                    let lot = try await partagee.recordZoneChanges(inZoneWith: zoneRecue.zoneID, since: jeton, desiredKeys: nil,
                                                                   resultsLimit: nil)
                    for (_, resultat) in lot.modificationResultsByID {
                        if case .success(let modification) = resultat, let carte = FabriqueRecords.carte(depuis: modification.record) {
                            cartes.append(carte)
                        }
                    }
                    jeton = lot.changeToken
                    encore = lot.moreComing
                }
                collections.append(CollectionAmi(ami: Ami(id: proprietaire, nom: nom, sens: .recu), cartes: cartes))
            }
            return collections
        }
    }

    func quitterPartage(de ami: Ami) async throws {
        try await executer {
            let zoneAmi = CKRecordZone.ID(zoneName: "Pescedex", ownerName: ami.id)
            let identifiant = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneAmi)
            do {
                _ = try await partagee.modifyRecords(saving: [], deleting: [identifiant], savePolicy: .ifServerRecordUnchanged,
                                                     atomically: true)
            } catch let erreur as CKError where erreur.code == .unknownItem || erreur.code == .zoneNotFound {
                return
            }
        }
    }

    func accepter(_ invitation: InvitationRecue) async throws -> Ami {
        guard let metadata = invitation.metadata else { throw ErreurAmis.invitationInvalide }
        return try await executer {
            _ = try await conteneur.accept(metadata)
            let proprietaire = metadata.share.recordID.zoneID.ownerName
            return Ami(id: proprietaire, nom: invitation.nomAmi, sens: .recu)
        }
    }

    // MARK: Aides

    /// Traduit toute erreur CloudKit en `ErreurAmis` : le reste de l'app ne connaît pas CloudKit.
    private func executer<T>(_ travail: () async throws -> T) async throws -> T {
        do {
            return try await travail()
        } catch {
            throw Self.traduire(error)
        }
    }

    static func traduire(_ erreur: Error) -> ErreurAmis {
        if let connue = erreur as? ErreurAmis { return connue }
        guard let ck = erreur as? CKError else { return .autre }
        switch ck.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .internalError:
            return .reseau
        case .notAuthenticated, .accountTemporarilyUnavailable, .permissionFailure:
            return .iCloudIndisponible
        case .quotaExceeded:
            return .iCloudPlein
        case .unknownItem, .zoneNotFound:
            return .introuvable
        case .partialFailure:
            let internes = (ck.partialErrorsByItemID ?? [:]).values.map(traduire)
            return internes.first(where: { $0 != .autre }) ?? .autre
        default:
            return .autre
        }
    }

    private static func identifiant(de participant: CKShare.Participant) -> String {
        let identite = participant.userIdentity
        return identite.userRecordID?.recordName ?? identite.lookupInfo?.emailAddress ?? identite.lookupInfo?.phoneNumber ?? "invite"
    }

    private static func nom(de identite: CKUserIdentity) -> String {
        guard let composants = identite.nameComponents else { return "Un ami" }
        let texte = PersonNameComponentsFormatter().string(from: composants)
        return texte.isEmpty ? "Un ami" : texte
    }
}
