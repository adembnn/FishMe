#!/usr/bin/env bash
# scripts/archive-planb.sh <variante> : archive Release avec moins de capacités, si Apple en refuse une.
# Variantes : sans-icloud (sauvegarde et amis coupés), sans-icloud-weatherkit (plus la météo), minimal (plus le widget partagé).
# Le fichier d'entitlements est remplacé le temps de l'archive, puis remis : rien ne change dans git.
# L'app se dégrade d'elle-même : sans App Group le widget dit « Ta 1re prise nagera ici », sans CloudKit
# Amis et Mon compte affichent l'absence d'iCloud, sans WeatherKit le bloc météo ne charge pas.
set -eu
cd "$(dirname "$0")/.."
v=${1:?"variante : sans-icloud | sans-icloud-weatherkit | minimal"}
[ -f "Config/planb/app-$v.entitlements" ] || { echo "variante inconnue : $v" >&2; exit 2; }
sauve=$(mktemp -d); cp Config/BuildChallenge.entitlements Config/FishMeWidget.entitlements "$sauve/"
trap 'cp "$sauve"/*.entitlements Config/; echo "entitlements remis"' EXIT
cp "Config/planb/app-$v.entitlements" Config/BuildChallenge.entitlements
[ "$v" = minimal ] && cp Config/planb/widget-minimal.entitlements Config/FishMeWidget.entitlements
icloud=YES; case "$v" in sans-icloud*|minimal) icloud=NO ;; esac
xcodebuild FISHME_ICLOUD=$icloud -project BuildChallenge.xcodeproj -scheme BuildChallenge -configuration Release \
  -destination generic/platform=iOS -archivePath "build/FishMe-$v.xcarchive" -allowProvisioningUpdates archive
echo "Archive : build/FishMe-$v.xcarchive (Organizer d'Xcode > Distribute App > TestFlight)"
