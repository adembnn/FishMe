import XCTest
import Core
@testable import BuildChallenge

// Écrits sans compilateur Apple : non exécutés. À lancer sur Mac avec le schéma BuildChallenge.

@MainActor
final class DepotReperesTests: XCTestCase {
    /// Un dossier neuf par test, effacé à la fin.
    private func nouveauDossier() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("reperes-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }

    private func exemple(_ nom: String = "Poste") -> Repere {
        Repere(nom: nom, position: Coordonnee(latitude: 48.8, longitude: 2.4), cree: Date(timeIntervalSince1970: 1_000))
    }

    func testFichierAbsentDonneListeVide() async throws {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        let liste = try await depot.lire()
        XCTAssertTrue(liste.isEmpty)
    }

    func testEcritureEtRelecture() async throws {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        let r = exemple()
        try await depot.mettreAJour { $0 + [r] }
        let relu = try await DepotReperes(dossier: dossier).lire()
        XCTAssertEqual(relu, [r])
    }

    func testFichierDUneVersionFutureNEstPasEcrase() async throws {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let futur = Data(#"{"version": 99, "reperes": []}"#.utf8)
        try futur.write(to: dossier.appendingPathComponent("reperes.json"))
        let r = exemple()
        do {
            try await depot.mettreAJour { $0 + [r] }
            XCTFail("l'écriture aurait dû être refusée")
        } catch ErreurDepotReperes.versionFuture(let v) {
            XCTAssertEqual(v, 99)
        }
        XCTAssertEqual(try Data(contentsOf: dossier.appendingPathComponent("reperes.json")), futur)
    }

    func testFichierIllisibleEstCopieAvantDeRepartirDeZero() async throws {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        try Data("{ pas du json".utf8).write(to: dossier.appendingPathComponent("reperes.json"))
        let r = exemple()
        try await depot.mettreAJour { $0 + [r] }
        XCTAssertTrue(FileManager.default.fileExists(atPath: dossier.appendingPathComponent("reperes.illisible.json").path))
        let relu = try await depot.lire()
        XCTAssertEqual(relu, [r])
    }

    func testNomsDePhotoValides() {
        XCTAssertTrue(DepotReperes.nomPhotoValide(DepotReperes.nouveauNomPhoto()))
        XCTAssertFalse(DepotReperes.nomPhotoValide("../../reperes.json"))
        XCTAssertFalse(DepotReperes.nomPhotoValide("photo.jpg"))
        XCTAssertFalse(DepotReperes.nomPhotoValide(UUID().uuidString))
    }

    func testPhotoEcritePuisRelue() async throws {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        let nom = try await depot.ecrirePhoto(Data([1, 2, 3]))
        let relue = await depot.photo(nom)
        XCTAssertEqual(relue, Data([1, 2, 3]))
        await depot.supprimerPhotos([nom])
        let apres = await depot.photo(nom)
        XCTAssertNil(apres)
    }

    func testPhotoAvecNomInvalideRefusee() async {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        do {
            _ = try await depot.ecrirePhoto(Data([1]), nom: "../evil.jpg")
            XCTFail("nom refusé attendu")
        } catch {
            XCTAssertEqual(error as? ErreurDepotReperes, .photoInvalide)
        }
    }

    func testEffacerToutSupprimeFichierEtPhotos() async throws {
        let dossier = nouveauDossier()
        let depot = DepotReperes(dossier: dossier)
        let r = exemple()
        try await depot.mettreAJour { $0 + [r] }
        _ = try await depot.ecrirePhoto(Data([9]))
        try await depot.effacerTout()
        XCTAssertFalse(FileManager.default.fileExists(atPath: dossier.path))
        let apres = try await depot.lire()
        XCTAssertTrue(apres.isEmpty)
    }
}
