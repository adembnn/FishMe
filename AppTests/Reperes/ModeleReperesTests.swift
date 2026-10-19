import XCTest
import Core
@testable import BuildChallenge

// Écrits sans compilateur Apple : non exécutés. À lancer sur Mac avec le schéma BuildChallenge.

@MainActor
final class ModeleReperesTests: XCTestCase {
    private func nouveauModele() -> ModeleReperes {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("modele-reperes-\(UUID().uuidString)")
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return ModeleReperes(depot: DepotReperes(dossier: url))
    }

    private let ici = Coordonnee(latitude: 48.8, longitude: 2.4)

    func testTroisGratuitsPuisPaywallSansRienPerdre() async throws {
        let modele = nouveauModele()
        for n in 1...3 {
            try await modele.ajouter(nom: "Poste \(n)", note: "", icone: .poste, position: ici, abonne: false)
        }
        XCTAssertEqual(modele.actifs, 3)
        do {
            try await modele.ajouter(nom: "Quatrième", note: "", icone: .poste, position: ici, abonne: false)
            XCTFail("le paywall était attendu")
        } catch {
            XCTAssertEqual(error as? ErreurAjoutRepere, .paywall)
        }
        XCTAssertEqual(modele.actifs, 3)
        // Pro : le même ajout passe.
        try await modele.ajouter(nom: "Quatrième", note: "", icone: .poste, position: ici, abonne: true)
        XCTAssertEqual(modele.actifs, 4)
    }

    func testNomVideRefuse() async {
        let modele = nouveauModele()
        do {
            try await modele.ajouter(nom: "   ", note: "", icone: .poste, position: ici, abonne: true)
            XCTFail("nom vide refusé attendu")
        } catch {
            XCTAssertEqual(error as? ErreurAjoutRepere, .invalide(.nomVide))
        }
    }

    func testRepereRestePresentApresRechargement() async throws {
        let modele = nouveauModele()
        let r = try await modele.ajouter(nom: "Parking", note: "Chemin de halage", icone: .parking, position: ici, abonne: false)
        let autre = ModeleReperes(depot: modele.depot)
        await autre.charger()
        XCTAssertEqual(autre.reperes.map(\.id), [r.id])
        XCTAssertEqual(autre.reperes.first?.note, "Chemin de halage")
    }

    func testSuppressionLaisseUnePierreTombaleEtLibereUnePlace() async throws {
        let modele = nouveauModele()
        let r = try await modele.ajouter(nom: "A", note: "secret", icone: .poste, position: ici, abonne: false)
        try await modele.supprimer(id: r.id)
        XCTAssertEqual(modele.actifs, 0)
        let fichier = try await modele.depot.lire()
        XCTAssertEqual(fichier.count, 1)
        XCTAssertTrue(fichier[0].estSupprime)
        XCTAssertEqual(fichier[0].note, "", "la note ne reste pas dans la pierre tombale")
        XCTAssertEqual(modele.decision(abonne: false), .oui)
    }

    func testModificationEtRattachement() async throws {
        let modele = nouveauModele()
        let r = try await modele.ajouter(nom: "A", note: "", icone: .poste, position: ici, abonne: false)
        try await modele.modifier(id: r.id, nom: "  B  ", note: "n", icone: .danger)
        let prise = UUID()
        try await modele.rattacher(prise: prise, a: r.id)
        try await modele.rattacher(prise: prise, a: r.id)
        let relu = try XCTUnwrap(modele.repere(id: r.id))
        XCTAssertEqual(relu.nom, "B")
        XCTAssertEqual(relu.icone, .danger)
        XCTAssertEqual(relu.idsPrises, [prise])
    }

    func testEffacerToutVideLaListeEtLeDisque() async throws {
        let modele = nouveauModele()
        try await modele.ajouter(nom: "A", note: "", icone: .poste, position: ici, abonne: false)
        try await modele.effacerTout()
        XCTAssertTrue(modele.reperes.isEmpty)
        let fichier = try await modele.depot.lire()
        XCTAssertTrue(fichier.isEmpty)
    }

    func testPositionExacteNEstJamaisDansUnTexteAffiche() async throws {
        // Le lieu flou d'un repère est « eau · département » : le point exact ne s'écrit jamais dans un libellé.
        let modele = nouveauModele()
        let r = try await modele.ajouter(nom: "A", note: "", icone: .poste, position: ici, abonne: false)
        let libelles = [TextesReperes.libelle(r.icone), TextesReperes.compteur(actifs: modele.actifs)]
        for l in libelles { XCTAssertFalse(l.contains("48.8")) }
    }
}
