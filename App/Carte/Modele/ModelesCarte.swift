import Foundation
import Core

// Types de données purs de la carte : tous `nonisolated` et Sendable, pour être calculés hors du fil principal.

/// Une zone visible (nommée ZoneCarte pour ne pas masquer `RegionCarte` de Core) de la carte (centre et étendue en degrés).
nonisolated struct ZoneCarte: Sendable, Equatable, Codable {
    var centre: Coordonnee
    var spanLatitude: Double
    var spanLongitude: Double

    func contient(_ c: Coordonnee, marge: Double = 0.1) -> Bool {
        let demiLat = spanLatitude / 2 * (1 + marge)
        let demiLon = spanLongitude / 2 * (1 + marge)
        return abs(c.latitude - centre.latitude) <= demiLat && abs(c.longitude - centre.longitude) <= demiLon
    }

    /// Vrai si cette zone tient entièrement dans la zone déjà chargée par `StationsViaCore` (la zone demandée plus une demi-zone de marge
    /// de chaque côté, soit 1,5 fois son étendue) : inutile de relire les stations, le regroupement suffit.
    func estCouverte(parChargee chargee: ZoneCarte) -> Bool {
        let demiLat = chargee.spanLatitude / 2 * 1.5
        let demiLon = chargee.spanLongitude / 2 * 1.5
        return abs(centre.latitude - chargee.centre.latitude) + spanLatitude / 2 <= demiLat
            && abs(centre.longitude - chargee.centre.longitude) + spanLongitude / 2 <= demiLon
    }

    /// Vrai si les deux vues sont presque les mêmes (centre à moins de 35 % de l'étendue, étendue à un facteur 1,7 près) :
    /// MapKit corrige un peu l'étendue demandée pour l'écran, une vue « proche » reste celle que le code a posée.
    func estProche(de autre: ZoneCarte) -> Bool {
        guard autre.spanLatitude > 0, autre.spanLongitude > 0 else { return false }
        let rapport = spanLatitude / autre.spanLatitude
        return abs(centre.latitude - autre.centre.latitude) <= autre.spanLatitude * 0.35
            && abs(centre.longitude - autre.centre.longitude) <= autre.spanLongitude * 0.35
            && rapport >= 0.6 && rapport <= 1.7
    }

    /// Paris et l'Île-de-France : la carte d'un relecteur hors de France (jamais une carte vide).
    static let parisIleDeFrance = ZoneCarte(centre: Coordonnee(latitude: 48.86, longitude: 2.35), spanLatitude: 1.2, spanLongitude: 1.6)
    static let france = ZoneCarte(centre: Coordonnee(latitude: 46.6, longitude: 2.5), spanLatitude: 11, spanLongitude: 13)
}

/// Une espèce relevée à une station OFB, avec N et l'année : rien d'autre n'est affiché comme chiffre.
nonisolated struct ReleveEspece: Sendable, Equatable, Hashable, Codable {
    var espece: Espece
    var nPeches: Int
    var annee: Int
}

/// Une station OFB de la carte, avec les espèces qui y sont relevées.
nonisolated struct StationCarte: Sendable, Equatable, Hashable, Identifiable, Codable {
    var code: String
    var eau: String?
    var departement: Departement
    var coordonnee: Coordonnee
    var releves: [ReleveEspece]
    /// Décision 8 du 19 oct. (D5) : `true` = la coordonnée est posée sur le tracé du cours d'eau (épingle) ;
    /// `false` = elle garde l'arrondi à 0,01° (environ 1 km) et la carte la dessine en halo, jamais en épingle.
    /// Absent de l'ancien fichier de stations : lu à `true`, jamais de plantage.
    var recalee: Bool = true

    var id: String { code }

    enum CodingKeys: String, CodingKey { case code, eau, departement, coordonnee, releves, recalee }
}

extension StationCarte {
    /// Lecture tolérante : un ancien cache ou un ancien fichier sans `recalee` donne `true`.
    nonisolated init(from decodeur: Decoder) throws {
        let c = try decodeur.container(keyedBy: CodingKeys.self)
        self.init(code: try c.decode(String.self, forKey: .code),
                  eau: try c.decodeIfPresent(String.self, forKey: .eau),
                  departement: try c.decode(Departement.self, forKey: .departement),
                  coordonnee: try c.decode(Coordonnee.self, forKey: .coordonnee),
                  releves: try c.decode([ReleveEspece].self, forKey: .releves),
                  recalee: try c.decodeIfPresent(Bool.self, forKey: .recalee) ?? true)
    }

    /// Le point que dessine la carte pour cette station.
    nonisolated var point: PointCarte { PointCarte(id: code, coordonnee: coordonnee, recalee: recalee) }
}

/// Lit le champ `recalee` d'une station de `Core` quand `Core` le porte (D5, via B/L1), sinon `true`.
/// `StationOFB` n'a pas ce champ aujourd'hui et `Packages/Core` n'est pas à L17 : la lecture passe par le miroir du type,
/// et marche sans rien changer le jour où `StationOFB` gagne un `recalee: Bool` (ou `Bool?`).
nonisolated enum LectureRecalage {
    static func valeur(de station: Any) -> Bool {
        for enfant in Mirror(reflecting: station).children where enfant.label == "recalee" {
            if let b = enfant.value as? Bool { return b }
            if let b = enfant.value as? Bool? { return b ?? true }
        }
        return true
    }
}

/// Un point affiché : une station seule.
nonisolated struct PointCarte: Sendable, Equatable, Hashable, Identifiable {
    var id: String
    var coordonnee: Coordonnee
    /// Faux : la carte dessine un halo de 1 km à la place de l'épingle (jamais une épingle).
    var recalee: Bool = true
}

/// Ce que la carte dessine : un point ou un regroupement (un point par case, avec le nombre de stations).
nonisolated enum ElementCarte: Sendable, Equatable, Identifiable {
    case point(PointCarte)
    case groupe(id: String, coordonnee: Coordonnee, nombre: Int)

    var id: String {
        switch self {
        case .point(let p): return p.id
        case .groupe(let id, _, _): return id
        }
    }

    var coordonnee: Coordonnee {
        switch self {
        case .point(let p): return p.coordonnee
        case .groupe(_, let c, _): return c
        }
    }
}

/// Les trois niveaux de zoom de la carte. Chaque niveau montre de plus petites grappes et plus d'épingles que le précédent.
/// Les seuils sont des étendues en degrés de latitude, lues sur les vues que la carte pose elle-même :
/// France entière 11, vue d'une région 3,7 (un toucher sur une grappe divise l'étendue par 3), vue d'un département 1,2, ouverture 0,14.
nonisolated enum NiveauZoomCarte: Int, Sendable, Equatable, Comparable {
    case large = 1, moyen, proche

    /// Au-dessus : `large` (la France, de grosses grappes).
    static let seuilLarge = 6.0
    /// Au-dessus : `moyen` (une région) ; en dessous : `proche` (un département ou moins, les épingles).
    static let seuilMoyen = 1.5

    static func pour(spanLatitude: Double) -> NiveauZoomCarte {
        if spanLatitude > seuilLarge { return .large }
        if spanLatitude > seuilMoyen { return .moyen }
        return .proche
    }

    static func < (a: NiveauZoomCarte, b: NiveauZoomCarte) -> Bool { a.rawValue < b.rawValue }

    /// Part de la grille pleine utilisée : plus on est loin, plus les grappes sont grosses.
    var finesse: Double {
        switch self {
        case .large: return 0.6
        case .moyen: return 0.85
        case .proche: return 1.0
        }
    }
}

/// Regroupement des points : au plus `maximum` éléments dans la zone visible (60 pour tout l'écran, décision du 19 oct.),
/// des grappes numérotées au-delà. Calcul pur, appelé hors du fil principal.
nonisolated enum Regroupeur {
    /// Le budget de tout l'écran : stations, halos, grappes et épingles d'eau ensemble.
    static let maximum = 60
    /// Part du budget des stations quand les épingles d'eau sont aussi dessinées (niveau `proche`).
    static let maximumStationsAvecEau = 40
    /// Part du budget des épingles d'eau (niveau `proche` seulement) : 40 + 20 = 60.
    static let maximumEau = 20

    /// Le nombre de cases de la grille (lignes, colonnes) : leur produit ne dépasse jamais `maximum`.
    static func grille(maximum: Int, niveau: NiveauZoomCarte) -> (lignes: Int, colonnes: Int) {
        let plein = max(1, Int(Double(maximum).squareRoot()))
        let lignes = max(1, min(plein, Int((Double(plein) * niveau.finesse).rounded(.down))))
        let colonnes = max(1, min(maximum / lignes, lignes + 1))
        return (lignes, colonnes)
    }

    static func elements(points: [PointCarte], region: ZoneCarte, maximum: Int = Regroupeur.maximum) -> [ElementCarte] {
        guard maximum > 0 else { return [] }
        let visibles = points.filter { region.contient($0.coordonnee) }
        if visibles.count <= maximum { return visibles.map { .point($0) } }

        let niveau = NiveauZoomCarte.pour(spanLatitude: region.spanLatitude)
        let (n, m) = grille(maximum: maximum, niveau: niveau)
        let latMin = region.centre.latitude - region.spanLatitude / 2 * 1.1
        let lonMin = region.centre.longitude - region.spanLongitude / 2 * 1.1
        let hauteur = region.spanLatitude * 1.1 / Double(n)
        let largeur = region.spanLongitude * 1.1 / Double(m)
        // Zone d'étendue nulle ou invalide : pas de grille possible (Int(inf) planterait).
        guard hauteur > 0, largeur > 0, hauteur.isFinite, largeur.isFinite else { return visibles.prefix(maximum).map { .point($0) } }

        var cases: [Int: [PointCarte]] = [:]
        for p in visibles {
            let i = min(n - 1, max(0, Int((p.coordonnee.latitude - latMin) / hauteur)))
            let j = min(m - 1, max(0, Int((p.coordonnee.longitude - lonMin) / largeur)))
            cases[i * m + j, default: []].append(p)
        }
        return cases.keys.sorted().compactMap { cle -> ElementCarte? in
            guard let membres = cases[cle] else { return nil }
            if membres.count == 1 { return .point(membres[0]) }
            let lat = membres.map { $0.coordonnee.latitude }.reduce(0, +) / Double(membres.count)
            let lon = membres.map { $0.coordonnee.longitude }.reduce(0, +) / Double(membres.count)
            return .groupe(id: "case-\(cle)", coordonnee: Coordonnee(latitude: lat, longitude: lon), nombre: membres.count)
        }
    }

    /// Le budget des stations pour une vue : tout l'écran aux niveaux `large` et `moyen` (l'eau n'est pas dessinée),
    /// 40 au niveau `proche` (les 20 autres sont aux épingles d'eau).
    static func maximumStations(pour region: ZoneCarte) -> Int {
        NiveauZoomCarte.pour(spanLatitude: region.spanLatitude) == .proche ? maximumStationsAvecEau : maximum
    }

    /// Les épingles d'eau ne se dessinent qu'au niveau `proche` : plus loin, elles mangeraient le budget des grappes.
    static func eauVisible(pour region: ZoneCarte) -> Bool {
        NiveauZoomCarte.pour(spanLatitude: region.spanLatitude) == .proche
    }

    /// La région où zoomer quand on touche un regroupement : un tiers de l'étendue, centrée dessus.
    static func zoom(sur c: Coordonnee, depuis region: ZoneCarte) -> ZoneCarte {
        ZoneCarte(centre: c, spanLatitude: max(region.spanLatitude / 3, 0.02), spanLongitude: max(region.spanLongitude / 3, 0.02))
    }
}

/// Où en est le choix de la zone au départ.
nonisolated enum DepartCarte: Sendable, Equatable {
    case enAttente
    /// La position est connue et en France.
    case surLePecheur(Coordonnee)
    /// Position refusée : le pêcheur choisit son département ou sa commune sur la carte.
    case choixDeZone
    /// Choix fait à la main (sans GPS).
    case zoneChoisie(Coordonnee)
    /// Hors de France : la carte s'ouvre sur Paris et l'Île-de-France.
    case horsDeFrance
}

/// Ce qu'on ouvre quand on touche un point de la carte : le coin et, s'il vient du filtre, son relevé.
nonisolated struct CoinSelectionne: Identifiable, Equatable, Sendable {
    var id: String
    var coordonnee: Coordonnee
    var eau: String?
    var departement: Departement?
    /// Renseigné quand le coin vient du filtre d'espèce.
    var coin: Coin?
    /// Faux : la station garde l'arrondi à 0,01° (halo) ; la fiche le dit d'une icône, et « Y aller » vise ce point approximatif.
    var recalee: Bool = true
}

// Calculs lourds : hors du fil principal (`@concurrent`), jamais dans une vue.

@concurrent nonisolated func calculerElements(points: [PointCarte], region: ZoneCarte, maximum: Int = Regroupeur.maximum) async -> [ElementCarte] {
    Regroupeur.elements(points: points, region: region, maximum: maximum)
}

@concurrent nonisolated func lireCoins(especes: any ServiceEspeces, espece: Espece, pres: Coordonnee) async -> [Coin] {
    especes.coins(ou: espece, pres: pres)
}
