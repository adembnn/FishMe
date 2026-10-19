import Foundation
import Testing
@testable import Core

@Suite("Skins : galerie et libellés")
struct GalerieSkinsTests {
    typealias O = OutilsSkins
    let paris = OutilsSkins.calendrier()

    func ids(_ entrees: [EntreeGalerie]) -> [IdentifiantSkin] { entrees.map(\.id) }

    @Test("19 octobre, sans Pro : Halloween est en ce moment, Noël revient chaque année")
    func dixNeufOctobre() {
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19)))
        #expect(ids(r.mesDecors) == [.riviere, .etang, .grotte])
        #expect(ids(r.enCeMoment) == [.halloween])
        #expect(ids(r.reviennentChaqueAnnee) == [.noel, .ouvertureTruite, .ete])
    }

    @Test("5 novembre : Halloween passe dans « Reviennent chaque année »")
    func cinqNovembre() {
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 11, 5), abonne: true))
        #expect(r.enCeMoment.isEmpty)
        #expect(ids(r.reviennentChaqueAnnee).contains(.halloween))
    }

    @Test("Les décors à gagner restent dans « Mes décors », avec leur critère")
    func decorsAGagner() throws {
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19)))
        let etang = try #require(r.mesDecors.first { $0.id == .etang })
        #expect(etang.statut == .aGagner(.especesDifferentes(5)))
    }

    @Test("Un skin sans image est écarté, jamais montré vide")
    func skinSansImage() {
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19))) { $0.id == .riviere || $0.id == .halloween }
        #expect(ids(r.mesDecors) == [.riviere])
        #expect(ids(r.enCeMoment) == [.halloween])
        #expect(r.reviennentChaqueAnnee.isEmpty)
    }

    @Test("Les sept skins s'affichent sans aucune image quand leur fond est dessiné en code")
    func septSkinsSansImage() {
        let tous = Set(CatalogueSkins.tous.map(\.id))
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19))) {
            skinAffichable($0, imageExiste: { _ in false }, fondDessine: { tous.contains($0) })
        }
        #expect(r.mesDecors.count + r.enCeMoment.count + r.reviennentChaqueAnnee.count == 7)
        #expect(ids(r.mesDecors) == [.riviere, .etang, .grotte])
        #expect(ids(r.enCeMoment) == [.halloween])
        #expect(ids(r.reviennentChaqueAnnee) == [.noel, .ouvertureTruite, .ete])
    }

    @Test("Sans image ni fond dessiné, seul le décor de départ reste")
    func sansImageNiDessin() {
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19))) {
            skinAffichable($0, imageExiste: { _ in false }, fondDessine: { _ in false })
        }
        #expect(ids(r.mesDecors) == [.riviere])
        #expect(r.enCeMoment.isEmpty)
        #expect(r.reviennentChaqueAnnee.isEmpty)
    }

    @Test("Une illustration suffit à montrer un skin sans fond dessiné")
    func imageSeule() {
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19))) {
            skinAffichable($0, imageExiste: { $0 == "fond-halloween-grand" }, fondDessine: { _ in false })
        }
        #expect(ids(r.enCeMoment) == [.halloween])
    }

    @Test("Source du fond : l'illustration d'abord, puis le dessin, puis le fond d'avant les skins")
    func sourceDuFond() {
        let h = CatalogueSkins.skin(.halloween)
        #expect(sourceFond(h, format: .grand, imageExiste: { $0 == "fond-halloween-grand" }, fondDessine: { _ in true })
                == .image("fond-halloween-grand"))
        #expect(sourceFond(h, format: .grand, imageExiste: { _ in false }, fondDessine: { _ in true }) == .dessine)
        #expect(sourceFond(h, format: .petit, imageExiste: { _ in false }, fondDessine: { _ in false }) == .repli("fond-petit"))
        #expect(sourceFond(nil, format: .moyen, imageExiste: { _ in true }, fondDessine: { _ in true }) == .repli("fond-moyen"))
        let r = CatalogueSkins.skin(.parDefaut)
        #expect(sourceFond(r, format: .grand, imageExiste: { $0 == "fond-grand" }, fondDessine: { _ in true }) == .image("fond-grand"))
    }

    @Test("Un décor gagné reste dans « Mes décors » quand le Pro est perdu")
    func gagneResteSansPro() {
        let p = ProgressionPecheur(especesDifferentes: 5)
        let r = rangeesGalerie(dans: O.contexte(O.date(2026, 10, 19), abonne: false, progression: p))
        #expect(r.mesDecors.first { $0.id == .etang }?.statut == .disponible)
    }

    @Test("« Revient en octobre » : le mois, jamais un nombre de jours")
    func revientEnMois() {
        #expect(LibellesSkins.revient(le: O.date(2027, 10, 15, heure: 0), calendrier: paris) == "Revient en octobre")
        #expect(LibellesSkins.revient(le: O.date(2027, 12, 1, heure: 0), calendrier: paris) == "Revient en décembre")
        #expect(LibellesSkins.revient(le: O.date(2027, 8, 1, heure: 0), calendrier: paris) == "Revient en août")
    }

    @Test("Textes « À gagner »")
    func aGagner() {
        #expect(LibellesSkins.aGagner(.especesDifferentes(5)) == "À gagner : 5 espèces différentes")
        #expect(LibellesSkins.aGagner(.especesDifferentes(1)) == "À gagner : 1 espèce")
        #expect(LibellesSkins.aGagner(.sessions(10)) == "À gagner : 10 sessions de pêche")
        #expect(LibellesSkins.aGagner(.unLegendaire) == "À gagner : un poisson légendaire")
    }

    @Test("Libellé d'accessibilité d'une vignette")
    func accessibilite() throws {
        let h = try #require(CatalogueSkins.skin(.halloween))
        let enSaison = O.contexte(O.date(2026, 10, 20), abonne: true)
        #expect(LibellesSkins.accessibilite(h, statut: statut(h, dans: enSaison), calendrier: paris)
                == "Halloween, inclus avec Pro, disponible")
        let sansPro = O.contexte(O.date(2026, 10, 20))
        #expect(LibellesSkins.accessibilite(h, statut: statut(h, dans: sansPro), calendrier: paris)
                == "Halloween, inclus avec Pro, aperçu seulement, Pro requis pour l'appliquer")
    }

    @Test("Texte du bouton du bandeau d'aperçu")
    func bouton() {
        #expect(LibellesSkins.boutonAppliquer(.disponible) == "Appliquer")
        #expect(LibellesSkins.boutonAppliquer(.apercuSeulement(raison: .proRequis)) == "Appliquer avec Pro")
        #expect(LibellesSkins.boutonAppliquer(.aGagner(.unLegendaire)) == nil)
    }
}
