import Core
import SwiftUI

/// Les numéros d'urgence : 112, 18 et 15 en gros boutons, 17 et 114 derrière « Autres numéros ».
/// Chaque bouton ouvre un lien `tel:` : l'iPhone demande de confirmer avant d'appeler.
/// Aucun conseil médical, aucune promesse de délai, aucune position envoyée.
struct NumerosUtilesView: View {
    @State private var autresOuverts = false
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text(AnglaisE.t(TextesMaFederation.numerosTitre, locale))
                .font(Police.sousTitre).foregroundStyle(Palette.encre)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: Espace.s) {
                ForEach(NumerosUtiles.principaux) { numero in
                    BoutonNumero(numero: numero, gros: true)
                }
            }

            DisclosureGroup(AnglaisE.t(TextesMaFederation.autresNumeros, locale), isExpanded: $autresOuverts) {
                VStack(spacing: Espace.s) {
                    ForEach(NumerosUtiles.autres) { numero in
                        BoutonNumero(numero: numero, gros: false)
                    }
                }
                .padding(.top, Espace.s)
            }
            .font(Police.corps)
            .foregroundStyle(Palette.encre)
            .frame(minHeight: Gabarit.zoneTactile)
            .accessibilityIdentifier("numeros-autres")

            Link(destination: NumerosUtiles.sourceURL) {
                Text(TextesMaFederation.sourceNumeros(JourLocalise.texte(NumerosUtiles.releveLe, locale), locale: locale))
                    .font(Police.legende)
                    .foregroundStyle(Palette.marine)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: Gabarit.zoneTactile, alignment: .leading)
            }
            .accessibilityHint(AnglaisE.t(TextesMaFederation.ouvreSafari, locale))
        }
        .accessibilityIdentifier("numeros-utiles")
    }
}

private struct BoutonNumero: View {
    let numero: NumeroUtile
    let gros: Bool
    @Environment(\.locale) private var locale

    var body: some View {
        if let lien = numero.lienTelephone {
            Link(destination: lien) {
                HStack(spacing: Espace.m) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .accessibilityHidden(true)
                    Text(numero.numero)
                        .font(gros ? Police.chiffreMoyen : Police.sousTitre)
                    Text(AnglaisE.t(numero.libelle, locale))
                        .font(Police.detail)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(gros ? Palette.surMarine : Palette.marine)
                .padding(.horizontal, Espace.l)
                .padding(.vertical, Espace.s)
                .frame(maxWidth: .infinity, minHeight: Gabarit.bouton, alignment: .leading)
                .background(gros ? Palette.marine : Palette.marineDoux,
                            in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
            .accessibilityLabel(AnglaisE.f("Appeler le %@, %@", locale, numero.numero, AnglaisE.t(numero.libelle, locale)))
            .accessibilityHint(AnglaisE.t("Demande une confirmation avant d'appeler", locale))
            .accessibilityIdentifier("numero-\(numero.numero)")
        }
    }
}
