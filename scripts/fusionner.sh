#!/usr/bin/env bash
# Fusionne le lot courant dans main : le seul chemin vers main.
# Usage : scripts/fusionner.sh [lot/<nom>]   (depuis la copie de travail d'un lot, créée par scripts/lot.sh ;
#         la branche en argument est facultative et doit être la branche courante)
# Étapes : arbre propre, origin/main fusionné dans ta branche (merge, jamais rebase), contrôle des dossiers,
# scripts/verif.sh complet, puis envoi vers main et vers la branche du lot.

racine=$(cd "$(dirname "$0")/.." && pwd)
cd "$racine" || exit 1
outil="outils/atelier/lots.py"

echec() { echo "✗ $*" >&2; exit 1; }

branche=$(git symbolic-ref --short -q HEAD)
code=$(python3 "$outil" lot "$branche" 2>/dev/null)
if [ -n "${1:-}" ] && [ "$1" != "$branche" ]; then
  echec "Tu demandes de fusionner $1, mais ce dossier est sur « ${branche:-une tête détachée} ». À faire : va dans la copie de travail de $1 (scripts/lot.sh <code> l'affiche), puis relance."
fi
[ -n "$code" ] || echec "Tu es sur « ${branche:-une tête détachée} », qui n'est la branche d'aucun lot. À faire : scripts/lot.sh <code>, puis lance fusionner.sh depuis le dossier qu'il affiche."

# 1. Arbre propre
sale=$(git status --porcelain)
if [ -n "$sale" ]; then
  printf '%s\n' "$sale" | head -n 20 | sed 's/^/    /' >&2
  echec "Il reste des changements non commités (liste ci-dessus). À faire : commite-les (un commit par lot terminé), puis relance."
fi

# 2. origin/main dans la branche (merge)
git fetch origin || echec "git fetch a échoué : pas de réseau, ou pas d'origin. À faire : vérifie ta connexion, puis relance."
git rev-parse -q --verify refs/remotes/origin/main >/dev/null \
  || echec "origin/main n'existe pas encore. À faire, une seule fois (A) : ATELIER_FUSION=1 git push origin claude/project-thread-78e20q:main, puis relance."
if ! git merge --no-edit origin/main; then
  echo "✗ Conflit en fusionnant origin/main dans $branche. Fichiers en conflit :" >&2
  git diff --name-only --diff-filter=U | sed 's/^/    /' >&2
  echo "  À faire : règle chaque conflit (Claude peut le faire), puis git add et git commit, puis relance scripts/fusionner.sh." >&2
  echo "  Pour tout annuler : git merge --abort" >&2
  exit 1
fi

# 3. Le diff avec origin/main ne touche que les dossiers du lot
hors=$(git -c core.quotepath=off diff --name-only --no-renames origin/main HEAD | python3 "$outil" hors-lot "$code")
if [ -n "$hors" ]; then
  echo "✗ Ces fichiers sortent des dossiers du lot $code (fichier, puis lot qui le possède) :" >&2
  printf '%s\n' "$hors" | sed 's/^/    /' >&2
  echec "Rien n'est envoyé. À faire : remets chaque fichier comme dans main (git checkout origin/main -- <fichier>, ou git rm <fichier> si tu l'as créé), commite, puis relance."
fi
echo "✓ Dossiers : le diff avec origin/main reste dans le lot $code."

# 4. Vérification complète
copie=$(mktemp "${TMPDIR:-/tmp}/fusion.XXXXXX")
trap 'rm -f "$copie"' EXIT
bash scripts/verif.sh 2>&1 | tee "$copie"
[ "${PIPESTATUS[0]}" -eq 0 ] || echec "scripts/verif.sh est rouge : rien n'est envoyé. À faire : corrige ce qui est marqué ✗, commite, puis relance."
resume=$(grep '^verif :' "$copie" | tail -n 1)

# 5. Envoi vers main (ATELIER_FUSION=1 est le laissez-passer du crochet pre-push), puis vers la branche du lot
nb=$(git diff --name-only --no-renames origin/main HEAD | grep -c .)
if ! envoi=$(ATELIER_FUSION=1 git push origin HEAD:main 2>&1); then
  printf '%s\n' "$envoi" | tail -n 15 >&2
  if printf '%s' "$envoi" | grep -qiE 'non-fast-forward|fetch first|rejected'; then
    echec "Quelqu'un a fusionné dans main entre-temps. Relance scripts/fusionner.sh : il reprendra la dernière version de main."
  fi
  echec "L'envoi vers main a échoué (message ci-dessus)."
fi
git push origin "$branche" >/dev/null 2>&1 \
  || echo "· main est à jour, mais la branche $branche n'a pas pu être envoyée. Sans gravité : relance git push origin $branche."

echo
echo "Fusionné : le lot $code ($nb fichier(s)) est dans main, au commit $(git rev-parse --short HEAD)."
echo "Vérification : $resume"
echo "Suite : les autres lots te récupèrent avec « git fetch && git merge origin/main » ; passe à ta prochaine fiche dans docs/fiches/."
