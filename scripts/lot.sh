#!/usr/bin/env bash
# Crée la copie de travail d'un lot : un second dossier du même dépôt (un « worktree » git),
# sur la branche du lot, avec les crochets de git branchés.
# Usage : scripts/lot.sh <code du lot>      par exemple : scripts/lot.sh L3
# La branche et les dossiers du lot viennent de docs/lots.md (via outils/atelier/lots.py), jamais d'ici.

racine=$(cd "$(dirname "$0")/.." && pwd)
outil="$racine/outils/atelier/lots.py"

if [ -z "${1:-}" ]; then
  echo "Usage : scripts/lot.sh <code du lot>   (par exemple : scripts/lot.sh L3)"
  echo "Lots :"
  python3 "$outil" liste
  exit 1
fi
code=$(printf '%s' "$1" | tr 'a-z' 'A-Z')
branche=$(python3 "$outil" branche-de "$code") || { echo "Lots :" >&2; python3 "$outil" liste >&2; exit 1; }

principal=$(git -C "$racine" worktree list --porcelain | sed -n '1s/^worktree //p')
[ -n "$principal" ] || { echo "✗ Ce dossier n'est pas un dépôt git." >&2; exit 1; }
minuscule=$(printf '%s' "$code" | tr 'A-Z' 'a-z')
dossier="$(dirname "$principal")/$(basename "$principal")-$minuscule"

git -C "$racine" fetch origin --quiet 2>/dev/null || echo "· pas de réseau (ou pas d'origin) : je pars de ce que j'ai sur cet ordinateur."

if [ -e "$dossier" ]; then
  actuelle=$(git -C "$dossier" symbolic-ref --short -q HEAD 2>/dev/null)
  if [ "$actuelle" != "$branche" ]; then
    echo "✗ Le dossier $dossier existe déjà mais n'est pas sur la branche $branche." >&2
    echo "  À faire : déplace-le ou supprime-le, puis relance scripts/lot.sh $code." >&2
    exit 1
  fi
  echo "Le lot $code est déjà prêt."
else
  if git -C "$racine" show-ref --verify --quiet "refs/heads/$branche"; then
    git -C "$racine" worktree add "$dossier" "$branche" || exit 1
  else
    if git -C "$racine" show-ref --verify --quiet "refs/remotes/origin/$branche"; then
      depart="origin/$branche"
    elif git -C "$racine" show-ref --verify --quiet "refs/remotes/origin/main"; then
      depart="origin/main"
    else
      depart="HEAD"
    fi
    git -C "$racine" worktree add --no-track -b "$branche" "$dossier" "$depart" || exit 1
  fi
fi

# Les crochets de git (dossier .githooks) valent pour toutes les copies du dépôt.
git -C "$racine" config core.hooksPath .githooks

echo
echo "✓ Lot $code prêt, sur la branche $branche."
echo "Les 2 commandes suivantes :"
echo "  cd \"$dossier\""
echo "  claude"
