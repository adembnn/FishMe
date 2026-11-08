import Core
import SwiftUI

/// L'aquarium plein écran avec le skin choisi (le même `AquariumView`, les poissons du pêcheur nagent), un bandeau bas
/// « Aperçu » avec un seul bouton, et la croix « Fermer » de l'aquarium. Toute personne peut ouvrir l'aperçu d'un
/// skin Pro ; « Appliquer avec Pro » ouvre l'offre Pro (`demanderPro`) sans changer le choix.
/// « Réduire les animations » : `AquariumView` reste immobile, rien n'est ajouté ici qui bouge.
struct SkinApercuView<Aquarium: View>: View {
  @Environment(\.locale) private var locale
  /// L'aquarium plein écran pour un skin, donné par l'hôte : `{ skin, fermer in AquariumView(modele: m, fermer: fermer, skin: skin) }`.
  // ⚠ à vérifier : fermeture `@escaping` dans un type générique, et `.fullScreenCover` qui la capture (galerie).
  let aquarium: (IdentifiantSkin, @escaping () -> Void) -> Aquarium
  let skin: Skin
  let contexte: ContexteSkin
  @Binding var choisi: IdentifiantSkin
  let demanderPro: () -> Void
  let auChangement: (IdentifiantSkin) -> Void
  let fermer: () -> Void

  var body: some View {
    let etat = statut(skin, dans: contexte)
    ZStack(alignment: .bottom) {
      aquarium(skin.id, fermer)
      bandeau(etat)
    }
    .ignoresSafeArea()
  }

  private func bandeau(_ etat: StatutSkin) -> some View {
    VStack(alignment: .leading, spacing: Espace.s) {
      Text(AquariumTextes.t("Aperçu", locale))
        .font(Police.legende)
        .foregroundStyle(Palette.encreDouce)
      Text(AquariumTextes.nomSkin(skin, locale: locale))
        .font(Police.titre)
        .foregroundStyle(Palette.encre)
        .fixedSize(horizontal: false, vertical: true)
      if let titre = AquariumTextes.boutonAppliquer(etat, locale: locale) {
        if choisi == skin.id {
          Label(AquariumTextes.t("Appliqué", locale), systemImage: "checkmark.circle.fill")
            .font(Police.corps)
            .foregroundStyle(Palette.ouvert)
            .frame(minHeight: Gabarit.zoneTactile)
        } else {
          Button(titre) {
            ApplicationSkin.appliquer(
              skin, contexte: contexte, choisi: $choisi,
              demanderPro: demanderPro, auChangement: auChangement)
          }
          .buttonStyle(.principal)
          .accessibilityHint(
            etat == .disponible
              ? AquariumTextes.t("Applique ce décor à ton aquarium et au widget", locale)
              : AquariumTextes.t("Ouvre l'offre Pro", locale))
        }
      } else {
        Text(AquariumTextes.ligneStatut(etat, calendrier: contexte.calendrier, locale: locale))
          .font(Police.corps)
          .foregroundStyle(Palette.encre)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(Espace.l)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Rayon.l, style: .continuous))
    .padding(.horizontal, Espace.l)
    .padding(.bottom, Espace.xl)
    .accessibilityElement(children: .contain)
  }
}
