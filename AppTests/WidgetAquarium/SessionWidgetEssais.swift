import Testing
import Foundation
@testable import WidgetSessionLogique

private let t0 = Date(timeIntervalSince1970: 1_800_000_000)

@Suite("AffichageSessionWidget")
struct SessionWidgetEssais {
    @Test func pasDeSession() {
        let a = AffichageSessionWidget.calculer(etat: nil, maintenant: t0)
        #expect(a.contenu == .aucuneSession)
        #expect(a.prises == 0)
        #expect(AffichageSessionWidget.datesTimeline(etat: nil, maintenant: t0) == [t0])
    }

    @Test func compteARebours() {
        let debut = t0.addingTimeInterval(-3600), fin = t0.addingTimeInterval(1800)
        let e = EtatSession(debut: debut, finLegale: fin, prises: 3)
        let a = AffichageSessionWidget.calculer(etat: e, maintenant: t0)
        #expect(a.contenu == .compteARebours(debut: debut, fin: fin))
        #expect(a.prises == 3)
        #expect(AffichageSessionWidget.datesTimeline(etat: e, maintenant: t0) == [t0, fin])
    }

    @Test func finLegalePassee() {
        let debut = t0.addingTimeInterval(-7200), fin = t0.addingTimeInterval(-60)
        let e = EtatSession(debut: debut, finLegale: fin, prises: 1)
        #expect(AffichageSessionWidget.calculer(etat: e, maintenant: t0).contenu == .finLegalePassee(fin))
        #expect(AffichageSessionWidget.datesTimeline(etat: e, maintenant: t0) == [t0])
    }

    @Test func entreeALaFinLegaleBascule() {
        let debut = t0.addingTimeInterval(-3600), fin = t0.addingTimeInterval(1800)
        let e = EtatSession(debut: debut, finLegale: fin, prises: 0)
        #expect(AffichageSessionWidget.calculer(etat: e, maintenant: fin).contenu == .finLegalePassee(fin))
    }

    @Test func pecheFermee() {
        let debut = t0, fin = t0.addingTimeInterval(-600)
        let e = EtatSession(debut: debut, finLegale: fin, prises: 0)
        #expect(AffichageSessionWidget.calculer(etat: e, maintenant: t0).contenu == .pecheFermee)
        #expect(AffichageSessionWidget.datesTimeline(etat: e, maintenant: t0) == [t0])
    }

    @Test func finInconnue() {
        let debut = t0.addingTimeInterval(-100)
        let e = EtatSession(debut: debut, finLegale: nil, prises: 2)
        #expect(AffichageSessionWidget.calculer(etat: e, maintenant: t0).contenu == .finInconnue(depuis: debut))
        #expect(AffichageSessionWidget.datesTimeline(etat: e, maintenant: t0) == [t0])
    }

    @Test func prisesNegativesRamenéesAZero() {
        let e = EtatSession(debut: t0, finLegale: nil, prises: -4)
        #expect(AffichageSessionWidget.calculer(etat: e, maintenant: t0).prises == 0)
    }

    @Test func depotAllerRetourEtTolerance() throws {
        let dossier = FileManager.default.temporaryDirectory.appendingPathComponent("sw-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dossier) }
        let url = dossier.appendingPathComponent("session-widget.json")

        #expect(DepotSessionWidget.lire(depuis: url) == nil)           // absent
        let e = EtatSession(debut: Date(timeIntervalSince1970: 1_800_000_000),
                            finLegale: Date(timeIntervalSince1970: 1_800_003_600), prises: 2)
        try DepotSessionWidget.ecrire(e, vers: url)
        #expect(DepotSessionWidget.lire(depuis: url) == e)
        try Data("pas du json".utf8).write(to: url)
        #expect(DepotSessionWidget.lire(depuis: url) == nil)           // illisible
        try DepotSessionWidget.ecrire(e, vers: url)
        try DepotSessionWidget.ecrire(nil, vers: url)                  // nil efface
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(DepotSessionWidget.lire(depuis: nil) == nil)
    }
}
