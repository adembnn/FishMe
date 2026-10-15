import Foundation
import Testing
import Core
@testable import BuildChallenge

@MainActor
struct CoucheMesureTests {
    private func couche(_ consentement: Consentement = .inconnu) -> (CoucheMesure, PasserelleFausse, CoffreConsentementMemoire) {
        let passerelle = PasserelleFausse()
        let coffre = CoffreConsentementMemoire(consentement)
        return (CoucheMesure(passerelle: passerelle, coffre: coffre), passerelle, coffre)
    }

    @Test func avantLAccordRienNEstConfigureNiEnvoye() {
        let (couche, passerelle, _) = couche()
        couche.demarrerSiAccorde()
        for evenement in EvenementMesure.allCases { couche.envoyer(evenement) }
        couche.paywallMontre(declencheur: .autreSpot)
        #expect(passerelle.configurations == 0)
        #expect(passerelle.evenements.isEmpty)
        #expect(!couche.actif)
    }

    @Test func leRefusLaisseLeSDKEteint() {
        let (couche, passerelle, coffre) = couche()
        couche.refuser()
        for evenement in EvenementMesure.allCases { couche.envoyer(evenement) }
        #expect(passerelle.configurations == 0)
        #expect(passerelle.evenements.isEmpty)
        #expect(coffre.lire() == .refuse)
    }

    @Test func lAccordConfigureUneSeuleFoisMemeSiOnLeDonneDeuxFois() {
        let (couche, passerelle, coffre) = couche()
        couche.accorder()
        couche.accorder()
        couche.demarrerSiAccorde()
        #expect(passerelle.configurations == 1)
        #expect(coffre.lire() == .accepte)
        #expect(couche.actif)
    }

    @Test func lesSixEvenementsDeLEntonnoirPartentUneFoisChacunApresLAccord() {
        let (couche, passerelle, _) = couche()
        couche.accorder()
        let entonnoir: [EvenementMesure] = [.carteListe, .priseCommencee, .carteCreee, .sessionCommencee, .sessionFinie]
        for evenement in entonnoir { couche.envoyer(evenement) }
        couche.paywallMontre(declencheur: .finPremiereSession)
        let types = passerelle.evenements.map(\.type)
        #expect(types == ["map_ready", "capture_started", "card_created", "session_started", "session_ended", "paywall_viewed"])
        #expect(EvenementMesure.allCases.count == 6)
    }

    @Test func paywallViewedPorteSonDeclencheurEtRienDAutre() {
        let (couche, passerelle, _) = couche()
        couche.accorder()
        couche.paywallMontre(declencheur: .fonction(.septJours))
        #expect(passerelle.evenements.count == 1)
        #expect(passerelle.evenements[0].proprietes == ["declencheur": "fonction_septJours"])
    }

    @Test func lesAutresEvenementsNePortentAucunePropriete() {
        let (couche, passerelle, _) = couche()
        couche.accorder()
        couche.envoyer(.carteCreee)
        #expect(passerelle.evenements[0].proprietes.isEmpty)
    }

    @Test func retirerLAccordArreteLEnvoiEtLeProchainLancementNeConfigurePas() {
        let (couche, passerelle, coffre) = couche()
        couche.accorder()
        couche.retirer()
        couche.envoyer(.sessionCommencee)
        #expect(passerelle.configurations == 1)
        #expect(passerelle.evenements.isEmpty)
        #expect(coffre.lire() == .refuse)

        let passerelleRelance = PasserelleFausse()
        let relance = CoucheMesure(passerelle: passerelleRelance, coffre: coffre)
        relance.demarrerSiAccorde()
        #expect(passerelleRelance.configurations == 0)
        #expect(!relance.actif)
    }

    @Test func unAccordDejaDonneConfigureAuLancementSuivant() {
        let (couche, passerelle, _) = couche(.accepte)
        couche.demarrerSiAccorde()
        #expect(passerelle.configurations == 1)
    }

    @Test func lesValeursDeDeclencheurSontDesMotsFixes() {
        #expect(DeclencheurPaywall.finPremiereSession.valeurMesure == "fin_premiere_session")
        #expect(DeclencheurPaywall.autreSpot.valeurMesure == "autre_spot")
        #expect(DeclencheurPaywall(mode: .quiSeFerme) == .finPremiereSession)
        #expect(DeclencheurPaywall(mode: .quiBloque) == .autreSpot)
        #expect(DeclencheurPaywall(mode: .aucun) == nil)
    }
}
