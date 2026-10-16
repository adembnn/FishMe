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
                #expect(p.y >= 0.14 && p.y <= 0.70)
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
                #expect(e.y >= 0.08 && e.y <= 0.50)
                #expect(e.x >= 0.18 && e.x <= 0.82)
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
            // Deux voisins de rangée ne se chevauchent pas : plus d'un tiers de largeur entre eux.
            #expect(abs(p[0].x - p[1].x) >= 0.37)
        }
        let a = NageWidget.placements(poissons(2), a: t0, dernierRepas: nil, limite: 2, colonnes: 2)
        let b = NageWidget.placements(poissons(2), a: t0.addingTimeInterval(NageWidget.pas), dernierRepas: nil, limite: 2, colonnes: 2)
        #expect((a[0].x < 0.5) != (b[0].x < 0.5))
        #expect(b[0].versLaDroite == (b[0].x > a[0].x))
    }

    @Test func ancienJSONSansNom() throws {
        // Fichier écrit avant l'ajout de `nom` (et sans `nombre`) : il se lit, `nom` vaut nil.
        let json = """
        {"dernierRepas":null,"especes":2,"misAJour":"2023-11-14T22:15:00Z","rations":1,"estPro":true,
         "poissons":[{"id":"a","slug":"brochet","rarete":3,"relache":true,"nombre":2},
                     {"id":"b","slug":"sandre","rarete":2,"relache":false}]}
        """
        let s = try JSONDecoder.aquarium.decode(InstantaneAquarium.self, from: Data(json.utf8))
        #expect(s.poissons.count == 2)
        #expect(s.poissons[0].nom == nil)
        #expect(s.poissons[0].nombre == 2)
        #expect(s.poissons[1].nombre == 1)
    }

    @Test func nomFaitLAllerRetour() throws {
        let p = InstantaneAquarium.Poisson(id: "a", slug: "brochet", rarete: 3, relache: true, nom: "Brochet")
        let s = InstantaneAquarium(poissons: [p], especes: 1, rations: 0, estPro: false, misAJour: t0)
        let relu = try JSONDecoder.aquarium.decode(InstantaneAquarium.self, from: JSONEncoder.aquarium.encode(s))
        #expect(relu.poissons.first?.nom == "Brochet")
    }

    @Test func plafondDe200() {
        #expect(InstantaneAquarium.plafond == 200)
        let s = InstantaneAquarium(poissons: poissons(250), especes: 40, rations: 0, estPro: true, misAJour: t0)
        #expect(s.poissons.count == 200)
    }

    @Test func limitesAffichees() {
        #expect(InstantaneAquarium.limiteAffichee(petit: true) == 3)
        #expect(InstantaneAquarium.limiteAffichee(petit: false) == 5)
    }

    @Test func retenusDansLOrdreChoisi() {
        let s = InstantaneAquarium(poissons: poissons(8), especes: 8, rations: 0, estPro: true, misAJour: t0)
        let r = s.retenus(choisis: ["p5", "p1", "p3"], limite: 5)
        #expect(r.map(\.id) == ["p5", "p1", "p3"])
    }

    @Test func retenusIgnorentLesDisparusEtLesDoublons() {
        let s = InstantaneAquarium(poissons: poissons(4), especes: 4, rations: 0, estPro: true, misAJour: t0)
        #expect(s.retenus(choisis: ["zz", "p2", "p2", "p0"], limite: 5).map(\.id) == ["p2", "p0"])
    }

    @Test func retenusRespectentLaLimite() {
        let s = InstantaneAquarium(poissons: poissons(8), especes: 8, rations: 0, estPro: true, misAJour: t0)
        #expect(s.retenus(choisis: ["p0", "p1", "p2", "p3", "p4", "p5", "p6"], limite: 3).map(\.id) == ["p0", "p1", "p2"])
    }

    @Test func retenusSansChoixPrennentLesPlusRares() {
        let s = InstantaneAquarium(poissons: poissons(8), especes: 8, rations: 0, estPro: true, misAJour: t0)
        #expect(s.retenus(choisis: nil, limite: 5).map(\.id) == ["p0", "p1", "p2", "p3", "p4"])
        #expect(s.retenus(choisis: [], limite: 3).map(\.id) == ["p0", "p1", "p2"])
        // Tous les choix ont disparu : repli sur les plus rares, jamais une eau vide.
        #expect(s.retenus(choisis: ["zz"], limite: 3).map(\.id) == ["p0", "p1", "p2"])
        #expect(InstantaneAquarium.vide.retenus(choisis: nil, limite: 5).isEmpty)
    }
}

@Suite("Nage")
struct NageTests {
    private let slugs = ["brochet", "gardon", "tanche", "truite-fario", "perche-commune", "silure"]

    private func boucle(_ slug: String, id: String = "p1", longueur: Double = 0.23, rapport: Double = 170.0 / 364,
                        repas: Bool = false) -> [NageWidget.PoseNage] {
        NageWidget.boucle(id: id, slug: slug, creneau: 7, longueur: longueur, rapport: rapport, repas: repas)
    }

    @Test func deterministe() {
        #expect(boucle("brochet") == boucle("brochet"))
        #expect(boucle("brochet", id: "p1") != boucle("brochet", id: "p2"))
    }

    @Test func especesDeNageJS() {
        #expect(NageWidget.espece("brochet").croisiere == 0.30)
        #expect(NageWidget.espece("perche-commune") == NageWidget.espece("perche"))
        #expect(NageWidget.espece("silure") == NageWidget.espece("gardon"))
    }

    @Test func resteDansLAquarium() {
        for slug in slugs {
            let poses = boucle(slug)
            #expect(poses.count == 80)
            for q in poses {
                #expect(q.x >= 0.23 * 0.45 - 1e-9 && q.x <= 1 - 0.23 * 0.45 + 1e-9, "\(slug) x \(q.x)")
                #expect(q.y >= 0.12 && q.y <= 0.72, "\(slug) y \(q.y)")
                #expect(abs(q.sens) >= 0.18 && abs(q.sens) <= 1)
                #expect((0..<8).contains(q.image))
                #expect(q.profondeur >= 0 && q.profondeur <= 1)
                #expect(abs(q.assiette) <= 0.22 + 1e-9)
            }
        }
    }

    /// La boucle se referme : de la dernière pose à la première, pas plus de saut qu'entre deux images.
    @Test func boucleSansSaut() {
        for slug in slugs {
            let poses = boucle(slug)
            let e = NageWidget.espece(slug)
            // Au plus 1,5 fois la croisière sur 1/8 s, plus une marge pour le recalage de la boucle.
            let maxPas = e.croisiere * 0.23 * 1.5 / 8 + 0.01
            for j in 0..<80 {
                let a = poses[j], b = poses[(j + 1) % 80]
                #expect(abs(b.x - a.x) <= maxPas, "\(slug) saut en x entre \(j) et \(j + 1)")
                // Un demi-tour passe par la tranche (±0,18) : jamais de bascule de face à face d'une image à l'autre.
                #expect(abs(b.sens - a.sens) <= 1.0, "\(slug) volte-face entre \(j) et \(j + 1)")
            }
        }
    }

    /// Il nage vraiment : il parcourt du chemin, et il regarde là où il va.
    @Test func nageVersOuIlRegarde() {
        for slug in slugs {
            let poses = boucle(slug)
            var chemin = 0.0, dansLeBonSens = 0, avance = 0
            for j in 0..<80 {
                let dx = poses[(j + 1) % 80].x - poses[j].x
                chemin += abs(dx)
                if abs(dx) > 0.002 { avance += 1; if (dx > 0) == (poses[j].sens > 0) { dansLeBonSens += 1 } }
            }
            #expect(chemin >= 0.15, "\(slug) ne nage presque pas (\(chemin))")
            #expect(Double(dansLeBonSens) >= 0.9 * Double(avance), "\(slug) nage à reculons")
        }
    }

    /// La queue bat sans arrêt : l'image avance de 0 à 4 crans par copie, et fait des tours entiers sur la boucle.
    @Test func battementContinu() {
        for slug in slugs {
            let poses = boucle(slug)
            var crans = 0
            for j in 0..<80 {
                let d = (poses[(j + 1) % 80].image - poses[j].image + 8) % 8
                #expect(d <= 4)
                crans += d
            }
            #expect(crans % 8 == 0, "\(slug) : la boucle ne retombe pas sur la même image")
            #expect(crans >= 8 * 8, "\(slug) : moins d'un battement par seconde")
        }
    }

    /// Chaque espèce reste dans sa bande : la tanche près du fond, l'ablette près de la surface ; au repas, en haut.
    @Test func bandesDeHauteur() {
        let moyenne: ([NageWidget.PoseNage]) -> Double = { $0.reduce(0) { $0 + $1.y } / Double($0.count) }
        #expect(moyenne(boucle("tanche")) > moyenne(boucle("ablette")))
        #expect(moyenne(boucle("tanche", repas: true)) < 0.30)
    }

    /// Petit widget (poisson à 0,44 de la largeur) : il reste dedans.
    @Test func petitWidget() {
        for q in boucle("brochet", longueur: 0.44, rapport: 1) {
            #expect(q.x >= 0.44 * 0.45 - 1e-9 && q.x <= 1 - 0.44 * 0.45 + 1e-9)
        }
    }

    /// À 16 images/s (160 copies), la boucle se referme aussi et le poisson avance par petits pas.
    @Test func boucleA16ImagesParSeconde() {
        let poses = NageWidget.boucle(id: "p1", slug: "gardon", creneau: 7, nombre: 160, longueur: 0.23,
                                      rapport: 170.0 / 364)
        #expect(poses.count == 160)
        let maxPas = NageWidget.espece("gardon").croisiere * 0.23 * 1.5 / 16 + 0.006
        for j in 0..<160 { #expect(abs(poses[(j + 1) % 160].x - poses[j].x) <= maxPas) }
    }
}

@Suite("Pleine eau")
struct PleineEauTests {
    private let slugs = ["brochet", "gardon", "tanche", "truite-fario", "silure"]
    private func boucle(_ slug: String, id: String = "p1", rapport: Double = 170.0 / 364) -> [NageWidget.PoseNage] {
        NageWidget.traversees(id: id, slug: slug, creneau: 3, nombre: 160, longueur: 0.26, rapport: rapport)
    }
    private func dehors(_ q: NageWidget.PoseNage) -> Bool {
        let demi = 0.26 * q.echelle / 2
        return q.x + demi < 0 || q.x - demi > 1 || q.y < -0.05 || q.y > 1.05 || q.opacite < 0.02
    }

    @Test func deterministeEtPropreAChaquePoisson() {
        #expect(boucle("gardon") == boucle("gardon"))
        #expect(boucle("gardon", id: "p1") != boucle("gardon", id: "p2"))
    }

    /// Il sort du widget et rentre ailleurs : la boucle passe hors du cadre, et elle se referme hors du cadre.
    @Test func sortEtRevient() {
        for slug in slugs {
            for id in ["a", "b", "c", "d"] {
                let poses = boucle(slug, id: id)
                #expect(poses.count == 160)
                #expect(poses.contains(where: dehors), "\(slug) \(id) ne sort jamais")
                #expect(poses.contains { !dehors($0) }, "\(slug) \(id) ne se voit jamais")
                #expect(dehors(poses[0]), "\(slug) \(id) : la boucle doit se refermer hors du cadre")
            }
        }
    }

    /// Dans le cadre, il avance sans saut et regarde là où il va.
    @Test func nageFluideDansLeCadre() {
        for slug in slugs {
            let poses = boucle(slug)
            var bon = 0, avance = 0
            for j in 0..<159 where !dehors(poses[j]) && !dehors(poses[j + 1]) {
                let dx = poses[j + 1].x - poses[j].x
                #expect(abs(dx) < 0.06 && abs(poses[j + 1].y - poses[j].y) < 0.12, "\(slug) saut à \(j)")
                if abs(dx) > 0.002 { avance += 1; if (dx > 0) == (poses[j].sens > 0) { bon += 1 } }
            }
            #expect(Double(bon) >= 0.9 * Double(avance), "\(slug) nage à reculons")
        }
    }

    /// Il va vers le fond et en revient : sur quelques boucles, des poissons rapetissent jusqu'au loin et
    /// d'autres passent tout près, plus grands que nature.
    @Test func versLeFondEtVersNous() {
        var loin = 0, pres = 0
        for slug in slugs {
            for id in ["a", "b", "c", "d", "e", "f"] {
                let poses = boucle(slug, id: id)
                if poses.contains(where: { $0.profondeur > 0.95 }) { loin += 1 }
                if poses.contains(where: { $0.echelle > 1.1 && !dehors($0) }) { pres += 1 }
            }
        }
        #expect(loin >= 5 && pres >= 5, "loin \(loin), près \(pres)")
    }

    @Test func perspectiveEtOpacite() {
        for slug in slugs {
            for q in boucle(slug) {
                #expect(q.echelle >= 0.41 && q.echelle <= 1.55)
                #expect(q.opacite >= 0 && q.opacite <= 1)
                #expect(abs(q.sens) >= 0.18 && abs(q.sens) <= 1)
                #expect((0..<8).contains(q.image))
            }
        }
    }
}
