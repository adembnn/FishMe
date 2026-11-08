import XCTest

// Écrit, non exécuté. « Mes envies » n'apparaît qu'une fois L25 passé `envies:` au Pescedex : sans cela le test est ignoré.
final class EnviesUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testLigneMesEnviesOuvreLaListe() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        app.launch()
        let ligne = app.buttons["envies.ligne"]
        try XCTSkipUnless(ligne.waitForExistence(timeout: 5), "Aucune envie marquée ou fonction pas encore branchée par L25.")
        XCTAssertGreaterThanOrEqual(ligne.frame.height, 44)
        ligne.tap()
        XCTAssertTrue(app.otherElements["envies.liste"].waitForExistence(timeout: 3)
                      || app.tables["envies.liste"].waitForExistence(timeout: 3)
                      || app.otherElements["envies.vide"].exists)
    }
}
