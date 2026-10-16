import Core
import SwiftUI
import UIKit

/// Les vraies photos de pêche embarquées pour la démo (`App/Demo/Photos/<espece>-<n>.jpg`), lues dans le bundle de l'app.
/// Fichier absent : `nil`, et la carte retombe sur l'image de l'espèce.
@MainActor
enum PhotoDemoClub {
  private static let memoire = NSCache<NSString, UIImage>()

  static func image(_ nom: String?, bundle: Bundle = .main) -> UIImage? {
    guard let nom, !nom.isEmpty else { return nil }
    let base = nom.hasSuffix(".jpg") ? String(nom.dropLast(4)) : nom
    if let connue = memoire.object(forKey: base as NSString) { return connue }
    for dossier in [nil, "Photos", "Demo/Photos", "Demo"] as [String?] {
      if let url = bundle.url(forResource: base, withExtension: "jpg", subdirectory: dossier),
        let image = UIImage(contentsOfFile: url.path)
      {
        memoire.setObject(image, forKey: base as NSString)
        return image
      }
    }
    return nil
  }
}

/// Une carte vue dans un club, au même dessin que les vignettes du classeur (fond de rareté, nom, badge).
/// Hauteur fixe : le dessin (photo ou poisson) occupe le haut, une bande de hauteur fixe sous l'image porte
/// le nom de l'espèce, la taille et le badge de rareté. Aucun texte ne passe sur le dessin, même avec un nom très long
/// ou du texte agrandi (les polices de la carte ont une taille fixe, comme dans le Pescedex).
struct VignetteCarteClub: View {
  let image: String
  let nom: String
  let niveau: NiveauRarete
  var tailleCm: Int? = nil
  /// Nom du fichier de la vraie photo (sans « .jpg »), s'il y en a une.
  var photo: String? = nil

  /// Hauteur de la zone réservée sous l'image.
  private static let hauteurBande: CGFloat = 46

  var body: some View {
    let style = StyleRarete(niveau)
    CarteCadre(style: style, declaree: false) {
      VStack(spacing: 0) {
        ZStack {
          LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
          if let vraie = PhotoDemoClub.image(photo) {
            Color.clear
              .overlay { Image(uiImage: vraie).resizable().scaledToFill() }
              .clipped()
          } else {
            Image(image)
              .resizable().scaledToFit()
              .padding(Espace.xs)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
        }
        .frame(maxHeight: .infinity)
        .clipped()
        HStack(spacing: Espace.xs) {
          VStack(alignment: .leading, spacing: 1) {
            Text(nom)
              .font(Police.taille(12, .heavy))
              .foregroundStyle(Palette.encre)
              .lineLimit(2)
              .multilineTextAlignment(.leading)
            if let tailleCm {
              Text("\(tailleCm) cm")
                .font(Police.taille(11, .bold).monospacedDigit())
                .foregroundStyle(Palette.encreDouce)
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
          BadgeRarete(style: style, taille: 16)
        }
        .padding(.horizontal, Espace.s)
        .frame(maxWidth: .infinity)
        .frame(height: Self.hauteurBande)
        .background(Palette.tuile)
        .clipped()
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(nom)\(tailleCm.map { ", \($0) cm" } ?? ""), \(style.mot)")
  }
}

/// Une de MES cartes (l'image déjà rendue par le Pescedex), au format d'une carte.
struct VignetteMaCarteClub: View {
  let carte: CarteAPartager

  var body: some View {
    let forme = RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
    Color.clear
      .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
      .overlay {
        if let image = UIImage(data: carte.png) {
          Image(uiImage: image).resizable().scaledToFill()
        } else {
          Palette.tuile
        }
      }
      .clipShape(forme)
      .overlay(forme.strokeBorder(Palette.filet, lineWidth: 1))
      .shadow(color: Palette.encre.opacity(0.14), radius: 5, y: 3)
      .accessibilityLabel(carte.titre)
  }
}

/// Feuille « Partager une carte au club » : la liste de mes cartes ; toucher une carte la partage ou la retire.
/// Rien n'est envoyé sur un serveur dans cette version : le choix reste sur cet iPhone.
struct PartagerCarteClubView: View {
  let club: ClubLocal
  let cartes: [CarteAPartager]
  let partagees: Set<String>
  let basculer: (String) -> Void

  @Environment(\.dismiss) private var fermer
  private let colonnes = [GridItem(.flexible(), spacing: Espace.m), GridItem(.flexible(), spacing: Espace.m)]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: Espace.m) {
          Text("Visible par les membres de ton club. Touche une carte pour la partager ou la retirer.")
            .font(Police.legende).foregroundStyle(Palette.encreDouce)
          if cartes.isEmpty {
            Text("Tu n'as pas encore de carte. Photographie une prise : elle apparaîtra ici.")
              .font(Police.corps).foregroundStyle(Palette.encreDouce)
              .padding(.top, Espace.m)
          } else {
            LazyVGrid(columns: colonnes, spacing: Espace.m) {
              ForEach(cartes) { carte in
                let choisie = partagees.contains(carte.id)
                Button {
                  basculer(carte.id)
                } label: {
                  VignetteMaCarteClub(carte: carte)
                    .overlay(alignment: .topTrailing) {
                      Image(systemName: choisie ? "checkmark.circle.fill" : "circle")
                        .font(Police.taille(24))
                        .foregroundStyle(choisie ? Palette.marine : Palette.silhouette)
                        .background(Circle().fill(Palette.surface).padding(2))
                        .padding(6)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(carte.titre)
                .accessibilityValue(choisie ? "partagée avec le club" : "non partagée")
                .accessibilityAddTraits(choisie ? .isSelected : [])
              }
            }
          }
          Text("Rien n'est envoyé sur un serveur dans cette version : le partage reste sur ton iPhone.")
            .font(Police.legende).foregroundStyle(Palette.encreDouce)
            .padding(.top, Espace.s)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.xl)
      }
      .scrollIndicators(.hidden)
      .font(Police.corps)
      .foregroundStyle(Palette.encre)
      .background(Palette.fond.ignoresSafeArea())
      .navigationTitle("Partager une carte")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Terminé") { fermer() }
        }
      }
    }
    .tint(Palette.marine)
    .presentationDetents([.large])
  }
}
