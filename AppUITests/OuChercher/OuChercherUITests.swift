import XCTest

/// Parcours « Choisir un autre spot » sur simulateur. Non compilé ici : à lancer sous Xcode (position simulée à Charenton)
/// une fois l'écran branché par A à côté du filtre de la carte.
@MainActor
final class OuChercherUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// E3 : une espèce en image, puis au plus 3 coins avec « N pêches, dernier relevé AAAA » et l'ouverture du jour.
    func testSandreDonneAuPlusTroisCoins() throws {
        let app = XCUIApplication()
        app.launch()
        let bouton = app.buttons["Choisir un autre spot"]
        XCTAssertTrue(bouton.waitForExistence(timeout: 10))
        bouton.tap()
        let sandre = app.buttons["Sandre"]
        XCTAssertTrue(sandre.waitForExistence(timeout: 5))
        sandre.tap()
        XCTAssertTrue(app.staticTexts["© contributeurs OpenStreetMap"].waitForExistence(timeout: 5))
        let releves = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'dernier relevé'"))
        XCTAssertGreaterThanOrEqual(releves.count, 1)
        XCTAssertLessThanOrEqual(releves.count, 3)
        XCTAssertEqual(app.scrollBars.count, 0)
    }
}
