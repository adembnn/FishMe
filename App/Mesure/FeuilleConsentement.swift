import SwiftUI

/// P05 (direction B, « Réglages ») : la feuille de consentement avant la mesure d'audience.
/// Deux groupes (ce qui est mesuré, ce qui n'est jamais envoyé), deux boutons de même poids, « En savoir plus ».
/// A la présente après la position et la question du niveau, jamais en même temps (`RootView.swift`).
struct FeuilleConsentement: View {
    let accepter: () -> Void
    let refuser: () -> Void

    @State private var detailOuvert = false

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.l) {
            VStack(alignment: .leading, spacing: Espace.xs) {
                Text("Mesure d'audience")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tu peux changer ton choix à tout moment dans les réglages.")
                    .font(Police.corps)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
            groupe(
                titre: "Mesuré",
                lignes: [
                    ("Écrans ouverts", "Pour savoir ce qui sert"),
                    ("Fonctions utilisées", "Pour corriger ce qui bloque"),
                ]
            )
            groupe(
                titre: "Jamais envoyé",
                lignes: [
                    ("Ta position exacte", nil),
                    ("Tes photos", nil),
                ]
            )
            if detailOuvert {
                Text("FishMe compte seulement des usages anonymes, sans te suivre d'une app à l'autre. Aucun coin de pêche ne quitte ton iPhone.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Espace.m) { boutons }
                VStack(spacing: Espace.m) { boutons }
            }
            Button(detailOuvert ? "Masquer" : "En savoir plus") { detailOuvert.toggle() }
                .font(Police.corps)
                .foregroundStyle(Palette.marine)
                .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
        }
        .padding(Espace.bord)
        .background(Palette.fond)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
    }

    private func groupe(titre: String, lignes: [(String, String?)]) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(titre.uppercased())
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .padding(.leading, Espace.l)
            VStack(spacing: 0) {
                ForEach(Array(lignes.enumerated()), id: \.offset) { position, ligne in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ligne.0)
                            .font(Police.sousTitre)
                            .foregroundStyle(Palette.encre)
                        if let detail = ligne.1 {
                            Text(detail)
                                .font(Police.legende)
                                .foregroundStyle(Palette.encreDouce)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
                    .padding(.horizontal, Espace.l)
                    .padding(.vertical, Espace.s)
                    .accessibilityElement(children: .combine)
                    if position < lignes.count - 1 {
                        Divider().padding(.leading, Espace.l)
                    }
                }
            }
            .tuileFishMe(rayon: Rayon.l)
        }
    }

    /// Même style pour les deux : aucun bouton n'est poussé plus que l'autre.
    @ViewBuilder private var boutons: some View {
        Button("Refuser", action: refuser).buttonStyle(.secondaire)
        Button("Accepter", action: accepter).buttonStyle(.secondaire)
    }
}
