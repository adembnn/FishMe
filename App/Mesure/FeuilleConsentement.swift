import SwiftUI

/// La demi-feuille de consentement : une ligne, deux boutons de même poids, la carte reste visible derrière.
/// A la présente après la position et la question du niveau, jamais en même temps (`RootView.swift`).
struct FeuilleConsentement: View {
    let accepter: () -> Void
    let refuser: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Peut-on compter, sans jamais te suivre, comment FishMe est utilisé ? Ni photo, ni position.")
                .font(JetonsAbonnement.police(.headline))
                .foregroundStyle(JetonsAbonnement.marine)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { boutons }
                VStack(spacing: 12) { boutons }
            }
        }
        .padding(20)
        .presentationDetents([.height(220), .medium])
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled()
    }

    @ViewBuilder private var boutons: some View {
        bouton("Accepter", action: accepter)
        bouton("Refuser", action: refuser)
    }

    private func bouton(_ titre: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titre)
                .font(JetonsAbonnement.police(.headline))
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
        .tint(JetonsAbonnement.marine)
        .controlSize(.large)
    }
}
