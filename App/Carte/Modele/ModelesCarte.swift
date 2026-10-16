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

    var id: String { code }
}

/// Un point affiché : une station seule.
nonisolated struct PointCarte: Sendable, Equatable, Hashable, Identifiable {
    var id: String
    var coordonnee: Coordonnee
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

/// Regroupement des points : au plus `maximum` éléments dans la zone visible, un point par case au-delà.
/// Calcul pur, appelé hors du fil principal.
nonisolated enum Regroupeur {
    static let maximum = 150
    /// 12 x 12 = 144 cases au plus : jamais plus de 150 éléments.
    static let cotesGrille = 12

    static func elements(points: [PointCarte], region: ZoneCarte, maximum: Int = Regroupeur.maximum) -> [ElementCarte] {
        let visibles = points.filter { region.contient($0.coordonnee) }
        if visibles.count <= maximum { return visibles.map { .point($0) } }

        let n = Regroupeur.cotesGrille
        let latMin = region.centre.latitude - region.spanLatitude / 2 * 1.1
        let lonMin = region.centre.longitude - region.spanLongitude / 2 * 1.1
        let hauteur = region.spanLatitude * 1.1 / Double(n)
        let largeur = region.spanLongitude * 1.1 / Double(n)
        // Zone d'étendue nulle ou invalide : pas de grille possible (Int(inf) planterait).
        guard hauteur > 0, largeur > 0, hauteur.isFinite, largeur.isFinite else { return visibles.prefix(maximum).map { .point($0) } }

        var cases: [Int: [PointCarte]] = [:]
        for p in visibles {
            let i = min(n - 1, max(0, Int((p.coordonnee.latitude - latMin) / hauteur)))
            let j = min(n - 1, max(0, Int((p.coordonnee.longitude - lonMin) / largeur)))
            cases[i * n + j, default: []].append(p)
        }
        return cases.keys.sorted().compactMap { cle -> ElementCarte? in
            guard let membres = cases[cle] else { return nil }
            if membres.count == 1 { return .point(membres[0]) }
            let lat = membres.map { $0.coordonnee.latitude }.reduce(0, +) / Double(membres.count)
            let lon = membres.map { $0.coordonnee.longitude }.reduce(0, +) / Double(membres.count)
            return .groupe(id: "case-\(cle)", coordonnee: Coordonnee(latitude: lat, longitude: lon), nombre: membres.count)
        }
    }

    /// La région où zoomer quand on touche un regroupement : un tiers de l'étendue, centrée dessus.
    static func zoom(sur c: Coordonnee, depuis region: ZoneCarte) -> ZoneCarte {
        ZoneCarte(centre: c, spanLatitude: max(region.spanLatitude / 3, 0.02), spanLongitude: max(region.spanLongitude / 3, 0.02))
    }
}

/// Une station où nagent les petits poissons : `Core` y donne une espèce rare ou légendaire.
nonisolated struct StationAnimee: Sendable, Equatable, Identifiable {
    var station: StationCarte
    /// Noms d'images des espèces rares ou légendaires.
    var images: [String]
    var id: String { station.id }

    static let maximumStations = 20
    static let poissonsParStation = 3
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
}

// Calculs lourds : hors du fil principal (`@concurrent`), jamais dans une vue.

@concurrent nonisolated func calculerElements(points: [PointCarte], region: ZoneCarte) async -> [ElementCarte] {
    Regroupeur.elements(points: points, region: region)
}

/// Les stations où `Core` donne une espèce rare ou légendaire (20 au plus), les plus proches du centre d'abord.
@concurrent nonisolated func calculerAnimees(stations: [StationCarte], region: ZoneCarte, especes: any ServiceEspeces,
                                             images: [String: String]) async -> [StationAnimee] {
    // Trop dézoomé : rien ne nage (les poissons seraient illisibles, la carte coûterait cher).
    guard region.spanLatitude <= 3 else { return [] }
    let proches = stations
        .filter { region.contient($0.coordonnee, marge: 0) }
        .sorted { distanceMetres($0.coordonnee, region.centre) < distanceMetres($1.coordonnee, region.centre) }
    var niveaux: [String: NiveauRarete] = [:]
    var resultat: [StationAnimee] = []
    for station in proches {
        var rares: [String] = []
        for releve in station.releves {
            let cle = releve.espece.id + "|" + station.departement.code
            let niveau: NiveauRarete
            if let connu = niveaux[cle] {
                niveau = connu
            } else {
                niveau = especes.rarete(espece: releve.espece, departement: station.departement).niveau
                niveaux[cle] = niveau
            }
            if niveau == .rare || niveau == .legendaire, let image = images[releve.espece.id] { rares.append(image) }
        }
        guard !rares.isEmpty else { continue }
        resultat.append(StationAnimee(station: station, images: Array(rares.prefix(StationAnimee.poissonsParStation))))
        if resultat.count >= StationAnimee.maximumStations { break }
    }
    return resultat
}

@concurrent nonisolated func lireCoins(especes: any ServiceEspeces, espece: Espece, pres: Coordonnee) async -> [Coin] {
    especes.coins(ou: espece, pres: pres)
}
