#!/usr/bin/env bash
# Veille des règles lancée depuis un ordinateur d'Adem (PC ou Mac), à la place de GitHub Actions.
# Pourquoi : les sites .gouv.fr (préfectures, DDT) refusent ou bloquent les machines de cloud ; un robot GitHub Actions
# risque de ne rien pouvoir lire. Depuis la maison, ça passe. À mettre dans cron (Linux/Mac) :
#   17 7 * * *  cd /chemin/du/depot && bash outils/veille/veille-local.sh >> ~/veille.log 2>&1
# ou dans le Planificateur de tâches de Windows (avec Git Bash). Nécessite python3 et gh connecté.
set -u
cd "$(dirname "$0")/../.."
alertes="$(mktemp)"
python3 -I outils/veille/veille.py --sortie-alertes "$alertes"
code=$?
if [ "$code" -eq 1 ]; then
  gh label create veille --color BFD4F2 2>/dev/null || true
  gh issue create --label veille \
    --title "Veille des règles : un texte a peut-être changé ($(date -u +%Y-%m-%d))" \
    --body-file "$alertes"
fi
rm -f "$alertes"
[ "$code" -le 1 ] || exit "$code"
