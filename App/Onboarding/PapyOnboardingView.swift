import SwiftUI

/// Papy, le petit grand-père qui guide l'onboarding : une illustration, une bulle de dialogue.
/// L'illustration est l'image `papy-onboarding` du catalogue d'images (à fournir par Adem). Tant qu'elle manque, un emplacement
/// sobre et lisible tient la place : jamais une illustration inventée.
struct PapyOnboardingView: View {
    let replique: String
    var nom: String = "Papy"

    private static let nomImage = "papy-onboarding"

    var body: some View {
        HStack(alignment: .bottom, spacing: Espace.m) {
            illustration
                .frame(width: 84, height: 84)
            bulle
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(nom) : \(replique)")
        .accessibilityIdentifier("papy-onboarding")
    }

    @ViewBuilder private var illustration: some View {
        if UIImage(named: Self.nomImage) != nil {
            Image(Self.nomImage)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            // Emplacement de l'illustration, en attendant celle d'Adem.
            ZStack {
                Circle().fill(Palette.marineDoux)
                VStack(spacing: 2) {
                    Image(systemName: "figure.fishing")
                        .font(.system(size: 34, weight: .bold))
                    Text(nom)
                        .font(Police.taille(11, .heavy))
                }
                .foregroundStyle(Palette.marine)
            }
            .accessibilityHidden(true)
        }
    }

    private var bulle: some View {
        Text(replique)
            .font(Police.detail)
            .foregroundStyle(Palette.encre)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Espace.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Palette.filet, lineWidth: 1))
            .overlay(alignment: .bottomLeading) {
                // La queue de la bulle, vers Papy.
                Triangle()
                    .fill(Palette.surface)
                    .overlay(Triangle().stroke(Palette.filet, lineWidth: 1))
                    .frame(width: 14, height: 12)
                    .rotationEffect(.degrees(-90))
                    .offset(x: -9, y: -14)
            }
    }
}

private struct Triangle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
