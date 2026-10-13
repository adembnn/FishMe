// swift-tools-version: 6.0
// NON COMPILÉ : écrit sans compilateur Swift (Windows, 13/10/2026). Voir README.
//
// PecheCore = Swift pur. Foundation SEULEMENT (aucun framework Apple, aucune dépendance).
// Doit compiler et tester sous macOS, Linux ET Windows (`swift test`).
// Propriétaire : Titouan.
import PackageDescription

let package = Package(
    name: "PecheCore",
    // Les plateformes ne contraignent que les builds Apple ; Linux/Windows les ignorent.
    // Forme chaîne ("26.0") utilisée exprès : `.v26` n'existe qu'à partir de swift-tools 6.2.
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
    ],
    products: [
        .library(name: "PecheCore", targets: ["PecheCore"]),
    ],
    dependencies: [],  // volontairement vide : règle du dépôt
    targets: [
        .target(
            name: "PecheCore",
            resources: [
                // Données de référence (species.json, departments/, stations/, ...) :
                // fournies par Tools/data-pipeline. Chargées via Bundle.module.
                .copy("Resources/Data"),
            ]
        ),
        .testTarget(
            name: "PecheCoreTests",
            dependencies: ["PecheCore"]
        ),
    ]
)
