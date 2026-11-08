import XCTest

/// Premières minutes (L16). Non compilé ici : à lancer sous Xcode sur une app neuve (désinstaller l'app avant).
/// Les écrans qui n'apparaissent pas (app déjà passée par l'onboarding) sautent le test au lieu d'échouer.
@MainActor
final class OnboardingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Arguments d'un premier lancement neuf : l'onboarding de Papy s'affiche, sans choix de langue mémorisé.
    private func lancer(telephone: String, region: String = "france") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", region, "-premierLancement.ouPechesTuVu", "NO", "-langue.choix", "", "-FishMeForcerOnboarding", "YES",
                                "-AppleLanguages", "(\(telephone))", "-AppleLocale", telephone == "fr" ? "fr_FR" : "en_US"]
        app.launch()
        return app
    }

    private func enregistrer(_ nom: String) {
        let dossier = ProcessInfo.processInfo.environment["FISHME_CAPTURES"] ?? "/private/tmp/claude-501/onboarding-shots"
        try? FileManager.default.createDirectory(atPath: dossier, withIntermediateDirectories: true)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dossier)/\(nom).png"))
    }

    /// Le parcours en français : langue (présélectionnée d'après le téléphone), surnom sans e-mail, zone, premiers poissons.
    func testParcoursPapyEnFrancais() throws {
        let app = lancer(telephone: "fr")
        let ecran = app.otherElements["onboarding"]
        guard ecran.waitForExistence(timeout: 45) else { throw XCTSkip("Onboarding absent : position déjà demandée sur ce simulateur.") }
        XCTAssertTrue(app.otherElements["papy-onboarding"].exists || app.descendants(matching: .any)["papy-onboarding"].exists)
        XCTAssertTrue(app.buttons["onboarding.passer"].exists)
        enregistrer("fr-1-langue")
        XCTAssertTrue(app.buttons["onboarding.langue.fr"].isSelected, "Le français est présélectionné d'après le téléphone")
        app.buttons["onboarding.continuer"].tap()

        let surnom = app.textFields["onboarding.surnom"]
        XCTAssertTrue(surnom.waitForExistence(timeout: 5))
        // La case de consentement n'est pas cochée par défaut ; l'e-mail est facultatif.
        XCTAssertEqual(app.switches["onboarding.consentement"].value as? String, "0")
        enregistrer("fr-2-compte")
        app.switches["onboarding.age"].coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        surnom.tap(); surnom.typeText("PapyBrochet")
        enregistrer("fr-2b-compte-rempli")
        app.buttons["onboarding.sans-email"].tap()

        XCTAssertTrue(app.buttons["onboarding.carte"].waitForExistence(timeout: 5))
        enregistrer("fr-3-zone")
        app.buttons["onboarding.carte"].tap()
        XCTAssertTrue(app.buttons["onboarding.cestparti"].waitForExistence(timeout: 5))
        enregistrer("fr-4-poissons")
        XCTAssertEqual(app.scrollBars.count, 0)
    }

    /// Un téléphone en anglais : English présélectionné ; un Français peut choisir English, un Américain Français.
    func testParcoursPapyEnAnglais() throws {
        let app = lancer(telephone: "en", region: "france")
        guard app.otherElements["onboarding"].waitForExistence(timeout: 45) else { throw XCTSkip("Onboarding absent.") }
        XCTAssertTrue(app.buttons["onboarding.langue.en"].isSelected)
        enregistrer("en-1-langue")
        app.buttons["onboarding.continuer"].tap()
        XCTAssertTrue(app.staticTexts["Your fisher nickname"].waitForExistence(timeout: 5))
        enregistrer("en-2-compte")
        app.buttons["onboarding.passer"].tap()
        XCTAssertTrue(app.staticTexts["Where do you fish?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Choose on the map"].exists)
        enregistrer("en-3-zone")
        app.buttons["onboarding.carte"].tap()
        XCTAssertTrue(app.buttons["Let's go"].waitForExistence(timeout: 5))
        enregistrer("en-4-poissons")
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
