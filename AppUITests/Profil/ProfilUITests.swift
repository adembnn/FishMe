import XCTest

/// Parcours Communauté : « Finis ton profil » (L25), puis la page Amis et sa recherche, sans barre de défilement.
final class ProfilUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFinisTonProfilEtRechercheSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        app.launchArguments += ["-communaute.reseau", "YES"]
        app.launch()
        app.tabBars.buttons["Communauté"].tap()
        let plusTard = app.buttons["profil.plustard"]
        if plusTard.waitForExistence(timeout: 5) {
            XCTAssertEqual(app.scrollBars.count, 0)
            plusTard.tap()
        }
        // La recherche d'amis vit dans la page « Amis » ; la Communauté s'ouvre sur « Fil ».
        let amis = app.segmentedControls.buttons["Amis"]
        XCTAssertTrue(amis.waitForExistence(timeout: 5))
        amis.tap()
        XCTAssertEqual(app.scrollBars.count, 0)
        // Sans iCloud (FISHME_ICLOUD=NO, le simulateur du Mac A), `gestionAmis()` rend nil : la page Amis dit « Tes amis ne peuvent pas
        // s'ouvrir pour l'instant » et n'a pas de champ de recherche. Le champ n'est alors pas testable : on le dit au lieu de faire semblant.
        guard app.textFields["profil.recherche"].waitForExistence(timeout: 5) else {
            try XCTSkipIf(app.staticTexts["Tes amis ne peuvent pas s'ouvrir pour l'instant."].exists,
                          "Recherche d'amis absente sans iCloud : à rejouer sur un build avec iCloud.")
            return XCTFail("Le champ profil.recherche manque alors que la page Amis est disponible.")
        }
        for bouton in app.scrollViews.buttons.allElementsBoundByIndex where bouton.isHittable {
            XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, bouton.label)
        }
    }
}
