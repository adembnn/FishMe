import Foundation

/// Ce qui reste sur l'iPhone : l'identifiant de mon profil et mon surnom (pour titrer mon partage d'amis).
nonisolated protocol MemoireProfil: Sendable {
    func idProfil() -> String?
    func surnom() -> String?
    func retenir(id: String, surnom: String)
    func oublier()
}

nonisolated struct MemoireProfilLocale: MemoireProfil {
    static let cleId = "profil.id"
    static let cleSurnom = "profil.surnom"
    var cleId: String = Self.cleId
    var cleSurnom: String = Self.cleSurnom

    func idProfil() -> String? { UserDefaults.standard.string(forKey: cleId) }
    func surnom() -> String? { UserDefaults.standard.string(forKey: cleSurnom) }

    func retenir(id: String, surnom: String) {
        UserDefaults.standard.set(id, forKey: cleId)
        UserDefaults.standard.set(surnom, forKey: cleSurnom)
    }

    func oublier() {
        UserDefaults.standard.removeObject(forKey: cleId)
        UserDefaults.standard.removeObject(forKey: cleSurnom)
    }
}

/// Nom et prénom : facultatifs, privés, jamais publiés ni affichés à un autre (décision 3).
/// Cette version les garde sur l'iPhone. // R2: `ProfilPrive` en base privée (zone « Sauvegarde ») est à brancher par A dans `App/Compte/`.
nonisolated protocol StockageIdentitePrivee: Sendable {
    func lire() -> (nom: String, prenom: String)
    func ecrire(nom: String, prenom: String)
    func effacer()
}

nonisolated struct IdentitePriveeLocale: StockageIdentitePrivee {
    var cleNom: String = "profil.prive.nom"
    var clePrenom: String = "profil.prive.prenom"

    func lire() -> (nom: String, prenom: String) {
        (UserDefaults.standard.string(forKey: cleNom) ?? "", UserDefaults.standard.string(forKey: clePrenom) ?? "")
    }

    func ecrire(nom: String, prenom: String) {
        UserDefaults.standard.set(nom, forKey: cleNom)
        UserDefaults.standard.set(prenom, forKey: clePrenom)
    }

    func effacer() {
        UserDefaults.standard.removeObject(forKey: cleNom)
        UserDefaults.standard.removeObject(forKey: clePrenom)
    }
}

/// Les profils que je ne veux plus voir : bloqués (je l'ai choisi) ou signalés (masqués tout de suite, règle 1.2).
/// Un filtre local : la recherche, la liste d'amis et le fil de L23 l'interrogent. // R2: `Blocage` en base privée (`schema.md` 9) pour suivre
/// la personne d'un iPhone à l'autre : à écrire avec la zone de `App/Compte/`.
nonisolated struct BlocagesProfils: Sendable {
    var cleBloques: String = "profil.bloques"
    var cleMasques: String = "profil.masques"

    func bloques() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: cleBloques) ?? []) }
    func masques() -> Set<String> { Set(UserDefaults.standard.stringArray(forKey: cleMasques) ?? []) }

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
