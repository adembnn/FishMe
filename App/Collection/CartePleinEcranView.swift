import Core
import SwiftUI
import UIKit

/// La carte d'une prise, ouverte en plein écran (P24 A pour le recto, P25 C pour le verso) : le poisson nage, les rares et légendaires brillent,
/// un toucher la retourne, un glissement horizontal la fait tourner au doigt (elle se pose sur la face la plus proche), l'inclinaison de l'iPhone
/// lui donne un léger relief et un glissement vers le bas ferme. Le mouvement n'est lancé qu'ici, jamais sur la grille du classeur.
/// Recto : fond bleu clair, fermer à gauche, retourner et partager à droite, « Enregistrer dans Photos » en bas. Verso : fond blanc,
/// fermer et partager, la photo seule sur la carte (Adem, 16 oct.), « Enregistrer dans Photos » (la photo) et « Voir le recto » en bas.
struct CartePleinEcranView: View {
    let infos: InfosCarte
    let photo: Data?
    var emplacements: EmplacementsExternes = .vides
    /// Image PNG du recto pour le partage (P49) ; sans elle, le bouton de partage n'est pas affiché.
    var png: Data? = nil
    let fermer: () -> Void

    /// Angle de la carte autour de Y, en degrés : 0 recto à plat, 180 verso à plat.
    @State private var angle: Double = 0
    @State private var angleDebut: Double?
    @State private var descente: CGFloat = 0
    @State private var sens: Sens?
    @State private var apercuOuvert = false
    @State private var publierOuvert = false
    @State private var mouvement = MouvementIPhone()
    @Environment(\.accessibilityReduceMotion) private var reduireAnimations

    /// Largeur de la carte à l'écran (la maquette : 302 pt sur 390).
    private let largeurCarte: CGFloat = 302

    private enum Sens { case horizontal, vertical }

    private var retournee: Bool { cos(angle * .pi / 180) <= 0 }

    var body: some View {
        ZStack {
            (retournee ? Palette.surface : Palette.tuile).ignoresSafeArea()
            VStack(spacing: 0) {
                entete
                carte
                    .frame(width: largeurCarte)
                    .padding(.top, 15)
                // Plus de panneau « raretés » sous une carte ouverte (L18) : il vit dans la fiche d'une espèce.
                Spacer(minLength: Espace.l)
                // US12 : en région États-Unis, le bouton des règles de pêche de l'État (rien en France).
                BoutonReglesUS(prise: infos.prise, nomEspece: infos.espece.nom)
                // Recto : l'image de la carte ; verso : la photo du pêcheur (déjà sans GPS). Jamais de lieu dans Photos.
                EnregistrerDansPhotosBouton(donnees: retournee ? photo : png)
                    .id(retournee)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, retournee ? Espace.s : Espace.l)
                if let photo, let publier = emplacements.publierCarte,
                   PublicationDepuisCarte.estPublicable(infos.prise, photo: photo) {
                    // L23 : la photo de la prise (sans GPS), lieu « département seul » par défaut.
                    Button { publierOuvert = true } label: {
                        Label("Publier", systemImage: "paperplane")
                    }
                    .buttonStyle(.secondaire)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, retournee ? Espace.s : Espace.l)
                    .sheet(isPresented: $publierOuvert) {
                        publier(infos.prise, infos.rarete.niveau, photo)
                    }
                }
                if retournee {
                    Button(action: retourner) {
                        Label("Voir le recto", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.principal)
                    .padding(.horizontal, Espace.bord)
                    .padding(.bottom, 6)
                }
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
        let cible = ((angle / 180).rounded() + 1) * 180
        withAnimation(reduireAnimations ? .easeInOut(duration: 0.2) : .spring(duration: 0.55)) { angle = cible }
    }

    private var carte: some View {
        let tourne = !reduireAnimations
        let reposRecto = abs(angle.truncatingRemainder(dividingBy: 360)) < 0.5
        // Relief de l'iPhone seulement quand la carte est à plat sur son recto.
        let reliefX = tourne && reposRecto ? Double(mouvement.inclinaison.height) * -6 : 0
        let reliefY = tourne && reposRecto ? Double(mouvement.inclinaison.width) * 8 : 0
        return ZStack {
            CarteRectoView(infos: infos, anime: true, inclinaison: mouvement.inclinaison, refletFixe: reduireAnimations)
                .opacity(retournee ? 0 : 1)
            CarteVersoView(infos: infos, photo: photo, emplacements: emplacements)
                .opacity(retournee ? 1 : 0)
                .rotation3DEffect(.degrees(tourne ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(tourne ? angle : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(reliefX), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
        .rotation3DEffect(.degrees(reliefY), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .contentShape(Rectangle())
        .onTapGesture { retourner() }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(retournee ? "Montre le recto" : "Montre le verso")
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
