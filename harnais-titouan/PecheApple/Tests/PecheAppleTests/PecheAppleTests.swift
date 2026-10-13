// NON COMPILÉ : écrit sans compilateur Swift. Test minimal : prouve que le module se lie.
import XCTest
@testable import PecheApple

final class PecheAppleTests: XCTestCase {
    func testFoundationModelsIndisponibleParDefaut() async {
        let disponible = await FoundationModelsIdentifier().isAvailable()
        XCTAssertFalse(disponible)  // stub : le repli doit prendre le relais
    }

    func testIDsProduitsPresents() {
        XCTAssertEqual(StoreProductID.all.count, 2)
    }
}
