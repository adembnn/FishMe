import Foundation

public enum GenreFichierCarte: String, Sendable, Codable, Equatable, CaseIterable {
    case image
    case pdf

    /// Extension du fichier stocké.
    public var extensionFichier: String { self == .pdf ? "pdf" : "jpg" }
}

/// Le fichier importé : un nom relatif au dossier de l'app, jamais un chemin absolu.
public struct FichierCarte: Sendable, Codable, Equatable, Hashable {
    /// Taille maximale d'un fichier importé : 15 Mo.
    public static let tailleMaxOctets = 15 * 1024 * 1024

    public var nom: String
    public var genre: GenreFichierCarte

    public init(nom: String, genre: GenreFichierCarte) {
        self.nom = nom
        self.genre = genre
    }

    /// Vrai si `nom` est un simple nom de fichier (ni dossier, ni `..`, ni chemin absolu).
    public var nomEstSur: Bool {
        !nom.isEmpty && nom != "." && nom != ".." && !nom.contains("/") && !nom.contains("\\") && !nom.contains("\0")
    }
}

/// La fiche de « Ma carte de pêche », gardée sur l'iPhone.
/// Aucun champ nom, prénom ni numéro d'adhérent : ils sont sur l'image importée, et nulle part ailleurs.
public struct FicheCartePeche: Sendable, Codable, Equatable, Identifiable {
    public var id: UUID
    public var millesime: Int
    /// Champ libre et facultatif (AAPPMA).
    public var association: String?
    public var expireLe: JourCivil
    public var rappelActif: Bool
    public var fichier: FichierCarte
    public var ajouteeLe: JourCivil

    public init(id: UUID = UUID(), millesime: Int, association: String? = nil, expireLe: JourCivil,
                rappelActif: Bool = false, fichier: FichierCarte, ajouteeLe: JourCivil) {
        self.id = id
        self.millesime = millesime
        self.association = association
        self.expireLe = expireLe
        self.rappelActif = rappelActif
        self.fichier = fichier
        self.ajouteeLe = ajouteeLe
    }

    /// L'identifiant stable de la notification : `cartepeche-<id>`.
    public var identifiantRappel: String { "cartepeche-\(id.uuidString)" }
}
