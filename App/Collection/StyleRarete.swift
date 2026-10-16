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

    /// Fond de la fenêtre du poisson (P24, `fishme-ds.css` : `.fc`, `.fc.pc`, `.fc.r`, `.fc.l`) : mat et sombre pour le commun
    /// et le peu commun, argent pour le rare, or pour le légendaire. Deux couleurs, de haut en bas (une seule répétée si le fond est uni).
    var fond: [Color] {
        switch self {
        case .commun, .nonMesuree:
            return [Color(carte: 0x5F7775), Color(carte: 0x5F7775)]
        case .peuCommun:
            return [Color(carte: 0x17403F), Color(carte: 0x17403F)]
        case .rare:
            return [Color(carte: 0xDCE3E8), Color(carte: 0x8497A3)]
        case .legendaire:
            return [Color(carte: 0xE3B654), Color(carte: 0xB8862A)]
        }
    }

    /// Fond de la plaque du bas (`--fpl`) : gris très clair, crème pour le légendaire.
    var plaque: Color {
        self == .legendaire ? Color(carte: 0xF4E6BF) : Color(carte: 0xE9EDEB)
    }

    /// Couleur du centile en haut de la carte (`--fcen`) : blanc sur les fonds sombres, encre sur l'argent et l'or.
    var couleurCentile: Color {
        switch self {
        case .commun, .nonMesuree, .peuCommun: return .white
        case .rare: return Color(carte: 0x0F1A1C)
        case .legendaire: return Color(carte: 0x1A1408)
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

extension Color {
    /// Une couleur fixe lue en hexadécimal (0xRRGGBB) : les cartes ne suivent pas le mode sombre.
    init(carte hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

/// La marque de palier de la maquette (P24, `.rkm` et `.rk svg`) : rond, hexagone, losange ou étoile, dessinés dans une boîte de 16.
/// Une forme et un mot disent le palier ; la couleur seule ne suffit jamais.
struct MarqueRarete: View {
    let style: StyleRarete
    var taille: CGFloat = 16

    var body: some View {
        Group {
            switch style {
            case .commun, .nonMesuree:
                Circle().fill(style.couleur).frame(width: taille * 12 / 16, height: taille * 12 / 16)
            case .peuCommun:
                Self.forme([(8, 1.5), (13.6, 4.75), (13.6, 11.25), (8, 14.5), (2.4, 11.25), (2.4, 4.75)]).fill(style.couleur)
            case .rare:
                Self.forme([(8, 1), (15, 8), (8, 15), (1, 8)]).fill(style.couleur)
            case .legendaire:
                Self.forme([(8, 1), (10.1, 5.4), (15, 6), (11.4, 9.4), (12.3, 14.2), (8, 11.9), (3.7, 14.2), (4.6, 9.4), (1, 6), (5.9, 5.4)])
                    .fill(style.couleur)
            }
        }
        .frame(width: taille, height: taille)
        .accessibilityHidden(true)
    }

    private static func forme(_ points: [(CGFloat, CGFloat)]) -> Polygone {
        Polygone(points: points.map { CGPoint(x: $0.0 / 16, y: $0.1 / 16) })
    }
}
