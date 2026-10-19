import Foundation

/// Température d'un cours d'eau par Hub'Eau (API « température des cours d'eau », Naïades), avec le seul code de la station.
/// Jamais `latitude`, `longitude`, `distance` ni `bbox`. Sans réseau ou sans mesure récente : `nil`, jamais un plantage.
/// ⚠ à vérifier : la forme des réponses est celle du schéma lu en ligne, pas encore vue en vrai (le proxy du cloud bloque Hub'Eau).
public struct HubEauTemperatureService: TemperatureEauService {
    public typealias Transport = HubEauNiveauService.Transport

    public static let base = "https://hubeau.eaufrance.fr/api/v1/temperature"
    /// Les seules clés de requête permises (le test de vie privée les compare).
    static let clesPermises: Set<String> = ["code_station", "size", "sort", "date_debut_mesure", "fields"]
    /// ⚠ à vérifier : la taille maximale d'une page de la chronique n'est pas lue.
    static let taillePage = "3000"
    /// Une température hors de cette plage est une panne de sonde, pas une mesure (⚠ à confirmer).
    static let plage: ClosedRange<Double> = -5...45

    let transport: Transport
    let horloge: @Sendable () -> Date

    public init(transport: @escaping Transport = HubEauNiveauService.transportReseau, horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.transport = transport
        self.horloge = horloge
    }

    public func temperature(station: StationTemperature) async -> TemperatureEau? {
        let maintenant = horloge()
        let debut = maintenant.addingTimeInterval(-MoteurMesures.ageMax)
        guard let u = Self.requete(code: station.code, depuis: debut),
              let donnees = try? await transport(u) else { return nil }
        return Self.lire(donnees, station: station, maintenant: maintenant)
    }

    static func requete(code: String, depuis: Date) -> URL? {
        var c = URLComponents(string: base + "/chronique")
        let parametres: [String: String] = [
            "code_station": code, "size": taillePage, "sort": "desc", "date_debut_mesure": jourISO(depuis),
            "fields": "code_station,date_mesure_temp,heure_mesure_temp,resultat,symbole_unite",
        ]
        c?.queryItems = parametres.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c?.url
    }

    static func jourISO(_ d: Date) -> String {
        let c = Calendar.utcGregorien.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Les points valides, du plus récent au plus ancien. Un point sans `resultat`, sans date ou avec une autre unité que « °C » est écarté.
    /// ⚠ à vérifier : la date et l'heure de la chronique sont lues comme UTC ; Hub'Eau ne le dit pas dans ce qui a été lu.
    static func points(_ donnees: Data) -> [MesureTemperature] {
        guard let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any], let data = racine["data"] as? [[String: Any]] else { return [] }
        let lus = data.compactMap { o -> MesureTemperature? in
            guard (o["symbole_unite"] as? String) == "°C",
                  let v = (o["resultat"] as? NSNumber)?.doubleValue, v.isFinite, plage.contains(v),
                  let jour = dateAAAAMMJJ(o["date_mesure_temp"] as? String), let h = secondesDepuisMinuit(o["heure_mesure_temp"] as? String) else { return nil }
            return MesureTemperature(heure: jour.addingTimeInterval(h), celsius: v)
        }
        return lus.sorted { $0.heure > $1.heure }
    }

    /// « 14:20:00 » ou « 14:20 » en secondes depuis minuit.
    static func secondesDepuisMinuit(_ texte: String?) -> TimeInterval? {
        guard let texte else { return nil }
        let p = texte.split(separator: ":")
        guard p.count >= 2, let h = Int(p[0]), let m = Int(p[1]), (0..<24).contains(h), (0..<60).contains(m) else { return nil }
        let s = p.count > 2 ? (Int(p[2].prefix(2)) ?? 0) : 0
        return TimeInterval(h * 3600 + m * 60 + s)
    }

    static func lire(_ donnees: Data, station: StationTemperature, maintenant: Date) -> TemperatureEau? {
        let tous = points(donnees)
        guard let dernier = tous.first, MoteurMesures.fraicheur(heure: dernier.heure, date: maintenant) != nil else { return nil }
        // Au plus un point par heure (le plus récent), sur les 48 h avant la dernière mesure.
        let limite = dernier.heure.addingTimeInterval(-48 * 3600)
        var heuresVues: Set<Int> = []
        var serie: [MesureTemperature] = []
        for p in tous where p.heure >= limite {
            let seau = Int((p.heure.timeIntervalSince1970 / 3600).rounded(.down))
            if heuresVues.insert(seau).inserted { serie.append(p) }
        }
        serie.sort { $0.heure < $1.heure }
        return TemperatureEau(station: station, celsius: dernier.celsius, heureMesure: dernier.heure, serie48h: serie)
    }
}
