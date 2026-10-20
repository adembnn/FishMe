import XCTest
import Core
@testable import BuildChallenge

// Écrits sans compilateur Apple : non exécutés. Critère 9 (mots interdits) et partie « privé en toutes lettres » de la fiche.

final class AllerAuRepereTests: XCTestCase {
    private let p = Coordonnee(latitude: 48.123456789, longitude: -2.5)

    func testPlansPartSansQuestion() {
        XCTAssertFalse(DestinationRepere.plans.demandeConfirmation)
        let url = AllerAuRepere.url(pour: .plans, position: p)
        XCTAssertEqual(url?.host, "maps.apple.com")
        XCTAssertTrue(url?.absoluteString.contains("daddr=48.123457,-2.500000") ?? false)
    }

    func testWazeEtGoogleDemandentToujoursConfirmation() {
        XCTAssertTrue(DestinationRepere.waze.demandeConfirmation)
        XCTAssertTrue(DestinationRepere.googleMaps.demandeConfirmation)
        XCTAssertEqual(AllerAuRepere.url(pour: .waze, position: p)?.scheme, "waze")
        XCTAssertEqual(AllerAuRepere.url(pour: .googleMaps, position: p)?.scheme, "comgooglemaps")
    }

    func testPointDecimalQuelleQueSoitLaLangue() {
        XCTAssertEqual(AllerAuRepere.decimal(1.5), "1.500000")
        XCTAssertEqual(AllerAuRepere.decimal(-0.25), "-0.250000")
    }

    func testLaLigneDeConfirmationNommeLApplication() {
        XCTAssertEqual(TextesReperes.confirmerTiers("Waze"), "Waze saura où se trouve ce repère. Continuer ?")
    }
}

final class TextesReperesTests: XCTestCase {
    func testAucunMotInterditDansLesTextes() {
        let interdits = ["tu peux garder", "tu peux la garder", "autorisé", "bon spot", "bon coin", "hors réserve", "pokémon", "pokédex"]
        var textes: [String] = [
            TextesReperes.etatVide, TextesReperes.paywallTexte, TextesReperes.plafondTexte, TextesReperes.aucuneReserve,
            TextesReperes.reserveSurEau("La Marne"), TextesReperes.reservesNonPlacees(1), TextesReperes.reservesNonPlacees(3),
            TextesReperes.horsDeFrance, TextesReperes.prive, TextesReperes.supprimerExplication, TextesReperes.lectureSeule,
        ]
        textes += IconeRepere.allCases.map(TextesReperes.libelle)
        for texte in textes {
            for mot in interdits { XCTAssertFalse(texte.lowercased().contains(mot), "« \(mot) » dans « \(texte) »") }
        }
    }

    func testAucuneReserveDitDeVerifierSurPlaceEtJamaisHorsReserve() {
        XCTAssertTrue(TextesReperes.aucuneReserve.contains("Vérifie sur place"))
        XCTAssertTrue(TextesReperes.reservesNonPlacees(2).contains("vérifie sur place"))
    }

    func testPluriel() {
        XCTAssertTrue(TextesReperes.reservesNonPlacees(1).hasPrefix("Une réserve"))
        XCTAssertTrue(TextesReperes.reservesNonPlacees(2).hasPrefix("2 réserves"))
    }

    func testChaqueIconeADesLibellesEtUnLibelleVocal() {
        for icone in IconeRepere.allCases {
            XCTAssertFalse(TextesReperes.libelle(icone).isEmpty)
            XCTAssertFalse(TextesReperes.libelleVocal(icone).isEmpty)
        }
        XCTAssertEqual(IconeRepere.allCases.map(TextesReperes.libelleVocal), ["parking", "poste de pêche", "danger", "amorçage"])
    }
}

final class LienSourceTests: XCTestCase {
    @MainActor
    func testSeulsLesLiensHttpsSOuvrent() {
        XCTAssertNotNil(AvertissementReserveView.lienSur("https://exemple.org/a.pdf"))
        XCTAssertNil(AvertissementReserveView.lienSur("http://exemple.org/a.pdf"))
        XCTAssertNil(AvertissementReserveView.lienSur("javascript:alert(1)"))
        XCTAssertNil(AvertissementReserveView.lienSur("pas un lien"))
    }
}

final class CalqueReperesTests: XCTestCase {
    @MainActor
    func testVisibiliteSelonLeZoom() {
        XCTAssertFalse(CalqueReperes.visible(spanLatitude: 11))
        XCTAssertTrue(CalqueReperes.visible(spanLatitude: 1))
        XCTAssertFalse(CalqueReperes.afficheLesNoms(spanLatitude: 1))
        XCTAssertTrue(CalqueReperes.afficheLesNoms(spanLatitude: 0.02))
    }
}

/// Un faux `ServiceGeo` : un département et une eau fixes.
nonisolated private struct FauxGeo: ServiceGeo {
    var departementRenvoye: Departement
    var eaux: [Eau]

    func departement(de coordonnee: Coordonnee) -> Departement { departementRenvoye }
    func lieu(de coordonnee: Coordonnee, choix: ChoixLieu?) -> Lieu { Lieu(departement: departementRenvoye, eau: eaux.first) }
    func eauxProches(_ coordonnee: Coordonnee) -> [Eau] { eaux }
    func lieuFlou(_ coordonnee: Coordonnee) -> String { "Test · \(departementRenvoye.code)" }
}

final class EvaluationReserveTests: XCTestCase {
    private let ici = Coordonnee(latitude: 48.8, longitude: 2.4)

    func testHorsDeFranceNAffichePasDAvertissement() {
        let geo = FauxGeo(departementRenvoye: .inconnu, eaux: [])
        let lieu = EvaluationReserve.evaluer(position: ici, geo: geo, chargeur: .embarque())
        XCTAssertTrue(lieu.horsDeFrance)
        XCTAssertEqual(lieu.avertissement, .aucuneConnue)
    }

    func testSeineDuValDeMarneSignaleUneReserveSourcee() {
        let seine = Eau(nom: "La Seine", cle: "seine", type: .riviere)
        let geo = FauxGeo(departementRenvoye: Departement(code: "94"), eaux: [seine])
        let lieu = EvaluationReserve.evaluer(position: ici, geo: geo, chargeur: .embarque())
        guard case .surCetteEau(let nom, let sources, _) = lieu.avertissement else {
            return XCTFail("une réserve sur la Seine du 94 était attendue, obtenu \(lieu.avertissement)")
        }
        XCTAssertEqual(nom, "La Seine")
        XCTAssertFalse(sources.isEmpty)
        XCTAssertFalse(lieu.horsDeFrance)
    }
}
