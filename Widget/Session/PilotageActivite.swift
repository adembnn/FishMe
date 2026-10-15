import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit

// Cible APP seulement (pas la cible widget) : A appelle ces fonctions depuis `RootView.swift`, quand L5 signale le début
// de session, chaque prise et la fin. `Widget/` n'importe pas `App/Session/` : on ne passe que des valeurs
// (heure de départ, `finLegale` de Core, nombre de prises). Le départ se fait app au premier plan seulement.
//
// Si les Live Activities sont désactivées, ou si la demande échoue : on continue sans activité, sans message d'erreur.

@MainActor
public final class PilotageActivite {
    private var activite: Activity<SessionActivityAttributes>?

    public init() {}

    /// À appeler au départ de session, app au premier plan.
    public func demarrer(debut: Date, finLegale: Date?, prises: Int = 0, maintenant: Date = .now) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let etat = EtatSession(debut: debut, finLegale: finLegale, prises: prises)
        let contenu = ActivityContent(state: etat, staleDate: etat.heurePerimee(maintenant: maintenant))
        activite = try? Activity.request(attributes: SessionActivityAttributes(), content: contenu, pushType: nil)
    }

    /// À appeler au lancement de l'app quand L5 rend une session déjà en cours (`MoteurSession.reprendre`) :
    /// reprend l'activité encore affichée, sinon en démarre une (l'app est au premier plan). Les doublons sont retirés.
    public func reprendre(debut: Date, finLegale: Date?, prises: Int, maintenant: Date = .now) async {
        let existantes = Activity<SessionActivityAttributes>.activities
        if let premiere = existantes.first {
            for autre in existantes.dropFirst() {
                await autre.end(nil, dismissalPolicy: .immediate)
            }
            activite = premiere
            let etat = EtatSession(debut: debut, finLegale: finLegale, prises: prises)
            // Activity n'est pas Sendable : la copie locale lève l'alerte de concurrence de Swift 6 (appel unique, sur MainActor).
            nonisolated(unsafe) let cible = premiere
            await cible.update(ActivityContent(state: etat, staleDate: etat.heurePerimee(maintenant: maintenant)))
        } else {
            demarrer(debut: debut, finLegale: finLegale, prises: prises, maintenant: maintenant)
        }
    }

    /// À appeler à chaque prise (le nombre vient de L5 : `MoteurSession.nombrePrises`).
    public func mettreAJour(prises: Int, maintenant: Date = .now) async {
        guard let activite else { return }
        var etat = activite.content.state
        etat.prises = prises
        nonisolated(unsafe) let cible = activite
        await cible.update(ActivityContent(state: etat, staleDate: etat.heurePerimee(maintenant: maintenant)))
    }

    /// À appeler à la fin de session (bouton, fin légale ou reprise après la fin légale).
    /// Fin légale atteinte : « fin légale 19:33 » en texte fixe reste sur l'écran verrouillé (le système la retire seul, au plus 4 h après).
    /// Arrêt avant la fin légale : retrait immédiat, pour ne pas laisser un compte à rebours qui court pour rien.
    public func terminer(maintenant: Date = .now) async {
        let toutes = Activity<SessionActivityAttributes>.activities
        for a in toutes {
            let etat = a.content.state
            let finie = etat.finLegale.map { $0 > etat.debut && maintenant >= $0 } ?? false
            await a.end(ActivityContent(state: etat, staleDate: nil), dismissalPolicy: finie ? .default : .immediate)
        }
        activite = nil
    }
}

#if DEBUG
extension PilotageActivite {
    /// Faux de travail, en attendant le branchement : départ maintenant, fin légale dans `minutes` minutes (essai de 2 min du test 1).
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
