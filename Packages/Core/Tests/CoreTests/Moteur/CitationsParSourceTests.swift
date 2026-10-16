import Foundation
import Testing
@testable import Core

/// Quand deux textes se contredisent (arrêté 50 cm, avis 2026 60 cm), chaque source montre SA citation.
@Suite("Citations par source (94-bro-taille)")
struct CitationsParSourceTests {
    @Test("Brochet du 94 : l'arrêté et l'avis portent chacun leur citation, sur les vrais fichiers")
    func chaqueSourceSaCitation() throws {
        let dossier = CasVerdictsReelsTests.dossier.appendingPathComponent("regles")
        let moteur = MoteurCore(
            donnees: DonneesMoteur(
                departements: CasVerdictsReelsTests.lire("departements.geojson"), lacs: CasVerdictsReelsTests.lire("lacs.geojson"),
                especes: CasVerdictsReelsTests.lire("especes.json"), longueurPoids: CasVerdictsReelsTests.lire("longueur-poids.json"),
                regles: ChargeurRegles(sources: [SourceDossier(dossier: dossier)])),
            horloge: { utc(2026, 10, 15) })
        let r = moteur.regles.controle(espece: brochetEssai, tailleCm: 55, mesure: .toise, date: quinzeOctobre,
                                       lieu: lieuCharenton, prisesDuJour: [])
        let ligne = try #require(r.lignes.first { $0.type == .taille })
        #expect(ligne.sources.count == 2)
        let arrete = try #require(ligne.sources.first { $0.titre.hasPrefix("Arrêté préfectoral") })
        let avis = try #require(ligne.sources.first { $0.titre.hasPrefix("Avis annuel 2026") })
        #expect(arrete.citation?.contains("0,50 mètre pour le brochet") == true)
        #expect(avis.citation?.contains("0,60m pour le brochet") == true)
        #expect(arrete.citation != avis.citation)
    }

}
