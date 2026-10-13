// NON COMPILÉ : écrit sans compilateur Swift. Voir README.
// Mock : horloge figée pour tests et #Preview.
import Foundation

public struct FixedClock: ClockProviding {
    public let fixed: Date

    public init(_ fixed: Date) {
        self.fixed = fixed
    }

    /// 2026-10-15 09:00:00 UTC, premier jour du build.
    public init() {
        self.fixed = Date(timeIntervalSince1970: 1_792_054_800)
    }

    public func now() -> Date {
        fixed
    }
}
