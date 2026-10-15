import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Niveau de la rivière par Hub'Eau hydrométrie, avec le seul code de la station. Sans réseau : `nil`, jamais un plantage.
public struct HubEauNiveauService: NiveauEauService {
    /// Une requête GET : l'URL entre, le corps de la réponse sort. Les tests y mettent une réponse enregistrée.
    public typealias Transport = @Sendable (URL) async throws -> Data

    public static let base = "https://hubeau.eaufrance.fr/api/v2/hydrometrie"
    /// Une normale du mois demande au moins ce nombre de mois d'archive.
    static let moisMinimumPourNormale = 3

    let transport: Transport
    let horloge: @Sendable () -> Date

    public init(transport: @escaping Transport = HubEauNiveauService.transportReseau, horloge: @escaping @Sendable () -> Date = { Date() }) {
        self.transport = transport
        self.horloge = horloge
    }

    public static let transportReseau: Transport = { url in
        try await withCheckedThrowingContinuation { suite in
            var requete = URLRequest(url: url)
            requete.timeoutInterval = 15
            URLSession.shared.dataTask(with: requete) { donnees, reponse, erreur in
                if let erreur {
                    suite.resume(throwing: erreur)
                } else if let donnees, let http = reponse as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
                    suite.resume(returning: donnees)
                } else {
                    suite.resume(throwing: URLError(.badServerResponse))
                }
            }.resume()
        }
    }

    // MARK: Contrat

    public func niveau(station: StationHydro) async -> NiveauEau? {
        let maintenant = horloge()
        let debut = maintenant.addingTimeInterval(-48 * 3600)
        async let hauteurs = observations(station: station.code, grandeur: "H", depuis: debut)
        async let debits = observations(station: station.code, grandeur: "Q", depuis: debut)
        let h = await hauteurs, q = await debits
        guard !h.isEmpty || !q.isEmpty else { return nil }

        // Hub'Eau : hauteur en millimètres, débit en litres par seconde.
        var parHeure: [Date: MesureNiveau] = [:]
        for (t, v) in h { parHeure[t, default: MesureNiveau(heure: t)].hauteurM = v / 1000 }
        for (t, v) in q { parHeure[t, default: MesureNiveau(heure: t)].debitM3s = v / 1000 }
        let serie = parHeure.values.sorted { $0.heure < $1.heure }
        let derniereHauteur = serie.last(where: { $0.hauteurM != nil })
        let dernierDebit = serie.last(where: { $0.debitM3s != nil })
        let heureMesure = serie.last?.heure ?? maintenant
        let normale = dernierDebit == nil ? nil : await normaleDuMois(station: station.code, date: maintenant)
        return NiveauEau(station: station, hauteurM: derniereHauteur?.hauteurM, debitM3s: dernierDebit?.debitM3s, serie48h: serie,
                         normaleDebitM3s: normale, vigilance: nil, heureMesure: heureMesure)
    }

    // MARK: Appels

    private func url(_ chemin: String, _ parametres: [String: String]) -> URL? {
        var c = URLComponents(string: Self.base + "/" + chemin)
        c?.queryItems = parametres.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        return c?.url
    }

    private func observations(station: String, grandeur: String, depuis: Date) async -> [(Date, Double)] {
        guard let u = url("observations_tr", ["code_entite": station, "grandeur_hydro": grandeur, "date_debut_obs": Self.texteISO(depuis),
                                              "size": "1000", "sort": "desc", "fields": "date_obs,resultat_obs,grandeur_hydro"]),
              let donnees = try? await transport(u) else { return [] }
        return Self.lireObservations(donnees)
    }

    static func lireObservations(_ donnees: Data) -> [(Date, Double)] {
        guard let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any], let data = racine["data"] as? [[String: Any]] else { return [] }
        return data.compactMap { o in
            guard let t = instantISO(o["date_obs"] as? String), let v = (o["resultat_obs"] as? NSNumber)?.doubleValue else { return nil }
            return (t, v)
        }
    }

    /// Débit moyen du mois en cours sur toute l'archive de la station (débits élaborés), ou `nil` si la station n'en a pas assez.
    private func normaleDuMois(station: String, date: Date) async -> Double? {
        guard let u = url("obs_elab", ["code_entite": station, "grandeur_hydro_elab": "QmM", "size": "400", "fields": "date_obs_elab,resultat_obs_elab"]),
              let donnees = try? await transport(u) else { return nil }
        return Self.normale(donnees, mois: Calendar.utcGregorien.component(.month, from: date))
    }

    static func normale(_ donnees: Data, mois: Int) -> Double? {
        guard let racine = (try? JSONSerialization.jsonObject(with: donnees)) as? [String: Any], let data = racine["data"] as? [[String: Any]] else { return nil }
        let valeurs = data.compactMap { o -> Double? in
            guard let d = dateAAAAMMJJ(o["date_obs_elab"] as? String), Calendar.utcGregorien.component(.month, from: d) == mois,
                  let v = (o["resultat_obs_elab"] as? NSNumber)?.doubleValue else { return nil }
            return v / 1000
        }
        guard valeurs.count >= moisMinimumPourNormale else { return nil }
        return (valeurs.reduce(0, +) / Double(valeurs.count)).arrondi(3)
    }

    static func texteISO(_ d: Date) -> String {
        let c = Calendar.utcGregorien.dateComponents([.year, .month, .day, .hour, .minute, .second], from: d)
        return String(format: "%04d-%02d-%02dT%02d:%02d:%02dZ", c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
