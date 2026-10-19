import Foundation

/// Ce que le pêcheur met sur son repère. Liste fermée de la v1 (fiche N6, décision 6) : « danger » est une étiquette du pêcheur,
/// jamais une promesse de sécurité.
public enum IconeRepere: String, CaseIterable, Codable, Sendable {
    case parking
    case poste
    case danger
    case amorcage
}

/// Plafonds et seuils des repères (propositions de la fiche N6, à confirmer par Adem : décision 2).
public enum LimitesReperes {
    /// Repères actifs permis sans Pro.
    public static let gratuits = 3
    /// Plafond technique, même en Pro (poids des photos : voir risque 4 de la fiche).
    public static let plafondTechnique = 300
    public static let nomMax = 40
    public static let noteMax = 500
    public static let photosMax = 6
    /// Une position à cette distance ou moins d'un repère peut lui être rattachée.
    public static let rayonRattachementM: Double = 150
    /// Une pierre tombale plus vieille que cela disparaît à la fusion.
    public static let joursPierreTombale = 30
}

public enum ErreurRepere: Error, Equatable, Sendable {
    case nomVide
    case nomTropLong
    case noteTropLongue
}

/// Nom et note après contrôle (nom rogné).
public struct SaisieRepere: Equatable, Sendable {
    public var nom: String
    public var note: String

    public init(nom: String, note: String) {
        self.nom = nom
        self.note = note
    }
}

/// Un point que le pêcheur pose lui-même. Privé : il reste sur l'iPhone et dans l'iCloud privé du pêcheur, jamais publié.
/// Ce n'est pas un spot (le spot est fourni par FishMe).
public struct Repere: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var nom: String
    public var icone: IconeRepere
    public var note: String
    public var position: Coordonnee
    /// Rattachements explicites : une `Prise` ne reçoit jamais de coordonnée.
    public var idsPrises: [UUID]
    /// Noms de fichiers des photos ajoutées au repère.
    public var photos: [String]
    public var cree: Date
    public var modifie: Date
    public var passageManuel: Date?
    /// Pierre tombale : date de suppression. Un repère supprimé reste dans le fichier le temps de la fusion.
    public var supprime: Date?

    public init(id: UUID = UUID(), nom: String, icone: IconeRepere = .poste, note: String = "", position: Coordonnee,
                idsPrises: [UUID] = [], photos: [String] = [], cree: Date, modifie: Date? = nil,
                passageManuel: Date? = nil, supprime: Date? = nil) {
        self.id = id
        self.nom = nom
        self.icone = icone
        self.note = note
        self.position = position
        self.idsPrises = idsPrises
        self.photos = photos
        self.cree = cree
        self.modifie = modifie ?? cree
        self.passageManuel = passageManuel
        self.supprime = supprime
    }

    public var estSupprime: Bool { supprime != nil }

    /// Le dernier moment où ce repère a changé : sa modification ou sa suppression.
    public var dernierChangement: Date {
        guard let supprime else { return modifie }
        return max(modifie, supprime)
    }

    // MARK: Validation

    /// Nom rogné, ou `nil` s'il est vide ou plus long que `nomMax` (refusé, jamais tronqué en silence).
    public static func nomPropre(_ nom: String) -> String? {
        let rogne = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rogne.isEmpty, rogne.count <= LimitesReperes.nomMax else { return nil }
        return rogne
    }

    /// Contrôle une saisie. Les valeurs invalides sont refusées avec leur raison, jamais tronquées.
    public static func valide(nom: String, note: String) throws -> SaisieRepere {
        let rogne = nom.trimmingCharacters(in: .whitespacesAndNewlines)
        if rogne.isEmpty { throw ErreurRepere.nomVide }
        if rogne.count > LimitesReperes.nomMax { throw ErreurRepere.nomTropLong }
        if note.count > LimitesReperes.noteMax { throw ErreurRepere.noteTropLongue }
        return SaisieRepere(nom: rogne, note: note)
    }

    /// Les dates du fichier sont en ISO 8601 à la seconde : on les ramène à la seconde dès la création pour que
    /// l'aller-retour du fichier ne change jamais une date.
    public static func instant(_ date: Date) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded(.down))
    }

    // MARK: Dernier passage

    /// Le plus récent entre le passage noté à la main et la date des prises rattachées. `nil` : « Jamais noté ».
    public func dernierPassage(prises: [Prise]) -> Date? {
        let rattachees = Set(idsPrises)
        var dates = prises.filter { rattachees.contains($0.id) && !$0.estDeclaree }.map(\.date)
        if let passageManuel { dates.append(passageManuel) }
        return dates.max()
    }
}

public enum DecisionAjoutRepere: Equatable, Sendable {
    case oui
    /// Gratuit et `gratuits` repères déjà posés : le paywall s'ouvre, sans perdre la saisie.
    case paywall
    /// `plafondTechnique` repères actifs, même en Pro.
    case plafond
}

public enum ReglesReperes {
    /// `actifs` ne compte pas les pierres tombales (voir `actifs(dans:)`).
    public static func peutAjouter(actifs: Int, abonne: Bool) -> DecisionAjoutRepere {
        if actifs >= LimitesReperes.plafondTechnique { return .plafond }
        if !abonne && actifs >= LimitesReperes.gratuits { return .paywall }
        return .oui
    }

    public static func actifs(dans reperes: [Repere]) -> Int {
        reperes.filter { !$0.estSupprime }.count
    }
}

public enum RepereProche {
    /// Le repère actif le plus proche à `rayonM` mètres ou moins (150 m par défaut), `nil` sinon.
    public static func plusProche(de point: Coordonnee, dans reperes: [Repere],
                                  rayonM: Double = LimitesReperes.rayonRattachementM) -> Repere? {
        var meilleur: (Repere, Double)?
        for r in reperes where !r.estSupprime {
            let d = Geodesie.distanceM(point, r.position)
            guard d <= rayonM else { continue }
            if let m = meilleur, m.1 <= d { continue }
            meilleur = (r, d)
        }
        return meilleur?.0
    }
}

/// Arrondi des coordonnées pour un partage futur en zone floue (0,01°, environ 1 km, comme le spot gratuit).
/// Aucun appelant dans N6 : un lot de partage ne doit pas inventer son propre arrondi.
public enum ZoneFloue {
    public static func arrondi(_ c: Coordonnee) -> Coordonnee {
        Geodesie.arrondi(c)
    }
}
