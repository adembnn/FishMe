import XCTest

/// Parcours à jouer une fois la liste des conversations branchée par A dans Communauté (nom de l'onglet et du bouton à ajuster) :
/// aucune barre de défilement, boutons de 44 points. Écrit sans pouvoir l'exécuter.
final class ChatUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testMessagesSansBarreDeDefilement() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france", "-FishMeSauterOnboarding", "YES", "-langue.choix", "fr"]
        app.launchArguments += ["-communaute.reseau", "YES"]
        app.launch()
        app.tabBars.buttons["Communauté"].tap()
        let messages = app.buttons["Messages"]
        XCTAssertTrue(messages.waitForExistence(timeout: 20))
        messages.tap()
        // Un toucher peut se perdre pendant le chargement de l'onglet : un second toucher, puis une attente large.
        if !app.navigationBars["Messages"].waitForExistence(timeout: 5), messages.exists { messages.tap() }
        XCTAssertTrue(app.navigationBars["Messages"].waitForExistence(timeout: 20))
        XCTAssertEqual(app.scrollBars.count, 0)
        for bouton in app.scrollViews.buttons.allElementsBoundByIndex where bouton.isHittable {
            XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, bouton.label)
        }
    }

    @MainActor
    func testTexteLePlusGrandSansBarre() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france", "-FishMeSauterOnboarding", "YES", "-langue.choix", "fr"]
        app.launchArguments += ["-communaute.reseau", "YES"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        app.tabBars.buttons["Communauté"].tap()
        app.buttons["Messages"].tap()
        XCTAssertTrue(app.navigationBars["Messages"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
    }
}
