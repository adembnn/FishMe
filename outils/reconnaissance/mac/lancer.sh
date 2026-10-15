#!/bin/bash
# NON EXÉCUTÉ (sans Mac). Une commande sur le Mac : bash lancer.sh <jeu-prepare> [sortie]
# Entraîne Create ML, écrit le journal du test, puis passe l'examen d'acceptation (code 0 = le modèle passe).
set -e
JEU="${1:?dossier jeu-prepare (train/ val/ test/)}"
SORTIE="${2:-$JEU/../sortie}"
ICI="$(cd "$(dirname "$0")" && pwd)"
swift "$ICI/entrainer.swift" "$JEU" "$SORTIE"
python3 -I "$ICI/../examen.py" --journal "$SORTIE/journal-createml.csv" --modele "$SORTIE/Poissons.mlmodel" --sortie "$SORTIE"
