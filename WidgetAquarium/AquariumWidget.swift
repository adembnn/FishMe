import SwiftUI
import WidgetKit

// Cible widget seulement. Le widget « Mon aquarium » : les poissons du Pescedex qui nagent sur l'écran d'accueil.
// Petit gratuit ; moyen, grand et très grand avec Pro (choix par défaut en attente de la décision d'Adem).
// Aucun lieu : l'écran d'accueil et l'écran verrouillé sont vus par d'autres. Aucun faux poisson : vide = état vide.

/// Une image de l'aquarium à une date donnée.
nonisolated struct EntreeAquarium: TimelineEntry, Sendable {
    let date: Date
    let instantane: InstantaneAquarium
}

nonisolated struct FournisseurAquarium: TimelineProvider {
    /// Le système rend cette entrée floutée (`.placeholder`) ; elle ne contient aucun poisson.
    func placeholder(in context: Context) -> EntreeAquarium {
        EntreeAquarium(date: .now, instantane: .vide)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntreeAquarium) -> Void) {
        // Les vraies données ; si l'aquarium est vide, c'est l'état vide, jamais de poissons d'exemple.
        completion(EntreeAquarium(date: .now, instantane: DepotAquariumWidget.lire()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntreeAquarium>) -> Void) {
        let instantane = DepotAquariumWidget.lire()
        var dates = NageWidget.dates(depuis: .now, dernierRepas: instantane.dernierRepas)
        if dates.isEmpty { dates = [.now] }
        let entrees = dates.map { EntreeAquarium(date: $0, instantane: instantane) }
        completion(Timeline(entries: entrees, policy: .atEnd))
    }
}

struct AquariumWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DepotAquariumWidget.genre, provider: FournisseurAquarium()) { entree in
            VueAquariumWidget(entree: entree)
        }
        .configurationDisplayName("Mon aquarium")
        .description("Les poissons de ton Pescedex.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge, .systemExtraLargePortrait,
            .accessoryRectangular, .accessoryCircular,
        ])
        .contentMarginsDisabled()
    }
}

#if DEBUG
private extension InstantaneAquarium {
    static var exemple: InstantaneAquarium {
        InstantaneAquarium(
            poissons: [
                .init(id: "p1", slug: "brochet", rarete: 3, relache: true),
                .init(id: "p2", slug: "sandre", rarete: 2, relache: false),
                .init(id: "p3", slug: "perche-commune", rarete: 1, relache: true),
                .init(id: "p4", slug: "perche-commune", rarete: 0, relache: true, nombre: 3),
                .init(id: "p5", slug: "sandre", rarete: 0, relache: false),
            ],
            especes: 3, rations: 2, estPro: true,
            dernierRepas: nil, misAJour: .now
        )
    }
}

#Preview(as: .systemMedium) {
    AquariumWidget()
} timeline: {
    EntreeAquarium(date: .now, instantane: .exemple)
    EntreeAquarium(date: .now.addingTimeInterval(30), instantane: .exemple)
}
#endif
