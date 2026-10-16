import Core
import SwiftUI
import UIKit

/// Une carte vue dans un club, au même dessin que les vignettes du classeur (fond de rareté, nom, badge) :
/// le poisson sur son fond, puis une bande avec le nom de l'espèce et le badge de rareté.
struct VignetteCarteClub: View {
  let image: String
  let nom: String
  let niveau: NiveauRarete
  /// Les cartes d'exemple portent l'étiquette « Exemple ».
  var exemple = false

  var body: some View {
    let style = StyleRarete(niveau)
    let forme = RoundedRectangle(cornerRadius: Rayon.s, style: .continuous)
    Color.clear
      .aspectRatio(Gabarit.rapportCarte, contentMode: .fit)
      .overlay {
        VStack(spacing: 0) {
          ZStack(alignment: .topTrailing) {
            LinearGradient(colors: style.fond, startPoint: .top, endPoint: .bottom)
            Image(image)
              .resizable().scaledToFit()
              .padding(Espace.xs)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
            if exemple {
              Text("Exemple")
                .font(Police.taille(11, .heavy))
                .foregroundStyle(Palette.encre)
                .padding(.horizontal, 7)
                .frame(height: 18)
                .background(Palette.surface, in: Capsule())
                .padding(5)
            }
          }
          .frame(maxHeight: .infinity)
          HStack(spacing: Espace.xs) {
            Text(nom)
              .font(Police.taille(13, .heavy))
              .foregroundStyle(Palette.encre)
              .lineLimit(1)
              .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            BadgeRarete(style: style, taille: 16)
          }
          .padding(.horizontal, Espace.s)
          .frame(height: 34)
          .background(Palette.tuile)
        }
      }
      .clipShape(forme)
      .overlay(forme.strokeBorder(Palette.filet, lineWidth: 1))
      .shadow(color: Palette.encre.opacity(0.14), radius: 5, y: 3)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("\(nom), \(style.mot)\(exemple ? ", exemple" : "")")
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
                        .font(.system(size: 24, weight: .bold, design: .rounded))
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
