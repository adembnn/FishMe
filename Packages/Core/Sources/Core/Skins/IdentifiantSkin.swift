import Foundation

/// Identifiant stable d'un skin d'aquarium. Une chaîne : elle est écrite telle quelle dans les réglages de l'iPhone
/// et lue par une version future de l'app, donc un identifiant inconnu doit rester lisible (voir `appliquable`).
public struct IdentifiantSkin: Hashable, Codable, Sendable, CustomStringConvertible {
    public let valeur: String

    public init(_ valeur: String) { self.valeur = valeur }

    public init(from decoder: Decoder) throws {
        let conteneur = try decoder.singleValueContainer()
        self.valeur = try conteneur.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var conteneur = encoder.singleValueContainer()
        try conteneur.encode(valeur)
    }

    public var description: String { valeur }

    public static let riviere = IdentifiantSkin("riviere")
    public static let etang = IdentifiantSkin("etang")
    public static let grotte = IdentifiantSkin("grotte")
    /// La rivière sous les arbres, gagnée après dix sessions de pêche.
    public static let sousBois = IdentifiantSkin("sous-bois")
    public static let halloween = IdentifiantSkin("halloween")
    public static let noel = IdentifiantSkin("noel")
    public static let ouvertureTruite = IdentifiantSkin("ouverture-truite")
    public static let ete = IdentifiantSkin("ete")

    /// Le décor de départ : toujours disponible, c'est le fond que l'aquarium a toujours eu.
    public static let parDefaut = IdentifiantSkin.riviere
}
