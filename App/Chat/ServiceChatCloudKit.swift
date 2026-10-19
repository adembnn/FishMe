import CloudKit
import Foundation

// Le vrai service de chat. Écrit de mémoire, NON COMPILÉ (pas de Mac pour ce lot). À VÉRIFIER SUR LE MAC :
//  - `CKContainer.shareParticipant(forUserRecordID:)` (async) et `participant.permission = .readWrite` ;
//  - `CKRecordZoneSubscription` en base partagée, et sa propriété `recordType` ;
//  - `CKDatabase.records(matching:inZoneWith:desiredKeys:resultsLimit:)` et sa valeur de retour `matchResults` ;
//  - `CKDatabase.subscription(for:)` (async) ;
//  - index à créer dans le tableau de bord (Development puis Production) : `recordName` queryable sur `MessageAmi` et `MessageClub`.
//
// AUCUN message n'entre en base publique (décision de Titouan : le chat d'un club est réservé à ses membres).
//  - Amis : UNE ZONE PARTAGÉE PAR PAIRE (`chat-<id>-<id>`), jamais la zone « Pescedex » du lot Amis (elle est partagée avec TOUS
//    les amis invités : les messages y seraient lisibles par les autres amis).
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

/// Une invitation de conversation reçue par lien. `CKShare.Metadata` n'est pas `Sendable` : il ne traverse qu'ici, une fois.
nonisolated struct InvitationChat: @unchecked Sendable {
    var metadata: CKShare.Metadata?

    /// Vrai si ce partage est une conversation du chat (ami ou club), et non l'invitation d'ami du lot Amis. A route avec ceci
    /// dans `SceneDuPartage` / `RelaisInvitations` : voir le rapport L24.
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

    func messages(de conversation: ConversationID) async throws -> [MessageChat] {
        try await executer {
            guard let zone = try await zoneChat(conversation, creer: false) else { return [] }
            let base = try zone.chezMoi ? privee : partagee
            let requete = CKQuery(recordType: Self.type(de: conversation), predicate: NSPredicate(value: true))
            let resultat = try await base.records(matching: requete, inZoneWith: zone.id, desiredKeys: nil,
                                                  resultsLimit: CKQueryOperation.maximumResults)
            var messages: [MessageChat] = []
            for (_, lecture) in resultat.matchResults {
                if case .success(let record) = lecture,
                   let message = FabriqueRecordsChat.message(depuis: record, conversation: conversation) {
                    messages.append(message)
                }
            }
            return messages.sorted { $0.date < $1.date }
        }
    }

    // MARK: Envoi

    func envoyer(_ message: MessageChat, peutCreerLaZone: Bool) async throws {
        try await executer {
            do {
                guard let zone = try await zoneChat(message.conversation, creer: peutCreerLaZone) else {
                    throw ErreurChat.introuvable // club : le fondateur n'a pas encore créé la zone, ou je n'ai pas encore accepté le lien
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

    // MARK: Abonnement (un par conversation)

    func abonner(_ conversation: ConversationID) async throws {
        try await executer {
            guard let zone = try await zoneChat(conversation, creer: false) else { throw ErreurChat.introuvable }
            let base = try zone.chezMoi ? privee : partagee
            let identifiant = "chat-zone-\(zone.id.zoneName)"
            if (try? await base.subscription(for: identifiant)) != nil { return }
            // Un abonnement de zone (et non de base) : la zone « Pescedex » des cartes ne déclenche aucune notification de chat.
            let abonnement = CKRecordZoneSubscription(zoneID: zone.id, subscriptionID: identifiant)
            abonnement.recordType = Self.type(de: conversation)
            let info = CKSubscription.NotificationInfo()
            // Visible : « Nouveau message », sans le texte ni le nom (rien de privé sur l'écran verrouillé).
            info.alertBody = "Nouveau message"
            info.soundName = "default"
            info.shouldSendContentAvailable = true
            abonnement.notificationInfo = info
            _ = try await base.save(abonnement)
        }
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

    private func zoneChat(_ conversation: ConversationID, creer: Bool) async throws -> ZoneChat? {
        let nom = try await nomDeZone(conversation)
        if let connue = zones[nom] { return connue }
        if let z = try await privee.allRecordZones().first(where: { $0.zoneID.zoneName == nom }) {
            zones[nom] = ZoneChat(id: z.zoneID, chezMoi: true)
            return zones[nom]
        }
        if let z = try await partagee.allRecordZones().first(where: { $0.zoneID.zoneName == nom }) {
            zones[nom] = ZoneChat(id: z.zoneID, chezMoi: false)
            return zones[nom]
        }
        guard creer else { return nil }
        let nouvelle = CKRecordZone(zoneName: nom)
        let resultat = try await privee.modifyRecordZones(saving: [nouvelle], deleting: [])
        if case .failure(let erreur)? = resultat.saveResults[nouvelle.zoneID] { throw erreur }
        zones[nom] = ZoneChat(id: nouvelle.zoneID, chezMoi: true)
        return zones[nom]
    }

    func lienDInvitation(pour conversation: ConversationID, participants: [String]) async throws -> URL? {
        try await executer {
            guard let zone = try await zoneChat(conversation, creer: false), zone.chezMoi else { return nil }
            let identifiant = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone.id)
            let existant = try? await privee.record(for: identifiant) as? CKShare
            let share = existant ?? CKShare(recordZoneID: zone.id)
            if existant == nil {
                share.publicPermission = .none // seules les personnes nommées peuvent accepter
                share[CKShare.SystemFieldKey.title] = conversation.type == .club ? "Club FishMe" : "Conversation FishMe"
            }
            let deja = Set(share.participants.compactMap { $0.userIdentity.userRecordID?.recordName })
            var ajoutes = false
            for cible in participants where !deja.contains(cible) {
                let participant = try await conteneur.shareParticipant(forUserRecordID: CKRecord.ID(recordName: cible))
                participant.permission = .readWrite
                share.addParticipant(participant)
                ajoutes = true
            }
            var final = share
            if ajoutes || existant == nil {
                let resultat = try await privee.modifyRecords(saving: [share], deleting: [],
                                                              savePolicy: .ifServerRecordUnchanged, atomically: true)
                guard case .success(let enregistre)? = resultat.saveResults[share.recordID],
                      let enregistre = enregistre as? CKShare else { throw ErreurChat.autre }
                final = enregistre
            }
            let enAttente = final.participants.contains { $0.role != .owner && $0.acceptanceStatus != .accepted }
            return enAttente ? final.url : nil
        }
    }

    /// Un lien de conversation reçu : A l'appelle depuis `SceneDuPartage` quand `InvitationChat.estUneConversation`.
    func accepterInvitation(_ invitation: InvitationChat) async throws {
        guard let metadata = invitation.metadata else { throw ErreurChat.introuvable }
        try await executer {
            _ = try await conteneur.accept(metadata)
            zones = [:]
        }
    }

    // MARK: Signalement

    /// R2: seule la base publique est lue par la personne de garde ; droits « Authenticated : créer », lecture réservée à l'équipe
    /// (à régler dans le tableau de bord ; sinon l'e-mail prérempli reste la preuve, voir R2 `moderation.md`).
    func enregistrerSignalement(_ signalement: SignalementEnAttente) async throws {
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
    func effacerMesMessages(auteurId: String) async throws {
        try await executer {
            for base in [try privee, try partagee] {
                for zone in try await base.allRecordZones() where zone.zoneID.zoneName.hasPrefix(Self.prefixeZone) {
                    let type = zone.zoneID.zoneName.hasPrefix(Self.prefixeZone + "club-")
                        ? FabriqueRecordsChat.typeClub : FabriqueRecordsChat.typeAmi
                    let requete = CKQuery(recordType: type, predicate: NSPredicate(value: true))
                    let lus = try await base.records(matching: requete, inZoneWith: zone.zoneID, desiredKeys: ["auteurNom"],
                                                     resultsLimit: CKQueryOperation.maximumResults)
                    let miens = lus.matchResults.compactMap { try? $0.1.get() }
                        .filter { ($0["auteurNom"] as? String) == auteurId }.map(\.recordID)
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
