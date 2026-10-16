import Foundation
import Testing
import Core
@testable import BuildChallenge

@MainActor
struct MemoireTailleTests {
    private func defauts() -> UserDefaults {
        let nom = "MemoireTailleTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: nom)!
        d.removePersistentDomain(forName: nom)
        return d
    }

    @Test func rienDeRetenuDonneNil() {
        let m = MemoireTaille(defauts: defauts())
        #expect(m.derniere(Espece(id: "brochet", codeSandre: nil)) == nil)
    }

    @Test func chaqueEspeceAsaTaille() {
        let m = MemoireTaille(defauts: defauts())
        let brochet = Espece(id: "brochet", codeSandre: nil), perche = Espece(id: "perche", codeSandre: nil)
        m.retenir(62, pour: brochet)
        m.retenir(23, pour: perche)
        #expect(m.derniere(brochet) == 62)
        #expect(m.derniere(perche) == 23)
    }

    @Test func laTailleRetenueResteDansLaPlage() {
        let m = MemoireTaille(defauts: defauts())
        let e = Espece(id: "silure", codeSandre: nil)
        m.retenir(900, pour: e)
        #expect(m.derniere(e) == PriseLogique.plageTaille.upperBound)
    }

    @Test func lePasMoinsPlusResteDansLesBornes() {
        let bas = PriseLogique.plageTaille.lowerBound, haut = PriseLogique.plageTaille.upperBound
        #expect(MemoireTaille.apresPas(40, delta: 1) == 41)
        #expect(MemoireTaille.apresPas(40, delta: -1) == 39)
        #expect(MemoireTaille.apresPas(bas, delta: -1) == bas)
        #expect(MemoireTaille.apresPas(haut, delta: 1) == haut)
    }

    @Test func uneMesureEstimeeEnRealiteAugmenteeResteEstimee() throws {
        let contexte = PriseContexte(coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                     lieu: Lieu(departement: Departement(code: "94")), lieuFlou: "94",
                                     date: Date(timeIntervalSince1970: 1_792_065_600), prisesDuJour: [])
        let m = PriseModele(services: .faux, contexte: contexte, terminer: { _ in })
        m.memoire = MemoireTaille(defauts: defauts())
        m.choisir(try #require(m.catalogue.first { $0.espece.id == "brochet" }))
        m.mesureARValidee(PlageMesureAR(basCm: 52, centreCm: 54, hautCm: 56, lidar: false))
        m.confirmerLaTaille()
        #expect(m.plageAR != nil)
        #expect(m.mesurePourVerdict == .estimee)
        #expect(m.methode == .estimee)
    }

    @Test func laTailleDeLaDerniereRetenuePourLEspeceServDeDepart() throws {
        let contexte = PriseContexte(coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                     lieu: Lieu(departement: Departement(code: "94")), lieuFlou: "94",
                                     date: Date(timeIntervalSince1970: 1_792_065_600), prisesDuJour: [])
        let m = PriseModele(services: .faux, contexte: contexte, terminer: { _ in })
        m.memoire = MemoireTaille(defauts: defauts())
        let brochet = try #require(m.catalogue.first { $0.espece.id == "brochet" })
        m.choisir(brochet)
        m.deplacerCurseur(63)
        m.confirmerLaTaille()
        m.choisir(brochet)
        #expect(m.longueurCm == 63)
        #expect(!m.curseurBouge)
        m.ajusterCurseur(1)
        #expect(m.longueurCm == 64 && m.curseurBouge)
    }
}
