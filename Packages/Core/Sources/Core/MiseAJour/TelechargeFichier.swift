import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Pourquoi un fichier n'a pas pu être pris. Jamais montré au pêcheur : la copie déjà là continue de servir.
public enum ErreurTelechargement: Error, Sendable, Equatable {
    /// Aucune adresse d'hébergement n'est réglée (choix d'Adem pas encore fait) : l'app garde sa copie embarquée.
    case aucuneAdresse
    case horsLigne
    case reponseInvalide(statut: Int)
    case tropGros
}

/// Contrat de téléchargement que l'app implémente (L11). `Core` ne sait ni où sont les règles ni comment les chercher.
/// Le chemin est relatif à la racine publiée (« index.json », « 94.json », « national.json ») : il ne contient
/// jamais la position du pêcheur, et la mise à jour demande les mêmes fichiers à tout le monde.
public protocol TelechargeFichier: Sendable {
    func telecharger(chemin: String) async throws -> Data
}

/// Pas d'adresse : tout échoue en `aucuneAdresse`, l'app garde sa copie embarquée. C'est la valeur par défaut
/// tant qu'Adem n'a pas choisi où publier le fichier de règles.
public struct TelechargeFichierSansAdresse: TelechargeFichier {
    public init() {}
    public func telecharger(chemin: String) async throws -> Data { throw ErreurTelechargement.aucuneAdresse }
}

/// Faux pour les tests et pour `#if DEBUG` côté app : des réponses écrites en dur, et la liste des chemins demandés.
public final class TelechargeFichierFaux: TelechargeFichier, @unchecked Sendable {
    private let verrou = NSLock()
    private var reponses: [String: Data]
    private var enLigne: Bool
    private var demandes: [String] = []

    public init(fichiers: [String: Data] = [:], enLigne: Bool = true) {
        self.reponses = fichiers
        self.enLigne = enLigne
    }

    /// Les chemins demandés, dans l'ordre.
    public var chemins: [String] { verrou.withLock { demandes } }

    public func definir(_ chemin: String, _ data: Data?) { verrou.withLock { reponses[chemin] = data } }
    public func coupeLeReseau(_ coupe: Bool) { verrou.withLock { enLigne = !coupe } }

    public func telecharger(chemin: String) async throws -> Data {
        try verrou.withLock {
            demandes.append(chemin)
            guard enLigne else { throw ErreurTelechargement.horsLigne }
            guard let data = reponses[chemin] else { throw ErreurTelechargement.reponseInvalide(statut: 404) }
            return data
        }
    }
}

/// Téléchargement par HTTPS depuis une adresse de base fournie par l'app. Rien n'est écrit en dur ici :
/// `base` reste `nil` tant qu'Adem n'a pas choisi l'hébergement, et l'app garde alors sa copie embarquée.
/// Aucun cookie, aucun en-tête personnalisé, aucune requête (`?`) : le serveur ne reçoit rien du pêcheur.
public struct TelechargeFichierHTTP: TelechargeFichier {
    public static let tailleMax = 10 * 1024 * 1024

    private let base: URL?
    private let session: URLSession

    public init(base: URL?, session: URLSession? = nil) {
        self.base = base
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.timeoutIntervalForRequest = 20
            self.session = URLSession(configuration: configuration)
        }
    }

    public func telecharger(chemin: String) async throws -> Data {
        guard let base else { throw ErreurTelechargement.aucuneAdresse }
        let url = base.appendingPathComponent(chemin)
        let data: Data
        let reponse: URLResponse
        do {
            (data, reponse) = try await session.data(from: url)
        } catch {
            throw ErreurTelechargement.horsLigne
        }
        if let http = reponse as? HTTPURLResponse, http.statusCode != 200 {
            throw ErreurTelechargement.reponseInvalide(statut: http.statusCode)
        }
        guard data.count <= Self.tailleMax else { throw ErreurTelechargement.tropGros }
        return data
    }
}
