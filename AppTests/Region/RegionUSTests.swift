import Core
import Foundation
import Testing
@testable import BuildChallenge

/// US14 : toute l'app suit la région. États-Unis = pouces, livres, °F, miles, mph, inHg, dates mois/jour ; France inchangée.
@MainActor
struct RegionUSTests {
    private let fr = RegionApp.france
    private let us = RegionApp.etatsUnis
    /// 7 nov. 2026, 15:05 dans le fuseau de la machine (les formats ne dépendent pas du fuseau choisi).
    private var date: Date { Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 7, hour: 15, minute: 5))! }

    private func net(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{202F}", with: " ").replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    // MARK: région persistée

    @Test func regionPersisteeSuitLeChoixPuisLaDeduction() {
        let suite = UserDefaults(suiteName: "RegionUSTests-\(UUID().uuidString)")!
        #expect(RegionPersistee.lire(suite) == .france)
        suite.set("etatsUnis", forKey: RegionPersistee.cleDeduite)
        #expect(RegionPersistee.lire(suite) == .etatsUnis)
        suite.set("france", forKey: RegionPersistee.cleChoix)
        #expect(RegionPersistee.lire(suite) == .france)
        suite.set("automatique", forKey: RegionPersistee.cleChoix)
        #expect(RegionPersistee.lire(suite) == .etatsUnis)
    }

    @Test func laCleInfoDuProxyUSEstLueEtSeuleUneAdresseHttpsPasse() {
        let vide = UserDefaults(suiteName: "RegionUSTests-\(UUID().uuidString)")!
        // L'app (hôte des tests) porte la clé FishMeProxyUSURL : adresse publique, jamais une clé d'API.
        #expect(ConfigProxyUS.url(env: [:], reglages: vide, bundle: .main) == "https://fishme-us-proxy.fishme-titouan.workers.dev")
        #expect(ConfigProxyUS.url(env: ["FISHME_US_PROXY_URL": "http://fishme-us-proxy.fishme-titouan.workers.dev"], reglages: vide, bundle: .main) == nil)
    }

    @Test func regionPersisteeEtRegionCouranteDonnentLaMemeReponse() {
        let suite = UserDefaults(suiteName: "RegionUSTests-\(UUID().uuidString)")!
        let courante = RegionCourante(reglages: suite)
        courante.choix = .etatsUnis
        #expect(RegionPersistee.lire(suite) == courante.region)
        courante.choix = .france
        #expect(RegionPersistee.lire(suite) == courante.region)
    }

    // MARK: conditions

    @Test func ventEnMilesParHeure() {
        #expect(FormatConditions.vent(kmh: 16, region: fr) == "16 km/h")
        #expect(FormatConditions.vent(kmh: 16, region: us) == "10 mph")
        #expect(FormatConditions.uniteVent(region: us) == "mph")
    }

    @Test func pressionEnPoucesDeMercure() {
        #expect(net(FormatConditions.pression(hPa: 1013, region: fr)).hasSuffix("hPa"))
        #expect(FormatConditions.pression(hPa: 1013, region: us) == "29.91 inHg")
        #expect(net(FormatConditions.pression(1013, tendance: -3, region: us)) == "29.91 inHg ↘ −0.09 inHg in 6 h")
        #expect(net(FormatConditions.pression(1013, tendance: -3, region: fr)).contains("en 6 h"))
    }

    @Test func temperaturesEnFahrenheit() {
        #expect(FormatConditions.degres(celsius: 10, region: fr) == "10°")
        #expect(FormatConditions.degres(celsius: 10, region: us) == "50°")
        #expect(FormatConditions.degres(celsius: 0, region: us) == "32°")
    }

    @Test func pluieEnPouces() {
        #expect(FormatConditions.pluie(mm: 2.5, region: fr) == "2,5 mm")
        #expect(FormatConditions.pluie(mm: 25.4, region: us) == "1.00 in")
    }

    @Test func eauEnPiedsEtPiedsCubes() {
        #expect(FormatConditions.hauteurEau(metres: 1.5, region: fr) == "1,50 m")
        #expect(FormatConditions.hauteurEau(metres: 1.5, region: us) == "4.92 ft")
        #expect(net(FormatConditions.debitEau(m3s: 10, region: us)) == "353 ft³/s")
        #expect(FormatConditions.debitEau(m3s: 10, region: fr) == "10 m³/s")
        #expect(FormatConditions.sourceEau(region: us) == "USGS")
        #expect(FormatConditions.sourceEau(region: fr) == "Hub’Eau")
    }

    @Test func datesMoisJourEnRegionUS() {
        #expect(net(FormatConditions.heure(date, region: us)) == "3:05 PM")
        #expect(FormatConditions.heure(date, region: fr) == "15 h 05")
        #expect(FormatConditions.horloge(date, region: fr) == "15:05")
        #expect(FormatConditions.jour(date, region: us) == "Saturday, Nov 7")
        #expect(FormatConditions.jour(date, region: fr) == "samedi 7 nov.")
        #expect(FormatMesures.jour(date, region: us) == "Nov 7")
        #expect(FormatMesures.jour(date, region: fr) == "7 nov.")
        #expect(FormatSortie.date(date, region: us) == "Nov 7")
        #expect(FormatSortie.date(date, region: fr) == "7 nov.")
    }

    @Test func pointsCardinauxEtCiel() {
        #expect(FormatConditions.cardinal(270, region: fr) == "O")
        #expect(FormatConditions.cardinal(270, region: us) == "W")
        #expect(FormatConditions.libelle(codeTemps: 0, region: us) == "Clear")
        #expect(FormatConditions.libelle(codeTemps: 0, region: fr) == "Dégagé")
    }

    // MARK: mesures de N3

    private func mesure(_ g: Grandeur, _ v: Double, _ unite: String, ecart: Double? = nil) -> MesureSourcee {
        MesureSourcee(grandeur: g, valeur: v, unite: unite, heure: date, source: "Hub'Eau, station Test",
                      tendance: ecart.map { Tendance(sens: .baisse, ecart: $0, surHeures: 6) })
    }

    @Test func mesuresEnUnitesAmericaines() {
        #expect(FormatMesures.valeur(mesure(.temperatureEau, 10, "°C"), region: us) == "50.0 °F")
        #expect(FormatMesures.valeur(mesure(.temperatureEau, 14.2, "°C"), region: fr) == "14,2 °C")
        #expect(FormatMesures.valeur(mesure(.pression, 1013, "hPa"), region: us) == "29.91 inHg")
        #expect(net(FormatMesures.valeur(mesure(.debit, 10, "m³/s"), region: us)) == "353 ft³/s")
        #expect(FormatMesures.ecart(mesure(.temperatureEau, 10, "°C", ecart: 1), region: us) == "+1.8 °F in 6 h")
        #expect(FormatMesures.ecart(mesure(.pression, 1013, "hPa", ecart: -3), region: us) == "−0.09 inHg in 6 h")
        #expect(FormatMesures.ecart(mesure(.pression, 1013, "hPa", ecart: -3), region: fr) == "−3 hPa en 6 h")
    }

    @Test func laSourceDeLEauEstUSGSAuxEtatsUnis() {
        let m = mesure(.debit, 10, "m³/s")
        #expect(FormatMesures.sourceEtHeure(m, region: us).hasPrefix("USGS, station Test"))
        #expect(FormatMesures.sourceEtHeure(m, region: fr).hasPrefix("Hub'Eau, station Test"))
    }

    // MARK: session

    @Test func tailleDeLaDernierePrise() {
        #expect(FormatSortie.taille(centimetres: 35, region: fr) == "35 cm")
        #expect(FormatSortie.taille(centimetres: 35, region: us) == "13.8 in")
    }

    // MARK: eau américaine

    @Test func sansProxyAucuneAdresseNiLecture() async {
        #expect(ConfigProxyUS.url(env: [:], reglages: UserDefaults(suiteName: "RegionUSTests-\(UUID().uuidString)")!, bundle: Bundle(for: AncreBundleTests.self)) == nil)
        let source = SourceEauUS(proxyURL: nil)
        #expect(!source.configure)
        let lecture = await source.lecture(pres: Coordonnee(latitude: 38.95, longitude: -77.12))
        #expect(lecture == LectureEauUS())
    }

    @Test func adresseDuProxyHttpsSeulement() {
        let vide = UserDefaults(suiteName: "RegionUSTests-\(UUID().uuidString)")!
        let b = Bundle(for: SourceEauUS.self)
        #expect(ConfigProxyUS.url(env: ["FISHME_US_PROXY_URL": "https://exemple.workers.dev"], reglages: vide, bundle: b) == "https://exemple.workers.dev")
        #expect(ConfigProxyUS.url(env: ["FISHME_US_PROXY_URL": "http://exemple.workers.dev"], reglages: vide, bundle: b) == nil)
        #expect(ConfigProxyUS.url(env: ["FISHME_US_PROXY_URL": "http://localhost:8787"], reglages: vide, bundle: b) == "http://localhost:8787")
    }

    @Test func mesuresUSGSConverties() {
        let station = StationUSGS(id: "USGS-01646500", nom: "Potomac River", latitude: 38.95, longitude: -77.12)
        let mesures = [
            MesureUSGS(stationId: station.id, parametre: .debit, valeur: 1000, unite: .piedCubeParSeconde, heure: date, statut: .provisoire),
            MesureUSGS(stationId: station.id, parametre: .hauteur, valeur: 10, unite: .pied, heure: date, statut: .approuvee),
            MesureUSGS(stationId: station.id, parametre: .temperatureEau, valeur: 12.5, unite: .degreCelsius, heure: date, statut: .provisoire),
        ]
        let l = SourceEauUS.lecture(station: station, mesures: mesures)
        #expect(abs((l.niveau?.hauteurM ?? 0) - 3.048) < 1e-9)
        #expect(abs((l.niveau?.debitM3s ?? 0) - 28.316846592) < 1e-6)
        #expect(l.temperature?.celsius == 12.5)
        #expect(l.niveau?.station.nom == "Potomac River")
        // Rien d'inventé : sans mesure, pas de niveau.
        #expect(SourceEauUS.lecture(station: station, mesures: []) == LectureEauUS())
    }

    // MARK: vocabulaire interdit

    @Test func aucunTexteAmericainNeDitAutoriseOuLegal() {
        let textes = [FormatConditions.eauIndisponible(region: us), FormatConditions.titreEau(region: us),
                      FormatConditions.luSansReseau(date, region: us), FormatConditions.vent(kmh: 5, region: us),
                      FormatConditions.libelle(codeTemps: 61, region: us), FormatMesures.nom(.debit, region: us),
                      FormatMesures.sourceEtHeure(mesure(.debit, 1, "m³/s"), region: us), SourceEauUS.self.description()]
        for t in textes.map({ $0.lowercased() }) {
            for mot in ["autorisé", "allowed", "legal", "tu peux la garder", "you can keep it"] { #expect(!t.contains(mot)) }
        }
    }
}

private extension SourceEauUS {
    static func description() -> String { "USGS" }
}

/// Une classe du paquet de tests, qui n'a pas la clé Info `FishMeProxyUSURL` (celle de l'app l'a désormais).
private final class AncreBundleTests {}
