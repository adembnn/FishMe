import Core
import SwiftUI
import UIKit

/// Carte « Eau calme » (anciennement bredouille) : une sortie finie sans prise, au même format que les autres cartes.
/// Pas de rareté ni de pourcentage ; le pêcheur peut y mettre une photo de lui. Son recto est `CarteBredouilleRectoView`.
struct BredouilleView: View {
    let carte: CarteBredouille
    let services: ServicesCollection
    var emplacements: EmplacementsExternes = .vides
    var inclinaison: CGSize = .zero
    var refletFixe = true

    var body: some View {
        CarteBredouilleRectoView(carte: carte, inclinaison: inclinaison, refletFixe: refletFixe)
    }
}

/// Une carte « Eau calme » ouverte en plein écran : on la retourne au toucher ou au glissement, comme `CartePleinEcranView`.
/// Au verso, la météo du départ (bloc L12 s'il est branché) et la marque Apple Weather passent sous la carte.
struct BredouillePleinEcranView: View {
    let carte: CarteBredouille
    let services: ServicesCollection
    var emplacements: EmplacementsExternes = .vides
    let fermer: () -> Void

    @State private var angle: Double = 0
    @State private var angleDebut: Double?
    @State private var descente: CGFloat = 0
    @State private var sens: Sens?
    @State private var mouvement = MouvementIPhone()
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    private enum Sens { case horizontal, vertical }
    private var montreLeRecto: Bool { cos(angle * .pi / 180) > 0 }

    var body: some View {
        ZStack {
            Palette.fond.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: Espace.s) {
                    BoutonRond(role: .fermer, rendu: .verre, action: fermer)
                    Spacer(minLength: 0)
                    RondRetourner(icone: "arrow.triangle.2.circlepath", libelle: "Retourner la carte", action: retourner)
                }
                .padding(.horizontal, Espace.bord)
                GeometryReader { g in
                    let largeur = max(1, min(g.size.width - 2 * Espace.xl, (g.size.height - Espace.l) * Gabarit.rapportCarte))
                    carteTournante
                        .frame(width: largeur, height: largeur / Gabarit.rapportCarte)
                        .position(x: g.size.width / 2, y: g.size.height / 2)
                }
                pied
            }
            .offset(y: descente)
            .opacity(1 - Double(min(descente, 200)) / 600)
        }
        .contentShape(Rectangle())
        .gesture(glisser)
        .onAppear { if !reduireAnimations { mouvement.demarrer() } }
        .onDisappear { mouvement.arreter() }
    }

    @ViewBuilder
    private var pied: some View {
        if !montreLeRecto, let c = carte.conditions {
            VStack(spacing: Espace.xs) {
                if let slot = emplacements.meteoDuDos { slot(c) } else { BlocMeteoSimple(conditions: c) }
                MarqueAppleWeather()
            }
            .foregroundStyle(Palette.encre)
            .padding(.horizontal, Espace.bord)
            .frame(minHeight: Gabarit.zoneTactile)
        } else {
            Text("Touche la carte pour la retourner")
                .font(Police.legende)
                .foregroundStyle(Palette.encreDouce)
                .frame(minHeight: Gabarit.zoneTactile)
                .padding(.horizontal, Espace.bord)
        }
    }

    private var carteTournante: some View {
        let tourne = !reduireAnimations
        let reposRecto = abs(angle.truncatingRemainder(dividingBy: 360)) < 0.5
        let reliefX = tourne && reposRecto ? Double(mouvement.inclinaison.height) * -6 : 0
        let reliefY = tourne && reposRecto ? Double(mouvement.inclinaison.width) * 8 : 0
        return ZStack {
            CarteBredouilleRectoView(carte: carte, inclinaison: mouvement.inclinaison, refletFixe: reduireAnimations)
                .opacity(montreLeRecto ? 1 : 0)
            CarteBredouilleVersoView(carte: carte, services: services)
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
private struct RondRetourner: View {
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
