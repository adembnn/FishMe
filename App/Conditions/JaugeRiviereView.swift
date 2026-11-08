import SwiftUI
import Core

/// Jauge de la rivière : « normal », « haut » ou « crue » (de `lireConditions`), la station Hub'Eau et l'heure de la mesure.
/// Station sans normale : la hauteur et ses valeurs sur 48 h, jamais « normal » ni « haut ».
struct JaugeRiviereView: View {
    let lecture: LectureConditions
    /// Un toucher ouvre la courbe de 48 h (Pro : A passe la porte).
    var ouvrirCourbe: () -> Void = {}

    var body: some View {
        Button(action: ouvrirCourbe) {
            if let eau = lecture.eau {
                contenu(eau)
            } else {
                Label(AnglaisF.t("pas de station de mesure près d'ici"), systemImage: "drop.triangle")
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("jauge-riviere")
    }

    @ViewBuilder private func contenu(_ eau: NiveauEau) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "water.waves").foregroundStyle(couleur)
                if let libelle {
                    Text(libelle).font(Police.sousTitre).foregroundStyle(couleur)
                }
                if let h = eau.hauteurM {
                    Text(FormatConditions.hauteurEau(metres: h)).font(Police.chiffreMoyen)
                        .foregroundStyle(Palette.encre)
                }
                if let q = eau.debitM3s {
                    Text(FormatConditions.debitEau(m3s: q)).font(Police.legende)
                        .foregroundStyle(Palette.encreDouce)
                }
            }
            if lecture.conditions.etatRiviere == .inconnu, let debut = eau.serie48h.first?.hauteurM, let h = eau.hauteurM {
                Text(AnglaisF.f("il y a 48 h : %@, maintenant : %@", FormatConditions.hauteurEau(metres: debut), FormatConditions.hauteurEau(metres: h)))
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
            }
            Text(AnglaisF.f("%@ · mesuré à %@", eau.station.nom, FormatConditions.heure(eau.heureMesure)))
                .font(Police.legende).foregroundStyle(Palette.encreDouce)
        }
        .accessibilityElement(children: .combine)
    }

    private var libelle: String? {
        switch lecture.conditions.etatRiviere {
        case .normal: return AnglaisF.bas("Normal")
        case .haut: return AnglaisF.bas("Haut")
        case .crue: return AnglaisF.bas("Crue")
        case .inconnu: return nil
        }
    }

    private var couleur: Color {
        switch lecture.conditions.etatRiviere {
        case .normal: return Palette.marine
        case .haut: return Palette.alerte
        case .crue: return Palette.alerte
        case .inconnu: return Palette.encreDouce
        }
    }
}
