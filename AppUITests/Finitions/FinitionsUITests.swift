import CoreLocation
import XCTest

/// Captures des écrans principaux pour les finitions TestFlight (France puis États-Unis).
/// Les images sont écrites dans le dossier donné par la variable d'environnement `FISHME_CAPTURES` (sinon /private/tmp/claude-501/finitions-shots).
@MainActor
final class FinitionsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = true }

    private func enregistrer(_ nom: String) {
        let dossier = ProcessInfo.processInfo.environment["FISHME_CAPTURES"] ?? "/private/tmp/claude-501/finitions-shots"
        try? FileManager.default.createDirectory(atPath: dossier, withIntermediateDirectories: true)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "\(dossier)/\(nom).png"))
    }

    private func parcours(region: String, code: String, position: CLLocation) {
        addUIInterruptionMonitor(withDescription: "Position") { alerte in
            for titre in ["Allow While Using App", "Autoriser lorsque l’app est active", "Allow", "OK"] where alerte.buttons[titre].exists {
                alerte.buttons[titre].tap(); return true
            }
            return false
        }
        XCUIDevice.shared.location = XCUILocation(location: position)
        let app = XCUIApplication()
        app.launchArguments += ["-region.choix", region, "-FishMeForcerPro", "YES"]
        if region == "etatsUnis" { app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"] }
        app.launch()
        sleep(6); enregistrer("\(code)-00-accueil")
        let bouton = app.buttons.matching(NSPredicate(format: "label IN {'Use my location','Utiliser ma position'}")).firstMatch
        if bouton.waitForExistence(timeout: 10) { bouton.tap() }
        sleep(4); app.tap()
        sleep(12); app.tap()
        enregistrer("\(code)-01-ouverture")
        // Traverse le parcours d'arrivée (niveau, tunnel, etc.) jusqu'à la barre d'onglets.
        for i in 0..<40 {
            if app.tabBars.buttons.firstMatch.isHittable && !app.otherElements["tunnel-premiers-pas"].exists { break }
            let non = app.buttons.matching(NSPredicate(format: "label IN {'Never caught','Jamais pêché'}")).firstMatch
            let suite = app.buttons.matching(NSPredicate(format: "label IN {'Continue','Continuer','Done','Terminé','Skip','Passer','Not now','Plus tard','Later'}")).firstMatch
            if non.exists { non.tap() } else if suite.exists { suite.tap() } else { app.tap() }
            if i == 2 || i == 14 { enregistrer("\(code)-01b-parcours\(i)") }
            sleep(2)
        }
        enregistrer("\(code)-01c-apres-parcours")
        let onglets = app.tabBars.buttons
        for i in 0..<onglets.count {
            onglets.element(boundBy: i).tap(); sleep(4)
            enregistrer("\(code)-02-onglet\(i)")
        }
        if onglets.count > 1 {
            onglets.element(boundBy: 1).tap(); sleep(3)
            let station = app.buttons["Station OFB"].firstMatch
            if station.waitForExistence(timeout: 6) { station.tap(); sleep(8); enregistrer("\(code)-03-fiche") }
        }
    }

    func testCapturesFrance() {
        parcours(region: "france", code: "fr", position: CLLocation(latitude: 48.8225, longitude: 2.4120))
    }

    func testCapturesEtatsUnis() {
        parcours(region: "etatsUnis", code: "us", position: CLLocation(latitude: 43.0731, longitude: -89.4012))
    }
}
