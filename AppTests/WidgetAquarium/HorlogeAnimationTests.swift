import Foundation
import Testing
#if canImport(WidgetAquariumLogique)
@testable import WidgetAquariumLogique
#else
@testable import BuildChallenge
#endif

private let ref = HorlogeAnimation.reference(pour: Date(timeIntervalSince1970: 1_800_000_000))

@Suite("HorlogeAnimation")
struct HorlogeAnimationTests {
    @Test func constantes() {
        #expect(HorlogeAnimation.imagesParSeconde == 16)
        #expect(HorlogeAnimation.nombreImages == 160)
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

    /// Image par image : sur une seconde, les 16 instants montrent 16 copies différentes, dans l'ordre, et la boucle
    /// revient à la copie 0 au bout de 10 s.
    @Test func seizeImagesDifferentesParSeconde() {
        let reference = Date(timeIntervalSinceReferenceDate: 1_000_000)
        let depart = reference.addingTimeInterval(60.03)
        let vues = (0..<16).map {
            HorlogeAnimation.imageVisible(reference: reference, a: depart.addingTimeInterval(Double($0) / 16))
        }
        #expect(Set(vues).count == 16)
        for k in 1..<16 { #expect((vues[k] - vues[k - 1] + 160) % 160 == 1) }
        #expect(HorlogeAnimation.imageVisible(reference: reference, a: depart.addingTimeInterval(10)) == vues[0])
    }

    // Boucle courte du vrai widget (lot/widget-fluide) : 2 s à 8 images/s, masques en union de chiffres.

    @Test func boucleCourteConstantes() {
        let b = HorlogeAnimation.Boucle.battement
        #expect(b.copies == 16)
        #expect(b.chronosParCopie == 10)
        #expect(HorlogeAnimation.masques(copie: 0, boucle: b).a.chiffres == [0, 2, 4, 6, 8])
        #expect(HorlogeAnimation.masques(copie: 0, boucle: b).b.chiffres == [9, 1, 3, 5, 7])
        #expect(HorlogeAnimation.masques(copie: 9, boucle: b).a.chiffres == [1, 3, 5, 7, 9])
        #expect(HorlogeAnimation.masques(copie: 9, boucle: b).a.decalage == 0.125)
        #expect(HorlogeAnimation.masques(copie: 9, boucle: b).b.decalage == 0.25)
    }

    @Test(arguments: [HorlogeAnimation.Boucle.battement, HorlogeAnimation.Boucle(parSeconde: 8, duree: 10),
                      HorlogeAnimation.Boucle(parSeconde: 6, duree: 5)])
    func boucleCourteUneSeuleCopieVisible(boucle: HorlogeAnimation.Boucle) {
        for pas in 0..<(20 * 64) {
            let t = ref.addingTimeInterval(Double(pas) / 64 + 1.0 / 128)
            let visibles = (0..<boucle.copies).filter {
                HorlogeAnimation.copieVisible($0, boucle: boucle, reference: ref, a: t)
            }
            #expect(visibles.count == 1)
            #expect(visibles.first == HorlogeAnimation.imageVisible(boucle: boucle, reference: ref, a: t))
        }
    }

    /// Polices de parité (boucle de 2 s) : une seule copie visible, la même que le calcul direct, à toutes les cadences.
    @Test(arguments: [8, 6, 4, 2, 1])
    func pariteUneSeuleCopieVisible(parSeconde: Int) {
        let boucle = HorlogeAnimation.Boucle(parSeconde: parSeconde, duree: 2)
        #expect(HorlogeAnimation.masquesParite(copie: 0, boucle: boucle).a.parite == 0)
        #expect(HorlogeAnimation.masquesParite(copie: 0, boucle: boucle).b.parite == 1)
        for pas in 0..<(12 * 64) {
            let t = ref.addingTimeInterval(Double(pas) / 64 + 1.0 / 128)
            let visibles = (0..<boucle.copies).filter {
                HorlogeAnimation.copieVisibleParite($0, boucle: boucle, reference: ref, a: t)
            }
            #expect(visibles.count == 1)
            #expect(visibles.first == HorlogeAnimation.imageVisible(boucle: boucle, reference: ref, a: t))
        }
    }

    @Test func boucleCourteAvanceDUneCopieParImage() {
        let b = HorlogeAnimation.Boucle.battement
        let vues = (0..<32).map { HorlogeAnimation.imageVisible(boucle: b, reference: ref, a: ref.addingTimeInterval(Double($0) / 8 + 0.01)) }
        for k in 1..<32 { #expect((vues[k] - vues[k - 1] + 16) % 16 == 1) }
    }
}

/// Nage du poisson unique (lot widget-fluide) : boucle de 10 s, une copie par pose du trajet, deux masques d’UN chrono.
@Suite("HorlogeAnimation, poisson unique")
struct HorlogePoissonUniqueTests {
    @Test(arguments: [4, 6, 8, 12])
    func uneSeuleCopieVisibleSurDixSecondes(parSeconde: Int) {
        let boucle = HorlogeAnimation.Boucle(parSeconde: parSeconde, duree: 10)
        #expect(boucle.copies == 10 * parSeconde)
        #expect(boucle.chronosParCopie == 2)
        for k in 0..<boucle.copies {
            let m = HorlogeAnimation.masques(copie: k, boucle: boucle)
            #expect(m.a.chiffres.count == 1 && m.b.chiffres.count == 1)
        }
        for pas in 0..<(25 * 32) {
            let t = ref.addingTimeInterval(Double(pas) / 32 + 1.0 / 64)
            let visibles = (0..<boucle.copies).filter {
                HorlogeAnimation.copieVisible($0, boucle: boucle, reference: ref, a: t)
            }
            #expect(visibles == [HorlogeAnimation.imageVisible(boucle: boucle, reference: ref, a: t)])
        }
    }
}
