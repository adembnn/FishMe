#!/usr/bin/env bash
# D2 : refait les 3 fichiers Hub'Eau (France entiere) et les publie sur la release privee `donnees`.
# Usage : outils/hubeau/lancer.sh            (calcule, puis demande avant d'envoyer)
#         outils/hubeau/lancer.sh --publier  (envoie sans demander)
# Reprise : le cache (outils/hubeau/cache) garde chaque page deja recue ; relancer apres une coupure.
set -euo pipefail
cd "$(dirname "$0")"
PY="${PYTHON:-python3}"

echo "== Verification de l'acces a Hub'Eau"
code=$(curl -sS -o /dev/null -w "%{http_code}" "https://hubeau.eaufrance.fr/api/v1/etat_piscicole/stations?size=1" || true)
[ "$code" = "200" ] || [ "$code" = "206" ] || { echo "Hub'Eau injoignable (HTTP $code)"; exit 1; }

echo "== Tests"
"$PY" -m unittest discover -s tests

echo "== Codes Sandre des especes (comparaison avec les noms latins de Hub'Eau)"
"$PY" hubeau.py --verifier-especes

echo "== Remplissage du cache par groupes de departements (reprise possible)"
GROUPES=(
  "75 77 78 91 92 93 94 95"
  "01 03 07 15 26 38 42 43 63 69 73 74"
  "21 25 39 58 70 71 89 90 18 28 36 37 41 45"
  "14 27 50 61 76 02 59 60 62 80"
  "08 10 51 52 54 55 57 67 68 88"
  "44 49 53 72 85 22 29 35 56"
  "16 17 19 23 24 33 40 47 64 79 86 87"
  "09 11 12 30 31 32 34 46 48 65 66 81 82"
  "04 05 06 13 83 84 2A 2B"
)
for g in "${GROUPES[@]}"; do
  echo "-- groupe : $g"
  # shellcheck disable=SC2086
  "$PY" hubeau.py --recuperer-seulement --departement $g || echo "(groupe incomplet : relancer lancer.sh pour reprendre)"
done

echo "== Fabrication des 3 fichiers (France entiere, depuis le cache)"
"$PY" hubeau.py --cache-seulement

cd sortie
ls -l stations-especes.json rarete-departements.json stations-hydro.json
echo "Rapport : $(pwd)/../cache/rapports/rapport.json"

if [ "${1:-}" != "--publier" ]; then
  read -r -p "Envoyer les 3 fichiers sur la release privee 'donnees' ? [o/N] " rep
  [ "$rep" = "o" ] || { echo "Rien envoye."; exit 0; }
fi
gh release view donnees >/dev/null 2>&1 || gh release create donnees --title "donnees" --notes "Fichiers fabriques par D2 (OFB et Hub'Eau, Licence Ouverte 2.0). Release privee."
gh release upload donnees stations-especes.json rarete-departements.json stations-hydro.json --clobber
gh release view donnees
