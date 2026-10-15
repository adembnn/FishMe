import Core
import Foundation
import ImageIO
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import BuildChallenge

struct CollectionTests {
    private let services = ServicesCollection(especes: EspecesFaux(), soleil: SoleilFaux(), regles: ReglesFaux())
    private let brochet = Espece(id: "brochet")
    private let sandre = Espece(id: "sandre")

    private func nouveauDepot() throws -> DepotCartes {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return DepotCartes(conteneur: try DepotCartes.creerConteneur(enMemoire: true), dossierPhotos: dossier, services: services)
    }

    /// Un JPEG qui porte un bloc GPS, pour vérifier qu'il disparaît.
    private func jpegAvecGPS() throws -> Data {
        let rendu = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
        let image = rendu.image { c in
            UIColor.systemTeal.setFill()
            c.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
        }
        let sortie = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(sortie, UTType.jpeg.identifier as CFString, 1, nil))
        let gps: [CFString: Any] = [kCGImagePropertyGPSLatitude: 48.85, kCGImagePropertyGPSLatitudeRef: "N",
                                    kCGImagePropertyGPSLongitude: 2.35, kCGImagePropertyGPSLongitudeRef: "E"]
        CGImageDestinationAddImage(destination, try #require(image.cgImage), [kCGImagePropertyGPSDictionary: gps] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        return sortie as Data
    }

    @Test func nettoyageRetireLeGPS() throws {
        let avant = try jpegAvecGPS()
        #expect(NettoyagePhoto.contientGPS(avant))
        let apres = try #require(NettoyagePhoto.sansMetadonnees(avant))
        #expect(!NettoyagePhoto.contientGPS(apres))
    }

    @Test func fichierEnregistreSansGPSEtCarteRelueApresRedemarrage() async throws {
        let depot = try nouveauDepot()
        let prise = Prise(espece: brochet, longueurCm: 62, mesure: .saisie, date: Date(), lieuFlou: "La Marne · 94", gardee: false)
        let enregistree = try await depot.enregistrer(prise: prise, photo: try jpegAvecGPS())
        let relue = try #require(await depot.cartes().first)
        #expect(relue.id == prise.id)
        #expect(relue.gardee == false)
        let photo = try #require(await depot.photo(de: enregistree))
        #expect(!NettoyagePhoto.contientGPS(photo))
    }

    @Test func uneVraiePriseSansPhotoEstRefusee() async throws {
        let depot = try nouveauDepot()
        let prise = Prise(espece: brochet, date: Date())
        await #expect(throws: ErreurDepot.self) { try await depot.enregistrer(prise: prise, photo: nil) }
    }

    @Test func carteDeclareeSansPhotoEntreAuPescedex() async throws {
        let depot = try nouveauDepot()
        let carte = try await depot.enregistrerDeclaree(espece: brochet)
        #expect(carte.estDeclaree)
        #expect(carte.cheminPhoto == nil)
        #expect(await depot.cartes().count == 1)
    }

    @Test func bredouilleRangeeAPart() async throws {
        let depot = try nouveauDepot()
        let debut = Date(timeIntervalSince1970: 1_000_000)
        let sortie = Sortie(debut: debut, fin: debut.addingTimeInterval(2 * 3600))
        try await depot.enregistrerBredouille(sortie: sortie, lieuFlou: "La Marne · 94")
        #expect(await depot.cartes().isEmpty)
        let b = try #require(await depot.bredouilles().first)
        #expect(b.dureeSecondes == 7200)
    }

    @Test func compteurParZoneJamaisTroisSurQuatorze() {
        let especes = services.especes.especesPechables()
        let cartes = [Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg")]
        let zone = CompteurPescedex.zoneParDefaut(cartes: cartes)
        #expect(zone == Departement(code: "94"))
        let emp = CompteurPescedex.emplacements(cartes: cartes, especes: especes, zone: zone) { e, _ in
            ResultatRarete(niveau: e.id == "sandre" ? .legendaire : .commun, nPeches: e.id == "sandre" ? 0 : 5, nTotal: 29,
                           anneeDernierReleve: 2023, echelle: .departement)
        }
        let compteur = CompteurPescedex.compteur(emplacements: emp, zone: zone)
        #expect(compteur.trouvees == 1)
        #expect(compteur.releveesDansLaZone == especes.count - 1)
        #expect(compteur.legendairesEnPlus == 0)
        #expect(compteur.texte.hasPrefix("1 sur les \(especes.count - 1) espèces relevées dans le 94"))
        // Les espèces relevées dans la zone passent d'abord.
        #expect(emp.last?.id == "sandre")
    }

    @Test func carteDExempleNeCompteJamais() {
        let especes = services.especes.especesPechables()
        let exemple = Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg", exemple: true)
        let emp = CompteurPescedex.emplacements(cartes: [exemple], especes: especes, zone: Departement(code: "94")) { _, _ in
            ResultatRarete(niveau: .commun, nPeches: 5, nTotal: 29, anneeDernierReleve: 2023, echelle: .departement)
        }
        #expect(CompteurPescedex.compteur(emplacements: emp, zone: Departement(code: "94")).trouvees == 0)
    }

    @Test func legendairePriseSeCompteEnPlus() {
        let especes = services.especes.especesPechables()
        let cartes = [Prise(espece: sandre, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg")]
        let emp = CompteurPescedex.emplacements(cartes: cartes, especes: especes, zone: Departement(code: "94")) { e, _ in
            e.id == "sandre"
                ? ResultatRarete(niveau: .legendaire, nPeches: 0, nTotal: 29, anneeDernierReleve: 2016, echelle: .departement)
                : ResultatRarete(niveau: .commun, nPeches: 5, nTotal: 29, anneeDernierReleve: 2023, echelle: .departement)
        }
        let c = CompteurPescedex.compteur(emplacements: emp, zone: Departement(code: "94"))
        #expect(c.trouvees == 0)
        #expect(c.legendairesEnPlus == 1)
        #expect(c.texte.contains("+ 1 légendaire"))
    }

    @Test func tailleEstimeeEtPoidsPortentEstime() {
        let p = Prise(espece: brochet, longueurCm: 62, mesure: .estimee, date: Date())
        #expect(Formats.taille(p)?.contains("estimé") == true)
        #expect(Formats.poids(PoidsEstime(kilos: 1.4, minKilos: 1.2, maxKilos: 1.6, source: "essai"))?.contains("≈") == true)
        #expect(Formats.poids(PoidsEstime(kilos: 1.4, minKilos: 1.2, maxKilos: 1.6, source: "essai"))?.contains("estimé") == true)
    }

    @Test func raretesDistinguablesSansCouleur() {
        let styles: [StyleRarete] = [.commun, .peuCommun, .rare, .legendaire]
        #expect(Set(styles.map(\.rang)).count == 4)
        #expect(Set(styles.map(\.mot)).count == 4)
        #expect(styles.filter(\.aUnReflet) == [.rare, .legendaire])
    }

    @MainActor
    @Test func imagePartageIdentiqueAvecOuSansMeteo() async throws {
        let prise = Prise(espece: brochet, longueurCm: 62, mesure: .saisie, date: Date(timeIntervalSince1970: 1_000_000),
                          lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg")
        let a = try #require(ImagePartage.png(de: prise, services: services))
        let b = try #require(ImagePartage.png(de: prise, services: services))
        #expect(a == b)
        #expect(!NettoyagePhoto.contientGPS(a))
    }

    @Test func departementLuDansLeLieuFlou() {
        #expect(Formats.departement(depuisLieuFlou: "La Marne · 94") == Departement(code: "94"))
        #expect(Formats.departement(depuisLieuFlou: "94") == nil)
        #expect(Formats.departement(depuisLieuFlou: nil) == nil)
    }
}
