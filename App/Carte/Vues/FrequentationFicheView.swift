import SwiftUI
import Core

/// Le niveau de fréquentation d'un tronçon (`NiveauFrequentation` de Core), en mots (docs/frequentation.md, règle 6).
/// Jamais un nombre de pêcheurs. Le compteur de `Core` le fournit ; sans niveau, la fiche reçoit `nil` et n'affiche rien.
extension NiveauFrequentation {
    var symbole: String {
        switch self {
        case .calme: return "leaf.fill"
        case .normal: return "person.2.fill"
        case .charge: return "person.3.fill"
        }
    }
}

/// La couleur de la pastille de fréquentation d'un coin : verte (calme), orange (normal), rouge (chargé), grise (niveau inconnu :
/// moins de 5 pêcheurs sur le tronçon, ou pas de réseau). La forme du symbole change aussi, pour se lire sans la couleur.
nonisolated enum EtatPastille: Sendable, Equatable, CaseIterable {
    case vert, orange, rouge, gris

    static func pour(_ niveau: NiveauFrequentation?) -> EtatPastille {
        switch niveau {
        case .calme: return .vert
        case .normal: return .orange
        case .charge: return .rouge
        case nil: return .gris
        }
    }

    /// Le mot lu par VoiceOver : il n'est jamais écrit à l'écran (aucune phrase).
    var mot: String {
        switch self {
        case .vert: return "calme"
        case .orange: return "normal"
        case .rouge: return "chargé"
        case .gris: return "inconnue"
        }
    }

    var symbole: String {
        switch self {
        case .vert: return "leaf.fill"
        case .orange: return "person.2.fill"
        case .rouge: return "person.3.fill"
        case .gris: return "questionmark"
        }
    }
}

extension EtatPastille {
    var couleur: Color {
        switch self {
        case .vert: return Palette.ouvert
        case .orange: return Palette.bouchon
        case .rouge: return CouleursCarte.rougeFrequentation
        case .gris: return Palette.encreDouce
        }
    }
}

/// La pastille de fréquentation, à gauche du nom du coin : un rond de couleur avec un petit symbole, aucun mot.
/// Gratuite pour tous (docs/frequentation.md). Rien n'est interdit par cette couleur : c'est une information, pas une règle.
struct PastilleFrequentationView: View {
    let niveau: NiveauFrequentation?

    var body: some View {
        let etat = EtatPastille.pour(niveau)
        Image(systemName: etat.symbole)
            .font(Police.taille(13, .heavy))
            .foregroundStyle(Palette.surMarine)
            .frame(width: 28, height: 28)
            .background(etat.couleur, in: Circle())
            .accessibilityElement()
            .accessibilityLabel("Fréquentation : \(etat.mot)")
    }
}

/// Pour un tronçon chargé, le bouton « Coin plus calme » (rien quand aucun coin plus calme n'existe).
/// La fréquentation elle-même se lit sur la pastille du titre.
struct FrequentationFicheView: View {
    let niveau: NiveauFrequentation
    /// Propose la station éligible la plus proche dont le tronçon n'est pas chargé ; `nil` : pas de bouton.
    let onCoinCalme: (() -> Void)?

    var body: some View {
        if niveau == .charge, let onCoinCalme {
            Button(action: onCoinCalme) {
                Label("Coin plus calme", systemImage: "leaf.fill")
            }
            .buttonStyle(.secondaire)
            .accessibilityHint("Propose un coin moins fréquenté sur la même rivière")
        }
    }
}

/// Q7 : la réserve listée sur le cours d'eau, en tête des règles, avec sa citation. Le mot « interdit » n'y figure
/// que si la citation de l'arrêté le dit : on affiche la citation telle quelle, rien d'ajouté.
struct ReserveEnTeteView: View {
    let lignes: [LigneControle]

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            HStack(spacing: Espace.s) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Police.taille(17, .heavy))
                    .accessibilityHidden(true)
                Text("Réserve listée sur ce cours d’eau")
                    .font(Police.taille(17, .heavy))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Palette.alerte)
            .accessibilityAddTraits(.isHeader)
            ForEach(Array(lignes.enumerated()), id: \.offset) { _, ligne in
                VStack(alignment: .leading, spacing: 6) {
                    Text(ligne.phrase)
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                        .fixedSize(horizontal: false, vertical: true)
                    SourceCitationView(ligne: ligne)
                }
            }
        }
        .padding(Espace.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.alerteDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
    }
}
