import SwiftUI
import Core

/// « Tes conditions » : la météo du spot courant (WeatherKit, plus Hub'Eau pour la rivière).
/// Rien n'est inventé : sans spot, un message ; sans réseau, la dernière lecture marquée « sans réseau » ;
/// sans aucune lecture, « pas de lecture » et un bouton pour réessayer.
/// Le gating Pro arrive par `porte` (le verdict de `peutUtiliser` de `Core`, déjà résolu pour ce spot), sans `ParcoursApp`.
struct TesConditionsMeteoView: View {
    private enum Onglet: Hashable { case maintenant, septJours }

    /// Le centre du spot courant, ou `nil` quand aucun spot n'est choisi.
    let centre: Coordonnee?
    @ObservedObject var conditions: ConditionsDuSpot
    @ObservedObject var marque: StockageMarque
    let porte: PorteConditions

    @State private var lecture: LectureConditions?
    @State private var essaiFait = false
    @State private var onglet: Onglet = .maintenant
    @State private var courbe = false

    init(centre: Coordonnee?, conditions: ConditionsDuSpot, marque: StockageMarque, porte: PorteConditions) {
        self.centre = centre
        self.conditions = conditions
        self.marque = marque
        self.porte = porte
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Espace.m) {
            Text("Tes conditions").font(Police.titre).foregroundStyle(Palette.encre)
                .padding(.top, Gabarit.zoneTactile + Espace.bord)
                .padding(.horizontal, Espace.bord)
                .accessibilityAddTraits(.isHeader)
            if centre == nil {
                videSansSpot
            } else if let lecture {
                if let alerte = lecture.alerte {
                    BandeauVigilanceView(alerte: alerte, lecture: lecture, marque: marque)
                        .padding(.horizontal, Espace.bord)
                }
                Picker("Période", selection: $onglet) {
                    Text("Maintenant").tag(Onglet.maintenant)
                    Text("7 jours").tag(Onglet.septJours)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Espace.bord)
                contenu(lecture)
            } else if essaiFait {
                ScrollView {
                    VStack(spacing: Espace.l) {
                        RangeeMaintenantVideView(reessayer: { Task { await lire(forcer: true) } })
                        MarqueMeteoView(stockage: marque)
                    }
                    .padding(Espace.bord)
                }
            } else {
                ProgressView("Lecture de la météo").frame(maxWidth: .infinity).padding(Espace.bord)
            }
            Spacer(minLength: 0)
        }
        .background(Palette.surface)
        .task(id: centre) {
            guard let c = centre else { lecture = nil; return }
            lecture = conditions.derniere(spot: c)
            await lire(forcer: false)
        }
        .sheet(isPresented: $courbe) {
            if let eau = lecture?.eau { CourbeRiviereView(eau: eau) }
        }
        .accessibilityIdentifier("tes-conditions-meteo")
    }

    @ViewBuilder private func contenu(_ lecture: LectureConditions) -> some View {
        switch onglet {
        case .maintenant:
            ScrollView {
                if porte.autorise(.meteoDuJour) {
                    RangeeMaintenantView(lecture: lecture, marque: marque,
                                         montrerRiviere: porte.autorise(.niveauEau),
                                         ouvrirCourbe: porte.autorise(.courbeEtNormale)
                                            ? { courbe = true } : { porte.ouvrirPaywall(.courbeEtNormale) },
                                         enFeuille: true)
                } else {
                    VerrouPro(fonction: .meteoDuJour, titre: "Météo du moment", icone: "cloud.sun", porte: porte)
                        .padding(Espace.bord)
                }
                if porte.autorise(.meteoDuJour) && !porte.autorise(.niveauEau) {
                    VerrouPro(fonction: .niveauEau, titre: "Niveau de l'eau", icone: "water.waves", porte: porte)
                        .padding(.horizontal, Espace.bord)
                }
            }
            .scrollIndicators(.hidden)
        case .septJours:
            if porte.autorise(.septJours) {
                SeptJoursView(lecture: lecture, marque: marque)
            } else {
                VStack(alignment: .leading, spacing: Espace.l) {
                    VerrouPro(fonction: .septJours, titre: "7 jours", icone: "calendar", porte: porte)
                    MarqueMeteoView(stockage: marque)
                }
                .padding(Espace.bord)
            }
        }
    }

    private var videSansSpot: some View {
        VStack(spacing: Espace.m) {
            Image(systemName: "mappin.slash").font(Police.taille(28)).foregroundStyle(Palette.encreDouce)
                .accessibilityHidden(true)
            Text("Choisis un spot sur la carte pour voir la météo.")
                .font(Police.corps).foregroundStyle(Palette.encreDouce).multilineTextAlignment(.center)
            MarqueMeteoView(stockage: marque).padding(.top, Espace.s)
        }
        .frame(maxWidth: .infinity)
        .padding(Espace.bord)
    }

    /// Lit le spot ; sans réseau `lire` rend la dernière lecture marquée « cache » (la rangée écrit « lu à …, sans réseau »).
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
