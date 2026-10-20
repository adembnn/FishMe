import Foundation
import SwiftUI
import Testing
import Core
@testable import BuildChallenge

// Tests des décors dessinés en code (N1, suite). Écrits sans Mac, non exécutés (⚠ à lancer sur le Mac de Sullyvan).
// La règle « quel dessin pour quel skin » du widget est aussi testée sous Linux (AppTests/WidgetAquarium/FondWidgetTests.swift).
@MainActor
struct DecorsDessinesTests {
    static let dessines: [IdentifiantSkin] = [.sousBois, .etang, .grotte, .halloween, .ouvertureTruite]

    @Test func lesCinqDecorsChoisisOntUnDessinEtLeDecorDeDepartEtNoelEtEteNon() {
        for id in Self.dessines {
            #expect(FondWidget.aUnDessin(id.valeur), "dessin manquant : \(id.valeur)")
            #expect(DecorDessin.reglage(id.valeur) != nil, "réglage manquant : \(id.valeur)")
        }
        for id in [IdentifiantSkin.parDefaut, .noel, .ete, IdentifiantSkin("inconnu")] {
            #expect(!FondWidget.aUnDessin(id.valeur))
            #expect(DecorDessin.reglage(id.valeur) == nil)
        }
    }

    @Test func laListeDesDecorsDessinesCorrespondAuCatalogue() {
        let ids = Set(CatalogueSkins.tous.map(\.id.valeur))
        #expect(FondWidget.decorsDessines.isSubset(of: ids))
        #expect(FondWidget.decorsDessines == ids.subtracting(["riviere", "noel", "ete"]))
        #expect(FondWidget.decorsDessines == Set(Self.dessines.map(\.valeur)))
    }

    @Test func lAppEtLeWidgetChoisissentLeMemeFondPourChaqueSkin() {
        for skin in CatalogueSkins.tous {
            for format in FormatFond.allCases {
                let app = sourceFond(skin, format: format, imageExiste: { _ in false },
                                     fondDessine: { FondWidget.aUnDessin($0.valeur) })
                let formatWidget = FondWidget.Format(rawValue: format.rawValue)!
                let widget = FondWidget.source(skin: skin.id.valeur, format: formatWidget, existe: { _ in false })
                switch (app, widget) {
                case (.dessine, .dessin(let id)): #expect(id == skin.id.valeur)
                case (.repli(let a), .repli(let b)): #expect(a == b)
                case (.image(let a), .image(let b)): #expect(a == b)
                default: Issue.record("app et widget divergent pour \(skin.id.valeur) (\(format.rawValue))")
                }
            }
        }
    }

    @Test func uneIllustrationRestePrioritaireSurLeDessin() {
        let skin = CatalogueSkins.skin(.halloween)
        let source = sourceFond(skin, format: .grand, imageExiste: { $0 == "fond-halloween-grand" }, fondDessine: { _ in true })
        #expect(source == .image("fond-halloween-grand"))
        #expect(FondWidget.source(skin: "halloween", format: .grand, existe: { $0 == "fond-halloween-grand" })
                == .image("fond-halloween-grand"))
    }

    @Test func laGalerieMontreLesDecorsDessinesEtMasqueNoelEtEte() {
        let jour = SkinsGalerieTests.date(2026, 10, 19)
        let contexte = SkinsGalerieTests.contexte(jour, abonne: true, progression: ProgressionPecheur(especesDifferentes: 9, sessions: 12, legendairesPris: 1))
        let rangees = rangeesGalerie(dans: contexte) {
            skinAffichable($0, imageExiste: { _ in false }, fondDessine: { FondWidget.aUnDessin($0.valeur) })
        }
        let tous = (rangees.mesDecors + rangees.enCeMoment + rangees.reviennentChaqueAnnee).map(\.id)
        #expect(Set(tous) == Set([IdentifiantSkin.parDefaut] + Self.dessines))
        #expect(!tous.contains(.noel))
        #expect(!tous.contains(.ete))
        #expect(rangees.mesDecors.map(\.id) == [.riviere, .etang, .grotte, .sousBois])
    }

    @Test func lesReglagesRestentDansDesBornesSobres() throws {
        for id in Self.dessines {
            let r = try #require(DecorDessin.reglage(id.valeur))
            let m = r.filtre.multiplicateur
            #expect([m.0, m.1, m.2].allSatisfy { $0 > 0 && $0 <= 1 })
            #expect(r.filtre.saturation > 0 && r.filtre.saturation <= 1.2)
            if let rais = r.ambiance.rais { #expect(rais.a > 0 && rais.a <= 0.25 && rais.n >= 1 && rais.n <= 5) }
            if let p = r.ambiance.particules { #expect(p.a > 0 && p.a <= 1) }
        }
    }

    @Test func leCadreGardeLeSolEnBasEtLePlafondEnHaut() {
        // Un iPhone : 390 x 844, le cadre de conception tel quel.
        let phone = CadreDecor(CGSize(width: 390, height: 844))
        #expect(phone.s == 1)
        #expect(phone.unite(100) == 100 && phone.unite(742) == 742 && phone.unite(844) == 844)
        // Un widget moyen (338 x 158) : le bas du dessin touche le bas du widget, le haut reste en haut.
        let moyen = CadreDecor(CGSize(width: 338, height: 158))
        #expect(abs(moyen.p(0, 844).y - 158) < 0.001)
        #expect(moyen.p(0, -10).y < 0)
        #expect(moyen.unite(300) == 300)
        // La mise à l'échelle est continue et ne remonte jamais.
        var precedent = moyen.unite(0)
        for y in stride(from: 1, through: 860, by: 1) {
            let courant = moyen.unite(CGFloat(y))
            #expect(courant >= precedent - 0.0001)
            precedent = courant
        }
        // Plus haut qu'un iPhone : le sol reste collé en bas aussi.
        let grand = CadreDecor(CGSize(width: 440, height: 956))
        #expect(abs(grand.p(0, 844).y - 956) < 0.001)
    }

    @Test func laGraineDonneToujoursLaMemeSuite() {
        var a = GraineDecor(42)
        var b = GraineDecor(42)
        for _ in 0..<50 {
            let x = a.suivant()
            #expect(x == b.suivant())
            #expect(x >= 0 && x < 1)
        }
        var c = GraineDecor(43)
        var d = GraineDecor(42)
        #expect(c.suivant() != d.suivant())
    }

    @Test func leDecorFigeUtiliseUnInstantFixe() {
        // Le widget et « Réduire les animations » n'ont aucun mouvement : l'instant est une constante.
        #expect(DecorDessin.tFixe == 27)
        #expect(DecorDessin.balance(DecorDessin.tFixe, periode: 12, retard: 0) == DecorDessin.balance(DecorDessin.tFixe, periode: 12, retard: 0))
    }
}
