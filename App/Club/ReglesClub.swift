import Foundation

/// Qui peut entrer, qui peut sortir, et comment. Fonctions pures : tout se teste sans iPhone ni réseau.
nonisolated enum RegleAdhesion {
    /// `nil` si `profil` peut rejoindre `club`. Être déjà membre n'est jamais une erreur (rejoindre deux fois ne fait rien).
    static func verifier(club: Club, membres: [Membre], profil: String) -> ErreurClub? {
        if club.ferme { return .clubFerme }
        if club.estEcarte(profil) { return .ecarte }
        if membres.contains(where: { $0.profil == profil }) { return nil }
        // R2 : sans fondateur, personne n'admet plus de nouveau membre dans la zone du chat. On n'y entre plus.
        if club.etat(membres: membres) == .sansFondateur { return .sansFondateur }
        return nil
    }

    nonisolated enum Sortie: Sendable, Equatable {
        /// Fondateur seul : le club est fermé.
        case fermer
        /// Tous les autres cas : mon adhésion et mes cartes disparaissent, le club reste.
        /// Fondateur qui part avec des membres encore là : le club reste SANS fondateur (R2 : pas de transfert possible).
        case quitter
    }

    static func sortie(club: Club, membres: [Membre], profil: String) -> Sortie {
        let autres = membres.filter { $0.profil != profil && !club.estEcarte($0.profil) }
        return club.fondateur == profil && autres.isEmpty ? .fermer : .quitter
    }

    /// Les membres à montrer : sans les écartés, dans l'ordre d'arrivée (le fondateur en premier à égalité de date).
    static func visibles(_ membres: [Membre], club: Club) -> [Membre] {
        membres.filter { !club.estEcarte($0.profil) }
            .sorted { ($0.depuis, $0.role == .fondateur ? 0 : 1, $0.id) < ($1.depuis, $1.role == .fondateur ? 0 : 1, $1.id) }
    }

    /// Le fondateur peut écarter un autre membre, jamais lui-même, et seulement tant qu'il est là.
    static func peutEcarter(club: Club, membres: [Membre], moi: String, cible: String) -> Bool {
        moi == club.fondateur && cible != moi && !club.ferme && club.etat(membres: membres) == .actif
    }
}

/// Le record du club : la plus grande taille parmi les cartes visibles. Aucune taille = pas de record.
nonisolated enum RecordDuClub {
    static func meilleure(_ cartes: [CartePartageeClub]) -> CartePartageeClub? {
        cartes.filter { ($0.tailleCm ?? 0) > 0 }
            .max { ($0.tailleCm ?? 0, $0.id) < ($1.tailleCm ?? 0, $1.id) }
    }
}
