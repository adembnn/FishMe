#!/usr/bin/env bash
# Resynchronise l'aquarium de l'app (App/Aquarium/AquariumView.swift) avec celui du widget (WidgetAquarium/).
# Sans réseau, idempotent. À lancer après chaque fusion d'un push d'Adem (lot/widget-aquarium, lot/aquarium).
#
# Pourquoi il ne copie rien par défaut : WidgetAquarium/ est un dossier synchronisé de la cible BuildChallenge
# (seul PoissonsWidget.xcassets en est exclu). Le code de la scène (NageWidget, PoissonVivant, ImagePoisson,
# HorlogeAnimation) et les catalogues FondsWidget.xcassets et NagePoissons.xcassets sont donc DÉJÀ dans l'app :
# les recopier ailleurs donnerait des types en double (erreur de compilation) et des images en double (+22 Mo).
# La resynchronisation se résume donc à : fusionner la branche d'Adem, puis lancer ce script pour vérifier.
#
#   scripts/sync-aquarium.sh            vérifie (code, images, appartenance à la cible) et rapporte le poids
#   scripts/sync-aquarium.sh --copier   copie fonds + poissons dans App/Assets.xcassets/Aquarium/
#                                       (seulement si les catalogues du widget sortent un jour de la cible app)
set -euo pipefail
racine="$(cd "$(dirname "$0")/.." && pwd)"
cd "$racine"

src="WidgetAquarium"
cible="App/Assets.xcassets/Aquarium"
pbx="BuildChallenge.xcodeproj/project.pbxproj"
limite_mo=25

[ -d "$src" ] || { echo "ERREUR : $src introuvable (lancer depuis le dépôt)."; exit 1; }

# Le bloc d'exceptions « WidgetAquarium » de la cible BuildChallenge : ce qui y figure n'est PAS dans l'app.
exclus="$(awk '/Exceptions for "WidgetAquarium" folder in "BuildChallenge" target \*\/ = \{/{d=1} d{print} d&&/^\t\t\};/{exit}' "$pbx" 2>/dev/null || true)"
dans_app() { ! printf '%s\n' "$exclus" | grep -q "$1"; }

taille_mo() { find "$@" -type f -name '*.png' -print0 2>/dev/null | xargs -0 stat -f%z 2>/dev/null \
  | awk '{s+=$1} END{printf "%.1f", s/1000000}' || echo 0; }

echo "== Fichiers de la scène (dans la cible app ?)"
manque=0
for f in NageWidget.swift PoissonVivant.swift HorlogeAnimation.swift InstantaneAquarium.swift VuesAquariumWidget.swift AquariumWidget.swift; do
  if [ ! -f "$src/$f" ]; then echo "  MANQUE  $f"; manque=1
  elif dans_app "$f"; then echo "  ok      $f"
  else echo "  HORS APP $f (exclu de la cible BuildChallenge : AquariumView ne compilera pas)"; manque=1; fi
done
for api in "static func traversees" "static func placements" "static func melange" "static func cycleUtilise"; do
  grep -q "$api" "$src/NageWidget.swift" || { echo "  SIGNATURE ABSENTE : $api (adapter App/Aquarium/AquariumView.swift)"; manque=1; }
done
grep -q "static func imageVisible" "$src/HorlogeAnimation.swift" || { echo "  SIGNATURE ABSENTE : HorlogeAnimation.imageVisible"; manque=1; }
grep -q "struct ImagePoisson" "$src/PoissonVivant.swift" || { echo "  SIGNATURE ABSENTE : ImagePoisson"; manque=1; }

echo "== Catalogues"
for cat in FondsWidget.xcassets NagePoissons.xcassets; do
  if [ ! -d "$src/$cat" ]; then echo "  MANQUE  $cat"; manque=1
  elif dans_app "$cat"; then echo "  ok      $cat dans la cible app ($(taille_mo "$src/$cat") Mo)"
  else echo "  HORS APP $cat"; manque=1; fi
done
[ -d "$src/FondsWidget.xcassets/fond-grand.imageset" ] || { echo "  MANQUE  fond-grand"; manque=1; }

echo "== Espèces rendues en volume (images -lacet-) et en cycle de 16 ou 8 images"
volume=0; cycle16=0; cycle8=0
for d in "$src"/NagePoissons.xcassets/*-nage-0.imageset; do
  [ -e "$d" ] || continue
  slug="$(basename "$d" -nage-0.imageset)"
  if ls "$src/NagePoissons.xcassets/$slug-lacet-"*-0.imageset >/dev/null 2>&1; then volume=$((volume+1))
  elif [ -d "$src/NagePoissons.xcassets/$slug-nage-15.imageset" ]; then cycle16=$((cycle16+1))
  else cycle8=$((cycle8+1)); fi
done
echo "  volume : $volume   cycle 16 images : $cycle16   cycle 8 images (profil aplati) : $cycle8"
echo "  Toute autre espèce retombe sur l'icône de poisson blanche, comme dans le widget."

poids="$(taille_mo "$src/NagePoissons.xcassets" "$src/FondsWidget.xcassets")"
echo "== Poids des images de l'aquarium : $poids Mo (limite $limite_mo Mo)"
awk -v p="$poids" -v l="$limite_mo" 'BEGIN{ if (p > l) print "  ATTENTION : au-dessus de la limite, ne garder que les espèces utiles." }'

if [ "${1:-}" = "--copier" ]; then
  if dans_app NagePoissons.xcassets && dans_app FondsWidget.xcassets; then
    echo "REFUS : les catalogues du widget sont déjà dans la cible app, une copie ferait des doublons."; exit 1
  fi
  mkdir -p "$cible"
  [ -f "$cible/Contents.json" ] || printf '{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  },\n  "properties" : {\n    "provides-namespace" : false\n  }\n}\n' > "$cible/Contents.json"
  for cat in FondsWidget NagePoissons; do
    for d in "$src/$cat.xcassets"/*.imageset; do
      rsync -a --delete "$d" "$cible/"
    done
  done
  echo "Copié dans $cible."
fi

[ "$manque" = 0 ] && echo "OK : l'aquarium de l'app suit le widget." || { echo "À CORRIGER (voir plus haut)."; exit 1; }
