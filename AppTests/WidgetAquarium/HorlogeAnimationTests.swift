import Testing
import Foundation
@testable import WidgetAquariumLogique

private let ref = HorlogeAnimation.dateReference

@Suite("HorlogeAnimation")
struct HorlogeAnimationTests {
    @Test func referenceFixeEntiereEtPassee() {
        #expect(ref.timeIntervalSince1970 == 1_700_000_000)
        #expect(ref.timeIntervalSince1970.truncatingRemainder(dividingBy: 1) == 0)
        #expect(ref < Date())
    }

    @Test func decalagesDesMasques() {
        #expect(HorlogeAnimation.decalagePair(copie: 0) == 0)
        #expect(HorlogeAnimation.decalagePair(copie: 3) == 0.375)
        #expect(HorlogeAnimation.decalageImpair(copie: 0) == 0.125)
        #expect(HorlogeAnimation.decalageImpair(copie: 15) == 2)
        #expect(HorlogeAnimation.dureeBoucle() == 2)
    }

    @Test func chronoComptePositifVersLeHaut() {
        // Une seconde après la date : chiffre 1 ; 10 s après : 0 ; 12,9 s : 2.
        #expect(HorlogeAnimation.dernierChiffre(decalage: 0, a: ref.addingTimeInterval(1.0)) == 1)
        #expect(HorlogeAnimation.dernierChiffre(decalage: 0, a: ref.addingTimeInterval(10.0)) == 0)
        #expect(HorlogeAnimation.dernierChiffre(decalage: 0, a: ref.addingTimeInterval(12.9)) == 2)
        // Décalage 0,5 s : la date est 0,5 s plus tard, donc le chiffre change 0,5 s plus tard.
        #expect(HorlogeAnimation.dernierChiffre(decalage: 0.5, a: ref.addingTimeInterval(1.2)) == 0)
        #expect(HorlogeAnimation.dernierChiffre(decalage: 0.5, a: ref.addingTimeInterval(1.5)) == 1)
    }

    /// Le cœur : à chaque instant (pas de 1/64 s sur 6 s), UNE seule copie est visible, et c'est celle du calcul direct.
    @Test func uneSeuleCopieVisible() {
        var t = ref.addingTimeInterval(1234)
        let fin = t.addingTimeInterval(6)
        while t < fin {
            let visibles = (0..<16).filter { HorlogeAnimation.copieVisible($0, a: t) }
            #expect(visibles.count == 1, "instant \(t.timeIntervalSince(ref))")
            #expect(visibles.first == HorlogeAnimation.imageVisible(a: t))
            t = t.addingTimeInterval(1.0 / 64)
        }
    }

    @Test func huitImagesParSeconde() {
        // Au milieu de chaque fenêtre de 1/8 s, l'image j de la boucle est visible.
        let debut = ref.addingTimeInterval(5000) // multiple de 2 s
        for j in 0..<16 {
            let t = debut.addingTimeInterval(Double(j) / 8 + 1.0 / 16)
            #expect(HorlogeAnimation.imageVisible(a: t) == j)
            #expect(HorlogeAnimation.copieVisible(j, a: t))
        }
        // La boucle dure 2 s.
        #expect(HorlogeAnimation.imageVisible(a: debut.addingTimeInterval(2.03)) == 0)
    }

    @Test func bornesDeFenetre() {
        let debut = ref.addingTimeInterval(5000)
        #expect(HorlogeAnimation.imageVisible(a: debut) == 0)
        #expect(HorlogeAnimation.imageVisible(a: debut.addingTimeInterval(0.124)) == 0)
        #expect(HorlogeAnimation.imageVisible(a: debut.addingTimeInterval(0.125)) == 1)
        #expect(HorlogeAnimation.imageVisible(a: debut.addingTimeInterval(1.999)) == 15)
    }

    @Test func entreeInvalide() {
        #expect(HorlogeAnimation.imageVisible(a: ref, nombre: 0) == 0)
        #expect(HorlogeAnimation.imageVisible(a: ref.addingTimeInterval(-3.2)) >= 0)
    }
}
