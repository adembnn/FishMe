import Foundation
import Testing
@testable import Core

@Suite("Règles : carpe de nuit")
struct CarpeDeNuitTests {
    let carpe = Espece(id: "carpe-commune", codeSandre: "2186")
    let nuit = utc(2026, 10, 15, 20, 0)   // 22 h à Paris

    func moteur(phrase: String? = nil, texte: String = "autorise : oui") -> MoteurRegles {
        var regles: [[String: Any]] = []
        if let phrase {
            regles.append(regle("75-car-nuit", "carpe_nuit", especes: ["2186"], cat: "2", niveau: "cours_eau", code: "75", eau: "seine",
                                valeur: ["texte": texte], phrase: phrase, textes: ["t1"]))
        }
        let dep = fichierRegles(departement: "75", eaux: [["cle": "seine", "nom": "Seine", "code": NSNull()]], regles: regles)
        return moteurEssai(regles: chargeurEssai(extra: ["75": dep])).regles
    }

    func ligneCarpe(_ r: ResultatControle) -> LigneControle? {
        r.lignes.first { $0.phrase.hasPrefix("Carpe de nuit :") || $0.phrase.hasPrefix("Pêche de nuit :") }
    }

    @Test("Carpe de nuit sur un secteur autorisé chargé : remise à l'eau, appâts végétaux, avec la source")
    func secteurAutorise() {
        let r = moteur(phrase: "Carpe de nuit autorisée sur la Seine à Paris.")
            .controle(espece: carpe, tailleCm: 60, mesure: .toise, date: nuit, lieu: lieuParis, prisesDuJour: [])
        let l = ligneCarpe(r)
        #expect(l?.phrase == "Carpe de nuit : remise à l'eau obligatoire, appâts végétaux seulement")
        #expect(l?.sources.isEmpty == false)
        #expect(r.consigne == .relacheLa)
    }

    @Test("Carpe de nuit sans règle locale pour ce lieu : secteurs autorisés, vérifie l'arrêté")
    func sansRegleLocale() {
        let r = moteur().controle(espece: carpe, tailleCm: 60, mesure: .toise, date: nuit, lieu: lieuParis, prisesDuJour: [])
        let l = ligneCarpe(r)
        #expect(l?.phrase == "Pêche de nuit : seulement sur les secteurs autorisés, vérifie l'arrêté")
        #expect(l?.etat == .aVerifierSurPlace)
        #expect(!texteDe(r).contains("garder"))
    }

    @Test("Une règle qui dit « autorise : non » ne vaut pas autorisation")
    func regleNegative() {
        let r = moteur(phrase: "Ailleurs à Paris, pas de pêche de nuit, carpe comprise.", texte: "autorise : non")
            .controle(espece: carpe, tailleCm: 60, mesure: .toise, date: nuit, lieu: lieuParis, prisesDuJour: [])
        #expect(ligneCarpe(r)?.phrase.hasPrefix("Pêche de nuit :") == true)
    }

    @Test("De jour, ou pour une autre espèce, aucune ligne de carpe de nuit")
    func pasDeNuit() {
        let m = moteur(phrase: "Carpe de nuit autorisée sur la Seine à Paris.")
        #expect(ligneCarpe(m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: quinzeOctobre, lieu: lieuParis, prisesDuJour: [])) == nil)
        #expect(ligneCarpe(m.controle(espece: percheEssai, tailleCm: 25, mesure: .toise, date: nuit, lieu: lieuParis, prisesDuJour: [])) == nil)
    }
}
