import SwiftUI
import Core

/// 7 jours, heure par heure, les mêmes icônes que la rangée. Chiffres prévus, chacun avec l'heure de lecture ; aucune note.
struct SeptJoursView: View {
    let lecture: LectureConditions
    @ObservedObject var marque: StockageMarque

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(jours, id: \.debut) { jour in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(FormatConditions.jour(jour.debut)).font(JetonsConditions.police(.headline))
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 14) {
                                ForEach(jour.heures, id: \.heure) { h in
                                    VStack(spacing: 3) {
                                        Text(FormatConditions.heure(h.heure)).font(JetonsConditions.police(.caption2))
                                        Image(systemName: FormatConditions.symbole(codeTemps: h.codeTemps)).foregroundStyle(JetonsConditions.accent)
                                        Text("\(FormatConditions.nombre(h.temperatureC)) °").font(JetonsConditions.police(.caption))
                                        Text("\(FormatConditions.nombre(h.ventKmh)) km/h").font(JetonsConditions.police(.caption2))
                                        Text("\(FormatConditions.nombre(h.pluieMm, decimales: 1)) mm").font(JetonsConditions.police(.caption2))
                                    }
                                    .foregroundStyle(JetonsConditions.encre)
                                    .accessibilityElement(children: .combine)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                Text("prévu, prévision lue \(FormatConditions.jourHeure(lecture.lueLe))")
                    .font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
                MarqueMeteoView(stockage: marque)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("sept-jours")
    }

    private struct JourHeures { var debut: Date; var heures: [PointMeteo] }

    /// Regroupement par jour calendaire : de la mise en page, pas du calcul. La journée en cours d'abord.
    private var jours: [JourHeures] {
        let cal = Calendar.current
        let futures = lecture.meteo.heures.filter { $0.heure >= lecture.lueLe.addingTimeInterval(-3600) }
        let groupes = Dictionary(grouping: futures) { cal.startOfDay(for: $0.heure) }
        return groupes.keys.sorted().prefix(7).map { JourHeures(debut: $0, heures: groupes[$0]!.sorted { $0.heure < $1.heure }) }
    }
}
