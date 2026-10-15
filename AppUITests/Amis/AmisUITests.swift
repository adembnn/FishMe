import XCTest

/// Parcours à jouer une fois le volet Amis branché par A dans Mon club : aucune barre de défilement, boutons de 44 points.
final class AmisUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAmisSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Mon club"].tap()
        app.buttons["Amis"].tap()
        XCTAssertTrue(app.staticTexts["Amis"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
        for bouton in app.buttons.allElementsBoundByIndex where bouton.isHittable {
            XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, bouton.label)
        }
    }
}
