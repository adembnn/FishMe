import Core
import SwiftUI

/// Le menu « Décors » de l'aquarium : trois rangées (Mes décors, En ce moment, Reviennent chaque année),
/// une vignette par skin. Toutes les entrées sont injectées : le contexte (date, abonnement, progression),
/// le choix, la demande du Pro et l'appel de fin de choix (l'hôte y republie le widget).
/// Aucun compte à rebours : une saison close dit « Revient en octobre », jamais un nombre de jours.
struct SkinsGalerieView<Aquarium: View>: View {
  /// L'aquarium plein écran pour un skin, donné par l'hôte (voir `SkinApercuView`).
  let aquarium: (IdentifiantSkin, @escaping () -> Void) -> Aquarium
  let contexte: ContexteSkin
  @Binding var choisi: IdentifiantSkin
  let demanderPro: () -> Void
  let auChangement: (IdentifiantSkin) -> Void
  var fermer: (() -> Void)? = nil
  /// Écarte un skin sans fond, ni illustration ni dessin (jamais de vignette vide). Remplaçable dans les tests.
  // ⚠ à vérifier : valeur par défaut qui nomme une fonction statique isolée au fil principal.
  var imagesPretes: (Skin) -> Bool = { FondSkin.imagesPretes($0) }

  @State private var apercu: Skin?
  @Environment(\.dynamicTypeSize) private var tailleTexte
  @Environment(\.locale) private var locale

  private var rangees: RangeesGalerie {
    rangeesGalerie(dans: contexte, afficher: imagesPretes)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Espace.xl) {
        HStack {
          Text(AquariumTextes.t("Décors", locale))
            .font(Police.grandTitre)
            .foregroundStyle(Palette.encre)
            .accessibilityAddTraits(.isHeader)
          Spacer(minLength: Espace.m)
          if let fermer { BoutonRond(role: .fermer, action: fermer) }
        }
        rangee(AquariumTextes.t("Mes décors", locale), rangees.mesDecors)
        rangee(AquariumTextes.t("En ce moment", locale), rangees.enCeMoment)
        rangee(AquariumTextes.t("Reviennent chaque année", locale), rangees.reviennentChaqueAnnee)
      }
      .padding(.horizontal, Espace.bord)
      .padding(.vertical, Espace.l)
    }
    .scrollIndicators(.hidden)
    .background(Palette.fond.ignoresSafeArea())
    .fullScreenCover(item: $apercu) { skin in
      SkinApercuView(
        aquarium: aquarium, skin: skin, contexte: contexte, choisi: $choisi,
        demanderPro: demanderPro, auChangement: auChangement,
        fermer: { apercu = nil })
    }
  }

  @ViewBuilder
  private func rangee(_ titre: String, _ entrees: [EntreeGalerie]) -> some View {
    if !entrees.isEmpty {
      VStack(alignment: .leading, spacing: Espace.m) {
        Text(titre)
          .font(Police.titre)
          .foregroundStyle(Palette.encre)
          .accessibilityAddTraits(.isHeader)
        if tailleTexte.isAccessibilitySize {
          // Aux très grandes tailles de texte, une colonne : rien n'est coupé, rien ne défile de côté.
          VStack(alignment: .leading, spacing: Espace.m) {
            ForEach(entrees) { vignette($0) }
          }
        } else {
          ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: Espace.m) {
              ForEach(entrees) { vignette($0) }
            }
          }
          .scrollIndicators(.hidden)
        }
      }
    }
  }

  private func vignette(_ entree: EntreeGalerie) -> some View {
    let actuel = choisi == entree.skin.id
    return Button {
      apercu = entree.skin
    } label: {
      VStack(alignment: .leading, spacing: Espace.s) {
        // Illustration du skin, ou décor dessiné en code posé sur le fond d'origine (sans mouvement dans la galerie).
        FondSkinVue(skin: entree.skin.id, format: .petit)
          // ⚠ à vérifier : `frame(width:)` avec un CGFloat? conditionnel ; rendu à AX5 à voir sur l'iPhone.
          .frame(width: tailleTexte.isAccessibilitySize ? nil : 160, height: 120)
          .frame(maxWidth: tailleTexte.isAccessibilitySize ? .infinity : nil)
          .clipShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
          .overlay(alignment: .topTrailing) {
            if actuel {
              Image(systemName: "checkmark.circle.fill")
                .font(Police.sousTitre)
                .foregroundStyle(Palette.ouvert)
                .padding(Espace.s)
                .background(.regularMaterial, in: Circle())
                .padding(Espace.s)
            }
          }
        Text(AquariumTextes.nomSkin(entree.skin, locale: locale))
          .font(Police.sousTitre)
          .foregroundStyle(Palette.encre)
          .fixedSize(horizontal: false, vertical: true)
        Text(
          AquariumTextes.ligneStatut(entree.statut, calendrier: contexte.calendrier, locale: locale)
        )
        .font(Police.legende)
        .foregroundStyle(Palette.encreDouce)
        .fixedSize(horizontal: false, vertical: true)
      }
      .frame(width: tailleTexte.isAccessibilitySize ? nil : 160, alignment: .leading)
      .frame(maxWidth: tailleTexte.isAccessibilitySize ? .infinity : nil, alignment: .leading)
      .frame(minHeight: Gabarit.zoneTactile)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(
      AquariumTextes.accessibilite(
        entree.skin, statut: entree.statut, calendrier: contexte.calendrier, locale: locale)
        + (actuel ? ", " + AquariumTextes.t("Appliqué", locale).lowercased() : "")
    )
    .accessibilityHint(AquariumTextes.t("Ouvre l'aperçu", locale))
    .accessibilityAddTraits(actuel ? .isSelected : [])
  }
}
