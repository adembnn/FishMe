import AVFoundation
import CloudKit
import Foundation

// PROTOTYPE R2 : écrit pour être lancé sur un Mac par Sullyvan. NON COMPILÉ par son auteur (PC Windows, pas de Swift).
// Chaque appel douteux porte « ⚠ à vérifier ». Si Xcode refuse une ligne, copie l'erreur dans RESULTATS.md : c'est une information.

enum ErreurProto: Error { case exportImpossible, aucunFichier }

/// Toutes les mesures. Écrit dans la base PUBLIQUE du conteneur d'essai (jamais celui de la vraie app).
actor Mesures {
    static let partage = Mesures()   // une seule instance : l'écran et le récepteur de notifications la partagent
    var jetons4c: [String: CKServerChangeToken] = [:]   // jeton de changements par base (test 4c)
    var vus4c: Set<String> = []                         // enregistrements 4c déjà comptés (doublons)
    let base = CKContainer.default().publicCloudDatabase   // premier conteneur de la capacité iCloud
    private let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("r2proto", isDirectory: true)
    let marqueur = "R2-proto"
    private let departements = ["94", "94", "94", "75", "77", "94", "92", "93", "94", "91"]

    init() { try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true) }

    // MARK: Fichiers d'essai

    /// Un fichier d'octets aléatoires : le quota compte des octets, le contenu n'a pas d'importance (aléatoire = pas compressible, cas défavorable).
    private func fichierAleatoire(octets: Int, nom: String) throws -> URL {
        let url = dossier.appendingPathComponent(nom)
        var donnees = Data(count: octets)
        let ok = donnees.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, octets, $0.baseAddress!) }
        guard ok == errSecSuccess else { throw ErreurProto.aucunFichier }
        try donnees.write(to: url)
        return url
    }

    private func publication(genre: String, media: URL, i: Int) -> CKRecord {
        let r = CKRecord(recordType: "Publication")
        r["auteurNom"] = "proto-\(i % 50)"
        r["genre"] = genre
        r["legende"] = "essai R2 \(i)"
        r["lieuMode"] = "departement"
        r["departement"] = departements[i % departements.count]
        r["club"] = ""
        r["creeLe"] = Date()
        r["marqueur"] = marqueur
        r["media"] = CKAsset(fileURL: media)
        return r
    }

    private func enregistrer(_ records: [CKRecord]) async throws -> Int {
        let res = try await base.modifyRecords(saving: records, deleting: [], savePolicy: .allKeys, atomically: false)
        return res.saveResults.values.filter { if case .failure = $0 { return true } else { return false } }.count
    }

    // MARK: 1. Photos (1 000 de 300 Ko)

    func ecrirePhotos(nombre: Int = 1000, journal: @Sendable (String) -> Void) async throws {
        let debut = Date()
        var echecs = 0
        var i = 0
        while i < nombre {
            let fin = min(i + 10, nombre)
            var records: [CKRecord] = []
            for k in i..<fin {
                records.append(publication(genre: "photo", media: try fichierAleatoire(octets: 300 * 1024, nom: "p\(k).jpg"), i: k))
            }
            echecs += try await enregistrer(records)
            for k in i..<fin { try? FileManager.default.removeItem(at: dossier.appendingPathComponent("p\(k).jpg")) }
            i = fin
            if i % 100 == 0 { journal("photos : \(i)/\(nombre), \(Int(Date().timeIntervalSince(debut))) s, échecs \(echecs)") }
        }
        journal("PHOTOS FINI : \(nombre) écrites en \(Int(Date().timeIntervalSince(debut))) s, \(echecs) échec(s)")
    }

    // MARK: 2. Vidéo : export 720p de 15 s, puis 100 copies

    func exporterVideo720(source: URL) async throws -> URL {
        let asset = AVURLAsset(url: source)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else { throw ErreurProto.exportImpossible }
        session.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: 15, preferredTimescale: 600))
        session.metadataItemFilter = AVMetadataItemFilter.forSharing()   // ⚠ à vérifier : retire-t-il bien les métadonnées de lieu ? Contrôle : exiftool sur la sortie.
        let sortie = dossier.appendingPathComponent("sortie720.mp4")
        try? FileManager.default.removeItem(at: sortie)
        try await session.export(to: sortie, as: .mp4)   // ⚠ à vérifier : API async récente (iOS 18 / macOS 15). Sinon exportAsynchronously.
        return sortie
    }

    func ecrireVideos(source: URL, nombre: Int = 100, journal: @Sendable (String) -> Void) async throws {
        let sortie = try await exporterVideo720(source: source)
        let taille = (try FileManager.default.attributesOfItem(atPath: sortie.path)[.size] as? Int) ?? 0
        let duree = try await AVURLAsset(url: sortie).load(.duration).seconds
        journal("VIDÉO EXPORTÉE : \(taille) octets (\(taille / 1024) Ko), durée \(String(format: "%.1f", duree)) s")
        let debut = Date()
        var echecs = 0
        var i = 0
        while i < nombre {
            let fin = min(i + 5, nombre)
            var records: [CKRecord] = []
            for k in i..<fin {
                // Copie + 16 octets aléatoires à la fin : évite qu'un éventuel dédoublonnage fausse le quota.
                let copie = dossier.appendingPathComponent("v\(k).mp4")
                try? FileManager.default.removeItem(at: copie)
                try FileManager.default.copyItem(at: sortie, to: copie)
                let h = try FileHandle(forWritingTo: copie)
                try h.seekToEnd()
                try h.write(contentsOf: try Data(contentsOf: try fichierAleatoire(octets: 16, nom: "salt.bin")))
                try h.close()
                var r = publication(genre: "video", media: copie, i: 5000 + k)
                r["dureeS"] = Int(duree.rounded())
                records.append(r)
            }
            echecs += try await enregistrer(records)
            for k in i..<fin { try? FileManager.default.removeItem(at: dossier.appendingPathComponent("v\(k).mp4")) }
            i = fin
            if i % 10 == 0 { journal("vidéos : \(i)/\(nombre), \(Int(Date().timeIntervalSince(debut))) s, échecs \(echecs)") }
        }
        journal("VIDÉOS FINI : \(nombre) écrites en \(Int(Date().timeIntervalSince(debut))) s, \(echecs) échec(s), \(taille / 1024) Ko chacune")
    }

    // MARK: 3. Lecture d'un fil de 50

    func lireFil(avecMedias: Bool, journal: @Sendable (String) -> Void) async throws {
        let q = CKQuery(recordType: "Publication", predicate: NSPredicate(format: "departement == %@", "94"))
        q.sortDescriptors = [NSSortDescriptor(key: "creeLe", ascending: false)]
        let cles: [CKRecord.FieldKey]? = avecMedias ? nil : ["auteurNom", "legende", "creeLe", "genre", "departement"]
        let t0 = Date()
        let (resultats, _) = try await base.records(matching: q, desiredKeys: cles, resultsLimit: 50)
        let dt = Date().timeIntervalSince(t0)
        var octets = 0
        var identifiants: [String] = []
        for (id, r) in resultats {
            identifiants.append(id.recordName)
            if case .success(let rec) = r, let a = rec["media"] as? CKAsset, let u = a.fileURL,
               let t = try? FileManager.default.attributesOfItem(atPath: u.path)[.size] as? Int { octets += t }
        }
        journal("FIL DE 50 \(avecMedias ? "avec médias" : "sans médias") : \(resultats.count) lus en \(String(format: "%.2f", dt)) s, médias téléchargés \(octets / 1024) Ko")
        if avecMedias == false { try await lireLikes(pour: identifiants, journal: journal) }
    }

    /// Deux likes par publication, puis une seule requête `IN` pour les compter (ce que le schéma prévoit).
    private func lireLikes(pour ids: [String], journal: @Sendable (String) -> Void) async throws {
        let likes = ids.flatMap { id in (0..<2).map { n -> CKRecord in
            let r = CKRecord(recordType: "Like", recordID: CKRecord.ID(recordName: "l-\(id)-proto\(n)"))
            r["publication"] = id; r["auteurNom"] = "proto-\(n)"; r["creeLe"] = Date(); r["marqueur"] = marqueur
            return r } }
        _ = try await enregistrer(likes)
        let q = CKQuery(recordType: "Like", predicate: NSPredicate(format: "publication IN %@", ids))   // ⚠ à vérifier : IN sur un champ texte
        let t0 = Date()
        let (res, _) = try await base.records(matching: q, resultsLimit: 400)
        journal("LIKES du fil (1 requête IN) : \(res.count) lus en \(String(format: "%.2f", Date().timeIntervalSince(t0))) s")
    }
}
