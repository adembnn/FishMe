import SwiftUI
import Core

/// Conditions de la prise, au dos de la carte (L4) : l'instantané relevé à la prise, avec son heure et la marque Apple Weather.
/// `pourPartage` : l'image partagée de L9 n'a jamais ce bloc.
struct BlocConditionsPriseView: View {
    let conditions: Conditions?
    var pourPartage = false
    @ObservedObject var marque: StockageMarque

    var body: some View {
        if !pourPartage, let c = conditions {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    if let v = c.ventKmh { Label(FormatConditions.vent(kmh: v), systemImage: "wind") }
                    if let p = c.pluieMm { Label(FormatConditions.pluie(mm: p), systemImage: "cloud.rain") }
                    if let hpa = c.pressionHPa {
                        Label(FormatConditions.pression(hpa, tendance: c.tendancePressionHPa6h), systemImage: "gauge.medium")
                    }
                }
                .font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre)
                Text(AnglaisF.f("relevé à %@", FormatConditions.heure(c.heure))).font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
                MarqueMeteoView(stockage: marque)
            }
            .accessibilityIdentifier("conditions-prise")
        }
    }
}
