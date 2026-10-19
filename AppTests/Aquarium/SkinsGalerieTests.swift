import Foundation
import SwiftUI
import Testing
import Core
@testable import BuildChallenge

// Tests de l'app pour N1 : écrits sans Mac, non exécutés (⚠ à lancer sur le Mac de Sullyvan).
@MainActor
struct SkinsGalerieTests {
    // ⚠ à vérifier : si `Binding(get:set:)` exige des fermetures `@Sendable` avec Swift 6, rendre `Boite` `@unchecked Sendable`.
    final class Boite { var valeur: IdentifiantSkin = .parDefaut }

    static let paris: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Paris")!
        return c
    }()

    static func date(_ a: Int, _ m: Int, _ j: Int) -> Date {
        paris.date(from: DateComponents(year: a, month: m, day: j, hour: 12))!
    }

    static func contexte(_ d: Date, abonne: Bool, progression: ProgressionPecheur = ProgressionPecheur()) -> ContexteSkin {
        ContexteSkin(date: d, calendrier: paris, abonne: abonne, progression: progression)
    }

    /// Des réglages à part : un test n'écrit jamais dans ceux de l'app.
    static func reglages() -> UserDefaults {
        let nom = "essai-skins-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: nom)!
        d.removePersistentDomain(forName: nom)
        return d
    }

    @Test func sansProAppliquerAvecProAppelleLOffreSansChangerLeChoix() throws {
        let boite = Boite()
        let binding = Binding(get: { boite.valeur }, set: { boite.valeur = $0 })
        var demandes = 0
        var changements: [IdentifiantSkin] = []
        let halloween = try #require(CatalogueSkins.skin(.halloween))
        let applique = ApplicationSkin.appliquer(
            halloween, contexte: Self.contexte(Self.date(2026, 10, 20), abonne: false), choisi: binding,
            demanderPro: { demandes += 1 }, auChangement: { changements.append($0) }, defaults: Self.reglages())
        #expect(!applique)
        #expect(demandes == 1)
        #expect(changements.isEmpty)
        #expect(boite.valeur == .parDefaut)
    }

    @Test func avecProAppliquerEcritLeChoixEtAppelleAuChangementUneFois() throws {
        let boite = Boite()
        let binding = Binding(get: { boite.valeur }, set: { boite.valeur = $0 })
        var demandes = 0
        var changements: [IdentifiantSkin] = []
        let halloween = try #require(CatalogueSkins.skin(.halloween))
        let applique = ApplicationSkin.appliquer(
            halloween, contexte: Self.contexte(Self.date(2026, 10, 20), abonne: true), choisi: binding,
            demanderPro: { demandes += 1 }, auChangement: { changements.append($0) }, defaults: Self.reglages())
        #expect(applique)
        #expect(demandes == 0)
        #expect(changements == [.halloween])
        #expect(boite.valeur == .halloween)
    }

    @Test func horsSaisonOuAGagnerNeChangeRien() throws {
        let boite = Boite()
        let binding = Binding(get: { boite.valeur }, set: { boite.valeur = $0 })
        var appels = 0
        let noel = try #require(CatalogueSkins.skin(.noel))
        let grotte = try #require(CatalogueSkins.skin(.grotte))
        let c = Self.contexte(Self.date(2026, 10, 20), abonne: true)
        #expect(!ApplicationSkin.appliquer(noel, contexte: c, choisi: binding, demanderPro: { appels += 1 },
                                           auChangement: { _ in appels += 1 }, defaults: Self.reglages()))
        #expect(!ApplicationSkin.appliquer(grotte, contexte: c, choisi: binding, demanderPro: { appels += 1 },
                                           auChangement: { _ in appels += 1 }, defaults: Self.reglages()))
        #expect(appels == 0)
        #expect(boite.valeur == .parDefaut)
    }

    @Test func unDecorGagneAppliqueEstRetenuPourLeRetourSansPro() throws {
        let reglages = Self.reglages()
        let boite = Boite()
        let binding = Binding(get: { boite.valeur }, set: { boite.valeur = $0 })
        let etang = try #require(CatalogueSkins.skin(.etang))
        let avecEtang = Self.contexte(Self.date(2026, 10, 20), abonne: false, progression: ProgressionPecheur(especesDifferentes: 5))
        ApplicationSkin.appliquer(etang, contexte: avecEtang, choisi: binding, demanderPro: {}, auChangement: { _ in },
                                  defaults: reglages)
        #expect(reglages.string(forKey: ChoixSkin.cleDernierGagne) == "etang")
        // Le pêcheur a ensuite choisi Halloween avec Pro ; le Pro prend fin : retour à l'étang, jamais un fond vide.
        let sansPro = Self.contexte(Self.date(2026, 10, 20), abonne: false, progression: ProgressionPecheur(especesDifferentes: 5))
        #expect(ChoixSkin.affiche(brut: "halloween", contexte: sansPro, defaults: reglages) == .etang)
    }

    @Test func choixInconnuOuVideRetombeSurLeDecorDeDepart() {
        let c = Self.contexte(Self.date(2026, 10, 20), abonne: true)
        #expect(ChoixSkin.affiche(brut: "skin-d-une-version-future", contexte: c, defaults: Self.reglages()) == .parDefaut)
        #expect(ChoixSkin.affiche(brut: "", contexte: c, defaults: Self.reglages()) == .parDefaut)
    }

    @Test func leBindingLitEtEcritLaChaine() {
        // ⚠ à vérifier : capture d'une variable locale par les fermetures du `Binding` (Swift 6).
        var brut = "halloween"
        let b = ChoixSkin.binding(Binding(get: { brut }, set: { brut = $0 }))
        #expect(b.wrappedValue == .halloween)
        b.wrappedValue = .noel
        #expect(brut == "noel")
    }

    @Test func lesRangeesAuxDatesInjectees() {
        let le19 = rangeesGalerie(dans: Self.contexte(Self.date(2026, 10, 19), abonne: false))
        #expect(le19.enCeMoment.map(\.id) == [.halloween])
        #expect(le19.reviennentChaqueAnnee.map(\.id).contains(.noel))
        let le5 = rangeesGalerie(dans: Self.contexte(Self.date(2026, 11, 5), abonne: false))
        #expect(le5.enCeMoment.isEmpty)
        #expect(le5.reviennentChaqueAnnee.map(\.id).contains(.halloween))
        let texte = le5.reviennentChaqueAnnee.first { $0.id == .halloween }
            .map { LibellesSkins.ligneStatut($0.statut, calendrier: Self.paris) }
        #expect(texte == "Revient en octobre")
    }

    @Test func lesLibellesNeContiennentAucunMotDePression() {
        let interdits = ["dernière chance", "dernier jour", "plus que", "vite", "offre limitée", "expire dans", "coffre",
                         "loot", "mystère"]
        let c = Self.contexte(Self.date(2026, 11, 5), abonne: false)
        for skin in CatalogueSkins.tous {
            let s = statut(skin, dans: c)
            let textes = [LibellesSkins.ligneStatut(s, calendrier: Self.paris),
                          LibellesSkins.accessibilite(skin, statut: s, calendrier: Self.paris),
                          LibellesSkins.boutonAppliquer(s) ?? ""]
            for t in textes { for mot in interdits { #expect(!t.lowercased().contains(mot)) } }
        }
    }

    @Test func leFondDuDecorDeDepartEstLeFondDAvantLesSkins() {
        #expect(FondSkin.nomImage(.parDefaut, format: .grand) == "fond-grand")
        // Un identifiant inconnu ou un skin sans image : repli, jamais un nom d'image absent.
        #expect(FondSkin.nomImage(IdentifiantSkin("inconnu"), format: .petit) == "fond-petit")
        #expect(FondSkin.nomImage(.ete, format: .moyen) == "fond-ete-moyen" || FondSkin.nomImage(.ete, format: .moyen) == "fond-moyen")
    }
}
