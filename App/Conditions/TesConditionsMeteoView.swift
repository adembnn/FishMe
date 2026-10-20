import SwiftUI
import Core

/// « Tes conditions » : la météo du spot courant, dans le style de l'app Météo d'Apple (une seule page qui défile).
/// Rien n'est inventé : une donnée absente n'a pas de carte. Sans lecture (WeatherKit muet), le mode démo
/// (`demo.communaute`) montre une lecture d'exemple annoncée comme telle ; hors démo, « pas de lecture » et un bouton pour réessayer.
/// Le gating Pro arrive par `porte` (le verdict de `peutUtiliser` de `Core`, déjà résolu pour ce spot), sans `ParcoursApp`.
struct TesConditionsMeteoView: View {
    /// Le centre du spot courant, ou `nil` quand aucun spot n'est choisi.
    let centre: Coordonnee?
    @ObservedObject var conditions: ConditionsDuSpot
    @ObservedObject var marque: StockageMarque
    let porte: PorteConditions

    #if DEBUG
    @AppStorage("demo.communaute") private var demo = false
    #endif
    @State private var lecture: LectureConditions?
    @State private var essaiFait = false
    @State private var courbe = false
    /// La lecture d'exemple du mode démo : créée une fois, jamais recalculée à chaque `body`.
    @State private var exemple: LectureConditions?

    init(centre: Coordonnee?, conditions: ConditionsDuSpot, marque: StockageMarque, porte: PorteConditions) {
        self.centre = centre
        self.conditions = conditions
        self.marque = marque
        self.porte = porte
    }

    /// La lecture réelle, ou en démo l'exemple quand il n'y en a pas.
    private var affichee: (lecture: LectureConditions, exemple: Bool)? {
        if let lecture { return (lecture, false) }
        #if DEBUG
        if demo, let exemple { return (exemple, true) }
        #endif
        return nil
    }

    var body: some View {
        let maintenant = Date()
        let vue = affichee
        let point = vue.flatMap { FormatConditions.pointLePlusProche($0.lecture.meteo, de: maintenant) }
        let nuit = vue.map { StyleMeteo.estNuit(maintenant, conditions: $0.lecture.conditions) } ?? false
        let fond = StyleMeteo.fond(codeTemps: point?.codeTemps ?? 3, nuit: nuit)

        ZStack(alignment: .top) {
            LinearGradient(colors: fond, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: point?.codeTemps)
            ScrollView {
                VStack(spacing: Espace.m) {
                    if let vue, let point {
                        page(vue.lecture, exemple: vue.exemple, point: point, maintenant: maintenant)
                    } else if centre == nil {
                        videSansSpot
                    } else if essaiFait {
                        VStack(spacing: Espace.l) {
                            RangeeMaintenantVideView(reessayer: { Task { await lire(forcer: true) } }, cause: conditions.derniereCause)
                            MarqueMeteoView(stockage: marque)
                        }
                        .padding(.top, 120)
                    } else {
                        ProgressView("Lecture de la météo").tint(.white).frame(maxWidth: .infinity).padding(.top, 140)
                    }
                }
                .padding(.horizontal, Espace.bord)
                .padding(.bottom, Espace.xl)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .topLeading) {
            BoutonRond(role: .fermer, rendu: .verre)
                .padding(.top, Espace.s).padding(.leading, Espace.bord)
        }
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .task(id: centre) {
            #if DEBUG
            if demo && exemple == nil { exemple = LectureExemple.creer() }
            #endif
            guard let c = centre else { lecture = nil; return }
            lecture = conditions.derniere(spot: c)
            await lire(forcer: false)
        }
        .sheet(isPresented: $courbe) {
            if let eau = affichee?.lecture.eau { CourbeRiviereView(eau: eau) }
        }
        .accessibilityIdentifier("tes-conditions-meteo")
    }

    // MARK: la page

    @ViewBuilder private func page(_ lecture: LectureConditions, exemple: Bool, point: PointMeteo, maintenant: Date) -> some View {
        enTete(lecture, point: point, maintenant: maintenant)
        if exemple {
            Text("Données d'exemple (mode démo)")
                .font(Police.taille(13, .bold)).foregroundStyle(StyleMeteo.texteDoux)
        }
        if let alerte = lecture.alerte {
            BandeauVigilanceView(alerte: alerte, lecture: lecture, marque: marque)
        }
        if porte.autorise(.meteoDuJour) {
            CarteHoraireView(lecture: lecture, maintenant: maintenant)
            jours(lecture, maintenant: maintenant)
            tuiles(lecture, point: point, maintenant: maintenant)
            riviere(lecture)
        } else {
            CarteVitree(titre: "Météo du moment", icone: "cloud.sun") {
                VerrouPro(fonction: .meteoDuJour, titre: "Météo du moment", icone: "cloud.sun", porte: porte)
            }
        }
        if lecture.depuisCache {
            Text("lu à \(FormatConditions.heure(lecture.lueLe)), sans réseau")
                .font(Police.taille(13, .bold)).foregroundStyle(StyleMeteo.texteDoux)
        }
        // Marque Apple Weather et lien légal : obligatoires sous une vraie lecture WeatherKit, jamais à côté de chiffres d'exemple.
        if exemple {
            Text("Données d'exemple (mode démo)")
                .font(.system(.footnote, weight: .medium)).foregroundStyle(StyleMeteo.texteDoux)
        } else {
            MarqueMeteoView(stockage: marque, libelleLien: "Sources", mention: lecture.eau == nil ? nil : "Hub’Eau")
        }
    }

    private func enTete(_ lecture: LectureConditions, point: PointMeteo, maintenant: Date) -> some View {
        let liste = StyleMeteo.jours(lecture)
        let duJour = liste.first { Calendar.current.isDate($0.jour, inSameDayAs: maintenant) } ?? liste.first
        let lieu = lecture.eau?.station.eau ?? lecture.eau?.station.nom ?? "Ton spot"
        return VStack(spacing: 2) {
            Text(lieu).font(Police.taille(30, .bold)).lineLimit(1)
            Text("\(FormatConditions.nombre(point.temperatureC))°")
                .font(Police.taille(96, .heavy)).monospacedDigit()
                .accessibilityIdentifier("temperature-maintenant")
            Text(StyleMeteo.libelle(codeTemps: point.codeTemps))
                .font(Police.taille(20, .bold)).foregroundStyle(.white.opacity(0.85))
            if let j = duJour {
                Text("Max. \(FormatConditions.nombre(j.temperatureMaxC))°  Min. \(FormatConditions.nombre(j.temperatureMinC))°")
                    .font(Police.taille(20, .bold)).monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Gabarit.zoneTactile + Espace.xl)
        .padding(.bottom, Espace.m)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private func jours(_ lecture: LectureConditions, maintenant: Date) -> some View {
        let liste = StyleMeteo.jours(lecture)
        if porte.autorise(.septJours) {
            if !liste.isEmpty { CarteSeptJoursView(jours: liste, aujourdhui: maintenant) }
        } else {
            CarteVitree(titre: "Prévisions sur 7 jours", icone: "calendar") {
                VerrouPro(fonction: .septJours, titre: "7 jours", icone: "calendar", porte: porte)
            }
        }
    }

    /// Vent, pluie, pression en cartes carrées, deux par ligne. Pas de température ressentie : WeatherKit n'est lu que pour
    /// la température réelle, et rien n'est calculé ici.
    @ViewBuilder private func tuiles(_ lecture: LectureConditions, point: PointMeteo, maintenant: Date) -> some View {
        let cumul = lecture.meteo.heures
            .filter { $0.heure > maintenant.addingTimeInterval(-1800) && $0.heure <= maintenant.addingTimeInterval(24 * 3600) }
            .map(\.pluieMm).reduce(0, +)
        let aPluie = lecture.meteo.heures.contains { $0.heure > maintenant }
        LazyVGrid(columns: [GridItem(.flexible(), spacing: Espace.m), GridItem(.flexible(), spacing: Espace.m)], spacing: Espace.m) {
            CarteVentView(point: point)
            if aPluie { CartePluieView(cumulMm: cumul) }
            if point.pressionHPa > 0 {
                CartePressionView(hPa: lecture.conditions.pressionHPa ?? point.pressionHPa,
                                  tendance: lecture.conditions.tendancePressionHPa6h)
            }
        }
    }

    @ViewBuilder private func riviere(_ lecture: LectureConditions) -> some View {
        if let eau = lecture.eau {
            if porte.autorise(.niveauEau) {
                CarteRiviereView(eau: eau, etat: lecture.conditions.etatRiviere,
                                 ouvrirCourbe: porte.autorise(.courbeEtNormale)
                                    ? { courbe = true } : { porte.ouvrirPaywall(.courbeEtNormale) })
            } else {
                CarteVitree(titre: "Niveau de l'eau", icone: "water.waves") {
                    VerrouPro(fonction: .niveauEau, titre: "Niveau de l'eau", icone: "water.waves", porte: porte)
                }
            }
        }
    }

    private var videSansSpot: some View {
        VStack(spacing: Espace.m) {
            Image(systemName: "mappin.slash").font(.system(size: 28)).foregroundStyle(StyleMeteo.texteDoux)
                .accessibilityHidden(true)
            Text("Choisis un spot sur la carte pour voir la météo.")
                .font(Police.taille(17, .bold)).foregroundStyle(StyleMeteo.texteDoux).multilineTextAlignment(.center)
            MarqueMeteoView(stockage: marque).padding(.top, Espace.s)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 140)
    }

    /// Lit le spot ; sans réseau `lire` rend la dernière lecture marquée « cache ».
    private func lire(forcer: Bool) async {
        guard let c = centre else { return }
        let lue = await conditions.lire(spot: c, forcer: forcer)
        lecture = lue ?? lecture
        essaiFait = true
    }
}

#if DEBUG
#Preview("Avec lecture") {
    let source = ConditionsDuSpot(meteo: SourceMeteoFaux(), eau: NiveauEauFaux(), noyau: ConditionsFaux(), fichier: nil)
    TesConditionsMeteoView(centre: Coordonnee(latitude: 48.85, longitude: 2.35), conditions: source,
                           marque: StockageMarque(source: SourceMarqueFaux(), dossier: nil),
                           porte: .toutOuvert)
}

#Preview("Sans spot") {
    let source = ConditionsDuSpot(meteo: SourceMeteoFaux(), eau: NiveauEauFaux(), noyau: ConditionsFaux(), fichier: nil)
    TesConditionsMeteoView(centre: nil, conditions: source,
                           marque: StockageMarque(source: SourceMarqueFaux(), dossier: nil),
                           porte: .toutOuvert)
}

#Preview("Hors ligne, sans lecture") {
    let source = ConditionsDuSpot(meteo: SourceMeteoFaux(meteoRendue: nil), eau: NiveauEauFaux(), noyau: ConditionsFaux(), fichier: nil)
    TesConditionsMeteoView(centre: Coordonnee(latitude: 48.85, longitude: 2.35), conditions: source,
                           marque: StockageMarque(source: SourceMarqueFaux(), dossier: nil),
                           porte: .toutOuvert)
}
#endif
