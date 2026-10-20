import Foundation
import Testing
#if canImport(WidgetAquariumLogique)
@testable import WidgetAquariumLogique
#else
@testable import BuildChallenge
#endif

// Le budget de performance des décors dessinés en code (exigence n°1 : fluide, même sur un iPhone ancien).
// Pure logique (Foundation) : tourne sous Linux avec `lancer-tests.sh`, et dans l'app sur Mac.
// Si un test échoue après l'ajout d'un décor ou d'un élément animé, c'est qu'il dépasse le budget : alléger, ne pas relever
// les plafonds sans mesurer sur un iPhone ancien (Instruments, voir LISEZMOI-N1.md).
@Suite("Budget de performance des décors")
struct BudgetDecorTests {
    @Test func laCadenceEstDeVingImagesParSecondeAuPlusEtDixEnEconomie() {
        #expect(BudgetDecor.imagesParSeconde(economie: false) == 20)
        #expect(BudgetDecor.imagesParSeconde(economie: true) == 10)
        #expect(BudgetDecor.imagesParSeconde(economie: false) <= 20)
        #expect(BudgetDecor.imagesParSeconde(economie: true) < BudgetDecor.imagesParSeconde(economie: false))
        #expect(abs(BudgetDecor.intervalle(economie: false) - 0.05) < 1e-9)
        #expect(abs(BudgetDecor.intervalle(economie: true) - 0.1) < 1e-9)
    }

    @Test func lesPlafondsSontCeuxDeLaSpecification() {
        #expect(BudgetDecor.rubansMax <= 6)
        #expect(BudgetDecor.bokehMax <= 12)
        #expect(BudgetDecor.bullesMax <= 15)
        #expect(BudgetDecor.vuesAnimeesMax == 2)
        #expect(BudgetDecor.imagesMobilesMax <= 2)
        #expect(BudgetDecor.operationsParSecondeMax == BudgetDecor.operationsParImageMax * BudgetDecor.imagesParSeconde)
        #expect(BudgetDecor.operationsParSecondeEconomieMax < BudgetDecor.operationsParSecondeMax)
        #expect(BudgetDecor.particulesFondParDefaut + BudgetDecor.particulesProchesParDefaut <= BudgetDecor.particulesMax)
    }

    @Test func chaqueDecorDessineADeclareSaChargeEtTientDansLeBudget() {
        #expect(!FondWidget.decorsDessines.isEmpty)
        for id in FondWidget.decorsDessines.sorted() {
            guard let charge = BudgetDecor.charge(id) else {
                Issue.record("charge non déclarée pour le décor \(id) : ajouter un cas à BudgetDecor.charge")
                continue
            }
            #expect(charge.depassements.isEmpty, "\(id) dépasse le budget : \(charge.depassements)")
            #expect(charge.tientDansLeBudget)
            #expect(charge.vues <= BudgetDecor.vuesAnimeesMax)
        }
    }

    @Test func lEconomieDEnergieCoupeLaChargeParSeconde() {
        for id in FondWidget.decorsDessines.sorted() {
            guard let charge = BudgetDecor.charge(id) else { continue }
            #expect(charge.operations(economie: true) <= charge.operations(economie: false))
            #expect(charge.operationsParSeconde(economie: true) < charge.operationsParSeconde(economie: false), "\(id)")
            #expect(charge.operationsParSeconde(economie: true) <= BudgetDecor.operationsParSecondeEconomieMax, "\(id)")
        }
    }

    @Test func uneChargeTropLourdeEstRefusee() {
        // Le test détecte bien un dépassement (garde-fou du garde-fou).
        #expect(!BudgetDecor.Charge(bokeh: 13).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(rubans: 7).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(bulles: 16).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(particules: 25).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(vues: 3).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(imagesMobiles: 3).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(lamesNervurees: 40, brinsFleuris: 40).tientDansLeBudget)
        #expect(!BudgetDecor.Charge(rais: 5, caustiquesLignes: 9, particules: 24, bulles: 15, plaques: 7, halos: 16, lamesNervurees: 30, brinsFleuris: 30, brume: 10, autres: 30).tientDansLeBudget)
        #expect(BudgetDecor.Charge().tientDansLeBudget)
    }

    @Test func leDecorEteEstNettementPlusLegerQueLesAutres() {
        // L'Été doit rester nettement plus léger que le plus lourd des décors existants.
        guard let ete = BudgetDecor.charge("ete") else {
            Issue.record("charge de l'Été non déclarée")
            return
        }
        let autres = FondWidget.decorsDessines.subtracting(["ete"]).compactMap { BudgetDecor.charge($0) }
        let plusLourd = autres.map { $0.operations() }.max() ?? 0
        #expect(ete.operations() * 2 <= plusLourd)
        #expect(ete.rubans <= 6 && ete.bokeh <= 12 && ete.bulles <= 15)
        #expect(ete.imagesMobiles <= BudgetDecor.imagesMobilesMax)
    }

    @Test func unDecorInconnuOuLeDecorDeDepartNOntPasDeCharge() {
        for id in ["riviere", "", "inconnu", "Ete"] { #expect(BudgetDecor.charge(id) == nil) }
    }
}
