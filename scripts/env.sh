#!/usr/bin/env bash
# Crée ou complète `.env` avec les noms de `env.exemple`, valeurs vides, puis l'ouvre dans ton éditeur.
# Ne lit jamais une valeur et n'affiche rien de `.env` : seuls les noms manquants sont ajoutés.
# Usage : scripts/env.sh            (ATELIER_SANS_EDITEUR=1 : ne pas ouvrir l'éditeur)

racine=$(cd "$(dirname "$0")/.." && pwd)
cd "$racine" || exit 1
[ -f env.exemple ] || { echo "✗ env.exemple est absent : rien à recopier." >&2; exit 1; }

umask 077
touch .env
chmod 600 .env
ajoutes=0
while IFS= read -r ligne || [ -n "$ligne" ]; do
  case "$ligne" in ''|\#*) continue ;; esac
  nom=${ligne%%=*}
  if ! grep -q "^${nom}=" .env; then
    printf '%s=\n' "$nom" >> .env
    ajoutes=$((ajoutes + 1))
  fi
done < env.exemple
echo "✓ .env prêt ($ajoutes nom(s) ajouté(s), valeurs vides). Il est dans .gitignore."

if [ "${ATELIER_SANS_EDITEUR:-}" != "1" ]; then
  if command -v code >/dev/null 2>&1; then code .env
  elif [ "$(uname)" = "Darwin" ]; then open -e .env
  else echo "Ouvre .env dans ton éditeur."
  fi
fi
echo "À faire : remplis .env toi-même, puis dis à Claude « c'est fait ». Ne colle jamais une clé dans un chat."
