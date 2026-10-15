import XCTest

/// Parcours de la carte sur simulateur. Non compilé ici : à lancer sous Xcode (position simulée à Charenton).
@MainActor
final class CarteUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// E3 : « Choisir un autre spot » puis une espèce : la carte filtrée en 2 touchers depuis la carte.
    func testFiltreParEspeceEnDeuxToucher() throws {
        let app = XCUIApplication()
        app.launch()
        let bouton = app.buttons["Choisir un autre spot"]
        XCTAssertTrue(bouton.waitForExistence(timeout: 10))
        bouton.tap()
        let espece = app.buttons["Sandre"]
        XCTAssertTrue(espece.waitForExistence(timeout: 5))
        espece.tap()
        XCTAssertTrue(app.buttons["Filtre : Sandre"].waitForExistence(timeout: 5))
    }

    /// Aucune barre de défilement visible dans la fiche d'un coin.
    func testPasDeBarreDeDefilementDansLaFiche() throws {
        let app = XCUIApplication()
        app.launch()
        let station = app.buttons["Station OFB"].firstMatch
        XCTAssertTrue(station.waitForExistence(timeout: 10))
        station.tap()
        XCTAssertTrue(app.staticTexts["Règles du jour"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
    }
}
