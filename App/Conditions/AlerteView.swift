import SwiftUI
import Core

/// Alerte orage ou crue en plein écran (maquette P13-alerte-C). L'alerte officielle fait foi ;
/// l'app affiche l'`Alerte` que `Core` rend, sans rien calculer. Orange permis ici : c'est une alerte.
struct AlerteView: View {
    let alerte: Alerte
    /// « Préviens-moi » : l'interrupteur n'apparaît que si l'appelant fournit le modèle.
    var previensMoi: PreviensMoiModele? = nil
    var lecture: LectureConditions? = nil

    @Environment(\.dismiss) private var fermer
    @Environment(\.openURL) private var ouvrir
    @State private var sourceOuverte = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { fermer() } label: {
                    Image(systemName: "xmark")
                        .font(Police.sousTitre)
                        .foregroundStyle(Palette.encre)
                        .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                        .background(Palette.fond, in: Circle())
                }
                .accessibilityLabel("Fermer")
            }
            ScrollView {
                VStack(spacing: Espace.l) {
                    Image(systemName: alerte.type == .orage ? "bolt.fill" : "water.waves")
                        .font(Police.taille(40))
                        .foregroundStyle(Palette.alerte)
                        .frame(width: 84, height: 84)
                        .background(Palette.alerteDoux, in: Circle())
                        .accessibilityHidden(true)
                    Text(FormatConditions.heure(alerte.heure))
                        .font(Police.taille(96, .heavy).monospacedDigit())
                        .minimumScaleFactor(0.5).lineLimit(1)
                        .foregroundStyle(Palette.alerte)
                    Text(titre).font(Police.titre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                    Text(explication).font(Police.corps).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                        .padding(.horizontal, Espace.xl)
                    if let previensMoi {
                        InterrupteurPrevienMoi(modele: previensMoi, lecture: lecture)
                            .padding(.horizontal, Espace.l)
                    }
                    if sourceOuverte {
                        VStack(spacing: Espace.s) {
                            Text("\(alerte.mesure) · \(alerte.source)")
                                .font(Police.legende).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
                            Button { ouvrir(lien) } label: {
                                Label(alerte.type == .orage ? "Vigilance de Météo-France" : "Vigicrues", systemImage: "arrow.up.right.square")
                                    .font(Police.legende)
                            }
                            .frame(minHeight: Gabarit.zoneTactile)
                            Text("L'alerte officielle fait foi.").font(Police.legende).foregroundStyle(Palette.encreDouce)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, Espace.xl)
            }
            .scrollIndicators(.hidden)
            VStack(spacing: Espace.m) {
                Button("Compris") { fermer() }
                    .buttonStyle(.principal)
                Button { withAnimation { sourceOuverte.toggle() } } label: {
                    Label(alerte.type == .orage ? "Météo-France · Sources" : "Vigicrues · Sources", systemImage: "info.circle")
                        .font(Police.legende).foregroundStyle(Palette.marine)
                        .frame(minHeight: Gabarit.zoneTactile)
                }
                .accessibilityHint("Affiche la source de l'alerte")
            }
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.l)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityIdentifier("alerte-plein-ecran")
    }

    private var titre: String {
        alerte.type == .orage ? "Orage, vigilance" : "Crue, vigilance"
    }

    private var explication: String {
        alerte.type == .orage ? "Range tes cannes en carbone et mets-toi à l'abri." : "Reste loin de l'eau."
    }

    private var lien: URL { alerte.type == .orage ? LiensVigilance.vigilanceMeteoFrance : LiensVigilance.vigicrues }
}

/// Interrupteur « Préviens-moi » branché sur `PreviensMoiModele.vigilanceActive`.
private struct InterrupteurPrevienMoi: View {
    @ObservedObject var modele: PreviensMoiModele
    let lecture: LectureConditions?

    var body: some View {
        Toggle("Préviens-moi", isOn: $modele.vigilanceActive)
            .font(Police.corps)
            .frame(minHeight: Gabarit.zoneTactile)
            .onChange(of: modele.vigilanceActive) { _, _ in
                Task {
                    _ = await modele.assurerPermission()
                    await modele.reprogrammer(avec: lecture)
                }
            }
            .accessibilityIdentifier("alerte-previens-moi")
    }
}
