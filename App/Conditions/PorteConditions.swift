import SwiftUI
import Core

/// Ce que A passe aux vues : le verdict de `peutUtiliser` de `Core` et l'action qui ouvre le paywall de L6.
struct PorteConditions {
    /// `peutUtiliser(fonction, abonne:, surSonSpot:)` de `Core`, déjà résolu par A.
    var autorise: (FonctionPro) -> Bool
    /// Ouvre le paywall contextuel de L6 avec le nom de la fonction (E7).
    var ouvrirPaywall: (FonctionPro) -> Void

    static var toutOuvert: PorteConditions { PorteConditions(autorise: { _ in true }, ouvrirPaywall: { _ in }) }
}

/// Une fonction Pro fermée : un toucher appelle le paywall au lieu d'ouvrir la vue.
struct VerrouPro: View {
    let fonction: FonctionPro
    let titre: String
    let icone: String
    let porte: PorteConditions

    var body: some View {
        Button { porte.ouvrirPaywall(fonction) } label: {
            Label(titre, systemImage: icone)
                .font(JetonsConditions.police(.body))
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .trailing) { Image(systemName: "lock.fill").foregroundStyle(JetonsConditions.encre2) }
        }
        .buttonStyle(.plain)
        .accessibilityHint(AnglaisF.t("Fonction Pro"))
    }
}
