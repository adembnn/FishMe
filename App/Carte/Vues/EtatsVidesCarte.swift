import SwiftUI

/// P46 B : les deux états vides de la carte. Bandeau bleu doux (jamais orange : ce n'est pas une alerte),
/// et la carte « Pas de spot » avec un seul chemin, « Choisir un spot ». Aucune donnée : que du texte fixe.

/// Bandeau « Pas de réseau ». À poser au-dessus de la carte quand le réseau manque.
struct BandeauPasDeReseauView: View {
    var body: some View {
        HStack(alignment: .top, spacing: Espace.m) {
            Image(systemName: "wifi.slash")
                .font(Police.taille(20))
                .foregroundStyle(Palette.marine)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text("Pas de réseau")
                    .font(Police.sousTitre)
                    .foregroundStyle(Palette.encre)
                Text("Tes cartes restent là. Règles et cartes disponibles, météo et rivière reviennent avec le réseau.")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Espace.l)
        .background(Palette.marineDoux, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Carte « Pas de spot » : un cercle en pointillés, deux phrases, une seule action.
struct PasDeSpotView: View {
    let choisirUnSpot: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: Espace.m) {
                ZStack {
                    Circle()
                        .strokeBorder(Palette.marine, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                        .frame(width: 72, height: 72)
                    Image(systemName: "mappin")
                        .font(Police.taille(26))
                        .foregroundStyle(Palette.marine)
                }
                .accessibilityHidden(true)
                Text("Pas de spot")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Text("Pose un cercle d'1 km sur ta rivière pour voir ses poissons.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Espace.xl)
            .frame(maxWidth: .infinity)

            Divider().overlay(Palette.filet)

            Button(action: choisirUnSpot) {
                HStack {
                    Text("Choisir un spot")
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                    Spacer(minLength: Espace.s)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Palette.silhouette)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, Espace.l)
                .frame(minHeight: Gabarit.bouton)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .tuileFishMe(rayon: Rayon.l)
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: Espace.l) {
        BandeauPasDeReseauView()
        PasDeSpotView(choisirUnSpot: {})
    }
    .padding(Espace.bord)
    .background(Palette.fond)
}
#endif
