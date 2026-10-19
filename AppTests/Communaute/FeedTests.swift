import CloudKit
import Core
import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import BuildChallenge

// Tests du lot L23 (fil). Écrits sans compilateur : non exécutés à ce jour.

@MainActor
struct FeedLieuTests {
    private let riviere = ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94")
    private let etang = ContexteLieu(eauNom: "Étang de Saint-Quentin", planDEau: true, departement: "78")

    @Test func surUneRiviereTroisChoixEtLeDepartementSeulParDefaut() {
        #expect(LieuPublication.options(riviere) == [.coursEau, .departement, .aucun])
        // Décision de Titouan (19 oct.) : « département seul » par défaut, le cours d'eau reste possible.
        #expect(LieuPublication.parDefaut(riviere) == .departement)
        #expect(LieuPublication.etiquette(.coursEau, riviere) == "La Marne · 94")
        #expect(LieuPublication.etiquette(.departement, riviere) == "94")
    }

    @Test func surUnPlanDEauNommeLeCoursDEauNExistePas() {
        #expect(LieuPublication.options(etang) == [.departement, .aucun])
        #expect(LieuPublication.choisir(.coursEau, etang) == nil)
        #expect(LieuPublication.parDefaut(etang) == .departement)
    }

    @Test func leLieuInconnuNeProposeQueAucun() {
        #expect(LieuPublication.options(.inconnu) == [.aucun])
        #expect(LieuPublication.parDefaut(.inconnu) == .aucun)
    }

    @Test func departementSeulEtAucunNePortentPasLeNomDeLEau() {
        let seul = LieuPublication.choisir(.departement, riviere)
        #expect(seul?.lieuTexte == "")
        #expect(seul?.departement == "94")
        let aucun = LieuPublication.choisir(.aucun, riviere)
        #expect(aucun?.lieuTexte == "")
        // Décision de Titouan : aucun lieu, aucun département.
        #expect(aucun?.departement == "")
    }

    @Test func leLieuFlouDUneCarteSansTypeDEauEstTraiteCommeUnPlanDEau() {
        let inconnu = ContexteLieu(lieuFlou: "La Marne · 94", typeEau: nil)
        #expect(LieuPublication.options(inconnu) == [.departement, .aucun])
        let riv = ContexteLieu(lieuFlou: "La Marne · 94", typeEau: .riviere)
        #expect(LieuPublication.options(riv).first == .coursEau)
    }

    @Test func leLieuAfficheEstExactementLeChoix() {
        var p = DemoFeed.publication("x", mode: .coursEau)
        #expect(p.lieuAffiche == "La Marne · 94")
        p = DemoFeed.publication("x", mode: .departement)
        #expect(p.lieuAffiche == "Département 94")
        p = DemoFeed.publication("x", mode: .aucun)
        #expect(p.lieuAffiche == nil)
    }
}

struct FeedFiltreTests {
    @Test func unMotInterditEstRefuse() {
        #expect(FiltreTexte.verifier("quel connard") == .motInterdit)
        #expect(FiltreTexte.verifier("C0NNARD") == .motInterdit)
        #expect(FiltreTexte.verifier("c o n n a r d") == .motInterdit)
        #expect(FiltreTexte.verifier("Énculé") == .motInterdit)
    }

    @Test func unTexteDePecheEstAccepte() {
        #expect(FiltreTexte.verifier("Beau brochet de 62 cm pris au leurre, relâché.") == nil)
        #expect(FiltreTexte.verifier("") == nil)
    }

    @Test func uneCoordonneeOuUnLienDeCarteEstRefuse() {
        #expect(FiltreTexte.verifier("48.85661, 2.35222") == .coordonnee)
        #expect(FiltreTexte.verifier("lat 48 lon 2") == .coordonnee)
        #expect(FiltreTexte.verifier("https://maps.app.goo.gl/abc") == .lienCarte)
        #expect(FiltreTexte.verifier("https://waze.com/ul?q=x") == .lienCarte)
    }

    @Test func lesLiensDeCarteGoogleEtAppleSontRefuses() {
        for lien in ["https://maps.google.com/?q=48.1,2.1", "google.fr/maps/place/x", "https://www.google.com/maps/@48,2,15z",
                     "https://goo.gl/maps/abc", "https://g.co/maps/abc", "https://maps.apple.com/?ll=1,2",
                     "https://www.bing.com/maps?cp=1~2"] {
            #expect(FiltreTexte.verifier(lien) == .lienCarte, "\(lien)")
        }
    }

    @Test func uneCoordonneeADeuxDecimalesEstRefuseMaisPasUnePrise() {
        #expect(FiltreTexte.verifier("48.85, 2.35") == .coordonnee)
        #expect(FiltreTexte.verifier("48,85 ; 2,35") == .coordonnee)
        #expect(FiltreTexte.verifier("-33.86/151.21") == .coordonnee)
        // Une taille, un poids ou un prix isolé passent.
        #expect(FiltreTexte.verifier("Brochet de 62,50 cm") == nil)
        #expect(FiltreTexte.verifier("Une carpe de 12,40 kg, relâchée.") == nil)
        // Hors bornes d'une latitude : ce n'est pas une position.
        #expect(!FiltreTexte.contientPaireDeCoordonnees("120.50, 300.25"))
    }

    @Test func plusDe280CaracteresEstRefuse() {
        #expect(FiltreTexte.verifier(String(repeating: "a", count: 281)) == .tropLong)
        #expect(FiltreTexte.verifier(String(repeating: "a", count: 280)) == nil)
    }
}

struct FeedFabriqueTests {
    private func brouillon(lieu: LieuChoisi) throws -> BrouillonPublication {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let f = dossier.appendingPathComponent("m.jpg")
        try Data([1, 2, 3]).write(to: f)
        return BrouillonPublication(auteurNom: "p-moi", genre: .photo, fichierMedia: f, vignette: f, dureeS: 0, legende: "Salut",
                                    lieu: lieu, carte: CarteLiee(espece: "brochet", rarete: .rare, tailleCm: 62), club: "club-1")
    }

    @Test func lesCleDeLaPublicationSontLesSeulesAutorisees() throws {
        let lieu = try #require(LieuPublication.choisir(.coursEau, ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94")))
        let r = FabriqueFeed.record(pour: try brouillon(lieu: lieu))
        #expect(Set(r.allKeys()).isSubset(of: FabriqueFeed.clesPublication))
        for interdite in ["latitude", "longitude", "altitude", "location", "gps", "coordonnee"] {
            #expect(!r.allKeys().contains(interdite))
        }
        #expect(r["lieuMode"] as? String == "cours-eau")
        #expect(r["departement"] as? String == "94")
    }

    @Test func sansLieuLEnregistrementNePorteAucunDepartement() throws {
        let lieu = try #require(LieuPublication.choisir(.aucun, ContexteLieu(eauNom: "La Marne", planDEau: false, departement: "94")))
        let r = FabriqueFeed.record(pour: try brouillon(lieu: lieu))
        #expect(r["lieuMode"] as? String == "aucun")
        #expect(r["lieuTexte"] as? String == "")
        #expect(r["departement"] as? String == "")
    }

    @Test func unLikeParPersonneEtParPublication() {
        let a = FabriqueFeed.recordLike(publication: "p1", auteur: "p-moi")
        let b = FabriqueFeed.recordLike(publication: "p1", auteur: "p-moi")
        #expect(a.recordID.recordName == b.recordID.recordName)
        #expect(a.recordID.recordName == "l-p1-p-moi")
        #expect(Set(a.allKeys()).isSubset(of: FabriqueFeed.clesLike))
    }

    @Test func leSignalementNePorteQueLesChampsDuSchema() {
        let s = SignalementFeed(cible: "p1", typeCible: .publication, motif: .spam, signalePar: "p-moi", auteurCible: "p-lui")
        let r = FabriqueFeed.record(pour: s)
        #expect(Set(r.allKeys()) == FabriqueFeed.clesSignalement)
    }

    @Test func lEmailDeSignalementVaChezFishmeAvecLIdentifiant() throws {
        let s = SignalementFeed(cible: "pub-123", typeCible: .publication, motif: .harcelement, signalePar: "p-moi", auteurCible: "p-lui",
                                extrait: "texte signalé")
        let url = try #require(CourrielSignalement.url(s))
        #expect(url.absoluteString.hasPrefix("mailto:fishme.app@gmail.com"))
        #expect(url.absoluteString.contains("pub-123"))
        #expect(url.absoluteString.contains("texte"))
    }

    @Test func leTexteSignaleNeVaPasDansLEnregistrement() {
        let s = SignalementFeed(cible: "p1", typeCible: .publication, motif: .spam, signalePar: "p-moi", auteurCible: "p-lui", extrait: "secret")
        let r = FabriqueFeed.record(pour: s)
        #expect(!r.allKeys().contains("extrait"))
        #expect(!r.allKeys().contains("auteurCible"))
    }

    @Test func lesMotifsOntLesLibellesDeL21() {
        #expect(MotifSignalementPublication.allCases.map(\.rawValue) ==
                ["choquant", "harcelement", "nudite", "cruaute", "pecheIllegale", "coinExact", "mineur", "spam", "autre"])
        #expect(MotifSignalementPublication.mineur.titre == "Personne mineure sans accord")
        #expect(MotifSignalementPublication.harcelement.titre == "Haine ou harcèlement")
    }

    @Test func laTailleVenueDeLaBasePubliqueNePlantePas() {
        #expect(FabriqueFeed.centimetres(62.4) == 62)
        #expect(FabriqueFeed.centimetres(nil) == nil)
        #expect(FabriqueFeed.centimetres(.nan) == nil)
        #expect(FabriqueFeed.centimetres(.infinity) == nil)
        #expect(FabriqueFeed.centimetres(-3) == nil)
        #expect(FabriqueFeed.centimetres(0) == nil)
        #expect(FabriqueFeed.centimetres(1e300) == nil)
        #expect(FabriqueFeed.centimetres(500) == nil)
    }

    @Test func laLectureDUnRecordBorneLaTaille() {
        let r = CKRecord(recordType: FabriqueFeed.typePublication, recordID: CKRecord.ID(recordName: "x"))
        r["auteurNom"] = "p-lui"; r["genre"] = "photo"; r["lieuMode"] = "aucun"; r["creeLe"] = Date(); r["tailleCm"] = 1e300
        #expect(FabriqueFeed.publication(depuis: r)?.tailleCm == nil)
    }

    @Test func lesRequetesPartentEnPaquetsDeCinquante() {
        let valeurs = (0..<120).map(String.init)
        let lots = ServiceFeedCloudKit.lots(valeurs)
        #expect(lots.map(\.count) == [50, 50, 20])
        #expect(lots.flatMap { $0 } == valeurs)
        #expect(ServiceFeedCloudKit.lots([String]()).isEmpty)
    }

    @Test func unJpegRecompresseNAPasDeGPS() throws {
        let rendu = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 1000))
        let image = rendu.image { c in
            UIColor.systemTeal.setFill()
            c.fill(CGRect(x: 0, y: 0, width: 2000, height: 1000))
        }
        let sortie = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 48.85, kCGImagePropertyGPSLatitudeRef: "N",
                                    kCGImagePropertyGPSLongitude: 2.35, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(destination, try #require(image.cgImage), [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        #expect(PreparationMedia.contientGPS(sortie as Data))
        let propre = try PreparationMedia.jpegSansMetadonnee(sortie as Data)
        #expect(!PreparationMedia.contientGPS(propre))
        let source = try #require(CGImageSourceCreateWithData(propre as CFData, nil))
        let taille = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let largeur = try #require(taille[kCGImagePropertyPixelWidth] as? Int)
        #expect(largeur <= PreparationMedia.coteMax)
    }
}

struct FeedVideoSansGPSTests {
    @Test func uneMetadonneeDeLieuQuickTimeEstReconnue() {
        let quicktime = PreparationMedia.ElementMetadonnee(identifiant: "com.apple.quicktime.location.ISO6709", cleCommune: "", valeur: "+48.8566+002.3522+035.000/")
        #expect(PreparationMedia.contientBaliseLieu(parmi: [quicktime]))
        let xyz = PreparationMedia.ElementMetadonnee(identifiant: "uiso/\u{A9}xyz", cleCommune: "", valeur: "")
        #expect(PreparationMedia.contientBaliseLieu(parmi: [xyz]))
        let commune = PreparationMedia.ElementMetadonnee(identifiant: "", cleCommune: "location", valeur: "")
        #expect(PreparationMedia.contientBaliseLieu(parmi: [commune]))
    }

    @Test func uneValeurISO6709SansIdentifiantEstReconnue() {
        // Cas d'une piste : la clé est opaque, mais la valeur est une position.
        let piste = PreparationMedia.ElementMetadonnee(identifiant: "mdta/inconnu", cleCommune: "", valeur: "+48.8566+002.3522/")
        #expect(PreparationMedia.contientBaliseLieu(parmi: [piste]))
    }

    @Test func desMetadonneesSansLieuPassent() {
        let logiciel = PreparationMedia.ElementMetadonnee(identifiant: "com.apple.quicktime.software", cleCommune: "software", valeur: "17.0")
        let creation = PreparationMedia.ElementMetadonnee(identifiant: "mdta/creationdate", cleCommune: "creationDate", valeur: "2026-10-19T10:00:00Z")
        #expect(!PreparationMedia.contientBaliseLieu(parmi: [logiciel, creation]))
        #expect(!PreparationMedia.contientBaliseLieu(parmi: []))
    }

    @Test func lesOctetsAvecUneCleDeLieuSontRefuses() {
        var avecCle = Data([0, 0, 0, 20]) + Data("keys".utf8)
        avecCle += Data("mdta".utf8) + Data("com.apple.quicktime.location.ISO6709".utf8)
        #expect(PreparationMedia.contientBaliseLieu(octets: avecCle))
        #expect(PreparationMedia.contientBaliseLieu(octets: Data([0x00, 0xA9, 0x78, 0x79, 0x7A, 0x00])))
        #expect(PreparationMedia.contientBaliseLieu(octets: Data("xxISO6709xx".utf8)))
        #expect(!PreparationMedia.contientBaliseLieu(octets: Data("ftypmp42 moov mdat".utf8)))
    }
}
