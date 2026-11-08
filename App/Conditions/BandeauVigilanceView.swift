import SwiftUI
import Core

/// Vigilance orage ou crue : gratuite pour tous, jamais derrière le paywall. L'alerte officielle (Météo-France, Vigicrues) fait foi ;
/// l'app n'en calcule aucune, elle affiche l'`Alerte` que `Core` rend.
struct BandeauVigilanceView: View {
    let alerte: Alerte
    /// Facultatifs : sans eux, l'écran d'alerte n'a pas l'interrupteur « Préviens-moi ».
    var previensMoi: PreviensMoiModele? = nil
    var lecture: LectureConditions? = nil
    /// Marque Apple Weather de l'écran d'alerte (facultative).
    var marque: StockageMarque? = nil
    @State private var detail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { detail = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: alerte.type == .orage ? "cloud.bolt.fill" : "water.waves")
                    Text(titre).font(Police.detail).foregroundStyle(Palette.encre).multilineTextAlignment(.leading)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Palette.alerte)
                .padding(Espace.m)
                .frame(minHeight: Gabarit.zoneTactile)
                .background(Palette.alerteDoux, in: RoundedRectangle(cornerRadius: Rayon.m, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .fullScreenCover(isPresented: $detail) {
            AlerteView(alerte: alerte, previensMoi: previensMoi, lecture: lecture, marque: marque)
        }
        .accessibilityIdentifier("bandeau-vigilance")
    }

    private var titre: String {
        AnglaisF.t(alerte.type == .orage ? "Vigilance orage : range la canne en carbone" : "Vigilance crue : reste loin de l'eau")
    }
}

/// Une ligne courte pour le bandeau de session (L5), seulement s'il y a la place.
struct LigneConditionsSession: View {
    let lecture: LectureConditions
    @ObservedObject var marque: StockageMarque

    var body: some View {
        let c = lecture.conditions
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                if let v = c.ventKmh { Label(FormatConditions.vent(kmh: v), systemImage: "wind") }
                if let p = c.pluieMm { Label(FormatConditions.pluie(mm: p), systemImage: "cloud.rain") }
                if let hpa = c.pressionHPa { Label(FormatConditions.pression(hPa: hpa), systemImage: "gauge.medium") }
            }
            .font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre)
            MarqueMeteoView(stockage: marque)
        }
        .accessibilityIdentifier("ligne-conditions-session")
    }
}
