---
name: point
description: "Point d'étape en 3 lignes : ce qui est fait avec la preuve, ce qui change le plan, la recommandation (continuer ou arrêter). À lancer dès le premier résultat concret, puis à chaque lot terminé."
allowed-tools: Read Grep Glob Bash(git branch*) Bash(git status*) Bash(git log*) Bash(git diff*) Bash(python3 outils/atelier/lots.py*) Bash(scripts/verif.sh*)
---

# /point : trois lignes, avec la preuve

Branche courante : !`git branch --show-current`

Un point d'étape est court. Il ne raconte pas la séance : il dit où on en est, avec une preuve.

## 1. Rassembler les faits
1. Lance `python3 outils/atelier/lots.py lot <la branche>` : le code du lot (rien si la branche n'est pas un lot). Si c'est un lot, retrouve son test « fini » dans `python3 outils/atelier/lots.py json` et dans sa fiche `docs/fiches/<code>.md`.
2. Lance `git log --oneline origin/main..HEAD` (ce qui est enregistré dans ce lot) et `git status --short` (ce qui ne l'est pas encore).
3. Lance `scripts/verif.sh --rapide`. Garde ses lignes ✓ / ✗ / · telles quelles. S'il ne peut pas tourner (script absent, pas de Mac), la preuve est « non vérifié », et tu dis pourquoi.

## 2. Écrire les trois lignes
Exactement trois lignes, puis dessous le bloc « Preuve ».

```
Fait : <ce qui marche, avec la commande lancée et son résultat ; ou « non vérifié »>
Change le plan : <ce que cela change : une étape qui sort du lot, une porte qui saute, un blocage ; ou « rien »>
Recommandation : <continuer ou arrêter, et la raison en une phrase>

Preuve :
<les lignes ✓ / ✗ / · de scripts/verif.sh --rapide, collées sans les résumer>
```

## 3. Règles
- Tu n'écris jamais « fini », « ça marche » ou « testé » sans coller la sortie de la commande qui le prouve. Une estimation n'est pas une mesure : écris « estimation » quand c'en est une.
- « Non vérifié » veut dire « non fusionné ». Dis-le si c'est le cas.
- Si la recommandation est « arrêter », dis ce qui arrête (un lot qui échoue à sa vérification, un plan à changer, une décision qui revient à la personne : design, produit, périmètre, argent, fournisseur).
- Si une décision revient à la personne, pose-la après le point, avec ta recommandation et un choix par défaut si elle ne répond pas. Au plus 3 questions à la fois, numérotées, avec des options lettrées.
- Tu ne rappelles aucune échéance et tu n'inventes aucune contrainte d'horaire.
