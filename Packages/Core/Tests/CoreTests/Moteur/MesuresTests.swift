import Foundation
import Testing
@testable import Core

// N3 : pression, eau, débit. Écrits sans compilateur Swift : non exécutés. Les fixtures de température sont écrites d'après le schéma
// de Hub'Eau lu en ligne, pas d'après une réponse vue en vrai (forme non vue en vrai).

private let stationDebit = StationHydro(code: "F664000104", nom: "La Marne à Gournay-sur-Marne - Pont", eau: "La Marne",
                                        coordonnee: Coordonnee(latitude: 48.835, longitude: 2.43))

private func stationT(distance: Double? = nil) -> StationTemperature {
    StationTemperature(code: "F000TEMP", nom: "La Marne (station d'essai)", eau: "La Marne", codeEau: "F6--0020",
                       coordonnee: Coordonnee(latitude: 48.83, longitude: 2.42), distanceM: distance)
}

private func conditions(pression: Double? = 1010, tendance: Double? = -3, heurePression: Date? = nil) -> Conditions {
    Conditions(heure: quinzeOctobre, pressionHPa: pression, tendancePressionHPa6h: tendance, heurePression: heurePression)
}

private func niveau(debit: Double?, serie: [(Double, Double)], heure: Date = quinzeOctobre) -> NiveauEau {
    // `serie` : (heures avant `heure`, débit).
    NiveauEau(station: stationDebit, hauteurM: 1.2, debitM3s: debit,
              serie48h: serie.map { MesureNiveau(heure: heure.addingTimeInterval(-$0.0 * 3600), debitM3s: $0.1) }
                  + (debit.map { [MesureNiveau(heure: heure, debitM3s: $0)] } ?? []),
              heureMesure: heure)
}

private func temperature(celsius: Double, avant: [(Double, Double)], heure: Date = quinzeOctobre, distance: Double? = nil) -> TemperatureEau {
    TemperatureEau(station: stationT(distance: distance), celsius: celsius, heureMesure: heure,
                   serie48h: avant.map { MesureTemperature(heure: heure.addingTimeInterval(-$0.0 * 3600), celsius: $0.1) }
                       + [MesureTemperature(heure: heure, celsius: celsius)])
}

private let moteur = MoteurMesures()

private func uneMesure(_ g: Grandeur, _ liste: [MesureSourcee]) -> MesureSourcee? { liste.first { $0.grandeur == g } }

@Suite("Mesures : pression")
struct MesuresPressionTests {
    @Test("Pression −3 hPa en 6 h : baisse, source Apple Weather, 6 h")
    func baisse() throws {
        let m = try #require(uneMesure(.pression, moteur.mesures(conditions: conditions(tendance: -3), eau: nil, temperature: nil, date: quinzeOctobre)))
        #expect(m.valeur == 1010 && m.unite == "hPa" && m.source == "Apple Weather")
        #expect(m.tendance == Tendance(sens: .baisse, ecart: -3, surHeures: 6))
        #expect(m.prevue == false)
    }

    @Test("Seuils de la pression : +1,9 stable, +2 hausse, −1,9 stable, −2 baisse")
    func seuils() {
        func sens(_ t: Double) -> SensTendance? {
            uneMesure(.pression, moteur.mesures(conditions: conditions(tendance: t), eau: nil, temperature: nil, date: quinzeOctobre))?.tendance?.sens
        }
        #expect(sens(1.9) == .stable)
        #expect(sens(2) == .hausse)
        #expect(sens(-1.9) == .stable)
        #expect(sens(-2) == .baisse)
        #expect(sens(0) == .stable)
    }

    @Test("Mesure d'avant absente : pas de tendance, jamais « stable » par défaut")
    func sansTendance() throws {
        let m = try #require(uneMesure(.pression, moteur.mesures(conditions: conditions(tendance: nil), eau: nil, temperature: nil, date: quinzeOctobre)))
        #expect(m.tendance == nil)
    }

    @Test("Sans pression : aucune ligne")
    func sansPression() {
        #expect(moteur.mesures(conditions: conditions(pression: nil, tendance: nil), eau: nil, temperature: nil, date: quinzeOctobre).isEmpty)
    }

    @Test("« Prévu » à plus de 90 min de la date : vrai à 91 min, faux à 89 et à 90 min, faux sans heure de point")
    func prevue() throws {
        func prevue(_ minutes: Double?) throws -> Bool {
            let h = minutes.map { quinzeOctobre.addingTimeInterval($0 * 60) }
            return try #require(uneMesure(.pression, moteur.mesures(conditions: conditions(heurePression: h), eau: nil, temperature: nil, date: quinzeOctobre))).prevue
        }
        #expect(try prevue(91) == true)
        #expect(try prevue(-91) == true)
        #expect(try prevue(89) == false)
        #expect(try prevue(90) == false)
        #expect(try prevue(nil) == false)
    }

    @Test("lireConditions donne l'heure du point d'où vient la pression")
    func heureDuPoint() {
        let p = PointMeteo(heure: quinzeOctobre.addingTimeInterval(-20 * 60), ventKmh: 5, pluieMm: 0, pressionHPa: 1008, temperatureC: 12, codeTemps: 1)
        let c = moteurEssai().conditions.lireConditions(meteo: MeteoBrute(heures: [p]), eau: nil, date: quinzeOctobre)
        #expect(c.heurePression == p.heure)
        let vide = moteurEssai().conditions.lireConditions(meteo: MeteoBrute(heures: []), eau: nil, date: quinzeOctobre)
        #expect(vide.heurePression == nil)
    }

    @Test("Un ancien cache de Conditions, sans heurePression, se relit")
    func ancienCache() throws {
        let json = Data("{\"heure\":0,\"etatRiviere\":\"inconnu\",\"septJours\":[],\"sources\":[]}".utf8)
        let c = try JSONDecoder().decode(Conditions.self, from: json)
        #expect(c.heurePression == nil)
    }
}

@Suite("Mesures : débit")
struct MesuresDebitTests {
    private func tendance(_ actuel: Double, avant: Double, heuresAvant: Double = 6) -> Tendance? {
        let n = niveau(debit: actuel, serie: [(heuresAvant, avant)])
        return uneMesure(.debit, moteur.mesures(conditions: conditions(), eau: n, temperature: nil, date: quinzeOctobre))?.tendance
    }

    @Test("+5 % pile : hausse ; +4,9 % : stable ; −5 % : baisse ; −4,9 % : stable")
    func seuils() {
        #expect(tendance(105, avant: 100)?.sens == .hausse)
        #expect(tendance(104.9, avant: 100)?.sens == .stable)
        #expect(tendance(95, avant: 100)?.sens == .baisse)
        #expect(tendance(95.1, avant: 100)?.sens == .stable)
    }

    @Test("Écart en m³/s et fenêtre de 6 h")
    func ecart() {
        let t = tendance(20, avant: 18)
        #expect(t?.ecart == 2)
        #expect(t?.surHeures == 6)
        #expect(t?.sens == .hausse)
    }

    @Test("Série trouée : la mesure la plus proche de H−6 h est à plus de 2 h, donc aucune tendance")
    func serieTrouee() {
        #expect(tendance(30, avant: 20, heuresAvant: 3.5) == nil)
        #expect(tendance(30, avant: 20, heuresAvant: 8.5) == nil)
        #expect(tendance(30, avant: 20, heuresAvant: 7.9)?.sens == .hausse)
    }

    @Test("Une mesure d'avant à zéro : pas de pourcentage, donc pas de tendance")
    func avantZero() {
        #expect(tendance(5, avant: 0) == nil)
    }

    @Test("Source Hub'Eau avec le nom de la station, unité m³/s, heure du dernier point de débit")
    func source() throws {
        let n = niveau(debit: 18, serie: [(6, 18)])
        let m = try #require(uneMesure(.debit, moteur.mesures(conditions: conditions(), eau: n, temperature: nil, date: quinzeOctobre)))
        #expect(m.source == "Hub'Eau, station La Marne à Gournay-sur-Marne - Pont")
        #expect(m.unite == "m³/s" && m.valeur == 18)
        #expect(m.heure == quinzeOctobre)
    }

    @Test("Sans débit : aucune ligne « Débit »")
    func sansDebit() {
        let n = NiveauEau(station: stationDebit, hauteurM: 1.2, debitM3s: nil, heureMesure: quinzeOctobre)
        #expect(uneMesure(.debit, moteur.mesures(conditions: conditions(), eau: n, temperature: nil, date: quinzeOctobre)) == nil)
        #expect(uneMesure(.debit, moteur.mesures(conditions: conditions(), eau: nil, temperature: nil, date: quinzeOctobre)) == nil)
    }
}

@Suite("Mesures : température de l'eau et fraîcheur")
struct MesuresTemperatureTests {
    private func lire(_ t: TemperatureEau, date: Date = quinzeOctobre) -> MesureSourcee? {
        uneMesure(.temperatureEau, moteur.mesures(conditions: conditions(), eau: nil, temperature: t, date: date))
    }

    @Test("Sur 24 h : +0,5 °C hausse, +0,4 stable, −0,5 baisse")
    func seuils() {
        #expect(lire(temperature(celsius: 14.2, avant: [(24, 13.7)]))?.tendance?.sens == .hausse)
        #expect(lire(temperature(celsius: 14.2, avant: [(24, 13.8)]))?.tendance?.sens == .stable)
        #expect(lire(temperature(celsius: 13.2, avant: [(24, 13.7)]))?.tendance?.sens == .baisse)
        let t = lire(temperature(celsius: 14.2, avant: [(24, 13.5)]))?.tendance
        #expect(t?.ecart == 0.7 && t?.surHeures == 24)
    }

    @Test("Mesure d'avant à plus de 2 h de H−24 h : pas de tendance")
    func trou() {
        #expect(lire(temperature(celsius: 14.2, avant: [(20, 13.0)]))?.tendance == nil)
        #expect(lire(temperature(celsius: 14.2, avant: []))?.tendance == nil)
    }

    @Test("La source nomme la station et sa distance")
    func source() {
        #expect(lire(temperature(celsius: 14.2, avant: [], distance: 3_600))?.source == "Hub'Eau, station La Marne (station d'essai), 4 km")
        #expect(lire(temperature(celsius: 14.2, avant: [], distance: 120))?.source == "Hub'Eau, station La Marne (station d'essai), 1 km")
        #expect(lire(temperature(celsius: 14.2, avant: []))?.source == "Hub'Eau, station La Marne (station d'essai)")
        #expect(lire(temperature(celsius: 14.2, avant: []))?.unite == "°C")
    }

    @Test("Fraîcheur : 48 h pile récente, 48 h et 1 s ancienne, 30 jours pile ancienne, au-delà plus de ligne")
    func fraicheur() {
        let h = quinzeOctobre
        #expect(MoteurMesures.fraicheur(heure: h.addingTimeInterval(-48 * 3600), date: h) == .recente)
        #expect(MoteurMesures.fraicheur(heure: h.addingTimeInterval(-48 * 3600 - 1), date: h) == .ancienne)
        #expect(MoteurMesures.fraicheur(heure: h.addingTimeInterval(-30 * 86_400), date: h) == .ancienne)
        #expect(MoteurMesures.fraicheur(heure: h.addingTimeInterval(-30 * 86_400 - 1), date: h) == nil)
        let ancienne = temperature(celsius: 11, avant: [], heure: h.addingTimeInterval(-5 * 86_400))
        #expect(lire(ancienne)?.fraicheur == .ancienne)
        #expect(lire(temperature(celsius: 11, avant: [], heure: h.addingTimeInterval(-31 * 86_400))) == nil)
    }

    @Test("Ordre des lignes : pression, eau, débit ; une mesure absente n'a pas de ligne")
    func ordre() {
        let liste = moteur.mesures(conditions: conditions(), eau: niveau(debit: 18, serie: []),
                                   temperature: temperature(celsius: 14, avant: []), date: quinzeOctobre)
        #expect(liste.map(\.grandeur) == [.pression, .temperatureEau, .debit])
        let seule = moteur.mesures(conditions: conditions(pression: nil, tendance: nil), eau: nil, temperature: nil, date: quinzeOctobre)
        #expect(seule.isEmpty)
    }

    @Test("Une MesureSourcee se code et se relit à l'identique (cache)")
    func codable() throws {
        let m = MesureSourcee(grandeur: .temperatureEau, valeur: 14.2, unite: "°C", heure: quinzeOctobre, source: "Hub'Eau, station X",
                              tendance: Tendance(sens: .hausse, ecart: 0.7, surHeures: 24), prevue: false, fraicheur: .ancienne)
        let relu = try JSONDecoder().decode(MesureSourcee.self, from: JSONEncoder().encode(m))
        #expect(relu == m)
    }
}

@Suite("Mesures : station de température")
struct StationTemperatureTests {
    /// Décale un point vers le nord d'une distance en mètres (1° de latitude = 111 195 m environ).
    private func auNord(_ c: Coordonnee, _ metres: Double) -> Coordonnee {
        Coordonnee(latitude: c.latitude + metres / 111_194.93, longitude: c.longitude)
    }

    private func fichier(_ stations: [[String: Any]]) -> Data { try! JSONSerialization.data(withJSONObject: stations) }

    private func station(_ code: String, _ c: Coordonnee, eau: String? = "La Marne", codeEau: String? = nil, enService: Bool = true) -> [String: Any] {
        var s: [String: Any] = ["code": code, "nom": "Station \(code)", "lat": c.latitude, "lon": c.longitude, "en_service": enService]
        if let eau { s["eau"] = eau }
        if let codeEau { s["code_eau"] = codeEau }
        return s
    }

    @Test("À 9,9 km oui, à 10,1 km non")
    func rayon() {
        let a = avec(station("PROCHE", auNord(charenton, 9_900)))
        #expect(a.stationTemperature(pres: charenton, eau: nil)?.code == "PROCHE")
        let b = avec(station("LOIN", auNord(charenton, 10_100)))
        #expect(b.stationTemperature(pres: charenton, eau: nil) == nil)
    }

    @Test("La plus proche gagne, et sa distance est rendue en mètres")
    func laPlusProche() throws {
        let m = avec(station("A", auNord(charenton, 6_000)), station("B", auNord(charenton, 2_000)), station("C", auNord(charenton, 8_000)))
        let s = try #require(m.stationTemperature(pres: charenton, eau: nil))
        #expect(s.code == "B")
        #expect(abs((s.distanceM ?? 0) - 2_000) < 5)
    }

    @Test("Même eau seulement (par le nom du cours d'eau de la station de débit)")
    func memeEauParLeNom() {
        let m = avec(station("SEINE", auNord(charenton, 1_000), eau: "La Seine"), station("MARNE", auNord(charenton, 5_000), eau: "La Marne"))
        #expect(m.stationTemperature(pres: charenton, eau: stationDebit)?.code == "MARNE")
        let seineSeule = avec(station("SEINE", auNord(charenton, 1_000), eau: "La Seine"))
        #expect(seineSeule.stationTemperature(pres: charenton, eau: stationDebit) == nil)
    }

    @Test("Même eau seulement (par le code Sandre du lieu du spot)")
    func memeEauParLeCode() throws {
        let donnees = DonneesMoteur(departements: departementsEssai, lacs: lacsEssai, especes: especesEssai, stationsEspeces: stationsOFBEssai,
                                    regles: chargeurEssai())
        let conditionsCore = MoteurCore(donnees: donnees, horloge: { quinzeOctobre }).conditions
        let m = conditionsCore.mesures(stationsTemperature: fichier([
            station("SEINE", auNord(charenton, 1_000), eau: "La Seine", codeEau: "----0010"),
            station("MARNE", auNord(charenton, 5_000), eau: "La Marne", codeEau: "F6--0020"),
        ]))
        #expect(try #require(m.stationTemperature(pres: charenton, eau: nil)).code == "MARNE")
    }

    @Test("Une station hors service est ignorée ; sans fichier, aucune station")
    func horsService() {
        #expect(avec(station("HS", auNord(charenton, 500), enService: false)).stationTemperature(pres: charenton, eau: nil) == nil)
        #expect(MoteurMesures().stationTemperature(pres: charenton, eau: nil) == nil)
        #expect(MoteurMesures(stationsTemperature: Data("pas du json".utf8)).stationTemperature(pres: charenton, eau: nil) == nil)
    }

    @Test("Le fichier peut être un objet avec la clé stations")
    func objetStations() throws {
        let o = try JSONSerialization.data(withJSONObject: ["stations": [station("OBJ", auNord(charenton, 1_000))]])
        #expect(MoteurMesures(stationsTemperature: o).stationTemperature(pres: charenton, eau: nil)?.code == "OBJ")
    }

    @Test("Un vrai extrait de stations-temperature.json (fabriqué par D2, 20 oct. 2026) se décode champ par champ")
    func extraitReelD2() throws {
        let donnees = HubEauTemperatureTests.fixture("stations-temperature-extrait.json")
        let liste = StationTemperatureDonnee.decoder(donnees)
        #expect(liste.count == 8)
        let marne = try #require(liste.first { $0.station.code == "03112480" })
        #expect(marne.station.nom == "LA MARNE A CHARENTON-LE-PONT 2")
        #expect(marne.station.eau == "La Marne")
        #expect(marne.station.codeEau == "F---0100")
        #expect(marne.station.coordonnee == Coordonnee(latitude: 48.816895, longitude: 2.41963))
        #expect(marne.enService == false)
        let loir = try #require(liste.first { $0.station.code == "04108000" })
        #expect(loir.enService == true)
        #expect(loir.station.nom.hasPrefix("LOIR "))
        #expect(loir.station.nom.hasSuffix(" NAVEIL"))
        // Cours d'eau inconnu : null dans le fichier, nil côté app (et le nom reste le libellé de la station).
        let sansEau = try #require(liste.first { $0.station.code == "02001047" })
        #expect(sansEau.station.eau == nil && sansEau.station.codeEau == nil)
        #expect(sansEau.station.nom == "LE SCHAFTEU A RHINAU")
        // L'apostrophe et les accents passent.
        let hogneau = try #require(liste.first { $0.station.code == "01001336" })
        #expect(hogneau.station.nom.hasPrefix("L'HOGNEAU "))
        #expect(hogneau.station.nom.hasSuffix(" GUSSIGNIES (59)"))
        #expect(liste.filter(\.enService).count == 4)
    }

    @Test("Avec l'extrait réel, le choix de la station ignore la Marne hors service et prend le Loir en service")
    func choixSurExtraitReel() {
        let m = MoteurMesures(stationsTemperature: HubEauTemperatureTests.fixture("stations-temperature-extrait.json"))
        #expect(m.stationTemperature(pres: charenton, eau: nil) == nil)
        #expect(m.stationTemperature(pres: Coordonnee(latitude: 47.80, longitude: 1.03), eau: nil)?.code == "04108000")
    }

    private func avec(_ stations: [String: Any]...) -> MoteurMesures {
        MoteurMesures(stationsTemperature: fichier(stations))
    }
}

/// Une boîte qui note les URL demandées (le transport est `@Sendable`).
final class UrlsTemperature: @unchecked Sendable {
    private let verrou = NSLock()
    private var liste: [URL] = []
    func ajouter(_ u: URL) { verrou.lock(); liste.append(u); verrou.unlock() }
    var urls: [URL] { verrou.lock(); defer { verrou.unlock() }; return liste }
}

@Suite("Hub'Eau température : fixtures, requête, échecs")
struct HubEauTemperatureTests {
    let horloge = utc(2026, 10, 15, 14, 49)
    let station = stationT(distance: 3_600)

    static func fixture(_ nom: String) -> Data {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        return try! Data(contentsOf: dossier.appendingPathComponent(nom))
    }

    func service(_ nom: String, horloge h: Date? = nil, urls: UrlsTemperature = UrlsTemperature()) -> HubEauTemperatureService {
        let reponse = Self.fixture(nom)
        let date = h ?? horloge
        return HubEauTemperatureService(transport: { url in urls.ajouter(url); return reponse }, horloge: { date })
    }

    @Test("Réponse complète : dernière valeur, heure, série d'un point par heure sur 48 h")
    func complete() async throws {
        let t = try #require(await service("hubeau-temperature-marne.json").temperature(station: station))
        #expect(t.celsius == 14.2)
        #expect(t.heureMesure == utc(2026, 10, 15, 14, 20))
        #expect(t.station == station)
        #expect(t.serie48h.count == 49)
        #expect(zip(t.serie48h, t.serie48h.dropFirst()).allSatisfy { $0.heure < $1.heure })
        #expect(t.serie48h.last?.heure == t.heureMesure)
        #expect(t.serie48h.first!.heure >= t.heureMesure.addingTimeInterval(-48 * 3600))
    }

    @Test("La température de la réponse enregistrée monte de 0,7 °C en 24 h : hausse")
    func tendanceDepuisLaReponse() async throws {
        let t = try #require(await service("hubeau-temperature-marne.json").temperature(station: station))
        let m = try #require(uneMesure(.temperatureEau, moteur.mesures(conditions: conditions(), eau: nil, temperature: t, date: horloge)))
        #expect(m.tendance?.sens == .hausse)
        #expect(m.tendance?.ecart == 0.7)
    }

    @Test("Réponse avec data vide : nil")
    func vide() async {
        #expect(await service("hubeau-temperature-vide.json").temperature(station: station) == nil)
    }

    @Test("Réponse où resultat est null partout : nil")
    func resultatNull() async {
        #expect(await service("hubeau-temperature-resultat-null.json").temperature(station: station) == nil)
    }

    @Test("Un resultat null en tête est écarté, la valeur valide suivante est prise")
    func nullEnTete() async throws {
        let json = """
        {"data":[{"date_mesure_temp":"2026-10-15","heure_mesure_temp":"14:20:00","resultat":null,"symbole_unite":"°C"},
                 {"date_mesure_temp":"2026-10-15","heure_mesure_temp":"14:10:00","resultat":13.9,"symbole_unite":"°C"}]}
        """
        let s = HubEauTemperatureService(transport: { _ in Data(json.utf8) }, horloge: { [horloge] in horloge })
        let t = try #require(await s.temperature(station: station))
        #expect(t.celsius == 13.9)
        #expect(t.heureMesure == utc(2026, 10, 15, 14, 10))
    }

    @Test("Unité inattendue : nil, jamais une valeur lue comme des degrés Celsius")
    func uniteInattendue() async {
        #expect(await service("hubeau-temperature-unite-inattendue.json").temperature(station: station) == nil)
    }

    @Test("Valeur hors plage (sonde en panne) : écartée")
    func horsPlage() async {
        let json = "{\"data\":[{\"date_mesure_temp\":\"2026-10-15\",\"heure_mesure_temp\":\"14:20:00\",\"resultat\":-999,\"symbole_unite\":\"°C\"}]}"
        let s = HubEauTemperatureService(transport: { _ in Data(json.utf8) }, horloge: { [horloge] in horloge })
        #expect(HubEauTemperatureService.points(Data(json.utf8)).isEmpty)
        #expect(await s.temperature(station: station) == nil)
    }

    @Test("Dernière mesure de 14 jours : rendue (ancienne) ; de plus de 30 jours : nil")
    func fraicheur() async throws {
        let ancienne = try #require(await service("hubeau-temperature-ancienne.json").temperature(station: station))
        #expect(MoteurMesures.fraicheur(heure: ancienne.heureMesure, date: horloge) == .ancienne)
        #expect(await service("hubeau-temperature-ancienne.json", horloge: utc(2026, 11, 20)).temperature(station: station) == nil)
    }

    @Test("Sans réseau ou réponse cassée : nil, jamais un plantage")
    func sansReseau() async {
        let hors = HubEauTemperatureService(transport: { _ in throw URLError(.notConnectedToInternet) }, horloge: { [horloge] in horloge })
        #expect(await hors.temperature(station: station) == nil)
        let casse = HubEauTemperatureService(transport: { _ in Data("pas du json".utf8) }, horloge: { [horloge] in horloge })
        #expect(await casse.temperature(station: station) == nil)
    }

    @Test("La requête ne porte que le code de la station : aucune coordonnée, aucune distance")
    func seulementLeCode() async throws {
        let urls = UrlsTemperature()
        _ = await service("hubeau-temperature-marne.json", urls: urls).temperature(station: station)
        #expect(urls.urls.count == 1)
        for u in urls.urls {
            #expect(u.host == "hubeau.eaufrance.fr")
            #expect(u.path == "/api/v1/temperature/chronique")
            let c = try #require(URLComponents(url: u, resolvingAgainstBaseURL: false))
            let cles = Set((c.queryItems ?? []).map(\.name))
            #expect(cles.isSubset(of: HubEauTemperatureService.clesPermises))
            #expect(c.queryItems?.first { $0.name == "code_station" }?.value == "F000TEMP")
            for interdite in ["latitude", "longitude", "distance", "bbox", "lat", "lon"] { #expect(!cles.contains(interdite)) }
            let texte = u.absoluteString
            #expect(!texte.contains("48.8") && !texte.contains("2.42"))
        }
    }

    @Test("La requête demande la fenêtre de 30 jours, du plus récent au plus ancien")
    func fenetre() async {
        let urls = UrlsTemperature()
        _ = await service("hubeau-temperature-vide.json", urls: urls).temperature(station: station)
        let texte = urls.urls.first?.absoluteString ?? ""
        #expect(texte.contains("date_debut_mesure=2026-09-15"))
        #expect(texte.contains("sort=desc"))
    }
}

@Suite("Mesures : contrats et faux")
struct MesuresFauxTests {
    @Test("TemperatureEauFaux rend une mesure ou rien, sans réseau")
    func temperatureFaux() async {
        let s = stationT()
        #expect(await TemperatureEauFaux().temperature(station: s)?.celsius == 14.2)
        #expect(await TemperatureEauFaux(scenario: .sansMesure).temperature(station: s) == nil)
    }

    @Test("ServiceMesuresFaux rend les trois grandeurs et une station")
    func mesuresFaux() {
        let f = ServiceMesuresFaux()
        let liste = f.mesures(conditions: conditions(), eau: nil, temperature: nil, date: quinzeOctobre)
        #expect(liste.map(\.grandeur) == [.pression, .temperatureEau, .debit])
        #expect(f.stationTemperature(pres: charenton, eau: nil)?.code == "F000TEMP")
    }

    @Test("Aucun mot de note ni de promesse dans les sources de N3")
    func mots() throws {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/Core/Conditions")
        let interdits = ["score", "sur 100", "solunaire", "meil" + "leure heure", "meil" + "leur créneau", "bite", "ça va mordre", "indice de pêche"]
        for nom in ["Mesures.swift", "MoteurMesures.swift", "HubEauTemperatureService.swift"] {
            let source = try String(contentsOf: dossier.appendingPathComponent(nom), encoding: .utf8).lowercased()
            for mot in interdits { #expect(!source.contains(mot), "\(nom) contient « \(mot) »") }
        }
    }
}
