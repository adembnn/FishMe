import Foundation
import WidgetKit

// Cible APP seulement. Le pont entre l'app et le widget « Ma session » (A le branche dans RootView).
// À appeler aux MÊMES endroits que `PilotageActivite` (Widget/Session/PilotageActivite.swift) :
//   - démarrer       -> `publier(etat)`
//   - reprendre      -> `publier(etat)`
//   - mettreAJour    -> `publier(etat)` (nouvelle prise, nouvelle fin légale)
//   - terminer       -> `publier(nil)` (plus de session : le widget invite à en lancer une)
// Tout est en `try?` : un App Group absent ou un disque plein ne font jamais planter l'app.

nonisolated enum PontSessionWidget {
    /// Écrit l'état dans le conteneur partagé (nil efface le fichier) puis recharge le widget.
    static func publier(_ etat: EtatSession?) {
        try? DepotSessionWidget.ecrire(etat)
        WidgetCenter.shared.reloadTimelines(ofKind: DepotSessionWidget.genre)
    }
}
