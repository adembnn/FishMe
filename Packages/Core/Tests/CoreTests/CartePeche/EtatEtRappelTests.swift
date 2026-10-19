import Foundation
import Testing
@testable import Core

@Suite("Carte de pêche : état, rappel, validation de la fiche")
struct EtatEtRappelTests {
    private let aujourdhui = JourCivil(annee: 2026, mois: 10, jour: 19)!

    private func dans(_ jours: Int) -> JourCivil { aujourdhui.ajouter(jours: jours) }

    // MARK: État

    @Test("Expire demain : bientôt, 1 jour")
    func demain() {
        #expect(EtatCartePeche.calculer(expireLe: dans(1), aujourdhui: aujourdhui) == .expireBientot(joursRestants: 1))
    }

    @Test("Expire aujourd'hui : bientôt, 0 jour")
    func aujourdHui() {
        #expect(EtatCartePeche.calculer(expireLe: aujourdhui, aujourdhui: aujourdhui) == .expireBientot(joursRestants: 0))
    }

    @Test("Expirée hier : depuis 1 jour")
    func hier() {
        #expect(EtatCartePeche.calculer(expireLe: dans(-1), aujourdhui: aujourdhui) == .expiree(depuisJours: 1))
    }

    @Test("Dans 31 jours : jusqu'au ; dans 30 jours : bientôt")
    func frontiere() {
        #expect(EtatCartePeche.calculer(expireLe: dans(31), aujourdhui: aujourdhui) == .jusquAu(dans(31)))
        #expect(EtatCartePeche.calculer(expireLe: dans(30), aujourdhui: aujourdhui) == .expireBientot(joursRestants: 30))
    }

    @Test("Les mots affichés")
    func mots() throws {
        let fin2026 = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        #expect(EtatCartePeche.jusquAu(fin2026).libelle(expireLe: fin2026) == "Jusqu'au 31/12/2026")
        #expect(EtatCartePeche.expireBientot(joursRestants: 12).libelle(expireLe: fin2026) == "Expire dans 12 jours")
        #expect(EtatCartePeche.expireBientot(joursRestants: 1).libelle(expireLe: fin2026) == "Expire demain")
        #expect(EtatCartePeche.expireBientot(joursRestants: 0).libelle(expireLe: fin2026) == "Expire aujourd'hui")
        let fin2025 = try #require(JourCivil(annee: 2025, mois: 12, jour: 31))
        #expect(EtatCartePeche.expiree(depuisJours: 293).libelle(expireLe: fin2025) == "Expirée le 31/12/2025")
    }

    @Test("Aucun libellé ne porte un verdict")
    func aucunVerdict() throws {
        let jour = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        let etats: [EtatCartePeche] = [.jusquAu(jour), .expireBientot(joursRestants: 0), .expireBientot(joursRestants: 1),
                                       .expireBientot(joursRestants: 5), .expiree(depuisJours: 3)]
        for etat in etats {
            let texte = etat.libelle(expireLe: jour).lowercased()
            #expect(!texte.contains("valide"))
            #expect(!texte.contains("en règle"))
        }
    }

    // MARK: Rappel

    @Test("Expire dans 45 jours : rappel dans 15 jours")
    func rappelDans45() {
        #expect(RappelCartePeche.jourDuRappel(expireLe: dans(45), aujourdhui: aujourdhui) == dans(15))
    }

    @Test("Expire dans 30 jours ou moins : aucun rappel")
    func rappelTropTard() {
        #expect(RappelCartePeche.jourDuRappel(expireLe: dans(30), aujourdhui: aujourdhui) == nil)
        #expect(RappelCartePeche.jourDuRappel(expireLe: dans(10), aujourdhui: aujourdhui) == nil)
        #expect(RappelCartePeche.jourDuRappel(expireLe: dans(-5), aujourdhui: aujourdhui) == nil)
    }

    @Test("Expire dans 31 jours : rappel demain")
    func rappelDemain() {
        #expect(RappelCartePeche.jourDuRappel(expireLe: dans(31), aujourdhui: aujourdhui) == dans(1))
    }

    @Test("Textes du rappel")
    func textesRappel() throws {
        let fin = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        #expect(RappelCartePeche.titre == "Ta carte de pêche expire dans 30 jours")
        #expect(RappelCartePeche.corps(millesime: 2026, expireLe: fin) == "Millésime 2026 · expire le 31/12/2026.")
        #expect(RappelCartePeche.messageSansRappel(expireLe: dans(10), aujourdhui: aujourdhui)
                == "Moins de 30 jours : pas de rappel, ta carte expire dans 10 jours.")
        #expect(RappelCartePeche.messageSansRappel(expireLe: dans(45), aujourdhui: aujourdhui) == nil)
        #expect(RappelCartePeche.messageSansRappel(expireLe: dans(-2), aujourdhui: aujourdhui) != nil)
    }

    // MARK: Validation

    @Test("Millésime 1999 refusé")
    func millesimeTropAncien() throws {
        let fin = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        #expect(ValidationFiche.verifier(millesime: 1999, expireLe: fin, aujourdhui: aujourdhui).contains(.millesimeHorsBornes))
    }

    @Test("Millésime de l'année prochaine accepté, de dans deux ans refusé")
    func millesimeFutur() throws {
        let fin = try #require(JourCivil(annee: 2027, mois: 12, jour: 31))
        #expect(ValidationFiche.verifier(millesime: 2027, expireLe: fin, aujourdhui: aujourdhui).isEmpty)
        #expect(ValidationFiche.verifier(millesime: 2028, expireLe: fin, aujourdhui: aujourdhui).contains(.millesimeHorsBornes))
    }

    @Test("Expiration avant le millésime refusée")
    func expirationAvantMillesime() throws {
        let debut = try #require(JourCivil(annee: 2025, mois: 12, jour: 31))
        #expect(ValidationFiche.verifier(millesime: 2026, expireLe: debut, aujourdhui: aujourdhui).contains(.expirationAvantMillesime))
    }

    @Test("Expiration à plus de 3 ans refusée")
    func expirationLointaine() {
        #expect(ValidationFiche.verifier(millesime: 2026, expireLe: dans(5 * 365), aujourdhui: aujourdhui).contains(.expirationTropLointaine))
        #expect(!ValidationFiche.verifier(millesime: 2026, expireLe: dans(2 * 365), aujourdhui: aujourdhui).contains(.expirationTropLointaine))
    }

    @Test("Cas courant accepté : millésime 2026, expire le 31/12/2026")
    func casCourant() throws {
        let fin = try #require(JourCivil(annee: 2026, mois: 12, jour: 31))
        #expect(ValidationFiche.verifier(millesime: 2026, expireLe: fin, aujourdhui: aujourdhui).isEmpty)
    }

    @Test("Chaque erreur a un message sans verdict")
    func messagesErreurs() {
        for erreur in ErreurFiche.allCases {
            #expect(!erreur.message.isEmpty)
            #expect(!erreur.message.lowercased().contains("valide"))
        }
    }
}
