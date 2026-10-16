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
            Palette.fond.ignoresSafeArea()
            VStack {
                Spacer(minLength: 64)
                carte
                    .padding(.horizontal, Espace.xl)
                Spacer(minLength: Espace.l)
                Button(action: retourner) {
                    Label(retournee ? "Voir le recto" : "Voir la photo", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.principal)
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.l)
            }
            BoutonRond(role: .fermer, rendu: .verre, action: fermer)
                .padding(Espace.bord)
        }
        .onAppear { if infos.style.aUnReflet && !reduireAnimations { mouvement.demarrer() } }
        .onDisappear { mouvement.arreter() }
    }

    private func retourner() {
        withAnimation(reduireAnimations ? .easeInOut(duration: 0.2) : .spring(duration: 0.55)) {
            retournee.toggle()
        }
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
        .onTapGesture { retourner() }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Retourne la carte")
    }
}
