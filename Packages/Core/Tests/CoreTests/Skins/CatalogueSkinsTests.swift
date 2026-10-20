import Foundation
import Testing
@testable import Core

@Suite("Skins : catalogue")
struct CatalogueSkinsTests {
    @Test("Huit skins au départ, identifiants uniques")
    func identifiantsUniques() {
        #expect(CatalogueSkins.tous.count == 8)
        #expect(Set(CatalogueSkins.tous.map(\.id)).count == CatalogueSkins.tous.count)
    }

    @Test("Le décor de départ est présent et gagné d'emblée")
    func decorDeDepart() throws {
        let skin = try #require(CatalogueSkins.skin(.parDefaut))
        #expect(skin.origine == .gagne(.especesDifferentes(0)))
        let c = OutilsSkins.contexte(OutilsSkins.date(2026, 1, 1))
        #expect(statut(skin, dans: c) == .disponible)
        #expect(skin.nomImageFond(.grand) == "fond-grand")
    }

    @Test("Sous-bois : décor gagné après dix sessions de pêche, rangé entre la grotte et les saisons")
    func sousBois() throws {
        let skin = try #require(CatalogueSkins.skin(.sousBois))
        #expect(skin.id.valeur == "sous-bois")
        #expect(skin.nom == "Sous-bois")
        #expect(skin.origine == .gagne(.sessions(10)))
        #expect(skin.nomImageFond(.grand) == "fond-sous-bois-grand")
        let grotte = try #require(CatalogueSkins.skin(.grotte))
        #expect(grotte.ordre < skin.ordre)
        let c = OutilsSkins.contexte(OutilsSkins.date(2026, 10, 20), progression: ProgressionPecheur(sessions: 9))
        #expect(statut(skin, dans: c) == .aGagner(.sessions(10)))
        let gagne = OutilsSkins.contexte(OutilsSkins.date(2026, 10, 20), progression: ProgressionPecheur(sessions: 10))
        #expect(statut(skin, dans: gagne) == .disponible)
        #expect(LibellesSkins.accessibilite(skin, statut: .aGagner(.sessions(10)), calendrier: OutilsSkins.calendrier())
                == "Sous-bois, décor gagné en pêchant, À gagner : 10 sessions de pêche")
    }

    @Test("Aucun skin sans nom")
    func nomsPresents() {
        for skin in CatalogueSkins.tous { #expect(!skin.nom.trimmingCharacters(in: .whitespaces).isEmpty) }
    }

    @Test("Ordre stable et sans doublon")
    func ordreStable() {
        let ordres = CatalogueSkins.tous.map(\.ordre)
        #expect(ordres == ordres.sorted())
        #expect(Set(ordres).count == ordres.count)
    }

    @Test("Les décors gagnés d'abord, les saisons ensuite")
    func gagnesAvantSaisons() {
        func estGagne(_ skin: Skin) -> Bool {
            if case .gagne = skin.origine { return true }
            return false
        }
        func estSaison(_ skin: Skin) -> Bool {
            if case .saison = skin.origine { return true }
            return false
        }
        let dernierGagne = CatalogueSkins.tous.filter(estGagne).map(\.ordre).max()!
        let premiereSaison = CatalogueSkins.tous.filter(estSaison).map(\.ordre).min()!
        #expect(dernierGagne < premiereSaison)
    }

    @Test("Fenêtres de saison sans trou absurde : Halloween avant Noël, jours et mois valides")
    func fenetresSensees() throws {
        func fenetre(_ id: IdentifiantSkin) throws -> FenetreAnnuelle {
            guard case .saison(_, let f) = try #require(CatalogueSkins.skin(id)).origine else {
                Issue.record("pas une saison"); return FenetreAnnuelle(moisDebut: 1, jourDebut: 1, moisFin: 1, jourFin: 1)
            }
            return f
        }
        let debutHalloween = try fenetre(.halloween).moisDebut
        let debutNoel = try fenetre(.noel).moisDebut
        #expect(debutHalloween < debutNoel)
        for skin in CatalogueSkins.tous {
            guard case .saison(_, let f) = skin.origine else { continue }
            #expect((1...12).contains(f.moisDebut) && (1...12).contains(f.moisFin))
            #expect((1...31).contains(f.jourDebut) && (1...31).contains(f.jourFin))
        }
    }

    @Test("Chaque thème de saison a son skin, une fois")
    func chaqueThemeUneFois() {
        let themes = CatalogueSkins.tous.compactMap { skin -> ThemeSaison? in
            if case .saison(let t, _) = skin.origine { return t } else { return nil }
        }
        #expect(Set(themes) == Set(ThemeSaison.allCases))
        #expect(themes.count == ThemeSaison.allCases.count)
    }

    @Test("Poids annoncé sous les plafonds")
    func poids() {
        for skin in CatalogueSkins.tous { #expect(skin.poidsApproxOctets <= CatalogueSkins.plafondOctetsParSkin) }
        #expect(CatalogueSkins.tous.map(\.poidsApproxOctets).reduce(0, +) <= CatalogueSkins.plafondOctetsTotal)
    }

    @Test("Au plus trois petits objets par skin")
    func objets() {
        for skin in CatalogueSkins.tous { #expect(skin.objets.count <= 3) }
        let trop = Skin(id: IdentifiantSkin("x"), nom: "x", origine: .pro, ordre: 0, poidsApproxOctets: 0,
                        objets: ["a", "b", "c", "d"])
        #expect(trop.objets.count == 3)
    }

    @Test("Teinte bornée entre 0 et 1")
    func teinteBornee() {
        let t = TeinteEclairage(rouge: 2, vert: -1, bleu: 0.5, opacite: 9)
        #expect(t.rouge == 1 && t.vert == 0 && t.bleu == 0.5 && t.opacite == 1)
    }

    @Test("Noms d'images des fonds, par format")
    func nomsImages() throws {
        let h = try #require(CatalogueSkins.skin(.halloween))
        #expect(h.nomImageFond(.petit) == "fond-halloween-petit")
        #expect(h.nomImageFond(.moyen) == "fond-halloween-moyen")
        #expect(h.nomImageFond(.grand) == "fond-halloween-grand")
        let truite = try #require(CatalogueSkins.skin(.ouvertureTruite))
        #expect(truite.nomImageFond(.grand) == "fond-ouverture-truite-grand")
        #expect(Skin.nomImageRepli(.moyen) == "fond-moyen")
    }

    @Test("Un identifiant s'écrit et se relit comme une simple chaîne")
    func identifiantCodable() throws {
        let donnees = try JSONEncoder().encode([IdentifiantSkin.halloween])
        #expect(String(data: donnees, encoding: .utf8) == "[\"halloween\"]")
        let relu = try JSONDecoder().decode([IdentifiantSkin].self, from: donnees)
        #expect(relu == [.halloween])
        #expect(CatalogueSkins.skin(IdentifiantSkin("inconnu-d-une-version-future")) == nil)
    }
}
