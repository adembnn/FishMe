import Core
import SwiftUI

/// La carte d'une prise, ouverte en plein écran : le poisson nage, les rares et légendaires brillent, un toucher la retourne.
/// Le mouvement n'est lancé qu'ici, jamais sur la grille du classeur.
struct CartePleinEcranView: View {
    let infos: InfosCarte
    let photo: Data?
    var emplacements: EmplacementsExternes = .vides
    let fermer: () -> Void

    @State private var retournee = false
    @State private var mouvement = MouvementIPhone()
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    var body: some View {
        ZStack(alignment: .topLeading) {
            Jeton.fondPage.ignoresSafeArea()
            VStack {
                Spacer(minLength: 56)
                carte
                    .padding(.horizontal, 20)
                Text(retournee ? "Touche la carte pour revoir le recto" : "Touche la carte pour la retourner")
                    .font(Jeton.police(14, .semibold))
                    .foregroundStyle(Jeton.encreDouce)
                    .padding(.top, 12)
                Spacer(minLength: 24)
            }
            Button(action: fermer) {
                Label("Fermer", systemImage: "xmark")
                    .font(Jeton.police(16))
                    .padding(.horizontal, 14)
                    .frame(minHeight: Jeton.zoneTactile)
                    .background(.regularMaterial, in: Capsule())
                    .foregroundStyle(Jeton.encre)
            }
            .padding(16)
        }
        .onAppear { if infos.style.aUnReflet && !reduireAnimations { mouvement.demarrer() } }
        .onDisappear { mouvement.arreter() }
    }

    private var carte: some View {
        ZStack {
            CarteRectoView(infos: infos, anime: true, inclinaison: mouvement.inclinaison, refletFixe: reduireAnimations)
                .opacity(retournee ? 0 : 1)
            CarteVersoView(infos: infos, photo: photo, emplacements: emplacements)
                .opacity(retournee ? 1 : 0)
                .rotation3DEffect(.degrees(reduireAnimations ? 0 : 180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(retournee && !reduireAnimations ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(reduireAnimations ? .easeInOut(duration: 0.2) : .spring(duration: 0.55)) {
                retournee.toggle()
            }
        }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Retourne la carte")
    }
}
