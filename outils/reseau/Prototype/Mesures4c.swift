import CloudKit
import Foundation

// PROTOTYPE R2 : NON COMPILÉ. TEST 4c : latence sur une ZONE PARTAGÉE, le chemin réel du chat (L24).
// Dispositif : compte iCloud A (propriétaire, appareil 1) et compte iCloud B (invité, appareil 2). Pas d'index à créer : on lit les changements de zone.
// Le chat réel : zone privée du créateur + CKShare ; l'invité s'abonne sur la base PARTAGÉE. On teste donc les DEUX types d'abonnement sur la base
// partagée (CKRecordZoneSubscription comme L24, CKDatabaseSubscription comme R2) : le journal dit lequel est accepté et lequel réveille l'app.

enum Cote: String, Sendable { case proprietaire, invite }

extension Mesures {
    static let nomZone = "r2-4c"
    static let zone4c = CKRecordZone.ID(zoneName: nomZone, ownerName: CKCurrentUserDefaultName)
    private var privee: CKDatabase { CKContainer.default().privateCloudDatabase }
    private var partagee: CKDatabase { CKContainer.default().sharedCloudDatabase }

    private func silencieuse() -> CKSubscription.NotificationInfo {
        let i = CKSubscription.NotificationInfo(); i.shouldSendContentAvailable = true; return i
    }

    /// 4c-A (PROPRIÉTAIRE) : zone, partage de zone (lien ouvert en lecture-écriture, simplification d'essai), abonnement de zone sur la base privée.
    func creerZonePartagee4c(journal: @Sendable (String) -> Void) async throws {
        _ = try await privee.save(CKRecordZone(zoneID: Self.zone4c))
        let partage = CKShare(recordZoneID: Self.zone4c)               // ⚠ à vérifier : partage d'une zone entière
        partage[CKShare.SystemFieldKey.title] = "R2 essai 4c"
        partage.publicPermission = .readWrite                          // le chat réel nomme les participants ; ici le lien suffit
        guard let sauve = try await privee.save(partage) as? CKShare, let url = sauve.url else { throw ErreurProto.aucunFichier }
        let abo = CKRecordZoneSubscription(zoneID: Self.zone4c, subscriptionID: "r2-4c-zone-privee")
        abo.notificationInfo = silencieuse()
        _ = try await privee.save(abo)
        _ = try await releverChangements4c(etat: "amorçage", source: "", recuA: Date().timeIntervalSince1970, amorcage: true)
        journal("4c-A : zone créée, abonnement de zone (base privée) posé. LIEN À COPIER VERS L'INVITÉ : \(url.absoluteString)")
    }

    /// 4c-B (INVITÉ, autre compte iCloud) : accepte le lien, puis pose les deux abonnements sur la base partagée et note ceux que CloudKit refuse.
    func accepterLien4c(_ url: URL, journal: @Sendable (String) -> Void) async throws {
        let meta: CKShare.Metadata = try await withCheckedThrowingContinuation { suite in
            let op = CKFetchShareMetadataOperation(shareURLs: [url])
            let boite = BoiteMeta()                                    // porte la métadonnée entre les deux fermetures
            op.perShareMetadataResultBlock = { _, r in if case .success(let m) = r { boite.valeur = m } }
            op.fetchShareMetadataResultBlock = { r in
                if case .failure(let e) = r { suite.resume(throwing: e) }
                else if let m = boite.valeur { suite.resume(returning: m) } else { suite.resume(throwing: ErreurProto.aucunFichier) }
            }
            CKContainer.default().add(op)
        }
        try await withCheckedThrowingContinuation { (suite: CheckedContinuation<Void, Error>) in
            let op = CKAcceptSharesOperation(shareMetadatas: [meta])
            op.acceptSharesResultBlock = { r in
                switch r { case .success: suite.resume(); case .failure(let e): suite.resume(throwing: e) }
            }
            CKContainer.default().add(op)
        }
        journal("4c-B : partage accepté")
        let zoneID = meta.share.recordID.zoneID                        // ⚠ à vérifier : identifiant de la zone partagée
        let zoneAbo = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: "r2-4c-zone-partagee")
        let baseAbo = CKDatabaseSubscription(subscriptionID: "r2-4c-db")
        for (nom, abo) in [("CKRecordZoneSubscription", zoneAbo as CKSubscription), ("CKDatabaseSubscription", baseAbo as CKSubscription)] {
            abo.notificationInfo = silencieuse()
            do { _ = try await partagee.save(abo); journal("4c-B : \(nom) sur la base partagée : ACCEPTÉ") }
            catch { journal("4c-B : \(nom) sur la base partagée : REFUSÉ : \(error)") }
        }
        _ = try await releverChangements4c(etat: "amorçage", source: "", recuA: Date().timeIntervalSince1970, amorcage: true)
    }

    /// 4c-C : 20 messages, un toutes les 8 s, écrits par le propriétaire (base privée) ou par l'invité (base partagée). `ecritA` pris juste avant `save`.
    func ecrireMessages4c(cote: Cote, journal: @Sendable (String) -> Void) async throws {
        let base4c: CKDatabase
        let zoneID: CKRecordZone.ID
        if cote == .proprietaire { base4c = privee; zoneID = Self.zone4c }
        else {
            guard let z = try await partagee.allRecordZones().first(where: { $0.zoneID.zoneName == Self.nomZone }) else { throw ErreurProto.aucunFichier }
            base4c = partagee; zoneID = z.zoneID
        }
        for k in 0..<20 {
            let r = CKRecord(recordType: "MessageEssai", recordID: CKRecord.ID(recordName: "m4c-\(UUID().uuidString)", zoneID: zoneID))
            r["texte"] = "essai 4c"; r["marqueur"] = marqueur
            let ecrit = Date()
            r["ecritA"] = ecrit.timeIntervalSince1970
            _ = try await base4c.save(r)
            let retour = Date()
            journal("ÉCRIT 4c #\(k) (\(cote.rawValue)) appel à \(Self.heure(ecrit)), retour à \(Self.heure(retour)), save = \(String(format: "%.2f", retour.timeIntervalSince(ecrit))) s")
            try await Task.sleep(nanoseconds: 8_000_000_000)
        }
    }

    /// Appelé à la réception d'une notification de zone ou de base : lit les changements et note le délai. `recuA` = heure de réception, prise avant la lecture.
    func releverChangements4c(etat: String, source: String, recuA: Double, amorcage: Bool = false) async throws -> [String] {
        var lignes: [String] = []
        for (nom, db) in [("privée", privee), ("partagée", partagee)] {
            var zones: [CKRecordZone.ID] = []
            if nom == "privée" { zones = [Self.zone4c] }
            else { zones = ((try? await partagee.allRecordZones()) ?? []).map { $0.zoneID }.filter { $0.zoneName == Self.nomZone } }
            for zone in zones {
                let cle = nom + zone.ownerName
                var encore = true
                while encore {
                    // ⚠ à vérifier : API async iOS 15+ ; elle échoue si la zone n'existe pas de ce côté (alors on passe)
                    guard let r = try? await db.recordZoneChanges(inZoneWith: zone, since: jetons4c[cle]) else { break }
                    for (_, res) in r.modificationResultsByID {
                        guard case .success(let m) = res, let ecrit = m.record["ecritA"] as? Double else { continue }
                        let id = m.record.recordID.recordName
                        if amorcage { vus4c.insert(id); continue }
                        if vus4c.contains(id) { lignes.append("DOUBLON 4c \(id.prefix(12))"); continue }
                        vus4c.insert(id)
                        lignes.append("REÇU 4c (\(etat), base \(nom), \(source)) délai = \(String(format: "%.2f", recuA - ecrit)) s [\(id.prefix(12))]")
                    }
                    jetons4c[cle] = r.changeToken
                    encore = r.moreComing
                }
            }
        }
        if lignes.isEmpty && !amorcage { lignes.append("notification 4c (\(etat), \(source)) : aucun nouveau message lu") }
        return lignes
    }

    func nettoyer4c(journal: @Sendable (String) -> Void) async {
        do { _ = try await privee.deleteRecordZone(withID: Self.zone4c); journal("zone 4c supprimée (côté propriétaire)") }
        catch { journal("zone 4c : \(error) (normal sur l'appareil invité)") }
        _ = try? await privee.deleteSubscription(withID: "r2-4c-zone-privee")
        _ = try? await partagee.deleteSubscription(withID: "r2-4c-zone-partagee")
        _ = try? await partagee.deleteSubscription(withID: "r2-4c-db")
    }
}

/// Petite boîte partagée par deux fermetures CloudKit qui s'exécutent l'une après l'autre.
final class BoiteMeta: @unchecked Sendable { var valeur: CKShare.Metadata? }
