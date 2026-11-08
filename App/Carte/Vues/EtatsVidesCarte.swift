import SwiftUI

/// P46 B : les deux états vides de la carte. Bandeau sur surface blanche, icône grise (jamais orange : ce n'est pas une alerte),
/// et la carte « Pas de spot » avec un seul chemin, « Choisir un spot ». Aucune donnée : que du texte fixe.

/// Bandeau « Pas de réseau ». À poser au-dessus de la carte quand le réseau manque.
struct BandeauPasDeReseauView: View {
    var body: some View {
        HStack(spacing: Espace.m) {
            Image(systemName: "wifi.slash")
                .font(Police.taille(24))
                .foregroundStyle(Palette.encreDouce)
                .frame(width: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Pas de réseau")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                Text("Règles et cartes disponibles. Météo et rivière reviennent avec le réseau.")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Espace.l)
        .padding(.vertical, Espace.s)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .tuileFishMe(rayon: Rayon.m)
        .accessibilityElement(children: .combine)
    }
}

/// Carte « Pas de spot » : un cercle en pointillés, deux phrases, une seule action.
struct PasDeSpotView: View {
    let choisirUnSpot: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .strokeBorder(Palette.marine, style: StrokeStyle(lineWidth: 2.5, dash: [5, 4]))
                        .frame(width: 72, height: 72)
                    Image(systemName: "mappin")
                        .font(Police.taille(32))
                        .foregroundStyle(Palette.marine)
                }
                .accessibilityHidden(true)
                Text(MonSpotTextes.t("Pas de spot", locale))
                    .font(Police.taille(22, .heavy))
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Text(MonSpotTextes.t("Pose un cercle d'1 km sur ta rivière pour voir ses poissons.", locale))
                    .font(Police.taille(15))
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Espace.l)
            .padding(.top, 28)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)

            Divider().overlay(Palette.filet)

            Button(action: choisirUnSpot) {
                HStack {
                    Text(MonSpotTextes.t("Choisir un spot", locale))
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                    Spacer(minLength: Espace.s)
                    Image(systemName: "chevron.right")
                        .font(Police.taille(13))
                        .foregroundStyle(Palette.encreDouce)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, Espace.l)
                .frame(minHeight: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .tuileFishMe(rayon: Rayon.m)
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
