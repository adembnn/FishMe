import SwiftUI

// Widget + app. Le décor qui bouge, via `ImagesAnimees` (16 images, boucle de 2 s). Sobre : formes simples, sans flou.

/// Une bulle : colonne (0...1 en largeur), décalage de départ (0..<16), taille en points, ondulation.
private struct Bulle {
    let colonne: CGFloat
    let decalage: Int
    let taille: CGFloat
    let ondulation: CGFloat
}

/// 3 colonnes de petites bulles qui montent. L'image k place la bulle à la hauteur 1 − ((k + décalage) mod 16) / 16.
struct BullesAnimees: View {
    private static let bulles: [Bulle] = [
        Bulle(colonne: 0.16, decalage: 0, taille: 5, ondulation: 3),
        Bulle(colonne: 0.16, decalage: 9, taille: 3, ondulation: 2),
        Bulle(colonne: 0.52, decalage: 5, taille: 6, ondulation: 3),
        Bulle(colonne: 0.52, decalage: 13, taille: 4, ondulation: 2),
        Bulle(colonne: 0.84, decalage: 11, taille: 4, ondulation: 3),
        Bulle(colonne: 0.84, decalage: 2, taille: 3, ondulation: 2),
    ]

    var body: some View {
        ImagesAnimees { k in
            GeometryReader { geo in
                ForEach(0..<Self.bulles.count, id: \.self) { i in
                    let b = Self.bulles[i]
                    let progres = CGFloat((k + b.decalage) % 16) / 16
                    let x = geo.size.width * b.colonne
                        + b.ondulation * CGFloat(sin(2 * .pi * Double(k + b.decalage) / 8))
                    Circle()
                        .fill(Color.white.opacity(0.35))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.55), lineWidth: 0.5))
                        .frame(width: b.taille, height: b.taille)
                        .position(x: x, y: geo.size.height * (1 - progres))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// 2 ou 3 rayons doux depuis la surface : leur opacité et leur angle oscillent légèrement sur les 16 images.
struct LumiereAnimee: View {
    private static let rayons: [(x: CGFloat, largeur: CGFloat, dephasage: Double)] = [
        (0.14, 0.10, 0), (0.46, 0.12, 5), (0.78, 0.09, 11),
    ]

    var body: some View {
        ImagesAnimees { k in
            GeometryReader { geo in
                let l = geo.size.width
                let h = geo.size.height
                ForEach(0..<Self.rayons.count, id: \.self) { i in
                    let r = Self.rayons[i]
                    let onde = sin(2 * .pi * (Double(k) + r.dephasage) / 16)
                    // Inclinaison : le pied du rayon se décale de ±3 % de la largeur ; opacité entre 0,06 et 0,14.
                    let derive = l * 0.03 * CGFloat(onde)
                    let x = l * r.x
                    let w = l * r.largeur
                    Path { chemin in
                        chemin.move(to: CGPoint(x: x, y: 0))
                        chemin.addLine(to: CGPoint(x: x + w, y: 0))
                        chemin.addLine(to: CGPoint(x: x + w * 0.2 - l * 0.10 + derive, y: h * 0.85))
                        chemin.addLine(to: CGPoint(x: x - l * 0.14 + derive, y: h * 0.85))
                        chemin.closeSubpath()
                    }
                    .fill(LinearGradient(colors: [.white.opacity(0.10 + 0.04 * onde), .white.opacity(0)],
                                         startPoint: .top, endPoint: .bottom))
                }
            }
        }
        .accessibilityHidden(true)
    }
}
