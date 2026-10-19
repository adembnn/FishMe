import CloudKit
import Foundation

/// Réglages donnés par A. Le conteneur est celui du projet MWM (comme `ConfigurationAmis`).
nonisolated struct ConfigurationFeed: Sendable {
    var conteneur: String = "iCloud.ai.mwm.build.challenge.team.01"
}

/// Le vrai service du fil : base publique du conteneur (publications, likes, commentaires, signalements), base privée (blocages).
///
/// À VÉRIFIER SUR LE MAC (écrit de mémoire, non compilé ici) :
/// - `CKDatabase.records(matching:inZoneWith:desiredKeys:resultsLimit:)` et `records(continuingMatchFrom:desiredKeys:resultsLimit:)` (async) ;
/// - le prédicat `IN` combiné à `creeLe <` (`schema.md` le marque aussi à vérifier) ;
/// - les index « queryable » et « sortable » du tableau de bord (`schema.md`, « Index »), sinon les requêtes échouent ;
/// - les rôles de sécurité de la base publique : seul le créateur modifie ou supprime son enregistrement.
actor ServiceFeedCloudKit: ServiceFeed {
    private let conteneurPermis: CKContainer?
    private let dossierTemp: URL

    init(configuration: ConfigurationFeed = ConfigurationFeed()) {
        // Archive de repli sans iCloud (clé Info `FishMeICloud` = NO) : créer un `CKContainer` ferait quitter l'app.
        let valeur = (Bundle.main.object(forInfoDictionaryKey: "FishMeICloud") as? String ?? "").uppercased()
        let actif = !["NO", "0", "FALSE"].contains(valeur)
        self.conteneurPermis = actif ? CKContainer(identifier: configuration.conteneur) : nil
        self.dossierTemp = FileManager.default.temporaryDirectory.appendingPathComponent("FeedEnvoi", isDirectory: true)
    }

    private var conteneur: CKContainer {
        get throws {
            guard let conteneurPermis else { throw ErreurFeed.iCloudIndisponible }
            return conteneurPermis
        }
    }
    private var publique: CKDatabase { get throws { try conteneur.publicCloudDatabase } }
    private var privee: CKDatabase { get throws { try conteneur.privateCloudDatabase } }

    func compteDisponible() async -> Bool {
        guard let conteneurPermis else { return false }
        return (try? await conteneurPermis.accountStatus()) == .available
    }

    // MARK: Publications

    func publier(_ brouillon: BrouillonPublication) async throws -> PublicationFeed {
        try await executer {
            let record = FabriqueFeed.record(pour: brouillon)
            try await ecrire([record], dans: publique)
            guard var publiee = FabriqueFeed.publication(depuis: record) else { throw ErreurFeed.autre }
            publiee.vignette = brouillon.vignette
            return publiee
        }
    }

    func page(_ demande: DemandeSection) async throws -> PageFeed {
        guard !demande.valeurs.isEmpty else { return PageFeed(publications: [], encore: false) }
        return try await executer {
            let champ: String
            switch demande.section {
            case .clubs: champ = "club"
            case .amis: champ = "auteurNom"
            case .region: champ = "departement"
            }
            var predicats = [NSPredicate(format: "%K IN %@", champ, demande.valeurs)]
            if let avant = demande.avant { predicats.append(NSPredicate(format: "creeLe < %@", avant as NSDate)) }
            let requete = CKQuery(recordType: FabriqueFeed.typePublication, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicats))
            requete.sortDescriptors = [NSSortDescriptor(key: "creeLe", ascending: false)]
            let (resultats, _) = try await publique.records(matching: requete, desiredKeys: FabriqueFeed.clesDuFil, resultsLimit: demande.limite)
            let publications = resultats.compactMap { _, resultat in (try? resultat.get()).flatMap(FabriqueFeed.publication(depuis:)) }
            return PageFeed(publications: publications, encore: resultats.count >= demande.limite)
        }
    }

    func supprimerPublication(_ id: String) async throws {
        try await executer { try await effacer([CKRecord.ID(recordName: id)], dans: publique) }
    }

    func media(de publication: String) async throws -> URL {
        try await executer {
            let record = try await publique.record(for: CKRecord.ID(recordName: publication))
            guard let url = (record["media"] as? CKAsset)?.fileURL else { throw ErreurFeed.introuvable }
            return url
        }
    }

    // MARK: Likes et commentaires

    func likes(de publications: [String]) async throws -> [String: [String]] {
        guard !publications.isEmpty else { return [:] }
        return try await executer {
            let requete = CKQuery(recordType: FabriqueFeed.typeLike, predicate: NSPredicate(format: "publication IN %@", publications))
            let (resultats, _) = try await publique.records(matching: requete, desiredKeys: ["publication", "auteurNom"],
                                                            resultsLimit: CKQueryOperation.maximumResults)
            var parPublication: [String: [String]] = [:]
            for (_, resultat) in resultats {
                guard let record = try? resultat.get(), let pub = record["publication"] as? String,
                      let auteur = record["auteurNom"] as? String else { continue }
                parPublication[pub, default: []].append(auteur)
            }
            return parPublication
        }
    }

    func aimer(publication: String, par auteur: String) async throws {
        try await executer { try await ecrire([FabriqueFeed.recordLike(publication: publication, auteur: auteur)], dans: publique) }
    }

    func nePlusAimer(publication: String, par auteur: String) async throws {
        let id = CKRecord.ID(recordName: FabriqueFeed.identifiantLike(publication: publication, auteur: auteur))
        try await executer { try await effacer([id], dans: publique) }
    }

    func commentaires(de publication: String, apres: Date?, limite: Int) async throws -> [CommentaireFeed] {
        try await executer {
            var predicats = [NSPredicate(format: "publication == %@", publication)]
            if let apres { predicats.append(NSPredicate(format: "creeLe > %@", apres as NSDate)) }
            let requete = CKQuery(recordType: FabriqueFeed.typeCommentaire, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicats))
            requete.sortDescriptors = [NSSortDescriptor(key: "creeLe", ascending: true)]
            let (resultats, _) = try await publique.records(matching: requete, resultsLimit: limite)
            return resultats.compactMap { _, resultat in (try? resultat.get()).flatMap(FabriqueFeed.commentaire(depuis:)) }
        }
    }

    func commenter(_ commentaire: CommentaireFeed) async throws {
        try await executer { try await ecrire([FabriqueFeed.record(pour: commentaire)], dans: publique) }
    }

    func supprimerCommentaire(_ id: String) async throws {
        try await executer { try await effacer([CKRecord.ID(recordName: id)], dans: publique) }
    }

    // MARK: Modération

    func signaler(_ signalement: SignalementFeed) async throws {
        try await executer { try await ecrire([FabriqueFeed.record(pour: signalement)], dans: publique) }
    }

    func bloquer(_ auteur: String) async throws {
        try await executer { try await ecrire([FabriqueFeed.recordBlocage(auteur)], dans: privee) }
    }

    /// Efface ce que cet auteur a mis en base publique. Les enregistrements des autres ne se touchent pas.
    func supprimerContenus(de auteur: String) async throws {
        try await executer {
            for type in [FabriqueFeed.typePublication, FabriqueFeed.typeCommentaire, FabriqueFeed.typeLike] {
                let requete = CKQuery(recordType: type, predicate: NSPredicate(format: "auteurNom == %@", auteur))
                var ids: [CKRecord.ID] = []
                var (resultats, curseur) = try await publique.records(matching: requete, desiredKeys: [], resultsLimit: 200)
                ids += resultats.map(\.0)
                while let suite = curseur {
                    (resultats, curseur) = try await publique.records(continuingMatchFrom: suite, desiredKeys: [], resultsLimit: 200)
                    ids += resultats.map(\.0)
                }
                var debut = 0
                while debut < ids.count {
                    try await effacer(Array(ids[debut..<min(debut + 200, ids.count)]), dans: publique)
                    debut += 200
                }
            }
        }
    }

    // MARK: Aides

    private func ecrire(_ records: [CKRecord], dans base: CKDatabase) async throws {
        // `.allKeys` : réécrire son propre like ne produit pas d'erreur de version.
        let resultat = try await base.modifyRecords(saving: records, deleting: [], savePolicy: .allKeys, atomically: false)
        for (_, sauvegarde) in resultat.saveResults {
            if case .failure(let erreur) = sauvegarde { throw erreur }
        }
    }

    private func effacer(_ ids: [CKRecord.ID], dans base: CKDatabase) async throws {
        let resultat = try await base.modifyRecords(saving: [], deleting: ids, savePolicy: .allKeys, atomically: false)
        for (_, suppression) in resultat.deleteResults {
            if case .failure(let erreur) = suppression, (erreur as? CKError)?.code != .unknownItem { throw erreur }
        }
    }

    private func executer<T>(_ travail: () async throws -> T) async throws -> T {
        do {
            return try await travail()
        } catch {
            throw Self.traduire(error)
        }
    }

    /// Traduit toute erreur CloudKit en `ErreurFeed` : le reste de l'app ne connaît pas CloudKit.
    static func traduire(_ erreur: Error) -> ErreurFeed {
        if let connue = erreur as? ErreurFeed { return connue }
        guard let ck = erreur as? CKError else { return .autre }
        switch ck.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy, .internalError:
            return .reseau
        case .notAuthenticated, .accountTemporarilyUnavailable:
            return .iCloudIndisponible
        case .permissionFailure:
            return .refuse
        case .quotaExceeded:
            return .iCloudPlein
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
