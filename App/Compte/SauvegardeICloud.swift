import CloudKit
import Core
import Foundation

/// État du compte iCloud de l'iPhone. Le compte FishMe, c'est l'identifiant Apple : pas de mot de passe, pas de serveur à nous.
nonisolated enum EtatICloud: Sendable, Equatable { case disponible, absent, restreint, inconnu }

/// Ce que montre « Mon compte » après une synchro.
nonisolated struct BilanSauvegarde: Sendable, Equatable {
    /// Cartes du Pescedex maintenant dans iCloud.
    var cartes: Int
    /// Sorties terminées sauvegardées.
    var sorties: Int
    /// Cartes revenues d'iCloud à cette synchro (nouvel iPhone, ou carte prise sur un autre).
    var rapatriees: Int
    var date: Date
}

nonisolated protocol ServiceSauvegarde: Sendable {
    func etatCompte() async -> EtatICloud
    func synchroniser() async throws -> BilanSauvegarde
    func effacer() async throws
}

/// Sauvegarde des cartes, des photos (déjà sans GPS) et du profil dans la base privée iCloud du pêcheur, zone « Sauvegarde ».
/// Personne d'autre ne la lit : ni nous, ni MWM (la base privée n'apparaît pas dans la console). Rien ne s'efface par une
/// synchro : chaque côté reçoit ce qui lui manque. La base SwiftData reste locale (`cloudKitDatabase: .none`).
actor SauvegardeICloud: ServiceSauvegarde {
    static let identifiantConteneur = "iCloud.ai.mwm.build.challenge.team.01"
    /// Vrai après « Effacer ma sauvegarde iCloud » : plus de sauvegarde automatique tant que le pêcheur ne touche pas
    /// « Sauvegarder maintenant ».
    nonisolated static let cleCoupee = "compte.sauvegardeCoupee"
    private static let zone = CKRecordZone.ID(zoneName: "Sauvegarde", ownerName: CKCurrentUserDefaultName)
    private static let lot = 100

    private let depot: DepotCartes
    private var conteneur: CKContainer?
    private var zonePrete = false

    init(depot: DepotCartes) {
        self.depot = depot
    }

    /// Créé au premier usage seulement : rien ne touche iCloud au lancement si le pêcheur n'a pas de compte.
    private var base: CKDatabase {
        if let conteneur { return conteneur.privateCloudDatabase }
        let nouveau = CKContainer(identifier: Self.identifiantConteneur)
        conteneur = nouveau
        return nouveau.privateCloudDatabase
    }

    func etatCompte() async -> EtatICloud {
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

    func synchroniser() async throws -> BilanSauvegarde {
        UserDefaults.standard.set(false, forKey: Self.cleCoupee)
        let db = base
        try await preparerZone(db)
        let distant = try await lister(db)

        // Cartes et bredouilles : on envoie ce qui manque à iCloud, on rapatrie ce qui manque à l'iPhone.
        let locaux = await depot.identifiants()
        let planCartes = FusionSauvegarde.plan(locaux: locaux.cartes, distants: distant.cartes)
        let planBredouilles = FusionSauvegarde.plan(locaux: locaux.bredouilles, distants: distant.bredouilles)
        try await envoyer(cartes: Set(planCartes.aEnvoyer), bredouilles: Set(planBredouilles.aEnvoyer), db)
        let rapatriees = try await rapatrier(cartes: planCartes.aRapatrier, bredouilles: planBredouilles.aRapatrier, db)

        // Profil : un seul enregistrement, fusionné puis écrit des deux côtés.
        // Le fichier des sessions et les réglages vivent sur le fil principal (comme `SuiviSession`).
        let local = await MainActor.run { ProfilLocal().lire() }
        let fusion = FusionSauvegarde.fusionner(local: local, distant: distant.profil ?? ProfilSauvegarde())
        await MainActor.run { ProfilLocal().ecrire(fusion) }
        let enregistrement = distant.enregistrementProfil ?? CKRecord(recordType: Type.profil, recordID: Self.idProfil)
        enregistrement["json"] = try JSONEncoder().encode(fusion) as NSData
        _ = try await db.modifyRecords(saving: [enregistrement], deleting: [], savePolicy: .changedKeys, atomically: false)

        return BilanSauvegarde(cartes: Set(locaux.cartes).union(distant.cartes).count, sorties: fusion.sorties.count,
                               rapatriees: rapatriees, date: Date())
    }

    /// Efface toute la sauvegarde iCloud (la zone entière). Les cartes restent sur cet iPhone.
    func effacer() async throws {
        let db = base
        _ = try await db.modifyRecordZones(saving: [], deleting: [Self.zone])
        zonePrete = false
        UserDefaults.standard.set(true, forKey: Self.cleCoupee)
        UserDefaults.standard.removeObject(forKey: "compte.dernierProfil")
    }

    // MARK: Pièces

    private enum Type {
        static let carte = "Carte"
        static let bredouille = "Bredouille"
        static let profil = "Profil"
    }

    private static let idProfil = CKRecord.ID(recordName: "profil", zoneID: zone)

    private static func id(_ uuid: UUID) -> CKRecord.ID { CKRecord.ID(recordName: uuid.uuidString, zoneID: zone) }

    private func preparerZone(_ db: CKDatabase) async throws {
        guard !zonePrete else { return }
        _ = try await db.modifyRecordZones(saving: [CKRecordZone(zoneID: Self.zone)], deleting: [])
        zonePrete = true
    }

    private struct Distant {
        var cartes: [UUID] = []
        var bredouilles: [UUID] = []
        var profil: ProfilSauvegarde?
        var enregistrementProfil: CKRecord?
    }

    /// Liste la zone sans télécharger les photos (`desiredKeys` sans « photo ») : pas d'index de requête à créer dans la console.
    private func lister(_ db: CKDatabase) async throws -> Distant {
        var resultat = Distant()
        var jeton: CKServerChangeToken?
        var encore = true
        while encore {
            let page = try await db.recordZoneChanges(inZoneWith: Self.zone, since: jeton,
                                                      desiredKeys: ["origine", "json"], resultsLimit: nil)
            for (_, essai) in page.modificationResultsByID {
                guard let enregistrement = try? essai.get().record else { continue }
                switch enregistrement.recordType {
                case Type.carte:
                    if let uuid = UUID(uuidString: enregistrement.recordID.recordName) { resultat.cartes.append(uuid) }
                case Type.bredouille:
                    if let uuid = UUID(uuidString: enregistrement.recordID.recordName) { resultat.bredouilles.append(uuid) }
                case Type.profil:
                    resultat.enregistrementProfil = enregistrement
                    if let json = enregistrement["json"] as? Data {
                        resultat.profil = try? JSONDecoder().decode(ProfilSauvegarde.self, from: json)
                    }
                default: break
                }
            }
            jeton = page.changeToken
            encore = page.moreComing
        }
        return resultat
    }

    private func envoyer(cartes: Set<UUID>, bredouilles: Set<UUID>, _ db: CKDatabase) async throws {
        guard !cartes.isEmpty || !bredouilles.isEmpty else { return }
        var aSauver: [CKRecord] = []
        for carte in await depot.detaillees() where cartes.contains(carte.prise.id) {
            aSauver.append(await enregistrement(de: carte))
        }
        for b in await depot.bredouilles() where bredouilles.contains(b.id) {
            let r = CKRecord(recordType: Type.bredouille, recordID: Self.id(b.id))
            r["debut"] = b.debut as NSDate
            r["fin"] = b.fin.map { $0 as NSDate }
            r["lieuFlou"] = b.lieuFlou as NSString?
            r["conditions"] = b.conditions.flatMap { try? JSONEncoder().encode($0) } as NSData?
            aSauver.append(r)
        }
        for debut in stride(from: 0, to: aSauver.count, by: Self.lot) {
            let tranche = Array(aSauver[debut..<min(debut + Self.lot, aSauver.count)])
            let reponse = try await db.modifyRecords(saving: tranche, deleting: [], savePolicy: .changedKeys, atomically: false)
            // Une carte refusée (réseau coupé au milieu) repartira à la prochaine synchro : on ne bloque pas les autres.
            _ = reponse
        }
    }

    /// Champs d'une carte : jamais de coordonnée, seulement le lieu flou (cours d'eau et département) déjà gardé sur l'iPhone.
    private func enregistrement(de carte: CarteDetaillee) async -> CKRecord {
        let p = carte.prise
        let r = CKRecord(recordType: Type.carte, recordID: Self.id(p.id))
        r["especeId"] = p.espece.id as NSString
        r["codeSandre"] = p.espece.codeSandre as NSString?
        r["origine"] = p.origine.rawValue as NSString
        r["longueurCm"] = p.longueurCm.map { NSNumber(value: $0) }
        r["mesure"] = p.mesure?.rawValue as NSString?
        r["stade"] = p.stade?.rawValue as NSString?
        r["date"] = p.date as NSDate
        r["lieuFlou"] = p.lieuFlou as NSString?
        r["gardee"] = NSNumber(value: p.gardee)
        r["exemple"] = NSNumber(value: p.exemple)
        r["conditions"] = carte.conditions.flatMap { try? JSONEncoder().encode($0) } as NSData?
        r["dureeSecondes"] = carte.dureeSecondes.map { NSNumber(value: $0) }
        if let url = await depot.urlPhoto(de: p) { r["photo"] = CKAsset(fileURL: url) }
        return r
    }

    private func rapatrier(cartes: [UUID], bredouilles: [UUID], _ db: CKDatabase) async throws -> Int {
        var revenues = 0
        let ids = cartes.map(Self.id) + bredouilles.map(Self.id)
        for debut in stride(from: 0, to: ids.count, by: Self.lot) {
            let tranche = Array(ids[debut..<min(debut + Self.lot, ids.count)])
            let lus = try await db.records(for: tranche)
            for (_, essai) in lus {
                guard let r = try? essai.get() else { continue }
                if r.recordType == Type.carte, let carte = Self.carte(depuis: r) {
                    let photo = (r["photo"] as? CKAsset)?.fileURL.flatMap { try? Data(contentsOf: $0) }
                    try await depot.importer(carte, photo: photo)
                    revenues += 1
                } else if r.recordType == Type.bredouille, let uuid = UUID(uuidString: r.recordID.recordName),
                          let debut = r["debut"] as? Date {
                    let conditions = (r["conditions"] as? Data).flatMap { try? JSONDecoder().decode(Conditions.self, from: $0) }
                    try await depot.importer(bredouille: CarteBredouille(id: uuid, debut: debut, fin: r["fin"] as? Date,
                                                                         lieuFlou: r["lieuFlou"] as? String, conditions: conditions))
                }
            }
        }
        return revenues
    }

    private static func carte(depuis r: CKRecord) -> CarteDetaillee? {
        guard let uuid = UUID(uuidString: r.recordID.recordName),
              let especeId = r["especeId"] as? String,
              let date = r["date"] as? Date else { return nil }
        let prise = Prise(id: uuid, espece: Espece(id: especeId, codeSandre: r["codeSandre"] as? String),
                          origine: (r["origine"] as? String).flatMap(OrigineCarte.init(rawValue:)) ?? .priseReelle,
                          longueurCm: (r["longueurCm"] as? NSNumber)?.doubleValue,
                          mesure: (r["mesure"] as? String).flatMap(MethodeMesure.init(rawValue:)),
                          stade: (r["stade"] as? String).flatMap(StadeAnguille.init(rawValue:)),
                          date: date, lieuFlou: r["lieuFlou"] as? String, cheminPhoto: nil,
                          gardee: (r["gardee"] as? NSNumber)?.boolValue ?? false,
                          exemple: (r["exemple"] as? NSNumber)?.boolValue ?? false)
        let conditions = (r["conditions"] as? Data).flatMap { try? JSONDecoder().decode(Conditions.self, from: $0) }
        return CarteDetaillee(prise: prise, conditions: conditions, dureeSecondes: (r["dureeSecondes"] as? NSNumber)?.doubleValue)
    }
}
