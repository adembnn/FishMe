import Core
import SwiftUI
import UIKit

/// La carte d'une prise, ouverte en plein écran (P24 A pour le recto, P25 C pour le verso) : le poisson nage, les rares et légendaires brillent,
/// un toucher la retourne. Le mouvement n'est lancé qu'ici, jamais sur la grille du classeur.
/// Recto : fond bleu clair, fermer à gauche, retourner et partager à droite, rien d'autre. Verso : fond blanc, fermer et partager,
/// la photo seule sur la carte (Adem, 16 oct.), et « Voir le recto » en bas.
struct CartePleinEcranView: View {
    let infos: InfosCarte
    let photo: Data?
    var emplacements: EmplacementsExternes = .vides
    /// Image PNG du recto pour le partage (P49) ; sans elle, le bouton de partage n'est pas affiché.
    var png: Data? = nil
    let fermer: () -> Void

    @State private var retournee = false
    @State private var apercuOuvert = false
    @State private var mouvement = MouvementIPhone()
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    /// Largeur de la carte à l'écran (la maquette : 302 pt sur 390).
    private let largeurCarte: CGFloat = 302

    var body: some View {
        ZStack {
            (retournee ? Palette.surface : Palette.tuile).ignoresSafeArea()
            VStack(spacing: 0) {
                entete
                carte
                    .frame(width: largeurCarte)
                    .padding(.top, 15)
                Spacer(minLength: Espace.l)
                if retournee {
                    Button(action: retourner) {
                        Label("Voir le recto", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.principal)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, 6)
                }
            }
        }
        .onAppear { if infos.style.aUnReflet && !reduireAnimations { mouvement.demarrer() } }
        .onDisappear { mouvement.arreter() }
        .fullScreenCover(isPresented: $apercuOuvert) {
            if let png {
                ApercuPartageView(png: png) { apercuOuvert = false }
            }
        }
    }

    // MARK: En-tête

    /// Haut de l'écran, à 16 pt des bords : fermer à gauche ; retourner (recto seulement) et partager à droite.
    private var entete: some View {
        HStack(spacing: Espace.s) {
            if retournee {
                RondSimple(icone: "xmark", libelle: "Fermer", couleur: Palette.encre, action: fermer)
            } else {
                BoutonRond(role: .fermer, rendu: .verre, action: fermer)
            }
            Spacer(minLength: 0)
            if !retournee {
                RondSimple(icone: "arrow.triangle.2.circlepath", libelle: "Retourner la carte", couleur: Palette.encre,
                           verre: true, action: retourner)
            }
            if png != nil {
                RondSimple(icone: "square.and.arrow.up", libelle: "Partager", couleur: retournee ? Palette.marine : Palette.encre,
                           verre: !retournee) { apercuOuvert = true }
            }
        }
        .padding(.horizontal, Espace.bord)
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

/// Bouton rond de 44 pt à icône : de verre (`.rond.verre`) ou sur fond bleu clair (`.rond` du verso).
private struct RondSimple: View {
    let icone: String
    let libelle: String
    let couleur: Color
    var verre = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icone)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(couleur)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background {
                    if verre {
                        Circle()
                            .fill(.regularMaterial)
                            .overlay(Circle().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                            .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
                    } else {
                        Circle().fill(Palette.tuile)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }
}
