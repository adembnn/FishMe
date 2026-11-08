import SwiftUI
import Charts
import Core

/// Courbe de la rivière sur 48 h. Avec une normale du mois : le débit et sa normale ; sans : la hauteur seule.
struct CourbeRiviereView: View {
    let eau: NiveauEau

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let normale = eau.normaleDebitM3s {
                Text(AnglaisF.t("débit (m³/s), normale du mois en pointillé")).font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre2)
                Chart {
                    ForEach(eau.serie48h.filter { $0.debitM3s != nil }, id: \.heure) { m in
                        LineMark(x: .value("heure", m.heure), y: .value("débit", m.debitM3s ?? 0))
                            .foregroundStyle(JetonsConditions.accent)
                    }
                    RuleMark(y: .value("normale", normale))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .foregroundStyle(JetonsConditions.encre2)
                }
            } else {
                Text(AnglaisF.t("hauteur (m) sur 48 h")).font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre2)
                Chart(eau.serie48h.filter { $0.hauteurM != nil }, id: \.heure) { m in
                    LineMark(x: .value("heure", m.heure), y: .value("hauteur", m.hauteurM ?? 0))
                        .foregroundStyle(JetonsConditions.accent)
                }
            }
            Text(AnglaisF.f("%@ · %@ · mesuré à %@", eau.station.nom, FormatConditions.sourceEau(), FormatConditions.heure(eau.heureMesure)))
                .font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
        }
        .frame(minHeight: 220)
        .padding(16)
        .accessibilityIdentifier("courbe-riviere")
    }
}
