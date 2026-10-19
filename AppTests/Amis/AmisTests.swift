import CloudKit
import Core
import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import BuildChallenge

/// Collection factice : rend des cartes fixes et une image fixe.
nonisolated private struct CollectionFausse: CollectionCartes {
    var prises: [Prise]
    var png: Data?
    func cartes() async -> [Prise] { prises }
    func imagePNG(de carte: Prise) async -> Data? { png }
}

@MainActor
struct AmisTests {
    private let brochet = Espece(id: "brochet")
    private let sandre = Espece(id: "sandre")
    private let zone = CKRecordZone.ID(zoneName: "Pescedex", ownerName: CKCurrentUserDefaultName)

    private func pngAvecGPS() throws -> Data {
        let rendu = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        let image = rendu.image { c in
            UIColor.systemTeal.setFill()
            c.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        let sortie = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(sortie, UTType.png.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 48.85, kCGImagePropertyGPSLatitudeRef: "N",
                                    kCGImagePropertyGPSLongitude: 2.35, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(destination, try #require(image.cgImage), [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return sortie as Data
    }

    private func carte(_ espece: Espece = Espece(id: "brochet"), image: Data? = nil) -> CartePartagee {
        CartePartagee(id: UUID(), espece: espece.id, rarete: .rare, date: CartePartagee.moisEtAnnee(Date(timeIntervalSince1970: 1_760_000_000)), tailleCm: 62,
                      bredouille: false, departement: "94", image: image)
    }

    private func nouveauGestionnaire(service: FauxServiceAmis, prises: [Prise] = []) throws -> (GestionAmis, FileEnvoi, CacheAmis) {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let file = FileEnvoi(dossier: dossier.appendingPathComponent("file"))
        let cache = CacheAmis(conteneur: try CacheAmis.creerConteneur(enMemoire: true), dossierImages: dossier.appendingPathComponent("img"))
        let gestion = GestionAmis(service: service, cache: cache, file: file, collection: CollectionFausse(prises: prises, png: nil),
                                  especes: EspecesFaux(), configuration: ConfigurationAmis(contact: "contact@exemple.invalid"))
        return (gestion, file, cache)
    }

    // MARK: Rien d'exact ne part

    @Test func lesChampsDeLaCarteSontLesSeulsAutorises() {
        let c = carte()
        let noms = Set(Mirror(reflecting: c).children.compactMap { $0.label })
        #expect(noms == CartePartagee.champsAutorises)
    }

    @Test func leRecordNePorteQueLesClesAutorisees() throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let record = try FabriqueRecords.record(pour: carte(image: try pngAvecGPS()), zone: zone, dossierTemp: dossier)
        let cles = Set(record.allKeys())
        #expect(cles.isSubset(of: FabriqueRecords.cles))
        for cle in cles {
            let minuscule = cle.lowercased()
            #expect(!["lat", "lon", "coord", "gps", "lieu", "nom", "texte"].contains { minuscule.contains($0) })
        }
        #expect(cles.contains("zone"))
        #expect(record["zone"] as? String == "94")
    }

    @Test func lImageEnvoyeeNaPasDeGPS() throws {
        let avec = try pngAvecGPS()
        #expect(PngSansGPS.contientGPS(avec))
        let propre = try #require(PngSansGPS.nettoyer(avec))
        #expect(!PngSansGPS.contientGPS(propre))
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let record = try FabriqueRecords.record(pour: carte(image: avec), zone: zone, dossierTemp: dossier)
        let fichier = try #require((record["image"] as? CKAsset)?.fileURL)
        #expect(!PngSansGPS.contientGPS(try Data(contentsOf: fichier)))
    }

    @Test func uneImageIllisibleEstRefusee() {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(throws: ErreurAmis.imageRefusee) {
            _ = try FabriqueRecords.record(pour: carte(image: Data([1, 2, 3])), zone: zone, dossierTemp: dossier)
        }
    }

    @Test func laDateEnvoyeeEstLePremierDuMois() throws {
        let exacte = Date(timeIntervalSince1970: 1_760_000_000) // 9 oct. 2025
        let arrondie = CartePartagee.moisEtAnnee(exacte)
        var paris = Calendar(identifier: .gregorian)
        paris.timeZone = try #require(TimeZone(identifier: "Europe/Paris"))
        let c = paris.dateComponents([.year, .month, .day, .hour, .minute], from: arrondie)
        #expect(c.day == 1 && c.hour == 0 && c.minute == 0)
        #expect(c.month == 10 && c.year == 2025)
        #expect(CartePartagee.moisEtAnnee(arrondie) == arrondie)
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var ancienne = carte()
        ancienne.date = exacte
        let record = try FabriqueRecords.record(pour: ancienne, zone: zone, dossierTemp: dossier)
        #expect(record["datePrise"] as? Date == arrondie)
    }

    @Test func leRecordSeRelitSansPerte() throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let origine = carte()
        let relue = try #require(FabriqueRecords.carte(depuis: try FabriqueRecords.record(pour: origine, zone: zone, dossierTemp: dossier)))
        #expect(relue == origine)
    }

    @Test func lesCartesPartageesSontCeDuPescedexSansLExemple() async throws {
        let lieu = "La Marne · 94"
        let reelle = Prise(espece: brochet, longueurCm: 62, date: Date(), lieuFlou: lieu, cheminPhoto: "a.jpg")
        let declaree = Prise.declaree(espece: sandre, date: Date())
        let exemple = Prise(espece: brochet, date: Date(), lieuFlou: lieu, cheminPhoto: "b.jpg", exemple: true)
        let constructeur = ConstructeurCartes(collection: CollectionFausse(prises: [reelle, declaree, exemple], png: try pngAvecGPS()),
                                              especes: EspecesFaux())
        let cartes = await constructeur.cartesAPartager()
        #expect(cartes.count == 2)
        let r = try #require(cartes.first { $0.id == reelle.id })
        #expect(r.departement == "94")
        let image = try #require(r.image)
        #expect(!PngSansGPS.contientGPS(image))
        let d = try #require(cartes.first { $0.id == declaree.id })
        #expect(d.image == nil && d.departement == nil && d.rarete == .nonMesuree)
    }

    // MARK: Envoi hors ligne

    @Test func rienNePartAvantLInvitation() async throws {
        let service = FauxServiceAmis()
        let (gestion, _, _) = try nouveauGestionnaire(service: service, prises: [Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "a.jpg")])
        await gestion.synchroniserMesCartes()
        #expect(await service.tentatives == 0)
    }

    @Test func lEnvoiHorsLigneEstRejoueAuRetour() async throws {
        let prise = Prise(espece: brochet, longueurCm: 60, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "a.jpg")
        let service = FauxServiceAmis(horsLigne: true)
        let (gestion, file, _) = try nouveauGestionnaire(service: service, prises: [prise])
        await file.activerPartage()
        await gestion.synchroniserMesCartes()
        #expect(gestion.cartesEnAttente == 1)
        #expect(await service.publiees.isEmpty)
        #expect(gestion.message == .horsLigne)

        await service.regler(horsLigne: false)
        await gestion.synchroniserMesCartes()
        #expect(gestion.cartesEnAttente == 0)
        #expect(await service.publiees.map(\.id) == [prise.id])
        // Une carte déjà envoyée ne repart pas.
        await gestion.synchroniserMesCartes()
        #expect(await service.publiees.count == 1)
    }

    @Test func laFileSurvitAUnRedemarrage() async throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let premiere = FileEnvoi(dossier: dossier)
        await premiere.mettreEnAttente([carte(image: try #require(PngSansGPS.nettoyer(try pngAvecGPS())))])
        let seconde = FileEnvoi(dossier: dossier)
        let relue = await seconde.enAttente()
        #expect(relue.count == 1)
        #expect(relue.first?.image != nil)
    }

    // MARK: Cache, règle 1.2

    @Test func leCacheGardeLesCartesDesAmisHorsLigne() async throws {
        let ami = Ami(id: "lea", nom: "Léa", sens: .recu)
        let service = FauxServiceAmis(recues: [CollectionAmi(ami: ami, cartes: [carte()])])
        let (gestion, _, _) = try nouveauGestionnaire(service: service)
        await gestion.actualiser()
        #expect(gestion.collections.first?.cartes.count == 1)
        await service.regler(horsLigne: true)
        await gestion.actualiser()
        #expect(gestion.collections.first?.cartes.count == 1)
        #expect(gestion.message == .horsLigne)
    }

    @Test func bloquerUnAmiMasqueSesCartesMemeSiIlReviens() async throws {
        let ami = Ami(id: "lea", nom: "Léa", sens: .recu)
        let service = FauxServiceAmis(recues: [CollectionAmi(ami: ami, cartes: [carte()])])
        let (gestion, _, cache) = try nouveauGestionnaire(service: service)
        await gestion.actualiser()
        await gestion.bloquer(ami)
        #expect(await service.quittes == ["lea"])
        #expect(gestion.amis.isEmpty)
        // Il invite de nouveau : le blocage tient.
        await service.regler(recues: [CollectionAmi(ami: ami, cartes: [carte()])])
        await gestion.actualiser()
        #expect(gestion.collections.isEmpty)
        #expect(await cache.collections().isEmpty)
    }

    @Test func retirerUnAmiInviteLeRetireDuPartage() async throws {
        let ami = Ami(id: "malo", nom: "Malo", sens: .invite)
        let service = FauxServiceAmis(invites: [ami])
        let (gestion, _, _) = try nouveauGestionnaire(service: service)
        await gestion.actualiser()
        #expect(gestion.amis.map(\.id) == ["malo"])
        await gestion.retirer(ami)
        #expect(await service.retires == ["malo"])
        #expect(gestion.amis.isEmpty)
    }

    @Test func supprimerMesCartesVideLaFileEtArreteLePartage() async throws {
        let prise = Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "a.jpg")
        let service = FauxServiceAmis()
        let (gestion, file, _) = try nouveauGestionnaire(service: service, prises: [prise])
        await file.activerPartage()
        await gestion.synchroniserMesCartes()
        await gestion.supprimerMesCartesPartagees()
        #expect(await service.zoneSupprimee)
        #expect(await file.partageActif == false)
        #expect(await file.envoyees.isEmpty)
    }

    @Test func accepterUneInvitationProposeDInviterEnRetour() async throws {
        let service = FauxServiceAmis()
        let (gestion, _, _) = try nouveauGestionnaire(service: service)
        gestion.invitationRecue = InvitationRecue(nomAmi: "Karim", metadata: nil)
        await gestion.accepterLInvitation()
        #expect(await service.acceptees == ["ami-Karim"])
        #expect(gestion.invitationRecue == nil)
        #expect(gestion.proposerInvitationEnRetour)
        #expect(gestion.amis.map(\.nom) == ["Karim"])
    }

    @Test func sansICloudUnMessageEtRienNePart() async throws {
        let service = FauxServiceAmis(compte: .indisponible)
        let (gestion, file, _) = try nouveauGestionnaire(service: service)
        await file.activerPartage()
        await gestion.actualiser()
        #expect(gestion.message == .iCloudIndisponible)
        #expect(await service.tentatives == 0)
    }

    @Test func leSignalementPartVersLeContactPublieSansCoordonnee() throws {
        let ami = Ami(id: "lea", nom: "Léa", sens: .recu)
        let c = carte()
        let url = try #require(Signalement.url(contact: "contact@exemple.invalid", ami: ami, carte: c))
        #expect(url.scheme == "mailto")
        let texte = url.absoluteString.removingPercentEncoding ?? ""
        #expect(texte.contains("contact@exemple.invalid"))
        #expect(texte.contains(c.id.uuidString))
        #expect(!texte.lowercased().contains("lat"))
    }

    // MARK: Signaler un ami, nom confirmé (L21)

    @Test func signalerUnAmiLeMasqueToutDeSuiteSansCouperLePartage() async throws {
        let id = "test-masque-\(UUID().uuidString)"
        defer { ListeBlocages.partage.debloquer(id) }
        let ami = Ami(id: id, nom: NomAmi.anonyme, sens: .recu)
        let service = FauxServiceAmis(recues: [CollectionAmi(ami: ami, cartes: [carte()])])
        let (gestion, _, _) = try nouveauGestionnaire(service: service)
        await gestion.actualiser()
        #expect(gestion.amis.contains { $0.id == id })
        gestion.masquerApresSignalement(ami)
        #expect(!gestion.amis.contains { $0.id == id })
        #expect(gestion.collections.isEmpty)
        // Ce n'est pas un blocage : le partage n'est pas quitté.
        #expect(await service.quittes.isEmpty)
        // Et le masquage tient à l'actualisation suivante.
        await gestion.actualiser()
        #expect(!gestion.amis.contains { $0.id == id })
    }

    @Test func laCleDeBlocageEstLIdentifiantPublicSeulementPourUnSurnomConfirme() {
        #expect(GestionAmis.cleDeBlocage(Ami(id: "_abc", nom: "Gros-Brochet", sens: .recu)) == "p-gros-brochet")
        #expect(GestionAmis.cleDeBlocage(Ami(id: "_abc", nom: "Un ami", sens: .recu)) == "_abc")
        #expect(GestionAmis.cleDeBlocage(Ami(id: "_abc", nom: "Léa Dupont", sens: .recu)) == "_abc")
    }

    @Test func leSignalementDUneCartePorteLeMotifSansCoordonnee() throws {
        let ami = Ami(id: "lea", nom: "Léa", sens: .recu)
        let c = carte()
        let url = try #require(Signalement.url(contact: "contact@exemple.invalid", ami: ami, carte: c, motif: .coinExact))
        let texte = url.absoluteString.removingPercentEncoding ?? ""
        #expect(texte.contains("Coin de pêche exact révélé") && texte.contains(c.id.uuidString))
        #expect(!texte.lowercased().contains("lat"))
    }

    // MARK: Aides du dossier

    @Test func leDepartementSeLitApresLePointMedian() {
        #expect(JetonAmis.departement(depuisLieuFlou: "La Marne · 94")?.code == "94")
        #expect(JetonAmis.departement(depuisLieuFlou: "La Marne") == nil)
        #expect(JetonAmis.departement(depuisLieuFlou: nil) == nil)
    }

    // MARK: Mots interdits

    @Test func lesTextesAffichesSansMotInterdit() throws {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("App/Amis")
        let fichiers = try FileManager.default.contentsOfDirectory(at: dossier, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }
        let interdits = ["poké", "poke", "bon spot", "meilleur coin", "meilleures chances", "garanti"]
        for f in fichiers {
            let texte = try String(contentsOf: f, encoding: .utf8).lowercased()
            for mot in interdits { #expect(!texte.contains(mot), "\(mot) dans \(f.lastPathComponent)") }
        }
    }
}
