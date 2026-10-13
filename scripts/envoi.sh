#!/usr/bin/env bash
# scripts/envoi.sh : archive l'app et l'envoie sur TestFlight (App Store Connect).
#
# À lancer sur un Mac, depuis la branche main à jour, sans changement en cours et verte
# (scripts/verif.sh doit passer). Sous Linux, le script refuse de démarrer.
#
# Usage :
#   SCHEMA=NomDuSchema scripts/envoi.sh              envoi réel (une question te sera posée)
#   SCHEMA=NomDuSchema scripts/envoi.sh --oui        envoi réel, sans poser la question
#   SCHEMA=NomDuSchema scripts/envoi.sh --a-blanc    répétition : archive et export en local,
#                                                    rien n'est envoyé, aucun contrôle git
#
# Ce que le script fait, dans l'ordre :
#   1. contrôles (Mac, Xcode 27, branche main propre et à jour, scripts/verif.sh vert) ;
#   2. calcul du numéro de build (voir plus bas) ;
#   3. xcodebuild archive : fabrique l'archive de l'app, signée automatiquement ;
#   4. xcodebuild -exportArchive avec destination=upload : envoie l'archive à App Store Connect.
# Il utilise le compte Apple connecté dans Xcode (Xcode > Settings > Apple Accounts). Une clé d'API App Store
# Connect n'est utilisée que si ASC_KEY_ID, ASC_ISSUER_ID et ASC_KEY_PATH sont tous les trois remplis
# (dans l'environnement ou dans .env, voir docs/atelier-mac.md).
#
# Numéro de build : nombre de minutes écoulées depuis le 1er octobre 2026 (00:00 UTC). Il monte
# tout seul à chaque minute, aucun fichier à modifier, et deux envois n'ont jamais le même numéro.
# Pour en imposer un autre : BUILD=250 SCHEMA=... scripts/envoi.sh
# Le numéro de version (1.0) reste celui du projet Xcode (MARKETING_VERSION), réglé par A.
#
# Écrit pour bash 3.2, le bash livré avec macOS.

# Le nom du schéma Xcode de l'app (Product > Scheme dans Xcode). Laisse vide : à défaut, le script
# reprend celui que A écrit jeudi dans la ligne SCHEMA= en tête de scripts/verif.sh (une seule saisie).
SCHEMA="${SCHEMA:-}"

PROJET="Projet.xcodeproj"
PLISTBUDDY="${PLISTBUDDY:-/usr/libexec/PlistBuddy}"
ORIGINE_BUILD=1790812800   # 1er octobre 2026, 00:00 UTC, en secondes Unix

set -u
set -o pipefail
cd "$(dirname "$0")/.." || exit 2

if [ -z "$SCHEMA" ] && [ -f scripts/verif.sh ]; then
  SCHEMA=$(bash -c "$(grep -m1 '^SCHEMA=' scripts/verif.sh)"$'\n''printf %s "$SCHEMA"' 2>/dev/null) || SCHEMA=""
fi

echec() { printf '✗ %s\n' "$1" >&2; exit 1; }
etape() { printf '\n==> %s\n' "$1"; }
bien() { printf '✓ %s\n' "$1"; }

# Options -----------------------------------------------------------------------------------

A_BLANC=0
OUI=0
for arg in "$@"; do
  case "$arg" in
    --a-blanc) A_BLANC=1 ;;
    --oui) OUI=1 ;;
    -h|--aide|--help) sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $arg (essaie --aide)" >&2; exit 2 ;;
  esac
done

# 1. Contrôles ------------------------------------------------------------------------------

if [ "$(uname -s)" != "Darwin" ]; then
  echo "✗ Ce script ne marche que sur un Mac : il a besoin d'Xcode (xcodebuild)." >&2
  echo "  Ici, le système est $(uname -s). Lance-le depuis le Mac A ou le Mac B." >&2
  exit 2
fi

etape "Contrôles"

[ -n "$SCHEMA" ] || echec "SCHEMA est vide. Lance : SCHEMA=NomDuSchema scripts/envoi.sh   (ou A écrit le nom dans la ligne SCHEMA= en tête de scripts/verif.sh, jeudi)."
[ -d "$PROJET" ] || echec "$PROJET est introuvable. Il est créé par A au lot L0 : fais d'abord git pull sur main."

XCODE_V=$(xcodebuild -version 2>/dev/null | sed -n '1s/^Xcode //p')
[ -n "$XCODE_V" ] || echec "xcodebuild ne répond pas. Répare avec : sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
[ "${XCODE_V%%.*}" = "27" ] || echec "Xcode $XCODE_V est sélectionné, il faut Xcode 27. Répare avec : sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
bien "Xcode $XCODE_V"

# Clés d'API App Store Connect : facultatives, voie de repli si le compte d'Xcode ne suffit pas.
lire_cle() {  # lire_cle NOM : valeur de NOM dans l'environnement, sinon dans .env (ces 3 noms seulement)
  local nom="$1" val
  val="${!nom:-}"
  if [ -z "$val" ] && [ -f .env ]; then
    val=$(grep -E "^${nom}=" .env | tail -1 | cut -d= -f2- | tr -d '\r')
    val=${val%\"}; val=${val#\"}; val=${val%\'}; val=${val#\'}
  fi
  printf '%s' "$val"
}
ASC_KEY_ID=$(lire_cle ASC_KEY_ID)
ASC_ISSUER_ID=$(lire_cle ASC_ISSUER_ID)
ASC_KEY_PATH=$(lire_cle ASC_KEY_PATH)
ASC_KEY_PATH="${ASC_KEY_PATH/#\~/$HOME}"

CLE_API=()
NB_CLES=0
[ -n "$ASC_KEY_ID" ] && NB_CLES=$((NB_CLES + 1))
[ -n "$ASC_ISSUER_ID" ] && NB_CLES=$((NB_CLES + 1))
[ -n "$ASC_KEY_PATH" ] && NB_CLES=$((NB_CLES + 1))
if [ "$NB_CLES" = "3" ]; then
  [ -f "$ASC_KEY_PATH" ] || echec "ASC_KEY_PATH pointe vers un fichier qui n'existe pas : $ASC_KEY_PATH"
  CLE_API=(-authenticationKeyPath "$ASC_KEY_PATH" -authenticationKeyID "$ASC_KEY_ID" -authenticationKeyIssuerID "$ASC_ISSUER_ID")
  bien "connexion à Apple par clé d'API (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH)"
elif [ "$NB_CLES" != "0" ]; then
  echec "Clé d'API incomplète : ASC_KEY_ID, ASC_ISSUER_ID et ASC_KEY_PATH doivent être remplis tous les trois, ou aucun."
else
  bien "connexion à Apple par le compte connecté dans Xcode (Xcode > Settings > Apple Accounts)"
fi

if [ "$A_BLANC" = "1" ]; then
  echo "· répétition : les contrôles git et scripts/verif.sh sont sautés, rien ne sera envoyé."
else
  BRANCHE=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$BRANCHE" = "main" ] || echec "Tu es sur la branche « $BRANCHE ». L'envoi se fait depuis main : git switch main && git pull"
  [ -z "$(git status --porcelain)" ] || echec "Il reste des changements non enregistrés. Fais un commit, ou annule-les, puis relance. Voir : git status"
  git fetch -q origin main || echec "git fetch a échoué (pas de réseau, ou pas d'accès à GitHub). Vérifie avec : gh auth status"
  COMPTE=$(git rev-list --left-right --count HEAD...origin/main 2>/dev/null) || echec "origin/main est introuvable. Vérifie avec : git remote -v"
  AVANCE=${COMPTE%%[[:space:]]*}
  RETARD=${COMPTE##*[[:space:]]}
  [ "$RETARD" = "0" ] || echec "Ta branche main a $RETARD commit(s) de retard. Répare avec : git pull"
  [ "$AVANCE" = "0" ] || echec "Ta branche main a $AVANCE commit(s) qui ne sont pas sur GitHub. Envoie-les d'abord : git push"
  bien "main propre et identique à origin/main"

  [ -x scripts/verif.sh ] || echec "scripts/verif.sh est introuvable ou non exécutable. Fais git pull sur main."
  echo "· scripts/verif.sh en cours..."
  scripts/verif.sh || echec "scripts/verif.sh a échoué : main n'est pas vert, rien n'est envoyé. Corrige d'abord (voir les lignes ci-dessus)."
  bien "scripts/verif.sh est vert"
fi

# 2. Numéro de build ------------------------------------------------------------------------

BUILD="${BUILD:-$(( ( $(date +%s) - ORIGINE_BUILD ) / 60 ))}"
[[ "$BUILD" =~ ^[0-9]+$ ]] || echec "BUILD doit être un nombre entier (reçu : $BUILD)."
[ "$BUILD" -gt 0 ] || echec "Le numéro de build calculé est $BUILD : l'heure du Mac est fausse. Vérifie Réglages Système > Général > Date et heure."
bien "numéro de build $BUILD"

if [ "$A_BLANC" = "0" ] && [ "$OUI" = "0" ]; then
  if [ -t 0 ]; then
    printf 'Envoyer le build %s sur TestFlight ? Un numéro envoyé ne peut plus être réutilisé. (o/N) ' "$BUILD"
    read -r REPONSE
    case "$REPONSE" in
      o|O|oui|Oui|OUI) ;;
      *) echo "Annulé : rien n'a été envoyé."; exit 1 ;;
    esac
  else
    echec "Pas de terminal pour te poser la question. Relance dans un terminal, ou ajoute --oui si tu es sûr."
  fi
fi

# Dossier de travail hors du dépôt (archive, journaux, export) ------------------------------

DOSSIER=$(mktemp -d "${TMPDIR:-/tmp}/envoi.XXXXXX") || echec "Impossible de créer un dossier de travail."
ARCHIVE="$DOSSIER/App.xcarchive"
OPTIONS="$DOSSIER/ExportOptions.plist"
EXPORT="$DOSSIER/export"
echo "· dossier de travail et journaux : $DOSSIER"

montrer_fin() {  # montrer_fin FICHIER : les dernières lignes utiles d'un journal
  echo "--- fin du journal ($1) ---" >&2
  tail -n 25 "$1" >&2
  echo "---" >&2
}

conseils() {  # conseils FICHIER : explique les erreurs de compte et de signature les plus courantes
  local j="$1"
  if grep -q -i -E "Unable to log in|session has expired|authentication failed|No Accounts|No account for team" "$j"; then
    echo "→ Xcode n'est plus connecté à Apple. Ouvre Xcode > Settings > Apple Accounts, reconnecte le compte de l'équipe MWM, puis relance." >&2
  fi
  if grep -q -i -E "No signing certificate|no certificate|Cloud signing permission|doesn't include the .* capability|requires a provisioning profile|No profiles for" "$j"; then
    echo "→ Le compte n'a pas pu créer le certificat ou le profil de signature. Demande à un admin MWM de t'ajouter à l'équipe avec le rôle Admin ou App Manager, ou de créer une clé d'API (voir docs/atelier-mac.md)." >&2
  fi
  if grep -q -i -E "must be enabled before it can be used|Validate plug-in|Validate macro" "$j"; then
    echo "→ Xcode demande d'approuver une extension de paquet : ouvre le projet dans Xcode, lance une fois la compilation et clique sur « Trust & Enable »." >&2
  fi
}

# 3. Archive --------------------------------------------------------------------------------

etape "Archive (de quelques minutes à un quart d'heure la première fois)"
xcodebuild archive \
  -project "$PROJET" \
  -scheme "$SCHEMA" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  ${CLE_API[@]+"${CLE_API[@]}"} \
  CURRENT_PROJECT_VERSION="$BUILD" \
  > "$DOSSIER/archive.log" 2>&1
CODE=$?
if [ "$CODE" != "0" ]; then
  montrer_fin "$DOSSIER/archive.log"
  conseils "$DOSSIER/archive.log"
  echec "L'archive a échoué (code $CODE). Journal complet : $DOSSIER/archive.log"
fi
[ -d "$ARCHIVE" ] || echec "xcodebuild n'a pas produit d'archive. Journal : $DOSSIER/archive.log"

BUILD_ARCHIVE=$("$PLISTBUDDY" -c "Print :ApplicationProperties:CFBundleVersion" "$ARCHIVE/Info.plist" 2>/dev/null)
VERSION_ARCHIVE=$("$PLISTBUDDY" -c "Print :ApplicationProperties:CFBundleShortVersionString" "$ARCHIVE/Info.plist" 2>/dev/null)
IDENT_ARCHIVE=$("$PLISTBUDDY" -c "Print :ApplicationProperties:CFBundleIdentifier" "$ARCHIVE/Info.plist" 2>/dev/null)
[ "$BUILD_ARCHIVE" = "$BUILD" ] || echec "L'archive porte le numéro de build « ${BUILD_ARCHIVE:-?} » au lieu de $BUILD. Journal : $DOSSIER/archive.log"
bien "archive prête : ${IDENT_ARCHIVE:-?} version ${VERSION_ARCHIVE:-?} (build $BUILD_ARCHIVE)"

# 4. Export et envoi ------------------------------------------------------------------------

if [ "$A_BLANC" = "1" ]; then DESTINATION=export; else DESTINATION=upload; fi

cat > "$OPTIONS" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>destination</key>
  <string>$DESTINATION</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
PLIST

if [ "$DESTINATION" = "upload" ]; then
  etape "Envoi à App Store Connect"
else
  etape "Export local (répétition, rien n'est envoyé)"
fi
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$OPTIONS" \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates \
  ${CLE_API[@]+"${CLE_API[@]}"} \
  > "$DOSSIER/export.log" 2>&1
CODE=$?
if [ "$CODE" != "0" ]; then
  montrer_fin "$DOSSIER/export.log"
  conseils "$DOSSIER/export.log"
  echec "L'export a échoué (code $CODE). Journal complet : $DOSSIER/export.log"
fi

echo
if [ "$DESTINATION" = "upload" ]; then
  bien "Build $BUILD (version ${VERSION_ARCHIVE:-?}) envoyé à App Store Connect."
  echo "  Étape suivante : dans App Store Connect > ton app > TestFlight, le build apparaît après"
  echo "  le traitement par Apple (quelques minutes). Journaux : $DOSSIER"
else
  bien "Répétition réussie : l'archive et l'export fonctionnent. Rien n'a été envoyé."
  echo "  Fichiers : $EXPORT"
fi
exit 0
