import XCTest
import Core
@testable import BuildChallenge

// Écrits sans Mac : non exécutés, ni compilés. ⚠ à compiler et lancer par A ou S.
#if DEBUG
/// Un espion de `TemperatureEauService` : note les codes de station reçus, jamais autre chose (le contrat ne reçoit rien d'autre).
private actor EspionTemperature: TemperatureEauService {
    private(set) var codes: [String] = []
    private let rendu: TemperatureEau?

    init(rendu: TemperatureEau?) { self.rendu = rendu }

    func temperature(station: StationTemperature) async -> TemperatureEau? {
        codes.append(station.code)
        return rendu
    }

    var nombreDAppels: Int { codes.count }
}

@MainActor
final class MesuresSourceesTests: XCTestCase {
    private let debut = Date(timeIntervalSince1970: 1_760_000_000)
    private let spot = Coordonnee(latitude: 48.81234, longitude: 2.41567)

    private func mesure(_ g: Grandeur, valeur: Double, unite: String, tendance: Tendance? = nil, prevue: Bool = false,
                        fraicheur: FraicheurMesure = .recente, source: String = "Apple Weather") -> MesureSourcee {
        MesureSourcee(grandeur: g, valeur: valeur, unite: unite, heure: debut, source: source, tendance: tendance, prevue: prevue, fraicheur: fraicheur)
    }

    // MARK: Mise en forme

    func testPressionAvecTendance() {
        let m = mesure(.pression, valeur: 1012, unite: "hPa", tendance: Tendance(sens: .baisse, ecart: -3, surHeures: 6))
        XCTAssertEqual(FormatMesures.valeur(m), "\(FormatConditions.nombre(1012)) hPa")
        XCTAssertEqual(FormatMesures.ecart(m), "−3 hPa en 6 h")
        XCTAssertEqual(FormatMesures.fleche(.baisse), "arrow.down.right")
    }

    func testTemperatureEtDebit() {
        let t = mesure(.temperatureEau, valeur: 14.2, unite: "°C", tendance: Tendance(sens: .hausse, ecart: 0.7, surHeures: 24))
        XCTAssertEqual(FormatMesures.valeur(t), "14,2 °C")
        XCTAssertEqual(FormatMesures.ecart(t), "+0,7 °C en 24 h")
        let q = mesure(.debit, valeur: 18, unite: "m³/s", tendance: Tendance(sens: .stable, ecart: 0, surHeures: 6))
        XCTAssertEqual(FormatMesures.valeur(q), "18 m³/s")
        XCTAssertEqual(FormatMesures.ecart(q), "0 m³/s en 6 h")
        XCTAssertNil(FormatMesures.ecart(mesure(.debit, valeur: 18, unite: "m³/s")))
    }

    /// Critère 4 : chaque mesure porte son nom de source et son heure.
    func testChaqueLigneDitSaSourceEtSonHeure() {
        let mesures = ServiceMesuresFaux().mesures(conditions: ConditionsFaux().lireConditions(meteo: MeteoBrute(heures: []), eau: nil, date: debut),
                                                   eau: nil, temperature: nil, date: debut)
        XCTAssertEqual(mesures.count, 3)
        for m in mesures {
            let legende = FormatMesures.sourceEtHeure(m)
            XCTAssertTrue(legende.contains(m.source))
            XCTAssertTrue(legende.contains(FormatConditions.heure(m.heure)))
            XCTAssertTrue(FormatMesures.accessibilite(m).contains(m.source))
        }
    }

    /// Critère 4 : une valeur de prévision porte le mot « prévu ».
    func testValeurPrevueEcritPrevu() {
        let m = mesure(.pression, valeur: 1008, unite: "hPa", prevue: true)
        XCTAssertTrue(FormatMesures.sourceEtHeure(m).contains("prévu"))
        XCTAssertFalse(FormatMesures.sourceEtHeure(mesure(.pression, valeur: 1008, unite: "hPa")).contains("prévu"))
    }

    func testMesureAncienneDitDerniereMesure() {
        let m = mesure(.temperatureEau, valeur: 11, unite: "°C", fraicheur: .ancienne, source: "Hub'Eau, station X")
        let legende = FormatMesures.sourceEtHeure(m)
        XCTAssertTrue(legende.contains("dernière mesure le"))
        XCTAssertTrue(legende.contains(FormatMesures.jour(m.heure)))
    }

    /// Aucune couleur d'alerte, aucun mot de promesse dans ce que le bloc écrit.
    func testAucunMotInterdit() {
        let interdits = ["score", "sur 100", "solunaire", "meil" + "leur", "bite", "mordre", "garantie", "indice de pêche"]
        let textes = ServiceMesuresFaux().mesures(conditions: Conditions(heure: debut), eau: nil, temperature: nil, date: debut).flatMap {
            [FormatMesures.nom($0.grandeur), FormatMesures.valeur($0), FormatMesures.ecart($0) ?? "", FormatMesures.sourceEtHeure($0), FormatMesures.accessibilite($0)]
        } + [AideMesuresView.phrasePrincipale, AideMesuresView.phrasePression, AideMesuresView.phraseEau]
        for t in textes {
            for mot in interdits { XCTAssertFalse(t.lowercased().contains(mot), "« \(t) » contient « \(mot) »") }
        }
        XCTAssertEqual(AideMesuresView.phrasePrincipale, "Simple mesure : on ne prédit pas la touche.")
    }

    // MARK: Modèle

    /// Hub'Eau ne reçoit que le code de la station ; une lecture par 30 min et par station.
    func testUneLectureParTrenteMinutes() async {
        let station = StationTemperature(code: "F000TEMP", nom: "La Marne (essai)", eau: "La Marne", coordonnee: Coordonnee(latitude: 48.82, longitude: 2.41))
        let t = TemperatureEau(station: station, celsius: 14.2, heureMesure: debut)
        let espion = EspionTemperature(rendu: t)
        let m = ModeleMesures(service: espion, noyau: ServiceMesuresFaux(), maintenant: { Date(timeIntervalSince1970: 1_760_000_000) }, fichier: nil)
        await m.charger(spot: spot, eau: nil)
        await m.charger(spot: spot, eau: nil)
        let codes = await espion.codes
        XCTAssertEqual(codes, ["F000TEMP"])
        XCTAssertEqual(m.temperature(spot: spot, eau: nil)?.celsius, 14.2)
    }

    /// Critère 7 : station sans mesure, aucune ligne « Eau » ; jamais d'estimation.
    func testSansMesureAucuneTemperature() async {
        let m = ModeleMesures(service: TemperatureEauFaux(scenario: .sansMesure), noyau: ServiceMesuresFaux(), fichier: nil)
        await m.charger(spot: spot, eau: nil)
        XCTAssertNil(m.temperature(spot: spot, eau: nil))
    }

    /// Pas de station de température proche : le service n'est pas appelé du tout.
    func testSansStationPasDAppel() async {
        struct SansStation: ServiceMesures {
            func mesures(conditions: Conditions, eau: NiveauEau?, temperature: TemperatureEau?, date: Date) -> [MesureSourcee] { [] }
            func stationTemperature(pres: Coordonnee, eau: StationHydro?) -> StationTemperature? { nil }
        }
        let espion = EspionTemperature(rendu: nil)
        let m = ModeleMesures(service: espion, noyau: SansStation(), fichier: nil)
        await m.charger(spot: spot, eau: nil)
        let n = await espion.nombreDAppels
        XCTAssertEqual(n, 0)
    }

    /// Le cache sur disque ne garde ni coordonnée du spot ni distance au spot.
    func testCacheSansDistanceNiSpot() async throws {
        let fichier = FileManager.default.temporaryDirectory.appendingPathComponent("mesures-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: fichier) }
        let m = ModeleMesures(service: TemperatureEauFaux(), noyau: ServiceMesuresFaux(), fichier: fichier)
        await m.charger(spot: spot, eau: nil)
        let texte = String(decoding: try Data(contentsOf: fichier), as: UTF8.self)
        XCTAssertFalse(texte.contains("48.81234"))
        XCTAssertFalse(texte.contains("2.41567"))
        XCTAssertFalse(texte.contains("\"distanceM\""))
    }
}
#endif
