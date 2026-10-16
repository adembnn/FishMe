import SwiftUI
import Core

/// Prévisions horaires : une bande qui défile (heure, icône, température).
struct CarteHoraireView: View {
    let lecture: LectureConditions
    let maintenant: Date

    var body: some View {
        let points = lecture.meteo.heures
            .filter { $0.heure >= maintenant.addingTimeInterval(-1800) }
            .sorted { $0.heure < $1.heure }
            .prefix(24)
        CarteVitree(titre: "Prévisions horaires", icone: "clock") {
            ScrollView(.horizontal) {
                HStack(spacing: Espace.l) {
                    ForEach(Array(points.enumerated()), id: \.element.heure) { i, p in
                        let nuit = StyleMeteo.estNuit(p.heure, conditions: lecture.conditions)
                        VStack(spacing: Espace.s) {
                            Text(i == 0 ? "Auj." : StyleMeteo.heureCourte(p.heure))
                                .font(.system(.subheadline, weight: .medium))
                            Image(systemName: StyleMeteo.symbole(codeTemps: p.codeTemps, nuit: nuit))
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 24))
                                .frame(height: 30)
                            Text("\(FormatConditions.nombre(p.temperatureC))°")
                                .font(.system(.body, weight: .semibold)).monospacedDigit()
                        }
                        .foregroundStyle(.white)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(StyleMeteo.heureCourte(p.heure)), \(StyleMeteo.libelle(codeTemps: p.codeTemps)), \(FormatConditions.nombre(p.temperatureC)) degrés")
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityIdentifier("previsions-horaires")
    }
}

/// Prévisions sur 7 jours : jour, icône, mini, barre de plage dégradée, maxi.
struct CarteSeptJoursView: View {
    let jours: [JourConditions]
    let aujourdhui: Date

    var body: some View {
        let bas = jours.map(\.temperatureMinC).min() ?? 0
        let haut = jours.map(\.temperatureMaxC).max() ?? 0
        CarteVitree(titre: "Prévisions sur \(jours.count) jours", icone: "calendar") {
            VStack(spacing: 0) {
                ForEach(Array(jours.enumerated()), id: \.element.jour) { i, j in
                    if i > 0 { Divider().overlay(Color.white.opacity(0.18)) }
                    HStack(spacing: Espace.m) {
                        Text(FormatConditions.jourCourt(j.jour, aujourdhui: aujourdhui))
                            .font(.system(.body, weight: .semibold))
                            .frame(width: 52, alignment: .leading)
                        Image(systemName: StyleMeteo.symbole(codeTemps: j.codeTemps, nuit: false))
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 20)).frame(width: 28)
                        Text("\(FormatConditions.nombre(j.temperatureMinC))°")
                            .foregroundStyle(StyleMeteo.texteDoux).monospacedDigit()
                            .frame(width: 34, alignment: .trailing)
                        BarrePlage(minimum: j.temperatureMinC, maximum: j.temperatureMaxC, bas: bas, haut: haut)
                            .frame(height: 5)
                        Text("\(FormatConditions.nombre(j.temperatureMaxC))°")
                            .font(.system(.body, weight: .semibold)).monospacedDigit()
                            .frame(width: 34, alignment: .leading)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(FormatConditions.jour(j.jour)), \(StyleMeteo.libelle(codeTemps: j.codeTemps)), minimum \(FormatConditions.nombre(j.temperatureMinC)) degrés, maximum \(FormatConditions.nombre(j.temperatureMaxC)) degrés")
                }
            }
        }
        .accessibilityIdentifier("previsions-7-jours")
    }
}

/// La barre de plage de l'app Météo : une piste claire, et dessus le tronçon min-max en dégradé.
private struct BarrePlage: View {
    let minimum: Double
    let maximum: Double
    let bas: Double
    let haut: Double

    var body: some View {
        GeometryReader { geo in
            let etendue = max(haut - bas, 0.1)
            let debut = (minimum - bas) / etendue
            let fin = (maximum - bas) / etendue
            let largeur = max(geo.size.width * (fin - debut), geo.size.height)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.22))
                Capsule()
                    .fill(LinearGradient(colors: [StyleMeteo.couleur(temperature: minimum), StyleMeteo.couleur(temperature: maximum)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: largeur)
                    .offset(x: min(geo.size.width * debut, geo.size.width - largeur))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Vent : vitesse, rafales, boussole.
struct CarteVentView: View {
    let point: PointMeteo

    var body: some View {
        CarteVitree(titre: "Vent", icone: "wind") {
            VStack(alignment: .leading, spacing: Espace.s) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(FormatConditions.nombre(point.ventKmh)).font(.system(size: 34, weight: .semibold)).monospacedDigit()
                    Text("km/h").font(.system(.subheadline, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
                }
                if let r = point.rafalesKmh {
                    Text("Rafales à \(FormatConditions.nombre(r)) km/h")
                        .font(.system(.footnote, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
                }
                Spacer(minLength: 0)
                if let d = point.directionDeg { Boussole(direction: d).frame(maxWidth: .infinity) }
            }
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("carte-vent")
    }
}

/// Une boussole : cercle, N/E/S/O, flèche dans le sens où souffle le vent (`direction` = d'où il vient).
private struct Boussole: View {
    let direction: Double

    var body: some View {
        HStack(spacing: Espace.s) {
            ZStack {
                Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                ForEach(Array(["N", "E", "S", "O"].enumerated()), id: \.offset) { i, lettre in
                    Text(lettre).font(.system(size: 8, weight: .semibold)).foregroundStyle(StyleMeteo.texteDoux)
                        .offset(x: sin(Double(i) * .pi / 2) * 19, y: -cos(Double(i) * .pi / 2) * 19)
                }
                Image(systemName: "location.north.fill").font(.system(size: 14))
                    .rotationEffect(.degrees(direction + 180))
            }
            .frame(width: 52, height: 52)
            Text("d'\(FormatConditions.cardinal(direction))")
                .font(.system(.footnote, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
        }
        .accessibilityLabel("Vent venant du \(FormatConditions.cardinal(direction))")
    }
}

/// Pluie : cumul prévu sur les 24 prochaines heures.
struct CartePluieView: View {
    let cumulMm: Double

    var body: some View {
        CarteVitree(titre: "Pluie", icone: "drop.fill") {
            VStack(alignment: .leading, spacing: Espace.s) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(FormatConditions.nombre(cumulMm, decimales: cumulMm < 10 ? 1 : 0))
                        .font(.system(size: 34, weight: .semibold)).monospacedDigit()
                    Text("mm").font(.system(.subheadline, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
                }
                Text("prévus dans les 24 h").font(.system(.footnote, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
                Spacer(minLength: 0)
                Text(cumulMm < 0.1 ? "Aucune pluie prévue." : "Cumul des 24 prochaines heures.")
                    .font(.system(.footnote, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("carte-pluie")
    }
}

/// Pression : hPa et tendance sur 6 h quand `Core` la donne.
struct CartePressionView: View {
    let hPa: Double
    let tendance: Double?

    var body: some View {
        CarteVitree(titre: "Pression", icone: "gauge.medium") {
            VStack(alignment: .leading, spacing: Espace.s) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(FormatConditions.nombre(hPa)).font(.system(size: 34, weight: .semibold)).monospacedDigit()
                    Text("hPa").font(.system(.subheadline, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
                }
                Spacer(minLength: 0)
                if let t = tendance {
                    Label(texte(t), systemImage: t < -0.5 ? "arrow.down.right" : (t > 0.5 ? "arrow.up.right" : "arrow.right"))
                        .font(.system(.footnote, weight: .medium))
                }
            }
            .foregroundStyle(.white)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("carte-pression")
    }

    private func texte(_ t: Double) -> String {
        let mot = t < -0.5 ? "En baisse" : (t > 0.5 ? "En hausse" : "Stable")
        let signe = t < 0 ? "−" : "+"
        return "\(mot), \(signe)\(FormatConditions.nombre(abs(t))) en 6 h"
    }
}

/// Niveau de la rivière (Hub'Eau) : nom de la station, hauteur ou débit, état. Un toucher ouvre la courbe si `ouvrirCourbe`.
struct CarteRiviereView: View {
    let eau: NiveauEau
    let etat: EtatRiviere
    var ouvrirCourbe: (() -> Void)? = nil

    var body: some View {
        let valeur: String? = eau.hauteurM.map { "\(FormatConditions.nombre($0, decimales: 2)) m" }
            ?? eau.debitM3s.map { "\(FormatConditions.nombre($0)) m³/s" }
        if let valeur {
            Button { ouvrirCourbe?() } label: {
                CarteVitree(titre: "Niveau de l'eau", icone: "water.waves") {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(valeur).font(.system(size: 34, weight: .semibold)).monospacedDigit()
                            Text(eau.station.nom).font(.system(.footnote, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
                        }
                        Spacer(minLength: Espace.m)
                        if let mot = mot { Text(mot).font(.system(.subheadline, weight: .semibold)) }
                        if ouvrirCourbe != nil { Image(systemName: "chevron.right").foregroundStyle(StyleMeteo.texteDoux) }
                    }
                    .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(eau.station.nom), \(valeur), mesuré à \(FormatConditions.heure(eau.heureMesure))")
            .accessibilityIdentifier("jauge-riviere")
        }
    }

    private var mot: String? {
        switch etat {
        case .normal: return "Normal"
        case .haut: return "Haut"
        case .crue: return "Crue"
        case .inconnu: return nil
        }
    }
}
