import Foundation
import Testing
@testable import Core

@Suite("Skins : appliquable")
struct AppliquableTests {
    typealias O = OutilsSkins
    let tout = ProgressionPecheur(especesDifferentes: 5, sessions: 10, legendairesPris: 1)

    @Test("Identifiant inconnu : le décor de départ")
    func inconnu() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: true, progression: tout)
        #expect(appliquable(IdentifiantSkin("zzz"), choisiActuel: nil, dans: c) == .parDefaut)
        #expect(appliquable(IdentifiantSkin(""), choisiActuel: .etang, dans: c) == .parDefaut)
    }

    @Test("Skin permis : lui-même")
    func permis() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: true, progression: tout)
        #expect(appliquable(.halloween, choisiActuel: nil, dans: c) == .halloween)
        #expect(appliquable(.etang, choisiActuel: nil, dans: c) == .etang)
    }

    @Test("Pro expiré : le dernier décor gagné choisi")
    func proExpire() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: false, progression: tout)
        #expect(appliquable(.halloween, choisiActuel: .etang, dans: c) == .etang)
    }

    @Test("Pro expiré sans mémoire : le décor gagné le plus avancé, jamais rien")
    func proExpireSansMemoire() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: false, progression: tout)
        #expect(appliquable(.halloween, choisiActuel: nil, dans: c) == .grotte)
    }

    @Test("Pro expiré, rien gagné : le décor de départ")
    func proExpireRienGagne() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: false)
        #expect(appliquable(.halloween, choisiActuel: nil, dans: c) == .parDefaut)
        // La mémoire pointe un décor que le pêcheur n'a pas : on ne la croit pas.
        #expect(appliquable(.halloween, choisiActuel: .grotte, dans: c) == .parDefaut)
    }

    @Test("Saison close, Pro actif : le skin reste affiché")
    func saisonCloseReste() {
        let c = O.contexte(O.date(2026, 11, 20), abonne: true, progression: tout)
        #expect(appliquable(.halloween, choisiActuel: .etang, dans: c) == .halloween)
    }

    @Test("Saison close et Pro perdu : retour au décor gagné")
    func saisonClosePuisProPerdu() {
        let c = O.contexte(O.date(2026, 11, 20), abonne: false, progression: tout)
        #expect(appliquable(.halloween, choisiActuel: .etang, dans: c) == .etang)
    }

    @Test("Défi : la récompense reste à vie, sans Pro et hors saison")
    func defiAVie() {
        let c = O.contexte(O.date(2026, 11, 20), abonne: false, progression: tout, defis: [.halloween])
        #expect(appliquable(.halloween, choisiActuel: .etang, dans: c) == .halloween)
    }

    @Test("Un décor gagné reste affiché quand le Pro est perdu")
    func gagneSansPro() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: false, progression: tout)
        #expect(appliquable(.grotte, choisiActuel: nil, dans: c) == .grotte)
    }

    @Test("Décor gagné dont le critère n'est plus rempli : repli, pas de fond vide")
    func gagnePlusRempli() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: false, progression: ProgressionPecheur())
        #expect(appliquable(.grotte, choisiActuel: nil, dans: c) == .parDefaut)
    }

    @Test("Le résultat est toujours un skin du catalogue")
    func toujoursConnu() {
        let ids = ["riviere", "etang", "grotte", "halloween", "noel", "ouverture-truite", "ete", "futur", ""]
        let dates = [O.date(2026, 1, 3), O.date(2026, 7, 1), O.date(2026, 10, 20), O.date(2026, 12, 31)]
        for id in ids {
            for date in dates {
                for abonne in [false, true] {
                    let c = O.contexte(date, abonne: abonne)
                    let r = appliquable(IdentifiantSkin(id), choisiActuel: nil, dans: c)
                    #expect(CatalogueSkins.skin(r) != nil)
                }
            }
        }
    }
}
