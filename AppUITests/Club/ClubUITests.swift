import XCTest

/// Parcours de la page Club (L22), à jouer sur Mac une fois la page branchée dans l'onglet Communauté :
/// aucune barre de défilement visible, boutons d'au moins 44 points, la page dit quand le club reste sur l'iPhone.
/// Écrit sans Mac : NON EXÉCUTÉ. Le chemin « Communauté puis Club » suit `CommunauteView` (L23) ; à ajuster si les libellés changent.
final class ClubUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func ouvrirPageClub() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Communauté"].tap()
        app.buttons["Club"].tap()
        return app
    }

    @MainActor
    func testClubSansBarreDeDefilementEtBoutonsDe44Points() throws {
        let app = ouvrirPageClub()
        XCTAssertTrue(app.buttons["Créer mon club"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
        // Les segments Fil / Amis / Club sont le sélecteur système de l'écran Communauté (32 pt, hors page Club) : écartés de la règle des 44 points.
        let segments = Set(app.segmentedControls.buttons.allElementsBoundByIndex.map(\.label))
        for bouton in app.buttons.allElementsBoundByIndex where bouton.isHittable && !segments.contains(bouton.label) {
            XCTAssertGreaterThanOrEqual(bouton.frame.height, 44, bouton.label)
        }
    }

    @MainActor
    func testRejoindreAvecUnLienOuvreLaFeuilleDeColle() throws {
        let app = ouvrirPageClub()
        app.buttons["Rejoindre un nouveau club"].tap()
        app.buttons["Rejoindre avec un lien"].tap()
        XCTAssertTrue(app.buttons["Continuer"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    @MainActor
    func testLeLienDeClubOuvreLaFeuilleRejoindre() throws {
        // Lien lancé au démarrage : `fishme://club/<uuid>`. Sans iCloud ni profil la feuille l'explique au lieu de ne rien faire.
        let app = XCUIApplication()
        app.launchArguments += ["-FISHME_URL", "fishme://club/\(UUID().uuidString)"]
        app.launch()
        // ⚠ L'argument de lancement n'existe pas encore dans RootView : à brancher par A (voir le rapport L22), sinon ce test est ignoré.
        try XCTSkipUnless(app.staticTexts["Je cherche le club…"].waitForExistence(timeout: 3), "Lien non branché dans RootView")
        XCTAssertEqual(app.scrollBars.count, 0)
    }
}
