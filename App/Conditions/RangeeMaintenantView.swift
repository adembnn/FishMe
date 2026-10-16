import SwiftUI
import Core

/// Une valeur : une icône, un chiffre, un petit libellé. Pas de phrase.
private struct CaseCondition: View {
    let icone: String
    let valeur: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: icone).foregroundStyle(JetonsConditions.accent)
            Text(valeur).font(JetonsConditions.police(.headline)).foregroundStyle(JetonsConditions.encre)
            if let detail { Text(detail).font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// Rangée « maintenant » (E2) : vent, pluie, pression et tendance, aube, crépuscule, fin légale. Tout vient de `Core` ;
/// la direction et les rafales sont lues telles quelles dans la météo brute.
struct RangeeMaintenantView: View {
    let lecture: LectureConditions
    @ObservedObject var marque: StockageMarque

    var body: some View {
        let c = lecture.conditions
        let point = FormatConditions.pointLePlusProche(lecture.meteo, de: c.heure)
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12, alignment: .topLeading)], alignment: .leading, spacing: 14) {
                if let v = c.ventKmh {
                    CaseCondition(icone: "wind", valeur: "\(FormatConditions.nombre(v)) km/h", detail: detailVent(point))
                }
                if let p = c.pluieMm {
                    CaseCondition(icone: "cloud.rain", valeur: "\(FormatConditions.nombre(p, decimales: 1)) mm", detail: nil)
                }
                if let hpa = c.pressionHPa {
                    CaseCondition(icone: "gauge.medium", valeur: FormatConditions.pression(hpa, tendance: c.tendancePressionHPa6h), detail: nil)
                }
                if let a = c.aube { CaseCondition(icone: "sunrise.fill", valeur: FormatConditions.heure(a), detail: nil) }
                if let s = c.crepuscule { CaseCondition(icone: "sunset.fill", valeur: FormatConditions.heure(s), detail: nil) }
                if let f = c.finLegale { CaseCondition(icone: "clock.badge.exclamationmark", valeur: FormatConditions.heure(f), detail: "fin légale") }
            }
            Text(lecture.depuisCache ? "lu à \(FormatConditions.heure(lecture.lueLe)), sans réseau" : "lu à \(FormatConditions.heure(lecture.lueLe))")
                .font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
            MarqueMeteoView(stockage: marque)
        }
        .accessibilityIdentifier("rangee-maintenant")
    }

    private func detailVent(_ p: PointMeteo?) -> String? {
        guard let p else { return nil }
        var morceaux: [String] = []
        if let d = p.directionDeg { morceaux.append(FormatConditions.cardinal(d)) }
        if let r = p.rafalesKmh { morceaux.append("rafales \(FormatConditions.nombre(r))") }
        return morceaux.isEmpty ? nil : morceaux.joined(separator: " · ")
    }
}

/// Rien à montrer sans lecture : jamais un chiffre inventé.
struct RangeeMaintenantVideView: View {
    var body: some View {
        Label("pas de lecture", systemImage: "wifi.slash")
            .font(JetonsConditions.police(.footnote)).foregroundStyle(JetonsConditions.encre2)
            .accessibilityIdentifier("rangee-vide")
    }
}
