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

    /// Images par battement fournies : 16 (rendus en volume, `-nage-0` à `-15`), 8 (anciens), 0 (sans cycle).
    static func imagesDisponibles(_ slug: String) -> Int {
        if UIImage(named: "\(slug)-nage-15") != nil { return 16 }
        return cycleDisponible(slug) ? 8 : 0
    }

    /// Lacets rendus en volume (en degrés, hors profil) : `<slug>-lacet-<a>-<k>` (a = 15, 30… vers le fond ;
    /// m15, m30… vers nous), et les anciennes vues `-vue-1-` (45) et `-vue-2-` (−45).
    static let lacetsPossibles = [-75, -60, -45, -30, -15, 15, 30, 45, 60, 75]

    static func anglesDisponibles(_ slug: String) -> [Int] {
        lacetsPossibles.filter { UIImage(named: nomVue(slug, angle: $0, image: 0)) != nil }
    }

    /// Nom de l'image d'un lacet (0 : le profil `-nage-`).
    static func nomVue(_ slug: String, angle: Int, image: Int) -> String {
        if angle == 0 { return "\(slug)-nage-\(image)" }
        let lacet = "\(slug)-lacet-\(angle < 0 ? "m" : "")\(abs(angle))-\(image)"
        if abs(angle) == 45, UIImage(named: lacet) == nil { return "\(slug)-vue-\(angle > 0 ? 1 : 2)-\(image)" }
        return lacet
    }
}

/// Une image du poisson : `image` = n° dans le cycle de nage (nil : image fixe). Les planches regardent à DROITE ;
/// `sens` est l'échelle horizontale (−1 : à gauche, entre les deux pendant un demi-tour).
struct ImagePoisson: View {
    let slug: String
    let image: Int?
    let largeur: CGFloat
    let sens: Double
    /// Lacet rendu à montrer (0 : profil). Avec des rendus en volume, l'image est déjà tournée : on ne l'aplatit
    /// pas, on la retourne seulement quand il nage vers la gauche.
    var angle: Int = 0
    var volume = false

    var body: some View {
        let nom = image.map { PoissonVivant.nomVue(slug, angle: angle, image: $0) } ?? slug
        let echelleX = volume && image != nil ? (sens < 0 ? -1.0 : 1.0) : sens
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
