import CloudKit
import Core
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import BuildChallenge

/// Tests du lot L22 (clubs dans CloudKit). Écrits sans Mac : NON EXÉCUTÉS au moment de l'écriture.
/// Aucun test n'appelle iCloud : tout passe par `FauxServiceClubs` et `FauxServiceProfil`.

nonisolated private final class MemoireClubFausse: MemoireProfil, @unchecked Sendable {
    var id: String?
    init(_ id: String?) { self.id = id }
    func idProfil() -> String? { id }
    func surnom() -> String? { id.map(GestionClubs.surnomTronque) }
    func retenir(id: String, surnom: String) { self.id = id }
    func oublier() { id = nil }
}

nonisolated private final class DrapeauxFaux: DrapeauxMigration, @unchecked Sendable {
    var etats: [UUID: EtatMigrationClub] = [:]
    var global = false
    func etat(de club: UUID) -> EtatMigrationClub? { etats[club] }
    func fixer(_ etat: EtatMigrationClub, pour club: UUID) { etats[club] = etat }
    var termine: Bool {
        get { global }
        set { global = newValue }
    }
}

private let horloge: @Sendable () -> Date = { Date(timeIntervalSince1970: 1_800_000_000) }

@MainActor
struct ClubEnLigneTests {
    // MARK: Aides

    private func profils() -> FauxServiceProfil {
        FauxServiceProfil(profils: [
            ProfilModele(id: "p-adem", surnom: "Adem", avatar: nil, creeLe: horloge()),
            ProfilModele(id: "p-titouan", surnom: "Titouan", avatar: nil, creeLe: horloge()),
            ProfilModele(id: "p-lea", surnom: "Léa", avatar: nil, creeLe: horloge()),
        ])
    }

    /// Un « iPhone » : sa gestion, son identité, ses réglages de blocage. Tous partagent le même faux CloudKit.
    private func iPhone(_ moi: String?, service: FauxServiceClubs, profils: FauxServiceProfil,
                        filtre: any FiltreMots = AucunFiltre()) -> GestionClubs {
        let u = UUID().uuidString
        return GestionClubs(service: service, profils: profils, memoire: MemoireClubFausse(moi), cache: CacheClubsMemoire(),
                            blocages: BlocagesProfils(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
                            masquees: CartesMasquees(cle: "t.cm.\(u)"), filtre: filtre, maintenant: horloge)
    }

    private func carte(_ id: String, espece: String = "Brochet", taille: Double? = 62, departement: String? = "94") -> CarteAPartager {
        CarteAPartager(id: id, titre: espece, png: Data([0x89, 0x50, 0x4E, 0x47]), espece: espece, rarete: .rare, tailleCm: taille,
                       departement: departement)
    }

    private func imageAvecGPS() throws -> Data {
        let contexte = try #require(CGContext(data: nil, width: 1000, height: 600, bitsPerComponent: 8, bytesPerRow: 0,
                                              space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        contexte.setFillColor(red: 0, green: 0.4, blue: 0.8, alpha: 1)
        contexte.fill(CGRect(x: 0, y: 0, width: 1000, height: 600))
        let image = try #require(contexte.makeImage())
        let sortie = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 48.82, kCGImagePropertyGPSLatitudeRef: "N",
                                    kCGImagePropertyGPSLongitude: 2.41, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return sortie as Data
    }

    // MARK: Lien

    @Test func leLienDeClubFaitUnAllerRetour() throws {
        let id = UUID().uuidString
        let url = try #require(LienClub.url(clubID: id))
        #expect(url.absoluteString == "fishme://club/\(id)")
        #expect(LienClub.clubID(depuis: url) == id)
    }

    @Test func unLienQuiNEstPasUnClubEstRefuse() throws {
        let ligne1 = try #require(URL(string: "fishme://ami/p-gros-brochet"))
        #expect(LienClub.clubID(depuis: ligne1) == nil)
        let ligne2 = try #require(URL(string: "fishme://club/pas-un-uuid"))
        #expect(LienClub.clubID(depuis: ligne2) == nil)
        let ligne3 = try #require(URL(string: "https://club/\(UUID().uuidString)"))
        #expect(LienClub.clubID(depuis: ligne3) == nil)
        #expect(LienClub.url(clubID: "pas-un-uuid") == nil)
    }

    @Test func unLienColleAvecDesEspacesSeLit() {
        let id = UUID().uuidString
        #expect(LienClub.clubID(depuis: "  fishme://club/\(id)\n") == id)
        #expect(LienClub.clubID(depuis: "bonjour") == nil)
    }

    @Test func leRelaisGardeLeLienJusquAuSolde() throws {
        let relais = RelaisLienClub()
        let id = UUID().uuidString
        let ligne4 = try #require(LienClub.url(clubID: id))
        #expect(relais.recevoir(ligne4))
        #expect(relais.enAttente == id)
        relais.solder()
        #expect(relais.enAttente == nil)
        let ligne5 = try #require(URL(string: "fishme://pro"))
        #expect(!relais.recevoir(ligne5))
    }

    // MARK: Règles

    private func club(fondateur: String = "p-adem", retires: [String] = [], ferme: Bool = false) -> Club {
        Club(id: UUID().uuidString, nom: "Les brochets du 94", poissonId: "brochet", image: nil, fondateur: fondateur,
             retires: retires, ferme: ferme, creeLe: horloge())
    }

    private func membre(_ profil: String, dans club: Club, role: RoleMembre = .membre, depuis: TimeInterval = 0) -> Membre {
        Membre(id: Membre.identifiant(club: club.id, profil: profil), club: club.id, profil: profil, role: role,
               depuis: Date(timeIntervalSince1970: 1_800_000_000 + depuis))
    }

    @Test func unClubFermeNeSeRejointPas() {
        let c = club(ferme: true)
        #expect(RegleAdhesion.verifier(club: c, membres: [], profil: "p-lea") == .clubFerme)
    }

    @Test func unMembreEcarteNeRevientPas() {
        let c = club(retires: ["p-lea"])
        let liste = [membre("p-adem", dans: c, role: .fondateur)]
        #expect(RegleAdhesion.verifier(club: c, membres: liste, profil: "p-lea") == .ecarte)
    }

    @Test func unClubSansFondateurNAdmetPlusPersonne() {
        let c = club()
        // Le fondateur a quitté : seule Léa reste.
        let liste = [membre("p-lea", dans: c)]
        #expect(c.etat(membres: liste) == .sansFondateur)
        #expect(RegleAdhesion.verifier(club: c, membres: liste, profil: "p-titouan") == .sansFondateur)
        // Léa, déjà membre, n'est pas refusée.
        #expect(RegleAdhesion.verifier(club: c, membres: liste, profil: "p-lea") == nil)
    }

    @Test func unClubActifAdmetUnNouveau() {
        let c = club()
        let liste = [membre("p-adem", dans: c, role: .fondateur)]
        #expect(c.etat(membres: liste) == .actif)
        #expect(RegleAdhesion.verifier(club: c, membres: liste, profil: "p-lea") == nil)
    }

    @Test func leFondateurSeulFermeLeClubLesAutresQuittent() {
        let c = club()
        let seul = [membre("p-adem", dans: c, role: .fondateur)]
        #expect(RegleAdhesion.sortie(club: c, membres: seul, profil: "p-adem") == .fermer)
        let deux = seul + [membre("p-lea", dans: c)]
        #expect(RegleAdhesion.sortie(club: c, membres: deux, profil: "p-adem") == .quitter)
        #expect(RegleAdhesion.sortie(club: c, membres: deux, profil: "p-lea") == .quitter)
        // Les autres sont tous écartés : le fondateur est seul de fait.
        let ecarte = club(retires: ["p-lea"])
        let liste = [membre("p-adem", dans: ecarte, role: .fondateur), membre("p-lea", dans: ecarte)]
        #expect(RegleAdhesion.sortie(club: ecarte, membres: liste, profil: "p-adem") == .fermer)
    }

    @Test func seulLeFondateurActifPeutEcarter() {
        let c = club()
        let liste = [membre("p-adem", dans: c, role: .fondateur), membre("p-lea", dans: c)]
        #expect(RegleAdhesion.peutEcarter(club: c, membres: liste, moi: "p-adem", cible: "p-lea"))
        #expect(!RegleAdhesion.peutEcarter(club: c, membres: liste, moi: "p-lea", cible: "p-adem"))
        #expect(!RegleAdhesion.peutEcarter(club: c, membres: liste, moi: "p-adem", cible: "p-adem"))
        // Fondateur parti : plus personne n'écarte.
        let sans = [membre("p-lea", dans: c)]
        #expect(!RegleAdhesion.peutEcarter(club: c, membres: sans, moi: "p-adem", cible: "p-lea"))
    }

    @Test func lesMembresVisiblesSansLesEcartesDansLOrdreDArrivee() {
        let c = club(retires: ["p-lea"])
        let liste = [membre("p-titouan", dans: c, depuis: 20), membre("p-lea", dans: c, depuis: 10),
                     membre("p-adem", dans: c, role: .fondateur, depuis: 0)]
        #expect(RegleAdhesion.visibles(liste, club: c).map(\.profil) == ["p-adem", "p-titouan"])
    }

    @Test func leRecordEstLaPlusGrandeTaille() {
        func c(_ id: String, _ taille: Double?) -> CartePartageeClub {
            CartePartageeClub(id: id, club: "c", carteID: id, auteur: "p-adem", espece: "Brochet", rarete: nil, tailleCm: taille,
                              departement: "", image: nil, creeLe: horloge())
        }
        #expect(RecordDuClub.meilleure([c("a", 40), c("b", 74), c("c", nil)])?.id == "b")
        #expect(RecordDuClub.meilleure([c("a", nil)]) == nil)
        #expect(RecordDuClub.meilleure([]) == nil)
    }

    @Test func leLieuNeDepasseJamaisLeDepartement() {
        #expect(LieuClub.departement("94") == "94")
        #expect(LieuClub.departement(" 2a ") == "2A")
        #expect(LieuClub.departement("971") == "971")
        #expect(LieuClub.departement("Paris") == "")
        #expect(LieuClub.departement("La Marne · 94") == "")
        #expect(LieuClub.departement("48.82,2.41") == "")
        #expect(LieuClub.departement(nil) == "")
    }

    // MARK: Enregistrements CloudKit

    @Test func lEnregistrementClubSuitLeSchemaDeR2() throws {
        let c = club(retires: ["p-lea"])
        let record = try FabriqueRecordsClub.recordClub(c, dossierTemp: FileManager.default.temporaryDirectory.appendingPathComponent("t-club"))
        #expect(record.recordType == "Club")
        #expect(record.recordID.recordName == c.id)
        #expect(Set(record.allKeys()).isSubset(of: FabriqueRecordsClub.clesClub))
        let relu = try #require(FabriqueRecordsClub.club(depuis: record))
        #expect(relu.fondateur == "p-adem" && relu.retires == ["p-lea"] && !relu.ferme && relu.nom == c.nom)
    }

    @Test func lAdhesionPorteUnIdentifiantDeterministe() throws {
        let c = club()
        let m = membre("p-lea", dans: c)
        #expect(m.id == "m-\(c.id)-p-lea")
        let record = FabriqueRecordsClub.recordMembre(m)
        #expect(Set(record.allKeys()).isSubset(of: FabriqueRecordsClub.clesMembre))
        #expect(FabriqueRecordsClub.membre(depuis: record) == m)
    }

    @Test func uneCarteDeClubEstUnePublicationSansLieuExact() throws {
        let c = club()
        let carte = CartePartageeClub(
            id: CartePartageeClub.identifiant(club: c.id, carte: "abc"), club: c.id, carteID: "abc", auteur: "p-lea", espece: "Brochet",
            rarete: .rare, tailleCm: 62, departement: "94", image: try ImageSansGPS.nettoyer(try imageAvecGPS()), creeLe: horloge())
        let record = try FabriqueRecordsClub.recordCarte(carte, dossierTemp: FileManager.default.temporaryDirectory.appendingPathComponent("t-carte"))
        #expect(record.recordType == "Publication")
        #expect(record.recordID.recordName == "pc-\(c.id)-abc")
        #expect(Set(record.allKeys()).isSubset(of: FabriqueRecordsClub.clesCarte))
        #expect(record["club"] as? String == c.id)
        #expect(record["lieuMode"] as? String == "departement")
        #expect(record["departement"] as? String == "94")
        for cle in record.allKeys() {
            let minuscule = cle.lowercased()
            #expect(!minuscule.contains("lat") && !minuscule.contains("lon") && !minuscule.contains("gps") && !minuscule.contains("location"))
        }
        // Le média écrit n'a aucun GPS.
        let asset = try #require(record["media"] as? CKAsset)
        let donnees = try Data(contentsOf: try #require(asset.fileURL))
        #expect(!ImageSansGPS.contientGPS(donnees))
        let relue = try #require(FabriqueRecordsClub.carte(depuis: record))
        #expect(relue.carteID == "abc" && relue.auteur == "p-lea" && relue.rarete == .rare && relue.tailleCm == 62)
    }

    @Test func sansDepartementLeLieuEstAucun() throws {
        let carte = CartePartageeClub(id: "pc-c-x", club: "c", carteID: "x", auteur: "p-lea", espece: "Perche", rarete: nil, tailleCm: nil,
                                      departement: "", image: nil, creeLe: horloge())
        let record = try FabriqueRecordsClub.recordCarte(carte, dossierTemp: FileManager.default.temporaryDirectory.appendingPathComponent("t-carte2"))
        #expect(record["lieuMode"] as? String == "aucun")
        #expect(record["departement"] as? String == "")
    }

    @Test func unePublicationOrdinaireDuFilNEstPasUneCarteDeClub() {
        let record = CKRecord(recordType: "Publication", recordID: CKRecord.ID(recordName: UUID().uuidString))
        record["club"] = "c1"
        record["auteurNom"] = "p-lea"
        record["creeLe"] = horloge()
        #expect(FabriqueRecordsClub.carte(depuis: record) == nil)
    }

    @Test func leChatDeClubRecoitLesAutresMembresSansLesEcartes() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let c = iPhone("p-titouan", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        #expect(await c.rejoindre(clubID: cree.id))
        await a.charger()
        var pourChat = a.clubsPourChat()
        #expect(pourChat.count == 1 && pourChat[0].jeSuisFondateur)
        #expect(pourChat[0].membres.map(\.profil).sorted() == ["p-lea", "p-titouan"])
        #expect(pourChat[0].membres.first { $0.profil == "p-lea" }?.surnom == "Léa")
        let ligne6 = try #require(a.club(id: cree.id))
        #expect(await a.ecarter("p-lea", de: ligne6))
        pourChat = a.clubsPourChat()
        #expect(pourChat[0].membres.map(\.profil) == ["p-titouan"])
        // Côté membre : il n'est pas fondateur.
        await c.charger()
        #expect(c.clubsPourChat().first?.jeSuisFondateur == false)
    }

    @Test func leSignalementNePorteQueLesChampsDuSchema() {
        let record = FabriqueRecordsClub.recordSignalement(cible: "pc-c-x", typeCible: "publication", motif: .spam, par: "p-adem", le: horloge())
        #expect(Set(record.allKeys()).isSubset(of: FabriqueRecordsClub.clesSignalement))
    }

    // MARK: Images

    @Test func laPhotoDuClubPartEnJPEGSansGPSEtPasTropGrande() throws {
        let originale = try imageAvecGPS()
        #expect(ImageSansGPS.contientGPS(originale))
        let propre = try ImageClubJPEG.preparer(originale)
        #expect(!ImageSansGPS.contientGPS(propre))
        #expect(!ImageClubJPEG.contientMetadonnees(propre))
        let source = try #require(CGImageSourceCreateWithData(propre as CFData, nil))
        let proprietes = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        let largeur = proprietes[kCGImagePropertyPixelWidth] as? Int ?? 0
        #expect(largeur > 0 && largeur <= ImageClubJPEG.cote)
    }

    @Test func uneImageIllisibleEstRefusee() {
        #expect(throws: ErreurClub.imageRefusee) { try ImageClubJPEG.preparer(Data([1, 2, 3])) }
    }

    // MARK: Création, lien, adhésion (deux iPhones)

    @Test func unClubCreeParAEstRejointParB() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-titouan", service: service, profils: p)

        let cree = try #require(await a.creer(nom: "Les brochets du 94", poissonId: "brochet", photo: nil))
        #expect(cree.fondateur == "p-adem")
        #expect(a.jeSuisFondateur(de: cree))
        let lien = try #require(LienClub.url(clubID: cree.id))

        // B ouvre le lien : la feuille montre le nom et un membre.
        let id = try #require(LienClub.clubID(depuis: lien))
        guard case .success(let apercu) = await b.apercu(clubID: id) else { Issue.record("aperçu attendu"); return }
        #expect(apercu.club.nom == "Les brochets du 94" && apercu.nombreDeMembres == 1 && !apercu.dejaMembre)

        #expect(await b.rejoindre(clubID: id))
        #expect(b.clubs.map(\.id) == [cree.id])

        // A voit B (surnom) au prochain rafraîchissement.
        await a.charger()
        let vus = a.membresVisibles(de: cree)
        #expect(vus.map(\.profil).sorted() == ["p-adem", "p-titouan"])
        #expect(a.surnom(de: "p-titouan") == "Titouan")
    }

    @Test func rejoindreDeuxFoisNeCreePasDeDoublon() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        #expect(await b.rejoindre(clubID: cree.id))
        let membres = try await service.membres(deClub: cree.id)
        #expect(membres.count == 2)
    }

    @Test func sansProfilOnNeCreeNiNeRejointRien() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        let sansProfil = iPhone(nil, service: service, profils: p)
        #expect(await sansProfil.creer(nom: "Autre", poissonId: nil, photo: nil) == nil)
        #expect(sansProfil.message == .profilRequis)
        #expect(!(await sansProfil.rejoindre(clubID: cree.id)))
        #expect(sansProfil.message == .profilRequis)
        #expect(await service.clubsParID.count == 1)
    }

    @Test func unNomRefuseParLeFiltreNeCreeRien() async throws {
        let service = FauxServiceClubs()
        let a = iPhone("p-adem", service: service, profils: profils(), filtre: FiltreParListe(mots: ["zut"]))
        #expect(await a.creer(nom: "Club zut", poissonId: nil, photo: nil) == nil)
        #expect(a.message == .nomRefuse)
        #expect(await service.clubsParID.isEmpty)
    }

    @Test func sansICloudRienNEstEcritEtLaPageLeSait() async throws {
        let service = FauxServiceClubs(icloud: false)
        let a = iPhone("p-adem", service: service, profils: profils())
        await a.charger()
        #expect(!a.icloud)
        #expect(a.message == .iCloudIndisponible)
        #expect(await a.creer(nom: "Club", poissonId: nil, photo: nil) == nil)
        #expect(await service.clubsParID.isEmpty)
    }

    @Test func unClubFermeOuUnLienPerduSontExpliques() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        guard case .failure(let erreur) = await b.apercu(clubID: UUID().uuidString) else { Issue.record("échec attendu"); return }
        #expect(erreur == .introuvable)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await a.quitter(cree)) // seul : le club est fermé
        guard case .failure(let ferme) = await b.apercu(clubID: cree.id) else { Issue.record("échec attendu"); return }
        #expect(ferme == .clubFerme)
        #expect(!(await b.rejoindre(clubID: cree.id)))
        #expect(b.message == .clubFerme)
    }

    // MARK: Cartes partagées

    @Test func uneCarteDeBEstVisibleChezAEtNeContientQueLeDepartement() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-titouan", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))

        let clubB = try #require(b.club(id: cree.id))
        #expect(await b.partager(carte("c1", departement: "94"), dans: clubB))
        await a.charger()
        let vues = a.cartesVisibles(de: cree)
        #expect(vues.count == 1)
        #expect(vues[0].auteur == "p-titouan" && vues[0].departement == "94" && vues[0].tailleCm == 62)
        #expect(a.record(de: cree)?.id == vues[0].id)
        // Un lieu plus précis qu'un département est jeté.
        #expect(await b.partager(carte("c2", departement: "La Marne"), dans: clubB))
        let toutes = try await service.cartes(deClub: cree.id, sauf: [])
        #expect(toutes.first { $0.carteID == "c2" }?.departement == "")
    }

    @Test func partagerDeuxFoisLaMemeCarteNeLaDuplique() async throws {
        let service = FauxServiceClubs()
        let a = iPhone("p-adem", service: service, profils: profils())
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await a.partager(carte("c1"), dans: cree))
        #expect(await a.partager(carte("c1"), dans: cree))
        #expect(await service.cartesParID.count == 1)
        #expect(a.mesCartesPartagees(dans: cree) == ["c1"])
        await a.basculer(carte("c1"), dans: cree) // la retire
        #expect(await service.cartesParID.isEmpty)
    }

    @Test func quitterRetireLAdhesionEtSesCartesSeulement() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-titouan", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        let clubB = try #require(b.club(id: cree.id))
        #expect(await a.partager(carte("a1"), dans: cree))
        #expect(await b.partager(carte("b1"), dans: clubB))
        #expect(await b.partager(carte("b2"), dans: clubB))

        #expect(await b.quitter(clubB))
        #expect(b.clubs.isEmpty)
        let restantes = try await service.cartes(deClub: cree.id, sauf: [])
        #expect(restantes.map(\.carteID) == ["a1"])
        await a.charger()
        #expect(a.cartesVisibles(de: cree).map(\.carteID) == ["a1"])
        #expect(a.membresVisibles(de: cree).map(\.profil) == ["p-adem"])
        // Le club de B ne revient pas sur son écran au rafraîchissement suivant.
        await b.charger()
        #expect(b.clubs.isEmpty)
    }

    @Test func leFondateurQuiPartAvecDesMembresLaisseUnClubSansFondateur() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let c = iPhone("p-titouan", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        #expect(await a.quitter(cree))
        // Le club existe encore, non fermé, sans fondateur : pas de transfert (R2).
        let restant = try #require(try await service.club(id: cree.id))
        #expect(!restant.ferme && restant.fondateur == "p-adem")
        await b.charger()
        let clubB = try #require(b.club(id: cree.id))
        #expect(b.etat(de: clubB) == .sansFondateur)
        #expect(!b.jeSuisFondateur(de: clubB))
        // Personne de nouveau n'y entre.
        #expect(!(await c.rejoindre(clubID: cree.id)))
        #expect(c.message == .sansFondateur)
        // Et personne ne peut écarter.
        #expect(!(await b.ecarter("p-adem", de: clubB)))
        #expect(b.message == .refuse)
    }

    // MARK: Modération

    @Test func signalerMasqueLaCarteTraceEtDonneLEmail() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-titouan", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        let ligne7 = try #require(b.club(id: cree.id))
        #expect(await b.partager(carte("b1"), dans: ligne7))
        await a.charger()
        let cible = try #require(a.cartesVisibles(de: cree).first)

        let url = try #require(await a.signaler(cible, motif: .spam))
        #expect(a.cartesVisibles(de: cree).isEmpty)
        #expect(await service.signalements.count == 1)
        #expect(await service.signalements.first?.cible == cible.id)
        let composants = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        #expect(composants.scheme == "mailto" && composants.path == ContactClub.adresse)
        let corps = composants.queryItems?.first { $0.name == "body" }?.value ?? ""
        #expect(corps.contains(cible.id) && corps.contains("p-titouan"))
        #expect(!corps.lowercased().contains("lat") && !corps.contains("48."))
        // L'autre iPhone, lui, garde la carte.
        await b.charger()
        let ligne8 = try #require(b.club(id: cree.id))
        #expect(b.cartesVisibles(de: ligne8).count == 1)
    }

    @Test func bloquerUnMembreMasqueSesCartesEtSaPlace() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-titouan", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        let ligne9 = try #require(b.club(id: cree.id))
        #expect(await b.partager(carte("b1"), dans: ligne9))
        await a.charger()
        #expect(a.cartesVisibles(de: cree).count == 1)
        a.bloquer("p-titouan")
        #expect(a.cartesVisibles(de: cree).isEmpty)
        #expect(a.membresVisibles(de: cree).map(\.profil) == ["p-adem"])
    }

    @Test func leFondateurEcarteUnMembreEtSonIPhoneSeNettoie() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        let ligne10 = try #require(b.club(id: cree.id))
        #expect(await b.partager(carte("b1"), dans: ligne10))
        await a.charger()
        let clubA = try #require(a.club(id: cree.id))
        #expect(await a.ecarter("p-lea", de: clubA))
        let ligne11 = try #require(a.club(id: cree.id))
        #expect(a.membresVisibles(de: ligne11).map(\.profil) == ["p-adem"])
        // Sa carte reste en base (R2 : seul son auteur la supprime) mais n'est plus montrée.
        #expect(await service.cartesParID.count == 1)
        let ligne12 = try #require(a.club(id: cree.id))
        #expect(a.cartesVisibles(de: ligne12).isEmpty)
        // Au prochain chargement de B, son iPhone efface lui-même son adhésion et sa carte.
        await b.charger()
        #expect(b.clubs.isEmpty)
        #expect(await service.cartesParID.isEmpty)
        // Il ne peut pas revenir par le lien.
        #expect(!(await b.rejoindre(clubID: cree.id)))
        #expect(b.message == .ecarte)
    }

    @Test func unMembreNePeutPasEcarterUnAutre() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        let ligne13 = try #require(b.club(id: cree.id))
        #expect(!(await b.ecarter("p-adem", de: ligne13)))
        #expect(b.message == .refuse)
    }

    // MARK: Hors ligne

    @Test func horsLigneLaPageMontreLeDernierEtatLu() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let cache = CacheClubsMemoire()
        let u = UUID().uuidString
        func gestion() -> GestionClubs {
            GestionClubs(service: service, profils: p, memoire: MemoireClubFausse("p-adem"), cache: cache,
                         blocages: BlocagesProfils(cleBloques: "t.bl.\(u)", cleMasques: "t.ma.\(u)"),
                         masquees: CartesMasquees(cle: "t.cm.\(u)"), filtre: AucunFiltre(), maintenant: horloge)
        }
        let a = gestion()
        let cree = try #require(await a.creer(nom: "Les brochets du 94", poissonId: nil, photo: nil))
        #expect(await a.partager(carte("a1"), dans: cree))
        await a.charger()

        // Mode avion, nouveau lancement de l'app : rien ne se lit, mais le cache répond.
        await service.regler(horsLigne: true)
        let relance = gestion()
        #expect(relance.clubs.map(\.nom) == ["Les brochets du 94"])
        let ligne14 = try #require(relance.club(id: cree.id))
        #expect(relance.cartesVisibles(de: ligne14).count == 1)
        await relance.charger()
        #expect(relance.horsLigne)
        #expect(relance.message == .horsLigne)
        #expect(relance.clubs.map(\.id) == [cree.id])
        // Retour du réseau.
        await service.regler(horsLigne: false)
        await relance.charger()
        #expect(!relance.horsLigne)
    }

    @Test func leCacheSeRelitTelQuelEtResteLeger() throws {
        var etat = EtatCacheClubs()
        let c = club()
        etat.clubs = [c]
        etat.membres[c.id] = [membre("p-adem", dans: c, role: .fondateur)]
        etat.cartes[c.id] = (0..<(EtatCacheClubs.cartesParClub + 10)).map { i in
            CartePartageeClub(id: "pc-\(c.id)-\(i)", club: c.id, carteID: "\(i)", auteur: "p-adem", espece: "Brochet", rarete: .legendaire,
                              tailleCm: 80, departement: "94", image: Data([1]), creeLe: horloge())
        }
        etat.profils["p-adem"] = EtatCacheClubs.ProfilCache(id: "p-adem", surnom: "Adem", avatar: nil)
        let relu = try JSONDecoder().decode(EtatCacheClubs.self, from: try JSONEncoder().encode(etat))
        #expect(relu == etat)
        #expect(etat.reduit().cartes[c.id]?.count == EtatCacheClubs.cartesParClub)
    }

    // MARK: Migration

    private func local(_ nom: String, poisson: String? = "brochet") -> ClubLocal {
        ClubLocal(id: UUID(), nom: nom, poissonId: poisson)
    }

    private func migration(_ service: FauxServiceClubs, drapeaux: DrapeauxFaux, locaux: [ClubLocal], partages: [String: Set<String>] = [:],
                           moi: String? = "p-adem", filtre: any FiltreMots = AucunFiltre()) -> MigrationClubs {
        MigrationClubs(service: service, memoire: MemoireClubFausse(moi), drapeaux: drapeaux, filtre: filtre,
                       clubsLocaux: { locaux }, partages: { partages }, photo: { _ in nil }, maintenant: horloge)
    }

    @Test func unClubLocalMigreAvecSesCartesPartagees() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let club = local("Mon club")
        let m = migration(service, drapeaux: drapeaux, locaux: [club], partages: [club.id.uuidString: ["c1", "disparue"]])
        #expect(m.enAttente.map(\.id) == [club.id])

        let issues = await m.migrer([club], cartes: [carte("c1"), carte("c2")])
        #expect(issues[club.id] == .fait)
        let enLigne = try #require(try await service.club(id: club.id.uuidString))
        #expect(enLigne.fondateur == "p-adem" && enLigne.nom == "Mon club")
        // Même UUID que le club local, fondateur membre, seule c1 repartagée (c2 n'était pas partagée, « disparue » est introuvable).
        #expect(await service.adhesions.values.map(\.role) == [.fondateur])
        #expect(await service.cartesParID.values.map(\.carteID) == ["c1"])
        #expect(drapeaux.etat(de: club.id) == .fait)
        #expect(m.enAttente.isEmpty)
        #expect(drapeaux.termine)
    }

    @Test func laMigrationNeRejoueJamaisUnClubDejaFait() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let club = local("Mon club")
        let m = migration(service, drapeaux: drapeaux, locaux: [club], partages: [club.id.uuidString: ["c1"]])
        _ = await m.migrer([club], cartes: [carte("c1")])
        let ecrituresApres = await service.ecritures
        // Second lancement : rien à proposer, rien ne s'écrit, pas de doublon.
        #expect(m.enAttente.isEmpty)
        let issues = await m.migrer([club], cartes: [carte("c1")])
        #expect(issues[club.id] == .fait)
        #expect(await service.ecritures == ecrituresApres)
        #expect(await service.clubsParID.count == 1)
        #expect(await service.cartesParID.count == 1)
    }

    @Test func memeSiLeDrapeauSePerdLEcritureRejoueeNeCreePasDeDoublon() async throws {
        let service = FauxServiceClubs()
        let club = local("Mon club")
        let premier = DrapeauxFaux()
        _ = await migration(service, drapeaux: premier, locaux: [club], partages: [club.id.uuidString: ["c1"]]).migrer([club], cartes: [carte("c1")])
        let perdu = DrapeauxFaux()
        _ = await migration(service, drapeaux: perdu, locaux: [club], partages: [club.id.uuidString: ["c1"]]).migrer([club], cartes: [carte("c1")])
        #expect(await service.clubsParID.count == 1)
        #expect(await service.adhesions.count == 1)
        #expect(await service.cartesParID.count == 1)
    }

    @Test func unEchecReseauNeNoteRienEtLeProchainLancementReprend() async throws {
        let service = FauxServiceClubs(horsLigne: true)
        let drapeaux = DrapeauxFaux()
        let un = local("Un")
        let deux = local("Deux")
        let m = migration(service, drapeaux: drapeaux, locaux: [un, deux])
        let issues = await m.migrer([un, deux], cartes: [])
        #expect(issues[un.id] == .echec(.reseau))
        #expect(issues[deux.id] == nil) // la boucle s'arrête au premier échec
        #expect(drapeaux.etats.isEmpty && !drapeaux.termine)
        await service.regler(horsLigne: false)
        let reprise = await m.migrer([un, deux], cartes: [])
        #expect(reprise[un.id] == .fait && reprise[deux.id] == .fait)
        #expect(drapeaux.termine)
    }

    @Test func unDrapeauParClubPasUnSeulGlobal() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let un = local("Un")
        let deux = local("Deux")
        let m = migration(service, drapeaux: drapeaux, locaux: [un, deux])
        _ = await m.migrer([un], cartes: [])
        #expect(drapeaux.etat(de: un.id) == .fait && drapeaux.etat(de: deux.id) == nil)
        #expect(!drapeaux.termine)
        #expect(m.enAttente.map(\.id) == [deux.id])
    }

    @Test func garderEnLocalNEcritJamaisEnLigne() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let club = local("Privé")
        let m = migration(service, drapeaux: drapeaux, locaux: [club])
        m.garderEnLocal(club)
        #expect(drapeaux.etat(de: club.id) == .gardeLocal)
        _ = await m.migrer([club], cartes: [])
        #expect(await service.clubsParID.isEmpty)
        #expect(drapeaux.termine)
    }

    @Test func lesCartesPasPretesRetardentLaMigrationSansRienNoter() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let club = local("Mon club")
        let m = migration(service, drapeaux: drapeaux, locaux: [club], partages: [club.id.uuidString: ["c1"]])
        let issues = await m.migrer([club], cartes: [])
        #expect(issues[club.id] == .cartesPasPretes)
        let rien = await service.clubsParID.isEmpty
        #expect(drapeaux.etat(de: club.id) == nil && rien)
    }

    @Test func unNomRefuseResteLocal() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let club = local("Club zut")
        let m = migration(service, drapeaux: drapeaux, locaux: [club], filtre: FiltreParListe(mots: ["zut"]))
        let issues = await m.migrer([club], cartes: [])
        #expect(issues[club.id] == .gardeLocal)
        #expect(await service.clubsParID.isEmpty)
    }

    @Test func sansProfilLaMigrationAttend() async throws {
        let service = FauxServiceClubs()
        let drapeaux = DrapeauxFaux()
        let club = local("Mon club")
        let m = migration(service, drapeaux: drapeaux, locaux: [club], moi: nil)
        #expect(!m.peutMigrer)
        #expect(await m.migrer([club], cartes: []).isEmpty)
        let rien = await service.clubsParID.isEmpty
        #expect(rien && drapeaux.etats.isEmpty)
    }

    // MARK: Effacement du profil

    @Test func supprimerLeProfilEffaceSesCartesEtSesAdhesions() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let clubA = try #require(await a.creer(nom: "Club A", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: clubA.id))
        let ligne15 = try #require(b.club(id: clubA.id))
        #expect(await b.partager(carte("b1"), dans: ligne15))
        let clubB = try #require(await b.creer(nom: "Club de Léa", poissonId: nil, photo: nil)) // fondatrice seule

        try await EffaceurClubs(service: service).effacerContenu(deProfil: "p-lea")

        #expect(await service.cartesParID.isEmpty)
        let lu16 = try await service.club(id: clubB.id)
        #expect(lu16 == nil) // fondateur seul : club supprimé
        let lu17 = try await service.club(id: clubA.id)
        #expect(lu17 != nil) // le club des autres continue
        let membres = try await service.membres(deClub: clubA.id)
        #expect(membres.map(\.profil) == ["p-adem"])
    }

    @Test func unFondateurQuiEffaceSonProfilLaisseLeClubSansFondateur() async throws {
        let service = FauxServiceClubs()
        let p = profils()
        let a = iPhone("p-adem", service: service, profils: p)
        let b = iPhone("p-lea", service: service, profils: p)
        let cree = try #require(await a.creer(nom: "Club", poissonId: nil, photo: nil))
        #expect(await b.rejoindre(clubID: cree.id))
        try await EffaceurClubs(service: service).effacerContenu(deProfil: "p-adem")
        let membres = try await service.membres(deClub: cree.id)
        let restant = try #require(try await service.club(id: cree.id))
        #expect(restant.etat(membres: membres) == .sansFondateur)
    }

    @Test func lEffaceurEchoueSiLeReseauManque() async throws {
        let service = FauxServiceClubs(horsLigne: true)
        await #expect(throws: ErreurClub.reseau) {
            try await EffaceurClubs(service: service).effacerContenu(deProfil: "p-adem")
        }
    }

    @Test func lEffaceurSEnregistreDansLeRegistre() {
        let registre = RegistreEffaceurs()
        EffaceurClubs.enregistrer(service: FauxServiceClubs(), dans: registre)
        #expect(registre.effaceurs.count == 1)
    }

    // MARK: Démo et compatibilité

    @Test func laDemoResteInchangee() {
        #expect(DemoClub.clubs.count == 2)
        #expect(DemoClub.clubs.allSatisfy { $0.nom.contains("Démo") })
        #expect(DemoClub.clubs.allSatisfy { DemoClub.estDemo($0) })
        #expect(DemoClub.membres(pour: DemoClub.clubs[0]).map(\.nom) == ["Adem", "Sullyvan", "Titouan"])
        #expect(DemoClub.membres(pour: DemoClub.clubs[1]).count == 5)
        #expect(DemoClub.dernieresCartes(pour: DemoClub.clubs[0]).count == 6)
        #expect(DemoClub.record(pour: DemoClub.clubs[1]).tailleCm == 74)
    }

    @Test func laDemoNEstJamaisEcriteEnLigne() async throws {
        let service = FauxServiceClubs()
        let a = iPhone("p-adem", service: service, profils: profils())
        await a.charger()
        #expect(await service.clubsParID.isEmpty)
        // Les clubs de démo ne sont pas des clubs en ligne : aucun n'est connu de la gestion.
        #expect(DemoClub.clubs.allSatisfy { a.club(id: $0.id.uuidString) == nil })
    }

    @Test func uneCarteAPartagerDAvantSeConstruitToujours() {
        let carte = CarteAPartager(id: "1", titre: "Brochet", png: Data())
        #expect(carte.espece == nil && carte.rarete == nil && carte.tailleCm == nil && carte.departement == nil)
    }

    @Test func unAncienClubLocalSeRelitSansLImageEnLigne() throws {
        // Un `ClubLocal` écrit avant L22 (sans `imageEnLigne`) se relit tel quel ; l'image en ligne n'est jamais écrite.
        var club = ClubLocal(id: UUID(), nom: "Ancien", poissonId: "brochet")
        club.imageEnLigne = Data([1, 2, 3])
        let json = try JSONEncoder().encode(club)
        let texte = String(decoding: json, as: UTF8.self)
        #expect(!texte.contains("imageEnLigne"))
        let relu = try JSONDecoder().decode(ClubLocal.self, from: json)
        #expect(relu.nom == "Ancien" && relu.imageEnLigne == nil)
    }

    @Test func unClubEnLignePasseParLesEcransExistants() throws {
        let c = club()
        let local = try #require(ClubLocal(enLigne: c))
        #expect(local.id.uuidString == c.id && local.nom == c.nom && local.poissonId == "brochet")
        #expect(ClubLocal(enLigne: Club(id: "pas-un-uuid", nom: "x", poissonId: nil, image: nil, fondateur: "p-a", creeLe: horloge())) == nil)
    }

    @Test func lesEnregistrementsRestentCodables() throws {
        let c = club()
        let carte = CartePartageeClub(id: "pc-\(c.id)-1", club: c.id, carteID: "1", auteur: "p-adem", espece: "Sandre", rarete: .peuCommun,
                                      tailleCm: 55.5, departement: "94", image: nil, creeLe: horloge())
        let dec18 = try JSONDecoder().decode(CartePartageeClub.self, from: try JSONEncoder().encode(carte))
        #expect(dec18 == carte)
        let dec19 = try JSONDecoder().decode(Club.self, from: try JSONEncoder().encode(c))
        #expect(dec19 == c)
    }
}
