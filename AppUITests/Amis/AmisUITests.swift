import XCTest

/// Parcours à jouer une fois le volet Amis branché par A dans Mon club : aucune barre de défilement, boutons de 44 points.
final class AmisUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAmisSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-communaute.reseau", "YES"]
        app.launch()
        // L'onglet « Mon club » est devenu « Communauté » (L23) ; Amis est une page du sélecteur Fil / Amis / Club.
        app.tabBars.buttons["Communauté"].tap()
        let pageAmis = app.segmentedControls.buttons["Amis"]
        XCTAssertTrue(pageAmis.waitForExistence(timeout: 10))
        pageAmis.tap()
        // Sans iCloud (FISHME_ICLOUD=NO), la page affiche « Tes amis ne peuvent pas s'ouvrir pour l'instant » : un titre « Amis » reste présent.
        XCTAssertTrue(app.staticTexts["Amis"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.scrollBars.count, 0)
        // Les segments Fil / Amis / Club sont le sélecteur système de l'écran Communauté (32 pt, hors page Amis) : écartés de la règle des 44 points.
        let segments = Set(app.segmentedControls.buttons.allElementsBoundByIndex.map(\.label))
        for bouton in app.buttons.allElementsBoundByIndex where bouton.isHittable && !segments.contains(bouton.label) {
            XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, bouton.label)
        }
    }
}
