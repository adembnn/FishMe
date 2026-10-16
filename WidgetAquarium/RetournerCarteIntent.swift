import AppIntents
import Foundation

// Fichier à ajouter aux DEUX cibles (app et widget) : le bouton du widget s'exécute dans le processus du widget,
// mais AppIntents veut aussi les types dans l'app (comme NourrirAquariumIntent).
// Trois types : le bouton qui retourne la carte, la carte vue comme choix de réglage, et le réglage du widget.
// Aucun lieu, aucune donnée de pêche : seulement un id de carte.

/// Toucher la carte l'autre face. WidgetKit recharge le widget tout seul après un bouton d'intent.
struct RetournerCarteIntent: AppIntent {
    static let title: LocalizedStringResource = "Retourner la carte"
    static let openAppWhenRun = false

    @Parameter(title: "Carte")
    var idCarte: String

    nonisolated init() {
        self.idCarte = ""
    }

    nonisolated init(idCarte: String) {
        self.idCarte = idCarte
    }

    nonisolated func perform() async throws -> some IntentResult {
        // Inverse `faceVisible[id]` et écrit ; ne fait rien si la carte n'existe plus.
        DepotCartesWidget.retourner(id: idCarte)
        return .result()
    }
}

/// Une carte du Pescedex, telle que la liste de choix du widget la propose.
nonisolated struct CarteWidgetEntite: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Carte"
    static let defaultQuery = RequeteCartesWidget()

    var id: String
    /// Le nom ne sert qu'à la liste de choix, jamais à la carte dessinée.
    var nom: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(nom)")
    }

    init(id: String, nom: String) {
        self.id = id
        self.nom = nom
    }

    init(_ carte: InstantaneCartes.Carte) {
        self.id = carte.id
        self.nom = carte.nom ?? "Carte"
    }
}

nonisolated struct RequeteCartesWidget: EntityQuery {
    nonisolated init() {}

    func entities(for identifiers: [String]) async throws -> [CarteWidgetEntite] {
        let instantane = DepotCartesWidget.lire()
        return identifiers.compactMap { instantane.carte(id: $0) }.map(CarteWidgetEntite.init)
    }

    func suggestedEntities() async throws -> [CarteWidgetEntite] {
        DepotCartesWidget.lire().cartes.map(CarteWidgetEntite.init)
    }
}

/// Le réglage du widget : quelle carte afficher. Rien de choisi : la plus rare, puis la plus récente.
struct ChoixCarteIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Choisir la carte"
    static let description = IntentDescription("Choisis la carte de ton Pescedex à montrer.")

    @Parameter(title: "Carte")
    var carte: CarteWidgetEntite?

    nonisolated init() {}
}
