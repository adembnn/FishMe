import SwiftUI

/// P05 (direction B, « Réglages ») : la feuille de consentement avant la mesure d'audience.
/// Deux groupes (ce qui est mesuré, ce qui n'est jamais envoyé), deux boutons de même poids, « En savoir plus ».
/// A la présente après la position et la question du niveau, jamais en même temps (`RootView.swift`), en grand (la maquette est un écran entier).
struct FeuilleConsentement: View {
    let accepter: () -> Void
    let refuser: () -> Void

    @State private var detailOuvert = false

    var body: some View {
        ScrollView {
            contenu
                .padding(.horizontal, Espace.bord)
                .padding(.top, Espace.s)
                .padding(.bottom, Espace.bord)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: Espace.xs) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { boutons }
                    VStack(spacing: 10) { boutons }
                }
                Button(detailOuvert ? "Masquer" : "En savoir plus") { detailOuvert.toggle() }
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
            .padding(.bottom, 6)
            .background(Palette.fond)
        }
        .background(Palette.fond)
        .presentationBackground(Palette.fond)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
    }

    private var contenu: some View {
        // Maquette P05-B : titre de 34, phrase de 15 à 8 pt dessous, puis chaque groupe à 22 pt du précédent.
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: Espace.s) {
                // Pas de bouton fermer (la maquette n'en a pas) : la feuille ne se ferme que par « Refuser » ou « Accepter »,
                // donc rien n'est mesuré tant que le pêcheur n'a pas accepté.
                Text("Mesure d'audience")
                    .font(Police.grandTitre)
                    .foregroundStyle(Palette.encre)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Tu peux changer ton choix à tout moment dans les réglages.")
                    .font(Police.detail)
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
        }
    }

    private func groupe(titre: String, lignes: [(String, String?)]) -> some View {
        VStack(alignment: .leading, spacing: Espace.s) {
            Text(titre.uppercased())
                .font(Police.legende)
                .tracking(0.5)
                .foregroundStyle(Palette.encreDouce)
                .padding(.leading, Espace.l)
            VStack(spacing: 0) {
                ForEach(Array(lignes.enumerated()), id: \.offset) { position, ligne in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(ligne.0)
                            .font(Police.corps)
                            .foregroundStyle(Palette.encre)
                        if let detail = ligne.1 {
                            Text(detail)
                                .font(Police.legende)
                                .foregroundStyle(Palette.encreDouce)
                        }
                    }
                    .padding(.horizontal, Espace.l)
                    .padding(.vertical, Espace.s)
                    .frame(maxWidth: .infinity, minHeight: ligne.1 == nil ? 56 : 64, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    if position < lignes.count - 1 {
                        Divider().padding(.leading, Espace.l)
                    }
                }
            }
            .tuileFishMe(rayon: Rayon.m)
        }
    }

    /// Même style pour les deux : aucun bouton n'est poussé plus que l'autre.
    @ViewBuilder private var boutons: some View {
        Button("Refuser", action: refuser).buttonStyle(.secondaire)
        Button("Accepter", action: accepter).buttonStyle(.secondaire)
    }
}
