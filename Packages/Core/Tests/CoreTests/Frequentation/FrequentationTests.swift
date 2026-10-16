import Foundation
import Testing
@testable import Core

@Suite("Fréquentation")
struct FrequentationTests {
    static let auj = Date(timeIntervalSince1970: 1_792_000_000) // mi-octobre 2026
    static func jourMoins(_ n: Int) -> String { JetonDuJour.jour(auj.addingTimeInterval(-Double(n) * 86_400)) }
    static func passages(_ n: Int, joursEnArriere: Int, prefixe: String, troncon: String = "T") -> [Passage] {
        (0..<n).map { Passage(troncon: troncon, jour: jourMoins(joursEnArriere), jeton: "\(prefixe)\($0)") }
    }

    @Test("Seuil : 4 pêcheurs rien, 5 un niveau")
    func seuil() {
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 4, moyenneHebdoHistorique: 10) == nil)
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 5, moyenneHebdoHistorique: nil) == .normal)
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 5, moyenneHebdoHistorique: 0) == .normal)
    }

    @Test("Calme, normal, chargé selon la moyenne")
    func niveaux() {
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 9, moyenneHebdoHistorique: 10) == .calme)
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 10, moyenneHebdoHistorique: 10) == .normal)
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 15, moyenneHebdoHistorique: 10) == .normal)
        #expect(CalculFrequentation.niveau(pecheurs7Jours: 16, moyenneHebdoHistorique: 10) == .charge)
    }

    @Test("Un même jeton est compté une fois")
    func jetonsDistincts() {
        let p = (0..<10).map { _ in Passage(troncon: "T", jour: Self.jourMoins(1), jeton: "a") }
        #expect(CalculFrequentation.niveau(passages: p, troncon: "T", aujourdhui: Self.auj) == nil)
    }

    @Test("Fenêtre de 7 jours : le jour 7 en arrière n'en fait plus partie")
    func fenetre() {
        let dedans = Self.passages(5, joursEnArriere: 6, prefixe: "d")
        #expect(CalculFrequentation.niveau(passages: dedans, troncon: "T", aujourdhui: Self.auj) == .normal)
        let dehors = Self.passages(5, joursEnArriere: 7, prefixe: "d")
        #expect(CalculFrequentation.niveau(passages: dehors, troncon: "T", aujourdhui: Self.auj) == nil)
        #expect(CalculFrequentation.niveau(passages: dedans, troncon: "autre", aujourdhui: Self.auj) == nil)
    }

    @Test("L'historique de 8 semaines donne la moyenne")
    func historique() {
        // 80 jetons répartis dans les 8 semaines d'avant : moyenne 10 par semaine.
        let histo = Self.passages(80, joursEnArriere: 20, prefixe: "h")
        let calme = histo + Self.passages(6, joursEnArriere: 1, prefixe: "r")
        #expect(CalculFrequentation.niveau(passages: calme, troncon: "T", aujourdhui: Self.auj) == .calme)
        let charge = histo + Self.passages(16, joursEnArriere: 1, prefixe: "r")
        #expect(CalculFrequentation.niveau(passages: charge, troncon: "T", aujourdhui: Self.auj) == .charge)
    }

    @Test("Jeton stable le même jour, différent le lendemain")
    func jeton() {
        let a = JetonDuJour.jeton(graine: 42, jour: "2026-10-16")
        #expect(a == JetonDuJour.jeton(graine: 42, jour: "2026-10-16"))
        #expect(a != JetonDuJour.jeton(graine: 42, jour: "2026-10-17"))
        #expect(a != JetonDuJour.jeton(graine: 43, jour: "2026-10-16"))
        #expect(a.count == 16)
        #expect(JetonDuJour.jour(Date(timeIntervalSince1970: 0)) == "1970-01-01")
    }

    @Test("CompteurLocal dédoublonne et ne montre rien seul")
    func local() async {
        let c = CompteurLocal()
        let p = Passage(troncon: "T", jour: Self.jourMoins(0), jeton: "x")
        await c.enregistrer(p)
        await c.enregistrer(Passage(troncon: "T", jour: p.jour, jeton: "y"))
        #expect(await c.passages.count == 1)
        #expect(await c.niveau(troncon: "T", aujourdhui: Self.auj) == nil)
    }

    #if DEBUG
    @Test("CompteurDemo rend le niveau fixé")
    func demo() async {
        let c = CompteurDemo(niveaux: ["T": .charge])
        #expect(await c.niveau(troncon: "T", aujourdhui: Self.auj) == .charge)
        #expect(await c.niveau(troncon: "U", aujourdhui: Self.auj) == nil)
    }
    #endif
}
