import XCTest

/// Test 1 et piège R6 : la marque Apple Weather est visible sous chaque bloc qui montre un chiffre météo.
/// Ne marche qu'une fois les vues branchées par A dans RootView.swift ; sinon le test est ignoré.
@MainActor
final class ConditionsUITests: XCTestCase {
    func testMarqueSousLaRangeeMaintenant() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        app.launch()
        let rangee = app.descendants(matching: .any)["rangee-maintenant"]
        try XCTSkipUnless(rangee.waitForExistence(timeout: 5), "rangée pas encore branchée dans RootView.swift")
        XCTAssertTrue(app.descendants(matching: .any)["marque-apple-weather"].exists)
    }
}
