import Core
import SwiftUI

/// Carte bredouille : une session finie sans prise. Son propre dos, aucune rareté, rangée à part.
struct BredouilleView: View {
    let carte: CarteBredouille
    let services: ServicesCollection
    var emplacements: EmplacementsExternes = .vides

    var body: some View {
        CarteCadre(style: .commun, declaree: false) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "water.waves")
                    .font(Police.taille(44))
                    .foregroundStyle(Palette.commun)
                Text("Bredouille")
                    .font(Police.taille(30, .heavy))
                    .foregroundStyle(Palette.encre)
                Text("Pas de poisson cette fois, mais tu y étais.")
                    .font(Police.detail)
                    .foregroundStyle(Palette.encreDouce)
                Divider()
                if let lieu = carte.lieuFlou { Text(lieu).font(Police.corps) }
                Text(Formats.date(carte.debut)).font(Police.detail)
                Text(Formats.lune(services.soleil.phaseLune(date: carte.debut))).font(Police.detail)
                if let s = carte.dureeSecondes { Text("Session de \(Formats.duree(s))").font(Police.detail) }
                if let c = carte.conditions {
                    Divider()
                    Text("Conditions du départ").font(Police.legende).foregroundStyle(Palette.encreDouce)
                    if let slot = emplacements.meteoDuDos { slot(c) } else { BlocMeteoSimple(conditions: c) }
                    MarqueAppleWeather()
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Palette.encre)
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Une bredouille ouverte en plein écran.
struct BredouillePleinEcranView: View {
    let carte: CarteBredouille
    let services: ServicesCollection
    var emplacements: EmplacementsExternes = .vides
    let fermer: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Palette.fond.ignoresSafeArea()
            VStack {
                Spacer(minLength: 56)
                BredouilleView(carte: carte, services: services, emplacements: emplacements).padding(.horizontal, 20)
                Spacer(minLength: 24)
            }
            BoutonRond(role: .fermer, rendu: .verre, action: fermer)
                .padding(Espace.bord)
        }
    }
}
