#!/usr/bin/env bash
# Tests de la logique du widget « Ma session » : Docker (swift:6.4) sous Linux, `swift test` sur Mac.
set -eu
ICI="$(cd "$(dirname "$0")" && pwd)"
RACINE="$(cd "$ICI/../.." && pwd)"
TRAVAIL="$(mktemp -d)"
trap 'rm -rf "$TRAVAIL"' EXIT

mkdir -p "$TRAVAIL/Sources/WidgetSessionLogique" "$TRAVAIL/Tests/WidgetSessionLogiqueTests"
cp "$RACINE/Widget/Session/EtatSession.swift" "$RACINE/WidgetAquarium/DepotSessionWidget.swift" "$TRAVAIL/Sources/WidgetSessionLogique/"
# DepotSessionWidget cite DepotAquariumWidget.groupe : on prend le fichier qui le définit.
cp "$RACINE/WidgetAquarium/InstantaneAquarium.swift" "$RACINE/WidgetAquarium/FondWidget.swift" "$TRAVAIL/Sources/WidgetSessionLogique/"
cp "$ICI/SessionWidgetEssais.swift" "$TRAVAIL/Tests/WidgetSessionLogiqueTests/"
cat > "$TRAVAIL/Package.swift" <<'PAQUET'
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WidgetSessionLogique",
    products: [.library(name: "WidgetSessionLogique", targets: ["WidgetSessionLogique"])],
    targets: [
        .target(name: "WidgetSessionLogique", path: "Sources/WidgetSessionLogique"),
        .testTarget(name: "WidgetSessionLogiqueTests", dependencies: ["WidgetSessionLogique"], path: "Tests/WidgetSessionLogiqueTests"),
    ]
)
PAQUET

if [ "$(uname)" = "Darwin" ]; then
    (cd "$TRAVAIL" && swift test)
else
    sudo docker run --rm -v "$TRAVAIL":/src -w /src swift:6.4 swift test
fi
