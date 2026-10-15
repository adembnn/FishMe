import XCTest

/// Parcours à jouer une fois le volet Pescedex branché par A dans RootView.swift : carte relue après avoir tué l'app.
final class PescedexUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    func testPescedexSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Pescedex"].tap()
        XCTAssertTrue(app.staticTexts["Pescedex"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
    }
}
