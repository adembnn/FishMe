import Foundation
import Testing
@testable import Core

private let stationMarne = StationHydro(code: "F664000104", nom: "La Marne à Gournay-sur-Marne - Pont", eau: "La Marne",
                                        coordonnee: Coordonnee(latitude: 48.835, longitude: 2.43))

private func point(_ heure: Date, pression: Double = 1013, vent: Double = 10, pluie: Double = 0, code: Int = 1) -> PointMeteo {
    PointMeteo(heure: heure, ventKmh: vent, pluieMm: pluie, pressionHPa: pression, temperatureC: 12, codeTemps: code)
}

private func niveau(hauteur: Double? = 1.2, debit: Double? = 40, normale: Double? = nil, vigilance: Vigilance? = nil,
                    serie: [MesureNiveau] = [], heure: Date = quinzeOctobre) -> NiveauEau {
    NiveauEau(station: stationMarne, hauteurM: hauteur, debitM3s: debit, serie48h: serie, normaleDebitM3s: normale, vigilance: vigilance, heureMesure: heure)
}

@Suite("Conditions : lecture, alertes, stations")
struct ConditionsTests {
    let moteur = moteurEssai()
    var conditions: MoteurConditions { moteur.conditions }

    @Test("Pression −3 hPa en 6 h : tendance en baisse ; vent, pluie et pression de l'heure")
    func tendancePression() {
        let meteo = MeteoBrute(heures: [point(quinzeOctobre.addingTimeInterval(-6 * 3600), pression: 1013), point(quinzeOctobre, pression: 1010, vent: 22, pluie: 0.4)])
        let c = conditions.lireConditions(meteo: meteo, eau: nil, date: quinzeOctobre)
        #expect(c.tendancePressionHPa6h == -3)
        #expect(c.pressionHPa == 1010)
        #expect(c.ventKmh == 22)
        #expect(c.pluieMm == 0.4)
        #expect(c.sources == ["Apple Weather"])
    }

    @Test("Sans point proche ou sans point six heures plus tôt : rien d'inventé")
    func sansDonnees() {
        let vide = conditions.lireConditions(meteo: MeteoBrute(heures: []), eau: nil, date: quinzeOctobre)
        #expect(vide.ventKmh == nil && vide.pressionHPa == nil && vide.tendancePressionHPa6h == nil)
        #expect(vide.sources.isEmpty)
        let seul = conditions.lireConditions(meteo: MeteoBrute(heures: [point(quinzeOctobre)]), eau: nil, date: quinzeOctobre)
        #expect(seul.tendancePressionHPa6h == nil)
        let loin = conditions.lireConditions(meteo: MeteoBrute(heures: [point(quinzeOctobre.addingTimeInterval(-10 * 3600))]), eau: nil, date: quinzeOctobre)
        #expect(loin.ventKmh == nil)
    }

    @Test("Aube, crépuscule et fin légale d'un spot (Soleil/)")
    func soleil() throws {
        let c = moteur.conditions.pour(spot: paris).lireConditions(meteo: MeteoBrute(heures: []), eau: nil, date: quinzeOctobre)
        let aube = try #require(c.aube), crepuscule = try #require(c.crepuscule), fin = try #require(c.finLegale)
        #expect(abs(aube.timeIntervalSince(utc(2026, 10, 15, 6, 9, 29))) <= 150)
        #expect(abs(crepuscule.timeIntervalSince(utc(2026, 10, 15, 17, 3, 14))) <= 150)
        #expect(abs(fin.timeIntervalSince(crepuscule.addingTimeInterval(29 * 60))) <= 1)
        // Sans position ni station, aucun calcul inventé.
        #expect(conditions.lireConditions(meteo: MeteoBrute(heures: []), eau: nil, date: quinzeOctobre).aube == nil)
    }

    @Test("Sans normale, ni « normal » ni « haut » ; avec une normale, haut au-delà de 2 fois")
    func niveauDeLEau() {
        let meteo = MeteoBrute(heures: [])
        #expect(conditions.lireConditions(meteo: meteo, eau: niveau(debit: 400), date: quinzeOctobre).etatRiviere == .inconnu)
        #expect(conditions.lireConditions(meteo: meteo, eau: niveau(debit: 31, normale: 15), date: quinzeOctobre).etatRiviere == .haut)
        #expect(conditions.lireConditions(meteo: meteo, eau: niveau(debit: 29, normale: 15), date: quinzeOctobre).etatRiviere == .normal)
        #expect(conditions.lireConditions(meteo: meteo, eau: nil, date: quinzeOctobre).etatRiviere == .inconnu)
        let c = conditions.lireConditions(meteo: meteo, eau: niveau(), date: quinzeOctobre)
        #expect(c.sources.contains { $0.hasPrefix("Hub'Eau, station La Marne") })
    }

    @Test("Sept jours : un jour par date, vent maximal, pluie cumulée")
    func septJours() {
        let heures = (0..<(9 * 24)).map { h in point(quinzeOctobre.addingTimeInterval(Double(h) * 3600), vent: Double(h % 24), pluie: 0.1) }
        let c = conditions.lireConditions(meteo: MeteoBrute(heures: heures), eau: nil, date: quinzeOctobre)
        #expect(c.septJours.count == 7)
        #expect(c.septJours.first?.ventKmh == 11)
        #expect(c.septJours.first?.jour == utc(2026, 10, 15, 0))
    }

    // MARK: alerte

    @Test("Un orage prévu dans 2 h donne .orage ; dans 5 h, rien")
    func orage() {
        let dans2h = MeteoBrute(heures: [point(quinzeOctobre), point(quinzeOctobre.addingTimeInterval(2 * 3600), code: 95)])
        #expect(conditions.alerte(meteo: dans2h, eau: nil)?.type == .orage)
        let dans5h = MeteoBrute(heures: [point(quinzeOctobre), point(quinzeOctobre.addingTimeInterval(5 * 3600), code: 95)])
        #expect(conditions.alerte(meteo: dans5h, eau: nil) == nil)
        #expect(conditions.alerte(meteo: MeteoBrute(heures: []), eau: nil) == nil)
    }

    @Test("Une alerte officielle d'orage donne .orage avec sa source")
    func orageOfficiel() {
        let m = MeteoBrute(heures: [], alertesOfficielles: [AlerteOfficielle(texte: "Vigilance orange : orages violents", source: "Météo-France")])
        let a = conditions.alerte(meteo: m, eau: nil)
        #expect(a?.type == .orage)
        #expect(a?.source == "Météo-France")
        let pluie = MeteoBrute(heures: [], alertesOfficielles: [AlerteOfficielle(texte: "Pluie-inondation", source: "Météo-France")])
        #expect(conditions.alerte(meteo: pluie, eau: nil) == nil)
    }

    @Test("+60 cm en 24 h donne .crue ; +30 cm, rien ; une vigilance jaune donne .crue")
    func crue() {
        let hier = quinzeOctobre.addingTimeInterval(-24 * 3600)
        func serie(_ avant: Double, _ maintenant: Double) -> [MesureNiveau] {
            [MesureNiveau(heure: hier, hauteurM: avant), MesureNiveau(heure: quinzeOctobre, hauteurM: maintenant)]
        }
        let meteo = MeteoBrute(heures: [])
        let a = conditions.alerte(meteo: meteo, eau: niveau(hauteur: 1.6, serie: serie(1.0, 1.6)))
        #expect(a?.type == .crue)
        #expect(a?.mesure == "+60 cm en 24 h")
        #expect(conditions.alerte(meteo: meteo, eau: niveau(hauteur: 1.3, serie: serie(1.0, 1.3))) == nil)
        #expect(conditions.alerte(meteo: meteo, eau: niveau(vigilance: .jaune))?.type == .crue)
        #expect(conditions.alerte(meteo: meteo, eau: niveau(vigilance: .vert)) == nil)
        let etat = conditions.lireConditions(meteo: meteo, eau: niveau(hauteur: 1.6, serie: serie(1.0, 1.6)), date: quinzeOctobre).etatRiviere
        #expect(etat == .crue)
    }

    // MARK: stations

    private func conditionsAvecStations() -> MoteurConditions {
        let hydro: [[String: Any]] = [
            ["code": "F664000104", "nom": "La Marne à Gournay-sur-Marne - Pont", "eau": "La Marne", "code_eau": "F6--0020", "lat": 48.835, "lon": 2.43, "dep": "93", "en_service": true, "debit": true],
            ["code": "F000SEINE", "nom": "La Seine à Ivry", "eau": "La Seine", "code_eau": "----0010", "lat": 48.8225, "lon": 2.414, "dep": "94", "en_service": true, "debit": true],
            ["code": "F000LOIN", "nom": "La Marne plus loin", "eau": "La Marne", "code_eau": "F6--0020", "lat": 48.95, "lon": 2.60, "dep": "93", "en_service": true, "debit": false],
            ["code": "F000HS", "nom": "La Marne hors service", "eau": "La Marne", "code_eau": "F6--0020", "lat": 48.8221, "lon": 2.4131, "dep": "94", "en_service": false, "debit": true],
        ]
        let d = DonneesMoteur(departements: departementsEssai, lacs: lacsEssai, especes: especesEssai, stationsEspeces: stationsOFBEssai,
                              stationsHydro: try! JSONSerialization.data(withJSONObject: hydro), regles: chargeurEssai())
        return MoteurCore(donnees: d, horloge: { quinzeOctobre }).conditions
    }

    @Test("stationHydro : la plus proche à moins de 10 km, sur la même eau, en service")
    func stationHydro() {
        let c = conditionsAvecStations()
        // À Charenton la Seine est plus proche, mais l'eau du spot est la Marne : la station de la Marne.
        #expect(c.stationHydro(pres: charenton)?.code == "F664000104")
        #expect(c.stationHydro(pres: cupertino) == nil)
        #expect(conditions.stationHydro(pres: charenton) == nil)
    }

    @Test("pointMeteo : la station OFB du spot à moins de 5 km, sinon le spot arrondi ; jamais la coordonnée exacte")
    func pointMeteo() {
        #expect(conditions.pointMeteo(spot: charenton) == Coordonnee(latitude: 48.8235, longitude: 2.4160))
        let loin = Coordonnee(latitude: 37.32304, longitude: -122.03218)
        #expect(conditions.pointMeteo(spot: loin) == Coordonnee(latitude: 37.32, longitude: -122.03))
        let surLaStation = Coordonnee(latitude: 48.8235, longitude: 2.4160)
        #expect(conditions.pointMeteo(spot: surLaStation) != surLaStation)
        for spot in [charenton, cupertino, paris, meaux] { #expect(conditions.pointMeteo(spot: spot) != spot) }
    }

    // MARK: tesConditions

    @Test("tesConditions : nil avant 10 sorties, des comptes ensuite")
    func tesConditions() throws {
        func sortie(_ i: Int, pris: Bool) -> Sortie {
            let debut = utc(2026, 9, 1 + i, 8)
            let c = Conditions(heure: debut, ventKmh: 8, pluieMm: 0, pressionHPa: 1015, tendancePressionHPa6h: 0)
            let prises = pris ? [Prise(espece: percheEssai, date: debut)] : []
            return Sortie(debut: debut, fin: debut.addingTimeInterval(7200), prises: prises, conditions: [c])
        }
        let neuf = (0..<9).map { sortie($0, pris: true) }
        #expect(conditions.tesConditions(sorties: neuf) == nil)
        let dix = (0..<10).map { sortie($0, pris: $0 < 6) }
        let constats = try #require(conditions.tesConditions(sorties: dix))
        let faible = try #require(constats.first { $0.texte.contains("vent faible") })
        #expect(faible.nPeches == 6)
        #expect(faible.surSorties == 10)
        #expect(faible.texte.contains("perche commune"))
        // Une sortie sans fin n'est pas comptée.
        let enCours = (0..<9).map { sortie($0, pris: true) } + [Sortie(debut: utc(2026, 9, 30), fin: nil)]
        #expect(conditions.tesConditions(sorties: enCours) == nil)
    }
}

/// Une boîte qui note les URL demandées (le transport est `@Sendable`).
final class Notes: @unchecked Sendable {
    private let verrou = NSLock()
    private var liste: [URL] = []
    func ajouter(_ u: URL) { verrou.lock(); liste.append(u); verrou.unlock() }
    var urls: [URL] { verrou.lock(); defer { verrou.unlock() }; return liste }
}

@Suite("Niveau de l'eau : Hub'Eau hydrométrie")
struct HubEauTests {
    /// Réponses réelles de Hub'Eau, tirées le 15 oct. 2026 à 14 h 49 UTC pour la station F664000104 (la Marne à Gournay-sur-Marne).
    static func fixture(_ nom: String) -> Data {
        let dossier = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures")
        return try! Data(contentsOf: dossier.appendingPathComponent(nom))
    }

    let horloge = utc(2026, 10, 15, 14, 49)

    func service(notes: Notes = Notes()) -> HubEauNiveauService {
        HubEauNiveauService(transport: { url in
            notes.ajouter(url)
            let chemin = url.absoluteString
            if chemin.contains("observations_tr") {
                return Self.fixture(chemin.contains("grandeur_hydro=Q") ? "hubeau-marne-Q.json" : "hubeau-marne-H.json")
            }
            if chemin.contains("obs_elab") { return Self.fixture("hubeau-marne-QmM.json") }
            throw URLError(.badURL)
        }, horloge: { [horloge] in horloge })
    }

    @Test("Sur la réponse enregistrée : hauteur, débit, série de 48 h et normale du mois")
    func reponseEnregistree() async throws {
        let n = try #require(await service().niveau(station: stationMarne))
        #expect(n.station == stationMarne)
        #expect(n.hauteurM == 1.041)
        #expect(n.debitM3s == 29.2)
        #expect(n.heureMesure == utc(2026, 10, 15, 14, 0))
        #expect(n.serie48h.count > 200)
        #expect(zip(n.serie48h, n.serie48h.dropFirst()).allSatisfy { $0.heure < $1.heure })
        #expect(n.serie48h.first?.heure == utc(2026, 10, 13, 15, 0))
        let normale = try #require(n.normaleDebitM3s)
        #expect(abs(normale - 79.817) < 0.01)
        // Ce débit est inférieur à la normale d'octobre : « normal », jamais « haut ».
        let c = MoteurCore(donnees: donneesEssai(), horloge: { quinzeOctobre }).conditions.lireConditions(meteo: MeteoBrute(heures: []), eau: n, date: quinzeOctobre)
        #expect(c.etatRiviere == .normal)
    }

    @Test("Hub'Eau ne reçoit que le code de la station, jamais une coordonnée")
    func seulementLeCode() async {
        let notes = Notes()
        _ = await service(notes: notes).niveau(station: stationMarne)
        let urls = notes.urls
        #expect(urls.count == 3)
        for u in urls {
            let s = u.absoluteString.lowercased()
            #expect(s.contains("code_entite=f664000104"))
            #expect(!s.contains("lat") && !s.contains("lon") && !s.contains("48.83") && !s.contains("2.43"))
            #expect(u.host == "hubeau.eaufrance.fr")
        }
    }

    @Test("Sans réseau : nil, jamais un plantage")
    func sansReseau() async {
        let hs = HubEauNiveauService(transport: { _ in throw URLError(.notConnectedToInternet) }, horloge: { [horloge] in horloge })
        #expect(await hs.niveau(station: stationMarne) == nil)
        let vide = HubEauNiveauService(transport: { _ in Data("{\"count\":0,\"data\":[]}".utf8) }, horloge: { [horloge] in horloge })
        #expect(await vide.niveau(station: stationMarne) == nil)
        let casse = HubEauNiveauService(transport: { _ in Data("pas du json".utf8) }, horloge: { [horloge] in horloge })
        #expect(await casse.niveau(station: stationMarne) == nil)
    }

    @Test("La hauteur seule suffit : sans débit, pas de normale ni de « haut »")
    func hauteurSeule() async throws {
        let hs = HubEauNiveauService(transport: { url in
            if url.absoluteString.contains("grandeur_hydro=H") { return Self.fixture("hubeau-marne-H.json") }
            return Data("{\"data\":[]}".utf8)
        }, horloge: { [horloge] in horloge })
        let n = try #require(await hs.niveau(station: stationMarne))
        #expect(n.hauteurM == 1.041)
        #expect(n.debitM3s == nil)
        #expect(n.normaleDebitM3s == nil)
    }

    @Test("Une normale demande au moins trois mois d'archive")
    func normaleTropMince() {
        let d = Data("{\"data\":[{\"date_obs_elab\":\"2020-10-01\",\"resultat_obs_elab\":50000}]}".utf8)
        #expect(HubEauNiveauService.normale(d, mois: 10) == nil)
    }
}
