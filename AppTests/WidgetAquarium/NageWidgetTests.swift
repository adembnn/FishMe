import Testing
import Foundation
@testable import WidgetAquariumLogique

private func poissons(_ n: Int) -> [InstantaneAquarium.Poisson] {
    (0..<n).map { InstantaneAquarium.Poisson(id: "p\($0)", slug: "brochet", rarete: $0 % 4, relache: true) }
}

private let t0 = Date(timeIntervalSince1970: 1_800_000_000) // multiple de 20 min ? vérifié par les tests via décalages

@Suite("NageWidget")
struct NageWidgetTests {
    @Test func deterministe() {
        let a = NageWidget.placements(poissons(8), a: t0, dernierRepas: nil, limite: 8)
        let b = NageWidget.placements(poissons(8), a: t0, dernierRepas: nil, limite: 8)
        #expect(a == b)
        // Même créneau, instant différent : même résultat.
        let c = NageWidget.placements(poissons(8), a: t0.addingTimeInterval(1), dernierRepas: nil, limite: 8)
        let creneau = { (d: Date) in Int(d.timeIntervalSince1970 / NageWidget.pas) }
        if creneau(t0) == creneau(t0.addingTimeInterval(1)) { #expect(a == c) }
    }

    @Test func stabiliteEnZero() {
        // Instant 0 : deux appels donnent le même x, dans les bornes.
        let p = NageWidget.placements(poissons(1), a: Date(timeIntervalSince1970: 0), dernierRepas: nil, limite: 1)
        let q = NageWidget.placements(poissons(1), a: Date(timeIntervalSince1970: 0), dernierRepas: nil, limite: 1)
        #expect(p[0].x == q[0].x)
        #expect(p[0].x >= 0.18 && p[0].x <= 0.82)
    }

    @Test func bornes() {
        for k in 0..<200 {
            let instant = t0.addingTimeInterval(Double(k) * NageWidget.pas)
            for p in NageWidget.placements(poissons(12), a: instant, dernierRepas: nil, limite: 12) {
                #expect(p.x >= 0.18 && p.x <= 0.82)
                #expect(p.y >= 0.15 && p.y <= 0.85)
                #expect(p.echelle >= 0.75 && p.echelle <= 1.25)
                #expect(!p.auRepas)
            }
        }
    }

    @Test func limite() {
        #expect(NageWidget.placements(poissons(10), a: t0, dernierRepas: nil, limite: 4).map(\.id) == ["p0", "p1", "p2", "p3"])
        #expect(NageWidget.placements(poissons(3), a: t0, dernierRepas: nil, limite: 10).count == 3)
        #expect(NageWidget.placements(poissons(3), a: t0, dernierRepas: nil, limite: 0).isEmpty)
        #expect(NageWidget.placements([], a: t0, dernierRepas: nil, limite: 5).isEmpty)
    }

    @Test func couloirsDistincts() {
        for n in [1, 2, 5, 12] {
            for k in 0..<50 {
                let instant = t0.addingTimeInterval(Double(k) * NageWidget.pas)
                let ys = NageWidget.placements(poissons(n), a: instant, dernierRepas: nil, limite: n).map(\.y)
                #expect(ys == ys.sorted())
                for (a, b) in zip(ys, ys.dropFirst()) { #expect(b - a > 0.7 / Double(n) * 0.35) }
            }
        }
    }

    @Test func echelleSuitLaRarete() {
        let p = NageWidget.placements(poissons(4), a: t0, dernierRepas: nil, limite: 4)
        #expect(p[0].echelle < p[3].echelle)
        for (i, e) in p.enumerated() { #expect(abs(e.echelle - (0.9 + 0.1 * Double(i))) <= 0.05 + 1e-9) }
    }

    @Test func directionCoherenteAvecLeGlissement() {
        let p1 = NageWidget.placements(poissons(6), a: t0, dernierRepas: nil, limite: 6)
        let p2 = NageWidget.placements(poissons(6), a: t0.addingTimeInterval(NageWidget.pas), dernierRepas: nil, limite: 6)
        for (a, b) in zip(p1, p2) { #expect(b.versLaDroite == (b.x > a.x)) }
    }

    @Test func repasDansLaFenetre() {
        let repas = t0
        for decalage in [0.0, 120, 599] {
            let p = NageWidget.placements(poissons(6), a: repas.addingTimeInterval(decalage), dernierRepas: repas, limite: 6)
            #expect(p.count == 6)
            for e in p {
                #expect(e.auRepas)
                #expect(e.y >= 0.08 && e.y <= 0.25)
                #expect(e.x >= 0.25 && e.x <= 0.75)
                #expect(e.versLaDroite == (e.x < 0.5))
            }
        }
    }

    @Test func plusDeRepasApres11Minutes() {
        let p = NageWidget.placements(poissons(6), a: t0.addingTimeInterval(11 * 60), dernierRepas: t0, limite: 6)
        #expect(p.allSatisfy { !$0.auRepas })
        // Repas dans le futur : pas de repas non plus.
        let f = NageWidget.placements(poissons(2), a: t0, dernierRepas: t0.addingTimeInterval(60), limite: 2)
        #expect(f.allSatisfy { !$0.auRepas })
    }

    @Test func datesBase() {
        let depuis = t0.addingTimeInterval(123)
        let d = NageWidget.dates(depuis: depuis, dernierRepas: nil)
        #expect(d.first == depuis)
        #expect(d == d.sorted())
        #expect(Set(d).count == d.count)
        #expect(d.last! <= depuis.addingTimeInterval(NageWidget.horizon))
        #expect(d.last! > depuis.addingTimeInterval(NageWidget.horizon - NageWidget.pas))
        for date in d.dropFirst() {
            #expect(date.timeIntervalSince1970.truncatingRemainder(dividingBy: NageWidget.pas) == 0)
        }
        #expect(d.count == 1 + 18 || d.count == 1 + 19) // 6 h / 20 min = 18 frontières (± 1 selon l'alignement)
    }

    @Test func datesSurFrontiere() {
        let depuis = Date(timeIntervalSince1970: 1200 * 1_000_000)
        let d = NageWidget.dates(depuis: depuis, dernierRepas: nil)
        #expect(d.first == depuis)
        #expect(Set(d).count == d.count)
        #expect(d.count == 1 + 18)
    }

    @Test func datesAvecFinDeRepas() {
        let depuis = Date(timeIntervalSince1970: 1200 * 1_000_000 + 300)
        let repas = depuis.addingTimeInterval(-120)
        let d = NageWidget.dates(depuis: depuis, dernierRepas: repas)
        #expect(d.contains(repas.addingTimeInterval(NageWidget.dureeRepas)))
        #expect(d == d.sorted())
        #expect(Set(d).count == d.count)
        // Repas fini : pas de date en plus.
        let fini = NageWidget.dates(depuis: depuis, dernierRepas: depuis.addingTimeInterval(-3600))
        #expect(fini == NageWidget.dates(depuis: depuis, dernierRepas: nil))
    }

    @Test func nourrirSansRation() {
        var s = InstantaneAquarium(poissons: poissons(2), especes: 2, rations: 0, estPro: false, misAJour: t0)
        let avant = s
        let donne = s.nourrir(maintenant: t0)
        #expect(donne == false)
        #expect(s == avant)
    }

    @Test func nourrirAvecRation() {
        var s = InstantaneAquarium(poissons: [], especes: 0, rations: 2, estPro: true, misAJour: t0)
        let donne = s.nourrir(maintenant: t0)
        #expect(donne)
        #expect(s.rations == 1)
        #expect(s.dernierRepas == t0)
    }

    @Test func allerRetourJSON() throws {
        let s = InstantaneAquarium(poissons: poissons(5), especes: 3, rations: 4, estPro: true,
                                   dernierRepas: Date(timeIntervalSince1970: 1_700_000_000),
                                   misAJour: Date(timeIntervalSince1970: 1_700_000_100))
        let donnees = try JSONEncoder.aquarium.encode(s)
        #expect(try JSONDecoder.aquarium.decode(InstantaneAquarium.self, from: donnees) == s)
    }

    @Test func depotSansUrlRendVide() {
        #expect(DepotAquariumWidget.lire(depuis: nil) == .vide)
        #expect(DepotAquariumWidget.url() == nil) // Linux : pas d'App Group, voulu
        #expect(DepotAquariumWidget.lire(depuis: URL(fileURLWithPath: "/n/existe/pas.json")) == .vide)
    }

    @Test func depotEcritureLecture() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("aquarium-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let s = InstantaneAquarium(poissons: poissons(3), especes: 3, rations: 1, estPro: false,
                                   misAJour: Date(timeIntervalSince1970: 1_700_000_100))
        try DepotAquariumWidget.ecrire(s, vers: url)
        #expect(DepotAquariumWidget.lire(depuis: url) == s)
    }

    @Test func deuxColonnes() {
        // Formats larges : deux voisins de rangée sont de part et d'autre du milieu, et changent de côté au créneau suivant.
        for k in 0..<6 {
            let instant = t0.addingTimeInterval(Double(k) * NageWidget.pas)
            let p = NageWidget.placements(poissons(5), a: instant, dernierRepas: nil, limite: 5, colonnes: 2)
            #expect(p.count == 5)
            #expect((p[0].x < 0.5) != (p[1].x < 0.5))
            #expect(abs(p[0].y - p[1].y) < 0.25)
            for q in p { #expect(q.x >= 0.18 && q.x <= 0.82) }
        }
        let a = NageWidget.placements(poissons(2), a: t0, dernierRepas: nil, limite: 2, colonnes: 2)
        let b = NageWidget.placements(poissons(2), a: t0.addingTimeInterval(NageWidget.pas), dernierRepas: nil, limite: 2, colonnes: 2)
        #expect((a[0].x < 0.5) != (b[0].x < 0.5))
        #expect(b[0].versLaDroite == (b[0].x > a[0].x))
    }
}
