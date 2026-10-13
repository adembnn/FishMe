// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// Tests triviaux du contrat (XCTest : fonctionne aussi sous Windows et Linux).
import XCTest
@testable import PecheCore

final class ContractsTests: XCTestCase {
    // MARK: - JSON

    private func roundTrip<T: Codable & Equatable>(_ value: T) throws -> T {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    func testCatchCardJSONRoundTrip() throws {
        let card = CatchCard(
            kind: .prise,
            speciesID: "brochet",
            sizeCm: 62,
            released: true,
            departmentCode: "95",
            place: FuzzyPlace(label: "Oise, près de Cergy", departmentCode: "95"),
            date: Date(timeIntervalSince1970: 1_792_054_800),
            photo: PhotoRef(fileName: "a.jpg"),
            rarity: .rare,
            identifiedBy: .manual,
            userCorrected: true
        )
        XCTAssertEqual(try roundTrip(card), card)
    }

    func testSnapshotJSONRoundTrip() throws {
        let bredouille = CatchCard(kind: .bredouille, date: Date(timeIntervalSince1970: 1_792_054_800))
        let snapshot = CollectionSnapshot(cards: [bredouille], trips: [Trip(startedAt: bredouille.date)])
        let decoded = try roundTrip(snapshot)
        XCTAssertEqual(decoded, snapshot)
        XCTAssertEqual(decoded.schemaVersion, CollectionSnapshot.currentSchemaVersion)
    }

    // MARK: - Chaîne de repli

    private func makeRequest() -> IdentificationRequest {
        IdentificationRequest(department: DepartmentProfile(code: "95", nom: "Val-d'Oise", stationsTotal: 38, especes: []), candidates: [])
    }

    func testChainFallsBackToNextAvailableEngine() async throws {
        let chain = IdentifierChain(identifiers: [
            MockIdentifier(source: .foundationModels, available: false, behavior: .fails(.unavailable)),
            MockIdentifier(source: .coreML, behavior: .fails(.guardrailViolation)),
            MockIdentifier.withSampleSpecies(source: .manual),
        ])
        let result = try await chain.identify(makeRequest())
        XCTAssertEqual(result.source, .manual)
        XCTAssertEqual(result.candidates.count, 3)
        XCTAssertEqual(result.fallbacks.map(\.source), [.foundationModels, .coreML])
    }

    func testChainThrowsWhenAllEnginesFail() async {
        let chain = IdentifierChain(identifiers: [
            MockIdentifier(source: .manual, behavior: .returns([])),
        ])
        do {
            _ = try await chain.identify(makeRequest())
            XCTFail("allEnginesFailed attendu")
        } catch {
            XCTAssertEqual(error as? IdentificationError, .allEnginesFailed)
        }
    }

    // MARK: - Plafond Free

    func testFreeCapBlocksPriseButNotBredouille() {
        let date = Date(timeIntervalSince1970: 0)
        let cards = (0..<3).map { _ in CatchCard(kind: .prise, speciesID: "perche", date: date) }
        let free = Entitlements(plan: .free, limits: EntitlementLimits(freeCardLimit: 3))
        XCTAssertFalse(free.canAddCard(kind: .prise, existingCards: cards))
        XCTAssertTrue(free.canAddCard(kind: .bredouille, existingCards: cards))
        XCTAssertEqual(free.remainingCards(existingCards: cards), 0)
        XCTAssertNil(Entitlements(plan: .pro).remainingCards(existingCards: cards))
    }

    // MARK: - Règles locales

    func testLocalRulesFallsBackToNationalLinkWithFixedWarning() {
        let info = LocalRulesInfo(departmentCode: "95")
        XCTAssertTrue(info.usesFallbackLink)
        XCTAssertEqual(info.linkURL, LocalRulesInfo.fallbackURL)
        XCTAssertEqual(info.avertissement, LocalRulesInfo.avertissement)
    }

    func testFixedClockAndInMemoryStore() async throws {
        XCTAssertEqual(FixedClock().now(), FixedClock().now())
        let store = InMemoryCollectionStore()
        let loaded = try await store.load()
        XCTAssertEqual(loaded, .empty)
    }
}
