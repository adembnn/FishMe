// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
import SwiftUI

/// Les cinq directions graphiques en concurrence. La direction N'EST PAS CHOISIE :
/// tout passe par des jetons (`Theme`), jamais de couleur ou de forme en dur dans les vues.
/// Pour changer de direction : modifier `ThemeKind.current`, rien d'autre.
enum ThemeKind: String, CaseIterable, Identifiable {
    case carnetDeTerrain   // A
    case applePur          // B
    case nuitSurLEau       // C
    case pop               // D
    case ecusson           // E

    var id: String { rawValue }

    /// Direction active (⚠ provisoire, en attente du choix de l'équipe).
    static let current: ThemeKind = .applePur

    var letter: String {
        switch self {
        case .carnetDeTerrain: return "A"
        case .applePur: return "B"
        case .nuitSurLEau: return "C"
        case .pop: return "D"
        case .ecusson: return "E"
        }
    }

    var title: String {
        switch self {
        case .carnetDeTerrain: return "Carnet de terrain"
        case .applePur: return "Apple pur"
        case .nuitSurLEau: return "Nuit sur l'eau"
        case .pop: return "Pop"
        case .ecusson: return "Écusson"
        }
    }

    var theme: Theme {
        switch self {
        case .carnetDeTerrain:
            return Theme(background: Color(hex: 0xF3ECDC), surface: Color(hex: 0xFBF7EC), textPrimary: Color(hex: 0x2B2A24),
                         textSecondary: Color(hex: 0x6B6757), accent: Color(hex: 0x3F6B4F), cornerRadius: 10,
                         fontDesign: .serif, forcedScheme: .light)
        case .applePur:
            return Theme(background: Color(.systemBackground), surface: Color(.secondarySystemBackground),
                         textPrimary: Color.primary, textSecondary: Color.secondary, accent: Color.accentColor,
                         cornerRadius: 20, fontDesign: .default, forcedScheme: nil)
        case .nuitSurLEau:
            return Theme(background: Color(hex: 0x0B1620), surface: Color(hex: 0x14283A), textPrimary: Color(hex: 0xE8F1F7),
                         textSecondary: Color(hex: 0x8FA7B8), accent: Color(hex: 0x5CC8D7), cornerRadius: 18,
                         fontDesign: .rounded, forcedScheme: .dark)
        case .pop:
            return Theme(background: Color(hex: 0xFFF4D6), surface: Color(hex: 0xFFFFFF), textPrimary: Color(hex: 0x1B1B1B),
                         textSecondary: Color(hex: 0x5A5A5A), accent: Color(hex: 0xFF4D6D), cornerRadius: 24,
                         fontDesign: .rounded, forcedScheme: .light)
        case .ecusson:
            return Theme(background: Color(hex: 0xEDE6D6), surface: Color(hex: 0xF8F3E6), textPrimary: Color(hex: 0x1F2A44),
                         textSecondary: Color(hex: 0x58607A), accent: Color(hex: 0x8C1D2B), cornerRadius: 6,
                         fontDesign: .serif, forcedScheme: .light)
        }
    }
}

/// Jetons de design. Le Liquid Glass reste réservé aux barres, boutons et feuilles (règle C11) :
/// il n'est donc PAS un jeton ici, il vient des composants système.
struct Theme {
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color
    let cornerRadius: CGFloat
    let fontDesign: Font.Design
    /// nil = suit le réglage du système.
    let forcedScheme: ColorScheme?

    static var current: Theme { ThemeKind.current.theme }
}

extension Color {
    /// Couleur depuis un entier RVB, ex. `Color(hex: 0x3F6B4F)`.
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

#Preview("Directions A à E") {
    VStack(spacing: 12) {
        ForEach(ThemeKind.allCases) { kind in
            let t = kind.theme
            Text("\(kind.letter). \(kind.title)")
                .font(.headline.weight(.semibold))
                .fontDesign(t.fontDesign)
                .foregroundStyle(t.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(t.surface, in: RoundedRectangle(cornerRadius: t.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: t.cornerRadius).stroke(t.accent, lineWidth: 2))
        }
    }
    .padding()
}
