# Données Hub'Eau (D2), calculées dans le cloud le 15 oct. 2026
Branche de transport, jamais fusionnée dans main. Le cloud ne peut pas créer de release GitHub.
Sur le Mac, depuis le dépôt :
    git fetch origin donnees/hubeau
    mkdir -p /tmp/d2 && git archive origin/donnees/hubeau | tar -x -C /tmp/d2
    gh release create donnees /tmp/d2/stations-especes.json /tmp/d2/rarete-departements.json /tmp/d2/stations-hydro.json --title "Données Hub'Eau" --notes "D2, France entière, 15 oct. 2026"
Puis scripts/donnees.sh (ajouter stations-hydro.json à sa liste s'il n'y est pas).
Comptes : 8 234 stations piscicoles (96 départements), 6 159 stations hydro, raretés pour 96 départements.
