#if DEBUG
import Foundation
import SwiftUI
import Testing
import UIKit
import WidgetKit
@testable import BuildChallenge

// L15 : le widget aquarium construit depuis un fichier de l'App Group comme celui du simulateur (16 oct. :
// estPro vrai, un brochet relâché de rareté 1), avec la configuration par défaut de l'intent (aucun poisson choisi).
// Il doit en sortir au moins un poisson qui nage, avec son image trouvée.

private let jsonSimulateur = """
{"poissons":[{"id":"6F1C2D3E-0000-4000-8000-000000000001","slug":"brochet","rarete":1,"relache":true,"nombre":1}],
 "especes":1,"rations":1,"estPro":true,"misAJour":"2026-10-16T04:55:00Z"}
"""

@MainActor
struct AquariumDepuisJSONTests {
    private func lire() throws -> InstantaneAquarium {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("aquarium-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(jsonSimulateur.utf8).write(to: url)
        let instantane = DepotAquariumWidget.lire(depuis: url)
        try #require(instantane.poissons.count == 1, "le fichier de l'App Group n'est pas lu")
        return instantane
    }

    @Test func configurationParDefautGardeLesPoissons() throws {
        var instantane = try lire()
        // Comme FournisseurAquarium.instantane : ChoixAquariumIntent() sans poisson choisi.
        let choisis = ChoixAquariumIntent().poissons?.map(\.id)
        for famille in [WidgetFamily.systemSmall, .systemMedium, .systemLarge, .systemExtraLargePortrait] {
            instantane.poissons = try lire().retenus(choisis: choisis, limite: limitePoissons(famille))
            #expect(instantane.poissons.map(\.slug) == ["brochet"], "famille \(famille)")
            let places = NageWidget.placements(instantane.poissons, a: .now, dernierRepas: nil,
                                               limite: limitePoissons(famille), colonnes: famille == .systemSmall ? 1 : 2)
            #expect(places.count == 1, "famille \(famille)")
        }
    }

    @Test func imageDuPoissonTrouvee() throws {
        let instantane = try lire()
        for poisson in instantane.poissons {
            #expect(PoissonVivant.imageDisponible(poisson.slug), "image « \(poisson.slug) » absente du catalogue")
        }
    }

    @Test func policesDeMasqueChargees() {
        #expect(PolicesMasque.disponibles, "polices de masque absentes (UIAppFonts) : le widget restera figé")
    }

    /// Rendu animé (pas le repli) : au moins un pixel du poisson doit être opaque à l'instant du rendu.
    @Test func renduAnimeMontreLePoisson() throws {
        let instantane = try lire()
        let entree = EntreeAquarium(date: .now, instantane: instantane)
        let vue = VueAquariumWidget(entree: entree, famille: .systemMedium, fondVisible: false, anime: true)
            .frame(width: 364, height: 170)
        let rendu = ImageRenderer(content: vue)
        rendu.scale = 1
        let image = try #require(rendu.cgImage)
        // Fond transparent (fondVisible: false) : tout pixel opaque vient des poissons ou du bouton.
        let largeur = image.width, hauteur = image.height
        var octets = [UInt8](repeating: 0, count: largeur * hauteur * 4)
        let contexte = try #require(CGContext(data: &octets, width: largeur, height: hauteur, bitsPerComponent: 8,
                                             bytesPerRow: largeur * 4, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        contexte.draw(image, in: CGRect(x: 0, y: 0, width: largeur, height: hauteur))
        // Zone haute du widget (le bouton nourrir est en bas à droite).
        var opaques = 0
        for y in 0..<(hauteur * 2 / 3) { for x in 0..<largeur where octets[(y * largeur + x) * 4 + 3] > 200 { opaques += 1 } }
        #expect(opaques > 200, "aucun poisson dessiné dans le rendu animé (\(opaques) pixels opaques)")
    }
}
#endif
