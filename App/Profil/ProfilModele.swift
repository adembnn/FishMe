import Foundation

/// Un profil public de pêcheur : surnom et avatar, rien d'autre (décision 3 : juste un pseudonyme, aucun nom ni prénom nulle part).
nonisolated struct ProfilModele: Sendable, Equatable, Hashable, Identifiable {
    /// `recordName` de l'enregistrement `ProfilPublic` : `p-` + surnom normalisé, ASCII seulement.
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
    /// « Retrouver mon profil » n'a rien trouvé au nom de ce compte iCloud.
    case profilIntrouvable
    case autre
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
