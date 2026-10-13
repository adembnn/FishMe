// swift-tools-version: 6.0
// NON COMPILÉ : écrit sans compilateur Swift (Windows, 13/10/2026).
//
// PecheApple = adaptateurs Apple (Foundation Models, Core ML, Vision, Core Motion, App Intents, StoreKit).
// Chaque API Apple est sous `#if canImport(...)` + `@available`. Propriétaire : Adem.
// Ne se compile pas sous Windows/Linux : vérifié seulement sur Mac (xcodebuild).
import PackageDescription

let package = Package(
    name: "PecheApple",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),  // permet `swift build` sur Mac sans simulateur
    ],
    products: [
        .library(name: "PecheApple", targets: ["PecheApple"]),
    ],
    dependencies: [
        .package(path: "../PecheCore"),
    ],
    targets: [
        .target(
            name: "PecheApple",
            dependencies: [.product(name: "PecheCore", package: "PecheCore")],
            // Mode Swift tolérant au départ (aligné sur project.yml) ; à resserrer plus tard.
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "PecheAppleTests",
            dependencies: ["PecheApple"]
        ),
    ]
)
