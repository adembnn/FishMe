import Foundation

/// Rareté américaine (lot US-rarete). Calcul pur, sans réseau : la fréquence d'occurrence d'une espèce par HUC8
/// (événements d'échantillonnage avec l'espèce ÷ événements totaux), par milieu et par engin, avec repli HUC6 puis État.
/// Rien ici n'est branché dans l'app : la rareté ne s'affiche qu'après la revue d'un biologiste (`ParametresRareteUS.revueBiologisteValidee`).

/// Type de milieu de l'événement.
enum MilieuUS: String, Sendable, Equatable, Hashable, Comparable {
    case coursDeau = "cours_d_eau"
    case lac
    case autre

    static func < (a: MilieuUS, b: MilieuUS) -> Bool { a.rawValue < b.rawValue }
}

/// Un événement d'échantillonnage (une pêche scientifique : un site, un jour, un engin) et les espèces qu'il a trouvées.
/// Jamais de coordonnées : le HUC8 suffit, et les positions des espèces sensibles ne sortent pas.
struct EvenementEchantillonnageUS: Sendable, Equatable {
    var id: String
    /// 8 chiffres (code HUC8 du USGS).
    var huc8: String
    /// Code postal de l'État (« WI »).
    var etat: String
    var milieu: MilieuUS
    /// Engin tel que la source le nomme, ramené en minuscules (« electrofishing »).
    var engin: String
    /// Espèces trouvées (nom scientifique ou code de la source) ; un événement sans espèce reste un événement vide, il compte au dénominateur.
    var especes: Set<String>
    var annee: Int
    var source: String

    var huc6: String { String(huc8.prefix(6)) }
}

/// Strate de comparaison : on ne compare pas une électropêche à un filet.
struct StrateUS: Sendable, Equatable, Hashable, Comparable {
    var milieu: String
    var engin: String

    static let tous = "tous"

    static func < (a: StrateUS, b: StrateUS) -> Bool { (a.milieu, a.engin) < (b.milieu, b.engin) }
}

/// Classe de rareté américaine. Pas de « légendaire » : une absence de donnée n'est pas une rareté.
enum ClasseRareteUS: String, Sendable, Equatable {
    case commun
    case peuCommun = "peu_commun"
    case rare
    case donneeInsuffisante = "donnee_insuffisante"
}

/// Pourquoi une espèce est en « donnée insuffisante ».
enum MotifInsuffisantUS: String, Sendable, Equatable {
    /// Aucun échelon (HUC8, HUC6, État) n'atteint le minimum d'événements.
    case pasAssezEvenements = "pas_assez_evenements"
    /// L'échelon retenu est assez fourni mais l'espèce n'y a jamais été trouvée : « non observée », pas « légendaire ».
    case nonObservee = "non_observee"
    /// Trop peu de cellules fiables dans la strate pour calculer des quantiles.
    case seuilsNonCalibres = "seuils_non_calibres"
}

/// Échelon géographique réellement utilisé.
enum EchelleUS: String, Sendable, Equatable {
    case huc8
    case huc6
    case etat
    /// Aucun échelon n'atteint le minimum ; les comptes viennent du plus fin qui a des événements.
    case aucune
}

/// Seuils de classe : des quantiles de la distribution (à calibrer sur un État pilote) ou des fréquences fixes.
enum SeuilsRareteUS: Sendable, Equatable {
    /// Rare sous le quantile `peuCommun`, commun à partir du quantile `commun` (par exemple 1/3 et 2/3).
    case quantiles(peuCommun: Double, commun: Double)
    /// Fréquences fixes (par exemple 0,2 et 0,5 comme l'OFB) : seulement après un test, jamais par défaut.
    case fixes(peuCommun: Double, commun: Double)
}

struct ParametresRareteUS: Sendable, Equatable {
    /// Minimum d'événements d'un échelon pour y lire une fréquence. Valeur de départ, à fixer sur l'État pilote.
    var minimumEvenements = 20
    var seuils = SeuilsRareteUS.quantiles(peuCommun: 1.0 / 3.0, commun: 2.0 / 3.0)
    /// Cellules fiables (espèce × HUC8 vue au moins une fois) qu'il faut dans une strate pour calculer des quantiles.
    var minimumCellulesCalibrage = 10
    /// Ne garde que les événements de cette année et après (fenêtre glissante de 10 à 15 ans).
    var anneeMinimum: Int?
    /// Une strate par milieu, une strate par engin ; faux : tous milieux / tous engins confondus.
    var separerParMilieu = true
    var separerParEngin = true
    /// Vrai seulement après la revue d'un biologiste d'agence : tant que c'est faux, aucune classe ne s'affiche.
    var revueBiologisteValidee = false
}

/// Résultat pour une espèce dans un HUC8 : toujours avec le nombre d'événements, la dernière année et la source.
struct ResultatRareteUS: Sendable, Equatable {
    var espece: String
    var huc8: String
    var strate: StrateUS
    var classe: ClasseRareteUS
    var motif: MotifInsuffisantUS?
    /// nEspece ÷ nTotal ; nil sans événement.
    var frequence: Double?
    var nEspece: Int
    var nTotal: Int
    /// Dernière année où l'espèce est vue dans l'échelon utilisé ; nil si jamais vue.
    var derniereAnnee: Int?
    var echelle: EchelleUS
    /// Code de l'échelon (HUC8, HUC6 ou État) ; vide si `aucune` sans événement.
    var codeEchelle: String
    /// Sources des événements de l'échelon, triées.
    var sources: [String]
    var affichageRarete: Bool

    /// Texte de présence, seul affiché avant la revue : jamais de niveau.
    var libellePresence: String {
        let src = sources.isEmpty ? "aucune source" : sources.joined(separator: ", ")
        if nEspece == 0 {
            return "Non vue dans \(nTotal) événements (\(echelle.rawValue) \(codeEchelle)), source \(src)"
        }
        let an = derniereAnnee.map { "dernière année \($0)" } ?? "année inconnue"
        return "Vue dans \(nEspece) événements sur \(nTotal) (\(echelle.rawValue) \(codeEchelle)), \(an), source \(src)"
    }
}
