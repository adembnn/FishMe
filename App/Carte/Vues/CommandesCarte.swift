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
        .tint(Palette.marine)
        .controlSize(.large)
        .disabled(!actif)
        .accessibilityHint(actif ? "" : "Pose d'abord ton spot en touchant la carte")
    }
}

/// La colonne de 4 petits boutons ronds en verre, à droite au-dessus de la barre d'onglets :
/// météo, autour de moi, filtre par espèce, réglages.
struct ColonneBoutonsCarte: View {
    let teinteFiltre: Color
    let meteo: () -> Void
    let autourDeMoi: () -> Void
    let filtre: () -> Void
    let reglages: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            VStack(spacing: 8) {
                BoutonVerreCarte(symbole: "cloud.sun", libelle: "Météo, tes conditions", action: meteo)
                BoutonVerreCarte(symbole: "location.fill", libelle: "Autour de moi", teinte: Palette.marine, action: autourDeMoi)
                BoutonVerreCarte(symbole: "line.3.horizontal.decrease", libelle: "Filtrer par espèce", teinte: teinteFiltre, action: filtre)
                BoutonVerreCarte(symbole: "gearshape", libelle: "Réglages et profil", action: reglages)
            }
        }
    }
}
