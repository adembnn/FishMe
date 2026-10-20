import Core
import SwiftUI
import UIKit

// Les images des skins : le fond (`fond-<skin>-<petit|moyen|grand>`), les petits objets, et le repli sur le fond
// déjà dans l'app (`fond-<format>`) quand l'image d'un skin n'existe pas. Quand elle manque mais que le décor est DESSINÉ
// en code (`FondWidget.decorsDessines`), l'app dessine le décor sur le fond d'origine. Rien ici ne lit d'endroit ni de collection.

enum FondSkin {
    /// Mémoire des réponses « cette image existe » : la vue de l'aquarium la lit à chaque image de l'animation.
    // ⚠ à vérifier : variable statique modifiable, isolée au fil principal par SWIFT_DEFAULT_ACTOR_ISOLATION (Swift 6).
    private static var existence: [String: Bool] = [:]

    static func existe(_ nom: String) -> Bool {
        if let connu = existence[nom] { return connu }
        let trouve = UIImage(named: nom) != nil
        existence[nom] = trouve
        return trouve
    }

    /// D'où vient le fond d'un skin : l'illustration du skin, le décor dessiné en code (`WidgetAquarium/DecorsDessines*.swift`,
    /// partagé avec le widget), ou le fond d'avant les skins. La règle est celle de Core (`sourceFond`).
    static func source(_ skin: IdentifiantSkin, format: FormatFond) -> SourceFond {
        sourceFond(CatalogueSkins.skin(skin), format: format, imageExiste: { existe($0) },
                   fondDessine: { FondWidget.aUnDessin($0.valeur) })
    }

    /// Le nom de l'image à dessiner : celle du skin si elle existe, sinon le fond d'avant les skins (sous le décor dessiné).
    static func nomImage(_ skin: IdentifiantSkin, format: FormatFond) -> String {
        switch source(skin, format: format) {
        case .image(let nom), .repli(let nom): return nom
        case .dessine: return Skin.nomImageRepli(format)
        }
    }

    /// L'identifiant du décor à dessiner en code, ou `nil` (illustration présente, fond d'origine, Noël, Été…).
    static func dessin(_ skin: IdentifiantSkin) -> String? {
        source(skin, format: .grand) == .dessine ? skin.valeur : nil
    }

    /// Un skin se montre dans la galerie dès qu'il a un fond : illustration ou dessin (le décor de départ toujours).
    /// Noël et Été n'ont ni l'un ni l'autre pour l'instant : la galerie les masque.
    static func imagesPretes(_ skin: Skin) -> Bool {
        skinAffichable(skin, imageExiste: { existe($0) }, fondDessine: { FondWidget.aUnDessin($0.valeur) })
    }
}

/// Le fond d'un skin en entier (illustration, ou fond d'origine + décor dessiné, ou fond d'origine), sans mouvement :
/// pour les vignettes de la galerie. Prend toute la place proposée.
struct FondSkinVue: View {
    let skin: IdentifiantSkin
    let format: FormatFond

    var body: some View {
        if let id = FondSkin.dessin(skin) {
            FondDecorFige(skin: id, nomFond: FondSkin.nomImage(skin, format: format))
        } else {
            Color.clear
                .overlay { Image(FondSkin.nomImage(skin, format: format)).resizable().scaledToFill() }
                .clipped()
        }
    }
}

/// Teinte d'éclairage et petits objets du skin, posés par-dessus le fond et sous les poissons.
/// Immobile : le skin ne touche ni à la nage ni aux effets d'eau.
struct CoucheSkin: View {
    let skin: IdentifiantSkin
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    var body: some View {
        if let id = FondSkin.dessin(skin) {
            // Décor dessiné en code : sa propre lumière, son sol, ses plantes. « Réduire les animations » : une image fixe.
            CoucheDecor(skin: id, anime: !reduireAnimations).equatable()
        } else if let connu = CatalogueSkins.skin(skin) {
            ZStack(alignment: .bottom) {
                if let t = connu.teinte {
                    Color(red: t.rouge, green: t.vert, blue: t.bleu).opacity(t.opacite)
                }
                let objets = connu.objets.filter { FondSkin.existe($0) }
                if !objets.isEmpty {
                    HStack(alignment: .bottom, spacing: Espace.xl) {
                        ForEach(objets, id: \.self) { nom in
                            Image(nom)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 96)
                        }
                    }
                    .padding(.bottom, Espace.xxl)
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Le décor dessiné en code devant les poissons (herbes sur les bords, poussières proches, bulles). Rien pour les autres skins.
struct CoucheSkinAvant: View {
    let skin: IdentifiantSkin
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    var body: some View {
        if let id = FondSkin.dessin(skin) {
            CoucheDecorAvant(skin: id, anime: !reduireAnimations).equatable()
        }
    }
}
