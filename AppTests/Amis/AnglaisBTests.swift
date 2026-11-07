import Foundation
import Testing
@testable import BuildChallenge

/// US13b : seul ce que la Release sans iCloud montre est traduit (la pastille de profil de la carte et son badge).
/// Amis, Compte et le profil public restent éteints (communauté « bientôt »), donc non traduits.
@MainActor
struct AnglaisBTests {
    private let en = Locale(identifier: "en_US")
    private let fr = Locale(identifier: "fr_FR")
    private let interdits = ["autoris", "allowed", "legal", "tu peux la garder", "you can keep"]

    @Test func lesBadgesSontEnAnglaisEnRegionUS() {
        #expect(BadgeProfil.niveau(cartes: 0, locale: en).titre == "Beginner")
        #expect(BadgeProfil.niveau(cartes: 5, locale: en).titre == "Angler")
        #expect(BadgeProfil.niveau(cartes: 12, locale: en).titre == "Experienced")
        #expect(BadgeProfil.niveau(cartes: 40, locale: en).titre == "Expert")
    }

    @Test func lesBadgesRestentEnFrancaisEnRegionFR() {
        #expect(BadgeProfil.niveau(cartes: 0, locale: fr).titre == "Débutant")
        #expect(BadgeProfil.niveau(cartes: 5, locale: fr).titre == "Pêcheur")
        #expect(BadgeProfil.niveau(cartes: 12).titre == "Confirmé")
        #expect(BadgeProfil.niveau(cartes: 40).titre == "Expert")
    }

    @Test func leLibelleAccessibleEstTraduit() {
        let nom = "Sam"
        #expect(AnglaisB.t("Mon profil, \(nom)", en) == "My profile, Sam")
        #expect(AnglaisB.t("Mon profil, \(nom), \("Expert")", en) == "My profile, Sam, Expert")
        #expect(AnglaisB.t("Mon profil, \(nom)", fr) == "Mon profil, Sam")
        #expect(AnglaisB.t("Mon profil, \(nom), \("Expert")", fr) == "Mon profil, Sam, Expert")
    }

    @Test func aucunMotInterditEnAnglais() {
        let textes = [0, 5, 12, 40].map { BadgeProfil.niveau(cartes: $0, locale: en).titre }
            + [AnglaisB.t("Mon profil, \("x")", en), AnglaisB.t("Mon profil, \("x"), \("y")", en)]
        for texte in textes {
            for mot in interdits { #expect(!texte.lowercased().contains(mot)) }
        }
    }
}
