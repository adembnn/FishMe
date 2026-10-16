import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// Une ligne de la page Sources : RootView la fabrique depuis `credits()` de Core.
struct SourceClub: Identifiable, Hashable {
    let nom: String
    let mention: String
    let lien: URL?
    var id: String { nom }
}

/// Les liens officiels du pêcheur : RootView les fabrique depuis `liensFederation(departement)` de Core.
struct LiensClub: Hashable {
    var federation: URL?
    /// Nom du département (champ `nom` de liens-federations.json), que RootView passe s'il le connaît.
    var nomDepartement: String? = nil
    var association: URL?
    var carteDePeche: URL = LiensOfficiels.carteDePeche
    /// Page de confidentialité publiée par le serveur MCP de MWM ; vide tant qu'elle n'existe pas.
    var confidentialite: URL?

    /// « Fédération de Val-de-Marne » : le nom du département tel quel, aucun nom officiel inventé.
    /// `nil` sans nom de département : la ligne n'a alors pas de sous-titre.
    var libelleFederation: String? {
        guard let nom = nomDepartement?.trimmingCharacters(in: .whitespacesAndNewlines), !nom.isEmpty else { return nil }
        return "Fédération de \(nom)"
    }
}

/// Une carte du Pescedex déjà rendue par L4, passée par RootView.
nonisolated struct CarteAPartager: Identifiable, Transferable, Sendable {
    let id: String
    let titre: String
    let png: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { carte in
            try ImageSansGPS.nettoyer(carte.png)
        }
    }
}

nonisolated enum LiensOfficiels {
    static let carteDePeche = URL(string: "https://www.cartedepeche.fr")!
    static let federationNationale = URL(string: "https://www.federationpeche.fr")!
    static let vigilanceMeteoFrance = URL(string: "https://vigilance.meteofrance.fr")!
    static let vigicrues = URL(string: "https://www.vigicrues.gouv.fr")!
}

nonisolated enum ContactClub {
    /// Adresse réelle fournie par Adem ou MWM (écrite dans CLAUDE.md). Jamais inventée.
    /// Vide : les lignes « Contact » et « Signaler une erreur de règle » disparaissent.
    // À remplir par Adem : l'adresse courriel de contact (un seul endroit).
    static let adresse = ""

    static func courriel(objet: String) -> URL? {
        guard !adresse.isEmpty else { return nil }
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = adresse
        composants.queryItems = [URLQueryItem(name: "subject", value: objet)]
        return composants.url
    }

    static var contact: URL? { courriel(objet: "FishMe") }
    static var erreurDeRegle: URL? { courriel(objet: "Erreur de règle") }
}
