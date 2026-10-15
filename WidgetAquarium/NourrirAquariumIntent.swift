import AppIntents
import Foundation

// Fichier à ajouter aux DEUX cibles (app et widget) : le bouton du widget s'exécute dans le processus du widget,
// mais AppIntents veut aussi le type dans l'app.
// Le bouton « nourrir » du widget moyen, grand et très grand. WidgetKit recharge le widget tout seul après un bouton d'intent.
// Aucun lieu, aucune donnée de pêche : seulement les rations et l'heure du dernier repas.

nonisolated struct NourrirAquariumIntent: AppIntent {
    static let title: LocalizedStringResource = "Nourrir les poissons"
    static let openAppWhenRun = false

    nonisolated init() {}

    nonisolated func perform() async throws -> some IntentResult {
        var instantane = DepotAquariumWidget.lire()
        // Réservé à Pro ; sans ration, `nourrir` ne change rien et rend false.
        if instantane.estPro, instantane.nourrir(maintenant: .now) {
            instantane.misAJour = .now
            try? DepotAquariumWidget.ecrire(instantane)
        }
        return .result()
    }
}
