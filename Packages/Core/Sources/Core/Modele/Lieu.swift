import Foundation

public enum TypeEau: String, Sendable, Equatable, Hashable, Codable {
    case riviere
    case lac
    case autre
}

/// Une eau : rivière ou plan d'eau. `cle` est le nom normalisé (« La Marne » donne `marne`) par lequel une règle la vise.
public struct Eau: Sendable, Equatable, Hashable, Codable {
    public var nom: String
    public var cle: String
    public var codeSandre: String?
    public var type: TypeEau

    public init(nom: String, cle: String, codeSandre: String? = nil, type: TypeEau) {
        self.nom = nom
        self.cle = cle
        self.codeSandre = codeSandre
        self.type = type
    }
}

public enum Categorie: String, Sendable, Equatable, Hashable, Codable {
    case premiere
    case deuxieme
    case inconnue
}

/// D'où vient la catégorie : le premier qui répond gagne, dans cet ordre.
public enum OrigineCategorie: String, Sendable, Equatable, Hashable, Codable {
    case choixDuPecheur
    case regleDeLEau
    case regleDeReste
    case aucune
}

/// Catégorie de l'eau (1re, 2e ou inconnue) avec son origine. Inconnue : l'app montre les deux valeurs et « ? ».
public struct CategorieEau: Sendable, Equatable, Hashable, Codable {
    public var valeur: Categorie
    public var origine: OrigineCategorie

    public init(valeur: Categorie, origine: OrigineCategorie) {
        self.valeur = valeur
        self.origine = origine
    }

    public static let inconnue = CategorieEau(valeur: .inconnue, origine: .aucune)
}

/// Ce que le pêcheur a confirmé d'un toucher sur ce spot (conservé sur l'iPhone).
public struct ChoixLieu: Sendable, Equatable, Hashable, Codable {
    public var eau: Eau?
    public var categorie: Categorie?
    public var tronconsConfirmes: [String]

    public init(eau: Eau? = nil, categorie: Categorie? = nil, tronconsConfirmes: [String] = []) {
        self.eau = eau
        self.categorie = categorie
        self.tronconsConfirmes = tronconsConfirmes
    }
}

/// Le lieu d'un point, calculé sur l'iPhone. La coordonnée exacte n'en fait pas partie.
public struct Lieu: Sendable, Equatable, Hashable, Codable {
    public var departement: Departement
    /// À moins de 500 m d'une limite : le département d'en face, pour appliquer la consigne la plus stricte des deux.
    public var departementVoisin: Departement?
    public var eau: Eau?
    public var categorie: CategorieEau
    public var tronconsConfirmes: [String]

    public init(departement: Departement, departementVoisin: Departement? = nil, eau: Eau? = nil,
                categorie: CategorieEau = .inconnue, tronconsConfirmes: [String] = []) {
        self.departement = departement
        self.departementVoisin = departementVoisin
        self.eau = eau
        self.categorie = categorie
        self.tronconsConfirmes = tronconsConfirmes
    }

    /// Hors de France ou sans polygone : aucune règle française.
    public static let inconnu = Lieu(departement: .inconnu)
}
