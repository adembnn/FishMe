import Foundation
import Core

/// Les stations de la dernière vue de la carte, gardées dans le dossier Caches de l'iPhone (jamais envoyées nulle part).
/// Au lancement suivant, la carte montre ces points tout de suite, puis les rafraîchit.
/// Coordonnées : celles des stations OFB (déjà arrondies à 0,01° par `Core`) et un centre de vue arrondi pareil.
nonisolated struct CacheCarte: Sendable, Equatable, Codable {
    static let versionCourante = 1

    var version: Int
    var ecritLe: Date
    var region: ZoneCarte
    var stations: [StationCarte]

    /// Au plus `maximum` stations, les plus proches du centre : le fichier reste petit.
    static func pour(region: ZoneCarte, stations: [StationCarte], maintenant: Date = Date(), maximum: Int = 400) -> CacheCarte {
        let arrondie = ZoneCarte(
            centre: Coordonnee(latitude: (region.centre.latitude * 100).rounded() / 100,
                               longitude: (region.centre.longitude * 100).rounded() / 100),
            spanLatitude: region.spanLatitude, spanLongitude: region.spanLongitude)
        return CacheCarte(version: versionCourante, ecritLe: maintenant, region: arrondie,
                          stations: SelectionVisible.stations(stations, dans: arrondie, maximum: maximum))
    }
}

/// Lecture et écriture du cache : des fonctions pures sur un dossier, appelées hors du fil principal.
nonisolated enum StockageCacheCarte {
    static let nomFichier = "carte-derniere-vue.json"
    /// Au-delà, le cache est ignoré (les relevés OFB changent avec les mises à jour de l'app, pas avec les jours).
    static let ageMaximum: TimeInterval = 60 * 24 * 3600
    /// On ne garde que les vues de cette étendue (en degrés de latitude) ou moins : jamais la France entière.
    static let etendueMaximale = 3.0

    static var dossierParDefaut: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    static func ecrire(_ cache: CacheCarte, dans dossier: URL) {
        guard let donnees = try? JSONEncoder().encode(cache) else { return }
        try? FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        try? donnees.write(to: dossier.appendingPathComponent(nomFichier), options: .atomic)
    }

    /// `nil` si le fichier manque, est abîmé, d'une autre version ou trop vieux.
    static func lire(dans dossier: URL, maintenant: Date) -> CacheCarte? {
        guard let donnees = try? Data(contentsOf: dossier.appendingPathComponent(nomFichier)),
              let cache = try? JSONDecoder().decode(CacheCarte.self, from: donnees),
              cache.version == CacheCarte.versionCourante,
              maintenant.timeIntervalSince(cache.ecritLe) <= ageMaximum,
              !cache.stations.isEmpty else { return nil }
        return cache
    }
}

/// Le choix des stations à garder ou à dessiner pour une zone : pur, sans effet de bord.
nonisolated enum SelectionVisible {
    /// Les stations de la zone (marge de 10 %), les plus proches du centre d'abord, au plus `maximum`, rendues triées par code.
    static func stations(_ stations: [StationCarte], dans region: ZoneCarte, maximum: Int) -> [StationCarte] {
        guard maximum > 0 else { return [] }
        let visibles = stations.filter { region.contient($0.coordonnee) }
        if visibles.count <= maximum { return visibles.sorted { $0.code < $1.code } }
        // Types explicites : la chaîne map/sorted/prefix/map sur des tuples dépassait le délai du compilateur.
        let centre: Coordonnee = region.centre
        var avecDistance: [(station: StationCarte, distance: Double)] = []
        avecDistance.reserveCapacity(visibles.count)
        for station in visibles {
            avecDistance.append((station: station, distance: distanceMetres(station.coordonnee, centre)))
        }
        avecDistance.sort { (a: (station: StationCarte, distance: Double), b: (station: StationCarte, distance: Double)) -> Bool in
            if a.distance != b.distance { return a.distance < b.distance }
            return a.station.code < b.station.code
        }
        let proches: [StationCarte] = avecDistance.prefix(maximum).map { (element: (station: StationCarte, distance: Double)) -> StationCarte in
            element.station
        }
        return proches.sorted { $0.code < $1.code }
    }
}
