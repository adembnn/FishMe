import SwiftUI

/// Papy, le petit grand-père qui guide l'onboarding : une bulle de dialogue, et sous elle Papy, sur le côté de l'écran.
/// Les quatre poses sont des images du catalogue (`papy-salut`, `papy-montre`, `papy-rit`, `papy-pouce`, fournies par Titouan).
/// Il entre en glissant avec un léger rebond (0,3 s), sans animation avec « Réduire les animations ». Jamais par-dessus un champ.
struct PapyOnboardingView: View {
    enum Pose: String {
        case salut = "papy-salut"      // de face, salue (plein pied) : bienvenue, langue
        case montre = "papy-montre"    // buste, montre du doigt vers la droite : zone, position
        case rit = "papy-rit"          // buste, se tient la barbe en riant : la blague sur la pêche
        case pouce = "papy-pouce"      // plein pied, pouce levé : fin de l'onboarding

        var hauteur: CGFloat { self == .salut || self == .pouce ? 160 : 110 }
    }

    let replique: String
    var pose: Pose = .salut
    var nom: String = "Papy"

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var apparu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            bulle
            papy
                .padding(.leading, Espace.l)
                .offset(y: -1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(nom) : \(replique)")
        .accessibilityIdentifier("papy-onboarding")
        .onAppear {
            guard !apparu else { return }
            if reduireAnimations { apparu = true } else {
                withAnimation(.spring(duration: 0.3, bounce: 0.3)) { apparu = true }
            }
        }
    }

    @ViewBuilder private var papy: some View {
        Image(pose.rawValue)
            .resizable()
            .scaledToFit()
            .frame(height: pose.hauteur)
            .accessibilityHidden(true)
            // Il « pop » depuis le côté : glissement doux et léger rebond.
            .offset(x: apparu ? 0 : -44)
            .opacity(apparu ? 1 : 0)
            .id(pose)
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
                // La queue de la bulle, vers Papy (en dessous).
                Triangle()
                    .fill(Palette.surface)
                    .overlay(Triangle().stroke(Palette.filet, lineWidth: 1))
                    .frame(width: 16, height: 11)
                    .rotationEffect(.degrees(180))
                    .offset(x: 34, y: 10)
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
