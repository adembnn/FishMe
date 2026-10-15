import Foundation
import Testing
@testable import BuildChallenge

// L10 : ce que l'écran verrouillé affiche selon l'heure. `EtatSession` est dans Widget/Session/ (cibles app et widget).
private let t0 = Date(timeIntervalSince1970: 1_792_065_600)

@Suite("L10 Écran verrouillé")
struct EtatSessionTests {
    @Test func compteAReboursPuisFinLegale() {
        let fin = t0.addingTimeInterval(120)
        let e = EtatSession(debut: t0, finLegale: fin, prises: 0)
        #expect(e.affichage(maintenant: t0, perime: false) == .compteARebours(jusqua: fin))
        #expect(e.affichage(maintenant: fin.addingTimeInterval(-1), perime: false) == .compteARebours(jusqua: fin))
        #expect(e.affichage(maintenant: fin, perime: false) == .finLegale(fin))
        #expect(e.affichage(maintenant: t0, perime: true) == .finLegale(fin))
    }

    @Test func heurePerimeEstLaFinLegaleSeulementSiFuture() {
        let fin = t0.addingTimeInterval(120)
        let e = EtatSession(debut: t0, finLegale: fin, prises: 0)
        #expect(e.heurePerimee(maintenant: t0) == fin)
        #expect(e.heurePerimee(maintenant: fin) == nil)
    }

    @Test func departHorsFenetreEstPecheFermee() {
        let e = EtatSession(debut: t0, finLegale: t0.addingTimeInterval(-1800), prises: 0)
        #expect(e.affichage(maintenant: t0, perime: false) == .pecheFermee)
        #expect(e.heurePerimee(maintenant: t0) == nil)
    }

    @Test func finInconnueNInventeAucuneHeure() {
        let e = EtatSession(debut: t0, finLegale: nil, prises: 2)
        #expect(e.affichage(maintenant: t0, perime: false) == .finInconnue(depuis: t0))
    }

    @Test func aucuneCoordonneeDansLEtat() throws {
        let json = try String(data: JSONEncoder().encode(EtatSession(debut: t0, finLegale: t0, prises: 1)), encoding: .utf8)!.lowercased()
        #expect(!json.contains("lat") && !json.contains("lon") && !json.contains("spot"))
    }
}
