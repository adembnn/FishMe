import Core
import SwiftUI
import UIKit

/// Visionneuse réutilisable d'une carte : plein écran, la carte au milieu (même cadrage que la révélation), recto puis dos.
/// Le recto reprend le dessin de `CarteAmiMini` en grand (cadre de rareté, dessin de l'espèce, nom, taille, badge).
/// Le dos est la vraie photo de la prise, plein cadre, sans aucun texte (décision d'Adem) ; sans photo, le dessin de l'espèce sur le fond de sa rareté.
/// Un toucher sur la carte ou le bouton en haut à droite la retourne ; un glissement horizontal la fait tourner et, lâchée, elle se pose
/// sur la face la plus proche ; glisser vers le bas ferme. Avec « Réduire les animations », la carte ne tourne pas : elle se retourne en fondu.
struct VisionneuseCarte: View {
  let nomEspece: String
  let imageEspece: String
  let tailleCm: Int?
  let niveau: NiveauRarete
  let photo: UIImage?
  let detail: String?
  let fermer: () -> Void

  init(
    nomEspece: String, imageEspece: String, tailleCm: Int?, niveau: NiveauRarete, photo: UIImage?,
    detail: String? = nil, fermer: @escaping () -> Void
  ) {
    self.nomEspece = nomEspece
    self.imageEspece = imageEspece
    self.tailleCm = tailleCm
    self.niveau = niveau
    self.photo = photo
    self.detail = detail
    self.fermer = fermer
  }

  /// Angle total autour de Y, en degrés : 0 recto à plat, 180 dos à plat.
  @State private var angle: Double = 0
  @State private var angleDebut: Double?
  @State private var descente: CGFloat = 0
  @State private var sens: Sens?
  @Environment(\.accessibilityReduceMotion) private var reduireAnimations

  private enum Sens { case horizontal, vertical }

  private var style: StyleRarete { StyleRarete(niveau) }
  private var montreLeRecto: Bool { cos(angle * .pi / 180) > 0 }

  var body: some View {
    ZStack {
      Palette.fond.ignoresSafeArea()
      VStack(spacing: 0) {
        entete
        GeometryReader { g in
          let largeur = max(
            1, min(g.size.width - 2 * Espace.xl, (g.size.height - Espace.l) * Gabarit.rapportCarte))
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
  }

  // MARK: En-tête

  private var entete: some View {
    HStack(spacing: Espace.s) {
      BoutonRond(role: .fermer, rendu: .verre, action: fermer)
      Spacer(minLength: 0)
      Button(action: retourner) {
        Image(systemName: "arrow.triangle.2.circlepath")
          .font(Police.taille(18, .bold))
          .foregroundStyle(Palette.encre)
          .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
          .background {
            Circle()
              .fill(.regularMaterial)
              .overlay(Circle().strokeBorder(Palette.encre.opacity(0.12), lineWidth: 0.5))
          }
          .contentShape(Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Retourner la carte")
    }
    .padding(.horizontal, Espace.bord)
  }

  // MARK: Carte

  private var carte: some View {
    let tourne = !reduireAnimations
    return ZStack {
      recto
        .opacity(montreLeRecto ? 1 : 0)
      dos
        .opacity(montreLeRecto ? 0 : 1)
        .rotation3DEffect(.degrees(tourne ? 180 : 0), axis: (x: 0, y: 1, z: 0))
    }
    .rotation3DEffect(.degrees(tourne ? angle : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    .contentShape(Rectangle())
    .onTapGesture { retourner() }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(montreLeRecto ? libelleRecto : "Photo de la prise, \(nomEspece)")
    .accessibilityAddTraits(.isButton)
    .accessibilityHint(montreLeRecto ? "Montre le dos" : "Montre le recto")
  }

  private var libelleRecto: String {
    var morceaux = [nomEspece, style.mot]
    if let t = tailleCm { morceaux.append("\(t) cm") }
    if let detail { morceaux.append(detail) }
    return morceaux.joined(separator: ", ")
  }

  /// Recto : le dessin de `CarteAmiMini` en grand. Tout est mesuré sur la largeur de la carte ; la bande de texte a une hauteur réservée.
  private var recto: some View {
    CarteCadre(style: style, declaree: false) {
      GeometryReader { geo in
        let u = geo.size.width / 100
        VStack(spacing: 0) {
          ZStack {
            LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
            if UIImage(named: imageEspece) != nil {
              Image(imageEspece)
                .resizable()
                .scaledToFit()
                .padding(4 * u)
            }
            if style.aUnReflet {
              RefletHolographique(inclinaison: .zero, fixe: true)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
          bande(u: u)
        }
      }
    }
  }

  private func bande(u: CGFloat) -> some View {
    HStack(spacing: 2 * u) {
      VStack(alignment: .leading, spacing: 0.6 * u) {
        Text(nomEspece)
          .font(Police.taille(7 * u, .heavy))
          .foregroundStyle(Palette.encre)
          .lineLimit(2)
          .minimumScaleFactor(0.5)
          .multilineTextAlignment(.leading)
        if let t = tailleCm {
          Text("\(t) cm")
            .font(Police.taille(4.8 * u, .bold))
            .foregroundStyle(Palette.encreDouce)
            .lineLimit(1)
        }
        if let detail {
          Text(detail)
            .font(Police.taille(3.8 * u, .semibold))
            .foregroundStyle(Palette.encreDouce)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      BadgeRarete(style: style, taille: 11 * u)
    }
    .padding(.horizontal, 5 * u)
    .frame(maxWidth: .infinity)
    .frame(height: 27 * u)
    .background(Palette.surface)
    .clipped()
  }

  /// Dos : la photo seule, plein cadre, aucun texte. Sans photo, le dessin de l'espèce sur le fond de sa rareté.
  private var dos: some View {
    CarteCadre(style: style, declaree: false, fond: Color(carte: 0xE9EDEB)) {
      GeometryReader { geo in
        Group {
          if let photo {
            PhotoVersoEntiere(image: photo)
          } else {
            ZStack {
              LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
              if UIImage(named: imageEspece) != nil {
                Image(imageEspece)
                  .resizable()
                  .scaledToFit()
                  .frame(width: geo.size.width * 0.88)
                  .rotationEffect(.degrees(-12))
              }
            }
          }
        }
        .frame(width: geo.size.width, height: geo.size.height)
        .clipped()
      }
    }
  }

  private func retourner() {
    let cible = ((angle / 180).rounded() + 1) * 180
    withAnimation(reduireAnimations ? .easeInOut(duration: 0.2) : .spring(duration: 0.55)) {
      angle = cible
    }
  }

  // MARK: Geste

  private var glisser: some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { v in
        if sens == nil {
          sens = abs(v.translation.width) >= abs(v.translation.height) ? .horizontal : .vertical
        }
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
        defer {
          sens = nil
          angleDebut = nil
        }
        if sens == .vertical {
          if v.translation.height > 120 || v.predictedEndTranslation.height > 300 {
            fermer()
          } else {
            withAnimation(.spring(duration: 0.35)) { descente = 0 }
          }
        } else if sens == .horizontal {
          if reduireAnimations {
            if abs(v.translation.width) > 60 { retourner() }
            return
          }
          let cible = (angle / 180).rounded() * 180
          withAnimation(.spring(duration: 0.55, bounce: 0.2)) { angle = cible }
        }
      }
  }
}

#if DEBUG
  #Preview("Visionneuse") {
    VisionneuseCarte(
      nomEspece: "Brochet", imageEspece: "brochet", tailleCm: 78, niveau: .rare, photo: nil,
      detail: "Camille · octobre 2026", fermer: {})
  }
#endif
