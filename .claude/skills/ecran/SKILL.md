---
name: ecran
description: "Montre l'app à l'écran, sur Mac seulement : lance testeur-ecran sur les étapes E du lot courant (ou celles qu'on lui donne), prend une capture par étape dans reports/ecrans/<lot>/ et dit pour chaque étape vu ou pas vu."
argument-hint: "[étapes, ex. E5 E6]"
allowed-tools: Read Glob Bash(git branch*) Bash(python3 outils/atelier/lots.py*) Bash(uname*) Bash(ls*)
---

# /ecran : voir l'app tourner

Système : !`uname -s`
Branche courante : !`git branch --show-current`
Étapes demandées par la personne : $ARGUMENTS (vide = les étapes du lot)

Tu parles à une personne débutante. Phrases courtes, un terme technique expliqué entre parenthèses la première fois. Tu ne corriges rien dans cette commande : tu constates.

## 1. Un Mac est nécessaire
Si le système ci-dessus n'est pas `Darwin`, tu n'es pas sur un Mac. Dis : « Je ne peux pas montrer l'écran ici : le simulateur d'iPhone n'existe que sur Mac, et rien n'a été testé. » Rappelle ce qui se teste sans Mac (`scripts/verif.sh --rapide`, ou `/fusion`) et arrête-toi. N'appelle pas l'agent.

## 2. Quelles étapes, pour quel lot ?
1. Lance `python3 outils/atelier/lots.py lot <la branche>` pour le code du lot, puis `python3 outils/atelier/lots.py json` pour ses étapes.
2. Si la personne a donné des étapes, prends-les. Sinon prends celles du lot. Si le lot dit « toutes », prends celles de la version soumise jeudi : E1, E2, E5, E6, E7, E9.
3. Si la branche n'est pas une branche de lot et qu'aucune étape n'est donnée, demande lesquelles (une question, avec un choix par défaut : E1 E2). Le dossier des captures s'appelle alors `reports/ecrans/essai/`.

## 3. Lancer le testeur
Fais un appel à l'outil Agent (il s'appelait Task dans les anciennes versions) : `subagent_type` est `testeur-ecran`, `model` est `sonnet`. Prompt :

```
Lot <code>, branche <branche>. Étapes à voir : <E…>. Captures dans reports/ecrans/<code>/. Build Debug, faux services. Rends le tableau de ton fichier.
```

## 4. Ne pas le croire sur parole
Quand il répond :
1. `ls reports/ecrans/<code>/` : chaque capture citée existe.
2. Ouvre chaque capture avec Read (tu la vois) et dis en une phrase ce qu'elle montre. Si une capture ne montre pas ce que l'agent dit avoir vu, change son « vu » en « pas vu » et dis pourquoi.
3. Donne le tableau final (étape, vu ou pas vu, ce que l'écran affichait, nom de la capture) et le dossier des captures. Sur Mac, la personne peut l'ouvrir avec `open reports/ecrans/<code>/`.

## 5. Ce que tu ne dis pas
- Jamais « l'étape marche » : dis « vue dans le simulateur ». Une étape est finie quand son test passe sur l'iPhone de test (`docs/parcours-demo.md`).
- Pour chaque étape « pas vu », reprends la raison de l'agent et dis si elle vient du simulateur (caméra, mode avion, écran verrouillé) ou de l'app. Dans le premier cas, la suite est de l'essayer sur l'iPhone ; dans le second, propose de corriger, sans coder avant le « ok ».
