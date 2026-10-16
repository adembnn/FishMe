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
        VStack(spacing: Espace.l) {
            HStack {
                Text("Choisir un autre spot")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                Button(action: plusTard) {
                    Image(systemName: "xmark")
                        .font(Police.corps)
                        .foregroundStyle(Palette.marine)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(Palette.marineDoux, in: Circle())
                }
                .accessibilityLabel("Fermer")
            }

            Spacer(minLength: 0)
            illustration
            Text("Spots illimités")
                .font(Police.grandTitre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text("Pose un cercle où tu veux : tronçons entiers de rivière et lacs.")
                .font(Police.corps)
                .foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Label("Ton spot gratuit reste à toi, pour toujours", systemImage: "checkmark.circle.fill")
                .font(Police.legende)
                .foregroundStyle(Palette.ouvert)
                .multilineTextAlignment(.center)
            Spacer(minLength: 0)

            VStack(spacing: Espace.s) {
                Button("Découvrir Pro", action: decouvrir)
                    .buttonStyle(.principal)
                Button("Plus tard", action: plusTard)
                    .font(Police.corps)
                    .foregroundStyle(Palette.marine)
                    .frame(minHeight: Gabarit.zoneTactile)
            }
        }
        .padding(Espace.bord)
        .background(Palette.fond.ignoresSafeArea())
    }

    /// Une rivière, ton spot au centre et trois cercles en pointillés : l'idée de « plusieurs spots », sans cadenas.
    private var illustration: some View {
        ZStack {
            Circle().fill(Palette.tuile)
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
                .padding(.horizontal, Espace.m)
                .padding(.vertical, Espace.xs)
                .background(Palette.marine, in: Capsule())
        }
        .frame(width: 260, height: 260)
        .clipShape(Circle())
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
