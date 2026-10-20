import CloudKit
import Core
import Foundation

/// État du compte iCloud de l'iPhone (copie de `EtatICloud` de App/Compte/, dont ce dossier ne dépend pas).
nonisolated enum EtatICloudReperes: Sendable, Equatable { case disponible, absent, restreint, inconnu }

nonisolated struct BilanSauvegardeReperes: Sendable, Equatable {
    /// Repères maintenant dans iCloud (sans les pierres tombales).
    var reperes: Int
    var envoyes: Int
    var recus: Int
    var date: Date
    /// Vrai si l'iPhone a reçu quelque chose : `ModeleReperes.recharger()` doit relire le fichier.
    var aRelire: Bool
}

/// Sauvegarde des repères dans la base PRIVÉE iCloud du pêcheur, zone « Reperes » (distincte de « Sauvegarde » et de la zone
/// « Pescedex » des amis : jamais le même `CKRecordZone`, donc jamais dans un `CKShare`).
/// Tous les champs sauf l'identifiant du repère sont dans `encryptedValues` : lisibles par le pêcheur seul, pas dans la console.
/// Écrit sans compilateur : tout ce qui touche à CloudKit est à vérifier sur un iPhone connecté (critères 18 et 19, ⚠).
actor SauvegardeReperes {
    /// Même conteneur que `SauvegardeICloud` (App/Compte/). ⚠ à garder identique si l'identifiant change.
    static let identifiantConteneur = "iCloud.ai.mwm.build.challenge.team.01"

    /// Même interrupteur que `SauvegardeICloud.actif` : clé Info `FishMeICloud`, « NO » dans les archives sans iCloud.
    nonisolated static var actif: Bool {
        let valeur = (Bundle.main.object(forInfoDictionaryKey: "FishMeICloud") as? String ?? "").uppercased()
        return !["NO", "0", "FALSE"].contains(valeur)
    }

    nonisolated private static let zone = CKRecordZone.ID(zoneName: "Reperes", ownerName: CKCurrentUserDefaultName)
    nonisolated private static let lot = 100

    private enum Genre {
        static let repere = "Repere"
        static let photo = "PhotoRepere"
    }

    /// Champs lus d'un repère (jamais « fichier » : les photos ne se téléchargent pas à la liste).
    private enum Cle {
        static let nom = "nom", icone = "icone", note = "note", latitude = "latitude", longitude = "longitude"
        static let idsPrises = "idsPrises", photos = "photos", cree = "cree", modifie = "modifie"
        static let passageManuel = "passageManuel", supprime = "supprime"
        static let fichier = "fichier", octets = "octets"
        static let reperes = [nom, icone, note, latitude, longitude, idsPrises, photos, cree, modifie, passageManuel, supprime]
    }

    private let depot: DepotReperes
    private var conteneur: CKContainer?
    private var zonePrete = false
    private var enCours: Task<BilanSauvegardeReperes, Error>?

    init(depot: DepotReperes) {
        self.depot = depot
    }

    /// Créé au premier usage seulement : rien ne touche iCloud au lancement si le pêcheur n'a pas de compte.
    private var base: CKDatabase {
        if let conteneur { return conteneur.privateCloudDatabase }
        let nouveau = CKContainer(identifier: Self.identifiantConteneur)
        conteneur = nouveau
        return nouveau.privateCloudDatabase
    }

    func etatCompte() async -> EtatICloudReperes {
        _ = base
        guard let conteneur, let statut = try? await conteneur.accountStatus() else { return .inconnu }
        switch statut {
        case .available: return .disponible
        case .noAccount: return .absent
        case .restricted: return .restreint
        default: return .inconnu
        }
    }

    // MARK: Synchro

    func synchroniser() async throws -> BilanSauvegardeReperes {
        if let enCours { return try await enCours.value }
        let tache = Task { try await self.faireSynchro() }
        enCours = tache
        defer { enCours = nil }
        return try await tache.value
    }

    private func faireSynchro() async throws -> BilanSauvegardeReperes {
        let db = base
        try await preparerZone(db)
        let distant = try await lister(db)

        // 1. Fusion dans le fichier local, en un seul passage de l'acteur du dépôt (pas de perte si l'écran écrit en même temps).
        let avant = try await depot.lire()
        let fusion = try await depot.mettreAJour { local in JeuReperes.fusionner(local: local, distant: distant.reperes) }

        // 2. Ce qui manque ou a changé dans iCloud part ; les pierres tombales purgées sont retirées d'iCloud.
        let remoteParId = Dictionary(distant.reperes.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        let aEnvoyer = fusion.filter { remoteParId[$0.id] != $0 }
        try await sauver(aEnvoyer.map(Self.enregistrement(de:)), db)
        let aRetirer = JeuReperes.aRetirer(distant: distant.reperes, resultat: fusion).map(Self.id)
        try await retirer(aRetirer, db)

        // 3. Photos : celles qu'iCloud n'a pas encore partent (une fois chacune) ; celles qu'aucun repère actif ne cite sont retirées.
        let citees = Set(fusion.filter { !$0.estSupprime }.flatMap(\.photos).filter(DepotReperes.nomPhotoValide))
        let urlsEnvoi = await urlsLocales(de: citees.subtracting(distant.photos))
        try await envoyerPhotos(urlsEnvoi, db)
        let orphelines = distant.photos.subtracting(citees)
        try await retirer(orphelines.map(Self.idPhoto), db)

        // 4. Photos citées et absentes du disque (nouvel iPhone, repère créé sur un autre) : téléchargées maintenant.
        let manquantes = await photosAbsentes(citees)
        let recues = try await rapatrierPhotos(manquantes, db)

        let nouveauxDeLautreIPhone = fusion.filter { f in !avant.contains(f) }.count
        return BilanSauvegardeReperes(reperes: fusion.filter { !$0.estSupprime }.count, envoyes: aEnvoyer.count,
                                      recus: nouveauxDeLautreIPhone, date: Date(),
                                      aRelire: nouveauxDeLautreIPhone > 0 || recues > 0)
    }

    /// Suppression du compte (App Store 5.1.1(v)) : efface la zone « Reperes » d'iCloud, puis le fichier et les photos locales.
    /// Le local part d'abord : si iCloud échoue (hors ligne), les repères ont déjà quitté l'iPhone et l'erreur est rendue.
    func effacerTout() async throws {
        try await depot.effacerTout()
        guard Self.actif else { return }
        let db = base
        _ = try await db.modifyRecordZones(saving: [], deleting: [Self.zone])
        zonePrete = false
    }

    // MARK: Pièces

    nonisolated private static func id(_ uuid: UUID) -> CKRecord.ID { CKRecord.ID(recordName: uuid.uuidString, zoneID: zone) }
    nonisolated private static func idPhoto(_ nom: String) -> CKRecord.ID { CKRecord.ID(recordName: nom, zoneID: zone) }

    private func preparerZone(_ db: CKDatabase) async throws {
        guard !zonePrete else { return }
        _ = try await db.modifyRecordZones(saving: [CKRecordZone(zoneID: Self.zone)], deleting: [])
        zonePrete = true
    }

    private struct Distant {
        var reperes: [Repere] = []
        /// Noms de fichiers des photos déjà dans iCloud.
        var photos: Set<String> = []
    }

    /// Liste la zone sans télécharger les photos : `desiredKeys` n'inclut jamais « fichier ».
    private func lister(_ db: CKDatabase) async throws -> Distant {
        var resultat = Distant()
        var jeton: CKServerChangeToken?
        var encore = true
        let cles = Cle.reperes + [Cle.octets]
        while encore {
            let page = try await db.recordZoneChanges(inZoneWith: Self.zone, since: jeton, desiredKeys: cles, resultsLimit: nil)
            for (_, essai) in page.modificationResultsByID {
                guard let enregistrement = try? essai.get().record else { continue }
                switch enregistrement.recordType {
                case Genre.repere:
                    if let r = Self.repere(depuis: enregistrement) { resultat.reperes.append(r) }
                case Genre.photo:
                    let nom = enregistrement.recordID.recordName
                    if DepotReperes.nomPhotoValide(nom) { resultat.photos.insert(nom) }
                default: break
                }
            }
            jeton = page.changeToken
            encore = page.moreComing
        }
        return resultat
    }

    nonisolated private static func enregistrement(de r: Repere) -> CKRecord {
        let e = CKRecord(recordType: Genre.repere, recordID: id(r.id))
        e.encryptedValues[Cle.nom] = r.nom
        e.encryptedValues[Cle.icone] = r.icone.rawValue
        e.encryptedValues[Cle.note] = r.note
        e.encryptedValues[Cle.latitude] = r.position.latitude
        e.encryptedValues[Cle.longitude] = r.position.longitude
        e.encryptedValues[Cle.idsPrises] = r.idsPrises.map(\.uuidString).joined(separator: ",")
        e.encryptedValues[Cle.photos] = r.photos.joined(separator: ",")
        e.encryptedValues[Cle.cree] = r.cree
        e.encryptedValues[Cle.modifie] = r.modifie
        e.encryptedValues[Cle.passageManuel] = r.passageManuel
        e.encryptedValues[Cle.supprime] = r.supprime
        return e
    }

    nonisolated private static func repere(depuis e: CKRecord) -> Repere? {
        guard let id = UUID(uuidString: e.recordID.recordName) else { return nil }
        guard let nom: String = e.encryptedValues[Cle.nom],
              let latitude: Double = e.encryptedValues[Cle.latitude],
              let longitude: Double = e.encryptedValues[Cle.longitude],
              let cree: Date = e.encryptedValues[Cle.cree],
              let modifie: Date = e.encryptedValues[Cle.modifie] else { return nil }
        let icone: String? = e.encryptedValues[Cle.icone]
        let note: String? = e.encryptedValues[Cle.note]
        let prises: String? = e.encryptedValues[Cle.idsPrises]
        let photos: String? = e.encryptedValues[Cle.photos]
        let passage: Date? = e.encryptedValues[Cle.passageManuel]
        let supprime: Date? = e.encryptedValues[Cle.supprime]
        return Repere(id: id, nom: nom, icone: icone.flatMap(IconeRepere.init(rawValue:)) ?? .poste, note: note ?? "",
                      position: Coordonnee(latitude: latitude, longitude: longitude),
                      idsPrises: (prises ?? "").split(separator: ",").compactMap { UUID(uuidString: String($0)) },
                      photos: (photos ?? "").split(separator: ",").map(String.init).filter(DepotReperes.nomPhotoValide),
                      cree: cree, modifie: modifie, passageManuel: passage, supprime: supprime)
    }

    private func sauver(_ enregistrements: [CKRecord], _ db: CKDatabase) async throws {
        for debut in stride(from: 0, to: enregistrements.count, by: Self.lot) {
            let tranche = Array(enregistrements[debut..<min(debut + Self.lot, enregistrements.count)])
            let reponse = try await db.modifyRecords(saving: tranche, deleting: [], savePolicy: .changedKeys, atomically: false)
            // Jamais « Sauvegardé » à l'écran si un envoi a échoué : la première erreur est rendue.
            for (_, resultat) in reponse.saveResults {
                if case .failure(let erreur) = resultat { throw erreur }
            }
        }
    }

    private func retirer(_ ids: [CKRecord.ID], _ db: CKDatabase) async throws {
        for debut in stride(from: 0, to: ids.count, by: Self.lot) {
            let tranche = Array(ids[debut..<min(debut + Self.lot, ids.count)])
            let reponse = try await db.modifyRecords(saving: [], deleting: tranche, savePolicy: .changedKeys, atomically: false)
            for (_, resultat) in reponse.deleteResults {
                // Déjà absent : rien à faire.
                if case .failure(let erreur) = resultat, (erreur as? CKError)?.code != .unknownItem { throw erreur }
            }
        }
    }

    // MARK: Photos

    private func urlsLocales(de noms: Set<String>) async -> [String: URL] {
        var sortie: [String: URL] = [:]
        for nom in noms { if let url = await depot.urlPhoto(nom) { sortie[nom] = url } }
        return sortie
    }

    private func envoyerPhotos(_ urls: [String: URL], _ db: CKDatabase) async throws {
        let enregistrements = urls.map { nom, url -> CKRecord in
            let e = CKRecord(recordType: Genre.photo, recordID: Self.idPhoto(nom))
            e.encryptedValues[Cle.fichier] = CKAsset(fileURL: url)
            e.encryptedValues[Cle.octets] = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return e
        }
        try await sauver(enregistrements, db)
    }

    private func photosAbsentes(_ citees: Set<String>) async -> [String] {
        var absentes: [String] = []
        for nom in citees.sorted() {
            if await depot.urlPhoto(nom) == nil { absentes.append(nom) }
        }
        return absentes
    }

    private func rapatrierPhotos(_ noms: [String], _ db: CKDatabase) async throws -> Int {
        var recues = 0
        for debut in stride(from: 0, to: noms.count, by: Self.lot) {
            let tranche = Array(noms[debut..<min(debut + Self.lot, noms.count)])
            let lus = try await db.records(for: tranche.map(Self.idPhoto), desiredKeys: [Cle.fichier])
            for (id, essai) in lus {
                guard let r = try? essai.get() else { continue }
                let asset: CKAsset? = r.encryptedValues[Cle.fichier]
                guard let url = asset?.fileURL, let donnees = try? Data(contentsOf: url) else { continue }
                if (try? await depot.ecrirePhoto(donnees, nom: id.recordName)) != nil { recues += 1 }
            }
        }
        return recues
    }
}
