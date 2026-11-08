import Foundation

/// Contour très simplifié d'un État (anneaux extérieurs, sommets [longitude, latitude]) et sa boîte englobante.
struct ZoneEtatUS: Sendable {
    let etat: String
    let minLon: Double
    let minLat: Double
    let maxLon: Double
    let maxLat: Double
    let anneaux: [[(lon: Double, lat: Double)]]

    func boite(contient lat: Double, _ lon: Double) -> Bool {
        lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon
    }

    /// Lancer de rayon sur les anneaux ; sans anneau, la boîte seule décide (repli grossier).
    func contient(latitude lat: Double, longitude lon: Double) -> Bool {
        guard boite(contient: lat, lon) else { return false }
        if anneaux.isEmpty { return true }
        for a in anneaux where Self.dans(anneau: a, lat: lat, lon: lon) { return true }
        return false
    }

    private static func dans(anneau: [(lon: Double, lat: Double)], lat: Double, lon: Double) -> Bool {
        var dedans = false
        var j = anneau.count - 1
        for i in 0..<anneau.count {
            let (xi, yi) = (anneau[i].lon, anneau[i].lat)
            let (xj, yj) = (anneau[j].lon, anneau[j].lat)
            if (yi > lat) != (yj > lat), lon < (xj - xi) * (lat - yi) / (yj - yi) + xi { dedans.toggle() }
            j = i
        }
        return dedans
    }
}

/// Lit les fichiers de `geo-us/` (un par État et par couche, JSON compact : voir outils/us/geo/embarquer.py).
/// Un fichier absent ou illisible donne une liste vide, jamais un plantage. Les couches se lisent une fois, à la demande.
final class DonneesGeoUS: @unchecked Sendable {
    /// Les données embarquées dans l'app.
    static let embarque = DonneesGeoUS(dossier: Bundle.module.url(forResource: "geo-us", withExtension: nil))

    let dossier: URL?
    private let verrou = NSLock()
    private var cachePoints: [String: [PointAccesUS]] = [:]
    private var cachePlans: [String: [PlanEauUS]] = [:]
    private var cacheLignes: [String: [LigneEauUS]] = [:]
    private var cacheAvis: [String: [AvisSanteEauUS]] = [:]
    private var cacheZones: [ZoneEtatUS]?
    private var cacheEtats: [String]?
    /// Ordre d'usage des États en cache (le plus ancien d'abord) : au plus `limiteEtats` États restent en mémoire (US15, 8 nov. :
    /// les lignes d'eau d'un gros État pèsent plusieurs dizaines de Mo en mémoire). Le plus ancien est évincé et se relit au besoin.
    private var ordreUsage: [String] = []
    private let limiteEtats: Int

    init(dossier: URL?, limiteEtats: Int = 3) {
        self.dossier = dossier
        self.limiteEtats = max(1, limiteEtats)
    }

    /// États dont au moins une couche est en cache (pour les tests). À appeler hors verrou.
    var etatsEnCache: [String] {
        verrou.lock()
        defer { verrou.unlock() }
        return ordreUsage
    }

    /// Marque l'État comme le plus récemment utilisé et évince le plus ancien au-delà de la limite. Verrou déjà pris.
    private func toucher(_ code: String) {
        ordreUsage.removeAll { $0 == code }
        ordreUsage.append(code)
        while ordreUsage.count > limiteEtats {
            let ancien = ordreUsage.removeFirst()
            cachePoints[ancien] = nil
            cachePlans[ancien] = nil
            cacheLignes[ancien] = nil
            cacheAvis[ancien] = nil
        }
    }

    // MARK: États

    /// Codes USPS des États qui ont un fichier de points, triés.
    var etats: [String] {
        verrou.lock()
        defer { verrou.unlock() }
        if let c = cacheEtats { return c }
        let noms = (try? dossier.map { try FileManager.default.contentsOfDirectory(atPath: $0.path) }) ?? []
        let codes = noms.filter { $0.hasSuffix("-points.json") }.map { String($0.dropLast("-points.json".count)) }.filter { $0.count == 2 }.sorted()
        cacheEtats = codes
        return codes
    }

    var zones: [ZoneEtatUS] {
        verrou.lock()
        defer { verrou.unlock() }
        if let c = cacheZones { return c }
        let z = Self.lireZones(objet(nom: "etats.json"))
        cacheZones = z
        return z
    }

    /// L'État qui contient le point. Contour simplifié quand il est fourni, boîte englobante sinon ; nil hors des États couverts.
    func etat(latitude: Double, longitude: Double) -> String? {
        guard latitude.isFinite, longitude.isFinite else { return nil }
        return zones.first { $0.contient(latitude: latitude, longitude: longitude) }?.etat
    }

    // MARK: Couches

    func points(etat: String) -> [PointAccesUS] {
        let code = etat.uppercased()
        verrou.lock()
        if let c = cachePoints[code] { toucher(code); verrou.unlock(); return c }
        verrou.unlock()
        let lues = Self.lirePoints(objet(nom: "\(code)-points.json"), etat: code)
        verrou.lock()
        cachePoints[code] = lues
        toucher(code)
        verrou.unlock()
        return lues
    }

    func plansEau(etat: String) -> [PlanEauUS] {
        let code = etat.uppercased()
        verrou.lock()
        if let c = cachePlans[code] { toucher(code); verrou.unlock(); return c }
        verrou.unlock()
        let lues = Self.lirePlansEau(objet(nom: "\(code)-plans-eau.json"), etat: code)
        verrou.lock()
        cachePlans[code] = lues
        toucher(code)
        verrou.unlock()
        return lues
    }

    func lignesEau(etat: String) -> [LigneEauUS] {
        let code = etat.uppercased()
        verrou.lock()
        if let c = cacheLignes[code] { toucher(code); verrou.unlock(); return c }
        verrou.unlock()
        let lues = Self.lireLignes(objet(nom: "\(code)-lignes-eau.json"), etat: code)
        verrou.lock()
        cacheLignes[code] = lues
        toucher(code)
        verrou.unlock()
        return lues
    }

    func avis(etat: String) -> [AvisSanteEauUS] {
        let code = etat.uppercased()
        verrou.lock()
        if let c = cacheAvis[code] { toucher(code); verrou.unlock(); return c }
        verrou.unlock()
        let lus = Self.lireAvis(objet(nom: "\(code)-avis.json"))
        verrou.lock()
        cacheAvis[code] = lus
        toucher(code)
        verrou.unlock()
        return lus
    }

    // MARK: Lecture du disque

    private func objet(nom: String) -> [String: Any]? {
        guard let url = dossier?.appendingPathComponent(nom),
              let data = try? Data(contentsOf: url),
              let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return o
    }
}
