#!/usr/bin/env bash
# scripts/lancer-simu.sh : compile FishMe et l'ouvre dans l'iPhone virtuel, comme Titouan (Xcode fermé, moins de RAM).
#
# Usage :
#   scripts/lancer-simu.sh            compile, installe et lance en premium (démo)
#   scripts/lancer-simu.sh --neuf     efface d'abord l'app (premier lancement, spot oublié)
#   scripts/lancer-simu.sh --gratuit  lance sans le premium de démo
#
# Une seule fois avant : xcodebuild -downloadComponent MetalToolchain
set -eu
cd "$(dirname "$0")/.."

APPAREIL="${APPAREIL:-iPhone 18 Pro}"
DD="${DD:-/tmp/fishme-dd}"
ID=ai.mwm.build.challenge.team.01
POSITION="${POSITION:-48.835,2.240}"   # Boulogne-Billancourt ; le simulateur n'a pas de GPS
NEUF=0; PRO=(-FishMeForcerPro YES)
for arg in "$@"; do
  case "$arg" in
    --neuf) NEUF=1 ;;
    --gratuit) PRO=() ;;
    *) echo "Option inconnue : $arg" >&2; exit 2 ;;
  esac
done

echo "==> Compilation (1 à 5 min)"
xcodebuild build FISHME_ICLOUD=NO -project BuildChallenge.xcodeproj -scheme BuildChallenge \
  -destination "platform=iOS Simulator,name=$APPAREIL" -derivedDataPath "$DD" CODE_SIGNING_ALLOWED=NO -quiet

echo "==> Démarrage de l'$APPAREIL"
xcrun simctl boot "$APPAREIL" 2>/dev/null || true
xcrun simctl bootstatus "$APPAREIL" -b >/dev/null
open "/Applications/Xcode.app/Contents/Applications/DeviceHub.app" 2>/dev/null || open -a Simulator 2>/dev/null || true

xcrun simctl terminate booted "$ID" 2>/dev/null || true
[ "$NEUF" = 1 ] && xcrun simctl uninstall booted "$ID"
xcrun simctl install booted "$DD/Build/Products/Debug-iphonesimulator/BuildChallenge.app"
xcrun simctl location booted set "$POSITION"
xcrun simctl launch booted "$ID" ${PRO[@]+"${PRO[@]}"}
echo "✓ FishMe est ouvert dans l'$APPAREIL"
