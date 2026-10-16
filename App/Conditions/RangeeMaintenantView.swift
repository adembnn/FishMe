import SwiftUI
import Core

/// L'arc du soleil de la maquette P11 : le jour en gris, la part déjà écoulée en marine, un rond à l'heure qu'il est.
private struct ArcSoleil: View {
    /// 0 au lever, 1 au coucher.
    let progres: Double

    var body: some View {
        Canvas { ctx, size in
            let sx = size.width / 320
            let sy = size.height / 120
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * sx, y: y * sy) }
            func milieu(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
                CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
            }
            let depart = pt(20, 108)
            let controle = pt(160, -12)
            let arrivee = pt(300, 108)

            var jour = Path()
            jour.move(to: depart)
            jour.addQuadCurve(to: arrivee, control: controle)
            ctx.stroke(jour, with: .color(Palette.filet), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            var sol = Path()
            sol.move(to: pt(6, 108))
            sol.addLine(to: pt(314, 108))
            ctx.stroke(sol, with: .color(Palette.filet), style: StrokeStyle(lineWidth: 2, lineCap: .round))

            // Courbe de Bézier coupée à t (de Casteljau) : la part du jour écoulée.
            let t = min(max(progres, 0), 1)
            let q1 = milieu(depart, controle, t)
            let r1 = milieu(controle, arrivee, t)
            let soleil = milieu(q1, r1, t)
            var ecoule = Path()
            ecoule.move(to: depart)
            ecoule.addQuadCurve(to: soleil, control: q1)
            ctx.stroke(ecoule, with: .color(Palette.marine), style: StrokeStyle(lineWidth: 3, lineCap: .round))

            let rond = Path(ellipseIn: CGRect(x: soleil.x - 8, y: soleil.y - 8, width: 16, height: 16))
            ctx.fill(rond, with: .color(Palette.surface))
            ctx.stroke(rond, with: .color(Palette.marine), lineWidth: 3.5)
        }
        .accessibilityHidden(true)
    }
}

/// Conditions du jour (maquette P11-conditions-A) : la température en grand, le vent et la pression à droite,
/// l'arc du soleil de l'aube au crépuscule, puis la fin légale et le niveau de la rivière. Tout vient de `Core`.
struct RangeeMaintenantView: View {
    let lecture: LectureConditions
    @ObservedObject var marque: StockageMarque
    /// Montre le niveau de la rivière (donnée Pro) : faux quand la fonction est verrouillée.
    var montrerRiviere: Bool = true
    /// Un toucher sur le niveau de la rivière ouvre la courbe de 48 h (Pro : l'appelant passe la porte).
    var ouvrirCourbe: (() -> Void)? = nil
    /// Vrai quand la rangée est déjà dans une feuille : ni tuile ni marge de tuile, seulement la marge de l'écran.
    var enFeuille: Bool = false

    var body: some View {
        let c = lecture.conditions
        let point = FormatConditions.pointLePlusProche(lecture.meteo, de: c.heure)
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                if let point {
                    VStack(alignment: .leading, spacing: Espace.s) {
                        Text("\(FormatConditions.nombre(point.temperatureC))°")
                            .font(Police.taille(72, .heavy).monospacedDigit()).minimumScaleFactor(0.6).lineLimit(1)
                            .foregroundStyle(Palette.encre)
                            .accessibilityIdentifier("temperature-maintenant")
                        Text(FormatConditions.libelle(codeTemps: point.codeTemps))
                            .font(Police.sousTitre).foregroundStyle(Palette.encre)
                    }
                    .accessibilityElement(children: .combine)
                }
                Spacer(minLength: Espace.m)
                VStack(alignment: .trailing, spacing: Espace.s) {
                    if let v = c.ventKmh {
                        ligne("wind", "\(FormatConditions.nombre(v)) km/h")
                    }
                    if let hpa = c.pressionHPa {
                        ligne("gauge.medium", "\(FormatConditions.nombre(hpa)) hPa")
                    }
                }
                .padding(.bottom, Espace.xs)
            }
            if let aube = c.aube, let soir = c.crepuscule, soir > aube {
                ArcSoleil(progres: c.heure.timeIntervalSince(aube) / soir.timeIntervalSince(aube))
                    .frame(height: 112)
                    .padding(.top, Espace.m)
                HStack {
                    Text("Lever \(FormatConditions.horloge(aube))")
                    Spacer()
                    Text("Coucher \(FormatConditions.horloge(soir))")
                }
                .font(Police.detail).foregroundStyle(Palette.encreDouce).monospacedDigit()
                .padding(.top, 2)
            }
            if c.finLegale != nil || (montrerRiviere && lecture.eau != nil) {
                Rectangle().fill(Palette.filet).frame(height: 1)
                    .padding(.top, Espace.l).padding(.bottom, Espace.m)
                HStack(alignment: .top) {
                    if let f = c.finLegale {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Fin légale").font(Police.legende).foregroundStyle(Palette.encreDouce)
                            Text(FormatConditions.horloge(f)).font(Police.taille(28, .heavy).monospacedDigit())
                                .foregroundStyle(Palette.encre)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Spacer(minLength: Espace.m)
                    if montrerRiviere, let eau = lecture.eau { riviere(eau) }
                }
            }
            if lecture.depuisCache {
                Text("lu à \(FormatConditions.heure(lecture.lueLe)), sans réseau")
                    .font(Police.legende).foregroundStyle(Palette.encreDouce)
                    .padding(.top, Espace.s)
            }
            MarqueMeteoView(stockage: marque).padding(.top, Espace.s)
        }
        .padding(enFeuille ? Espace.bord : 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(HabillageTuile(actif: !enFeuille))
        .accessibilityIdentifier("rangee-maintenant")
    }

    private func ligne(_ icone: String, _ texte: String) -> some View {
        HStack(spacing: Espace.s) {
            Image(systemName: icone).foregroundStyle(Palette.marine).frame(width: 20)
            Text(texte).font(Police.corps).foregroundStyle(Palette.encre).monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    /// Le niveau : le nom de la station et la hauteur ; sans hauteur, le débit ; sans rien, rien (jamais un chiffre inventé).
    @ViewBuilder private func riviere(_ eau: NiveauEau) -> some View {
        let valeur: String? = eau.hauteurM.map { "\(FormatConditions.nombre($0, decimales: 2)) m" }
            ?? eau.debitM3s.map { "\(FormatConditions.nombre($0)) m³/s" }
        if let valeur {
            let bloc = VStack(alignment: .trailing, spacing: 2) {
                Text(eau.station.nom).font(Police.legende).foregroundStyle(Palette.encreDouce).lineLimit(1)
                Text(valeur).font(Police.taille(28, .heavy).monospacedDigit()).minimumScaleFactor(0.6).lineLimit(1)
                    .foregroundStyle(Palette.encre)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(eau.station.nom), \(valeur), mesuré à \(FormatConditions.heure(eau.heureMesure))")
            .accessibilityIdentifier("jauge-riviere")
            if let ouvrirCourbe {
                Button(action: ouvrirCourbe) { bloc.frame(minHeight: Gabarit.zoneTactile).contentShape(Rectangle()) }
                    .buttonStyle(.plain)
            } else {
                bloc
            }
        }
    }
}

/// La tuile FishMe, sauf quand la rangée est déjà dans une feuille.
private struct HabillageTuile: ViewModifier {
    let actif: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if actif { content.tuileFishMe(rayon: Rayon.l) } else { content }
    }
}

/// Rien à montrer sans lecture : jamais un chiffre inventé. Avec `reessayer`, un bouton de 44 pt relance la lecture.
struct RangeeMaintenantVideView: View {
    var reessayer: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Espace.s) {
            Image(systemName: "wifi.slash").font(Police.taille(28)).foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
            Text("pas de lecture").font(Police.detail).foregroundStyle(Palette.encreDouce)
            if let reessayer {
                Button(action: reessayer) {
                    Text("Réessayer").font(Police.corps).foregroundStyle(Palette.marine)
                        .frame(minWidth: Gabarit.zoneTactile, minHeight: Gabarit.zoneTactile)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Espace.bord)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("rangee-vide")
    }
}
