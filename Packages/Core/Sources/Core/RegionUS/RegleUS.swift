import Foundation

/// D'où vient une donnée : la page ou le livret de l'agence, avec la date de lecture. Toute donnée US porte une source et une date ;
/// sans elles la donnée n'entre pas (un `SourceUS` ne se construit pas sans URL web ni date).
public struct SourceUS: Sendable, Equatable, Hashable, Codable {
    public let url: URL
    public let dateLecture: JourCivil
    /// Édition lue (ex. « Fishing Regulations 2026 »), si connue.
    public let edition: String?
    /// Passage du texte officiel d'où vient la valeur, si gardé.
    public let citation: String?

    /// `nil` si l'URL n'est pas une adresse http(s) avec un hôte.
    public init?(url: String, dateLecture: JourCivil, edition: String? = nil, citation: String? = nil) {
        guard let u = URL(string: url), let schema = u.scheme?.lowercased(), schema == "http" || schema == "https",
              let hote = u.host, !hote.isEmpty else { return nil }
        self.url = u
        self.dateLecture = dateLecture
        self.edition = edition
        self.citation = citation
    }
}

/// Niveau de couverture des décisions du 7 nov. (décision 2) : 1 = 50 États (permis, prix, lien de l'agence, « à vérifier ») ;
/// 2 = règles par espèce au niveau de l'État, par double lecture ; 3 = règles par plan d'eau là où un jeu ouvert existe.
public enum CouvertureUS: Int, Sendable, Hashable, Codable, Comparable, CaseIterable {
    case niveau1 = 1
    case niveau2 = 2
    case niveau3 = 3

    public static func < (a: CouvertureUS, b: CouvertureUS) -> Bool { a.rawValue < b.rawValue }
}

/// Où en est la relecture d'une règle. Seules les règles confirmées (double lecture concordante, ou personne) peuvent fonder « interdit » ;
/// les autres tombent à « à vérifier » (décision 3 du 7 nov. ; comme `consensus.py` en France).
public enum StatutRelecture: String, Sendable, Hashable, Codable, CaseIterable {
    case nonRelue
    case doubleLectureConfirmee
    case lecturesDivergentes
    case relueParPersonne

    public var estConfirme: Bool { self == .doubleLectureConfirmee || self == .relueParPersonne }
}

/// Jour de l'année sans année (1er mai, 28 févr.). Le 29 févr. est accepté.
public struct MoisJour: Sendable, Hashable, Codable, Comparable {
    public let mois: Int
    public let jour: Int

    public init?(mois: Int, jour: Int) {
        guard (1...12).contains(mois), jour >= 1,
              jour <= JourCivil.joursDansMois(annee: 2024, mois: mois) else { return nil }
        self.mois = mois
        self.jour = jour
    }

    var rang: Int { mois * 100 + jour }
    public static func < (a: MoisJour, b: MoisJour) -> Bool { a.rang < b.rang }
}

/// Où tombe un jour par rapport à une période annuelle.
public enum PositionDansPeriode: Sendable, Equatable {
    case dedans
    /// Premier ou dernier jour : les textes divergent sur l'inclusion (« jusqu'au », « à partir du »), donc le moteur ne tranche pas.
    case surBorne
    case dehors
}

/// Une période de l'année, bornes comprises, qui peut enjamber le 31 déc. (début après fin : du 1er nov. au 15 mars).
public struct PeriodeAnnuelle: Sendable, Hashable, Codable {
    public let debut: MoisJour
    public let fin: MoisJour

    public init(debut: MoisJour, fin: MoisJour) {
        self.debut = debut
        self.fin = fin
    }

    public func position(de jour: JourCivil) -> PositionDansPeriode {
        guard let j = MoisJour(mois: jour.mois, jour: jour.jour) else { return .dehors }
        if j == debut || j == fin { return .surBorne }
        if debut <= fin { return (j > debut && j < fin) ? .dedans : .dehors }
        return (j > debut || j < fin) ? .dedans : .dehors
    }
}

/// Fenêtre protégée (slot) : les poissons dont la taille est strictement entre `basse` et `haute` sont à relâcher.
public struct FenetreProtegee: Sendable, Hashable, Codable {
    public let basse: Longueur
    public let haute: Longueur

    /// `nil` si la borne basse n'est pas strictement sous la haute.
    public init?(basse: Longueur, haute: Longueur) {
        guard basse < haute else { return nil }
        self.basse = basse
        self.haute = haute
    }
}

/// Règles de taille. Une valeur absente veut dire « non lue », jamais « pas de limite ».
public struct TaillesUS: Sendable, Hashable, Codable {
    public var minimale: Longueur?
    public var fenetre: FenetreProtegee?
    public var maximale: Longueur?

    public init(minimale: Longueur? = nil, fenetre: FenetreProtegee? = nil, maximale: Longueur? = nil) {
        self.minimale = minimale
        self.fenetre = fenetre
        self.maximale = maximale
    }

    var estVide: Bool { minimale == nil && fenetre == nil && maximale == nil }
}

/// Limite de prise (par jour) et de possession (stock détenu) : deux valeurs distinctes. Absente = non lue, jamais « illimitée ».
public struct LimitesUS: Sendable, Hashable, Codable {
    public var prise: Int?
    public var possession: Int?

    public init(prise: Int? = nil, possession: Int? = nil) {
        self.prise = prise
        self.possession = possession
    }

    var estVide: Bool { prise == nil && possession == nil }
}

public enum TypeFermeture: String, Sendable, Hashable, Codable, CaseIterable {
    /// Pêche interdite (eau fermée, frayère).
    case pecheInterdite
    /// Prise et relâche seulement : rien ne se garde.
    case remiseAEauSeulement
    /// Espèce protégée (liste fédérale ou d'État) : à relâcher.
    case especeProtegee
}

/// Une fermeture, permanente (`periode` vide) ou sur une période de l'année.
public struct FermetureUS: Sendable, Hashable, Codable {
    public let type: TypeFermeture
    public let periode: PeriodeAnnuelle?
    public let motif: String

    public init(type: TypeFermeture, periode: PeriodeAnnuelle? = nil, motif: String) {
        self.type = type
        self.periode = periode
        self.motif = motif
    }
}

/// Tranche d'âge à laquelle la règle s'applique (ex. limite de prise propre aux 16 ans et plus). Bornes comprises.
public struct ConditionAge: Sendable, Hashable, Codable {
    public let ageMin: Int?
    public let ageMax: Int?

    public init(ageMin: Int? = nil, ageMax: Int? = nil) {
        self.ageMin = ageMin
        self.ageMax = ageMax
    }

    func contient(_ age: Int) -> Bool {
        (ageMin.map { age >= $0 } ?? true) && (ageMax.map { age <= $0 } ?? true)
    }
}

/// Les familles de contraintes : une règle plus spécifique remplace celles, plus larges, de la même famille seulement.
public enum FamilleRegle: String, Sendable, Hashable, CaseIterable {
    case ouverture
    case taille
    case limites
    case engins
    case appats
}

/// Une règle de pêche américaine, accrochée à une juridiction (État, zone, plan d'eau ou tronçon) et, si `espece` est renseignée, à une espèce.
/// Chaque champ absent est « non lu », pas « sans limite ».
public struct RegleUS: Sendable, Equatable, Hashable, Codable {
    public let id: String
    public let portee: IdJuridiction
    /// Identifiant d'espèce de l'app ; `nil` = toutes les espèces de la portée.
    public let espece: String?
    /// Période d'ouverture (hors de cette période : fermé).
    public var saison: PeriodeAnnuelle?
    public var tailles: TaillesUS
    public var limites: LimitesUS
    public var engins: [String]
    public var appats: [String]
    public var fermetures: [FermetureUS]
    public var age: ConditionAge?
    public let source: SourceUS
    public let couverture: CouvertureUS
    public var statut: StatutRelecture
    /// Dernier jour de validité (règle expérimentale, avis annuel) ; passé ce jour la règle ne fonde plus « interdit ».
    public var valideJusqua: JourCivil?

    public init(id: String, portee: IdJuridiction, espece: String? = nil, saison: PeriodeAnnuelle? = nil, tailles: TaillesUS = TaillesUS(),
                limites: LimitesUS = LimitesUS(), engins: [String] = [], appats: [String] = [], fermetures: [FermetureUS] = [],
                age: ConditionAge? = nil, source: SourceUS, couverture: CouvertureUS, statut: StatutRelecture = .nonRelue,
                valideJusqua: JourCivil? = nil) {
        self.id = id
        self.portee = portee
        self.espece = espece
        self.saison = saison
        self.tailles = tailles
        self.limites = limites
        self.engins = engins
        self.appats = appats
        self.fermetures = fermetures
        self.age = age
        self.source = source
        self.couverture = couverture
        self.statut = statut
        self.valideJusqua = valideJusqua
    }

    var familles: Set<FamilleRegle> {
        var f: Set<FamilleRegle> = []
        if saison != nil || !fermetures.isEmpty { f.insert(.ouverture) }
        if !tailles.estVide { f.insert(.taille) }
        if !limites.estVide { f.insert(.limites) }
        if !engins.isEmpty { f.insert(.engins) }
        if !appats.isEmpty { f.insert(.appats) }
        return f
    }
}
