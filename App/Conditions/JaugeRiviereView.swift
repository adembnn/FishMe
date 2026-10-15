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
                Label("pas de station de mesure près d'ici", systemImage: "drop.triangle")
                    .font(JetonsConditions.police(.footnote)).foregroundStyle(JetonsConditions.encre2)
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
                    Text(libelle).font(JetonsConditions.police(.headline)).foregroundStyle(couleur)
                }
                if let h = eau.hauteurM {
                    Text("\(FormatConditions.nombre(h, decimales: 2)) m").font(JetonsConditions.police(.headline))
                        .foregroundStyle(JetonsConditions.encre)
                }
                if let q = eau.debitM3s {
                    Text("\(FormatConditions.nombre(q)) m³/s").font(JetonsConditions.police(.subheadline))
                        .foregroundStyle(JetonsConditions.encre2)
                }
            }
            if lecture.conditions.etatRiviere == .inconnu, let debut = eau.serie48h.first?.hauteurM, let h = eau.hauteurM {
                Text("il y a 48 h : \(FormatConditions.nombre(debut, decimales: 2)) m, maintenant : \(FormatConditions.nombre(h, decimales: 2)) m")
                    .font(JetonsConditions.police(.caption)).foregroundStyle(JetonsConditions.encre2)
            }
            Text("\(eau.station.nom) · mesuré à \(FormatConditions.heure(eau.heureMesure))")
                .font(JetonsConditions.police(.caption2)).foregroundStyle(JetonsConditions.encre2)
        }
        .accessibilityElement(children: .combine)
    }

    private var libelle: String? {
        switch lecture.conditions.etatRiviere {
        case .normal: return "normal"
        case .haut: return "haut"
        case .crue: return "crue"
        case .inconnu: return nil
        }
    }

    private var couleur: Color {
        switch lecture.conditions.etatRiviere {
        case .normal: return JetonsConditions.accent
        case .haut: return JetonsConditions.haut
        case .crue: return JetonsConditions.crue
        case .inconnu: return JetonsConditions.encre2
        }
    }
}
