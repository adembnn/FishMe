import Foundation
import Observation
import Core

/// L'état d'abonné que l'app lit. A le branche : `moteur.abonne = suivi.abonne` à chaque changement.
@MainActor @Observable
final class SuiviAbonnement {
    private(set) var etat: EtatAchats = .nonAbonne
    var abonne: Bool { etat.donneAcces }

    @ObservationIgnored private let achats: Achats
    @ObservationIgnored private var tache: Task<Void, Never>?

    init(achats: Achats) { self.achats = achats }

    /// Lit l'état au lancement puis suit les changements (renouvellement, remboursement, achat sur un autre appareil).
    func demarrer() {
        guard tache == nil else { return }
        let source = achats
        tache = Task { [weak self] in
            let initial = await source.etat()
            self?.etat = initial
            for await nouvel in source.modifications() { self?.etat = nouvel }
        }
    }

    func appliquer(_ nouvel: EtatAchats) { etat = nouvel }
}
