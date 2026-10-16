import SwiftUI
import Core

/// Alerte orage ou crue en plein écran (maquette P13-alerte-C). L'alerte officielle fait foi ;
/// l'app affiche l'`Alerte` que `Core` rend, sans rien calculer. Orange permis ici : c'est une alerte.
struct AlerteView: View {
    let alerte: Alerte
    /// « Préviens-moi » : l'interrupteur n'apparaît que si l'appelant fournit le modèle.
    var previensMoi: PreviensMoiModele? = nil
    var lecture: LectureConditions? = nil

    /// Marque Apple Weather sous le bouton ; sans elle, seul le lien des sources est montré.
    var marque: StockageMarque? = nil

    @Environment(\.dismiss) private var fermer
    @Environment(\.openURL) private var ouvrir
    @State private var sourceOuverte = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                BoutonRond(role: .fermer, rendu: .verre)
            }
            .padding(.top, Espace.s)
            GeometryReader { geo in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: Espace.l)
                        Image(systemName: alerte.type == .orage ? "bolt.fill" : "water.waves")
                            .font(Police.taille(40))
                            .foregroundStyle(Palette.alerte)
                            .frame(width: 84, height: 84)
                            .background(Palette.alerteDoux, in: Circle())
                            .accessibilityHidden(true)
                        Text(FormatConditions.heure(alerte.heure))
                            .font(Police.taille(120, .heavy).monospacedDigit())
                            .minimumScaleFactor(0.5).lineLimit(1)
                            .foregroundStyle(Palette.alerte)
                            .padding(.top, 36)
                        Text(titre).font(Police.titre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                            .padding(.top, 22)
                        Spacer(minLength: Espace.xl)
                        Text(explication).font(Police.sousTitre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                            .padding(.horizontal, Espace.xl)
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
                            .padding(.top, Espace.m)
                        }
                        Spacer(minLength: Espace.xl)
                        if let previensMoi {
                            InterrupteurPrevienMoi(modele: previensMoi, lecture: lecture)
                                .padding(.horizontal, Espace.bord)
                        }
                        Spacer(minLength: Espace.l)
                    }
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
                .scrollIndicators(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: Espace.m) {
            Button("Compris") { fermer() }
                .buttonStyle(.principal)
            if let marque {
                MarqueMeteoView(stockage: marque,
                                libelleLien: alerte.type == .orage ? "Météo-France · Sources" : "Vigicrues · Sources",
                                action: { withAnimation { sourceOuverte.toggle() } })
                    .accessibilityHint("Affiche la source de l'alerte")
            } else {
                Button { withAnimation { sourceOuverte.toggle() } } label: {
                    Text(alerte.type == .orage ? "Météo-France · Sources" : "Vigicrues · Sources")
                        .font(Police.legende).foregroundStyle(Palette.marine).underline()
                        .frame(minHeight: Gabarit.zoneTactile)
                }
                .accessibilityHint("Affiche la source de l'alerte")
            }
        }
            .padding(.top, Espace.s)
            .background(Palette.surface)
        }
        .padding(.horizontal, Espace.bord)
        .padding(.bottom, Espace.l)
        .background(Palette.surface.ignoresSafeArea())
        .accessibilityIdentifier("alerte-plein-ecran")
    }

    private var titre: String {
        switch alerte.type {
        case .orage:
            // À brancher : le niveau de vigilance de l'orage (jaune, orange, rouge) n'est pas dans `Alerte`.
            return "Alerte orage"
        case .crue:
            switch lecture?.eau?.vigilance {
            case .jaune: return "Crue, vigilance jaune"
            case .orange: return "Crue, vigilance orange"
            case .rouge: return "Crue, vigilance rouge"
            default: return "Alerte crue"
            }
        }
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
        HStack(spacing: Espace.m) {
            Text("Préviens-moi").font(Police.corps).foregroundStyle(Palette.encre)
            Spacer(minLength: 0)
            Toggle("Préviens-moi", isOn: $modele.vigilanceActive).labelsHidden()
        }
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
