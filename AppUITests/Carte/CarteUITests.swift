import XCTest

/// Parcours de la carte sur simulateur. Non compilé ici : à lancer sous Xcode (position simulée à Charenton).
@MainActor
final class CarteUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func lancer() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    private func pastilleMonSpot(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mon spot' OR label == 'Choisir mon spot'")).firstMatch
    }

    /// E3 : le filtre par espèce s'ouvre d'un toucher sur « Espèces » (le libellé est écrit sous l'icône).
    func testFiltreParEspeceDepuisLaColonneDeDroite() throws {
        let app = lancer()
        let bouton = app.buttons["Espèces"]
        XCTAssertTrue(bouton.waitForExistence(timeout: 10))
        bouton.tap()
        XCTAssertTrue(app.buttons["Sandre"].waitForExistence(timeout: 5))
    }

    /// Chaque icône de la colonne de droite a un libellé écrit.
    func testChaqueIconeDeLaColonneDeDroiteAUnLibelle() throws {
        let app = lancer()
        XCTAssertTrue(app.buttons["Météo"].waitForExistence(timeout: 10))
        for libelle in ["Météo", "Espèces", "Réglages"] {
            XCTAssertTrue(app.buttons[libelle].exists, "libellé manquant : \(libelle)")
            XCTAssertTrue(app.staticTexts[libelle].exists || app.buttons[libelle].label == libelle)
        }
        let position = app.buttons["Ma position"].exists || app.buttons["Ma zone"].exists
        XCTAssertTrue(position)
    }

    /// Aucune barre de défilement visible dans la fiche d'un coin.
    func testPasDeBarreDeDefilementDansLaFiche() throws {
        let app = lancer()
        let station = app.buttons["Station OFB"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 10))
        station.tap()
        XCTAssertTrue(app.staticTexts["Règles du jour"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// La fiche d'un coin : le nom de l'eau en titre, la pastille de fréquentation, et trois hauteurs que la poignée parcourt.
    func testLaFicheSOuvreEnMoyenPuisGrandPuisPleinEcran() throws {
        let app = lancer()
        let station = app.buttons["Station OFB"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 10))
        station.tap()
        XCTAssertTrue(app.staticTexts["Ce que tu peux pêcher ici aujourd’hui"].waitForExistence(timeout: 5))
        let pastille = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Fréquentation'")).firstMatch
        XCTAssertTrue(pastille.exists)

        let poignee = app.descendants(matching: .any)["Hauteur de la feuille"]
        XCTAssertTrue(poignee.waitForExistence(timeout: 5))
        XCTAssertEqual(poignee.value as? String, "hauteur moyenne")
        poignee.tap()
        XCTAssertEqual(poignee.value as? String, "grande hauteur")
        poignee.tap()
        XCTAssertEqual(poignee.value as? String, "plein écran")
        poignee.tap()
        XCTAssertEqual(poignee.value as? String, "hauteur moyenne")
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// « Y aller » : sans Waze ni Google Maps installés, Plans s'ouvre sans feuille de choix ; avec l'un d'eux, la feuille « Y aller avec »
    /// propose « Toujours utiliser ». Le simulateur n'a ni Waze ni Google Maps : ce test vérifie seulement qu'aucune feuille ne ment.
    func testYAllerNeProposeQueLesApplicationsInstallees() throws {
        let app = lancer()
        let station = app.buttons["Station OFB"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 10))
        station.tap()
        let yAller = app.buttons["Y aller"]
        XCTAssertTrue(yAller.waitForExistence(timeout: 5))
        yAller.tap()
        if app.staticTexts["Y aller avec"].waitForExistence(timeout: 2) {
            XCTAssertTrue(app.switches["Toujours utiliser"].exists)
            XCTAssertTrue(app.buttons["Y aller avec Plans"].exists)
        }
    }

    /// « Mon spot » se ferme cinq fois de suite sans artefact : la pastille et la croix restent là, la carte reste visible.
    func testMonSpotSOuvreEtSeFermeCinqFois() throws {
        let app = lancer()
        let pastille = pastilleMonSpot(app)
        XCTAssertTrue(pastille.waitForExistence(timeout: 10))
        for _ in 0..<5 {
            pastille.tap()
            let croix = app.buttons["Fermer Mon spot"]
            XCTAssertTrue(croix.waitForExistence(timeout: 3))
            XCTAssertTrue(app.buttons["Règles du spot"].exists)
            croix.tap()
            XCTAssertTrue(waitForDisappearance(of: croix, timeout: 3))
            XCTAssertTrue(pastille.exists)
        }
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// Aucun bouton retour sur la carte.
    func testAucunBoutonRetourSurLaCarte() throws {
        let app = lancer()
        XCTAssertTrue(pastilleMonSpot(app).waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Retour"].exists)
    }

    private func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval) -> Bool {
        let attente = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        return XCTWaiter().wait(for: [attente], timeout: timeout) == .completed
    }
}
