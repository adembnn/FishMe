import Foundation
import WidgetKit

// Cible APP seulement. Le pont entre l'app et le widget « Mon aquarium » (A le branche dans RootView).
// À appeler :
//   - `publier(poissons:especes:estPro:)` après chaque carte ajoutée au Pescedex,
//     et au changement d'abonnement (achat, expiration, restauration) ;
//   - `ajouterRations(_:)` à la fin d'une session (une session terminée donne une ration) ;
//     puis `publier` si la collection a aussi changé.
// Le fichier partagé est la vérité des rations et du dernier repas : le widget en consomme, donc l'app
// relit toujours le fichier avant d'écrire et ne touche qu'à ce qui lui appartient.
// Tout est en `try?` : un App Group absent ou un disque plein ne font jamais planter l'app.

nonisolated enum PontAquariumWidget {
    /// Passer TOUT le Pescedex (une entrée par carte ou par espèce regroupée, les plus rares d'abord, 200 au plus),
    /// pas seulement 5 : le pêcheur choisit ceux qui nagent par « Modifier le widget ». Passer aussi le nom commun
    /// de chaque espèce dans `Poisson.nom` (« Brochet ») : la liste de choix l'affiche, le widget jamais.
    /// Remplace les poissons, le nombre d'espèces et l'abonnement ; garde les rations et le dernier repas du fichier.
    static func publier(poissons: [InstantaneAquarium.Poisson], especes: Int, estPro: Bool) {
        let actuel = DepotAquariumWidget.lire()
        let neuf = InstantaneAquarium(
            poissons: poissons,
            especes: especes,
            rations: actuel.rations,
            estPro: estPro,
            dernierRepas: actuel.dernierRepas,
            misAJour: .now
        )
        ecrireEtRecharger(neuf)
    }

    /// Une session terminée donne des rations.
    static func ajouterRations(_ n: Int) {
        guard n > 0 else { return }
        var instantane = DepotAquariumWidget.lire()
        instantane.rations += n
        instantane.misAJour = .now
        ecrireEtRecharger(instantane)
    }

    private static func ecrireEtRecharger(_ instantane: InstantaneAquarium) {
        try? DepotAquariumWidget.ecrire(instantane)
        WidgetCenter.shared.reloadTimelines(ofKind: DepotAquariumWidget.genre)
    }
}
