import Core
import Foundation

/// Une demande de 20 publications d'une section ; `avant` charge les 20 suivantes (plus anciennes).
nonisolated struct DemandeSection: Sendable, Equatable {
    var section: SectionFeed
    /// Clubs : identifiants de mes clubs. Amis : noms de profil de mes amis (et le mien). Région : codes de département.
    var valeurs: [String]
    var avant: Date? = nil
    var limite: Int = 20
}

nonisolated struct PageFeed: Sendable, Equatable {
    var publications: [PublicationFeed]
    /// Vrai si la page est pleine : « voir plus » est proposé.
    var encore: Bool
}

/// Ce qui part, et seulement cela. Le média est déjà prêt : JPEG ou MP4 sans métadonnée (`PreparationMedia`).
nonisolated struct BrouillonPublication: Sendable, Equatable {
    var id: String = UUID().uuidString
    var auteurNom: String
    var genre: GenreMedia
    var fichierMedia: URL
    var vignette: URL
    var dureeS: Int
    var legende: String
    var lieu: LieuChoisi
    var carte: CarteLiee?
    var club: String
}

/// Tout ce que le fil demande à CloudKit, derrière un protocole : le vrai service, et le faux des tests et des aperçus.
nonisolated protocol ServiceFeed: Sendable {
    /// Vrai si iCloud répond.
    func compteDisponible() async -> Bool
    func publier(_ brouillon: BrouillonPublication) async throws -> PublicationFeed
    func page(_ demande: DemandeSection) async throws -> PageFeed
    /// Pour chaque publication, les noms de ceux qui l'aiment. Le compte vient de là, jamais d'un compteur.
    func likes(de publications: [String]) async throws -> [String: [String]]
    func aimer(publication: String, par auteur: String) async throws
    func nePlusAimer(publication: String, par auteur: String) async throws
    /// Chronologique ; `apres` charge les suivants.
    func commentaires(de publication: String, apres: Date?, limite: Int) async throws -> [CommentaireFeed]
    func commenter(_ commentaire: CommentaireFeed) async throws
    func signaler(_ signalement: SignalementFeed) async throws
    func supprimerPublication(_ id: String) async throws
    func supprimerCommentaire(_ id: String) async throws
    /// Efface tout ce que cet auteur a publié, commenté ou aimé (suppression du profil, règle 5.1.1).
    func supprimerContenus(de auteur: String) async throws
    /// Le fichier complet (photo 1 600 px ou vidéo 720p) d'une publication, téléchargé à la demande.
    func media(de publication: String) async throws -> URL
    /// Copie du blocage dans la base privée (le filtre, lui, est local).
    func bloquer(_ auteur: String) async throws
}

/// Les clubs de la personne. À aligner L22 : `ServiceClubs` donnera la vraie liste.
nonisolated struct ClubResume: Sendable, Equatable, Identifiable {
    var id: String
    var nom: String
}

/// Ce que le fil attend des lots voisins. Un seul protocole, que A branche sur L21, L22 et le spot (`RootView.swift`).
nonisolated protocol SourceContexte: Sendable {
    /// `recordName` de mon profil. À aligner L21 : `nil` tant que le profil n'est pas fini (on lit, on ne publie pas).
    func monNom() async -> String?
    /// `recordName` des profils de mes amis. À aligner L21 (surnoms) et Amis (invitations).
    func nomsDesAmis() async -> [String]
    /// À aligner L22 : `ServiceClubs`.
    func mesClubs() async -> [ClubResume]
    /// Département du spot d'abord, puis ceux de sa région. Un seul code suffit.
    func departementsDeMaRegion() async -> [String]
    /// Le lieu du spot, pour le sélecteur quand on publie depuis le « + » du fil.
    func lieuCourant() async -> ContexteLieu
}

nonisolated struct ContexteFeed: Sendable, Equatable {
    var monNom: String?
    var clubs: [ClubResume] = []
    var amis: [String] = []
    var departements: [String] = []

    /// Les valeurs de la requête de chaque section.
    func valeurs(pour section: SectionFeed) -> [String] {
        switch section {
        case .clubs: clubs.map(\.id)
        case .amis: amis + (monNom.map { [$0] } ?? [])
        case .region: departements
        }
    }
}

/// L'e-mail de signalement : un `mailto:` prérempli (CloudKit n'envoie pas d'e-mail seul, `moderation.md`).
/// Seuls des identifiants partent : jamais de coordonnée.
nonisolated enum CourrielSignalement {
    static let adresse = "fishme.app@gmail.com"

    static func url(_ s: SignalementFeed, adresse: String = adresse) -> URL? {
        var composants = URLComponents()
        composants.scheme = "mailto"
        composants.path = adresse
        let corps = "Type : \(s.typeCible.rawValue)\nIdentifiant : \(s.cible)\nAuteur : \(s.auteurCible)\nMotif : \(s.motif.titre)\nSignalement : \(s.id)"
        composants.queryItems = [
            URLQueryItem(name: "subject", value: "Signalement FishMe : \(s.typeCible.rawValue)"),
            URLQueryItem(name: "body", value: corps),
        ]
        return composants.url
    }
}
