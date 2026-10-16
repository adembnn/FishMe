import Foundation
import Testing
@testable import WidgetAquariumLogique

private let ref = HorlogeAnimation.reference(pour: Date(timeIntervalSince1970: 1_800_000_000))

@Suite("HorlogeAnimation")
struct HorlogeAnimationTests {
    @Test func constantes() {
        #expect(HorlogeAnimation.imagesParSeconde == 8)
        #expect(HorlogeAnimation.nombreImages == 80)
        #expect(HorlogeAnimation.dureeBoucle == 10)
        #expect(HorlogeAnimation.reference(pour: Date(timeIntervalSince1970: 100)) == Date(timeIntervalSince1970: 40))
    }

    @Test func masquesDeLaCopie() {
        #expect(HorlogeAnimation.masques(copie: 0, parSeconde: 8).a == (0, 0))
        #expect(HorlogeAnimation.masques(copie: 0, parSeconde: 8).b == (9, 0.125))
        #expect(HorlogeAnimation.masques(copie: 13, parSeconde: 8).a == (1, 0.625))
        #expect(HorlogeAnimation.masques(copie: 13, parSeconde: 8).b == (0, 0.75))
        #expect(HorlogeAnimation.masques(copie: 79, parSeconde: 8).a == (9, 0.875))
        #expect(HorlogeAnimation.masques(copie: 79, parSeconde: 8).b == (8, 1))
    }

    @Test func dernierChiffre() {
        #expect(HorlogeAnimation.dernierChiffre(reference: ref, decalage: 0, a: ref.addingTimeInterval(1.0)) == 1)
        #expect(HorlogeAnimation.dernierChiffre(reference: ref, decalage: 0, a: ref.addingTimeInterval(12.9)) == 2)
        #expect(HorlogeAnimation.dernierChiffre(reference: ref, decalage: 0.5, a: ref.addingTimeInterval(1.2)) == 0)
    }

    @Test func uneSeuleCopieVisibleAChaqueInstant() {
        // Sur 30 s, tous les 1/64 s : exactement une copie visible, celle que donne le calcul direct.
        for pas in 0..<(30 * 64) {
            let t = ref.addingTimeInterval(Double(pas) / 64 + 1.0 / 128)
            let visibles = (0..<HorlogeAnimation.nombreImages).filter { HorlogeAnimation.copieVisible($0, reference: ref, a: t) }
            #expect(visibles.count == 1)
            #expect(visibles.first == HorlogeAnimation.imageVisible(reference: ref, a: t))
        }
    }

    @Test func ordreEtBoucle() {
        for j in 0..<80 {
            let t = ref.addingTimeInterval(Double(j) / 8 + 0.06)
            #expect(HorlogeAnimation.imageVisible(reference: ref, a: t, parSeconde: 8) == j)
        }
        #expect(HorlogeAnimation.imageVisible(reference: ref, a: ref.addingTimeInterval(10.01), parSeconde: 8) == 0)
    }

    /// Image par image : sur une seconde, les 8 instants montrent 8 copies différentes, dans l'ordre, et la boucle
    /// revient à la copie 0 au bout de 10 s.
    @Test func huitImagesDifferentesParSeconde() {
        let reference = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let depart = reference.addingTimeInterval(60.03)
        let vues = (0..<8).map {
            HorlogeAnimation.imageVisible(reference: reference, a: depart.addingTimeInterval(Double($0) / 8))
        }
        #expect(Set(vues).count == 8)
        for k in 1..<8 { #expect((vues[k] - vues[k - 1] + 80) % 80 == 1) }
        #expect(HorlogeAnimation.imageVisible(reference: reference, a: depart.addingTimeInterval(10)) == vues[0])
    }
}
