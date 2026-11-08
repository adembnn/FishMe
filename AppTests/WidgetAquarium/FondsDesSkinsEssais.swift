import Foundation
import Testing
import Core
@testable import BuildChallenge

// App seulement (pas copié dans le paquet Linux de `lancer-tests.sh` : il lit Core et le widget ensemble).
// Garde l'accord entre les skins de l'aquarium de l'app (`CatalogueSkins`) et les fonds que le widget sait dessiner :
// un skin ajouté à l'app sans fond côté widget ferait afficher le fond de la rivière à la place du décor choisi.
@Suite("Chaque skin de l'app a son fond dans le widget")
struct FondsDesSkinsEssais {
    /// Le décor de départ a le fond d'origine ; tous les autres ont un dessin partagé avec l'app (ou une illustration).
    @Test func aucunSkinSansFond() {
        for skin in CatalogueSkins.tous {
            let id = skin.id.valeur
            if id == FondWidget.parDefaut { continue }
            #expect(FondWidget.aUnDessin(id), "le skin \(id) n'a ni illustration ni dessin dans le widget")
            for f in FondWidget.Format.allCases {
                let source = FondWidget.source(skin: id, format: f, existe: { _ in false })
                #expect(source == .dessin(id), "le skin \(id) retombe sur le fond d'origine en \(f.rawValue)")
            }
        }
    }

    /// Le widget ne dessine que des décors qui existent dans l'app.
    @Test func aucunFondSansSkin() {
        let ids = Set(CatalogueSkins.tous.map(\.id.valeur))
        for id in FondWidget.decorsDessines { #expect(ids.contains(id), "décor du widget sans skin dans l'app : \(id)") }
        #expect(ids.contains(FondWidget.parDefaut))
    }

    /// L'identifiant écrit par l'app dans l'App Group est lu tel quel par le widget (aucun skin ne devient « riviere »
    /// à cause d'un identifiant jugé douteux).
    @Test func lIdentifiantDeChaqueSkinEstLuTelQuel() {
        for skin in CatalogueSkins.tous {
            #expect(FondWidget.identifiantSain(skin.id.valeur) == skin.id.valeur)
        }
    }
}
