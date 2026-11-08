import XCTest

/// Carte des États-Unis sur simulateur (position simulée à Madison, Wisconsin ; réglages remis à zéro à chaque lancement).
/// Règle du produit : un toucher sur un pin n'ouvre jamais une autre application (Plans, Waze, Google Maps).
@MainActor
final class CarteUSUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func lancer(preference: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "etatsUnis", "-FISHME_POSITION_TEST", "43.0731,-89.4012",
                                "-AppleLanguages", "(en)", "-AppleLocale", "en_US", "-langue.choix", "en"]
        if let preference { app.launchArguments += ["-carte.applicationItineraire", preference] }
        app.launch()
        return app
    }

    private func unPlanDEau(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ENDSWITH[c] 'waterbody'")).firstMatch
    }

    /// Un seul toucher sur une goutte : la fiche s'ouvre ; Plans reste fermé, même avec « Toujours utiliser Plans » (cas relevé le 8 nov.).
    /// Le délai de 0,8 s de la garde est testé en logique (`CarteUSTests.yAllerIgnoreLesTouchersQuiSuiventLOuvertureDeLaFiche`) : un test
    /// d'interface ne tient pas ce délai sur un Mac chargé.
    func testUnToucherSurUneGoutteOuvreLaFicheEtPasPlans() throws {
        let app = lancer(preference: "plans")
        let goutte = unPlanDEau(app)
        let vue = goutte.waitForExistence(timeout: 90)
        let etiquettes = app.buttons.allElementsBoundByIndex.prefix(40).map(\.label).joined(separator: " | ")
        XCTAssertTrue(vue, "aucune goutte sur la carte (Madison) ? boutons vus : " + etiquettes)
        goutte.tap()
        XCTAssertTrue(app.staticTexts["Data source"].waitForExistence(timeout: 20), "la fiche ne s'est pas ouverte")
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.Maps").state, .notRunning)
        XCTAssertEqual(app.state, .runningForeground)
    }
}
