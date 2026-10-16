import SwiftUI

/// Le chrono façon Horloge d'Apple : un grand anneau, une jauge aux bouts arrondis, le temps écoulé au centre en chiffres fins.
/// `progression` va de 0 à 1 ; `sousTitre` se pose sous le temps. Le diamètre vient de l'appelant (largeur et hauteur disponibles).
struct ChronoAnneauView<SousTitre: View>: View {
  let temps: String
  let progression: Double
  let diametre: CGFloat
  let sousTitre: SousTitre
  @Environment(\.accessibilityReduceMotion) private var reduireAnimations

  init(
    temps: String, progression: Double, diametre: CGFloat, @ViewBuilder sousTitre: () -> SousTitre
  ) {
    self.temps = temps
    self.progression = progression
    self.diametre = diametre
    self.sousTitre = sousTitre()
  }

  private var epaisseur: CGFloat { max(10, diametre * 0.055) }

  var body: some View {
    ZStack {
      Circle()
        .stroke(Palette.filet.opacity(0.7), lineWidth: epaisseur)
      Circle()
        .trim(from: 0, to: min(max(progression, 0.003), 1))
        .stroke(Palette.marine, style: StrokeStyle(lineWidth: epaisseur, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(reduireAnimations ? nil : .linear(duration: 1), value: progression)
      VStack(spacing: Espace.xs) {
        Text(temps)
          .font(Police.taille(diametre * 0.2, .bold).monospacedDigit())
          .foregroundStyle(Palette.encre)
          .lineLimit(1)
          .minimumScaleFactor(0.4)
        sousTitre
      }
      .padding(.horizontal, epaisseur + Espace.s)
      .frame(width: diametre - epaisseur * 2)
    }
    .frame(width: diametre, height: diametre)
    .padding(epaisseur / 2)
    .accessibilityElement(children: .contain)
  }
}

/// Un gros bouton rond façon Horloge : un disque teinté, l'icône au centre, le libellé dessous.
struct BoutonRondHorloge: View {
  let titre: String
  let icone: String
  let couleur: Color
  var diametre: CGFloat = 84
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: Espace.s) {
        Image(systemName: icone)
          .font(.system(size: diametre * 0.34, weight: .semibold, design: .rounded))
          .foregroundStyle(couleur)
          .frame(width: diametre, height: diametre)
          .background(Circle().fill(couleur.opacity(0.18)))
          .overlay(Circle().strokeBorder(couleur.opacity(0.35), lineWidth: 1))
        Text(titre)
          .font(Police.detail)
          .foregroundStyle(Palette.encre)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(titre)
  }
}
