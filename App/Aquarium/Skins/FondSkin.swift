import Core
import SwiftUI
import UIKit

// Les images des skins : le fond (`fond-<skin>-<petit|moyen|grand>`), les petits objets, et le repli sur le fond
// déjà dans l'app (`fond-<format>`) quand l'image d'un skin n'existe pas. Rien ici ne lit d'endroit ni de collection.

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

    /// Le nom de l'image à dessiner : celle du skin si elle existe, sinon le fond d'avant les skins.
    static func nomImage(_ skin: IdentifiantSkin, format: FormatFond) -> String {
        let repli = Skin.nomImageRepli(format)
        guard let connu = CatalogueSkins.skin(skin) else { return repli }
        let nom = connu.nomImageFond(format)
        return existe(nom) ? nom : repli
    }

    /// Un skin se montre dans la galerie seulement si son image existe (le décor de départ toujours).
    static func imagesPretes(_ skin: Skin) -> Bool {
        skin.id == .parDefaut || existe(skin.nomImageFond(.grand))
    }
}

/// Teinte d'éclairage et petits objets du skin, posés par-dessus le fond et sous les poissons.
/// Immobile : le skin ne touche ni à la nage ni aux effets d'eau.
struct CoucheSkin: View {
    let skin: IdentifiantSkin

    var body: some View {
        if let connu = CatalogueSkins.skin(skin) {
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
