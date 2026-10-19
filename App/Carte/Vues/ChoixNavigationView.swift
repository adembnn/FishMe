import MapKit
import SwiftUI
import UIKit
import Core

/// Ouvre l'itinéraire dans l'application choisie. Reçoit la coordonnée de la STATION (le coin), jamais celle du pêcheur :
/// rien ici ne lit la position de l'iPhone. Rien ne part tant que le pêcheur n'a pas touché « Y aller ».
@MainActor
enum LanceurItineraire {
    /// Plans, plus Waze et Google Maps quand ils sont installés (`canOpenURL`, qui demande `LSApplicationQueriesSchemes`, à L25).
    static func installees() -> [ApplicationItineraire] {
        ApplicationItineraire.installees(peutOuvrir: { UIApplication.shared.canOpenURL($0) })
    }

    /// La décision du toucher : ouverture directe (préférence ou Plans seul) ou feuille de choix.
    static func decision(preference: ApplicationItineraire? = PreferenceItineraire.lire()) -> DecisionYAller {
        DecisionYAller.decider(installees: installees(), preference: preference)
    }

    static func ouvrir(_ application: ApplicationItineraire, vers c: Coordonnee, nom: String) {
        if let url = application.url(vers: c) {
            UIApplication.shared.open(url)
            return
        }
        // Plans d'Apple : itinéraire en voiture jusqu'à ce coin (même appel qu'avant L17).
        let item = MKMapItem(location: CLLocation(latitude: c.latitude, longitude: c.longitude), address: nil)
        item.name = nom
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

/// La feuille « Y aller avec » : une rangée par application installée, et « Toujours utiliser ».
/// Elle n'existe que si au moins une application autre que Plans est installée (sinon Plans s'ouvre directement).
struct ChoixNavigationView: View {
    let applications: [ApplicationItineraire]
    /// L'application choisie, et vrai si « Toujours utiliser » était allumé.
    let choisir: (ApplicationItineraire, Bool) -> Void
    @State private var toujours = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Espace.l) {
                Text("Y aller avec")
                    .font(Police.titre)
                    .foregroundStyle(Palette.encre)
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    ForEach(Array(applications.enumerated()), id: \.element.id) { index, application in
                        rangee(application)
                        if index < applications.count - 1 {
                            Divider().overlay(Palette.filet).padding(.leading, 56)
                        }
                    }
                }
                .tuileFishMe(rayon: Rayon.m)
                Toggle(isOn: $toujours) {
                    Text("Toujours utiliser")
                        .font(Police.corps)
                        .foregroundStyle(Palette.encre)
                }
                .tint(Palette.marine)
                .padding(.horizontal, Espace.l)
                .frame(minHeight: Gabarit.zoneTactile + 12)
                .tuileFishMe(rayon: Rayon.m)
            }
            .padding(Espace.bord)
        }
        .scrollIndicators(.hidden)
        .background(Palette.fond.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func rangee(_ application: ApplicationItineraire) -> some View {
        Button { choisir(application, toujours) } label: {
            HStack(spacing: Espace.m) {
                Image(systemName: application.symbole)
                    .font(Police.taille(20))
                    .foregroundStyle(Palette.marine)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                Text(application.nom)
                    .font(Police.corps)
                    .foregroundStyle(Palette.encre)
                Spacer(minLength: Espace.s)
                Image(systemName: "chevron.right")
                    .font(Police.taille(13))
                    .foregroundStyle(Palette.silhouette)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Espace.l)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Y aller avec \(application.nom)")
    }
}

/// La rangée des réglages : l'application de « Y aller ». À poser par A dans l'écran des réglages (profil), à côté des autres rangées.
/// Elle lit et écrit la même préférence que « Toujours utiliser » (`PreferenceItineraire`).
struct ReglageNavigationView: View {
    @AppStorage(PreferenceItineraire.cle) private var choix = ""
    @State private var installees: [ApplicationItineraire] = [.plans]

    var body: some View {
        HStack(spacing: Espace.m) {
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(Police.taille(20))
                .foregroundStyle(Palette.marine)
                .frame(width: 32)
                .accessibilityHidden(true)
            Text("Y aller avec")
                .font(Police.corps)
                .foregroundStyle(Palette.encre)
            Spacer(minLength: Espace.s)
            Picker("Y aller avec", selection: $choix) {
                Text("Toujours demander").tag("")
                ForEach(installees) { application in
                    Text(application.nom).tag(application.rawValue)
                }
            }
            .pickerStyle(.menu)
            .tint(Palette.marine)
        }
        .padding(.horizontal, Espace.l)
        .frame(minHeight: 56)
        .onAppear { installees = LanceurItineraire.installees() }
    }
}

#if DEBUG
#Preview("Choix de l'application") {
    ChoixNavigationView(applications: [.plans, .waze, .googleMaps], choisir: { _, _ in })
}

#Preview("Réglage") {
    ReglageNavigationView()
        .tuileFishMe()
        .padding(Espace.bord)
        .background(Palette.fond)
}
#endif
