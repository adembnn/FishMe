// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS("27.0"), .macOS(.v14)],
    products: [
        .library(name: "Core", targets: ["Core"]),
    ],
    targets: [
        .target(
            name: "Core",
            resources: [
                // Un dossier gardé tel quel : departementsCouverts() liste les fichiers regles/<code>.json présents.
                .copy("Resources/regles"),
                .process("Resources/departements.geojson"),
                .process("Resources/lacs.geojson"),
                .process("Resources/especes.json"),
                .process("Resources/longueur-poids.json"),
                .process("Resources/cas-verdicts.json"),
                .process("Resources/credits.json"),
                .process("Resources/liens-federations.json"),
                .process("Resources/coins-maison.json"),
                .process("Resources/coins-osm.geojson"),
                .process("Resources/stations-especes.json"),
                .process("Resources/rarete-departements.json"),
                .process("Resources/stations-hydro.json"),
                .process("Conseils/conseils.json"),
            ]
        ),
        .testTarget(name: "CoreTests", dependencies: ["Core"]),
    ]
)
