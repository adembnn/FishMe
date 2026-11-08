import SwiftUI

/// Onglet « Communauté » en v1 : un écran sobre, sans date promise, sans aperçu de fonction et sans rien collecter.
struct CommunauteBientotView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: Espace.l) {
        Image(systemName: "person.2.fill")
          .font(.system(size: 40, weight: .bold, design: .rounded))
          .foregroundStyle(Palette.marine)
          .frame(width: 88, height: 88)
          .background(Palette.marineDoux, in: Circle())
          .accessibilityHidden(true)
        Text(c: "Communauté")
          .font(Police.grandTitre)
          .foregroundStyle(Palette.encre)
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.5)
          .accessibilityAddTraits(.isHeader)
        Text(c: "Bientôt")
          .font(Police.sousTitre)
          .foregroundStyle(Palette.marine)
        Text(c: "Les autres pêcheurs sont encore en route. Le fil, les messages et les clubs viendront plus tard.")
          .font(Police.corps)
          .foregroundStyle(Palette.encreDouce)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: 420)
      .padding(.horizontal, Espace.xl)
      .padding(.vertical, Espace.xxl)
      .frame(maxWidth: .infinity)
      .accessibilityElement(children: .combine)
      .accessibilityIdentifier("communaute.bientot")
    }
    .scrollIndicators(.hidden)
    .background(Palette.fond.ignoresSafeArea())
  }
}

#Preview("Bientôt") { CommunauteBientotView() }
