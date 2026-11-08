import SwiftUI

/// Papy en personnage qui parle : une des quatre poses (images du catalogue, fournies par Titouan).
/// Il entre depuis la droite avec un léger rebond (0,3 s), sans animation avec « Réduire les animations ».
struct PapyPersonnage: View {
    enum Pose: String {
        case salut = "papy-salut"      // de face, salue (plein pied) : bienvenue, langue
        case montre = "papy-montre"    // buste, montre du doigt vers la droite : zone, position
        case rit = "papy-rit"          // buste, se tient la barbe en riant : la blague
        case pouce = "papy-pouce"      // plein pied, pouce levé : fin
        var pleinPied: Bool { self == .salut || self == .pouce }
    }

    let pose: Pose
    /// Hauteur d'un plein pied ; les bustes en prennent les 3/4.
    let hauteur: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var apparu = false

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .scaledToFit()
            .frame(height: pose.pleinPied ? hauteur : hauteur * 0.75)
            .accessibilityHidden(true)
            .offset(x: apparu ? 0 : 60)
            .opacity(apparu ? 1 : 0)
            .id(pose)
            .onAppear {
                if reduireAnimations { apparu = true } else { withAnimation(.spring(duration: 0.3, bounce: 0.3)) { apparu = true } }
            }
    }
}

/// La bulle de dialogue : sa queue part vers Papy (à droite, en bas de la bulle).
struct BulleDialogue: View {
    let texte: String
    /// Distance de la queue au bord droit de la bulle : sous la tête de Papy.
    var queueDepuisLaDroite: CGFloat = 56

    var body: some View {
        Text(texte)
            .font(Police.sousTitre)
            .foregroundStyle(Palette.encre)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(Espace.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.filet, lineWidth: 1))
            .overlay(alignment: .bottomTrailing) {
                QueueBulle()
                    .fill(Palette.surface)
                    .overlay(QueueBulle().stroke(Palette.filet, lineWidth: 1))
                    .frame(width: 26, height: 16)
                    .offset(x: -queueDepuisLaDroite, y: 15)
            }
            .padding(.bottom, 14)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Papy : \(texte)")
            .accessibilityIdentifier("papy-onboarding")
    }
}

private struct QueueBulle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX * 0.7, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
