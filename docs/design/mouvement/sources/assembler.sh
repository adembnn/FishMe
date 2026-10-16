#!/bin/bash
# Assemble la page unique : coque + assets + sons + animations + moteur de page.
cd "$(dirname "$0")"
{
  cat coque.html
  for f in assets.js sons.js anim-lancement.js anim-arrivee-a.js anim-arrivee-b.js anim-attente.js page.js; do
    if [ -f "$f" ]; then printf '<script>\n/* %s */\n' "$f"; sed 's#</script#<\\/script#g' "$f"; printf '\n</script>\n'; fi
  done
} > fishme-en-mouvement.html
ls -la fishme-en-mouvement.html
