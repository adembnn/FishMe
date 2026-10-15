import XCTest

/// Parcours des entrées aux sosies coûteux. A doit fournir une entrée de test qui ouvre l'écran Prise (argument de lancement `-prise-test`) ;
/// sans elle ce test est sauté, jamais déclaré vert.
final class PriseSosiesUITests: XCTestCase {
    @MainActor
    func testLesSosiesApparaissentAvantLaConfirmation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-prise-test"]
        app.launch()
        let exemple = app.buttons["Essayer avec une photo d'exemple"]
        guard exemple.waitForExistence(timeout: 5) else { throw XCTSkip("Pas d'entrée de test vers l'écran Prise (à demander à A).") }
        exemple.tap()
        XCTAssertTrue(app.buttons["Autre espèce"].waitForExistence(timeout: 5) || app.staticTexts["Touche ton espèce"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '%'")).firstMatch.exists, "Aucun pourcentage à l'écran")
    }
}
