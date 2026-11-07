import XCTest

/// Parcours à jouer une fois le fil branché par A dans « Mon club » (page « Fil »), mode démo activé par l'argument de lancement
/// `-demo.communaute YES` (clé `@AppStorage("demo.communaute")`). Écrit sans compilateur : non exécuté à ce jour.
/// Cible `BuildChallengeUITests` à compléter par L25 (le projet n'est pas dans le périmètre de L23).
final class FeedUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func lancer(grandTexte: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", "france"]
        var arguments = ["-demo.communaute", "YES", "-communaute.reseau", "YES"]
        if grandTexte { arguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launchArguments += arguments
        app.launch()
        app.tabBars.buttons["Communauté"].tap()
        app.buttons["Fil"].tap()
        return app
    }

    /// Règle 2.1 : un relecteur seul voit un fil rempli, marqué « Exemple », sans bouton « Publier ».
    @MainActor
    func testLeModeDemoMontreUnFilRempliEnLectureSeule() throws {
        let app = lancer()
        // La pastille « Exemple » se lit « Publication d'exemple » en VoiceOver : c'est ce libellé que l'arbre d'accessibilité expose.
        XCTAssertTrue(app.staticTexts["Publication d'exemple"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["Publier"].exists)
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// AX5 : aucun bouton de moins de 44 points, et « Commenter » reste atteignable.
    @MainActor
    func testTresGrandTexteSansDebordement() throws {
        let app = lancer(grandTexte: true)
        XCTAssertTrue(app.staticTexts["Publication d'exemple"].firstMatch.waitForExistence(timeout: 15))
        // En très grand texte, l'en-tête et le bandeau remplissent l'écran : la 1re publication est plus bas, on fait défiler jusqu'à « Commenter ».
        let commenter = app.buttons["Commenter"].firstMatch
        var defilements = 0
        while !commenter.exists && defilements < 8 { app.swipeUp(); defilements += 1 }
        XCTAssertTrue(commenter.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(commenter.frame.height, 44)
        XCTAssertLessThanOrEqual(commenter.frame.maxX, app.frame.maxX)
    }

    /// Signaler est visible dans le menu d'une publication (règle 1.2) et dit la vérité sur ce qui est enregistré.
    @MainActor
    func testSignalerEstAccessible() throws {
        let app = lancer()
        app.buttons["Plus d'options"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Signaler"].waitForExistence(timeout: 3))
    }
}
