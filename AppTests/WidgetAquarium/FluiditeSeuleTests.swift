import Testing
import Foundation
#if canImport(WidgetAquariumLogique)
@testable import WidgetAquariumLogique
#else
@testable import BuildChallenge
#endif

/// Mesures objectives de la nage du poisson unique (lot W1) : pose de chaque copie en points (widget petit 170 pt),
/// écart maximal entre deux copies successives, raccord de la boucle, part du temps où le poisson est visible.
/// Seule une vidéo sur iPhone réel juge le rendu final.
@Suite("Fluidité du poisson unique")
struct FluiditeSeuleTests {
    private let slugs = ["brochet", "gardon", "truite-fario", "carpe-commune", "perche-commune"]
    private let ids = ["a", "b", "c", "d", "e", "f"]
    private let cote = 170.0

    private func poses(_ id: String, _ slug: String, _ copies: Int, passages: Int = 3) -> [NageWidget.PoseNage] {
        NageWidget.traversees(id: id, slug: slug, creneau: 3, nombre: copies, imagesCycle: 1,
                              longueur: 0.26, rapport: 1, passagesMax: passages)
    }
    private func visible(_ q: NageWidget.PoseNage) -> Bool {
        let demi = 0.26 * q.echelle / 2
        return q.x + demi > 0 && q.x - demi < 1 && q.y > -0.05 && q.y < 1.05 && q.opacite > 0.02
    }

    @Test(arguments: [(40, 3), (60, 3), (80, 3), (120, 3), (40, 2), (60, 2), (60, 1)])
    func ecartsEtRaccord(copies: Int, passages: Int) {
        var pasMax = 0.0, sautEchelle = 0.0, raccordsVisibles = 0, total = 0, partVisible = 0.0
        for id in ids { for slug in slugs {
            let p = poses(id, slug, copies, passages: passages)
            total += 1
            partVisible += Double(p.filter(visible).count) / Double(p.count)
            // Raccord de la boucle : de la dernière copie à la copie 0, le poisson ne doit pas se voir sauter.
            if visible(p[p.count - 1]) && visible(p[0]) { raccordsVisibles += 1 }
            for j in 0..<p.count {
                let a = p[j], b = p[(j + 1) % p.count]
                guard visible(a), visible(b) else { continue }
                let pas = hypot((b.x - a.x) * cote, (b.y - a.y) * cote)
                pasMax = max(pasMax, pas)
                sautEchelle = max(sautEchelle, abs(b.echelle / a.echelle - 1))
            }
        } }
        print("W1MESURE copies=\(copies) passages=\(passages) pas_max_pt=\(String(format: "%.1f", pasMax)) saut_echelle_max=\(String(format: "%.3f", sautEchelle)) raccords_visibles=\(raccordsVisibles)/\(total) part_visible=\(String(format: "%.2f", partVisible / Double(total)))")
        #expect(raccordsVisibles == 0)
    }
}
