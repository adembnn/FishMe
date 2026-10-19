import Foundation
import Testing
@testable import Core

// Critères 4 et 5 de la fiche N6. Écrits sans compilateur : non exécutés.

@Suite("Repères : avertissement de réserve")
struct ReserveReperesTests {
    private let marne = Eau(nom: "La Marne", cle: "marne", type: .riviere)
    private let yerres = Eau(nom: "L'Yerres", cle: "yerres", type: .riviere)
    private let source = SourceRegle(titre: "Arrêté préfectoral n° 2025/00727", url: "https://exemple.org/a.pdf", citation: "Toute pêche est interdite.")

    private func reserve(_ id: String, eau: String?, dep: String = "94") -> ReserveConnue {
        ReserveConnue(id: id, eauCle: eau.map(cleEau), eauNom: eau, departement: dep, phrase: "Réserve de pêche.",
                      sources: [source], lueLe: nil, placeeSurUneEau: eau != nil)
    }

    @Test("Critère 4 : eau `marne` et réserve sur « La Marne » donnent surCetteEau")
    func surCetteEau() {
        let r = DetecteurReserve.evaluer(eauxProches: [marne], departement: Departement(code: "94"),
                                         reserves: [reserve("a", eau: "La Marne"), reserve("b", eau: nil)])
        guard case .surCetteEau(let nom, let sources, _) = r else { Issue.record("attendu surCetteEau, obtenu \(r)"); return }
        #expect(nom == "La Marne")
        #expect(!sources.isEmpty && sources.allSatisfy { !$0.titre.isEmpty })
    }

    @Test("Critère 4 : eau sans réserve et 2 réserves non placées donnent nonPlacees(2)")
    func nonPlacees() {
        let r = DetecteurReserve.evaluer(eauxProches: [yerres], departement: Departement(code: "94"),
                                         reserves: [reserve("a", eau: "La Marne"), reserve("b", eau: nil), reserve("c", eau: nil)])
        guard case .nonPlaceesDansLeDepartement(let n, let sources, _) = r else { Issue.record("attendu nonPlacees, obtenu \(r)"); return }
        #expect(n == 2)
        #expect(!sources.isEmpty && sources.allSatisfy { !$0.titre.isEmpty })
    }

    @Test("Critère 4 : rien du tout donne aucuneConnue")
    func aucune() {
        #expect(DetecteurReserve.evaluer(eauxProches: [marne], departement: Departement(code: "94"), reserves: []) == .aucuneConnue)
    }

    @Test("Les réserves d'un autre département et un département inconnu ne comptent pas")
    func autreDepartement() {
        let lesReserves = [reserve("a", eau: "La Marne", dep: "77"), reserve("b", eau: nil, dep: "77")]
        #expect(DetecteurReserve.evaluer(eauxProches: [marne], departement: Departement(code: "94"), reserves: lesReserves) == .aucuneConnue)
        #expect(DetecteurReserve.evaluer(eauxProches: [marne], departement: .inconnu, reserves: lesReserves) == .aucuneConnue)
    }

    @Test("Critère 4 : le switch à 3 cas est exhaustif, il n'y a pas de cas « hors réserve »")
    func troisCasSeulement() {
        let r = DetecteurReserve.evaluer(eauxProches: [], departement: Departement(code: "94"), reserves: [])
        switch r {
        case .surCetteEau: break
        case .nonPlaceesDansLeDepartement: break
        case .aucuneConnue: break
        }
    }

    @Test("Une clé équivalente (nom complet déclaré dans le fichier) vise aussi l'eau")
    func cleEquivalente() {
        var r = reserve("a", eau: "Marne")
        r.clesEquivalentes = [cleEau("La Grande Marne")]
        let eau = Eau(nom: "La Grande Marne", cle: cleEau("La Grande Marne"), type: .riviere)
        if case .surCetteEau = DetecteurReserve.evaluer(eauxProches: [eau], departement: Departement(code: "94"), reserves: [r]) {} else {
            Issue.record("attendu surCetteEau")
        }
    }

    @Test("Critère 5 : les vrais fichiers regles/*.json donnent des réserves avec une source non vide")
    func fichiersReels() {
        let chargeur = ChargeurRegles.embarque()
        let codes = chargeur.codesPresents()
        #expect(!codes.isEmpty)
        var total = 0
        for code in codes {
            for r in ReservesDuDepartement.charger(departement: Departement(code: code), chargeur: chargeur) {
                total += 1
                #expect(!r.sources.isEmpty, "réserve \(r.id) sans source")
                #expect(r.sources.allSatisfy { !$0.titre.isEmpty }, "réserve \(r.id) : titre de source vide")
                #expect(r.departement == code)
                #expect(r.placeeSurUneEau == (r.eauCle != nil))
            }
        }
        #expect(total > 0)
    }

    @Test("Le département 94 réel : des réserves placées sur la Seine, et des réserves non placées")
    func quatreVingtQuatorze() {
        let r = ReservesDuDepartement.charger(departement: Departement(code: "94"))
        #expect(r.contains { $0.eauCle == "seine" && $0.placeeSurUneEau })
        let seine = Eau(nom: "Seine", cle: "seine", type: .riviere)
        if case .surCetteEau = DetecteurReserve.evaluer(eauxProches: [seine], departement: Departement(code: "94"), reserves: r) {} else {
            Issue.record("attendu surCetteEau sur la Seine du 94")
        }
    }

    @Test("Département inconnu ou absent : liste vide, pas de plantage")
    func absent() {
        #expect(ReservesDuDepartement.charger(departement: .inconnu).isEmpty)
        #expect(ReservesDuDepartement.charger(departement: Departement(code: "ZZ")).isEmpty)
    }
}
