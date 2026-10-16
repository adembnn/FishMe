import SwiftUI
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

// Widget + app. Les images d'un poisson qui nage : le cycle de battement de queue vu de profil
// (`NagePoissons.xcassets`, `<slug>-nage-0` … `-7` : la queue se raccourcit puis s'élargit, elle bat vers nous
// puis loin de nous ; fabriqué par `fabriquer_cycle_nage.py`). Sans cycle, l'image fixe de l'espèce ;
// sans image du tout, une silhouette blanche : jamais un poisson invisible.
enum PoissonVivant {
    static let imagesCycle = 8

    /// L'image fixe de l'espèce existe-t-elle dans le catalogue de cette cible ?
    static func imageDisponible(_ slug: String) -> Bool { UIImage(named: slug) != nil }

    /// Le cycle de nage de l'espèce existe-t-il ?
    static func cycleDisponible(_ slug: String) -> Bool { UIImage(named: "\(slug)-nage-0") != nil }

    /// Les deux vues trois-quarts en volume (vers le fond, vers nous) existent-elles ?
    static func vuesDisponibles(_ slug: String) -> Bool {
        UIImage(named: "\(slug)-vue-1-0") != nil && UIImage(named: "\(slug)-vue-2-0") != nil
    }
}

/// Une image du poisson : `image` = n° dans le cycle de nage (nil : image fixe). Les planches regardent à DROITE ;
/// `sens` est l'échelle horizontale (−1 : à gauche, entre les deux pendant un demi-tour).
struct ImagePoisson: View {
    let slug: String
    let image: Int?
    let largeur: CGFloat
    let sens: Double
    /// Vue en volume (0 : profil). Une vue trois-quarts est déjà rendue tournée : on ne l'aplatit pas, on la
    /// retourne seulement quand il nage vers la gauche.
    var vue: Int = 0

    var body: some View {
        let nom = image.map { vue > 0 ? "\(slug)-vue-\(vue)-\($0)" : "\(slug)-nage-\($0)" } ?? slug
        let echelleX = vue > 0 && image != nil ? (sens < 0 ? -1.0 : 1.0) : sens
        let base = (image != nil || PoissonVivant.imageDisponible(slug) ? Image(nom) : Image(systemName: "fish.fill"))
            .resizable()
        #if canImport(WidgetKit)
            .widgetAccentedRenderingMode(.desaturated)
        #endif
        return base
            .scaledToFit()
            .foregroundStyle(.white.opacity(0.85))
            .frame(width: largeur)
            .scaleEffect(x: echelleX, y: 1)
    }
}
