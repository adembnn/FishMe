import Foundation
import Core

/// Ce que StoreKit dit d'un abonnement, réduit à ce qui compte (testable sans StoreKit).
nonisolated enum StatutAbonnement: Sendable, Equatable {
    case abonne
    /// Paiement refusé, mais l'accès reste (délai de grâce activé par MWM).
    case delaiDeGrace(fin: Date?)
    /// Paiement refusé après la grâce : l'accès tombe.
    case relancePaiement
    case expire
    /// Remboursé par Apple.
    case rembourse
    /// Accès retiré (partage familial arrêté, révocation).
    case revoque
}

nonisolated enum ResolveurEtat {
    /// La durée de grâce de repli si Apple ne donne pas la date de fin (16 jours, le réglage du kit).
    static let graceParDefaut: TimeInterval = 16 * 86_400

    static func etat(statut: StatutAbonnement, maintenant: Date) -> EtatAchats {
        switch statut {
        case .abonne: return .abonne
        case .delaiDeGrace(let fin): return .delaiDeGrace(fin: fin ?? maintenant.addingTimeInterval(graceParDefaut))
        case .relancePaiement: return .relancePaiement
        case .expire: return .expire
        case .rembourse: return .rembourse
        case .revoque: return .revoque
        }
    }

    /// Si plusieurs abonnements existent, le plus favorable gagne : un accès ouvert l'emporte sur un accès fermé.
    static func etat(statuts: [StatutAbonnement], maintenant: Date) -> EtatAchats {
        guard !statuts.isEmpty else { return .nonAbonne }
        let etats = statuts.map { etat(statut: $0, maintenant: maintenant) }
        return etats.first(where: { $0.donneAcces }) ?? etats[0]
    }

    /// Sans réseau, le dernier état vérifié sert : jamais un écran bloqué.
    static func sansReseau(dernierEtat: EtatAchats) -> EtatAchats {
        if case .sansReseau = dernierEtat { return dernierEtat }
        return .sansReseau(dernierEtatAbonne: dernierEtat.donneAcces)
    }
}
