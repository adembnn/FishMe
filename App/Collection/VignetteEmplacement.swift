import Core
import SwiftUI
import UIKit

/// Encre et gris d'une carte (mêmes valeurs que CarteRectoView, qui les garde privées).
private let encreVignette = Color(carte: 0x0F1A1C)
private let grisVignette = Color(carte: 0x5B6A6E)

/// Une prise du classeur, montrée face visible comme une vraie carte à collectionner (69/100) :
/// la photo de la prise dans une fenêtre aux couleurs de la rareté, puis une plaque réservée au nom et à la taille.
/// Le texte ne passe jamais sur l'image. Sans photo (carte déclarée), le poisson dessiné remplace la photo.
struct VignetteCarteObtenue: View {
  let emplacement: Emplacement
  /// Rend la photo de la prise (le dépôt de cartes). `nil` ou sans résultat : le poisson dessiné.
  let photoDe: (Prise) async -> Data?

  @State private var photo: UIImage?

  private var style: StyleRarete { StyleRarete(emplacement.rarete.niveau) }
  private var declaree: Bool { emplacement.carte?.estDeclaree == true }
  private var nom: String { emplacement.espece.nom }

  var body: some View {
    CarteCadre(style: style, declaree: declaree) {
      GeometryReader { geo in
        let w = geo.size.width
        let h = geo.size.height
        let u = w / 100
        VStack(spacing: 0) {
          fenetre(u)
            .frame(width: w - 8 * u, height: h * 0.70 - 4 * u)
            .clipShape(RoundedRectangle(cornerRadius: 3.4 * u, style: .continuous))
            .padding(.top, 4 * u)
          plaque(u)
            .frame(width: w, height: h * 0.30 - 0.0)
        }
        .frame(width: w, height: h, alignment: .top)
      }
    }
    .task(id: emplacement.carte?.id) {
      guard let carte = emplacement.carte, !declaree, let donnees = await photoDe(carte),
        let image = UIImage(data: donnees)
      else { return }
      photo =
        await image.byPreparingThumbnail(
          ofSize: CGSize(width: 480, height: 480 * image.size.height / max(1, image.size.width)))
        ?? image
    }
  }

  // MARK: Fenêtre

  private func fenetre(_ u: CGFloat) -> some View {
    ZStack {
      fondFenetre
      if let photo {
        Image(uiImage: photo)
          .resizable()
          .scaledToFill()
      } else {
        Image(emplacement.espece.image)
          .resizable()
          .scaledToFit()
          .saturation(declaree ? 0.55 : 1)
          .padding(.horizontal, 6 * u)
          .rotationEffect(.degrees(-12))
          .shadow(color: .black.opacity(0.3), radius: 1 * u, x: -1 * u, y: 2 * u)
      }
      if style.aUnReflet && !declaree {
        RefletHolographique(inclinaison: .zero, fixe: true)
      }
    }
    .overlay(alignment: .topTrailing) {
      BadgeRarete(style: style, taille: 15 * u)
        .padding(3 * u)
        .shadow(color: .black.opacity(0.3), radius: 1.5 * u, y: 1 * u)
    }
    .overlay(alignment: .topLeading) {
      if declaree {
        Text("Déclarée")
          .font(Police.taille(6.5 * u, .heavy))
          .foregroundStyle(.white)
          .lineLimit(1)
          .padding(.horizontal, 2.6 * u)
          .padding(.vertical, 1.2 * u)
          .background(Color.black.opacity(0.5), in: Capsule())
          .padding(3 * u)
      }
    }
    .accessibilityHidden(true)
  }

  @ViewBuilder
  private var fondFenetre: some View {
    let fond = style.fond
    LinearGradient(colors: fond, startPoint: .top, endPoint: .bottom)
  }

  // MARK: Plaque

  private func plaque(_ u: CGFloat) -> some View {
    VStack(spacing: 1.2 * u) {
      Text(nom)
        .font(Police.taille(8.6 * u, .heavy))
        .foregroundStyle(encreVignette)
        .lineLimit(2)
        .minimumScaleFactor(0.55)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 1.6 * u) {
        MarqueRarete(style: style, taille: 7.5 * u)
        Text(ligneBasse)
          .font(Police.taille(6.8 * u, .bold))
          .foregroundStyle(style == .legendaire ? Color(carte: 0x7A5410) : grisVignette)
          .lineLimit(1)
          .minimumScaleFactor(0.6)
      }
    }
    .padding(.horizontal, 5 * u)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  /// « 62 cm · rare », ou le seul palier pour une carte déclarée ou sans taille.
  private var ligneBasse: String {
    let palier = style.mot
    guard !declaree, let carte = emplacement.carte, let t = Formats.taille(carte) else {
      return palier
    }
    return "\(t) · \(palier)"
  }
}

/// Un emplacement « à trouver » : un fond clair de carton, un trait en pointillé, la silhouette de l'espèce en teinte douce
/// et son nom en légende. Rien de plein ni de sombre : l'envie de compléter la collection.
struct EmplacementATrouver: View {
  let emplacement: Emplacement

  private var style: StyleRarete { StyleRarete(emplacement.rarete.niveau) }
  private var espece: EspecePechable { emplacement.espece }

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      let h = geo.size.height
      let u = w / 100
      let forme = RoundedRectangle(cornerRadius: Gabarit.coinCarte * w, style: .continuous)
      let rapport: CGFloat = {
        guard let image = UIImage(named: espece.image), image.size.height > 0 else { return 2.8 }
        return image.size.width / image.size.height
      }()
      ZStack {
        forme.fill(Palette.surface)
        forme.fill(Palette.tuile.opacity(0.45))
        forme.strokeBorder(Palette.silhouette, style: StrokeStyle(lineWidth: 1.4, dash: [5, 4]))
        VStack(spacing: 0) {
          Spacer(minLength: 0)
          Image(espece.image)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .foregroundStyle(Palette.silhouette)
            .frame(width: w * 0.72, height: w * 0.72 / rapport)
            .rotationEffect(.degrees(-12))
            .accessibilityHidden(true)
          Spacer(minLength: 0)
          Text(espece.nom)
            .font(Police.taille(8.2 * u, .bold))
            .foregroundStyle(Palette.encreDouce)
            .lineLimit(2)
            .minimumScaleFactor(0.55)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 6 * u)
            .frame(height: h * 0.22, alignment: .top)
        }
        .padding(.top, 8 * u)
      }
      .overlay(alignment: .topTrailing) {
        if style != .nonMesuree && emplacement.releveeDansLaZone {
          MarqueRarete(style: style, taille: 11 * u)
            .opacity(0.8)
            .padding(5 * u)
        }
      }
      .frame(width: w, height: h)
    }
    .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(espece.nom), pas encore pris")
  }
}
