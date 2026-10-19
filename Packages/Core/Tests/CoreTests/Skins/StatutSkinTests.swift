import Foundation
import Testing
@testable import Core

@Suite("Skins : statut")
struct StatutSkinTests {
    typealias O = OutilsSkins
    let paris = OutilsSkins.calendrier()

    func skin(_ id: IdentifiantSkin) -> Skin { CatalogueSkins.skin(id)! }

    // MARK: Décors gagnés

    @Test("Gagné, critère rempli, sans Pro : disponible")
    func gagneRempliSansPro() {
        let c = O.contexte(O.date(2026, 10, 20), progression: ProgressionPecheur(especesDifferentes: 5))
        #expect(statut(skin(.etang), dans: c) == .disponible)
    }

    @Test("Gagné, critère rempli, avec Pro : disponible")
    func gagneRempliAvecPro() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: true, progression: ProgressionPecheur(especesDifferentes: 5))
        #expect(statut(skin(.etang), dans: c) == .disponible)
    }

    @Test("Gagné, critère non rempli : à gagner, avec le critère")
    func gagneNonRempli() {
        let c = O.contexte(O.date(2026, 10, 20), progression: ProgressionPecheur(especesDifferentes: 4))
        #expect(statut(skin(.etang), dans: c) == .aGagner(.especesDifferentes(5)))
        #expect(statut(skin(.grotte), dans: c) == .aGagner(.unLegendaire))
    }

    @Test("Gagné, critère non rempli, même avec Pro : à gagner (le Pro n'achète pas un décor gagné)")
    func gagneNonRempliAvecPro() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: true)
        #expect(statut(skin(.etang), dans: c) == .aGagner(.especesDifferentes(5)))
    }

    @Test("Le décor de départ est disponible d'emblée, sans Pro")
    func decorDeDepart() {
        let c = O.contexte(O.date(2026, 10, 20))
        #expect(statut(skin(.parDefaut), dans: c) == .disponible)
    }

    @Test("Les trois critères de décor")
    func criteres() {
        let p = ProgressionPecheur(especesDifferentes: 0, sessions: 10, legendairesPris: 1)
        #expect(p.satisfait(.sessions(10)))
        #expect(!p.satisfait(.sessions(11)))
        #expect(p.satisfait(.unLegendaire))
        #expect(!ProgressionPecheur().satisfait(.unLegendaire))
        #expect(ProgressionPecheur(especesDifferentes: 5).satisfait(.especesDifferentes(5)))
        #expect(!ProgressionPecheur(especesDifferentes: 4).satisfait(.especesDifferentes(5)))
    }

    // MARK: Saisons

    @Test("Halloween en saison, sans Pro : aperçu seulement")
    func halloweenSansPro() {
        let c = O.contexte(O.date(2026, 10, 20))
        #expect(statut(skin(.halloween), dans: c) == .apercuSeulement(raison: .proRequis))
    }

    @Test("Halloween en saison, avec Pro : disponible")
    func halloweenAvecPro() {
        let c = O.contexte(O.date(2026, 10, 20), abonne: true)
        #expect(statut(skin(.halloween), dans: c) == .disponible)
    }

    @Test("Halloween la veille : hors saison, revient le 15 octobre 2026")
    func halloweenLaVeille() {
        let c = O.contexte(O.date(2026, 10, 14), abonne: true)
        #expect(statut(skin(.halloween), dans: c) == .horsSaison(revientLe: O.date(2026, 10, 15, heure: 0)))
    }

    @Test("Halloween ouvert le 15 octobre et le 4 novembre, fermé le 5")
    func halloweenBornes() {
        #expect(statut(skin(.halloween), dans: O.contexte(O.date(2026, 10, 15), abonne: true)) == .disponible)
        #expect(statut(skin(.halloween), dans: O.contexte(O.date(2026, 11, 4), abonne: true)) == .disponible)
        #expect(statut(skin(.halloween), dans: O.contexte(O.date(2026, 11, 5), abonne: true))
                == .horsSaison(revientLe: O.date(2027, 10, 15, heure: 0)))
    }

    @Test("Noël : ouvert les 31 décembre et 2 janvier, fermé le 7 janvier, revient le 1er décembre suivant")
    func noelTraverseLAnnee() {
        #expect(statut(skin(.noel), dans: O.contexte(O.date(2026, 12, 31), abonne: true)) == .disponible)
        #expect(statut(skin(.noel), dans: O.contexte(O.date(2027, 1, 2), abonne: true)) == .disponible)
        #expect(statut(skin(.noel), dans: O.contexte(O.date(2027, 1, 7), abonne: true))
                == .horsSaison(revientLe: O.date(2027, 12, 1, heure: 0)))
    }

    @Test("Le même 20 octobre donne le même résultat en 2026 et en 2027")
    func memeJourChaqueAnnee() {
        for annee in [2026, 2027, 2028] {
            let c = O.contexte(O.date(annee, 10, 20), abonne: true)
            #expect(statut(skin(.halloween), dans: c) == .disponible)
        }
    }

    @Test("Hors saison, sans Pro : hors saison (rien à appliquer, rien à acheter)")
    func horsSaisonSansPro() {
        let c = O.contexte(O.date(2026, 7, 1))
        #expect(statut(skin(.halloween), dans: c) == .horsSaison(revientLe: O.date(2026, 10, 15, heure: 0)))
    }

    @Test("Été : en saison le 1er juillet")
    func eteEnSaison() {
        #expect(statut(skin(.ete), dans: O.contexte(O.date(2026, 7, 1))) == .apercuSeulement(raison: .proRequis))
        #expect(statut(skin(.ete), dans: O.contexte(O.date(2026, 7, 1), abonne: true)) == .disponible)
    }

    // MARK: Pro et défis

    @Test("Skin Pro de toute l'année : aperçu sans Pro, disponible avec")
    func skinPro() {
        let pro = Skin(id: IdentifiantSkin("essai-pro"), nom: "Essai", origine: .pro, ordre: 99, poidsApproxOctets: 0)
        #expect(statut(pro, dans: O.contexte(O.date(2026, 7, 1))) == .apercuSeulement(raison: .proRequis))
        #expect(statut(pro, dans: O.contexte(O.date(2026, 7, 1), abonne: true)) == .disponible)
    }

    @Test("Skin offert par défi : sans défi comme le Pro, avec défi disponible")
    func skinOffertParDefi() {
        let id = IdentifiantSkin("essai-defi")
        let defi = Skin(id: id, nom: "Défi", origine: .offertParDefi, ordre: 98, poidsApproxOctets: 0)
        #expect(statut(defi, dans: O.contexte(O.date(2026, 7, 1))) == .apercuSeulement(raison: .proRequis))
        #expect(statut(defi, dans: O.contexte(O.date(2026, 7, 1), abonne: true)) == .disponible)
        #expect(statut(defi, dans: O.contexte(O.date(2026, 7, 1), defis: [id])) == .disponible)
    }

    @Test("Un défi terminé rend un skin de saison disponible sans Pro et hors saison")
    func defiHorsSaisonSansPro() {
        let c = O.contexte(O.date(2026, 7, 1), abonne: false, defis: [.halloween])
        #expect(statut(skin(.halloween), dans: c) == .disponible)
    }

    @Test("Un défi terminé ne touche pas les autres skins")
    func defiLocal() {
        let c = O.contexte(O.date(2026, 10, 20), defis: [.noel])
        #expect(statut(skin(.halloween), dans: c) == .apercuSeulement(raison: .proRequis))
    }

    @Test("Un décor gagné reste disponible si le Pro est perdu")
    func gagneSansProApresPro() {
        let p = ProgressionPecheur(especesDifferentes: 5)
        #expect(statut(skin(.etang), dans: O.contexte(O.date(2026, 10, 20), abonne: true, progression: p)) == .disponible)
        #expect(statut(skin(.etang), dans: O.contexte(O.date(2026, 10, 20), abonne: false, progression: p)) == .disponible)
    }
}
