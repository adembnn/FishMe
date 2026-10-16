import Core
import SwiftUI

/// Jetons propres au dossier Amis (palette « Marine », SF Pro Rounded gras). Un dossier de l'app n'importe que Core et lui-même :
/// ces jetons pointent vers `Palette`, `Police` et `Gabarit` de `App/Style/Style.swift`.
enum JetonAmis {
    static let encre = Palette.encre
    static let encreDouce = Palette.encreDouce
    /// Marine : boutons et liens.
    static let bleu = Palette.marine
    static let fondPage = Palette.fond
    static let papier = Palette.surface
    static let ardoise = Palette.commun
    static let vert = Palette.peuCommun
    static let violet = Palette.rare
    static let or = Palette.legendaire

    static func police(_ taille: CGFloat, _ graisse: Font.Weight = .heavy) -> Font {
        Police.taille(taille, graisse)
    }

    /// Hauteur minimale d'une zone touchable.
    static let zoneTactile: CGFloat = Gabarit.zoneTactile
    static let rapportCarte: CGFloat = Gabarit.rapportCarte

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
