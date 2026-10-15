import Foundation

/// Ce que dit un conseil : l'appât, l'hameçon, la technique ou le moment de l'année.
public enum TypeConseil: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case appat
    case hamecon
    case technique
    case moment
}

/// Les modes de pêche qu'un conseil suppose, pour le confronter aux règles du lieu.
public enum ModeConseil: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case vif
    case poissonMort = "poisson_mort"
    case leurre
    case asticot
    case mouche
    case nuit
    case amorce
    case bateau
}

/// La catégorie d'eau où le conseil vaut : `toutes` veut dire « les deux ».
public enum CategorieConseil: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    case premiere = "1"
    case deuxieme = "2"
    case toutes
}

/// Une page ou une étude lue pour écrire un conseil.
public struct SourceLue: Sendable, Equatable, Hashable, Codable {
    public var id: String
    public var titre: String
    public var url: String
    public var luLe: String

    enum CodingKeys: String, CodingKey {
        case id, titre, url
        case luLe = "lu_le"
    }

    public init(id: String, titre: String, url: String, luLe: String) {
        self.id = id
        self.titre = titre
        self.url = url
        self.luLe = luLe
    }
}

/// Un conseil tel qu'il est écrit dans `conseils.json`. Le `Conseil` du contrat (C0) n'en garde que ce que l'écran montre.
public struct ConseilFiche: Sendable, Equatable, Hashable, Codable {
    public var id: String
    public var espece: String
    public var type: TypeConseil
    public var texte: String
    public var icone: String
    public var mois: [Int]
    public var categorie: CategorieConseil
    public var niveaux: [NiveauPecheur]
    public var modes: [ModeConseil]
    public var rang: Int
    public var sources: [String]
    /// Nom et date de la relecture de S. Vide : le conseil n'entre pas dans le fichier et n'est jamais montré.
    public var reluPar: String?

    enum CodingKeys: String, CodingKey {
        case id, espece, type, texte, icone, mois, categorie, niveaux, modes, rang, sources
        case reluPar = "relu_par"
    }

    public init(id: String, espece: String, type: TypeConseil, texte: String, icone: String, mois: [Int],
                categorie: CategorieConseil, niveaux: [NiveauPecheur], modes: [ModeConseil] = [], rang: Int,
                sources: [String], reluPar: String? = nil) {
        self.id = id
        self.espece = espece
        self.type = type
        self.texte = texte
        self.icone = icone
        self.mois = mois
        self.categorie = categorie
        self.niveaux = niveaux
        self.modes = modes
        self.rang = rang
        self.sources = sources
        self.reluPar = reluPar
    }

    public var estRelu: Bool {
        guard let reluPar else { return false }
        return !reluPar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Le contenu de `conseils.json`.
public struct FichierConseils: Sendable, Equatable, Codable {
    public var version: String
    public var date: String?
    public var sources: [SourceLue]
    public var conseils: [ConseilFiche]

    public init(version: String, date: String? = nil, sources: [SourceLue], conseils: [ConseilFiche]) {
        self.version = version
        self.date = date
        self.sources = sources
        self.conseils = conseils
    }

    public static func decoder(_ data: Data) throws -> FichierConseils {
        try JSONDecoder().decode(FichierConseils.self, from: data)
    }
}
