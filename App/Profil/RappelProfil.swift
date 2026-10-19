import Foundation

/// « Finis ton profil » : la feuille se montre au premier passage sur Communauté, jamais si le profil existe,
/// et « Me le rappeler plus tard » (ou tout autre moyen de la fermer) la repousse de 7 jours.
/// La valeur est lue par `@AppStorage("profil.rappel")` : 0 = jamais montrée, sinon la date (en secondes) avant laquelle on ne revient pas.
nonisolated enum RappelProfil {
    static let cle = "profil.rappel"
    static let delai: TimeInterval = 7 * 24 * 3600

    static func doitAfficher(prochain: Double, profilExiste: Bool, maintenant: Date) -> Bool {
        if profilExiste { return false }
        return maintenant.timeIntervalSince1970 >= prochain
    }

    /// La date avant laquelle la feuille ne revient pas.
    static func prochain(apres maintenant: Date) -> Double {
        maintenant.addingTimeInterval(delai).timeIntervalSince1970
    }

    /// À appeler quand la feuille s'affiche : « une fois » tient même si on la ferme d'un glissement.
    static func reporter(depuis maintenant: Date = Date(), pourCle: String = RappelProfil.cle) {
        UserDefaults.standard.set(prochain(apres: maintenant), forKey: pourCle)
    }
}
