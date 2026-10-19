import Foundation

/// Un profil public de pêcheur : surnom et avatar, rien d'autre. Nom et prénom n'existent pas ici (décision 3).
nonisolated struct ProfilModele: Sendable, Equatable, Hashable, Identifiable {
    /// `recordName` de l'enregistrement : `p-` + surnom normalisé.
    var id: String
    /// Le surnom comme la personne l'a écrit (« Gros-Brochet »).
    var surnom: String
    /// JPEG de 256 px sans EXIF, ou `nil` : l'initiale du surnom prend la place.
    var avatar: Data?
    var creeLe: Date
}

nonisolated enum ErreurProfil: Error, Equatable, Sendable {
    case surnomInvalide(Surnom.Refus)
    /// Pris par quelqu'un d'autre, ou perdu dans une course entre deux iPhones : la personne en choisit un autre.
    case surnomPris
    case reseau
    case iCloudIndisponible
    case imageRefusee
    case introuvable
    /// Une partie du contenu n'a pas pu être effacée : le profil est gardé pour réessayer.
    case effacementIncomplet
    case autre
}

/// Ce que `Signalement` d'un profil peut dire : liste fermée, pas de texte libre (`moderation.md`).
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

/// Ce que L23 (publications, commentaires) et L24 (messages) savent effacer pour un profil. A les compose dans `GestionProfil`.
/// Chaque effaceur lève une erreur s'il n'a pas pu tout effacer : le profil est alors gardé, la personne peut réessayer.
nonisolated protocol EffaceurContenu: Sendable {
    func effacerContenu(deProfil profilID: String) async throws
}

/// Les effaceurs enregistrés. L23 et L24 (ou A, à la composition) appellent `ajouter` ; sans eux, seul le profil s'efface.
@MainActor
final class RegistreEffaceurs {
    static let partage = RegistreEffaceurs()
    private(set) var effaceurs: [any EffaceurContenu] = []

    func ajouter(_ effaceur: any EffaceurContenu) {
        effaceurs.append(effaceur)
    }
}
