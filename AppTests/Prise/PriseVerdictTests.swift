import Foundation
import Testing
import Core
@testable import BuildChallenge

@MainActor
struct PriseVerdictTests {
    private func resultat(_ etat: EtatLigne, type: TypeRegle = .taille) -> ResultatControle {
        ResultatControle(lignes: [LigneControle(type: type, etat: etat, phrase: "p")], consigne: .verifieLArrete)
    }

    @Test func fourchetteEntierementAuDessusDeLaMailleDonneTailleLegale() {
        #expect(PriseLogique.verdict(resultats: [resultat(.respectee), resultat(.respectee)]) == .tailleLegale)
    }

    @Test func fourchetteEntierementSousLaMailleDonneSousLaMaille() {
        #expect(PriseLogique.verdict(resultats: [resultat(.nonRespectee), resultat(.nonRespectee)]) == .sousLaMaille)
    }

    @Test func fourchetteQuiChevaucheLaMailleNeDonneAucunVerdict() {
        #expect(PriseLogique.verdict(resultats: [resultat(.nonRespectee), resultat(.respectee)]) == .aVerifier)
        #expect(PriseLogique.verdict(resultats: [resultat(.aVerifierSurPlace), resultat(.respectee)]) == .aVerifier)
    }

    @Test func uneAutreRegleNonRespecteeDonneRelacheLa() {
        let r = ResultatControle(lignes: [LigneControle(type: .taille, etat: .respectee, phrase: "t"),
                                          LigneControle(type: .periode, etat: .nonRespectee, phrase: "p")], consigne: .relacheLa)
        #expect(PriseLogique.verdict(resultats: [r]) == .regleNonRespectee)
    }

    @Test func sansLigneDeTailleOnNeDitRienDeLaTaille() {
        #expect(PriseLogique.verdict(resultats: [resultat(.respectee, type: .periode)]) == .sansRegleDeTaille)
        #expect(PriseLogique.verdict(resultats: []) == nil)
    }

    @Test func ladeclarationNeDitPasEstCompteeCommeRelachee() {
        let contexte = PriseContexte(coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                     lieu: Lieu(departement: Departement(code: "94")), lieuFlou: "La Marne · 94",
                                     date: Date(timeIntervalSince1970: 1_792_065_600), prisesDuJour: [])
        let m = PriseModele(services: .faux, contexte: contexte, terminer: { _ in })
        #expect(m.devenir == .relachee && !m.gardee)
        m.devenir = .gardee
        #expect(m.gardee)
        m.devenir = .nonDit
        #expect(!m.gardee)
    }

    @Test func laTailleConfirmeeOuvreLesDetailsPuisLeVerdict() throws {
        let contexte = PriseContexte(coordonnee: Coordonnee(latitude: 48.8, longitude: 2.4),
                                     lieu: Lieu(departement: Departement(code: "94")), lieuFlou: "La Marne · 94",
                                     date: Date(timeIntervalSince1970: 1_792_065_600), prisesDuJour: [])
        let m = PriseModele(services: .faux, contexte: contexte, terminer: { _ in })
        let brochet = try #require(m.catalogue.first { $0.espece.id == "brochet" })
        m.choisir(brochet)
        m.longueurCm = 60
        m.confirmerLaTaille()
        #expect(m.etape == .details)
        m.continuerDetails()
        #expect(m.etape == .resultat)
        #expect(m.verdictTaille != nil)
    }
}
