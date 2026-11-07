import AppIntents
import SwiftUI
import WidgetKit

// Cible widget seulement. Le widget « Mon aquarium » : les poissons du Pescedex qui nagent sur l'écran d'accueil.
// Les poissons se choisissent par « Modifier le widget » (3 au plus en petit, 5 ailleurs). Petit gratuit ; moyen, grand et très grand avec Pro (Adem, 15 oct. 21h50 : « grand format Pro »).
// Aucun lieu : l'écran d'accueil et l'écran verrouillé sont vus par d'autres. Aucun faux poisson : vide = état vide.

/// Une image de l'aquarium à une date donnée.
nonisolated struct EntreeAquarium: TimelineEntry, Sendable {
    let date: Date
    let instantane: InstantaneAquarium
}

nonisolated struct FournisseurAquarium: AppIntentTimelineProvider {
    typealias Intent = ChoixAquariumIntent

    /// Le système rend cette entrée floutée (`.placeholder`) ; elle ne contient aucun poisson.
    func placeholder(in context: Context) -> EntreeAquarium {
        EntreeAquarium(date: .now, instantane: .vide)
    }

    func snapshot(for configuration: ChoixAquariumIntent, in context: Context) async -> EntreeAquarium {
        // Les vraies données ; si l'aquarium est vide, c'est l'état vide, jamais de poissons d'exemple.
        EntreeAquarium(date: .now, instantane: Self.instantane(configuration, famille: context.family))
    }

    func timeline(for configuration: ChoixAquariumIntent, in context: Context) async -> Timeline<EntreeAquarium> {
        let instantane = Self.instantane(configuration, famille: context.family)
        // Peu d'entrées : l'extension rend et archive CHAQUE entrée d'un coup, son pic de mémoire monte avec leur
        // nombre (mesuré le 7 nov., lot/widget-fluide). La timeline se recharge à la fin (.atEnd) : 2 h ici, soit
        // 12 rechargements par jour, dans le budget d'Apple (40 à 70 par jour).
        var dates = Array(NageWidget.dates(depuis: .now, dernierRepas: instantane.dernierRepas).prefix(Self.entreesMax))
        if dates.isEmpty { dates = [.now] }
        #if DEBUG
        // Essai piste c seulement : une entrée toutes les 10 s pendant 10 min (Apple demande ~5 min entre entrées).
        if PisteNage.widget == .glisse {
            let depart = Date(timeIntervalSince1970: (Date.now.timeIntervalSince1970 / 10).rounded(.down) * 10)
            dates = (0..<60).map { depart.addingTimeInterval(Double($0) * 10) }
        }
        #endif
        let entrees = dates.map { EntreeAquarium(date: $0, instantane: instantane) }
        return Timeline(entries: entrees, policy: .atEnd)
    }

    /// Entrées par timeline (créneaux de 20 min : 2 h).
    static let entreesMax: Int = {
        #if DEBUG
        if let url = DepotAquariumWidget.url()?.deletingLastPathComponent().appendingPathComponent("entrees-widget.txt"),
           let texte = try? String(contentsOf: url, encoding: .utf8),
           let n = Int(texte.trimmingCharacters(in: .whitespacesAndNewlines)), n > 0 {
            return n
        }
        #endif
        return 7
    }()

    /// Le fichier partagé, réduit aux poissons choisis (dans l'ordre choisi) ou, sans choix, aux plus rares.
    /// Le nombre d'espèces, les rations et l'abonnement restent ceux du fichier entier.
    private static func instantane(_ configuration: ChoixAquariumIntent, famille: WidgetFamily) -> InstantaneAquarium {
        var instantane = DepotAquariumWidget.lire()
        let ids = configuration.poissons?.map(\.id)
        instantane.poissons = instantane.retenus(choisis: ids, limite: limitePoissons(famille))
        return instantane
    }
}

struct AquariumWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: DepotAquariumWidget.genre, intent: ChoixAquariumIntent.self,
                               provider: FournisseurAquarium()) { entree in
            VueAquariumLue(entree: entree)
        }
        .configurationDisplayName("Mon aquarium")
        .description("Tes poissons nagent et changent de place au fil de la journée. Appui long pour choisir lesquels.")
        .supportedFamilies(Self.familles)
        .contentMarginsDisabled()
    }

    /// Le grand format portrait n'existe qu'à partir d'iOS 27 ; en iOS 26 l'aquarium garde les autres tailles.
    private static var familles: [WidgetFamily] {
        var f: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular]
        if #available(iOS 27, *) { f.insert(.systemExtraLargePortrait, at: 3) }
        return f
    }
}

/// Lit la famille dans l'environnement du widget, puis la passe à la vue (qui, elle, n'en lit plus :
/// elle peut ainsi se rendre hors widget, pour les tests d'image).
private struct VueAquariumLue: View {
    let entree: EntreeAquarium
    @Environment(\.widgetFamily) private var famille

    var body: some View {
        VueAquariumWidget(entree: entree, famille: famille)
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    AquariumWidget()
} timeline: {
    // Date de maintenant : le canevas d'Xcode fait tourner les chronos, les poissons doivent y nager.
    EntreeAquarium.exempleRendu(pro: true, date: .now)
    EntreeAquarium.exempleRendu(pro: true, repas: true, date: .now)
}
#endif
