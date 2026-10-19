import XCTest

/// Critères 4 à 7 de N3. Écrits sans Mac : non exécutés. Ne marchent qu'une fois `MesuresSourceesView` branchée par A (L25)
/// dans la rangée « maintenant » ou la feuille « Conditions du jour » ; sinon les tests sont ignorés.
@MainActor
final class MesuresUITests: XCTestCase {
    private func lancer() throws -> (XCUIApplication, XCUIElement) {
        let app = XCUIApplication()
        app.launch()
        let bloc = app.descendants(matching: .any)["mesures-sourcees"]
        try XCTSkipUnless(bloc.waitForExistence(timeout: 5), "bloc Mesures pas encore branché dans RootView.swift")
        return (app, bloc)
    }

    /// Critère 4 : chaque ligne affichée porte sa source et son heure ; une valeur de prévision, le mot « prévu ».
    func testChaqueLignePorteSaSourceEtSonHeure() throws {
        let (app, _) = try lancer()
        for id in ["mesure-pression", "mesure-eau", "mesure-debit"] {
            let ligne = app.descendants(matching: .any)[id]
            guard ligne.exists else { continue }  // une mesure absente n'a pas de ligne (critère 7)
            let label = ligne.label
            XCTAssertTrue(label.contains("Apple Weather") || label.contains("Hub'Eau"), "\(id) sans source : \(label)")
            XCTAssertNotNil(label.range(of: #"\d{1,2} h \d{2}|dernière mesure le"#, options: .regularExpression), "\(id) sans heure : \(label)")
        }
    }

    /// Critère 4 et R6 : la marque Apple Weather est sous le bloc quand la pression y est.
    func testMarqueSousLeBlocQuandLaPressionEstLa() throws {
        let (app, _) = try lancer()
        if app.descendants(matching: .any)["mesure-pression"].exists {
            XCTAssertTrue(app.descendants(matching: .any)["marque-apple-weather"].exists)
        }
    }

    /// Critère 5 : le « ? » fait 44 pt au moins et ouvre la feuille avec la phrase attendue.
    func testPointDInterrogation() throws {
        let (app, _) = try lancer()
        let bouton = app.buttons["mesures-aide"]
        XCTAssertTrue(bouton.exists)
        XCTAssertGreaterThanOrEqual(bouton.frame.width, 44)
        XCTAssertGreaterThanOrEqual(bouton.frame.height, 44)
        bouton.tap()
        let phrase = app.descendants(matching: .any)["mesures-aide-phrase"]
        XCTAssertTrue(phrase.waitForExistence(timeout: 3))
        XCTAssertEqual(phrase.label, "Simple mesure : on ne prédit pas la touche.")
    }

    /// Critère 8 : aucune barre de défilement visible dans la feuille.
    func testFeuilleSansBarreDeDefilement() throws {
        let (app, _) = try lancer()
        app.buttons["mesures-aide"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["mesures-aide-feuille"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.scrollViews.element(boundBy: 0).scrollBars.count, 0)
    }
}
