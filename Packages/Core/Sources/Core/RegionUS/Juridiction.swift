import Foundation

/// Code postal USPS d'un État (deux lettres), plus le district de Columbia. Les territoires ne sont pas couverts.
public struct CodeEtat: Sendable, Hashable, Comparable, Codable, CustomStringConvertible {
    public let rawValue: String

    private static let liste: [String] = [
        "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
        "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD",
        "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    ]
    private static let ensemble = Set(liste)

    public static let tous: [CodeEtat] = liste.map { CodeEtat(valide: $0) }

    private init(valide: String) { self.rawValue = valide }

    /// `nil` si ce n'est pas un code USPS connu. Les majuscules sont imposées (« wi » devient « WI »).
    public init?(rawValue: String) {
        let code = rawValue.uppercased()
        guard Self.ensemble.contains(code) else { return nil }
        self.rawValue = code
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        let brut = try c.decode(String.self)
        guard let code = CodeEtat(rawValue: brut) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Code d'État USPS inconnu : \(brut)")
        }
        self = code
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    public var description: String { rawValue }
    public static func < (a: CodeEtat, b: CodeEtat) -> Bool { a.rawValue < b.rawValue }
}

/// Identifiant stable d'une juridiction. Pour un État : `US-<USPS>` ; pour les niveaux plus fins, le chemin lisible choisi à la saisie
/// (ex. `US-WI/nord/lac-x`). Il ne change jamais d'une édition des règles à l'autre : les règles s'y accrochent.
public struct IdJuridiction: Sendable, Hashable, Codable, CustomStringConvertible, Comparable {
    public let rawValue: String

    /// `nil` si l'identifiant est vide ou contient des espaces.
    public init?(rawValue: String) {
        guard !rawValue.isEmpty, rawValue.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else { return nil }
        self.rawValue = rawValue
    }

    public static func etat(_ code: CodeEtat) -> IdJuridiction {
        IdJuridiction(rawValue: "US-\(code.rawValue)")!
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        let brut = try c.decode(String.self)
        guard let id = IdJuridiction(rawValue: brut) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Identifiant de juridiction invalide")
        }
        self = id
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(rawValue)
    }

    public var description: String { rawValue }
    public static func < (a: IdJuridiction, b: IdJuridiction) -> Bool { a.rawValue < b.rawValue }
}

/// Les quatre étages d'une portée de règle, du plus large au plus précis. Plus le rang est grand, plus la règle est spécifique.
public enum NiveauJuridiction: Int, Sendable, Hashable, Codable, Comparable, CaseIterable {
    case etat = 0
    case zone = 1
    case planDeau = 2
    case troncon = 3

    public static func < (a: NiveauJuridiction, b: NiveauJuridiction) -> Bool { a.rawValue < b.rawValue }
}

/// Un terrain qui ajoute ses propres règles sur la même eau (`reglementation-cadre.md` §1.4 à §1.7). Une alerte n'est jamais retirée
/// par une règle plus spécifique ; sur une réserve tribale, les règles d'État ne suffisent jamais à dire « interdit ».
public enum AlerteTerrain: String, Sendable, Hashable, Codable, CaseIterable {
    case reserveTribale
    case refugeFederal
    case parcNational
    case eauFrontaliere
    case especeListeeESA
}

/// Un nœud de la hiérarchie État → zone → plan d'eau → tronçon.
public struct Juridiction: Sendable, Equatable, Hashable, Codable {
    public let id: IdJuridiction
    public let niveau: NiveauJuridiction
    public let nom: String
    public let etat: CodeEtat
    /// `nil` pour un État, obligatoire sinon.
    public let parent: IdJuridiction?
    /// Bassin versant USGS à 8 chiffres, facultatif (zone, plan d'eau, tronçon).
    public let huc8: String?
    public let alertes: Set<AlerteTerrain>
    /// Page de l'agence de cet État ou de cette zone ; l'app l'affiche toujours avec le verdict.
    public let lienAgence: URL?

    /// `nil` si l'objet est incohérent : État avec parent ou sans l'identifiant `US-<code>`, autre niveau sans parent, HUC8 qui n'a pas
    /// 8 chiffres, nom vide.
    public init?(id: IdJuridiction, niveau: NiveauJuridiction, nom: String, etat: CodeEtat, parent: IdJuridiction? = nil,
                 huc8: String? = nil, alertes: Set<AlerteTerrain> = [], lienAgence: URL? = nil) {
        guard !nom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if niveau == .etat {
            guard parent == nil, id == IdJuridiction.etat(etat) else { return nil }
        } else {
            guard let parent, parent != id else { return nil }
        }
        if let huc8 {
            guard huc8.count == 8, huc8.allSatisfy({ $0 >= "0" && $0 <= "9" }) else { return nil }
        }
        self.id = id
        self.niveau = niveau
        self.nom = nom
        self.etat = etat
        self.parent = parent
        self.huc8 = huc8
        self.alertes = alertes
        self.lienAgence = lienAgence
    }

    /// La juridiction racine d'un État.
    public static func etat(_ code: CodeEtat, nom: String, lienAgence: URL? = nil, alertes: Set<AlerteTerrain> = []) -> Juridiction? {
        Juridiction(id: .etat(code), niveau: .etat, nom: nom, etat: code, alertes: alertes, lienAgence: lienAgence)
    }
}

public enum ErreurArbreJuridictions: Error, Equatable, Sendable {
    case identifiantEnDouble(IdJuridiction)
    case parentInconnu(IdJuridiction)
    /// Un enfant doit être plus précis que son parent (une zone sous un tronçon, par exemple, est refusée).
    case niveauIncoherent(IdJuridiction)
    case etatDifferentDuParent(IdJuridiction)
}

/// L'ensemble des juridictions chargées, validé : pas de doublon, parents connus, niveaux croissants, même État que le parent.
public struct ArbreJuridictions: Sendable, Equatable {
    private let parId: [IdJuridiction: Juridiction]

    public init(_ juridictions: [Juridiction]) throws {
        var index: [IdJuridiction: Juridiction] = [:]
        for j in juridictions {
            guard index[j.id] == nil else { throw ErreurArbreJuridictions.identifiantEnDouble(j.id) }
            index[j.id] = j
        }
        for j in juridictions {
            guard let idParent = j.parent else { continue }
            guard let parent = index[idParent] else { throw ErreurArbreJuridictions.parentInconnu(j.id) }
            guard parent.niveau < j.niveau else { throw ErreurArbreJuridictions.niveauIncoherent(j.id) }
            guard parent.etat == j.etat else { throw ErreurArbreJuridictions.etatDifferentDuParent(j.id) }
        }
        self.parId = index
    }

    public var toutes: [Juridiction] { parId.values.sorted { $0.id < $1.id } }

    public subscript(id: IdJuridiction) -> Juridiction? { parId[id] }

    /// De l'État au nœud demandé (le nœud en dernier). `nil` si l'identifiant est inconnu.
    public func chaine(de id: IdJuridiction) -> [Juridiction]? {
        guard var courant = parId[id] else { return nil }
        var remontee = [courant]
        while let idParent = courant.parent {
            guard let p = parId[idParent] else { return nil }
            remontee.append(p)
            courant = p
        }
        return remontee.reversed()
    }

    public func enfants(de id: IdJuridiction) -> [Juridiction] {
        parId.values.filter { $0.parent == id }.sorted { $0.id < $1.id }
    }
}
