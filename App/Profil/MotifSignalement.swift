import Foundation

/// LA liste des motifs de signalement de FishMe (décision de Titouan, 19 oct. : une seule énumération partagée).
/// Liste fermée, pas de texte libre (`moderation.md`). Les autres lots (L22, L23, L24) l'UTILISENT telle quelle, ils n'ont pas
/// de liste à eux : `rawValue` est ce qui s'écrit dans le champ `motif` du type CloudKit `Signalement`, `titre` est ce que la personne lit.
/// Ne change pas un `rawValue` sans prévenir : les signalements déjà écrits le portent.
nonisolated enum MotifSignalement: String, CaseIterable, Sendable, Identifiable {
    case choquant, harcelement, nudite, cruaute, pecheIllegale, coinExact, mineur, spam, autre

    var id: String { rawValue }

    var titre: String {
        switch self {
        case .choquant: "Contenu choquant ou violent"
        case .harcelement: "Haine ou harcèlement"
        case .nudite: "Nudité ou contenu sexuel"
        case .cruaute: "Cruauté envers un animal"
        case .pecheIllegale: "Pêche illégale"
        case .coinExact: "Coin de pêche exact révélé"
        case .mineur: "Personne mineure sans accord"
        case .spam: "Spam ou publicité"
        case .autre: "Autre"
        }
    }

    var symbole: String {
        switch self {
        case .choquant: "exclamationmark.triangle"
        case .harcelement: "bubble.left.and.exclamationmark.bubble.right"
        case .nudite: "eye.slash"
        case .cruaute: "pawprint"
        case .pecheIllegale: "scalemass"
        case .coinExact: "mappin.slash"
        case .mineur: "person.crop.circle.badge.exclamationmark"
        case .spam: "megaphone"
        case .autre: "flag"
        }
    }
}

/// Ce qu'on signale : écrit dans le champ `typeCible` du type `Signalement`.
nonisolated enum CibleSignalement: String, CaseIterable, Sendable {
    case profil, ami, carte, publication, commentaire, message
}

/// Ce que l'écran a le droit de dire (décision 19 oct., « signalement honnête ») :
/// « signalé » SEULEMENT si l'enregistrement `Signalement` est bien en base ; sinon « Pas enregistré, réessaie ».
nonisolated enum ResultatSignalement: Equatable, Sendable {
    case enregistre
    case nonEnregistre

    /// Le titre court de l'alerte.
    var titre: String {
        switch self {
        case .enregistre: "Merci, c'est signalé"
        case .nonEnregistre: "Pas enregistré, réessaie"
        }
    }

    /// Ce qui est vrai dans chaque cas : le masquage est local et immédiat, l'enregistrement dépend du réseau.
    func message(masque: Bool) -> String {
        switch self {
        case .enregistre:
            masque ? "Ton signalement est enregistré. Ce profil est masqué chez toi." : "Ton signalement est enregistré."
        case .nonEnregistre:
            masque ? "Ton signalement n'a pas pu être enregistré (réseau ou iCloud). Ce profil est déjà masqué chez toi. Réessaie."
                : "Ton signalement n'a pas pu être enregistré (réseau ou iCloud). Réessaie."
        }
    }
}
