import Foundation
import Testing
import Core
@testable import BuildChallenge

private struct SoleilLong: ServiceSoleil {
    func finLegale(date: Date, coordonnee: Coordonnee) -> Date? { date.addingTimeInterval(3600) }
    func phaseLune(date: Date) -> PhaseLune { .pleine }
}

/// Les règles d'accès de Core, reprises : 1re session toujours permise, même spot permis, autre spot bloqué sans Pro.
private struct AccesCommeCore: ServiceSession {
    func quota(prisesGardeesDuJour: [Prise], departement: Departement) -> QuotaDuJour { QuotaDuJour(gardees: 0, plafond: nil) }
    func spotPropose(coordonnee: Coordonnee, date: Date) -> Spot? { nil }
    func acces(sessionsTerminees: Int, spot: Spot, spotGratuit: Spot?, abonne: Bool) -> DecisionAcces {
        if abonne { return DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: spotGratuit) }
        guard let gratuit = spotGratuit else { return DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: spot) }
        if distanceMetres(spot.centre, gratuit.centre) <= 1000 {
            return DecisionAcces(sessionPermise: true, paywall: sessionsTerminees == 1 ? .quiSeFerme : .aucun, spotGratuit: gratuit)
        }
        return DecisionAcces(sessionPermise: false, paywall: .quiBloque, spotGratuit: gratuit)
    }
    func peutUtiliser(_ fonction: FonctionPro, abonne: Bool, surSonSpot: Bool) -> Bool { false }
    func offreAffichee(date: Date) -> OffreAffichee { OffreAffichee(produit: "annuel", prixCentimes: 3499, tarifFondateur: true) }
}

private let t0 = Date(timeIntervalSince1970: 1_792_065_600)
private let marne = Coordonnee(latitude: 48.81, longitude: 2.41)

@MainActor
private func moteurReel() -> SuiviSession {
    SuiviSession(session: AccesCommeCore(), soleil: SoleilLong(), horloge: HorlogeFausse(t0),
                 stockage: StockageMemoire(), coffre: CoffreMemoire())
}

/// B10 : le paywall est à la fin de la 1re session, jamais au départ.
@MainActor
struct DepartSessionTests {
    @Test func premiereSessionDemarreSansPaywallEtSeTermineAvecPaywallQuiSeFerme() {
        let m = moteurReel()
        let ctx = ContexteDepart(coordonnee: marne, departement: Departement(code: "94"))
        #expect(m.commencer(ctx) == .demarree)
        m.terminer()
        #expect(m.derniereFin?.paywall == .quiSeFerme)
    }

    @Test func secondToucherNeRouvrePasLeDepartNiLePaywall() {
        let m = moteurReel()
        let ctx = ContexteDepart(coordonnee: marne, departement: Departement(code: "94"))
        #expect(m.commencer(ctx) == .demarree)
        #expect(m.commencer(ctx) == .dejaEnCours)
        #expect(m.enCours != nil)
    }

    @Test func deuxiemeSessionSurLeMemeSpotDemarreSansPaywall() {
        let m = moteurReel()
        let ctx = ContexteDepart(coordonnee: marne, departement: Departement(code: "94"))
        m.commencer(ctx)
        m.terminer()
        #expect(m.commencer(ctx) == .demarree)
    }

    @Test func seulUnAutreSpotSansProOuvreLePaywallAuDepart() {
        let m = moteurReel()
        m.commencer(ContexteDepart(coordonnee: marne, departement: Departement(code: "94")))
        m.terminer()
        let loin = ContexteDepart(coordonnee: Coordonnee(latitude: 48.90, longitude: 2.60), departement: Departement(code: "93"))
        #expect(m.commencer(loin) == .paywallQuiBloque)
    }
}
