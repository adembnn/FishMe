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

/// Décision 3 (19 oct.) : juste un pseudonyme. Les versions de test gardaient deux champs sur l'iPhone ; on les efface, on ne les relit jamais.
nonisolated enum AnciensChampsIdentite {
    static let cles = ["profil.prive.nom", "profil.prive.prenom"]

    static func purger(defauts: UserDefaults = .standard) {
        for cle in cles { defauts.removeObject(forKey: cle) }
    }
}
