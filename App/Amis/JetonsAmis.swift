import Core
import SwiftUI

/// Jetons propres au dossier Amis (palette « Marine », SF Pro Rounded gras). Un dossier de l'app n'importe que Core et lui-même :
/// quand `App/Style/Style.swift` (lot D0) sera dans `mac/integration`, A remplace ces valeurs par `Palette.*` sans toucher aux écrans.
enum JetonAmis {
    static let encre = Color(red: 0x0E / 255, green: 0x1A / 255, blue: 0x26 / 255)
    static let encreDouce = Color(red: 0x56 / 255, green: 0x65 / 255, blue: 0x76 / 255)
    /// Marine #0D4A85 : boutons et liens.
    static let bleu = Color(red: 0x0D / 255, green: 0x4A / 255, blue: 0x85 / 255)
    static let fondPage = Color(red: 0xF2 / 255, green: 0xF5 / 255, blue: 0xF9 / 255)
    static let papier = Color.white
    static let ardoise = Color(red: 0x6B / 255, green: 0x77 / 255, blue: 0x80 / 255)
    static let vert = Color(red: 0x23 / 255, green: 0x88 / 255, blue: 0x5A / 255)
    static let violet = Color(red: 0x5B / 255, green: 0x4F / 255, blue: 0xD0 / 255)
    static let or = Color(red: 0xB0 / 255, green: 0x7A / 255, blue: 0x12 / 255)

    static func police(_ taille: CGFloat, _ graisse: Font.Weight = .heavy) -> Font {
        .system(size: taille, weight: graisse, design: .rounded)
    }

    /// Hauteur minimale d'une zone touchable.
    static let zoneTactile: CGFloat = 44
    static let rapportCarte: CGFloat = 5.0 / 7.0

    // MARK: Aides sans interface (Foundation seulement)

    /// « La Marne · 94 » : le département est ce qui suit le dernier point médian. Jamais un point exact.
    nonisolated static func departement(depuisLieuFlou lieu: String?) -> Departement? {
        guard let lieu, lieu.contains("·"), let reste = lieu.split(separator: "·").last else { return nil }
        let code = reste.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty, code.count <= 3 else { return nil }
        return Departement(code: code)
    }

    /// Même règle que le compteur du Pescedex (L4) : au moins une pêche OFB, ni légendaire ni non mesurée.
    nonisolated static func estReleveeDansLaZone(_ r: ResultatRarete) -> Bool {
        r.nPeches > 0 && r.niveau != .legendaire && r.niveau != .nonMesuree
    }

    nonisolated static func date(_ d: Date) -> String {
        d.formatted(.dateTime.day().month(.abbreviated).year().locale(Locale(identifier: "fr_FR")))
    }
}

/// La rareté d'une carte d'ami : le mot, le rang (1 à 4 points) et la forme disent le niveau sans la couleur.
enum RareteAmi: Equatable {
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
        case .commun, .nonMesuree: return JetonAmis.ardoise
        case .peuCommun: return JetonAmis.vert
        case .rare: return JetonAmis.violet
        case .legendaire: return JetonAmis.or
        }
    }

    var fond: [Color] {
        [couleur.opacity(0.12), couleur.opacity(0.35)]
    }
}

struct BadgeRareteAmi: View {
    let style: RareteAmi
    var taille: CGFloat = 24

    var body: some View {
        if style != .nonMesuree {
            ZStack {
                Circle().fill(style.couleur)
                Text("\(style.rang)")
                    .font(JetonAmis.police(taille * 0.5))
                    .foregroundStyle(.white)
            }
            .frame(width: taille, height: taille)
            .accessibilityHidden(true)
        }
    }
}
