import XCTest

/// Parcours à jouer une fois le volet Pescedex branché par A dans RootView.swift : carte relue après avoir tué l'app.
final class PescedexUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testPescedexSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Pescedex"].tap()
        XCTAssertTrue(app.staticTexts["Pescedex"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// L18 : aucun « Amis » dans le Pescedex, et la grille « Déclarer un poisson déjà pêché » trouve le sandre en deux touchers.
    @MainActor
    func testDeclarerUnPoissonParLaGrilleSansAmisNiTunnel() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Pescedex"].tap()
        XCTAssertTrue(app.staticTexts["Pescedex"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Amis"].exists)
        XCTAssertFalse(app.segmentedControls.buttons["Amis"].exists)

        let ajouter = app.buttons["Ajouter une prise"].exists ? app.buttons["Ajouter une prise"] : app.buttons["Prendre une photo"]
        XCTAssertTrue(ajouter.waitForExistence(timeout: 5))
        ajouter.press(forDuration: 1)
        app.buttons["Déclarer un poisson déjà pêché"].firstMatch.tap()

        let recherche = app.textFields["Chercher un poisson"]
        XCTAssertTrue(recherche.waitForExistence(timeout: 5))
        recherche.tap()
        recherche.typeText("san")
        app.buttons["Sandre"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars.buttons["Pescedex"].waitForExistence(timeout: 5))
    }

    /// L18 : le menu de zone propose Mon spot, Ma région et France.
    @MainActor
    func testMenuDeZone() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Pescedex"].tap()
        let menu = app.buttons["Zone du Pescedex"]
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
        XCTAssertTrue(app.buttons["Mon spot"].exists)
        XCTAssertTrue(app.buttons["Ma région"].exists)
        XCTAssertTrue(app.buttons["France"].exists)
    }
}
