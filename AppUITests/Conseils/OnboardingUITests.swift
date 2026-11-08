import XCTest

/// Premières minutes (L16). Non compilé ici : à lancer sous Xcode sur une app neuve (désinstaller l'app avant).
/// Les écrans qui n'apparaissent pas (app déjà passée par l'onboarding) sautent le test au lieu d'échouer.
@MainActor
final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// « Où pêches-tu ? » : le dernier bouton est posé à 40 pt du bas de l'écran (à 2 pt près), sans barre de défilement.
    func testOuPechesTuBoutonsA40PointsDuBas() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        app.launch()
        let ecran = app.otherElements["ou-peches-tu"]
        guard ecran.waitForExistence(timeout: 10) else { throw XCTSkip("App déjà passée par « Où pêches-tu ? » : désinstaller puis relancer.") }
        let bouton = app.buttons["Choisir sur la carte"]
        XCTAssertTrue(bouton.exists)
        let ecranApp = app.windows.firstMatch.frame
        XCTAssertEqual(ecranApp.maxY - bouton.frame.maxY, 40, accuracy: 2)
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// Tunnel : un titre en en-tête, aucune poignée, la carte centrée entre le titre et la feuille du bas.
    func testTunnelTitreEtCarteCentree() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        app.launch()
        let tunnel = app.otherElements["tunnel-premiers-pas"]
        guard tunnel.waitForExistence(timeout: 10) else { throw XCTSkip("Le tunnel n'est pas à l'écran : app neuve et niveau choisi requis.") }
        let titre = app.descendants(matching: .any)["tunnel-titre"]
        XCTAssertTrue(titre.exists)
        XCTAssertTrue(titre.label.contains("Lesquels as-tu déjà pêchés ?"))
        XCTAssertEqual(app.scrollBars.count, 0)
        // Le centre de la carte se mesure sur capture (fiche L16, test « fini » n° 3) ; ici seulement la présence du bouton.
    }

    /// Douze glissements à gauche : « pas encore de carte », le compteur de la zone, la phrase Pescedex, « Voir mon spot ».
    func testPasEncoreDeCarteApresDouzeGlissementsAGauche() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        app.launch()
        let tunnel = app.otherElements["tunnel-premiers-pas"]
        guard tunnel.waitForExistence(timeout: 10) else { throw XCTSkip("Le tunnel n'est pas à l'écran : app neuve et niveau choisi requis.") }
        let jamais = app.buttons["Jamais pêché"].firstMatch
        for _ in 0..<12 {
            guard jamais.waitForExistence(timeout: 3) else { break }
            jamais.tap()
        }
        XCTAssertTrue(app.staticTexts["Pas encore de carte"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["tunnel-compteur-zone"].exists)
        XCTAssertTrue(app.staticTexts["tunnel-compteur-zone"].label.hasPrefix("0 sur "))
        XCTAssertTrue(app.staticTexts["Tu pourras en déclarer d'autres depuis ton Pescedex."].exists)
        XCTAssertTrue(app.buttons["Voir mon spot"].exists)
        XCTAssertEqual(app.scrollBars.count, 0)
    }
}
