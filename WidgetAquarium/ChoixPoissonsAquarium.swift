import AppIntents
import Foundation

// Fichier à ajouter aux DEUX cibles (app et widget), comme NourrirAquariumIntent.swift : les types d'AppIntents
// doivent exister dans l'app aussi. Le choix des poissons de « Mon aquarium » (Adem, 16 oct.) : appui long sur le
// widget, « Modifier le widget », puis on choisit UN poisson parmi tout le Pescedex (Titouan, 7 nov.).
// Aucun lieu : la liste ne montre que des noms d'espèces.

/// Un poisson de la liste de choix. L'id est celui du `Poisson` de l'instantané.
nonisolated struct PoissonAquariumEntite: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Poisson"
    static let defaultQuery = RequetePoissonsAquarium()

    var id: String
    var slug: String
    var nom: String
    var rarete: Int

    nonisolated init(_ poisson: InstantaneAquarium.Poisson) {
        id = poisson.id
        slug = poisson.slug
        // Sans nom commun, le slug de l'image fait l'affaire (« perche-commune »).
        nom = poisson.nom ?? poisson.slug
        rarete = poisson.rarete
    }

    private var libelleRarete: String {
        switch rarete {
        case 3: "Légendaire"
        case 2: "Rare"
        case 1: "Peu commun"
        default: "Commun"
        }
    }

    var displayRepresentation: DisplayRepresentation {
        // L'image vient du catalogue de la cible qui affiche la liste (le widget) ; si elle manque, iOS n'en met pas.
        DisplayRepresentation(
            title: "\(nom)",
            subtitle: "\(libelleRarete)",
            image: DisplayRepresentation.Image(named: slug)
        )
    }
}

/// Lit le Pescedex dans le fichier partagé (App Group). Aucune requête réseau.
nonisolated struct RequetePoissonsAquarium: EntityQuery {
    nonisolated init() {}

    /// Les poissons demandés, dans l'ordre demandé ; un id disparu est ignoré.
    func entities(for identifiers: [String]) async throws -> [PoissonAquariumEntite] {
        let parId = Dictionary(
            DepotAquariumWidget.lire().poissons.map { ($0.id, $0) },
            uniquingKeysWith: { premier, _ in premier })
        return identifiers.compactMap { parId[$0].map(PoissonAquariumEntite.init) }
    }

    /// Tout le Pescedex, les plus rares d'abord (l'ordre du fichier).
    func suggestedEntities() async throws -> [PoissonAquariumEntite] {
        DepotAquariumWidget.lire().poissons.map(PoissonAquariumEntite.init)
    }
}

/// La configuration du widget : le poisson choisi.
struct ChoixAquariumIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choisir le poisson"
    static let description = IntentDescription("Le poisson de ton Pescedex qui nage dans le widget.")

    /// UN seul poisson (Titouan, 7 nov.). Vide : celui choisi dans l'app, sinon le plus rare.
    @Parameter(title: "Poisson")
    var poisson: PoissonAquariumEntite?

    /// Le choix sous forme de liste (zéro ou un poisson) : pour le code qui lisait l'ancienne liste.
    var poissons: [PoissonAquariumEntite]? { poisson.map { [$0] } }

    nonisolated init() {}
}
