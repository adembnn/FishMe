import Foundation

public enum TypeRegle: String, Sendable, Equatable, Hashable, Codable {
    case taille
    case periode
    case quota
    case modeDePeche
    case nuit
    case reserve
    case consommation
    case transportVivant
    case autre
}

public enum EtatLigne: String, Sendable, Equatable, Hashable, Codable {
    case respectee
    case nonRespectee
    case aVerifierSurPlace
    /// Interdiction ou obligation à appliquer (consommation, mode de pêche, carpe de nuit...) : ni vert ni rouge, jamais « respectée ».
    case information
}

/// Pourquoi une ligne est « à vérifier sur place ».
public enum RaisonAVerifier: String, Sendable, Equatable, Hashable, Codable {
    case troncon
    case reserve
    case categorie
    case desaccord
    case perimee
    case tropPresDeLaMaille
}

public struct SourceRegle: Sendable, Equatable, Hashable, Codable {
    public var titre: String
    public var url: String?
    /// Passage de CE texte qui fonde la règle (peut différer d'une source à l'autre).
    public var citation: String?

    public init(titre: String, url: String? = nil, citation: String? = nil) {
        self.titre = titre
        self.url = url
        self.citation = citation
    }
}

/// Une ligne de la liste de contrôle : une règle qui s'applique, avec son état, sa phrase et ses sources.
public struct LigneControle: Sendable, Equatable, Hashable, Codable {
    public var type: TypeRegle
    public var etat: EtatLigne
    public var raison: RaisonAVerifier?
    public var phrase: String
    /// Une ou deux sources (deux quand les textes se contredisent).
    public var sources: [SourceRegle]
    public var citation: String?
    public var dateLecture: Date?
    /// Catégorie inconnue : une valeur par catégorie (« 1re : fermée », « 2e : ouverte »).
    public var valeursParCategorie: [Categorie: String]
    /// Ligne de tronçon : son libellé, affiché avec « j'y suis ? ».
    public var libelleTroncon: String?

    public init(type: TypeRegle, etat: EtatLigne, raison: RaisonAVerifier? = nil, phrase: String,
                sources: [SourceRegle] = [], citation: String? = nil, dateLecture: Date? = nil,
                valeursParCategorie: [Categorie: String] = [:], libelleTroncon: String? = nil) {
        self.type = type
        self.etat = etat
        self.raison = raison
        self.phrase = phrase
        self.sources = sources
        self.citation = citation
        self.dateLecture = dateLecture
        self.valeursParCategorie = valeursParCategorie
        self.libelleTroncon = libelleTroncon
    }
}

/// La consigne globale. Aucune valeur d'autorisation : l'app montre la loi, elle n'accorde rien.
public enum Consigne: String, Sendable, Equatable, Hashable, Codable {
    case relacheLa
    case mesureLaSurUneToise
    case verifieLArrete
    case aucuneRegleSaisieNeLInterdit

    /// Texte affiché (la dernière phrase est le texte par défaut, à valider par Adem).
    public var texte: String {
        switch self {
        case .relacheLa: return "Relâche-la"
        case .mesureLaSurUneToise: return "Mesure-la sur une toise"
        case .verifieLArrete: return "Vérifie l'arrêté"
        case .aucuneRegleSaisieNeLInterdit: return "Aucune règle saisie ne l'interdit ; l'arrêté fait foi"
        }
    }
}

public struct ResultatControle: Sendable, Equatable, Hashable, Codable {
    public var lignes: [LigneControle]
    public var consigne: Consigne

    public init(lignes: [LigneControle], consigne: Consigne) {
        self.lignes = lignes
        self.consigne = consigne
    }
}

/// Comment la longueur a été obtenue (le nom `Mesure` est pris par le contrat de mesure d'usage).
public enum MethodeMesure: String, Sendable, Equatable, Hashable, Codable {
    case toise
    case saisie
    case estimee
}

public enum VerdictTaille: String, Sendable, Equatable, Hashable, Codable {
    case respectee
    case sousLaMaille
    /// À moins de 2 cm de la maille (seuil par défaut, à confirmer par Adem) : aucun verdict, mesure sur une toise.
    case tropPres
    /// Mesure `.estimee` : jamais de verdict.
    case sansVerdict
}
