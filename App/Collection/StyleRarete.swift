import Core
import SwiftUI

/// Un polygone dessiné dans le carré unité (forme du badge de rareté).
nonisolated struct Polygone: Shape {
    let points: [CGPoint]

    func path(in rect: CGRect) -> Path {
        var chemin = Path()
        guard let premier = points.first else { return chemin }
        chemin.move(to: CGPoint(x: rect.minX + premier.x * rect.width, y: rect.minY + premier.y * rect.height))
        for p in points.dropFirst() {
            chemin.addLine(to: CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height))
        }
        chemin.closeSubpath()
        return chemin
    }
}

/// Rareté : la forme du badge, le nombre de points et le mot disent le niveau sans la couleur (lisible en noir et blanc).
enum StyleRarete: Equatable {
    case commun, peuCommun, rare, legendaire, nonMesuree

    init(_ niveau: NiveauRarete) {
        switch niveau {
        case .commun: self = .commun
        case .peuCommun: self = .peuCommun
        case .rare: self = .rare
        case .legendaire: self = .legendaire
        case .nonMesuree: self = .nonMesuree
        }
    }

    var mot: String {
        switch self {
        case .commun: return "commun"
        case .peuCommun: return "peu commun"
        case .rare: return "rare"
        case .legendaire: return "légendaire"
        case .nonMesuree: return "rareté non mesurée"
        }
    }

    /// 1 à 4 points ; 0 pour une espèce que l'OFB ne suit pas.
    var rang: Int {
        switch self {
        case .commun: return 1
        case .peuCommun: return 2
        case .rare: return 3
        case .legendaire: return 4
        case .nonMesuree: return 0
        }
    }

    var couleur: Color {
        switch self {
        case .commun, .nonMesuree: return Palette.commun
        case .peuCommun: return Palette.peuCommun
        case .rare: return Palette.rare
        case .legendaire: return Palette.legendaire
        }
    }

    /// Fond de l'illustration : de plus en plus sombre avec la rareté.
    var fond: [Color] {
        switch self {
        case .commun, .nonMesuree:
            return [Palette.tuile, Palette.eauClaire]
        case .peuCommun:
            return [Palette.ouvertDoux, Palette.peuCommun.opacity(0.45)]
        case .rare:
            return [Palette.rare.opacity(0.25), Palette.rare.opacity(0.7)]
        case .legendaire:
            return [Palette.legendaire.opacity(0.55), Palette.nuit]
        }
    }

    /// Nombre de filets du cadre : 1, 1, 2, 3.
    var filets: Int {
        switch self {
        case .commun, .nonMesuree, .peuCommun: return 1
        case .rare: return 2
        case .legendaire: return 3
        }
    }

    /// Reflet holographique : rares et légendaires seulement.
    var aUnReflet: Bool { self == .rare || self == .legendaire }

    /// Hexagone, losange, étoile ; `nil` : rond.
    var forme: Polygone? {
        switch self {
        case .commun, .nonMesuree:
            return nil
        case .peuCommun:
            return Polygone(points: [CGPoint(x: 0.25, y: 0.05), CGPoint(x: 0.75, y: 0.05), CGPoint(x: 1, y: 0.5),
                                     CGPoint(x: 0.75, y: 0.95), CGPoint(x: 0.25, y: 0.95), CGPoint(x: 0, y: 0.5)])
        case .rare:
            return Polygone(points: [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)])
        case .legendaire:
            return Polygone(points: [CGPoint(x: 0.5, y: 0), CGPoint(x: 0.62, y: 0.36), CGPoint(x: 1, y: 0.38),
                                     CGPoint(x: 0.7, y: 0.6), CGPoint(x: 0.8, y: 0.98), CGPoint(x: 0.5, y: 0.76),
                                     CGPoint(x: 0.2, y: 0.98), CGPoint(x: 0.3, y: 0.6), CGPoint(x: 0, y: 0.38),
                                     CGPoint(x: 0.38, y: 0.36)])
        }
    }
}

struct BadgeRarete: View {
    let style: StyleRarete
    var taille: CGFloat = 46

    var body: some View {
        Group {
            if style != .nonMesuree {
                ZStack {
                    if let forme = style.forme {
                        forme.fill(style.couleur)
                    } else {
                        Circle().fill(style.couleur)
                    }
                    if style != .legendaire {
                        Text("\(style.rang)")
                            .font(Police.taille(taille * 0.46, .heavy))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: taille, height: taille)
            }
        }
        .accessibilityHidden(true)
    }
}

/// 1 à 4 points, pleins jusqu'au rang.
struct PointsRarete: View {
    let style: StyleRarete
    var taille: CGFloat = 12

    var body: some View {
        HStack(spacing: taille * 0.4) {
            ForEach(1...4, id: \.self) { i in
                Circle()
                    .strokeBorder(style.couleur, lineWidth: 2)
                    .background(Circle().fill(i <= style.rang ? style.couleur : Color.clear))
                    .frame(width: taille, height: taille)
            }
        }
        .accessibilityHidden(true)
    }
}
