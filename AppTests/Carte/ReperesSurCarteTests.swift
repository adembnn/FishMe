import XCTest
import Core
@testable import BuildChallenge

// Écrits sans compilateur Apple : non exécutés. Câblage de N6 dans la carte (L25).

@MainActor
final class ReperesSurCarteTests: XCTestCase {
    private let centre = Coordonnee(latitude: 48.8, longitude: 2.4)
    private func repere(_ n: Int, dx: Double = 0, supprime: Bool = false) -> Repere {
        Repere(nom: "R\(n)", position: Coordonnee(latitude: centre.latitude + dx, longitude: centre.longitude),
               cree: Date(timeIntervalSince1970: 1_700_000_000), supprime: supprime ? Date(timeIntervalSince1970: 1_700_000_100) : nil)
    }
    private func zone(span: Double) -> ZoneCarte { ZoneCarte(centre: centre, spanLatitude: span, spanLongitude: span) }

    func testCalqueEteintNeMontreRien() {
        XCTAssertTrue(ReperesSurCarte.visibles([repere(1)], region: zone(span: 0.05), calqueAllume: false).isEmpty)
    }

    func testCarteDezoomeeCacheLesReperes() {
        XCTAssertTrue(ReperesSurCarte.visibles([repere(1)], region: zone(span: 8), calqueAllume: true).isEmpty)
        XCTAssertEqual(ReperesSurCarte.visibles([repere(1)], region: zone(span: 1), calqueAllume: true).count, 1)
    }

    func testSeulsLesReperesDeLaZoneEtActifsSortent() {
        let tous = [repere(1), repere(2, dx: 5), repere(3, supprime: true)]
        let vus = ReperesSurCarte.visibles(tous, region: zone(span: 0.2), calqueAllume: true)
        XCTAssertEqual(vus.map(\.nom), ["R1"])
    }

    /// Les repères sont hors du plafond de 60 : ni comptés, ni regroupés, ni retirés du budget des stations.
    func testLesReperesNeSontPasDansLePlafondDe60() {
        let beaucoup = (0..<150).map { repere($0, dx: Double($0) * 0.0001) }
        XCTAssertEqual(ReperesSurCarte.visibles(beaucoup, region: zone(span: 0.5), calqueAllume: true).count, 150)
        XCTAssertEqual(Regroupeur.maximum, 60)
        let region = zone(span: 0.02)
        XCTAssertEqual(Regroupeur.maximumStations(pour: region), Regroupeur.maximumStations(pour: region))
        XCTAssertLessThanOrEqual(Regroupeur.maximumStations(pour: region), Regroupeur.maximum)
    }

    func testAppuiLongSeulementZoomeEtJamaisPendantLeChoixDuSpot() {
        XCTAssertTrue(ReperesSurCarte.peutPoser(region: zone(span: 0.1), modeChoixDuSpot: false))
        XCTAssertFalse(ReperesSurCarte.peutPoser(region: zone(span: 0.1), modeChoixDuSpot: true))
        XCTAssertFalse(ReperesSurCarte.peutPoser(region: zone(span: 6), modeChoixDuSpot: false))
    }

    func testUnGlissementNePoseRien() {
        XCTAssertTrue(ReperesSurCarte.gestePoseUnRepere(glissement: 3))
        XCTAssertFalse(ReperesSurCarte.gestePoseUnRepere(glissement: 40))
    }

    func testLaPointeDeLEpingleMarqueLEndroitExact() {
        // Le bas du rectangle est la pointe, au milieu : l'ancre `.bottom` de l'`Annotation` tombe dessus.
        let rect = CGRect(x: 0, y: 0, width: 32, height: 41)
        let boite = EpingleGoutte().path(in: rect).boundingRect
        XCTAssertEqual(boite.maxY, rect.maxY, accuracy: 0.01)
        XCTAssertEqual(boite.midX, rect.midX, accuracy: 0.01)
        XCTAssertEqual(CalqueReperes.tailleEpingle, 32)
    }

    func testChaqueTypeADesFormesDifferentes() {
        // Distincts par la forme, pas seulement par la couleur (daltonisme).
        let rect = CGRect(x: 0, y: 0, width: 24, height: 24)
        let formes = IconeRepere.allCases.map { type -> CGPath in
            var p = GlypheRepereRempli(type: type).path(in: rect)
            p.addPath(GlypheRepereTrait(type: type).path(in: rect))
            return p.cgPath
        }
        for i in formes.indices {
            XCTAssertFalse(formes[i].isEmpty)
            for j in formes.indices where j > i { XCTAssertNotEqual(formes[i], formes[j]) }
        }
    }
}
