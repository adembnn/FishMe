#!/usr/bin/env bash
# Lance les tests de la logique du widget aquarium : Docker (swift:6.4) sous Linux, `swift test` sur Mac.
set -eu
ICI="$(cd "$(dirname "$0")" && pwd)"
RACINE="$(cd "$ICI/../.." && pwd)"
TRAVAIL="$(mktemp -d)"
trap 'rm -rf "$TRAVAIL"' EXIT

mkdir -p "$TRAVAIL/Sources/WidgetAquariumLogique" "$TRAVAIL/Tests/WidgetAquariumLogiqueTests"
cp "$RACINE/WidgetAquarium/InstantaneAquarium.swift" "$RACINE/WidgetAquarium/NageWidget.swift" "$RACINE/WidgetAquarium/HorlogeAnimation.swift" "$TRAVAIL/Sources/WidgetAquariumLogique/"
cp "$ICI/Package.swift.modele" "$TRAVAIL/Package.swift"
cp "$ICI"/*Tests.swift "$TRAVAIL/Tests/WidgetAquariumLogiqueTests/"

if [ "$(uname)" = "Darwin" ]; then
    (cd "$TRAVAIL" && swift test)
else
    sudo docker run --rm -v "$TRAVAIL":/src -w /src swift:6.4 swift test
fi
