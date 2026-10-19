import CloudKit
import Foundation

// Le vrai service de chat. Écrit de mémoire, NON COMPILÉ (pas de Mac pour ce lot). À VÉRIFIER SUR LE MAC :
//  - `CKContainer.shareParticipant(forUserRecordID:)` (async) et `participant.permission = .readWrite` ;
//  - `CKDatabaseSubscription(subscriptionID:)` sur `sharedCloudDatabase` (R2 `schema.md:66`, `latence.md:46`) ;
//    `CKRecordZoneSubscription` et sa propriété `recordType` sur la base privée (zone que je possède) ; leur acceptation par CloudKit ;
//  - `CKDatabase.recordZoneChanges(inZoneWith:since:desiredKeys:resultsLimit:)` et ses quatre valeurs de retour ;
//  - `CKRecord.creatorUserRecordID` : `__defaultOwner__` ou identifiant réel selon la base ;
//  - `CKDatabase.records(matching:inZoneWith:desiredKeys:resultsLimit:)` et sa valeur de retour `matchResults` ;
//  - `CKDatabase.subscription(for:)` (async) ;
//  - index à créer dans le tableau de bord (Development puis Production) : `recordName` queryable sur `MessageAmi` et `MessageClub` ;
//    champ `texte` (String) à ajouter au type `Signalement`.
//
// AUCUN message n'entre en base publique (décision de Titouan : le chat d'un club est réservé à ses membres).
//  - Amis : UNE ZONE PARTAGÉE PAR PAIRE (`chat-<id>-<id>`), jamais la zone « Pescedex » du lot Amis (elle est partagée avec TOUS
//    les amis invités : les messages y seraient lisibles par les autres amis). UN SEUL CRÉATEUR PAR PAIRE : le pêcheur dont
//    l'identifiant de profil (`p-…`) est le plus petit dans l'ordre alphabétique crée la zone et la partage ; l'autre n'écrit
//    qu'après avoir accepté l'invitation. La zone partagée REÇUE est cherchée avant la zone privée.
//  - Club : UNE ZONE PARTAGÉE PAR CLUB (`chatclub-<id du club>`), possédée par le FONDATEUR, partagée avec chaque membre en
//    lecture-écriture (`publicPermission = .none` : le lien n'ouvre que pour les personnes nommées).
//
// Limites techniques (R2: à réaligner avec Adem) :
//  - R2: sans serveur, seul le propriétaire de la zone (le fondateur) peut ajouter ou retirer un participant : un nouveau membre ne
//    lit le chat qu'après que le fondateur a ouvert l'app (il ajoute alors les membres manquants) ET que le membre a accepté le lien.
//  - R2: `Club.fondateur` ne change jamais (schema.md) : fondateur parti ou compte supprimé = zone perdue, plus d'admission.
//  - R2: un `CKShare` plafonne le nombre de participants (de mémoire 100 ; non lu, à vérifier) : un club plus grand est refusé.
//  - R2: retirer un membre (écarté du club) ne lui retire pas encore l'accès à la zone : à faire côté fondateur
//    (`share.removeParticipant`), non fait ici faute de signal « membre écarté » dans le contrat de L22.
//  - R2: un membre qui a accepté peut transmettre le lien, mais il ne s'ouvre que pour les comptes nommés (`.none`).
//  - Un membre `readWrite` peut modifier ou supprimer les messages des autres dans la zone (limite de CKShare, non traitée).
//  - Les suppressions de messages faites ailleurs ne sont pas répercutées dans le cache local.

/// Une invitation de conversation reçue par lien. `CKShare.Metadata` n'est pas `Sendable` : il ne traverse qu'ici, une fois.
nonisolated struct InvitationChat: @unchecked Sendable {
    var metadata: CKShare.Metadata?

    init(metadata: CKShare.Metadata?) {
        self.metadata = metadata
    }

    /// Vrai si ce partage est une conversation du chat (ami ou club), et non l'invitation d'ami du lot Amis. A route avec ceci
    /// dans `SceneDuPartage` avant `RelaisInvitations` : voir le rapport L24. Les zones du lot Amis s'appellent « Pescedex » et
    /// ne commencent pas par « chat ».
    static func estUneConversation(_ metadata: CKShare.Metadata) -> Bool {
        metadata.share.recordID.zoneID.zoneName.hasPrefix(ServiceChatCloudKit.prefixeZone)
    }
}

nonisolated enum CloudKitPermisChat {
    /// Même clé Info que `CloudKitPermis` du lot Amis : « NO » dans les archives de repli sans iCloud.
    static var actif: Bool {
        let valeur = (Bundle.main.object(forInfoDictionaryKey: "FishMeICloud") as? String ?? "").uppercased()
        return !["NO", "0", "FALSE"].contains(valeur)
    }
}

actor ServiceChatCloudKit: ServiceChat {
    /// Toutes les zones du chat commencent par ceci (« chat-… » entre amis, « chatclub-… » pour un club).
    static let prefixeZone = "chat"

    private struct ZoneChat {
        var id: CKRecordZone.ID
        /// Vrai : la zone est dans ma base privée (je l'ai créée). Faux : elle est dans la base partagée (un autre l'a créée).
        var chezMoi: Bool
    }

    private let conteneurPermis: CKContainer?
    private var zones: [String: ZoneChat] = [:]
    private var monIdentifiant: String?
    /// Jetons de changement par zone, en mémoire : le rafraîchissement de 10 s ne relit que ce qui a changé.
    private var jetons: [String: CKServerChangeToken] = [:]
    private var basePartageeAbonnee = false

    init(conteneur: String = "iCloud.ai.mwm.build.challenge.team.01") {
        self.conteneurPermis = CloudKitPermisChat.actif ? CKContainer(identifier: conteneur) : nil
    }

    private var conteneur: CKContainer {
        get throws {
            guard let conteneurPermis else { throw ErreurChat.iCloudIndisponible }
            return conteneurPermis
        }
    }
    private var publique: CKDatabase { get throws { try conteneur.publicCloudDatabase } }
    private var privee: CKDatabase { get throws { try conteneur.privateCloudDatabase } }
    private var partagee: CKDatabase { get throws { try conteneur.sharedCloudDatabase } }

    private static func type(de conversation: ConversationID) -> String {
        conversation.type == .club ? FabriqueRecordsChat.typeClub : FabriqueRecordsChat.typeAmi
    }

    // MARK: Compte

    func iCloudDisponible() async -> Bool {
        guard let conteneurPermis else { return false }
        return (try? await conteneurPermis.accountStatus()) == .available
    }

    private func moi() async throws -> String {
        if let monIdentifiant { return monIdentifiant }
        let identifiant = try await conteneur.userRecordID().recordName
        monIdentifiant = identifiant
        return identifiant
    }

    // MARK: Lecture

    private func lire(_ conversation: ConversationID) async throws -> [MessageChat] {
        guard let zone = try await zoneChat(conversation, creer: false) else { return [] }
        let base = try zone.chezMoi ? privee : partagee
        let mon = try? await moi()
        let requete = CKQuery(recordType: Self.type(de: conversation), predicate: NSPredicate(value: true))
        let resultat = try await base.records(matching: requete, inZoneWith: zone.id, desiredKeys: nil,
                                              resultsLimit: CKQueryOperation.maximumResults)
        var messages: [MessageChat] = []
        for (_, lecture) in resultat.matchResults {
            if case .success(let record) = lecture,
               let message = FabriqueRecordsChat.message(depuis: record, conversation: conversation, monIdentifiant: mon) {
                messages.append(message)
            }
        }
        return messages.sorted { $0.date < $1.date }
    }

    func messages(de conversation: ConversationID) async throws -> [MessageChat] {
        try await executer { try await lire(conversation) }
    }

    /// Rafraîchissement périodique : seulement ce qui a changé depuis le dernier jeton. ⚠ API non vérifiée : à tout échec autre
    /// que le réseau, on retombe sur la lecture complète.
    func changements(de conversation: ConversationID) async throws -> [MessageChat] {
        try await executer {
            guard let zone = try await zoneChat(conversation, creer: false) else { return [] }
            let base = try zone.chezMoi ? privee : partagee
            let mon = try? await moi()
            var nouveaux: [MessageChat] = []
            do {
                for _ in 0..<5 {
                    let lot = try await base.recordZoneChanges(inZoneWith: zone.id, since: jetons[zone.id.zoneName],
                                                               desiredKeys: nil, resultsLimit: 200)
                    for (_, resultat) in lot.modificationResultsByID {
                        if case .success(let modification) = resultat,
                           modification.record.recordType == Self.type(de: conversation),
                           let message = FabriqueRecordsChat.message(depuis: modification.record, conversation: conversation,
                                                                     monIdentifiant: mon) {
                            nouveaux.append(message)
                        }
                    }
                    jetons[zone.id.zoneName] = lot.changeToken
                    if !lot.moreComing { break }
                }
                return nouveaux.sorted { $0.date < $1.date }
            } catch let erreur as CKError where Self.erreursReseau.contains(erreur.code) {
                throw erreur
            } catch {
                jetons[zone.id.zoneName] = nil // jeton expiré ou API refusée : relecture complète, nouveau jeton au prochain tour
                return try await lire(conversation)
            }
        }
    }

    private static let erreursReseau: [CKError.Code] = [
        .networkUnavailable, .networkFailure, .notAuthenticated, .serviceUnavailable, .requestRateLimited,
    ]

    // MARK: Envoi

    func envoyer(_ message: MessageChat, peutCreerLaZone: Bool) async throws {
        try await executer {
            do {
                guard let zone = try await zoneChat(message.conversation, creer: peutCreerLaZone) else {
                    // Ami : l'autre pêcheur crée la zone, je n'écris qu'après avoir accepté son lien. Club : le fondateur n'a
                    // pas encore créé la zone, ou je n'ai pas encore accepté le lien.
                    throw ErreurChat.introuvable
                }
                let base = try zone.chezMoi ? privee : partagee
                let record = message.conversation.type == .club
                    ? FabriqueRecordsChat.recordClub(message, zone: zone.id)
                    : FabriqueRecordsChat.recordAmi(message, zone: zone.id)
                _ = try await base.save(record)
            } catch let erreur as CKError where erreur.code == .serverRecordChanged {
                return // déjà arrivé lors d'une tentative précédente : même identifiant, même message
            }
        }
    }

    // MARK: Abonnements

    /// Zone à moi (je l'ai créée) : abonnement de zone dans ma base privée. Zone qui m'est partagée : abonnement de BASE sur la
    /// base partagée (c'est ce que prévoit R2) ; il couvre aussi les zones à venir. Les deux sont silencieux
    /// (`shouldSendContentAvailable`, pas de `alertBody`) : la base partagée contient aussi la zone « Pescedex » des amis, un texte
    /// « Nouveau message » y serait faux. `GestionChat` poste une alerte locale après filtrage (blocages, suppressions).
    /// ⚠ Une notification silencieuse n'est pas livrée à une app fermée de force, et iOS la limite : non vérifié sur appareil.
    func abonner(_ conversation: ConversationID) async throws {
        try await executer {
            let zone = try await zoneChat(conversation, creer: false)
            if zone == nil || zone?.chezMoi == false { try await abonnerBasePartagee() }
            guard let zone else { throw ErreurChat.introuvable }
            if zone.chezMoi { try await abonnerZonePrivee(zone.id, type: Self.type(de: conversation)) }
        }
    }

    private func abonnerBasePartagee() async throws {
        if basePartageeAbonnee { return }
        let identifiant = "chat-base-partagee"
        if (try? await partagee.subscription(for: identifiant)) == nil {
            let abonnement = CKDatabaseSubscription(subscriptionID: identifiant)
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true
            abonnement.notificationInfo = info
            _ = try await partagee.save(abonnement)
        }
        basePartageeAbonnee = true
    }

    private func abonnerZonePrivee(_ zone: CKRecordZone.ID, type: String) async throws {
        let identifiant = "chat-zone-\(zone.zoneName)"
        if (try? await privee.subscription(for: identifiant)) != nil { return }
        let abonnement = CKRecordZoneSubscription(zoneID: zone, subscriptionID: identifiant)
        abonnement.recordType = type // ⚠ propriété à vérifier ; sans elle, toute modification de la zone notifie (filtré côté app)
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        abonnement.notificationInfo = info
        _ = try await privee.save(abonnement)
    }

    // MARK: Zones partagées

    private func nettoyer(_ texte: String) -> String {
        String(texte.filter { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") })
    }

    private func nomDeZone(_ conversation: ConversationID) async throws -> String {
        switch conversation.type {
        case .club:
            return Self.prefixeZone + "club-" + nettoyer(conversation.cible)
        case .ami:
            let deux = [nettoyer(try await moi()), nettoyer(conversation.cible)].sorted()
            return Self.prefixeZone + "-" + deux.joined(separator: "-")
        }
    }

    /// La zone partagée REÇUE passe d'abord (l'autre pêcheur l'a créée), puis la mienne. On ne crée que si `creer` : et `creer`
    /// n'est vrai que pour le créateur désigné de la paire (identifiant de profil le plus petit) ou le fondateur du club.
    private func zoneChat(_ conversation: ConversationID, creer: Bool) async throws -> ZoneChat? {
        let nom = try await nomDeZone(conversation)
        if let connue = zones[nom] { return connue }
        if let z = try await partagee.allRecordZones().first(where: { $0.zoneID.zoneName == nom }) {
            zones[nom] = ZoneChat(id: z.zoneID, chezMoi: false)
            return zones[nom]
        }
        if let z = try await privee.allRecordZones().first(where: { $0.zoneID.zoneName == nom }) {
            zones[nom] = ZoneChat(id: z.zoneID, chezMoi: true)
            return zones[nom]
        }
        guard creer else { return nil }
        let nouvelle = CKRecordZone(zoneName: nom)
        let resultat = try await privee.modifyRecordZones(saving: [nouvelle], deleting: [])
        if case .failure(let erreur)? = resultat.saveResults[nouvelle.zoneID] { throw erreur }
        zones[nom] = ZoneChat(id: nouvelle.zoneID, chezMoi: true)
        return zones[nom]
    }

    func lienDInvitation(pour conversation: ConversationID, participants: [String], peutCreerLaZone: Bool) async throws -> URL? {
        try await executer {
            guard let zone = try await zoneChat(conversation, creer: peutCreerLaZone), zone.chezMoi else { return nil }
            let identifiant = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone.id)
            let existant = try? await privee.record(for: identifiant) as? CKShare
            let partage = existant ?? CKShare(recordZoneID: zone.id)
            if existant == nil {
                partage.publicPermission = .none // seules les personnes nommées peuvent accepter
                partage[CKShare.SystemFieldKey.title] = conversation.type == .club ? "Club FishMe" : "Conversation FishMe"
            }
            let deja = Set(partage.participants.compactMap { $0.userIdentity.userRecordID?.recordName })
            var ajoutes = false
            for cible in participants where !deja.contains(cible) {
                let participant = try await conteneur.shareParticipant(forUserRecordID: CKRecord.ID(recordName: cible))
                participant.permission = .readWrite
                partage.addParticipant(participant)
                ajoutes = true
            }
            var courant = partage
            if ajoutes || existant == nil {
                let resultat = try await privee.modifyRecords(saving: [partage], deleting: [],
                                                              savePolicy: .ifServerRecordUnchanged, atomically: true)
                guard case .success(let enregistre)? = resultat.saveResults[partage.recordID],
                      let enregistre = enregistre as? CKShare else { throw ErreurChat.autre }
                courant = enregistre
            }
            let enAttente = courant.participants.contains { $0.role != .owner && $0.acceptanceStatus != .accepted }
            return enAttente ? courant.url : nil
        }
    }

    /// Un lien de conversation reçu : A l'appelle depuis `SceneDuPartage` quand `InvitationChat.estUneConversation`.
    func accepterInvitation(_ invitation: InvitationChat) async throws {
        guard let metadata = invitation.metadata else { throw ErreurChat.introuvable }
        try await executer {
            _ = try await conteneur.accept(metadata)
            zones = [:]
            jetons = [:]
        }
    }

    // MARK: Signalement

    /// R2: seule la base publique est lue par la personne de garde ; droits « Authenticated : créer », lecture réservée à l'équipe
    /// (à régler dans le tableau de bord). Les erreurs montent : l'appelant ne dit « signalé » que si cet appel a réussi.
    func enregistrerSignalement(_ signalement: SignalementMessageEnAttente) async throws {
        try await executer {
            do {
                _ = try await publique.save(FabriqueRecordsChat.recordSignalement(signalement))
            } catch let erreur as CKError where erreur.code == .serverRecordChanged {
                return
            }
        }
    }

    // MARK: Effacement

    /// « Supprimer mon profil » : supprime mes messages dans toutes les zones du chat (les miennes et celles où je suis admis).
    /// « Mes » = créés par mon compte (`creatorUserRecordID`), pas « portant mon identifiant dans un champ » (falsifiable).
    func effacerMesMessages(auteurId: String) async throws {
        try await executer {
            let mon = try? await moi()
            for base in [try privee, try partagee] {
                for zone in try await base.allRecordZones() where zone.zoneID.zoneName.hasPrefix(Self.prefixeZone) {
                    let type = zone.zoneID.zoneName.hasPrefix(Self.prefixeZone + "club-")
                        ? FabriqueRecordsChat.typeClub : FabriqueRecordsChat.typeAmi
                    let requete = CKQuery(recordType: type, predicate: NSPredicate(value: true))
                    let lus = try await base.records(matching: requete, inZoneWith: zone.zoneID, desiredKeys: ["creeLe"],
                                                     resultsLimit: CKQueryOperation.maximumResults)
                    let miens = lus.matchResults.compactMap { try? $0.1.get() }
                        .filter { FabriqueRecordsChat.createurEstMoi($0.creatorUserRecordID?.recordName, monIdentifiant: mon) }
                        .map(\.recordID)
                    if !miens.isEmpty { _ = try await base.modifyRecords(saving: [], deleting: miens) }
                }
            }
        }
    }

    // MARK: Erreurs

    private func executer<T>(_ travail: () async throws -> T) async throws -> T {
        do {
            return try await travail()
        } catch {
            throw Self.traduire(error)
        }
    }

    static func traduire(_ erreur: Error) -> ErreurChat {
        if let connue = erreur as? ErreurChat { return connue }
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
}
