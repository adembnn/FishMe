import Core
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
    static let adresse = "fishme.app@gmail.com"

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

// MARK: - Ce que l'écran Club montre d'un groupe (P29, P31)
// Rien de tout ça n'existe encore côté données : RootView les passe quand le partage CloudKit les donne.
// Sans eux, les blocs correspondants ne s'affichent pas.

/// Un membre du club : une pastille à son initiale et le nombre de cartes qu'il a partagées.
struct MembreClub: Identifiable, Hashable {
    let id: String
    let nom: String
    let nombreDeCartes: Int?
}

/// Une carte récente d'un membre : « Léa · Sandre, lundi · 52 cm ».
struct CarteRecenteClub: Identifiable, Hashable {
    let id: String
    let membre: String
    let espece: String
    /// Jour en toutes lettres courtes (« lundi », « dim. »).
    let jour: String
    let tailleCm: Int?
    /// Nom de l'image du poisson dans les ressources.
    let image: String
    /// Rareté affichée sur la carte (fond et badge, comme dans le Pescedex).
    var niveau: NiveauRarete = .commun
}

/// Le record du club : « Plus gros brochet · Malo · 74 cm ».
struct RecordClub: Hashable {
    let titre: String
    let membre: String
    let tailleCm: Int
    let image: String
    var niveau: NiveauRarete = .commun
}

/// Une personne invitée, avec l'état de son invitation (P31).
struct InviteClub: Identifiable, Hashable {
    let id: String
    let nom: String
    let acceptee: Bool
}
