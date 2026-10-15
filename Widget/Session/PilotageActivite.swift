import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit

// Cible APP (et non widget) : A appelle ces trois fonctions depuis `RootView.swift`, quand L5 signale le début
// de session, chaque prise et la fin. `Widget/` n'importe pas `App/Session/` : on ne passe que des valeurs
// (heure de départ, `finLegale` de Core, nombre de prises). Le départ se fait app au premier plan seulement.
//
// Si les Live Activities sont désactivées, ou si la demande échoue : on continue sans activité, sans message d'erreur.

@MainActor
public final class PilotageActivite {
    private var activite: Activity<SessionActivityAttributes>?

    public init() {}

    /// À appeler au départ de session, app au premier plan.
    public func demarrer(debut: Date, finLegale: Date?, maintenant: Date = .now) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let etat = EtatSession(debut: debut, finLegale: finLegale, prises: 0)
        let contenu = ActivityContent(state: etat, staleDate: etat.heurePerimee(maintenant: maintenant))
        activite = try? Activity.request(attributes: SessionActivityAttributes(), content: contenu, pushType: nil)
    }

    /// À appeler à chaque prise (le nombre vient de L5).
    public func mettreAJour(prises: Int, maintenant: Date = .now) async {
        guard let activite else { return }
        var etat = activite.content.state
        etat.prises = prises
        await activite.update(ActivityContent(state: etat, staleDate: etat.heurePerimee(maintenant: maintenant)))
    }

    /// À appeler à la fin de session. Le dernier état reste lisible un moment, puis le système retire l'activité.
    public func terminer() async {
        guard let activite else { return }
        await activite.end(ActivityContent(state: activite.content.state, staleDate: nil), dismissalPolicy: .default)
        self.activite = nil
    }
}

#if DEBUG
extension PilotageActivite {
    /// Faux de travail, en attendant L5 : départ maintenant, fin légale dans `minutes` minutes (essai de 2 min du test 1).
    /// Heures écrites en dur, aucune donnée de pêche ; à ne jamais brancher hors `#if DEBUG`.
    public func demarrerFaux(finLegaleDansMinutes minutes: Double = 2) {
        let maintenant = Date.now
        demarrer(debut: maintenant, finLegale: maintenant.addingTimeInterval(minutes * 60), maintenant: maintenant)
    }

    /// Départ hors de la fenêtre légale : la fin légale est déjà passée (test 2).
    public func demarrerFauxHorsFenetre() {
        let maintenant = Date.now
        demarrer(debut: maintenant, finLegale: maintenant.addingTimeInterval(-30 * 60), maintenant: maintenant)
    }
}
#endif
#endif
