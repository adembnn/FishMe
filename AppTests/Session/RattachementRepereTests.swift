import XCTest
import Core
@testable import BuildChallenge

// Écrits sans compilateur Apple : non exécutés. Câblage de N6 dans la session (L25).

@MainActor
final class RattachementRepereTests: XCTestCase {
    private let ici = Coordonnee(latitude: 48.8, longitude: 2.4)
    private let date = Date(timeIntervalSince1970: 1_700_000_000)

    func testProposeLeRepereLePlusProche() {
        // 0,001 degré de latitude vaut environ 111 m ; 0,01 degré environ 1,1 km.
        let proche = Repere(nom: "Poste du pont", position: Coordonnee(latitude: 48.8008, longitude: 2.4), cree: date)
        let loin = Repere(nom: "Parking", position: Coordonnee(latitude: 48.81, longitude: 2.4), cree: date)
        let prise = UUID()
        let proposition = RattachementRepere.proposer(prise: prise, position: ici, reperes: [loin, proche])
        XCTAssertEqual(proposition?.idRepere, proche.id)
        XCTAssertEqual(proposition?.nomRepere, "Poste du pont")
        XCTAssertEqual(proposition?.idPrise, prise)
        XCTAssertEqual(RattachementRepere.question(try XCTUnwrap(proposition)), "Rattacher au repère Poste du pont ?")
    }

    func testRienSansPositionNiRepereAPortee() {
        let loin = Repere(nom: "Parking", position: Coordonnee(latitude: 48.81, longitude: 2.4), cree: date)
        XCTAssertNil(RattachementRepere.proposer(prise: UUID(), position: nil, reperes: [loin]))
        XCTAssertNil(RattachementRepere.proposer(prise: UUID(), position: ici, reperes: [loin]))
        XCTAssertNil(RattachementRepere.proposer(prise: UUID(), position: ici, reperes: []))
    }

    func testPasDePropositionPourUnRepereSupprimeNiDejaRattache() {
        let prise = UUID()
        let supprime = Repere(nom: "Ancien", position: ici, cree: date, supprime: date)
        XCTAssertNil(RattachementRepere.proposer(prise: prise, position: ici, reperes: [supprime]))
        let deja = Repere(nom: "Poste", position: ici, idsPrises: [prise], cree: date)
        XCTAssertNil(RattachementRepere.proposer(prise: prise, position: ici, reperes: [deja]))
    }

    func testRattacherEcritLIdentifiantDeLaPriseSurLeRepereSeulement() async throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rattachement-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let modele = ModeleReperes(depot: DepotReperes(dossier: url))
        let repere = try await modele.ajouter(nom: "Poste", note: "", icone: .poste, position: ici, abonne: true)
        let prise = UUID()
        let proposition = try XCTUnwrap(RattachementRepere.proposer(prise: prise, position: ici, reperes: modele.reperes))
        try await modele.rattacher(prise: proposition.idPrise, a: proposition.idRepere)
        XCTAssertEqual(modele.repere(id: repere.id)?.idsPrises, [prise])
        // Rattaché : plus de proposition pour cette prise.
        XCTAssertNil(RattachementRepere.proposer(prise: prise, position: ici, reperes: modele.reperes))
    }
}
