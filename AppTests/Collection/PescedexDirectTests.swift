import AVFoundation
import Core
import Foundation
import ImageIO
import Photos
import Testing
import UIKit
import UniformTypeIdentifiers
@testable import BuildChallenge

/// Tests du lot L18 « Pescedex direct ». Écrits sans Mac : non exécutés au moment de l'écriture.
@MainActor
struct PescedexDirectTests {
    private let services = ServicesCollection(especes: EspecesFaux(), soleil: SoleilFaux(), regles: ReglesFaux())
    private let brochet = Espece(id: "brochet")
    private let sandre = Espece(id: "sandre")

    private func nouveauDepot() throws -> DepotCartes {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return DepotCartes(conteneur: try DepotCartes.creerConteneur(enMemoire: true), dossierPhotos: dossier, services: services)
    }

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

    // MARK: Déclaration

    @Test func rechercheSanTrouveLeSandreEnPremier() {
        let toutes = services.especes.especesPechables()
        let resultat = FiltreDeclaration.especes(toutes, recherche: "san", deLaZone: [])
        #expect(resultat.first?.espece.id == "sandre")
    }

    @Test func rechercheIgnoreAccentsEtCasse() {
        let toutes = services.especes.especesPechables()
        let resultat = FiltreDeclaration.especes(toutes, recherche: "ECREVISSE", deLaZone: [])
        #expect(resultat.count == 2)
    }

    @Test func rechercheVideGardeToutEtLaZonePasseDAbord() {
        let toutes = services.especes.especesPechables()
        let resultat = FiltreDeclaration.especes(toutes, recherche: "", deLaZone: ["sandre"])
        #expect(resultat.count == toutes.count)
        #expect(resultat.first?.espece.id == "sandre")
    }

    @Test func declarerUneEspeceCreeUneCarteSansPhotoEtLeTunnelNeS_OuvrePas() async throws {
        let depot = try nouveauDepot()
        let modele = PescedexModele(depot: depot, services: services)
        _ = try await depot.enregistrerDeclaree(espece: sandre)
        await modele.charger()
        let emplacement = try #require(modele.emplacements.first { $0.id == "sandre" })
        let carte = try #require(emplacement.carte)
        #expect(carte.estDeclaree)
        #expect(carte.cheminPhoto == nil)
        // Une carte déclarée n'ouvre pas de carte pleine : elle ouvre sa fiche, avec ses infos.
        #expect(modele.infos(pour: emplacement) != nil)
    }

    // MARK: Caméra et Photos

    @Test func laCameraNeSOuvreEnUnToucherQueSiElleEstAutorisee() {
        #expect(AccesCamera.ouvreEnUnToucher(.authorized))
        #expect(!AccesCamera.ouvreEnUnToucher(.notDetermined))
        #expect(!AccesCamera.ouvreEnUnToucher(.denied))
        #expect(!AccesCamera.ouvreEnUnToucher(.restricted))
    }

    @Test func enregistrerDansPhotosNeGardeAucunGPS() throws {
        let avant = try jpegAvecGPS()
        #expect(NettoyagePhoto.contientGPS(avant))
        let apres = try #require(EnregistrementPhotos.donneesSansLieu(avant))
        #expect(!NettoyagePhoto.contientGPS(apres))
        // Un PNG fabriqué par UIKit passe tel quel ; des octets qui ne sont pas une image sont refusés.
        let png = try #require(UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }.pngData())
        #expect(EnregistrementPhotos.donneesSansLieu(png) == png)
        #expect(EnregistrementPhotos.donneesSansLieu(Data([1, 2, 3])) == nil)
    }

    @Test func laPermissionPhotosEstEnAjoutSeulOuLimite() {
        #expect(EnregistrementPhotos.peutEcrire(.authorized))
        #expect(EnregistrementPhotos.peutEcrire(.limited))
        #expect(!EnregistrementPhotos.peutEcrire(.denied))
        #expect(!EnregistrementPhotos.peutEcrire(.notDetermined))
    }

    // MARK: Libellés

    @Test func libellesEnToutesLettres() {
        #expect(LibellesCarte.frequence == "Fréquence")
        #expect(LibellesCarte.libelleTaille(estimee: false) == "Taille")
        #expect(LibellesCarte.libelleTaille(estimee: true) == "Taille · estimée")
        #expect(LibellesCarte.poidsEstime == "Poids · estimé")
        #expect(LibellesCarte.rang == "Rang")
        for court in [LibellesCarte.frequenceCourt, LibellesCarte.tailleEstimeeCourt] {
            #expect(court != "FRQ" && court != "TAI")
        }
        #expect(LibellesCarte.libelleTailleCourt(estimee: true) == "Taille est.")
    }

    @Test func valeursDeTailleEtDePoidsSansLeMotEstime() {
        let prise = Prise(espece: brochet, longueurCm: 62, mesure: .estimee, date: Date())
        #expect(Formats.tailleValeur(prise) == "62 cm")
        #expect(Formats.poidsValeur(PoidsEstime(kilos: 1.4, minKilos: 1.2, maxKilos: 1.6, source: "essai"))?.contains("estimé") == false)
    }

    // MARK: Menu de zone

    private func emplacementsDeTest(portee: PorteePescedex, cartes: [Prise]) -> CompteurPescedex {
        let especes = services.especes.especesPechables()
        let rarete: (Espece, Departement) -> ResultatRarete = { e, d in
            // Le brochet est relevé dans le 94 seulement, la perche dans le 75 seulement, le reste nulle part.
            switch (e.id, d.code) {
            case ("brochet", "94"): ResultatRarete(niveau: .commun, nPeches: 9, nTotal: 20, anneeDernierReleve: 2024, echelle: .departement)
            case ("perche", "75"): ResultatRarete(niveau: .peuCommun, nPeches: 4, nTotal: 20, anneeDernierReleve: 2023, echelle: .departement)
            default: ResultatRarete(niveau: .legendaire, nPeches: 0, nTotal: 20, anneeDernierReleve: nil, echelle: .departement)
            }
        }
        switch portee {
        case .monSpot:
            let emp = CompteurPescedex.emplacements(cartes: cartes, especes: especes, zone: Departement(code: "94"), rarete: rarete)
            return CompteurPescedex.compteur(emplacements: emp, zone: Departement(code: "94"))
        case .maRegion:
            let emp = CalculZonePescedex.emplacementsRegion(
                cartes: cartes, especes: especes, departements: [Departement(code: "75"), Departement(code: "94")], rarete: rarete)
            return CompteurPescedex.compteur(emplacements: emp, zone: Departement(code: "94"), portee: .maRegion,
                                             locutionRegion: "en Île-de-France")
        case .france:
            let emp = CalculZonePescedex.emplacementsFrance(cartes: cartes, especes: especes, reference: Departement(code: "94"),
                                                            rarete: rarete)
            return CompteurPescedex.compteur(emplacements: emp, zone: Departement(code: "94"), portee: .france)
        }
    }

    @Test func compteurMonSpotDit94() {
        let cartes = [Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg")]
        let c = emplacementsDeTest(portee: .monSpot, cartes: cartes)
        #expect(c.ligneCompteur == "1 sur 1 dans le 94")
    }

    @Test func compteurMaRegionUnitLesReleves() {
        let cartes = [Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg")]
        let c = emplacementsDeTest(portee: .maRegion, cartes: cartes)
        // Brochet (94) et perche (75) : deux espèces relevées dans la région.
        #expect(c.releveesDansLaZone == 2)
        #expect(c.ligneCompteur == "1 sur 2 en Île-de-France")
    }

    @Test func compteurFranceCompteToutesLesEspeces() {
        let cartes = [Prise(espece: brochet, date: Date(), lieuFlou: "La Marne · 94", cheminPhoto: "x.jpg"),
                      Prise.declaree(espece: sandre, date: Date())]
        let c = emplacementsDeTest(portee: .france, cartes: cartes)
        let total = services.especes.especesPechables().count
        #expect(c.releveesDansLaZone == total)
        #expect(c.legendairesEnPlus == 0)
        #expect(c.ligneCompteur == "2 sur \(total) en France")
    }

    @Test func rareteUnionPrendLeDepartementAuxPlusDePeches() {
        let a = ResultatRarete(niveau: .rare, nPeches: 2, nTotal: 30, anneeDernierReleve: 2022, echelle: .departement)
        let b = ResultatRarete(niveau: .commun, nPeches: 12, nTotal: 30, anneeDernierReleve: 2024, echelle: .departement)
        let rien = ResultatRarete(niveau: .legendaire, nPeches: 0, nTotal: 30, anneeDernierReleve: nil, echelle: .departement)
        #expect(CalculZonePescedex.rareteUnion([a, b, rien]).nPeches == 12)
        #expect(CalculZonePescedex.rareteUnion([rien]).niveau == .legendaire)
    }

    @Test func choixDeZoneRevientSurMonSpotSiLeChoixEstInconnu() {
        #expect(PorteePescedex(brut: "france") == .france)
        #expect(PorteePescedex(brut: "maRegion") == .maRegion)
        #expect(PorteePescedex(brut: "n'importe quoi") == .monSpot)
        #expect(PorteePescedex.allCases.map(\.libelle) == ["Mon spot", "Ma région", "France"])
    }

    @Test func maRegionResteGriseeSansTableDeRegions() async throws {
        let depot = try nouveauDepot()
        _ = try await depot.enregistrer(prise: Prise(espece: brochet, longueurCm: 60, mesure: .saisie, date: Date(),
                                                     lieuFlou: "Département 94", cheminPhoto: nil, gardee: true),
                                        photo: try jpegAvecGPS())
        let sans = PescedexModele(depot: depot, services: services)
        await sans.choisir(.maRegion)
        #expect(!sans.regionDisponible)
        #expect(sans.porteeMontree == .monSpot)

        let avec = PescedexModele(depot: depot, services: services, regionDe: { _ in
            RegionPescedex(nom: "Île-de-France", departements: [Departement(code: "75"), Departement(code: "94")])
        })
        await avec.choisir(.maRegion)
        #expect(avec.regionDisponible)
        #expect(avec.porteeMontree == .maRegion)
        #expect(avec.compteur.ligneCompteur?.hasSuffix("en Île-de-France") == true)

        await avec.choisir(.france)
        #expect(avec.compteur.releveesDansLaZone == services.especes.especesPechables().count)
        #expect(avec.compteur.ligneCompteur?.hasSuffix("en France") == true)
    }

    // MARK: Ma région branchée sur la table de Core (L18)

    @Test func regionDepuisCoreDonneLaLocution() {
        let idf = RegionPescedex.depuisCore(Departement(code: "94"))
        #expect(idf?.nom == "Île-de-France")
        #expect(idf?.phrase.hasPrefix("en ") == true)
        #expect(idf?.departements.contains(Departement(code: "75")) == true)
        #expect(RegionPescedex.depuisCore(Departement(code: "59"))?.phrase.hasPrefix("dans les ") == true)
        #expect(RegionPescedex.depuisCore(.inconnu) == nil)
        #expect(RegionPescedex.depuisCore(Departement(code: "zz")) == nil)
    }

    @Test func maRegionActiveAvecLeDepartementDuSpotSansCarte() async throws {
        let depot = try nouveauDepot()
        let modele = PescedexModele(depot: depot, services: services, regionDe: { RegionPescedex.depuisCore($0) })
        await modele.charger()
        #expect(!modele.regionDisponible)
        await modele.definirZoneDeRepli(Departement(code: "94"))
        #expect(modele.regionDisponible)
        await modele.choisir(.maRegion)
        #expect(modele.porteeMontree == .maRegion)
        #expect(modele.compteur.ligneCompteur?.hasSuffix("en Île-de-France") == true)
        await modele.definirZoneDeRepli(.inconnu)
        #expect(!modele.regionDisponible)
        #expect(modele.porteeMontree == .monSpot)
    }
}
