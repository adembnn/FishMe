import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Les erreurs des clients américains. Sans réseau ou sur refus, l'écran retombe sur « pas de mesure », jamais sur un plantage.
public enum ErreurUS: Error, Sendable, Equatable {
    /// 429 : trop de requêtes. `apres` = secondes demandées par l'en-tête `Retry-After`, si présent.
    case limiteAtteinte(apres: TimeInterval?)
    /// 403 : clé refusée ou User-Agent absent ou bloqué. Inutile de réessayer tel quel.
    case accesRefuse
    case serveur(Int)
    case http(Int)
    case identifiantInvalide
    case reponseIllisible
    case reseau
}

/// Une requête HTTP : la requête entre, le corps et la réponse sortent. Les tests y mettent une réponse enregistrée.
public protocol TransportUS: Sendable {
    func envoyer(_ requete: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Le transport réel : une `URLSession` injectable.
public struct TransportURLSession: TransportUS {
    let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public func envoyer(_ requete: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (donnees, reponse) = try await session.data(for: requete)
        guard let http = reponse as? HTTPURLResponse else { throw ErreurUS.reponseIllisible }
        return (donnees, http)
    }
}

/// Cache mémoire par URL, avec une durée de vie. Sert aussi de repli si la source répond 429.
actor CacheUS {
    private var entrees: [URL: (expire: Date, ecrit: Date, donnees: Data)] = [:]

    func frais(_ url: URL, maintenant: Date) -> Data? {
        guard let e = entrees[url], e.expire > maintenant else { return nil }
        return e.donnees
    }

    /// Une réponse plus vieille que `age` secondes est écartée du repli.
    func perime(_ url: URL, maintenant: Date, age: TimeInterval) -> Data? {
        guard let e = entrees[url], maintenant.timeIntervalSince(e.ecrit) <= age else { return nil }
        return e.donnees
    }

    func ranger(_ url: URL, _ donnees: Data, maintenant: Date, duree: TimeInterval) {
        entrees[url] = (maintenant.addingTimeInterval(duree), maintenant, donnees)
    }
}

/// Le noyau commun des clients : en-têtes, cache, lecture des codes 429 et 403.
struct LecteurUS: Sendable {
    let transport: TransportUS
    let cache = CacheUS()
    let userAgent: String
    let enTetes: [String: String]
    let horloge: @Sendable () -> Date
    /// Au-delà, une réponse en cache n'est plus resservie, même si la source refuse.
    static let ageMaxRepli: TimeInterval = 3600

    init(transport: TransportUS, userAgent: String, enTetes: [String: String] = [:], horloge: @escaping @Sendable () -> Date) {
        self.transport = transport
        self.userAgent = userAgent
        self.enTetes = enTetes
        self.horloge = horloge
    }

    func lire(_ url: URL, accept: String, duree: TimeInterval) async throws -> Data {
        let maintenant = horloge()
        if let d = await cache.frais(url, maintenant: maintenant) { return d }
        var requete = URLRequest(url: url)
        requete.timeoutInterval = 15
        requete.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        requete.setValue(accept, forHTTPHeaderField: "Accept")
        for (k, v) in enTetes { requete.setValue(v, forHTTPHeaderField: k) }
        let donnees: Data, reponse: HTTPURLResponse
        do {
            (donnees, reponse) = try await transport.envoyer(requete)
        } catch let e as ErreurUS {
            throw e
        } catch {
            if let vieux = await cache.perime(url, maintenant: maintenant, age: Self.ageMaxRepli) { return vieux }
            throw ErreurUS.reseau
        }
        switch reponse.statusCode {
        case 200..<300:
            await cache.ranger(url, donnees, maintenant: maintenant, duree: duree)
            return donnees
        case 429:
            if let vieux = await cache.perime(url, maintenant: maintenant, age: Self.ageMaxRepli) { return vieux }
            throw ErreurUS.limiteAtteinte(apres: reponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) })
        case 403:
            throw ErreurUS.accesRefuse
        case 500...:
            if let vieux = await cache.perime(url, maintenant: maintenant, age: Self.ageMaxRepli) { return vieux }
            throw ErreurUS.serveur(reponse.statusCode)
        default:
            throw ErreurUS.http(reponse.statusCode)
        }
    }

    static func url(_ base: String, _ chemin: String, _ parametres: [String: String]) -> URL? {
        var c = URLComponents(string: base + chemin)
        if !parametres.isEmpty { c?.queryItems = parametres.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) } }
        return c?.url
    }
}
