import Core
import SwiftUI
import UIKit

/// Une prise du classeur : la version réduite fidèle du recto de la vraie carte (même dessin d'espèce sur le fond de sa rareté,
/// même cadre, même plaque, même nom, taille et badge). Pas de photo : elle n'apparaît qu'au verso de la carte ouverte.
/// C'est `CarteRectoView` en pleine taille de référence (300 pt de large), réduite à la largeur de la cellule.
struct VignetteCarteObtenue: View {
  let emplacement: Emplacement
  /// Département de la collection, quand la prise n'en donne pas.
  let zone: Departement?

  /// Largeur de référence de la carte dessinée avant réduction.
  private static let largeurReference: CGFloat = 300

  var body: some View {
    GeometryReader { geo in
      let reduction = geo.size.width / Self.largeurReference
      if let infos = InfosCarte.vignette(emplacement: emplacement, zone: zone) {
        CarteRectoView(infos: infos, refletFixe: true)
          .frame(width: Self.largeurReference, height: Self.largeurReference / Gabarit.rapportCarte)
          .scaleEffect(reduction, anchor: .topLeading)
          .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
          // Rendu aplati une fois à la taille finale : le défilement ne redessine plus ombres, dégradés et textes de chaque carte.
          .drawingGroup()
      }
    }
    .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
    // La vignette est le libellé d'un Button : elle doit recevoir le toucher (sinon plus aucune carte ne s'ouvre).
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }
}

/// Un emplacement « à trouver » : un fond clair de carton, un trait en pointillé, la silhouette de l'espèce en teinte douce
/// et son nom en légende. Rien de plein ni de sombre : l'envie de compléter la collection.
struct EmplacementATrouver: View {
  let emplacement: Emplacement
  @Environment(\.locale) private var locale
  private var t: AnglaisD { AnglaisD(locale) }

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
    .accessibilityLabel(t("%@, pas encore pris", espece.nom))
  }
}
