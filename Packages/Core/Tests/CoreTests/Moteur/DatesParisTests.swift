import Foundation
import Testing
@testable import Core

@Suite("Règles : jour de Paris et dates de lecture")
struct DatesParisTests {
    let regles = moteurEssai().regles

    func ligne(_ r: ResultatControle, _ type: TypeRegle) -> LigneControle? { r.lignes.first { $0.type == type } }

    @Test("Quota : une prise à 00 h 30 heure de Paris compte pour le jour de Paris, pas pour la veille UTC")
    func quotaJourDeParis() {
        // 22 h 30 UTC le 14 oct. = 00 h 30 à Paris le 15 oct.
        let minuit = (0..<2).map { _ in Prise(espece: brochetEssai, date: utc(2026, 10, 14, 22, 30), gardee: true) }
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: minuit)
        #expect(ligne(r, .quota)?.etat == .nonRespectee)
        // 22 h 30 UTC le 15 oct. = 00 h 30 à Paris le 16 oct. : c'est un autre jour que midi le 15.
        let lendemain = (0..<2).map { _ in Prise(espece: brochetEssai, date: utc(2026, 10, 15, 22, 30), gardee: true) }
        let r2 = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: lendemain)
        #expect(ligne(r2, .quota)?.etat == .respectee)
    }

    @Test("Le jour de Paris est ramené à minuit UTC")
    func jourDeParis() {
        #expect(MoteurRegles.jourDeParis(utc(2026, 10, 14, 22, 30)) == utc(2026, 10, 15, 0, 0))
        #expect(MoteurRegles.jourDeParis(utc(2026, 12, 31, 23, 30)) == utc(2027, 1, 1, 0, 0))
    }

    @Test("Le quota n'écrit plus « gardé » dans sa phrase")
    func quotaNeutre() {
        let prise = Prise(espece: brochetEssai, date: quinzeOctobre, gardee: true)
        let r = regles.controle(espece: brochetEssai, tailleCm: 65, mesure: .toise, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [prise])
        let phrase = ligne(r, .quota)?.phrase ?? ""
        #expect(phrase.contains("déjà 1 aujourd'hui"))
        #expect(!phrase.lowercased().contains("gardé"))
    }

    @Test("Anguille sans stade et espèce protégée : une source légale et une date de lecture")
    func sourcesEtDates() {
        for e in [Espece(id: "anguille"), Espece(id: "esturgeon-europeen")] {
            let r = regles.controle(espece: e, tailleCm: nil, mesure: nil, date: quinzeOctobre, lieu: lieuCharenton, prisesDuJour: [])
            let l = r.lignes.filter { $0.etat == .nonRespectee && $0.sources.contains { $0.url?.contains("legifrance") == true } }
            #expect(!l.isEmpty)
            #expect(l.allSatisfy { $0.dateLecture != nil })
        }
    }
}
