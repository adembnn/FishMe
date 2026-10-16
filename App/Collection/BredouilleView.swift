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
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Jeton.ardoise)
                Text("Bredouille")
                    .font(Jeton.police(30))
                    .foregroundStyle(Jeton.encre)
                Text("Pas de poisson cette fois, mais tu y étais.")
                    .font(Jeton.police(15, .semibold))
                    .foregroundStyle(Jeton.encreDouce)
                Divider()
                if let lieu = carte.lieuFlou { Text(lieu).font(Jeton.police(17)) }
                Text(Formats.date(carte.debut)).font(Jeton.police(16, .semibold))
                Text(Formats.lune(services.soleil.phaseLune(date: carte.debut))).font(Jeton.police(16, .semibold))
                if let s = carte.dureeSecondes { Text("Session de \(Formats.duree(s))").font(Jeton.police(16, .semibold)) }
                if let c = carte.conditions {
                    Divider()
                    Text("Conditions du départ").font(Jeton.police(13)).foregroundStyle(Jeton.encreDouce)
                    if let slot = emplacements.meteoDuDos { slot(c) } else { BlocMeteoSimple(conditions: c) }
                    MarqueAppleWeather()
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Jeton.encre)
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
            Jeton.fondPage.ignoresSafeArea()
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
