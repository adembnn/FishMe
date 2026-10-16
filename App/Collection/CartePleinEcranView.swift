import Core
import SwiftUI
import UIKit

/// La carte d'une prise, ouverte depuis le Pescedex : posée au milieu de l'écran, avec de la marge (même cadrage que la révélation,
/// recto et verso à la même taille), sur un fond sobre. On la fait tourner au doigt (rotation sur Y) ; un toucher ou un glissement
/// qui dépasse 90 degrés la retourne ; lâchée, elle revient à plat. L'inclinaison de l'iPhone ajoute un léger effet de relief.
/// Fermer est toujours en haut à gauche ; glisser vers le bas ferme aussi.
struct CartePleinEcranView: View {
    let infos: InfosCarte
    let photo: Data?
    var emplacements: EmplacementsExternes = .vides
    /// Image PNG du recto pour le partage (P49) ; sans elle, le bouton de partage n'est pas affiché.
    var png: Data? = nil
    let fermer: () -> Void

    /// Angle total de la carte autour de Y, en degrés : 0 recto à plat, 180 verso à plat.
    @State private var angle: Double = 0
    @State private var angleDebut: Double?
    @State private var descente: CGFloat = 0
    @State private var sens: Sens?
    @State private var apercuOuvert = false
    @State private var mouvement = MouvementIPhone()
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    private enum Sens { case horizontal, vertical }

    private var montreLeRecto: Bool { cos(angle * .pi / 180) > 0 }

    var body: some View {
        ZStack {
            Palette.fond.ignoresSafeArea()
            VStack(spacing: 0) {
                entete
                GeometryReader { g in
                    // Même cadrage que la révélation : 24 pt de marge de chaque côté, jamais plus haut que la place disponible.
                    let largeur = max(1, min(g.size.width - 2 * Espace.xl, (g.size.height - Espace.l) * Gabarit.rapportCarte))
                    carte
                        .frame(width: largeur, height: largeur / Gabarit.rapportCarte)
                        .position(x: g.size.width / 2, y: g.size.height / 2)
                }
                Text("Touche la carte pour la retourner")
                    .font(Police.legende)
                    .foregroundStyle(Palette.encreDouce)
                    .frame(minHeight: Gabarit.zoneTactile)
                    .padding(.horizontal, Espace.bord)
            }
            .offset(y: descente)
            .opacity(1 - Double(min(descente, 200)) / 600)
        }
        .contentShape(Rectangle())
        .gesture(glisser)
        .onAppear { if !reduireAnimations { mouvement.demarrer() } }
        .onDisappear { mouvement.arreter() }
        .fullScreenCover(isPresented: $apercuOuvert) {
            if let png {
                ApercuPartageView(png: png) { apercuOuvert = false }
            }
        }
    }

    // MARK: En-tête

    /// Haut de l'écran, à 16 pt des bords : fermer à gauche ; retourner et partager à droite.
    private var entete: some View {
        HStack(spacing: Espace.s) {
            BoutonRond(role: .fermer, rendu: .verre, action: fermer)
            Spacer(minLength: 0)
            RondSimple(icone: "arrow.triangle.2.circlepath", libelle: "Retourner la carte", action: retourner)
            if png != nil {
                RondSimple(icone: "square.and.arrow.up", libelle: "Partager") { apercuOuvert = true }
            }
        }
        .padding(.horizontal, Espace.bord)
    }

    // MARK: Carte

    private var carte: some View {
        let tourne = !reduireAnimations
        let reposRecto = abs(angle.truncatingRemainder(dividingBy: 360)) < 0.5
        // Relief de l'iPhone seulement quand la carte est à plat sur son recto.
        let reliefX = tourne && reposRecto ? Double(mouvement.inclinaison.height) * -6 : 0
        let reliefY = tourne && reposRecto ? Double(mouvement.inclinaison.width) * 8 : 0
        return ZStack {
            CarteRectoView(infos: infos, anime: true, inclinaison: mouvement.inclinaison, refletFixe: reduireAnimations)
                .opacity(montreLeRecto ? 1 : 0)
            CarteVersoView(infos: infos, photo: photo, emplacements: emplacements)
                .opacity(montreLeRecto ? 0 : 1)
                .rotation3DEffect(.degrees(tourne ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(tourne ? angle : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(reliefX), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(reliefY), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .contentShape(Rectangle())
        .onTapGesture { retourner() }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(montreLeRecto ? "Montre le verso" : "Montre le recto")
    }

    private func retourner() {
        let cible = ((angle / 180).rounded() + 1) * 180
        withAnimation(reduireAnimations ? .easeInOut(duration: 0.2) : .spring(duration: 0.55)) { angle = cible }
    }

    // MARK: Geste

    /// Horizontal : fait tourner la carte, qui se pose sur la face la plus proche en lâchant. Vertical vers le bas : ferme.
    private var glisser: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { v in
                if sens == nil { sens = abs(v.translation.width) >= abs(v.translation.height) ? .horizontal : .vertical }
                switch sens {
                case .horizontal:
                    if reduireAnimations { return }
                    if angleDebut == nil { angleDebut = angle }
                    angle = (angleDebut ?? 0) + Double(v.translation.width) * 0.6
                case .vertical:
                    descente = max(0, v.translation.height)
                case nil:
                    break
                }
            }
            .onEnded { v in
                defer { sens = nil; angleDebut = nil }
                if sens == .vertical {
                    if v.translation.height > 120 || v.predictedEndTranslation.height > 300 {
                        fermer()
                    } else {
                        withAnimation(.spring(duration: 0.35)) { descente = 0 }
                    }
                } else if sens == .horizontal {
                    let cible = (angle / 180).rounded() * 180
                    withAnimation(.spring(duration: 0.55, bounce: 0.2)) { angle = cible }
                }
            }
    }
}

/// Bouton rond de 44 pt à icône, de verre comme `BoutonRond`.
private struct RondSimple: View {
    let icone: String
    let libelle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icone)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.encre)
                .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                .background {
                    Circle()
                        .fill(.regularMaterial)
                        .overlay(Circle().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
                        .shadow(color: Palette.encre.opacity(0.12), radius: 10, y: 6)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(libelle)
    }
}
