import Foundation
import Testing
@testable import Core

@Suite("Règles : état information et carpe de nuit départementale")
struct EtatInformationTests {
    let carpe = Espece(id: "carpe-commune", codeSandre: "2186")
    let brochet = Espece(id: "brochet", codeSandre: "2151")
    let nuit = utc(2026, 10, 15, 20, 0)
    let jour = utc(2026, 10, 15, 10, 0)

    func moteur(_ regles: [[String: Any]]) -> MoteurRegles {
        let dep = fichierRegles(departement: "75", eaux: [["cle": "seine", "nom": "Seine", "code": NSNull()]], regles: regles)
        return moteurEssai(regles: chargeurEssai(extra: ["75": dep])).regles
    }

    func carpeDep(lieu: String = "tous les cours d'eau de 2e catégorie") -> [String: Any] {
        regle("75-car-dep", "carpe_nuit", especes: ["2186"], cat: "2", niveau: "departement", code: "75", lieu: lieu,
              valeur: ["texte": "autorise : oui"], phrase: "Carpe de nuit autorisée dans tous les cours d'eau.", textes: ["t1"])
    }

    func lieu(_ type: TypeEau?) -> Lieu {
        Lieu(departement: Departement(code: "75"), eau: type.map { Eau(nom: "Eau", cle: "eau", type: $0) }, categorie: deuxieme)
    }

    func nuitLigne(_ r: ResultatControle) -> [LigneControle] { r.lignes.filter { $0.phrase.hasPrefix("Pêche de nuit :") || $0.phrase.hasPrefix("Carpe de nuit :") } }

    @Test("Consommation interdite, mode de pêche et carpe de nuit : information, jamais respectée")
    func informationJamaisVerte() {
        let regles = [
            regle("75-conso", "consommation", especes: ["2151"], cat: "2", niveau: "departement", code: "75",
                  phrase: "Consommation interdite.", textes: ["t1"]),
            regle("75-mode", "mode_peche", cat: "2", niveau: "departement", code: "75", phrase: "Hameçons sans ardillon.", textes: ["t1"]),
            carpeDep(),
        ]
        let m = moteur(regles)
        let r = m.controle(espece: brochet, tailleCm: nil, mesure: nil, date: jour, lieu: lieuParis, prisesDuJour: [])
        let conso = r.lignes.first { $0.phrase.hasPrefix("Consommation") }
        let mode = r.lignes.first { $0.phrase.hasPrefix("Hameçons") }
        #expect(conso?.etat == .information)
        #expect(mode?.etat == .information)
        let c = m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: jour, lieu: lieuParis, prisesDuJour: [])
        #expect(c.lignes.first { $0.phrase.hasPrefix("Carpe de nuit autorisée") }?.etat == .information)
    }

    @Test("Règle carpe de nuit « cours d'eau » : plan d'eau, autre ou eau inconnue donnent « vérifie l'arrêté »")
    func carpeHorsRiviere() {
        let m = moteur([carpeDep()])
        for t in [TypeEau.lac, .autre] + ([nil] as [TypeEau?]).compactMap({ $0 }) {
            let r = m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: jour, lieu: lieu(t), prisesDuJour: [])
            #expect(r.lignes.first { $0.phrase.hasPrefix("Carpe de nuit autorisée") }?.etat == .aVerifierSurPlace)
        }
        let inconnue = m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: jour, lieu: lieu(nil), prisesDuJour: [])
        #expect(inconnue.lignes.first { $0.phrase.hasPrefix("Carpe de nuit autorisée") }?.etat == .aVerifierSurPlace)
        let riviere = m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: jour, lieu: lieu(.riviere), prisesDuJour: [])
        #expect(riviere.lignes.first { $0.phrase.hasPrefix("Carpe de nuit autorisée") }?.etat == .information)
    }

    @Test("Règle carpe de nuit départementale applicable : pas de ligne générique « secteurs autorisés »")
    func pasDeContradiction() {
        let m = moteur([carpeDep()])
        let r = m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: nuit, lieu: lieu(.riviere), prisesDuJour: [])
        let l = nuitLigne(r)
        #expect(!l.contains { $0.phrase.hasPrefix("Pêche de nuit :") })
        #expect(l.contains { $0.phrase == MoteurRegles.phraseCarpeAutorisee })
        // Sur un plan d'eau, la règle ne vaut pas : la ligne générique revient.
        let lac = m.controle(espece: carpe, tailleCm: 60, mesure: .toise, date: nuit, lieu: lieu(.lac), prisesDuJour: [])
        #expect(nuitLigne(lac).contains { $0.phrase.hasPrefix("Pêche de nuit :") })
        #expect(!texteDe(r).contains("garder"))
    }
}
