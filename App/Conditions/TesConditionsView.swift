import SwiftUI
import Core

/// « Mes statistiques » (Pro) : des comptes de ses propres prises, avec leur N, jamais une prédiction.
/// `constats` vient de `tesConditions(sorties:)` de `Core` ; `nil` avant 10 sorties.
struct TesConditionsView: View {
    let constats: [Constat]?
    let sortiesTerminees: Int
    @ObservedObject var marque: StockageMarque

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(AnglaisF.t("Mes statistiques")).font(JetonsConditions.police(.title2)).foregroundStyle(JetonsConditions.encre)
                if let constats {
                    ForEach(constats, id: \.texte) { c in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.texte).font(JetonsConditions.police(.headline)).foregroundStyle(JetonsConditions.encre)
                            Text(AnglaisF.f("sur %lld sorties", c.surSorties)).font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre2)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    MarqueMeteoView(stockage: marque)
                } else {
                    Text(AnglaisF.f("encore %lld sorties", max(10 - sortiesTerminees, 0)))
                        .font(JetonsConditions.police(.title3)).foregroundStyle(JetonsConditions.encre)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("tes-conditions")
    }
}
