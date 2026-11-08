import XCTest

/// Parcours à jouer une fois « Mes repères » branché par Adem et A (accroches 1 et 2 de la fiche N6). Écrit sans compilateur :
/// non exécuté. Tant que l'accroche n'est pas faite, le test est sauté, il n'échoue pas.
final class ReperesUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testListeSansBarreDeDefilementEtBoutonsDe44Points() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france", "-FishMeSauterOnboarding", "YES", "-langue.choix", "fr"]
        app.launch()
        let ligne = app.buttons["Mes repères"]
        guard ligne.waitForExistence(timeout: 5) else { throw XCTSkip("« Mes repères » n'est pas encore branché (accroche 2).") }
        ligne.tap()
        XCTAssertTrue(app.staticTexts["Mes repères"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
        let ajouter = app.buttons["Ajouter un repère ici"]
        XCTAssertTrue(ajouter.exists)
        XCTAssertGreaterThanOrEqual(ajouter.frame.height, 44)
    }
}
