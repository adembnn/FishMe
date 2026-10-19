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
/// Le surnom voyage dans le titre du partage CloudKit (`partagePret`).
nonisolated enum NomAmi {
    static let titreSansProfil = "Pescedex"
    static let anonyme = "Un ami"

    /// Le titre d'un partage devient le nom de l'ami s'il ressemble à un surnom ; sinon « Un ami ».
    static func affiche(titre: String?) -> String {
        guard let titre, titre != titreSansProfil, Surnom.verifier(titre) == nil else { return anonyme }
        return titre
    }

    /// Le titre à écrire sur mon partage : mon surnom si j'en ai un.
    static func titre(surnom: String?) -> String {
        guard let surnom, Surnom.verifier(surnom) == nil else { return titreSansProfil }
        return surnom
    }
}
