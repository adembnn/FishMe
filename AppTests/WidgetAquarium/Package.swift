// swift-tools-version: 6.0
import PackageDescription

// Paquet jetable créé par lancer-tests.sh : il compile la logique pure du widget aquarium (Foundation seulement).
let package = Package(
    name: "WidgetAquariumLogique",
    products: [.library(name: "WidgetAquariumLogique", targets: ["WidgetAquariumLogique"])],
    targets: [
        .target(name: "WidgetAquariumLogique", path: "Sources/WidgetAquariumLogique"),
        .testTarget(name: "WidgetAquariumLogiqueTests", dependencies: ["WidgetAquariumLogique"], path: "Tests/WidgetAquariumLogiqueTests"),
    ]
)
