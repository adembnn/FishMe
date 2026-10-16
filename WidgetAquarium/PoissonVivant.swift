import SwiftUI
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

// Widget + app. Un poisson qui nage en continu : la planche (fond transparent, regarde vers la DROITE) est coupée
// en deux par des masques. Le corps (65 % avant) reste en place avec un très léger roulis ; la queue (35 % arrière)
// pivote autour de la jonction. Le halo de rareté n'est PAS ici : il se dessine une fois, derrière.
struct PoissonVivant: View {
    let slug: String
    let largeur: CGFloat
    let versLaDroite: Bool
    let phase: Int
    let anime: Bool

    init(slug: String, largeur: CGFloat, versLaDroite: Bool, phase: Int, anime: Bool) {
        self.slug = slug
        self.largeur = largeur
        self.versLaDroite = versLaDroite
        self.phase = phase
        self.anime = anime
    }

    /// Part avant de la planche qui reste rigide.
    private static let partCorps: CGFloat = 0.65
    /// Recouvrement des deux morceaux à la jonction, en points (évite une fente).
    private static let recouvrement: CGFloat = 2
    private static let angleQueue = 14.0

    /// L'image de l'espèce existe-t-elle dans le catalogue de cette cible ? Sinon, une silhouette générique :
    /// jamais un poisson invisible (slug inconnu, catalogue absent de la cible).
    static func imageDisponible(_ slug: String) -> Bool { UIImage(named: slug) != nil }

    private var planche: some View {
        let base = (Self.imageDisponible(slug) ? Image(slug) : Image(systemName: "fish.fill"))
            .resizable()
        #if canImport(WidgetKit)
            .widgetAccentedRenderingMode(.desaturated)
        #endif
        return base
            .scaledToFit()
            .foregroundStyle(.white.opacity(0.85))
            .frame(width: largeur)
    }

    var body: some View {
        Group {
            if anime {
                ImagesAnimees { k in
                    image(numero: k)
                }
            } else {
                planche
            }
        }
        .scaleEffect(x: versLaDroite ? 1 : -1, y: 1)
    }

    /// L'image n° k de la boucle de 16 images (2 s).
    private func image(numero k: Int) -> some View {
        let n = Double(k + phase)
        // 2 battements de queue par boucle ; roulis, tangage et avance-recul : 1 période par boucle.
        let battement = sin(2 * .pi * n / 8)
        let cycle = sin(2 * .pi * n / 16)
        let angle = battement * Self.angleQueue
        let roulis = cycle * 0.8
        let tangage = CGFloat(cos(2 * .pi * n / 16)) * 1.5
        let avance = CGFloat(cycle) * 2
        let coupe = largeur * Self.partCorps

        return ZStack {
            planche
                .mask(alignment: .leading) {
                    Rectangle().frame(width: coupe + Self.recouvrement / 2)
                }
                .rotationEffect(.degrees(roulis))
            planche
                .mask(alignment: .trailing) {
                    Rectangle().frame(width: largeur - coupe + Self.recouvrement / 2)
                }
                .rotationEffect(.degrees(angle), anchor: UnitPoint(x: Self.partCorps, y: 0.5))
        }
        .offset(x: avance, y: tangage)
    }
}
