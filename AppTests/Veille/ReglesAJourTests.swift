import XCTest
import Core
@testable import BuildChallenge

#if DEBUG
@MainActor
final class ReglesAJourTests: XCTestCase {
    func testAdresseVideOuNonHttpsEstIgnoree() {
        XCTAssertNil(ReglesAJour.adresse(info: [:]))
        XCTAssertNil(ReglesAJour.adresse(info: ["ReglesBaseURL": ""]))
        XCTAssertNil(ReglesAJour.adresse(info: ["ReglesBaseURL": "http://exemple.org/regles/"]))
        XCTAssertEqual(ReglesAJour.adresse(info: ["ReglesBaseURL": "https://exemple.org/regles/"])?.host, "exemple.org")
    }

    func testSansReseauLeRapportEstVideEtRienNePlante() async {
        let copies = FileManager.default.temporaryDirectory.appendingPathComponent("veille-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: copies) }
        let faux = ReglesAJour.fauxServeur([:], enLigne: false)
        let rapport = await ReglesAJour.lancer(telechargeur: faux, copies: copies)
        XCTAssertFalse(rapport.indexLu)
        XCTAssertTrue(rapport.adoptes.isEmpty)
        XCTAssertEqual(faux.chemins, ["index.json"])
    }

    func testSansAdresseLeTelechargeurParDefautNeFaitRien() async {
        let copies = FileManager.default.temporaryDirectory.appendingPathComponent("veille-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: copies) }
        let rapport = await ReglesAJour.lancer(telechargeur: TelechargeFichierSansAdresse(), copies: copies)
        XCTAssertFalse(rapport.indexLu)
    }
}
#endif
