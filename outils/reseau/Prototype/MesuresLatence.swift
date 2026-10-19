import CloudKit
import Foundation

// PROTOTYPE R2 : NON COMPILÉ. Test 4 (base publique, CKQuerySubscription) et nettoyage. Le test 4c est dans Mesures4c.swift.

extension Mesures {
    static func heure(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss.SSS"; return f.string(from: d)
    }

    // MARK: 4. Latence : 20 abonnements sur la base publique

    func creerAbonnements() async throws {
        for k in 0..<20 {
            let s = CKQuerySubscription(recordType: "Publication", predicate: NSPredicate(format: "departement == %@", "lat-\(k)"),
                                        subscriptionID: "r2-lat-\(k)", options: [.firesOnRecordCreation])
            let info = CKSubscription.NotificationInfo()
            info.shouldSendContentAvailable = true      // notification silencieuse
            info.desiredKeys = ["ecritA"]
            s.notificationInfo = info
            _ = try await base.save(s)
        }
    }

    /// Mode ÉCRIVAIN : un enregistrement toutes les 8 s, un par abonnement. Le RÉCEPTEUR est un autre appareil (CloudKit ne notifie en général pas l'appareil qui écrit ⚠).
    /// `ecritA` est pris juste avant l'appel à `save` ; le délai mesuré inclut donc l'envoi. Le journal donne aussi l'heure de retour de `save`
    /// et sa durée : « délai depuis le retour de save » = délai affiché par le récepteur - durée du save (même ligne côté écrivain).
    func ecrireLatence(journal: @Sendable (String) -> Void) async throws {
        for k in 0..<20 {
            let r = CKRecord(recordType: "Publication")
            r["departement"] = "lat-\(k)"; r["marqueur"] = marqueur; r["genre"] = "essai"; r["auteurNom"] = "proto-lat"
            let ecrit = Date()                                   // heure prise ici, juste avant l'envoi
            r["ecritA"] = ecrit.timeIntervalSince1970; r["creeLe"] = ecrit
            _ = try await base.save(r)
            let retour = Date()
            journal("ÉCRIT #\(k) appel à \(Self.heure(ecrit)), retour de save à \(Self.heure(retour)), save = \(String(format: "%.2f", retour.timeIntervalSince(ecrit))) s")
            try await Task.sleep(nanoseconds: 8_000_000_000)
        }
    }

    // MARK: 5. Nettoyage (borné : ni suppression en échec, ni index en retard ne peuvent faire boucler sans fin)

    func nettoyer(journal: @Sendable (String) -> Void) async throws {
        let maxPassages = 50                      // 50 passages de 300 au plus par type (estimation large)
        for type in ["Publication", "Like"] {
            var passages = 0
            var fini = false
            while passages < maxPassages && !fini {
                passages += 1
                let q = CKQuery(recordType: type, predicate: NSPredicate(format: "marqueur == %@", marqueur))
                let (res, _) = try await base.records(matching: q, desiredKeys: [], resultsLimit: 300)
                let ids = res.map { $0.0 }
                if ids.isEmpty { fini = true; break }
                let sortie = try await base.modifyRecords(saving: [], deleting: ids)
                let reussis = sortie.deleteResults.values.filter { if case .success = $0 { return true } else { return false } }.count
                journal("supprimés (\(type)) : \(reussis)/\(ids.count), passage \(passages)")
                if reussis == 0 { journal("aucune suppression réussie pour \(type) : arrêt (index en retard ou droits ? note-le)"); fini = true }
            }
            if !fini { journal("PLAFOND de \(maxPassages) passages atteint pour \(type) : relance « 5 » plus tard") }
        }
        await nettoyer4c(journal: journal)
        journal("NETTOYAGE FINI. Recontrôle le tableau de bord après quelques minutes (les compteurs bougent avec retard).")
    }
}
