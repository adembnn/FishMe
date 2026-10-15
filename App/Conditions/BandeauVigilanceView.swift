import SwiftUI
import Core

/// Vigilance orage ou crue : gratuite pour tous, jamais derrière le paywall. L'alerte officielle (Météo-France, Vigicrues) fait foi ;
/// l'app n'en calcule aucune, elle affiche l'`Alerte` que `Core` rend.
struct BandeauVigilanceView: View {
    let alerte: Alerte
    @State private var detail = false
    @Environment(\.openURL) private var ouvrir

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { detail.toggle() } label: {
                HStack(spacing: 10) {
                    Image(systemName: alerte.type == .orage ? "cloud.bolt.fill" : "water.waves")
                    Text(titre).font(JetonsConditions.police(.subheadline)).multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: detail ? "chevron.up" : "chevron.down")
                }
                .foregroundStyle(.white)
                .padding(12)
                .background(alerte.type == .orage ? JetonsConditions.haut : JetonsConditions.crue,
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            if detail {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(alerte.mesure) · \(alerte.source) · \(FormatConditions.heure(alerte.heure))")
                        .font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre2)
                    Button { ouvrir(lien) } label: {
                        Label(alerte.type == .orage ? "Vigilance de Météo-France" : "Vigicrues", systemImage: "arrow.up.right.square")
                            .font(JetonsConditions.police(.footnote))
                    }
                    Text("L'alerte officielle fait foi.").font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
                }
            }
        }
        .accessibilityIdentifier("bandeau-vigilance")
    }

    private var titre: String {
        alerte.type == .orage ? "Vigilance orage : range la canne en carbone" : "Vigilance crue : reste loin de l'eau"
    }

    private var lien: URL { alerte.type == .orage ? LiensOfficiels.vigilanceMeteoFrance : LiensOfficiels.vigicrues }
}

/// Une ligne courte pour le bandeau de session (L5), seulement s'il y a la place.
struct LigneConditionsSession: View {
    let lecture: LectureConditions
    @ObservedObject var marque: StockageMarque

    var body: some View {
        let c = lecture.conditions
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                if let v = c.ventKmh { Label("\(FormatConditions.nombre(v)) km/h", systemImage: "wind") }
                if let p = c.pluieMm { Label("\(FormatConditions.nombre(p, decimales: 1)) mm", systemImage: "cloud.rain") }
                if let hpa = c.pressionHPa { Label("\(FormatConditions.nombre(hpa)) hPa", systemImage: "gauge.medium") }
            }
            .font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre)
            MarqueMeteoView(stockage: marque)
        }
        .accessibilityIdentifier("ligne-conditions-session")
    }
}
