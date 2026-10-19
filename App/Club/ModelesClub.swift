import Core
import Foundation

// Les types du club en ligne (L22). Ils suivent `docs/reports/reseau/schema.md` (R2) :
//  - `Club` et `Membre` : types 5 et 6 de la base publique ;
//  - `CartePartageeClub` : R2 écarte un 10e type et replie la carte dans `Publication` (champ `club` rempli, `recordName` = `pc-<club>-<carte>`).
//    Écart avec la fiche L22 (qui prévoit un type à part) : on suit R2, la carte est donc aussi lue par le fil de L23 (« Tes clubs »).
// Rien ici ne porte une coordonnée : la carte s'arrête au département.

/// Un club en ligne. L'identifiant est l'UUID du club (celui du `ClubLocal` d'origine pour un club migré).
nonisolated struct Club: Sendable, Equatable, Hashable, Identifiable {
    var id: String
    var nom: String
    /// Image choisie parmi les poissons, ou `nil` si le club a une photo.
    var poissonId: String?
    /// JPEG de 512 px sans EXIF, ou `nil`.
    var image: Data?
    /// `recordName` du `Profil` du fondateur (`p-<surnom normalisé>`, L21). Ne change jamais (R2) : seul le créateur d'un enregistrement l'écrit.
    var fondateur: String
    /// Membres écartés par le fondateur (R2 : il ne peut pas supprimer leur `Membre`, il les écarte par cette liste).
    var retires: [String] = []
    var ferme: Bool = false
    var creeLe: Date
}

nonisolated enum RoleMembre: String, Sendable, Equatable {
    case fondateur
    case membre
}

/// Une adhésion : `recordName` = `m-<club>-<profil>`, une par personne et par club.
nonisolated struct Membre: Sendable, Equatable, Hashable, Identifiable {
    var id: String
    var club: String
    /// `recordName` du `Profil` (L21).
    var profil: String
    var role: RoleMembre
    var depuis: Date

    static func identifiant(club: String, profil: String) -> String { "m-\(club)-\(profil)" }
}

/// Une carte partagée au club : une `Publication` dont le champ `club` est rempli (R2).
/// L'image est le PNG de la collection, réécrit sans métadonnées ; le lieu s'arrête au département (« 94 »), jamais plus précis.
nonisolated struct CartePartageeClub: Sendable, Equatable, Hashable, Identifiable {
    /// `recordName` : `pc-<club>-<carte>`.
    var id: String
    var club: String
    /// Identifiant de la carte dans la collection du membre.
    var carteID: String
    /// `recordName` du profil de l'auteur.
    var auteur: String
    var espece: String
    var rarete: NiveauRarete?
    var tailleCm: Double?
    /// Code du département (« 94 ») ou vide : aucun lieu.
    var departement: String
    /// PNG sans GPS ; `nil` tant que le média n'est pas téléchargé.
    var image: Data?
    var creeLe: Date

    static func identifiant(club: String, carte: String) -> String { "pc-\(club)-\(carte)" }
}

/// Ce que `Club.fondateur` permet encore, déduit de la liste des membres.
/// R2 : le transfert du rôle de fondateur est IMPOSSIBLE en base publique. Un fondateur qui quitte alors qu'il reste des membres
/// laisse un club « sans fondateur » : lisible, on peut encore y partager et le quitter, mais plus écarter un membre, plus y entrer,
/// et le chat de club (zone partagée possédée par le fondateur) n'admet plus personne. « À reprendre » = suppression ou reprise à la main
/// dans le tableau de bord CloudKit. On ne promet aucun transfert.
nonisolated enum EtatClub: Sendable, Equatable {
    case actif
    case ferme
    case sansFondateur
}

extension Club {
    /// `membres` : les adhésions lues. Un fondateur dont l'adhésion a disparu (il est parti, ou son profil est supprimé) = club sans fondateur.
    func etat(membres: [Membre]) -> EtatClub {
        if ferme { return .ferme }
        return membres.contains { $0.role == .fondateur && $0.profil == fondateur } ? .actif : .sansFondateur
    }

    func estEcarte(_ profil: String) -> Bool { retires.contains(profil) }
}

nonisolated enum ErreurClub: Error, Equatable, Sendable {
    case reseau
    case iCloudIndisponible
    case introuvable
    /// Le fondateur a fermé le club.
    case clubFerme
    /// Plus de fondateur : on n'y entre plus (R2, voir `EtatClub`).
    case sansFondateur
    /// Le fondateur m'a écarté.
    case ecarte
    /// Pas de profil (L21) : « Finis ton profil ». Avoir un profil vaut déclaration « 15 ans ou plus » (L21 ne le crée pas sans).
    case profilRequis
    case nomRefuse
    case imageRefusee
    /// Une action réservée au fondateur, tentée par un autre (ou fondateur parti).
    case refuse
    case autre
}

/// Ce que montre la feuille « Rejoindre » avant de rejoindre.
nonisolated struct ApercuClub: Sendable, Equatable {
    var club: Club
    var nombreDeMembres: Int
    var etat: EtatClub
    var dejaMembre: Bool
}

/// Les motifs de signalement d'une carte de club : la liste fermée de L21 (`MotifSignalement`).
/// ⚠ L23 a sa propre liste (`MotifSignalementPublication`, « haine » là où L21 dit « harcelement ») : A harmonise à la composition.
typealias MotifSignalementClub = MotifSignalement
