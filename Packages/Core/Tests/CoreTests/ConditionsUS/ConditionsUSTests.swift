import Foundation
import Testing
@testable import Core

// FIXTURE : toutes les réponses ci-dessous sont écrites à la main d'après la documentation de l'API OGC USGS, de api.weather.gov et de NWPS
// (forme vérifiée à la main sur les vrais endpoints le 7 nov. 2026, valeurs inventées pour les tests).

enum FixtureUS {
    static let stations = Data("""
    {"type":"FeatureCollection","features":[{"type":"Feature","id":"USGS-01646500","properties":{"id":"USGS-01646500","agency_code":"USGS",
    "monitoring_location_name":"POTOMAC RIVER NEAR WASH, DC LITTLE FALLS PUMP STA","state_name":"Maryland","county_name":"Montgomery County",
    "site_type":"Stream","drainage_area":11560.0,"time_zone_abbreviation":"EST"},"geometry":{"type":"Point","coordinates":[-77.1276,38.9497]}}],"numberReturned":1}
    """.utf8)

    static let dernieres = Data("""
    {"type":"FeatureCollection","features":[
    {"type":"Feature","id":"a","properties":{"time_series_id":"s1","monitoring_location_id":"USGS-01646500","parameter_code":"00060","time":"2026-11-07T08:50:00+00:00","value":"2120","unit_of_measure":"ft^3/s","approval_status":"Provisional"},"geometry":null},
    {"type":"Feature","id":"b","properties":{"time_series_id":"s2","monitoring_location_id":"USGS-01646500","parameter_code":"00065","time":"2026-11-07T08:50:00+00:00","value":"2.85","unit_of_measure":"ft","approval_status":"Approved"},"geometry":null},
    {"type":"Feature","id":"c","properties":{"time_series_id":"s3","monitoring_location_id":"USGS-01646500","parameter_code":"00010","time":"2026-11-07T03:50:00-05:00","value":"17.0","unit_of_measure":"degC","approval_status":"Provisional"},"geometry":null},
    {"type":"Feature","id":"d","properties":{"monitoring_location_id":"USGS-01646500","parameter_code":"00095","time":"2026-11-07T08:50:00+00:00","value":"300","unit_of_measure":"uS/cm","approval_status":"Provisional"},"geometry":null},
    {"type":"Feature","id":"e","properties":{"monitoring_location_id":"USGS-01646500","parameter_code":"00060","time":"2026-11-07T08:50:00+00:00","value":null,"unit_of_measure":"ft^3/s","approval_status":"Provisional"},"geometry":null}
    ],"links":[{"rel":"next","href":"https://api.waterdata.usgs.gov/ogcapi/v1/collections/latest-continuous/items?offset=10"}]}
    """.utf8)

    static let alertes = Data("""
    {"type":"FeatureCollection","features":[{"id":"https://api.weather.gov/alerts/urn:1","type":"Feature","geometry":null,"properties":{"id":"urn:1","areaDesc":"Fairfax; Loudoun",
    "sent":"2026-11-07T03:56:00-05:00","effective":"2026-11-07T03:56:00-05:00","onset":"2026-11-07T04:00:00-05:00","expires":"2026-11-07T06:00:00-05:00","ends":null,
    "severity":"Moderate","certainty":"Likely","urgency":"Expected","event":"Flood Warning","senderName":"NWS Sterling VA","headline":"Flood Warning issued",
    "description":"The river will rise.","instruction":"Turn around, don't drown."}}]}
    """.utf8)

    static let gauge = Data("""
    {"lid":"WASD2","usgsId":"","name":"Washington Channel","latitude":38.87,"longitude":-77.02,
    "status":{"observed":{"floodCategory":"no_flooding"},"forecast":{"floodCategory":"minor"}},
    "flood":{"categories":{"major":{"stage":7,"flow":-9999},"moderate":{"stage":6.5,"flow":-9999},"minor":{"stage":5.3,"flow":-9999},"action":{"stage":-999,"flow":-9999}}}}
    """.utf8)

    static let stageflow = Data("""
    {"observed":{"issuedTime":"2026-11-07T09:24:00Z","data":[{"validTime":"2026-11-07T09:00:00Z","primary":1.7,"secondary":-999}]},
     "forecast":{"issuedTime":"2026-11-07T08:00:00Z","data":[{"validTime":"2026-11-07T12:00:00Z","primary":5.4,"secondary":12.5}]}}
    """.utf8)
}

/// Un transport de test : réponses en file, requêtes enregistrées.
final class TransportFaux: TransportUS, @unchecked Sendable {
    private let verrou = NSLock()
    private var reponses: [Result<(Data, Int, [String: String]), Error>]
    private(set) var requetes: [URLRequest] = []

    init(_ r: [Result<(Data, Int, [String: String]), Error>]) { reponses = r }
    convenience init(_ d: Data, statut: Int = 200) { self.init([.success((d, statut, [:]))]) }

    private func suivante(_ requete: URLRequest) -> Result<(Data, Int, [String: String]), Error> {
        verrou.withLock {
            requetes.append(requete)
            return reponses.count > 1 ? reponses.removeFirst() : reponses[0]
        }
    }

    func envoyer(_ requete: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let r = suivante(requete)
        let (d, code, h) = try r.get()
        return (d, HTTPURLResponse(url: requete.url!, statusCode: code, httpVersion: nil, headerFields: h)!)
    }
}

final class HorlogeFausse: @unchecked Sendable {
    var maintenant = Date(timeIntervalSince1970: 1_800_000_000)
}

@Suite("Conditions US : décodage")
struct DecodageUSTests {
    @Test("Station USGS : nom, lieu, bassin")
    func stations() {
        let s = DecodageUS.stationsUSGS(FixtureUS.stations)
        #expect(s.count == 1)
        #expect(s[0].id == "USGS-01646500")
        #expect(s[0].etat == "Maryland")
        #expect(s[0].latitude == 38.9497)
        #expect(s[0].bassinMilesCarres == 11560)
        #expect(s[0].attribution == AttributionUS.usgs)
    }

    @Test("Mesures USGS : valeurs texte lues, paramètre inconnu et valeur nulle écartés, unités brutes")
    func mesures() {
        let m = DecodageUS.mesuresUSGS(FixtureUS.dernieres)
        #expect(m.count == 3)
        #expect(m[0].parametre == .debit && m[0].valeur == 2120 && m[0].unite == .piedCubeParSeconde)
        #expect(m[1].parametre == .hauteur && m[1].unite == .pied && m[1].statut == .approuvee)
        #expect(m[2].parametre == .temperatureEau && m[2].unite == .degreCelsius && m[2].valeur == 17.0)
        // 03:50 à -05:00 = 08:50 UTC : le décalage est respecté.
        #expect(m[2].heure == m[0].heure)
    }

    @Test("Donnée provisoire : avertissement officiel présent ; donnée approuvée : aucun")
    func provisoire() {
        let m = DecodageUS.mesuresUSGS(FixtureUS.dernieres)
        #expect(m[0].estProvisoire && m[0].avertissement == AttributionUS.avertissementProvisoireUSGS)
        #expect(m[1].avertissement == nil)
        #expect(m.allSatisfy { $0.attribution == AttributionUS.usgs })
    }

    @Test("Pagination : lien next")
    func pagination() {
        #expect(DecodageUS.pageSuivante(FixtureUS.dernieres)?.absoluteString.hasSuffix("offset=10") == true)
        #expect(DecodageUS.pageSuivante(FixtureUS.stations) == nil)
    }

    @Test("Alertes NWS")
    func alertes() {
        let a = DecodageUS.alertesNWS(FixtureUS.alertes)
        #expect(a.count == 1)
        #expect(a[0].evenement == "Flood Warning" && a[0].gravite == "Moderate")
        #expect(a[0].emetteur == "NWS Sterling VA")
        #expect(a[0].expire != nil && a[0].fin == nil)
        #expect(a[0].attribution == AttributionUS.nws)
    }

    @Test("NWPS : catégories, seuils (-999 = absent), courbes")
    func nwps() {
        let p = DecodageUS.previsionCrueNWPS(gauge: FixtureUS.gauge, stageflow: FixtureUS.stageflow)
        #expect(p?.identifiant == "WASD2")
        #expect(p?.usgsId == nil)
        #expect(p?.categorieObservee == .pasDeCrue && p?.categoriePrevue == .mineure)
        #expect(p?.seuils.actionPieds == nil && p?.seuils.mineurePieds == 5.3 && p?.seuils.majeurePieds == 7)
        #expect(p?.observee.first?.debitKcfs == nil && p?.observee.first?.hauteurPieds == 1.7)
        #expect(p?.prevue.first?.debitKcfs == 12.5)
        #expect(DecodageUS.previsionCrueNWPS(gauge: FixtureUS.gauge, stageflow: nil)?.prevue.isEmpty == true)
    }

    @Test("JSON invalide : listes vides, pas de plantage")
    func invalide() {
        let junk = Data("pas du json".utf8)
        #expect(DecodageUS.mesuresUSGS(junk).isEmpty)
        #expect(DecodageUS.alertesNWS(junk).isEmpty)
        #expect(DecodageUS.previsionCrueNWPS(gauge: junk, stageflow: nil) == nil)
    }

    @Test("Cellule arrondie : coin sud-ouest et bbox, la position exacte disparaît")
    func cellule() {
        let c = CelluleUS(latitude: 38.94977, longitude: -77.12763)
        #expect(c.bbox == "-77.2,38.9,-77.1,39.0")
        #expect(CelluleUS(latitude: 38.94977, longitude: -77.12763) == CelluleUS(latitude: 38.9111, longitude: -77.1999))
    }
}

@Suite("Conditions US : clients")
struct ClientsUSTests {
    @Test("USGS : URL, clé en en-tête (jamais dans l'URL), User-Agent")
    func usgsRequete() async throws {
        let t = TransportFaux(FixtureUS.dernieres)
        let c = ClientUSGS(transport: t, cleAPI: "CLE-DE-TEST", userAgent: "FishMeTest/1")
        let m = try await c.dernieresMesures(stationId: "USGS-01646500", parametres: [.debit, .hauteur])
        #expect(m.count == 3)
        let r = t.requetes[0]
        let u = r.url!.absoluteString
        #expect(u.hasPrefix("https://api.waterdata.usgs.gov/ogcapi/v1/collections/latest-continuous/items?"))
        #expect(u.contains("monitoring_location_id=USGS-01646500"))
        #expect(u.contains("parameter_code=00060,00065") || u.contains("parameter_code=00060%2C00065"))
        #expect(!u.contains("CLE-DE-TEST") && !u.lowercased().contains("api_key"))
        #expect(r.value(forHTTPHeaderField: "X-Api-Key") == "CLE-DE-TEST")
        #expect(r.value(forHTTPHeaderField: "User-Agent") == "FishMeTest/1")
    }

    @Test("Identifiant de station invalide : refusé avant tout appel réseau")
    func identifiantInvalide() async {
        let t = TransportFaux(FixtureUS.dernieres)
        let c = ClientUSGS(transport: t)
        await #expect(throws: ErreurUS.identifiantInvalide) { try await c.dernieresMesures(stationId: "../../x?api_key=1") }
        await #expect(throws: ErreurUS.identifiantInvalide) { try await c.serie(stationId: "USGS-01646500", parametre: .debit, duree: "P2D&x=1") }
        #expect(t.requetes.isEmpty)
    }

    @Test("Stations d'une cellule : seule la bbox arrondie part")
    func stationsCellule() async throws {
        let t = TransportFaux(FixtureUS.stations)
        let c = ClientUSGS(transport: t)
        let s = try await c.stations(dans: CelluleUS(latitude: 38.94977, longitude: -77.12763))
        #expect(s.count == 1)
        let u = t.requetes[0].url!.absoluteString
        #expect(u.contains("bbox=-77.2,38.9,-77.1,39.0") || u.contains("bbox=-77.2%2C38.9%2C-77.1%2C39.0"))
        #expect(!u.contains("38.94") && !u.contains("77.12"))
    }

    @Test("Cache : la seconde lecture n'appelle pas le réseau, puis l'expiration rappelle")
    func cache() async throws {
        let h = HorlogeFausse()
        let t = TransportFaux(FixtureUS.dernieres)
        let c = ClientUSGS(transport: t, horloge: { h.maintenant })
        _ = try await c.dernieresMesures(stationId: "USGS-01646500")
        _ = try await c.dernieresMesures(stationId: "USGS-01646500")
        #expect(t.requetes.count == 1)
        h.maintenant.addTimeInterval(ClientUSGS.dureeCache + 1)
        _ = try await c.dernieresMesures(stationId: "USGS-01646500")
        #expect(t.requetes.count == 2)
    }

    @Test("429 sans cache : limiteAtteinte avec Retry-After ; avec cache récent : la dernière réponse est resservie")
    func limite() async throws {
        let h = HorlogeFausse()
        let sans = TransportFaux([.success((Data(), 429, ["Retry-After": "5"]))])
        await #expect(throws: ErreurUS.limiteAtteinte(apres: 5)) {
            try await ClientNWS(transport: sans, horloge: { h.maintenant }).alertesActives(etat: "va")
        }
        let t = TransportFaux([.success((FixtureUS.alertes, 200, [:])), .success((Data(), 429, [:]))])
        let c = ClientNWS(transport: t, horloge: { h.maintenant })
        _ = try await c.alertesActives(etat: "VA")
        h.maintenant.addTimeInterval(ClientNWS.dureeCache + 1)
        let a = try await c.alertesActives(etat: "VA")
        #expect(a.count == 1)
        #expect(t.requetes.count == 2)
    }

    @Test("403 : accesRefuse, sans repli ; erreur réseau sans cache : reseau")
    func refus() async {
        let c403 = ClientNWS(transport: TransportFaux(Data(), statut: 403))
        await #expect(throws: ErreurUS.accesRefuse) { try await c403.alertesActives(etat: "VA") }
        let cNet = ClientNWS(transport: TransportFaux([.failure(URLError(.notConnectedToInternet))]))
        await #expect(throws: ErreurUS.reseau) { try await cNet.alertesActives(etat: "VA") }
        let c500 = ClientNWS(transport: TransportFaux(Data(), statut: 503))
        await #expect(throws: ErreurUS.serveur(503)) { try await c500.alertesActives(etat: "VA") }
    }

    @Test("NWS : User-Agent envoyé, alertes par cellule sur le centre arrondi")
    func nws() async throws {
        let t = TransportFaux(FixtureUS.alertes)
        let c = ClientNWS(transport: t, userAgent: "FishMeTest/1 (test@example.com)")
        _ = try await c.alertesActives(cellule: CelluleUS(latitude: 38.94977, longitude: -77.12763))
        let r = t.requetes[0]
        #expect(r.value(forHTTPHeaderField: "User-Agent") == "FishMeTest/1 (test@example.com)")
        #expect(r.url!.absoluteString.contains("point=38.95,-77.15") || r.url!.absoluteString.contains("point=38.95%2C-77.15"))
        await #expect(throws: ErreurUS.identifiantInvalide) { try await c.alertesActives(etat: "Virginia") }
    }

    @Test("NWPS : deux appels (station, courbes), identifiant validé")
    func nwpsClient() async throws {
        let t = TransportFaux([.success((FixtureUS.gauge, 200, [:])), .success((FixtureUS.stageflow, 200, [:]))])
        let c = ClientNWPS(transport: t)
        let p = try await c.prevision(identifiant: "wasd2")
        #expect(p?.categoriePrevue == .mineure && p?.prevue.count == 1)
        #expect(t.requetes.map { $0.url!.path } == ["/nwps/v1/gauges/WASD2", "/nwps/v1/gauges/WASD2/stageflow"])
        await #expect(throws: ErreurUS.identifiantInvalide) { try await c.prevision(identifiant: "../x") }
    }

    @Test("Proxy FishMe : /station/<id>, aucune clé, aucune position")
    func proxy() async throws {
        let t = TransportFaux(FixtureUS.dernieres)
        let c = ClientProxyFishMe(base: "https://fishme-us.example.workers.dev/", transport: t)
        let m = try await c.mesures(stationId: "USGS-01646500")
        #expect(m.count == 3)
        #expect(t.requetes[0].url!.absoluteString == "https://fishme-us.example.workers.dev/station/USGS-01646500")
        #expect(t.requetes[0].value(forHTTPHeaderField: "X-Api-Key") == nil)
    }
}
