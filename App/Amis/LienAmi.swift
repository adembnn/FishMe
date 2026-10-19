import Foundation
import Observation

/// Le lien `fishme://ami/<id>` : il mène au profil d'un pêcheur. `<id>` est l'identifiant public `p-<surnom normalisé>`.
/// Aucune coordonnée, aucun nom réel : seulement le surnom, déjà public.
nonisolated enum LienAmi {
    static let schema = "fishme"
    static let hote = "ami"

    static func url(profilID: String) -> URL? {
        URL(string: "\(schema)://\(hote)/\(profilID)")
    }

    /// L'identifiant lu dans un lien, ou `nil` si ce n'est pas un lien d'ami valide.
    static func profilID(depuis url: URL) -> String? {
        guard url.scheme == schema, url.host() == hote,
              let dernier = url.pathComponents.last, dernier != "/", dernier.hasPrefix("p-") else { return nil }
        let surnom = String(dernier.dropFirst(2))
        guard Surnom.verifier(surnom) == nil, Surnom.normaliser(surnom) == surnom else { return nil }
        return dernier
    }
}

/// Garde le lien d'ami reçu, le temps que la page Amis montre le profil (comme `RelaisInvitations` pour les partages).
/// A l'appelle dans `ouvrir(url:)` de `RootView.swift` : `RelaisLienAmi.partage.recevoir(url)` pour l'hôte `ami`, puis ouvre l'onglet Communauté.
@MainActor
@Observable
final class RelaisLienAmi {
    static let partage = RelaisLienAmi()

    private(set) var enAttente: String?

    /// Vrai si le lien était un lien d'ami valide (A peut alors ouvrir Communauté).
    @discardableResult
    func recevoir(_ url: URL) -> Bool {
        guard let id = LienAmi.profilID(depuis: url) else { return false }
        enAttente = id
        return true
    }

    func solder() { enAttente = nil }
}

/// Le nom montré pour un ami : son surnom, jamais le nom de son compte Apple (décision 3).
/// Le surnom voyage dans le titre du partage CloudKit (`partagePret`, `TitrePartage`), MAIS ce titre est écrit par l'ami lui-même :
/// il peut y mettre le surnom d'un autre. Il ne devient donc un nom qu'une fois confirmé par le profil public (même auteur que la zone).
nonisolated enum NomAmi {
    static let titreSansProfil = "Pescedex"
    static let anonyme = "Un ami"

    /// Vrai si le titre a la forme d'un surnom (rien de plus : NON vérifié).
    static func ressembleAUnSurnom(_ titre: String?) -> Bool {
        guard let titre, titre != titreSansProfil, Surnom.verifier(titre) == nil else { return false }
        return true
    }

    /// Titre NON vérifié : toujours « Un ami ». À utiliser tant que le profil n'a pas confirmé (invitation reçue, hors ligne).
    static func affiche(titre: String?) -> String {
        anonyme
    }

    /// Titre confirmé : le surnom s'affiche seulement si l'auteur du profil public de ce surnom est le propriétaire de la zone partagée.
    static func affiche(titre: String?, auteurDuProfil: String?, proprietaire: String) -> String {
        guard ressembleAUnSurnom(titre), let titre, let auteurDuProfil, !proprietaire.isEmpty, auteurDuProfil == proprietaire else {
            return anonyme
        }
        return titre
    }

    /// Le titre à écrire sur mon partage : mon surnom si j'en ai un.
    static func titre(surnom: String?) -> String {
        guard let surnom, Surnom.verifier(surnom) == nil else { return titreSansProfil }
        return surnom
    }
}
