import Foundation
import Testing
import Core
@testable import BuildChallenge

struct FicheReglesTests {

    private func ligne(_ type: TypeRegle, _ etat: EtatLigne, _ phrase: String = "x") -> LigneControle {
        LigneControle(type: type, etat: etat, phrase: phrase)
    }

    @Test func lOrdreMetLImportantEnPremier() {
        let lignes = [
            ligne(.taille, .respectee, "taille"),
            ligne(.autre, .information, "autre"),
            ligne(.periode, .nonRespectee, "fermée"),
            ligne(.consommation, .information, "consommation"),
            ligne(.autre, .nonRespectee, "Parcours no-kill"),
            ligne(.nuit, .nonRespectee, "nuit"),
        ]
        let phrases = OrdreRegles.trier(lignes).map(\.phrase)
        #expect(phrases == ["nuit", "Parcours no-kill", "consommation", "fermée", "autre", "taille"])
    }

    @Test func laRegleDeNuitInformativeNePasseJamaisDevant() {
        let lignes = [ligne(.nuit, .information, "carpe de nuit"), ligne(.consommation, .information, "conso")]
        #expect(OrdreRegles.trier(lignes).map(\.phrase) == ["conso", "carpe de nuit"])
    }

    @Test func leTriGardeLOrdreDeCoreADaprioriteEgale() {
        let lignes = [ligne(.quota, .respectee, "a"), ligne(.taille, .respectee, "b"), ligne(.periode, .respectee, "c")]
        #expect(OrdreRegles.trier(lignes).map(\.phrase) == ["a", "b", "c"])
    }

    @Test func cinqLignesPuisToutesAuToucher() {
        let lignes = (0..<12).map { ligne(.autre, .information, "r\($0)") }
        #expect(OrdreRegles.visibles(lignes, toutVoir: false).count == 5)
        #expect(OrdreRegles.visibles(lignes, toutVoir: true).count == 12)
        #expect(OrdreRegles.visibles(Array(lignes.prefix(3)), toutVoir: false).count == 3)
    }

    @Test func laTruiteEstToujoursProposeeEnPremiereCategorie() {
        let brochet = LigneEspece(espece: Espece(id: "brochet"), nPeches: 9, annee: 2024, ouverture: .ouverte, rarete: nil)
        let avec = TruiteEnPremiere.completer([brochet], categorie: .premiere)
        let truite = avec.first { $0.espece.id == "truite-fario" }
        #expect(truite != nil)
        #expect(truite?.releve == false)
        #expect(truite?.nPeches == 0)
        #expect(TruiteEnPremiere.completer([], categorie: .premiere).count == 1)
    }

    @Test func laTruiteNEstPasAjouteeAilleursNiEnDouble() {
        let brochet = LigneEspece(espece: Espece(id: "brochet"), nPeches: 9, annee: 2024, ouverture: .ouverte, rarete: nil)
        #expect(TruiteEnPremiere.completer([brochet], categorie: .deuxieme) == [brochet])
        #expect(TruiteEnPremiere.completer([brochet], categorie: .inconnue) == [brochet])
        let truite = LigneEspece(espece: Espece(id: "truite-fario"), nPeches: 4, annee: 2023, ouverture: .ouverte, rarete: nil)
        let resultat = TruiteEnPremiere.completer([truite], categorie: .premiere)
        #expect(resultat == [truite])
        #expect(resultat[0].releve)
    }
}
