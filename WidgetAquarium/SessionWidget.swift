import SwiftUI
import WidgetKit

// Cible widget seulement. Le widget « Ma session » : la session de pêche en direct, sur l'écran d'accueil
// et l'écran verrouillé. Gratuit. Il lit `EtatSession?` écrit par l'app (`PontSessionWidget`).
// Le chrono tourne tout seul (rendu par le système) : la timeline n'a que deux entrées (maintenant, fin légale),
// politique `.never` car l'app recharge à chaque changement (démarrage, prise, fin).
// Aucun lieu, jamais de verdict « tu peux la garder ».

/// Une image du widget à une date donnée.
nonisolated struct EntreeSessionWidget: TimelineEntry, Sendable {
    let date: Date
    let etat: EtatSession?
}

nonisolated struct FournisseurSessionWidget: TimelineProvider {
    func placeholder(in context: Context) -> EntreeSessionWidget {
        EntreeSessionWidget(date: .now, etat: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntreeSessionWidget) -> Void) {
        completion(EntreeSessionWidget(date: .now, etat: DepotSessionWidget.lire()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntreeSessionWidget>) -> Void) {
        let etat = DepotSessionWidget.lire()
        let dates = AffichageSessionWidget.datesTimeline(etat: etat, maintenant: .now)
        let entrees = dates.map { EntreeSessionWidget(date: $0, etat: etat) }
        completion(Timeline(entries: entrees, policy: .never))
    }
}

struct SessionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DepotSessionWidget.genre, provider: FournisseurSessionWidget()) { entree in
            VueSessionWidgetEnveloppe(entree: entree)
        }
        .configurationDisplayName("Ma session")
        .description("Ta session de pêche en direct.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}

/// Lit la famille dans l'environnement du widget et la passe à la vue (qui, elle, la reçoit en paramètre).
private struct VueSessionWidgetEnveloppe: View {
    @Environment(\.widgetFamily) private var famille
    let entree: EntreeSessionWidget

    var body: some View {
        VueSessionWidget(entree: entree, famille: famille)
    }
}

#if DEBUG
extension EntreeSessionWidget {
    /// Pour le rendu en image hors widget : début il y a 1 h 12, fin légale dans 47 min, 3 prises.
    /// `enCours: false` donne l'état « pas de session ».
    static func exempleRendu(enCours: Bool) -> EntreeSessionWidget {
        let maintenant = Date.now
        guard enCours else { return EntreeSessionWidget(date: maintenant, etat: nil) }
        let etat = EtatSession(
            debut: maintenant.addingTimeInterval(-72 * 60),
            finLegale: maintenant.addingTimeInterval(47 * 60),
            prises: 3
        )
        return EntreeSessionWidget(date: maintenant, etat: etat)
    }
}

#Preview("En cours", as: .systemSmall) {
    SessionWidget()
} timeline: {
    EntreeSessionWidget.exempleRendu(enCours: true)
}

#Preview("Pas de session", as: .systemMedium) {
    SessionWidget()
} timeline: {
    EntreeSessionWidget.exempleRendu(enCours: false)
}
#endif
