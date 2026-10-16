import SwiftUI
import Core

/// P10 « Choisir un autre spot » : l'invitation Pro quand le pêcheur veut un deuxième spot.
/// Ton MWM positif (docs/design/ton-mwm.md) : « Spots illimités », aucun interdit, aucun cadenas.
/// Cette vue ne présente pas le paywall elle-même : `decouvrir` et `plusTard` sont branchés par A
/// (`RootView` ouvre déjà `.paywall(.autreSpot)`).
struct AutreSpotProView: View {
    let decouvrir: () -> Void
    let plusTard: () -> Void

    var body: some View {
        ScrollView {
            contenu
                .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: Espace.xs) {
                Button("Découvrir Pro", action: decouvrir)
                    .buttonStyle(.principal)
                Button("Plus tard", action: plusTard)
                    .font(Police.corps)
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
                Text("Choisir un autre spot")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Espace.s)
                Button(action: plusTard) {
                    Image(systemName: "xmark")
                        .font(Police.taille(18))
                        .foregroundStyle(Palette.marine)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(Palette.tuile, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fermer")
            }

            Spacer(minLength: Espace.l)
            illustration
            VStack(spacing: Espace.m) {
                Text("Spots illimités")
                    .font(Police.taille(28, .heavy))
                    .foregroundStyle(Palette.encre)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text("Pose un cercle où tu veux : tronçons entiers de rivière et lacs.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Espace.s) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.ouvert)
                        .accessibilityHidden(true)
                    Text("Ton spot gratuit reste à toi, pour toujours")
                        .foregroundStyle(Palette.encreDouce)
                        .multilineTextAlignment(.center)
                }
                .font(Police.legende)
            }
            .padding(.top, Espace.xl)
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
                .strokeBorder(Palette.marine, lineWidth: 2)
                .frame(width: 80, height: 80)
            Text("Ton spot")
                .font(Police.legende)
                .foregroundStyle(Palette.surMarine)
                .padding(.horizontal, Espace.s)
                .padding(.vertical, Espace.xs)
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
            .strokeBorder(Palette.marine, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            .background(Circle().fill(Palette.marine.opacity(0.12)))
            .frame(width: 56, height: 56)
            .offset(x: x, y: y)
    }
}

#if DEBUG
#Preview {
    AutreSpotProView(decouvrir: {}, plusTard: {})
}
#endif
