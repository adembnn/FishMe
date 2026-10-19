import Foundation

/// LA liste de blocage de l'app (décision 19 oct. : une seule). Elle vit ici, dans `App/Profil/`.
///
/// Contrat pour L23 (fil, commentaires) et L24 (chat, `AnnuaireChat.bloques()`) : ils n'ont PAS de liste à eux, ils LISENT celle-ci.
/// - La clé est l'identifiant public d'un profil : `p-` + surnom normalisé, ASCII (`Surnom.identifiant(pour:)`, `ProfilModele.id`).
/// - « Caché » = bloqué (choix de la personne) OU masqué (signalé : masquage immédiat, règle 1.2). Le fil, les commentaires, les messages, la
///   recherche et la liste d'amis cachent tout profil caché ; aucun lot ne décide à sa place.
/// - Lire : `ListeBlocages.partage.estCache(id)`, ou `profilsCaches()` pour filtrer une liste d'un coup. Les deux sont synchrones
///   (UserDefaults) et lisibles depuis n'importe quel acteur.
/// - Écrire : `bloquer`, `masquer`, `debloquer`. Seuls L21 (profil, amis) et l'écran de signalement écrivent. L23 et L24 n'écrivent pas :
///   pour signaler ou bloquer, ils appellent `GestionProfil.partage.signaler(cible:type:motif:)` et `GestionProfil.partage.bloquer(_:)`.
/// - Elle reste sur l'iPhone. // R2: `Blocage` en base privée (`schema.md` 9) pour la suivre d'un iPhone à l'autre : à écrire avec `App/Compte/`.
nonisolated protocol LectureBlocages: Sendable {
    func estCache(_ profilID: String) -> Bool
    func profilsCaches() -> Set<String>
}

nonisolated struct ListeBlocages: LectureBlocages {
    static let cleBloquesParDefaut = "profil.bloques"
    static let cleMasquesParDefaut = "profil.masques"
    /// La liste de l'app. Les tests construisent la leur avec d'autres clés.
    static let partage = ListeBlocages()

    var cleBloques: String = Self.cleBloquesParDefaut
    var cleMasques: String = Self.cleMasquesParDefaut

    func bloques() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: cleBloques) ?? []) }
    func masques() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: cleMasques) ?? []) }

    func profilsCaches() -> Set<String> { bloques().union(masques()) }

    func estCache(_ profilID: String) -> Bool {
        bloques().contains(profilID) || masques().contains(profilID)
    }

    func bloquer(_ profilID: String) {
        UserDefaults.standard.set(Array(bloques().union([profilID])).sorted(), forKey: cleBloques)
    }

    func masquer(_ profilID: String) {
        UserDefaults.standard.set(Array(masques().union([profilID])).sorted(), forKey: cleMasques)
    }

    func debloquer(_ profilID: String) {
        UserDefaults.standard.set(Array(bloques().subtracting([profilID])).sorted(), forKey: cleBloques)
        UserDefaults.standard.set(Array(masques().subtracting([profilID])).sorted(), forKey: cleMasques)
    }
}

/// Ancien nom, gardé pour que les branches qui l'appellent encore compilent. Utiliser `ListeBlocages`.
typealias BlocagesProfils = ListeBlocages
