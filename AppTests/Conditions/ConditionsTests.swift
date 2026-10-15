import XCTest
import Core
@testable import BuildChallenge

#if DEBUG
@MainActor
final class ConditionsTests: XCTestCase {
    private let spotExact = Coordonnee(latitude: 48.81234, longitude: 2.41567)
    private let debut = Date(timeIntervalSince1970: 1_760_000_000)

    private func modele(journal: EnregistreurRequetes, now: @escaping @Sendable () -> Date) -> ConditionsDuSpot {
        ConditionsDuSpot(meteo: SourceMeteoEspion(journal: journal), eau: NiveauEauEspion(journal: journal),
                         noyau: ConditionsFaux(), maintenant: now, fichier: nil)
    }

    /// Test 8 : WeatherKit reçoit le point de `pointMeteo`, Hub'Eau le seul code de `stationHydro`.
    func testRequetesSansCoordonneeExacte() async {
        let journal = EnregistreurRequetes()
        let m = modele(journal: journal, now: { Date(timeIntervalSince1970: 1_760_000_000) })
        _ = await m.lire(spot: spotExact)
        let points = await journal.pointsMeteo
        let codes = await journal.codesStation
        XCTAssertEqual(points, [ConditionsFaux().pointMeteo(spot: spotExact)])
        XCTAssertNotEqual(points.first, spotExact)
        XCTAssertEqual(codes, [ConditionsFaux().stationHydro(pres: spotExact)?.code])
    }

    /// Une seule lecture par spot en 30 min.
    func testCacheDe30Minutes() async {
        let journal = EnregistreurRequetes()
        let m = modele(journal: journal, now: { Date(timeIntervalSince1970: 1_760_000_000) })
        _ = await m.lire(spot: spotExact)
        _ = await m.lire(spot: spotExact)
        let n = await journal.pointsMeteo.count
        XCTAssertEqual(n, 1)
    }

    /// Sans réseau : la dernière lecture marquée « cache », ou rien ; jamais de valeur inventée.
    func testSansReseau() async {
        let m = ConditionsDuSpot(meteo: SourceMeteoFaux(meteoRendue: nil), eau: NiveauEauFaux(scenario: .sansReseau),
                                 noyau: ConditionsFaux(), maintenant: { Date() }, fichier: nil)
        let l = await m.lire(spot: spotExact)
        XCTAssertNil(l)
        XCTAssertNil(m.instantane(spot: spotExact))
    }

    func testInstantaneRefuseUneLectureDePlusDe60Minutes() async {
        let journal = EnregistreurRequetes()
        let horloge = Horloge(debut)
        let m = modele(journal: journal, now: { horloge.valeur })
        _ = await m.lire(spot: spotExact)
        XCTAssertNotNil(m.instantane(spot: spotExact))
        horloge.valeur = debut.addingTimeInterval(61 * 60)
        XCTAssertNil(m.instantane(spot: spotExact))
    }

    /// Test 7 : la permission ne se demande qu'au premier toucher ; une condition choisie donne une notification locale.
    func testPermissionAuPremierToucheSeulement() async {
        let faux = NotifieurFaux()
        let modele = PreviensMoiModele(notifieur: faux, maintenant: { Date(timeIntervalSince1970: 1_760_000_000) })
        let avant = await faux.demandes
        XCTAssertEqual(avant, 0)
        _ = await modele.assurerPermission()
        _ = await modele.assurerPermission()
        let apres = await faux.demandes
        XCTAssertEqual(apres, 1)

        let journal = EnregistreurRequetes()
        let m = self.modele(journal: journal, now: { Date(timeIntervalSince1970: 1_760_000_000) })
        let lecture = await m.lire(spot: spotExact)
        modele.criteres.ventSousKmh = 20
        await modele.reprogrammer(avec: lecture)
        let programmees = await faux.programmees
        XCTAssertEqual(programmees.count, 1)
        XCTAssertTrue(programmees[0].corps.contains("prévision lue"))
    }

    func testPlanificateurIgnoreLePasse() {
        let c = CriteresPreviensMoi(ouvertures: [OuvertureChoisie(espece: "brochet", date: debut.addingTimeInterval(-10))])
        let lecture = LectureConditions(point: Coordonnee(latitude: 48.8, longitude: 2.4),
                                        conditions: Conditions(heure: debut), meteo: MeteoBrute(heures: []), eau: nil, alerte: nil, lueLe: debut)
        XCTAssertTrue(PlanificateurPreviensMoi.planifier(criteres: c, lecture: lecture, maintenant: debut).isEmpty)
    }

    func testFormatPression() {
        XCTAssertTrue(FormatConditions.pression(1012, tendance: -3).hasSuffix("hPa ↘ −3 en 6 h"))
    }
}

/// `@unchecked Sendable` : la date n'est lue et écrite sous `NSLock` uniquement ; `nonisolated` pour que l'horloge serve dans une fermeture `@Sendable`.
nonisolated final class Horloge: @unchecked Sendable {
    private let verrou = NSLock()
    private var v: Date
    init(_ d: Date) { v = d }
    var valeur: Date {
        get { verrou.lock(); defer { verrou.unlock() }; return v }
        set { verrou.lock(); defer { verrou.unlock() }; v = newValue }
    }
}
#endif
