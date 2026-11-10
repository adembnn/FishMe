import Foundation
import Testing
import Core
@testable import BuildChallenge

private struct SoleilCourt: ServiceSoleil {
    func finLegale(date: Date, coordonnee: Coordonnee) -> Date? { date.addingTimeInterval(3600) }
    func phaseLune(date: Date) -> PhaseLune { .pleine }
}

private struct AccesLibre: ServiceSession {
    func quota(prisesGardeesDuJour: [Prise], departement: Departement) -> QuotaDuJour { QuotaDuJour(gardees: 0, plafond: nil) }
    func spotPropose(coordonnee: Coordonnee, date: Date) -> Spot? { nil }
    func acces(sessionsTerminees: Int, spot: Spot, spotGratuit: Spot?, abonne: Bool) -> DecisionAcces {
        DecisionAcces(sessionPermise: true, paywall: .aucun, spotGratuit: spotGratuit ?? spot)
    }
    func peutUtiliser(_ fonction: FonctionPro, abonne: Bool, surSonSpot: Bool) -> Bool { false }
    func offreAffichee(date: Date) -> OffreAffichee { OffreAffichee(produit: "annuel", prixCentimes: 3499, tarifFondateur: true) }
}

private let debut = Date(timeIntervalSince1970: 1_792_065_600)
private let marne = Coordonnee(latitude: 48.81, longitude: 2.41)

/// 9 nov. : la synthèse de fin de session disait « bredouille » alors que le pêcheur avait ajouté une prise
/// avec la photo d'exemple (le filtre `exemple` cachait la prise).
@MainActor
struct SyntheseSessionTests {
    private func session() -> SuiviSession {
        SuiviSession(session: AccesLibre(), soleil: SoleilCourt(), horloge: HorlogeFausse(debut),
                     stockage: StockageMemoire(), coffre: CoffreMemoire())
    }

    @Test func uneSessionAvecUnePriseDExempleNEstPasBredouille() throws {
        let m = session()
        _ = m.commencer(ContexteDepart(coordonnee: marne, departement: Departement(code: "94")))
        m.ajouter(prise: Prise(espece: Espece(id: "brochet"), longueurCm: 68, date: debut, exemple: true))
        m.terminer()
        let fin = try #require(m.derniereFin)
        #expect(fin.sortie.prises.count == 1)
        #expect(FormatSortie.prises(fin.sortie).count == 1)
    }

    @Test func uneVraiePriseEtUneDExempleCompteDeuxCartes() throws {
        let m = session()
        _ = m.commencer(ContexteDepart(coordonnee: marne, departement: Departement(code: "94")))
        m.ajouter(prise: Prise(espece: Espece(id: "brochet"), longueurCm: 68, date: debut))
        m.ajouter(prise: Prise(espece: Espece(id: "perche"), longueurCm: 25, date: debut, exemple: true))
        m.terminer()
        let fin = try #require(m.derniereFin)
        #expect(FormatSortie.prises(fin.sortie).map(\.espece.id) == ["brochet", "perche"])
    }

    @Test func uneSessionSansPriseResteBredouille() throws {
        let m = session()
        _ = m.commencer(ContexteDepart(coordonnee: marne, departement: Departement(code: "94")))
        m.terminer()
        let fin = try #require(m.derniereFin)
        #expect(FormatSortie.prises(fin.sortie).isEmpty)
    }
}
