import SwiftUI
import Core

/// La courbe de la rivière de la maquette P12 : une aire d'eau claire sous un trait marine, un rond sur la dernière mesure.
private struct CourbeEau: View {
    let valeurs: [Double]

    var body: some View {
        Canvas { ctx, size in
            guard valeurs.count >= 2, let bas = valeurs.min(), let haut = valeurs.max() else { return }
            let w = size.width
            let h = size.height
            // Deux repères en pointillé, à 25 % et 75 % de la hauteur.
            for fraction in [0.25, 0.75] {
                var repere = Path()
                repere.move(to: CGPoint(x: 0, y: h * fraction))
                repere.addLine(to: CGPoint(x: w, y: h * fraction))
                ctx.stroke(repere, with: .color(Palette.filet), style: StrokeStyle(lineWidth: 1, dash: [2, 5]))
            }
            let x0 = w * 14 / 334
            let x1 = w * 320 / 334
            let pas = (x1 - x0) / Double(valeurs.count - 1)
            let etendue = haut - bas
            let points: [CGPoint] = valeurs.enumerated().map { i, v in
                let part = etendue > 0 ? (v - bas) / etendue : 0.5
                return CGPoint(x: x0 + pas * Double(i), y: h * (0.72 - 0.44 * part))
            }
            var trait = Path()
            trait.move(to: points[0])
            for i in 1..<points.count {
                let a = points[i - 1]
                let b = points[i]
                let dx = (b.x - a.x) / 2
                trait.addCurve(to: b, control1: CGPoint(x: a.x + dx, y: a.y), control2: CGPoint(x: b.x - dx, y: b.y))
            }
            var aire = trait
            aire.addLine(to: CGPoint(x: x1, y: h))
            aire.addLine(to: CGPoint(x: x0, y: h))
            aire.closeSubpath()
            ctx.fill(aire, with: .color(Palette.eauClaire.opacity(0.55)))
            ctx.stroke(trait, with: .color(Palette.marine), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            if let dernier = points.last {
                let rond = Path(ellipseIn: CGRect(x: dernier.x - 6, y: dernier.y - 6, width: 12, height: 12))
                ctx.fill(rond, with: .color(Palette.surface))
                ctx.stroke(rond, with: .color(Palette.marine), lineWidth: 3.5)
            }
        }
        .accessibilityHidden(true)
    }
}

/// Sept jours et rivière (maquette P12-septjours-A) : sept colonnes (jour, icône, maximum, minimum),
/// puis le niveau de la rivière sur 48 h. Chiffres prévus par WeatherKit, niveau mesuré par Hub'Eau ; aucune note.
struct SeptJoursView: View {
    let lecture: LectureConditions
    @ObservedObject var marque: StockageMarque

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(AnglaisF.t("7 jours")).font(Police.titre).foregroundStyle(Palette.encre)
                if jours.isEmpty { aucunJour }
                HStack(alignment: .top, spacing: 0) {
                    ForEach(jours, id: \.jour) { j in
                        VStack(spacing: Espace.s) {
                            Text(FormatConditions.jourCourt(j.jour, aujourdhui: lecture.lueLe))
                                .font(Police.legende).foregroundStyle(Palette.encreDouce)
                            Image(systemName: FormatConditions.symbole(codeTemps: j.codeTemps))
                                .symbolRenderingMode(.monochrome)
                                .font(Police.taille(24)).foregroundStyle(Palette.marine)
                                .frame(height: 26)
                            Text(FormatConditions.degres(celsius: j.temperatureMaxC))
                                .font(Police.corps).foregroundStyle(Palette.encre).monospacedDigit()
                            Text(FormatConditions.degres(celsius: j.temperatureMinC))
                                .font(Police.detail).foregroundStyle(Palette.encreDouce).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(AnglaisF.f("%@, %@, maximum %@, minimum %@", FormatConditions.jour(j.jour), FormatConditions.libelle(codeTemps: j.codeTemps), FormatConditions.degres(celsius: j.temperatureMaxC), FormatConditions.degres(celsius: j.temperatureMinC)))
                    }
                }
                .padding(.top, 14)
                .padding(.horizontal, -6)
                if let eau = lecture.eau { riviere(eau) }
                if lecture.depuisCache {
                    Text(AnglaisF.f("prévision lue %@, sans réseau", FormatConditions.jourHeure(lecture.lueLe)))
                        .font(Police.legende).foregroundStyle(Palette.encreDouce)
                        .padding(.top, Espace.s)
                }
                MarqueMeteoView(stockage: marque, libelleLien: AnglaisF.t("Sources"), mention: lecture.eau == nil ? nil : FormatConditions.sourceEau())
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
        .background(Palette.surface)
        .overlay(alignment: .topTrailing) {
            BoutonRond(role: .fermer, rendu: .verre)
                .padding(.top, Espace.s).padding(.trailing, Espace.bord)
        }
        .scrollIndicators(.hidden)
        .presentationDetents([.height(460), .large])
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("sept-jours")
    }

    /// Pas de prévision lue : un état plein et une issue (la feuille se rouvre quand le réseau revient).
    private var aucunJour: some View {
        VStack(spacing: Espace.s) {
            Image(systemName: "cloud.sun").font(Police.taille(40)).foregroundStyle(Palette.marine)
            Text(AnglaisF.t("Pas de prévision pour l'instant")).font(Police.sousTitre).foregroundStyle(Palette.encre)
            Text(AnglaisF.t("Vérifie ta connexion, puis rouvre cette feuille.")).font(Police.detail).foregroundStyle(Palette.encreDouce)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Espace.xl)
        .accessibilityElement(children: .combine)
    }

    /// La rivière : le nom de la station et sa hauteur, la courbe de 48 h, et l'état en un mot.
    @ViewBuilder private func riviere(_ eau: NiveauEau) -> some View {
        Rectangle().fill(Palette.filet).frame(height: 1).padding(.top, 20).padding(.bottom, Espace.l)
        HStack(alignment: .firstTextBaseline) {
            Text(eau.station.nom).font(Police.titre).foregroundStyle(Palette.encre).lineLimit(1)
            Spacer(minLength: Espace.m)
            if let h = eau.hauteurM {
                Text(FormatConditions.hauteurEau(metres: h))
                    .font(Police.taille(26, .black).monospacedDigit()).foregroundStyle(Palette.encre)
            }
        }
        .accessibilityElement(children: .combine)
        let serie = eau.serie48h.sorted { $0.heure < $1.heure }.compactMap(\.hauteurM)
        if serie.count >= 2 {
            CourbeEau(valeurs: echantillon(serie, auPlus: 7))
                .frame(height: 116)
                .padding(.top, Espace.m)
            HStack {
                Text(AnglaisF.t("il y a 48 h"))
                Spacer()
                if let etat = etatRiviere { Text(etat.mot).foregroundStyle(etat.couleur) }
                Spacer()
                Text(AnglaisF.t("aujourd’hui"))
            }
            .font(Police.legende).foregroundStyle(Palette.encreDouce)
            .padding(.top, 6)
        }
    }

    private var etatRiviere: (mot: String, couleur: Color)? {
        switch lecture.conditions.etatRiviere {
        case .normal: return (AnglaisF.t("Normal"), Palette.encreDouce)
        case .haut: return (AnglaisF.t("Haut"), Palette.alerte)
        case .crue: return (AnglaisF.t("Crue"), Palette.alerte)
        case .inconnu: return nil
        }
    }

    /// Réduit la série à quelques points régulièrement espacés (le dernier est toujours gardé) : de la mise en page.
    private func echantillon(_ serie: [Double], auPlus maximum: Int) -> [Double] {
        guard serie.count > maximum, maximum >= 2 else { return serie }
        return (0..<maximum).map { i in serie[i * (serie.count - 1) / (maximum - 1)] }
    }

    /// Les sept jours rendus par `Core` ; à défaut, regroupés depuis la météo heure par heure (mise en page, pas de calcul de prévision).
    private var jours: [JourConditions] {
        if !lecture.conditions.septJours.isEmpty { return Array(lecture.conditions.septJours.prefix(7)) }
        let cal = Calendar.current
        let groupes = Dictionary(grouping: lecture.meteo.heures) { cal.startOfDay(for: $0.heure) }
        return groupes.keys.sorted().prefix(7).compactMap { debut in
            guard let h = groupes[debut], let milieu = h.min(by: { abs($0.heure.timeIntervalSince(debut.addingTimeInterval(13 * 3600))) < abs($1.heure.timeIntervalSince(debut.addingTimeInterval(13 * 3600))) }) else { return nil }
            return JourConditions(jour: debut, ventKmh: h.map(\.ventKmh).max() ?? 0, pluieMm: h.map(\.pluieMm).reduce(0, +),
                                  temperatureMinC: h.map(\.temperatureC).min() ?? milieu.temperatureC,
                                  temperatureMaxC: h.map(\.temperatureC).max() ?? milieu.temperatureC, codeTemps: milieu.codeTemps)
        }
    }
}
