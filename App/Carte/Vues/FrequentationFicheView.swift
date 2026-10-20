import SwiftUI
import Core

/// Le niveau de fréquentation d'un tronçon (`NiveauFrequentation` de Core), en mots (docs/frequentation.md, règle 6).
/// Jamais un nombre de pêcheurs écrit à l'écran. Le compteur de `Core` le fournit ; sans niveau, la fiche reçoit `nil`.
extension NiveauFrequentation {
    var symbole: String {
        switch self {
        case .calme: return "leaf.fill"
        case .normal: return "person.2.fill"
        case .charge: return "person.3.fill"
        }
    }
}

/// L'état de la pastille de fréquentation d'un coin : 1, 2 ou 3 silhouettes de pêcheur (la forme porte l'information, jamais la couleur
/// seule), ou une pastille neutre quand le niveau est inconnu (moins de 5 pêcheurs sur le tronçon, ou pas de réseau).
nonisolated enum EtatPastille: Sendable, Equatable, CaseIterable {
    case calme, moyen, frequente, inconnu

    static func pour(_ niveau: NiveauFrequentation?) -> EtatPastille {
        switch niveau {
        case .calme: return .calme
        case .normal: return .moyen
        case .charge: return .frequente
        case nil: return .inconnu
        }
    }

    /// Le nombre de silhouettes dessinées (0 pour inconnu).
    var silhouettes: Int {
        switch self {
        case .calme: return 1
        case .moyen: return 2
        case .frequente: return 3
        case .inconnu: return 0
        }
    }

    /// Le libellé complet lu par VoiceOver : il n'est jamais écrit à l'écran (aucune phrase).
    var libelle: String {
        switch self {
        case .calme: return "Fréquentation calme"
        case .moyen: return "Fréquentation moyenne"
        case .frequente: return "Fréquentation forte"
        case .inconnu: return "Fréquentation inconnue"
        }
    }
}

extension EtatPastille {
    /// Le fond du carré : gris (calme), ambre (moyen), bleu nuit (fréquenté). Ni rouge ni vert.
    var couleur: Color {
        switch self {
        case .calme: return CouleursCarte.frequentationCalme
        case .moyen: return CouleursCarte.frequentationMoyenne
        case .frequente: return CouleursCarte.frequentationForte
        case .inconnu: return Palette.silhouette
        }
    }
}

/// Une silhouette de pêcheur (tête + épaules) centrée en `centreX` dans une grille de 44 × 44, à l'échelle `echelle`.
/// Reprend le dessin de la planche (proposition C) : tête r = 3,3 à y = 18,5 ; épaules = demi-disque de rayon 5 posé sur y = 31.
struct SilhouettePecheur: Shape {
    let centreX: CGFloat
    let echelle: CGFloat

    func path(in rect: CGRect) -> Path {
        let u = rect.width / 44
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * u, y: rect.minY + y * u) }
        var chemin = Path()
        let rt = 3.3 * echelle
        let coin = pt(centreX - rt, 18.5 - rt)
        chemin.addEllipse(in: CGRect(x: coin.x, y: coin.y, width: 2 * rt * u, height: 2 * rt * u))
        let r = 5 * echelle
        let k = 0.5523 * r
        chemin.move(to: pt(centreX - r, 31))
        chemin.addCurve(to: pt(centreX, 31 - r), control1: pt(centreX - r, 31 - k), control2: pt(centreX - k, 31 - r))
        chemin.addCurve(to: pt(centreX + r, 31), control1: pt(centreX + k, 31 - r), control2: pt(centreX + r, 31 - k))
        chemin.closeSubpath()
        return chemin
    }
}

/// La pastille de fréquentation, à gauche du nom du coin : un carré arrondi avec 1, 2 ou 3 silhouettes de pêcheur, aucun mot.
/// Gratuite pour tous (docs/frequentation.md). Rien n'est interdit par cette couleur : c'est une information, pas une règle.
/// ⚠ à vérifier sur Mac : rendu clair/sombre, AX5 (la taille suit le Dynamic Type, bornée à 44 pt).
struct PastilleFrequentationView: View {
    let niveau: NiveauFrequentation?
    @ScaledMetric(relativeTo: .body) private var cote: CGFloat = 32

    var body: some View {
        let etat = EtatPastille.pour(niveau)
        let taille = min(cote, Gabarit.zoneTactile)
        ZStack {
            RoundedRectangle(cornerRadius: 11.0 / 44 * taille, style: .continuous)
                .fill(etat.couleur)
            if etat == .inconnu {
                Image(systemName: "questionmark")
                    .font(Police.taille(taille * 0.4, .heavy))
                    .foregroundStyle(Palette.surMarine)
            } else {
                ForEach(Array(Self.placement(etat.silhouettes).enumerated()), id: \.offset) { _, p in
                    SilhouettePecheur(centreX: p.x, echelle: p.echelle).fill(Palette.surMarine)
                }
            }
        }
        .frame(width: taille, height: taille)
        .accessibilityElement()
        .accessibilityLabel(etat.libelle)
    }

    /// Positions (x dans la grille de 44) et échelles de la planche : 1 grande, 2 moyennes, 3 petites.
    static func placement(_ n: Int) -> [(x: CGFloat, echelle: CGFloat)] {
        switch n {
        case 1: return [(22, 1.1)]
        case 2: return [(16.5, 0.95), (27.5, 0.95)]
        case 3: return [(12.5, 0.8), (22, 0.8), (31.5, 0.8)]
        default: return []
        }
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
