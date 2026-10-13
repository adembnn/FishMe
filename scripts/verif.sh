#!/usr/bin/env bash
# Vérification de l'atelier : sort 0 si tout est vert, 1 sinon.
# Usage : scripts/verif.sh [--rapide]
#   sans option : toutes les parties (documents, lots, atelier, Core, App).
#   --rapide    : seulement les parties touchées par les fichiers changés
#                 (depuis la base commune avec origin/main, plus ce qui n'est pas commité).
# Chaque partie imprime une ligne : « ✓ … » (vert), « ✗ … » (rouge, avec quoi faire) ou « · sauté : <raison> ».
# Jamais de vert silencieux. La dernière ligne résume le tout.

SCHEMA="${SCHEMA:-}"        # Nom du schéma Xcode. A l'écrit ici une fois le projet créé (L0), par exemple SCHEMA="PecheApp".
IMAGE_SWIFT="swift:6.4"     # Image Docker utilisée quand Swift n'est pas installé (cloud).

racine=$(cd "$(dirname "$0")/.." && pwd)
cd "$racine" || exit 1

rapide=0
case "${1:-}" in
  "") ;;
  --rapide) rapide=1 ;;
  *) echo "Usage : scripts/verif.sh [--rapide]" >&2; exit 2 ;;
esac

# ATELIER_SYSTEME ne sert qu'à l'essai (outils/atelier/essai.py) : il simule un Mac sous Linux.
systeme="${ATELIER_SYSTEME:-$(uname -s)}"

sortie=$(mktemp "${TMPDIR:-/tmp}/verif.XXXXXX") || exit 1
trap 'rm -f "$sortie"' EXIT

nb_ok=0; nb_ko=0; nb_saute=0; rouges=""
ok()    { printf '✓ %s\n' "$1"; nb_ok=$((nb_ok + 1)); }
saute() { printf '· sauté : %s\n' "$1"; nb_saute=$((nb_saute + 1)); }
# ko <partie> <message> [à faire] : une partie rouge, avec la fin de sa sortie.
ko() {
  printf '✗ %s\n' "$2"
  [ -n "${3:-}" ] && printf '    → À faire : %s\n' "$3"
  nb_ko=$((nb_ko + 1)); rouges="${rouges:+$rouges, }$1"
}
fin() { [ -s "$sortie" ] && tail -n 25 "$sortie" | sed 's/^/    /'; }

# Quelles parties les fichiers changés touchent-ils ? (en cas de doute, toutes)
parties=$(python3 outils/atelier/lots.py changes 2>/dev/null | python3 outils/atelier/lots.py parties 2>/dev/null) \
  || parties="documents lots atelier core app"
touche() { case " $parties " in *" $1 "*) return 0 ;; esac; return 1; }
# a_lancer <partie> : toujours vrai en complet ; en rapide, seulement si la partie est touchée.
a_lancer() { [ "$rapide" -eq 0 ] || touche "$1"; }

# --- documents -------------------------------------------------------------
if [ ! -f docs/verifier.py ]; then
  saute "documents : docs/verifier.py est absent"
elif ! a_lancer documents; then
  saute "documents : aucun fichier de docs/ n'a changé (--rapide)"
elif (cd docs && python3 verifier.py) >"$sortie" 2>&1; then
  ok "documents : $(tail -n 1 "$sortie")"
else
  ko documents "documents : docs/verifier.py a trouvé des trous" "lis la liste ci-dessous, corrige docs/, puis relance."
  fin
fi

# --- lots ------------------------------------------------------------------
if [ ! -f outils/atelier/lots.py ]; then
  saute "lots : outils/atelier/lots.py est absent"
elif ! a_lancer lots; then
  saute "lots : docs/lots.md et lots.py n'ont pas changé (--rapide)"
elif python3 outils/atelier/lots.py verifier >"$sortie" 2>&1; then
  ok "lots : $(tail -n 1 "$sortie")"
else
  ko lots "lots : docs/lots.md a un lot sans branche, sans dossier, ou deux lots qui se partagent un dossier" "corrige la colonne « Branche » ou « Dossier » de docs/lots.md."
  fin
fi

# --- atelier (les garde-fous eux-mêmes) --------------------------------------
if [ ! -f outils/atelier/essai.py ]; then
  saute "atelier : outils/atelier/essai.py est absent"
elif [ "${ATELIER_ESSAI:-}" = "1" ]; then
  saute "atelier : appelé depuis l'essai (évite que l'essai se relance lui-même)"
elif ! a_lancer atelier; then
  saute "atelier : aucun fichier de l'atelier n'a changé (--rapide)"
elif python3 outils/atelier/essai.py >"$sortie" 2>&1; then
  ok "$(tail -n 1 "$sortie")"
else
  ko atelier "atelier : un garde-fou ne bloque plus son erreur" "lance python3 outils/atelier/essai.py pour voir lequel."
  fin
fi

# --- Core (tests sans écran) -------------------------------------------------
if [ ! -f Packages/Core/Package.swift ]; then
  saute "Core : pas encore de Packages/Core/Package.swift"
elif ! a_lancer core; then
  saute "Core : aucun fichier de Packages/ n'a changé (--rapide)"
else
  statut=0; mode=""
  if command -v swift >/dev/null 2>&1; then
    mode="Swift natif"
    swift test --package-path Packages/Core >"$sortie" 2>&1 || statut=$?
  elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    mode="Docker $IMAGE_SWIFT"
    if ! docker image inspect "$IMAGE_SWIFT" >/dev/null 2>&1; then
      ko Core "Core : l'image Docker $IMAGE_SWIFT n'est pas téléchargée" "lance scripts/cloud-pret.sh"
      mode=""
    else
      docker run --rm -v "$PWD":/w -w /w "$IMAGE_SWIFT" swift test --package-path Packages/Core >"$sortie" 2>&1 || statut=$?
    fi
  else
    ko Core "Core : ni Swift ni Docker ne répondent" "dans le cloud, lance scripts/cloud-pret.sh ; sur Mac, installe Xcode."
  fi
  if [ -n "$mode" ]; then
    if [ "$statut" -eq 0 ]; then
      resume=$(grep -E 'Test run with|Executed [0-9]+ test' "$sortie" | tail -n 1)
      ok "Core : swift test vert ($mode)${resume:+ — $resume}"
    else
      ko Core "Core : swift test est rouge ($mode)" "corrige le test ou le code marqué ci-dessous, puis relance."
      fin
    fi
  fi
fi

# --- App (tests sur simulateur, Mac seulement) ---------------------------------
if [ "$systeme" = "Darwin" ]; then
  projet=$(ls -d ./*.xcodeproj 2>/dev/null | head -n 1)
  if [ -z "$projet" ]; then
    saute "App : pas encore de projet Xcode (*.xcodeproj)"
  elif ! a_lancer app; then
    saute "App : aucun fichier de l'App n'a changé (--rapide)"
  elif ! command -v xcodebuild >/dev/null 2>&1; then
    ko App "App : xcodebuild est introuvable" "installe Xcode puis lance : xcode-select --install"
  else
    schema="$SCHEMA"
    if [ -z "$schema" ]; then
      schemas=$(xcodebuild -list -json -project "$projet" 2>/dev/null \
        | python3 -c 'import json,sys; d=json.load(sys.stdin); print("\n".join((d.get("project") or d.get("workspace") or {}).get("schemes", [])))' 2>/dev/null)
      nom=$(basename "$projet" .xcodeproj)
      if [ "$(printf '%s\n' "$schemas" | grep -c .)" -eq 1 ]; then
        schema="$schemas"
      elif printf '%s\n' "$schemas" | grep -qx "$nom"; then
        schema="$nom"
      fi
    fi
    ligne=$(xcrun simctl list devices available 2>/dev/null | grep -E '^ +iPhone' | head -n 1)
    udid=$(printf '%s' "$ligne" | sed -E 's/.*\(([0-9A-Fa-f-]{36})\).*/\1/')
    if [ -z "$schema" ]; then
      ko App "App : je ne sais pas quel schéma Xcode tester" "écris son nom dans la ligne SCHEMA= en tête de scripts/verif.sh."
    elif [ -z "$ligne" ] || [ "$udid" = "$ligne" ]; then
      ko App "App : aucun simulateur iPhone n'est disponible" "ouvre Xcode > Settings > Components et installe un simulateur iOS."
    else
      cible=$(printf '%s' "$ligne" | sed -E 's/^ +//; s/ \([0-9A-Fa-f-]{36}\).*//')
      if xcodebuild test -project "$projet" -scheme "$schema" -destination "platform=iOS Simulator,id=$udid" >"$sortie" 2>&1; then
        ok "App : xcodebuild test vert (schéma $schema, simulateur $cible)"
      else
        ko App "App : xcodebuild test est rouge (schéma $schema, simulateur $cible)" "corrige le test ou le code marqué ci-dessous, puis relance."
        fin
      fi
    fi
  fi
elif touche app; then
  if [ "${CI:-}" = "true" ] || [ "${GITHUB_ACTIONS:-}" = "true" ]; then
    saute "App : l'App se vérifie sur un Mac (scripts/fusionner.sh y lance xcodebuild) ; la CI Linux ne la compile pas"
  else
    ko App "App : à vérifier sur un Mac (Linux ne peut pas compiler l'app iPhone)" "lance scripts/verif.sh sur un Mac avant de fusionner."
  fi
else
  saute "App : Mac requis, et aucun fichier de l'App n'a changé"
fi

# --- résumé ------------------------------------------------------------------
echo
if [ "$nb_ko" -gt 0 ]; then
  echo "verif : ROUGE — $nb_ko ✗ ($rouges), $nb_ok ✓, $nb_saute sauté(s)"
  exit 1
fi
echo "verif : VERT — $nb_ok ✓, $nb_saute sauté(s)"
exit 0
