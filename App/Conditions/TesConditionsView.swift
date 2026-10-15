import SwiftUI
import Core

/// « Tes conditions » (Pro) : des comptes de ses propres prises, avec leur N, jamais une prédiction.
/// `constats` vient de `tesConditions(sorties:)` de `Core` ; `nil` avant 10 sorties.
struct TesConditionsView: View {
    let constats: [Constat]?
    let sortiesTerminees: Int
    @ObservedObject var marque: StockageMarque

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let constats {
                    ForEach(constats, id: \.texte) { c in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.texte).font(JetonsConditions.police(.headline)).foregroundStyle(JetonsConditions.encre)
                            Text("sur \(c.surSorties) sorties").font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre2)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    MarqueMeteoView(stockage: marque)
                } else {
                    Text("encore \(max(10 - sortiesTerminees, 0)) sorties")
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
