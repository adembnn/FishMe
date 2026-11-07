import Foundation
import Core

/// Ce que la carte dessine : un point d'accès, un plan d'eau, ou un groupe de lieux trop serrés pour être dessinés un à un.
nonisolated enum ElementCarteUS: Sendable, Hashable, Identifiable {
    case point(PointAccesCarteUS)
    case planEau(PlanEauCarteUS)
    case groupe(id: String, centre: Coordonnee, nombre: Int)

    var id: String {
        switch self {
        case .point(let p): "p-" + p.id
        case .planEau(let e): "e-" + e.id
        case .groupe(let id, _, _): "g-" + id
        }
    }

    var coordonnee: Coordonnee {
        switch self {
        case .point(let p): p.coordonnee
        case .planEau(let e): e.coordonnee
        case .groupe(_, let c, _): c
        }
    }
}

/// Le tri de ce qui est visible : distance, zone et regroupement. Fonctions pures, sans état : appelées hors du thread principal.
nonisolated enum SelectionCarteUS {
    /// Plafond de la carte. Le regroupement en donne au plus 196 (14 x 14 cases).
    static let plafond = 200
    /// Au-delà de cette étendue (degrés de latitude), la carte est trop dézoomée pour lister des lieux : on demande de zoomer.
    static let etendueMaximale = 6.0

    static func distanceKm(_ a: Coordonnee, _ b: Coordonnee) -> Double {
        let r = 6_371.0088
        let p1 = a.latitude * .pi / 180, p2 = b.latitude * .pi / 180
        let dp = p2 - p1
        let dl = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2)
        return 2 * r * asin(min(1, h.squareRoot()))
    }

    /// Les points à moins de rayonKm du centre, du plus proche au plus loin, au plus limite. Égalité de distance : par identifiant.
    static func autour(_ centre: Coordonnee, rayonKm: Double, limite: Int, dans points: [PointAccesCarteUS]) -> [PointAccesCarteUS] {
        guard limite > 0, rayonKm >= 0 else { return [] }
        var proches: [(point: PointAccesCarteUS, distance: Double)] = []
        for p in points {
            let d = distanceKm(centre, p.coordonnee)
            if d <= rayonKm { proches.append((p, d)) }
        }
        proches.sort { a, b in a.distance != b.distance ? a.distance < b.distance : a.point.id < b.point.id }
        return proches.prefix(limite).map { item in item.point }
    }

    /// Les éléments à dessiner dans la zone : tout ce qui est visible s'il y en a peu, sinon des groupes par cases de la grille.
    static func elements(points: [PointAccesCarteUS], plans: [PlanEauCarteUS], dans zone: ZoneCarte,
                         maximum: Int = plafond) -> [ElementCarteUS] {
        guard maximum > 0, zone.spanLatitude <= etendueMaximale, zone.spanLatitude > 0, zone.spanLongitude > 0 else { return [] }
        var visibles: [ElementCarteUS] = []
        for e in plans.filter({ zone.contient($0.coordonnee) }).sorted(by: { a, b in a.id < b.id }) { visibles.append(.planEau(e)) }
        for p in points.filter({ zone.contient($0.coordonnee) }).sorted(by: { a, b in a.id < b.id }) { visibles.append(.point(p)) }
        if visibles.count <= maximum { return visibles }

        let cotes = max(1, min(14, Int(Double(maximum).squareRoot())))
        let sud = zone.centre.latitude - zone.spanLatitude / 2
        let ouest = zone.centre.longitude - zone.spanLongitude / 2
        var cases: [Int: [ElementCarteUS]] = [:]
        for e in visibles {
            let c = e.coordonnee
            let i = min(cotes - 1, max(0, Int((c.latitude - sud) / zone.spanLatitude * Double(cotes))))
            let j = min(cotes - 1, max(0, Int((c.longitude - ouest) / zone.spanLongitude * Double(cotes))))
            cases[i * cotes + j, default: []].append(e)
        }
        var resultat: [ElementCarteUS] = []
        for cle in cases.keys.sorted() {
            guard let membres = cases[cle], let premier = membres.first else { continue }
            if membres.count == 1 {
                resultat.append(premier)
            } else {
                let n = Double(membres.count)
                var lat = 0.0, lon = 0.0
                for m in membres { lat += m.coordonnee.latitude; lon += m.coordonnee.longitude }
                resultat.append(.groupe(id: String(cle), centre: Coordonnee(latitude: lat / n, longitude: lon / n), nombre: membres.count))
            }
        }
        return resultat
    }
}

/// Ce que la carte sait d'une zone, calculé hors du thread principal.
nonisolated struct ResultatCarteUS: Sendable, Equatable {
    /// L'État de la zone : celui que le pêcheur a choisi, sinon celui du centre de la carte.
    var etat: String?
    /// Vrai si des données de cet État sont chargées.
    var donneesChargees: Bool
    var elements: [ElementCarteUS]
    /// Vrai si la carte est trop dézoomée pour lister des lieux.
    var tropLoin: Bool

    static let vide = ResultatCarteUS(etat: nil, donneesChargees: false, elements: [], tropLoin: false)

    /// "Pas encore de données pour cet État" : aucune donnée chargée pour l'État de la zone.
    var sansDonnees: Bool { !donneesChargees && elements.isEmpty && !tropLoin }
}

nonisolated enum CalculCarteUS {
    static func calculer(source: any SourceCarteUS, zone: ZoneCarte, etatChoisi: String?,
                         maximum: Int = SelectionCarteUS.plafond) -> ResultatCarteUS {
        let etat = etatChoisi ?? source.etat(pour: zone.centre.latitude, longitude: zone.centre.longitude)
        let disponibles = source.etatsDisponibles
        let charge = etat.map { e in disponibles.contains(e) } ?? false
        if zone.spanLatitude > SelectionCarteUS.etendueMaximale {
            return ResultatCarteUS(etat: etat, donneesChargees: charge, elements: [], tropLoin: true)
        }
        // Tous les États chargés, pas seulement celui du centre : près d'une frontière, la rive d'en face reste visible.
        var points: [PointAccesCarteUS] = []
        var plans: [PlanEauCarteUS] = []
        for e in disponibles {
            points += source.points(etat: e).filter { p in zone.contient(p.coordonnee) }
            plans += source.plansEau(etat: e).filter { p in zone.contient(p.coordonnee) }
        }
        let elements = SelectionCarteUS.elements(points: points, plans: plans, dans: zone, maximum: maximum)
        return ResultatCarteUS(etat: etat, donneesChargees: charge || !elements.isEmpty, elements: elements, tropLoin: false)
    }
}
