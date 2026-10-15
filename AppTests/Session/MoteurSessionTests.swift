import Foundation
import Testing
import Core
@testable import BuildChallenge

private struct SoleilFixe: ServiceSoleil {
    var fin: Date?
    func finLegale(date: Date, coordonnee: Coordonnee) -> Date? { fin }
    func phaseLune(date: Date) -> PhaseLune { .pleine }
}

/// Quota réel simplifié : 3 gardés au plus (le vrai calcul est celui de `Core`).
private struct SessionQuota3: ServiceSession {
    func quota(prisesGardeesDuJour: [Prise], departement: Departement) -> QuotaDuJour {
        QuotaDuJour(gardees: prisesGardeesDuJour.count, plafond: 3)
    }
    func spotPropose(coordonnee: Coordonnee, date: Date) -> Spot? { nil }
    func acces(sessionsTerminees: Int, spot: Spot, spotGratuit: Spot?, abonne: Bool) -> DecisionAcces {
        DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: spotGratuit ?? spot)
    }
    func peutUtiliser(_ fonction: FonctionPro, abonne: Bool, surSonSpot: Bool) -> Bool { true }
    func offreAffichee(date: Date) -> OffreAffichee { OffreAffichee(produit: "annuel", prixCentimes: 3499, tarifFondateur: true) }
}

private let debut = Date(timeIntervalSince1970: 1_792_065_600)
private let paris = Coordonnee(latitude: 48.85, longitude: 2.35)

@MainActor
private func moteur(fin: Date? = debut.addingTimeInterval(3600), horloge: HorlogeFausse = HorlogeFausse(debut),
                    stockage: StockageMemoire = StockageMemoire(), coffre: CoffreMemoire = CoffreMemoire()) -> SuiviSession {
    SuiviSession(session: SessionQuota3(), soleil: SoleilFixe(fin: fin), horloge: horloge, stockage: stockage, coffre: coffre)
}

private func carnassier(gardee: Bool) -> Prise {
    Prise(espece: Espece(id: "brochet"), date: debut, gardee: gardee)
}

@MainActor
struct MoteurSessionTests {
    @Test func finLegaleVientDeCore() {
        let m = moteur()
        #expect(m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75"))) == .demarree)
        #expect(m.enCours?.finLegale == debut.addingTimeInterval(3600))
    }

    @Test func sansCoordonneeOnDemandeUnPoint() {
        let m = moteur()
        #expect(m.commencer(ContexteDepart(coordonnee: nil, departement: .inconnu)) == .pointAToucher)
        #expect(m.enCours == nil)
    }

    @Test func troisGardeesSurDeuxSessionsDuMemeJour() {
        let m = moteur()
        m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75")))
        m.ajouter(prise: carnassier(gardee: true))
        m.ajouter(prise: carnassier(gardee: true))
        m.ajouter(prise: carnassier(gardee: false))
        #expect(!m.quotaAtteint)
        m.terminer()
        m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75")))
        m.ajouter(prise: carnassier(gardee: true))
        #expect(m.quotaAtteint)
    }

    @Test func chronoCalculeDepuisLeDepart() {
        let h = HorlogeFausse(debut)
        let m = moteur(horloge: h)
        m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75")))
        #expect(m.duree(a: debut.addingTimeInterval(125)) == 125)
    }

    @Test func repriseApresAppTuee() {
        let h = HorlogeFausse(debut), s = StockageMemoire(), c = CoffreMemoire()
        let m = moteur(horloge: h, stockage: s, coffre: c)
        m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75")))
        m.ajouter(prise: carnassier(gardee: true))
        let relance = moteur(horloge: h, stockage: s, coffre: c)
        #expect(relance.enCours?.sortie.prises.count == 1)
        #expect(relance.enCours?.sortie.debut == m.enCours?.sortie.debut)
    }

    @Test func reouvertureApresLaFinLegaleLaSessionEstTerminee() {
        let h = HorlogeFausse(debut), s = StockageMemoire(), c = CoffreMemoire()
        let m = moteur(horloge: h, stockage: s, coffre: c)
        m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75")))
        h.avancer(de: 7200)
        let relance = moteur(horloge: h, stockage: s, coffre: c)
        relance.reprendre()
        #expect(relance.enCours == nil)
        #expect(relance.derniereFin?.sortie.fin == debut.addingTimeInterval(3600))
        #expect(relance.derniereFin?.sortie.prises.isEmpty == true)
    }

    @Test func departHorsFenetreLegaleDemarreAvecMessage() {
        let m = moteur(fin: debut.addingTimeInterval(-600))
        #expect(m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75"))) == .demarree)
        #expect(m.enCours?.messages.contains("pêche fermée à cette heure") == true)
        m.verifierFin()
        #expect(m.enCours != nil)
    }

    @Test func horsDeFranceMessageEtFinDeSessionAvecPaywall() {
        let m = moteur()
        m.commencer(ContexteDepart(coordonnee: Coordonnee(latitude: 37.32, longitude: -122.03), departement: .inconnu))
        #expect(m.enCours?.messages.contains("hors de France : aucune règle française") == true)
        m.terminer()
        #expect(m.derniereFin?.paywall == .quiSeFerme)
    }

    @Test func spotGratuitFixeAuDepartDeLaPremiereSession() {
        let c = CoffreMemoire()
        let m = moteur(coffre: c)
        m.commencer(ContexteDepart(coordonnee: paris, departement: Departement(code: "75")))
        #expect(c.lire()?.centre == paris)
    }
}
