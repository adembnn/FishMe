import XCTest

/// Écrit sans Mac, non exécuté. Parcours à jouer quand A a branché `.finisTonProfil()` sur Communauté (L25).
final class ProfilUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testFinisTonProfilEtRechercheSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Communauté"].tap()
        let plusTard = app.buttons["profil.plustard"]
        if plusTard.waitForExistence(timeout: 5) {
            XCTAssertEqual(app.scrollBars.count, 0)
            plusTard.tap()
        }
        XCTAssertTrue(app.textFields["profil.recherche"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
        for bouton in app.buttons.allElementsBoundByIndex where bouton.isHittable {
            XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, bouton.label)
        }
    }
}
