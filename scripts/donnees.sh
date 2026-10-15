#!/usr/bin/env bash
# Télécharge les 3 fichiers de données fabriqués par script, depuis la release privée « donnees » du dépôt.
# Ils ne sont jamais commités (.gitignore, crochets de git) : chaque ordinateur les télécharge ici.
# Usage : scripts/donnees.sh        (demande `gh` installé et connecté : gh auth login)

racine=$(cd "$(dirname "$0")/.." && pwd)
cd "$racine" || exit 1
# Dans App/Donnees/ (ignoré par git) : le dossier synchronisé de l'app les embarque, RootView passe Bundle.main à Core.
dossier="App/Donnees"
fichiers="stations-especes.json rarete-departements.json stations-hydro.json"

if ! command -v gh >/dev/null 2>&1; then
  echo "✗ L'outil « gh » (GitHub) n'est pas installé. À faire : brew install gh, puis gh auth login." >&2
  exit 1
fi

if ! erreur=$(gh release view donnees 2>&1 >/dev/null); then
  if printf '%s' "$erreur" | grep -qi "not found"; then
    echo "✗ Il n'y a pas encore de release « donnees » sur GitHub : le lot D2 ne l'a pas publiée." >&2
    echo "  Rien à télécharger. À faire : demande à la personne qui tient D2 de publier les 2 fichiers en pièces jointes d'une release privée nommée « donnees »." >&2
  else
    echo "✗ Impossible de lire la release « donnees » : $erreur" >&2
    echo "  À faire : vérifie que tu es connecté (gh auth login) et que tu as accès au dépôt." >&2
  fi
  exit 1
fi

mkdir -p "$dossier"
args=""
for f in $fichiers; do args="$args --pattern $f"; done
# shellcheck disable=SC2086
if ! gh release download donnees $args --dir "$dossier" --clobber; then
  echo "✗ Le téléchargement a échoué." >&2
  exit 1
fi

manque=0
for f in $fichiers; do
  if [ -s "$dossier/$f" ]; then
    echo "✓ $dossier/$f"
  else
    echo "✗ $f n'est pas dans la release « donnees »." >&2
    manque=1
  fi
done
exit "$manque"
