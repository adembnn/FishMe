import Foundation

public enum TypeExigence: String, Sendable, Hashable, Codable, CaseIterable {
    /// Licence de pêche d'État.
    case permis
    /// Timbre ou permis additionnel (truite, conservation stamp, Lac Érié…).
    case timbre
    /// Permis d'une tribu, pour les eaux de réserve (la licence d'État n'y vaut généralement pas).
    case permisTribal
}

/// Ce qu'il faut avoir pour pêcher à cet endroit : séparé des règles de capture (`reglementation-cadre.md` §1.3). Les exigences
/// s'ajoutent le long de la hiérarchie, une exigence plus spécifique ne retire jamais celle de l'État.
public struct ExigenceUS: Sendable, Equatable, Hashable, Codable {
    public let id: String
    public let portee: IdJuridiction
    public let type: TypeExigence
    public let nom: String
    /// Prix en dollars US ; `nil` tant qu'il n'est pas lu (jamais une valeur par défaut).
    public let prixDollars: Decimal?
    /// Âge en dessous duquel l'exigence est levée, si le texte le dit ; `nil` = non lu.
    public let exempteMoinsDe: Int?
    public let source: SourceUS
    public var statut: StatutRelecture

    public init(id: String, portee: IdJuridiction, type: TypeExigence, nom: String, prixDollars: Decimal? = nil,
                exempteMoinsDe: Int? = nil, source: SourceUS, statut: StatutRelecture = .nonRelue) {
        self.id = id
        self.portee = portee
        self.type = type
        self.nom = nom
        self.prixDollars = prixDollars
        self.exempteMoinsDe = exempteMoinsDe
        self.source = source
        self.statut = statut
    }
}
