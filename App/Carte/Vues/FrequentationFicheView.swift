import SwiftUI
import Core

/// Le niveau de fréquentation d'un tronçon, en mots (docs/frequentation.md, règle 6). Jamais un nombre de pêcheurs.
/// À brancher : le compteur (App/Frequentation, Core `NiveauFrequentation`) le fournit ; tant qu'il n'existe pas,
/// la fiche reçoit `nil` et n'affiche rien (aucune fausse donnée).
nonisolated enum NiveauFrequentationFiche: Sendable, Equatable {
    case calme, normal, charge

    var mot: String {
        switch self {
        case .calme: return "Calme"
        case .normal: return "Normal"
        case .charge: return "Chargé"
        }
    }

    var symbole: String {
        switch self {
        case .calme: return "leaf.fill"
        case .normal: return "person.2.fill"
        case .charge: return "person.3.fill"
        }
    }
}

/// Le badge « Calme / Normal / Chargé » de la fiche, et pour un tronçon chargé le bouton « Coin plus calme ».
/// Gratuit pour tous : aucun cadenas. Pas orange : ce n'est pas une alerte, rien n'est interdit.
struct FrequentationFicheView: View {
    let niveau: NiveauFrequentationFiche
    /// Propose la station éligible la plus proche dont le tronçon n'est pas chargé ; `nil` : pas de bouton.
    let onCoinCalme: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            badge
            if niveau == .charge, let onCoinCalme {
                Button(action: onCoinCalme) {
                    Label("Coin plus calme", systemImage: "leaf.fill")
                }
                .buttonStyle(.secondaire)
                .accessibilityHint("Propose un coin moins fréquenté sur la même rivière")
            }
        }
    }

    private var badge: some View {
        HStack(spacing: Espace.s) {
            Image(systemName: niveau.symbole)
                .font(Police.taille(13, .heavy))
                .accessibilityHidden(true)
            Text(niveau.mot)
                .font(Police.taille(15, .heavy))
        }
        .foregroundStyle(Palette.marine)
        .padding(.horizontal, 14)
        .frame(minHeight: 34)
        .background(Palette.marineDoux, in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fréquentation : \(niveau.mot)")
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
