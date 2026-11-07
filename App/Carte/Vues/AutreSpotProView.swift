import SwiftUI
import Core

/// P10 « Choisir un autre spot » : l'invitation Pro quand le pêcheur veut un deuxième spot.
/// Ton MWM positif (docs/design/ton-mwm.md) : « Spots illimités », aucun interdit, aucun cadenas.
/// Cette vue ne présente pas le paywall elle-même : `decouvrir` et `plusTard` sont branchés par A
/// (`RootView` ouvre déjà `.paywall(.autreSpot)`).
struct AutreSpotProView: View {
    let decouvrir: () -> Void
    let plusTard: () -> Void
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            contenu
                .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 6) {
                Button(AnglaisFCarte.t("Découvrir Pro", locale), action: decouvrir)
                    .buttonStyle(.principal)
                Button(AnglaisFCarte.t("Plus tard", locale), action: plusTard)
                    .font(Police.taille(17, .heavy))
                    .foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, Espace.s)
            .background(Palette.surface)
        }
        .background(Palette.surface.ignoresSafeArea())
    }

    private var contenu: some View {
        VStack(spacing: 0) {
            HStack {
                Text(AnglaisFCarte.t("Choisir un autre spot", locale))
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Espace.s)
                Button(action: plusTard) {
                    Image(systemName: "xmark")
                        .font(Police.taille(20, .heavy))
                        .foregroundStyle(Palette.marine)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(Palette.tuile, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AnglaisFCarte.t("Fermer", locale))
            }

            illustration
                .padding(.top, 47)
            VStack(spacing: 10) {
                Text(AnglaisFCarte.t("Spots illimités", locale))
                    .font(Police.taille(28, .heavy))
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(AnglaisFCarte.t("Pose un cercle où tu veux : tronçons entiers de rivière et lacs.", locale))
                    .font(Police.taille(15))
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Police.taille(16))
                        .foregroundStyle(Palette.ouvert)
                        .accessibilityHidden(true)
                    Text(AnglaisFCarte.t("Ton spot gratuit reste à toi, pour toujours", locale))
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                }
                .font(Police.taille(13))
            }
            .padding(.top, 32)
            .padding(.horizontal, Espace.l)
        }
    }

    /// Une rivière, ton spot au centre et trois cercles en pointillés : l'idée de « plusieurs spots », sans cadenas.
    private var illustration: some View {
        ZStack {
            Circle().fill(Palette.fond)
            Capsule()
                .fill(Palette.eau)
                .frame(width: 70, height: 300)
                .rotationEffect(.degrees(12))
            cercle(x: -30, y: -105)
            cercle(x: -85, y: 70)
            cercle(x: 55, y: 85)
            Circle()
                .strokeBorder(Palette.marine, lineWidth: 2.5)
                .background(Circle().fill(Color.white.opacity(0.35)))
                .frame(width: 80, height: 80)
            Text(AnglaisFCarte.t("Ton spot", locale))
                .font(Police.taille(12))
                .foregroundStyle(Palette.surMarine)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.marine, in: Capsule())
        }
        .frame(maxWidth: 280)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Palette.filet, lineWidth: 1))
        .accessibilityHidden(true)
    }

    private func cercle(x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .strokeBorder(Palette.marine, style: StrokeStyle(lineWidth: 2.5, dash: [4, 3]))
            .background(Circle().fill(Color.white.opacity(0.35)))
            .frame(width: 56, height: 56)
            .offset(x: x, y: y)
    }
}

#if DEBUG
#Preview {
    AutreSpotProView(decouvrir: {}, plusTard: {})
}
#endif
