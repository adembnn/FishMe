import Foundation

/// Une espèce, par son identifiant dans la liste de référence (`brochet`, `perche-commune`...), avec son code Sandre quand il existe.
/// Une structure, pas une énumération : la liste grandit (101 entrées prévues) sans casser le code de l'app.
public struct Espece: Sendable, Equatable, Hashable, Codable {
    public var id: String
    public var codeSandre: String?

    public init(id: String, codeSandre: String? = nil) {
        self.id = id
        self.codeSandre = codeSandre
    }

    /// Les 77 identifiants de `docs/regles/especes-national.json` (15 oct. 2026). `especes.json` (D1) étendra la liste.
    public static let identifiantsNationaux: [String] = [
        "truite-fario", "truite-arc-en-ciel", "truite-de-mer", "saumon-atlantique", "omble-de-fontaine",
        "omble-chevalier", "cristivomer", "ombre-commun", "huchon", "coregones", "brochet", "sandre",
        "perche-commune", "gremille", "black-bass", "perche-soleil", "silure-glane", "poisson-chat",
        "carpe-commune", "carpe-amour", "carpe-argentee", "carpe-grosse-tete", "gardon", "rotengle",
        "breme-commune", "breme-bordeliere", "chevesne", "tanche", "barbeau-fluviatile", "vandoise",
        "ide-melanote", "hotu", "ablette", "goujon", "spirlin", "able-de-heckel", "bouviere",
        "carassin-commun", "carassin-argente", "aspe", "pseudorasbora", "goujon-de-l-amour", "vairon",
        "gambusie", "loche-franche", "loche-de-riviere", "loche-d-etang", "chabot", "lotte", "epinoche",
        "flet", "mulet", "anguille-jaune", "anguille-argentee", "civelle", "grande-alose", "alose-feinte",
        "lamproie-marine", "lamproie-fluviatile", "lamproie-de-planer", "esturgeon-europeen",
        "apron-du-rhone", "ecrevisse-pattes-blanches", "ecrevisse-pattes-rouges", "ecrevisse-des-torrents",
        "ecrevisse-pattes-greles", "ecrevisse-americaine", "ecrevisse-de-louisiane", "ecrevisse-signal",
        "ecrevisse-virile", "ecrevisse-marbree", "ecrevisse-a-taches-rouges", "crabe-chinois",
        "grenouille-verte", "grenouille-rousse", "grenouille-taureau", "hybrides",
    ]

    /// Vrai si l'identifiant figure dans la liste nationale de référence.
    public var estDansLaListeNationale: Bool {
        Espece.identifiantsNationaux.contains(id)
    }
}

/// Pourquoi une espèce demande un traitement à part.
public enum StatutEspece: String, Sendable, Equatable, Hashable, Codable {
    case protegee
    case envahissante
    case stadeADemander
    case toujoursRelachee
}

/// Un sosie coûteux : l'espèce avec laquelle on la confond, le critère qui les sépare et sa source.
public struct Confusion: Sendable, Equatable, Hashable, Codable {
    public var avec: Espece
    public var critere: String
    public var source: String

    public init(avec: Espece, critere: String, source: String) {
        self.avec = avec
        self.critere = critere
        self.source = source
    }
}

/// Une entrée de `especes.json` : ce que l'app montre dans la grille, le Pescedex et l'écran de confirmation.
public struct EspecePechable: Sendable, Equatable, Hashable, Codable {
    public var espece: Espece
    public var nom: String
    public var nomLatin: String
    /// Nom de la classe du modèle de reconnaissance ; `nil` si le modèle ne la connaît pas (elle passe par « Autre »).
    public var classeModele: String?
    /// Nom de l'image dans les ressources.
    public var image: String
    public var statuts: Set<StatutEspece>
    public var confusions: [Confusion]
    /// Faux pour les grenouilles, le crabe chinois, les mulets : l'OFB ne les suit pas, donc pas de niveau de rareté.
    public var suiviOFB: Bool

    public init(espece: Espece, nom: String, nomLatin: String, classeModele: String? = nil, image: String,
                statuts: Set<StatutEspece> = [], confusions: [Confusion] = [], suiviOFB: Bool = true) {
        self.espece = espece
        self.nom = nom
        self.nomLatin = nomLatin
        self.classeModele = classeModele
        self.image = image
        self.statuts = statuts
        self.confusions = confusions
        self.suiviOFB = suiviOFB
    }
}
