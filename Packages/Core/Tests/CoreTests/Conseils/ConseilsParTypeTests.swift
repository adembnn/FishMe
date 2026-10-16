import Foundation
import Testing
@testable import Core

@Suite("conseilsParType")
struct ConseilsParTypeTests {
    private let courantes = ["brochet", "sandre", "perche-commune", "black-bass", "truite-fario", "carpe-commune", "gardon",
                             "tanche", "chevesne", "barbeau-fluviatile", "ablette", "silure-glane", "breme-commune", "rotengle"]

    @Test func chaqueEspeceCouranteADesTuilesEnOctobre() throws {
        let s = try ConseilsParEspece.charger()
        for id in courantes {
            let r = s.conseilsParType(espece: Espece(id: id), niveau: .debutant, mois: 10)
            // Barbeau : aucune source ne parle d'hameçon, donc pas de conseil d'hameçon (rien n'est inventé).
            let attendus = id == "barbeau-fluviatile" ? 3 : 4
            #expect(r.count >= attendus, "\(id) : \(r.keys)")
            #expect(r.values.allSatisfy { !$0.source.titre.isEmpty })
        }
    }

    @Test func horsSaisonPrendLeMoisLePlusProche() {
        let src = [SourceLue(id: "s", titre: "Page", url: "https://example.org", luLe: "2026-10-16")]
        func c(_ id: String, _ t: TypeConseil, _ m: [Int], _ rang: Int) -> ConseilFiche {
            ConseilFiche(id: id, espece: "perche-commune", type: t, texte: "T \(id)", icone: "fish", mois: m, categorie: .toutes,
                         niveaux: [.debutant, .occasionnel, .confirme], rang: rang, sources: ["s"], reluPar: "S")
        }
        let s = ConseilsParEspece(fichier: FichierConseils(version: "e", sources: src, conseils: [
            c("a", .appat, [4, 5], 1), c("b", .appat, [8], 2), c("m", .moment, [1], 3),
        ]))
        let r = s.conseilsParType(espece: Espece(id: "perche-commune"), niveau: .debutant, mois: 10)
        #expect(r[.appat]?.texte == "T b")      // août est à 2 mois de octobre, mai à 5
        #expect(r[.moment]?.texte == "T m")
        #expect(r[.hamecon] == nil)
        #expect(s.conseilsParType(espece: Espece(id: "perche-commune"), niveau: .debutant, mois: 13).isEmpty)
    }

    @Test func leNiveauPasseAvantLeMoisPuisCedeLaPlace() {
        let src = [SourceLue(id: "s", titre: "Page", url: "https://example.org", luLe: "2026-10-16")]
        let f = ConseilFiche(id: "x", espece: "perche-commune", type: .moment, texte: "Confirmé", icone: "fish", mois: [10],
                             categorie: .toutes, niveaux: [.confirme], rang: 1, sources: ["s"], reluPar: "S")
        let s = ConseilsParEspece(fichier: FichierConseils(version: "e", sources: src, conseils: [f]))
        // Aucun conseil pour un débutant : le conseil d'un autre niveau vaut mieux qu'une tuile vide.
        #expect(s.conseilsParType(espece: Espece(id: "perche-commune"), niveau: .debutant, mois: 10)[.moment]?.texte == "Confirmé")
    }
}
