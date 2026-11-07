# US4 Socle géographique US
B (Titouan) · branche `lot/us-geo` (créée par `scripts/lot.sh US4`) · étapes : hors parcours · travail d'une session seule : 2 à 4 j · lancé le 7 nov. (décision 8)

## But
Fabriquer le socle géographique américain : tracé de l'eau, aires publiques, accès, bassins versants, avis de santé de l'eau, avec source et licence pour chaque fichier. C'est le terrain sur lequel s'appuient la rareté (US6) et les conditions (US5).
Décisions du 7 nov. (`CLAUDE.md`) : 2 (niveau 3 : règles par plan d'eau où un jeu ouvert existe) et 8 (en parallèle).

## Avant de commencer
- [ ] Le rapport géographie et accès de `reports/us/` et `docs/donnees.md` lus (une ligne par fichier, avec sa licence).
- [ ] `outils/hubeau/` lu : même façon de fabriquer et de publier un fichier lourd.
- [ ] Place disque et temps de calcul estimés avant de lancer sur ta machine.

## Dossiers
- Permis : `outils/us/geo/`.
- Interdit : `Packages/Core`, `App/`, `outils/us/rarete/` (US6), `outils/us/etats/` (US2). Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- Chaque fichier : source, licence et obligation, date de téléchargement, dans `docs/donnees.md`.
- Géométries simplifiées pour l'app ; la version complète reste dans l'outil.
- Aucune donnée publiée telle quelle sans sa mention de source ; les fichiers fabriqués ne rentrent pas dans git.
- Tests en stdlib : formes, couverture par État, échantillon de contrôle.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US4), docs/atelier.md et docs/fiches/US4.md.
Travaille seulement dans : outils/us/geo/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd outils/us/geo && python3 -I -m unittest discover -s . -p 'test_*.py'` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-geo`. Test qui bloque : `cd outils/us/geo && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : chaque jeu de données a sa source, sa licence et sa date ; géométries valides ; un échantillon de plans d'eau connus tombe dans le bon État et le bon bassin ; avis EPA daté présent.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Données lourdes poussées par erreur dans git. Parade : `scripts/donnees.sh` et la règle des fichiers fabriqués.
- Une aire « publique » qui exclut l'accès réel à l'eau. Parade : le champ d'accès garde sa source, jamais « accès libre » sans elle.
- Licence mal lue. Parade : une ligne de `docs/donnees.md` par fichier avant de le publier.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan ; en retard, un seul État d'abord (WI), puis les autres.
