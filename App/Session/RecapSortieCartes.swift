import Core
import SwiftUI
import UIKit

/// Une carte créée par la sortie, prête à être posée dans le carrousel.
struct RecapCarte: Identifiable {
    let id: UUID
    let infos: InfosCarte
    /// Vrai quand l'espèce entre dans le Pescedex avec cette sortie.
    let nouvelle: Bool
}

/// Le carrousel horizontal des cartes gagnées : une carte au centre, la suivante qui dépasse, les cartes qui se posent l'une après l'autre.
/// Avec « Réduire les animations », tout est déjà en place et rien ne bouge.
struct RecapSortieCartes: View {
    let cartes: [RecapCarte]

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var posees = false
    @State private var inclinaison: CGSize = .zero

    var body: some View {
        VStack(spacing: Espace.l) {
            Text(cartes.count > 1 ? "\(cartes.count) cartes gagnées" : "1 carte gagnée")
                .font(Police.titre)
                .foregroundStyle(Palette.encre)
            ScrollView(.horizontal) {
                LazyHStack(spacing: Espace.l) {
                    ForEach(Array(cartes.enumerated()), id: \.element.id) { index, carte in
                        VStack(spacing: Espace.m) {
                            CarteRectoView(infos: carte.infos, inclinaison: inclinaison)
                                .containerRelativeFrame(.horizontal) { largeur, _ in largeur * 0.62 }
                            legende(carte)
                        }
                        .opacity(posees || reduireAnimations ? 1 : 0)
                        .offset(y: posees || reduireAnimations ? 0 : 40)
                        .scaleEffect(posees || reduireAnimations ? 1 : 0.92)
                        .animation(reduireAnimations ? nil : .spring(duration: 0.6, bounce: 0.25).delay(0.15 * Double(index)),
                                   value: posees)
                        .scrollTransition(.interactive, axis: .horizontal) { vue, phase in
                            vue.scaleEffect(phase.isIdentity ? 1 : 0.9).opacity(phase.isIdentity ? 1 : 0.7)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Espace.bord + 20, for: .scrollContent)
            .scrollClipDisabled()
            .frame(minHeight: 200)
        }
        .onAppear {
            posees = true
            guard !reduireAnimations else { return }
            // Un léger balancement fait glisser le reflet holographique des cartes rares.
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                inclinaison = CGSize(width: 0.5, height: 0.3)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func legende(_ carte: RecapCarte) -> some View {
        VStack(spacing: Espace.xs) {
            Text(carte.infos.espece.nom)
                .font(Police.sousTitre)
                .foregroundStyle(Palette.encre)
                .multilineTextAlignment(.center)
            if carte.nouvelle {
                Label("Nouvelle espèce !", systemImage: "sparkles")
                    .font(Police.detail)
                    .foregroundStyle(Palette.ouvert)
                    .padding(.horizontal, Espace.m)
                    .padding(.vertical, Espace.xs)
                    .frame(minHeight: Gabarit.zoneTactile - 12)
                    .background(Palette.ouvertDoux, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

/// La carte « Eau calme » au centre de l'écran, posée avec le même soin que les cartes de prise.
struct RecapCarteBredouille: View {
    let carte: CarteBredouille
    var photo: UIImage? = nil

    @Environment(\.accessibilityReduceMotion) private var reduireAnimations
    @State private var posee = false
    @State private var inclinaison: CGSize = .zero

    var body: some View {
        CarteBredouilleRectoView(carte: carte, photo: photo, inclinaison: inclinaison)
            .containerRelativeFrame(.horizontal) { largeur, _ in largeur * 0.62 }
            .opacity(posee || reduireAnimations ? 1 : 0)
            .offset(y: posee || reduireAnimations ? 0 : 40)
            .scaleEffect(posee || reduireAnimations ? 1 : 0.92)
            .animation(reduireAnimations ? nil : .spring(duration: 0.6, bounce: 0.25), value: posee)
            .onAppear {
                posee = true
                guard !reduireAnimations else { return }
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    inclinaison = CGSize(width: 0.5, height: 0.3)
                }
            }
    }
}
