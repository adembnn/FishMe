import SwiftUI

/// « Commencer une session » en Liquid Glass teinté marine, avec l'icône play. Grisé (et dit comme tel) tant qu'aucun spot n'est posé.
struct BoutonCommencerVerre: View {
    let actif: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Commencer une session", systemImage: "play.fill")
                .font(Police.corps)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Espace.s)
                .frame(minHeight: Gabarit.zoneTactile)
        }
        .buttonStyle(.glassProminent)
        .tint(Palette.marine.opacity(0.5))
        .controlSize(.large)
        .frame(maxWidth: 300)
        .disabled(!actif)
        .accessibilityHint(actif ? "" : "Pose d'abord ton spot en touchant la carte")
    }
}

/// Un bouton de la colonne de droite : l'icône ET son libellé écrit dessous (une icône seule ne se comprend pas, retour des testeurs).
/// 44 pt au moins dans les deux sens ; le libellé suit la taille du texte (jusqu'à AX5) et passe sur deux lignes au besoin.
struct BoutonLibelleCarte: View {
    let symbole: String
    let libelle: String
    var teinte: Color = Palette.encre
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbole)
                    .font(Police.taille(18))
                    .foregroundStyle(teinte)
                    .frame(height: 22)
                    .accessibilityHidden(true)
                Text(libelle)
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .frame(minWidth: 64, minHeight: Gabarit.zoneTactile + 12)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }
}

/// La colonne de 4 boutons en verre, à droite au-dessus de la barre d'onglets, chacun avec son libellé :
/// météo, ma position (recentre la caméra sans déplacer le spot), filtre par espèce, réglages.
struct ColonneBoutonsCarte: View {
    let teinteFiltre: Color
    let meteo: () -> Void
    let autourDeMoi: () -> Void
    let filtre: () -> Void
    let reglages: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 8) {
                BoutonLibelleCarte(symbole: "cloud.sun", libelle: "Météo", action: meteo)
                BoutonLibelleCarte(symbole: "location.fill", libelle: "Ma position", teinte: Palette.marine, action: autourDeMoi)
                BoutonLibelleCarte(symbole: "line.3.horizontal.decrease", libelle: "Espèces", teinte: teinteFiltre, action: filtre)
                BoutonLibelleCarte(symbole: "gearshape", libelle: "Réglages", action: reglages)
            }
        }
    }
}
