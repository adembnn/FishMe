import Foundation

/// Source d'une entrée (nom, lien https, licence, date). Toujours affichable avec l'espèce.
public struct SourceEspeceUS: Codable, Sendable, Hashable {
  public let nom: String
  public let url: String
  public let licence: String
  public let date: String

  public init(nom: String, url: String, licence: String, date: String) {
    self.nom = nom
    self.url = url
    self.licence = licence
    self.date = date
  }
}

/// Zone d'une entrée : `type` vaut « etat », « huc8 » ou « plan_eau ». Jamais de coordonnée.
public struct ZoneEspeceUS: Codable, Sendable, Hashable {
  public let type: String
  public let id: String
  public let nom: String?

  public init(type: String, id: String, nom: String? = nil) {
    self.type = type
    self.id = id
    self.nom = nom
  }
}

/// Une espèce signalée dans une zone, telle qu'un producteur l'a écrite (source déjà résolue).
public struct EntreeEspeceUS: Codable, Sendable, Hashable {
  public let slug: String?
  public let nom: String
  public let latin: String
  public let zone: ZoneEspeceUS
  public let preuve: String
  public let confiance: String
  public let n: Int?
  public let anneeMax: Int?
  public let source: SourceEspeceUS

  public init(
    slug: String?, nom: String, latin: String, zone: ZoneEspeceUS, preuve: String,
    confiance: String,
    n: Int? = nil, anneeMax: Int? = nil, source: SourceEspeceUS
  ) {
    self.slug = slug
    self.nom = nom
    self.latin = latin
    self.zone = zone
    self.preuve = preuve
    self.confiance = confiance
    self.n = n
    self.anneeMax = anneeMax
    self.source = source
  }

  enum CodingKeys: String, CodingKey {
    case slug, nom, latin, zone, preuve, confiance, n, source
    case anneeMax = "annee_max"
  }

  /// Niveau de confiance lu dans le texte ; un texte inconnu compte comme le plus bas.
  public var niveauConfiance: NiveauConfianceEspeceUS { NiveauConfianceEspeceUS(texte: confiance) }
}

/// Du plus sûr au moins sûr. L'ordre de `rawValue` sert au tri (0 d'abord).
public enum NiveauConfianceEspeceUS: Int, Sendable, Comparable, Codable {
  case officielle = 0
  case enregistrementScientifique = 1
  case nonConfirme = 2

  public init(texte: String) {
    switch texte {
    case "officielle": self = .officielle
    case "enregistrement_scientifique": self = .enregistrementScientifique
    default: self = .nonConfirme
    }
  }

  /// Texte tel qu'il est écrit dans les fichiers.
  public var texte: String {
    switch self {
    case .officielle: return "officielle"
    case .enregistrementScientifique: return "enregistrement_scientifique"
    case .nonConfirme: return "non confirmé, signalement public"
    }
  }

  public static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}

/// Zone demandée. Le plan d'eau se donne par identifiant ou par nom (comparé sans accents ni casse) ; le HUC8 par ses 8 chiffres.
public struct ZoneDemandeeUS: Sendable, Hashable {
  public let planEau: String?
  public let huc8: String?

  public init(planEau: String? = nil, huc8: String? = nil) {
    self.planEau = planEau
    self.huc8 = huc8
  }
}

/// Niveau auquel la requête s'est arrêtée.
public enum NiveauZoneUS: String, Sendable, Codable {
  case planEau = "plan_eau"
  case huc8
  case etat
}

/// Une espèce, une seule fois, avec ce que toutes les entrées retenues en disent.
public struct EspeceSignaleeUS: Sendable, Hashable {
  public let slug: String?
  public let nom: String
  public let latin: String
  /// Meilleur niveau de confiance parmi les entrées retenues.
  public let confiance: NiveauConfianceEspeceUS
  public let preuves: [String]
  public let sources: [SourceEspeceUS]
  /// Somme des `n` connus ; nil si aucune entrée n'en donne.
  public let n: Int?
  public let anneeMax: Int?

  public init(slug: String?, nom: String, latin: String, confiance: NiveauConfianceEspeceUS, preuves: [String],
              sources: [SourceEspeceUS], n: Int?, anneeMax: Int?) {
    self.slug = slug; self.nom = nom; self.latin = latin; self.confiance = confiance
    self.preuves = preuves; self.sources = sources; self.n = n; self.anneeMax = anneeMax
  }
}

public struct ResultatEspecesUS: Sendable, Hashable {
  /// Niveau où les espèces ont été trouvées ; nil si rien n'a été trouvé à aucun niveau.
  public let niveau: NiveauZoneUS?
  public let especes: [EspeceSignaleeUS]

  public init(niveau: NiveauZoneUS?, especes: [EspeceSignaleeUS]) {
    self.niveau = niveau; self.especes = especes
  }
}
