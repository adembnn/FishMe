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
        // Positions de la maquette P13-alerte-C, mesurées depuis le haut de l'écran de 844 pt.
        ZStack(alignment: .top) {
            Palette.surface
            // Pastille 84 pt à 140, heure en 120 pt, titre.
            VStack(spacing: 0) {
                Image(systemName: alerte.type == .orage ? "bolt.fill" : "water.waves")
                    .font(Police.taille(42))
                    .foregroundStyle(Palette.alerte)
                    .frame(width: 84, height: 84)
                    .background(Palette.alerteDoux, in: Circle())
                    .accessibilityHidden(true)
                Text(heureAlerte)
                    .font(Police.taille(120, .black).monospacedDigit())
                    .minimumScaleFactor(0.5).lineLimit(1)
                    .foregroundStyle(Palette.alerte)
                    .padding(.top, 36)
                Text(titre).font(Police.titre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                    .padding(.top, 22)
            }
            .padding(.horizontal, Espace.bord)
            .padding(.top, 140)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Explication à 460, côtés 40 ; la source s'ouvre d'un toucher, sous le texte.
            VStack(spacing: 0) {
                Text(explication).font(Police.sousTitre).foregroundStyle(Palette.encre).multilineTextAlignment(.center)
                if sourceOuverte {
                    VStack(spacing: Espace.s) {
                        Text("\(alerte.mesure) · \(alerte.source)")
                            .font(Police.legende).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
                        Button { ouvrir(lien) } label: {
                            Label(AnglaisF.t(alerte.type == .orage ? "Vigilance de Météo-France" : "Vigicrues"), systemImage: "arrow.up.right.square")
                                .font(Police.legende)
                        }
                        .frame(minHeight: Gabarit.zoneTactile)
                        Text(AnglaisF.t("L’alerte officielle fait foi.")).font(Police.legende).foregroundStyle(Palette.encreDouce)
                    }
                    .padding(.top, Espace.m)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 460)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // « Préviens-moi » à 560, côtés 24.
            if let previensMoi {
                InterrupteurPrevienMoi(modele: previensMoi, lecture: lecture)
                    .padding(.horizontal, 24)
                    .padding(.top, 560)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            // « Compris » et la marque, à 40 pt du bas.
            VStack(spacing: 14) {
                Button(AnglaisF.t("Compris")) { fermer() }
                    .buttonStyle(.principal)
                if let marque {
                    MarqueMeteoView(stockage: marque,
                                    libelleLien: AnglaisF.t(alerte.type == .orage ? "Météo-France · Sources" : "Vigicrues · Sources"),
                                    action: { withAnimation { sourceOuverte.toggle() } })
                        .accessibilityHint(AnglaisF.t("Affiche la source de l'alerte"))
                } else {
                    Button { withAnimation { sourceOuverte.toggle() } } label: {
                        Text(AnglaisF.t(alerte.type == .orage ? "Météo-France · Sources" : "Vigicrues · Sources"))
                            .font(Police.taille(13, .heavy)).foregroundStyle(Palette.marine).underline()
                            .frame(minHeight: Gabarit.zoneTactile)
                    }
                    .accessibilityHint(AnglaisF.t("Affiche la source de l'alerte"))
                }
            }
            .padding(.horizontal, Espace.bord)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            // Fermer : rond de 44 pt, fond clair (pas de verre), en haut à droite, à 59 pt du haut.
            Button { fermer() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.encre)
                    .frame(width: Gabarit.zoneTactile, height: Gabarit.zoneTactile)
                    .background(Palette.fond, in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AnglaisF.t("Fermer"))
            .padding(.top, 59).padding(.trailing, Espace.bord)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        .ignoresSafeArea()
        .accessibilityIdentifier("alerte-plein-ecran")
    }

    /// « 18 h » pile, « 18 h 05 » sinon : la maquette montre l'heure sans les minutes quand elles sont à zéro.
    private var heureAlerte: String {
        let m = Calendar.current.component(.minute, from: alerte.heure)
        if m == 0, RegionPersistee.lire() == .france { return "\(Calendar.current.component(.hour, from: alerte.heure)) h" }
        return FormatConditions.heure(alerte.heure)
    }

    private var titre: String {
        switch alerte.type {
        case .orage:
            // Le niveau n'est pas dans `Alerte` : on le lit dans le texte de l'alerte officielle (jamais deviné).
            let texte = alerte.mesure.lowercased()
            for niveau in ["jaune", "orange", "rouge"] where texte.contains(niveau) {
                return AnglaisF.f("Orage, vigilance %@", AnglaisF.bas(niveau.capitalized))
            }
            return AnglaisF.t("Orage")
        case .crue:
            switch lecture?.eau?.vigilance {
            case .jaune: return AnglaisF.t("Crue, vigilance jaune")
            case .orange: return AnglaisF.t("Crue, vigilance orange")
            case .rouge: return AnglaisF.t("Crue, vigilance rouge")
            default: return AnglaisF.t("Alerte crue")
            }
        }
    }

    private var explication: String {
        AnglaisF.t(alerte.type == .orage ? "Range tes cannes en carbone et mets-toi à l’abri." : "Reste loin de l'eau.")
    }

    private var lien: URL { alerte.type == .orage ? LiensVigilance.vigilanceMeteoFrance : LiensVigilance.vigicrues }
}

/// Interrupteur « Préviens-moi » branché sur `PreviensMoiModele.vigilanceActive`.
private struct InterrupteurPrevienMoi: View {
    @ObservedObject var modele: PreviensMoiModele
    let lecture: LectureConditions?

    var body: some View {
        HStack(spacing: Espace.m) {
            Text(AnglaisF.t("Préviens-moi")).font(Police.corps).foregroundStyle(Palette.encre)
            Spacer(minLength: 0)
            Toggle(AnglaisF.t("Préviens-moi"), isOn: $modele.vigilanceActive).labelsHidden().tint(Palette.marine)
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
