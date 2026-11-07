# US6 Rareté US
B (Titouan) · branche `lot/us-rarete` (créée par `scripts/lot.sh US6`) · étapes : E6 · travail d'une session seule : 2 à 4 j · lancé le 7 nov. (décision 8)

## But
Donner à chaque espèce américaine une rareté honnête, calculée par bassin versant à partir d'événements d'observation, avec repli et classe « donnée insuffisante ». Même idée que la rareté française, avec des données américaines.
Décisions du 7 nov. (`CLAUDE.md`) : 7 (modèle et données par région) et 2 (niveaux de couverture).

## Avant de commencer
- [ ] Le rapport rareté de `reports/us/` lu (sources, seuils, repli).
- [ ] `Packages/Core/Sources/Core/Rarete/` (France) lu sans y toucher.
- [ ] `outils/us/geo/` repéré (limites de bassins, produites par US4).

## Dossiers
- Permis : `Packages/Core/Sources/Core/RareteUS/`, `Packages/Core/Tests/CoreTests/RareteUS/`, `outils/us/rarete/`.
- Interdit : `Packages/Core/Sources/Core/Rarete/` (France), `outils/us/geo/` (US4), `App/`. Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- `outils/us/rarete/` produit un fichier fabriqué : fréquence par espèce et par bassin, nombre d'événements, niveau de repli utilisé.
- `RareteUS` lit ce fichier : classe de rareté, ou « donnée insuffisante » ; le repli est annoncé (« données de l'État »).
- Seuils par quantiles écrits dans un fichier, pas dans le code.
- Aucune rareté affichée sans nombre d'événements ; tests Linux.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US6), docs/atelier.md et docs/fiches/US6.md.
Travaille seulement dans : Packages/Core/Sources/Core/RareteUS/, Packages/Core/Tests/CoreTests/RareteUS/, outils/us/rarete/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd Packages/Core && swift test --filter RareteUS` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-rarete`. Test qui bloque : `cd Packages/Core && swift test --filter RareteUS` vert ; `cd outils/us/rarete && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : fréquences par bassin, repli sur le bassin plus large puis l'État annoncé, classe « donnée insuffisante » sous le seuil d'événements.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Une rareté trompeuse sur peu de données. Parade : seuil minimal d'événements, sinon « donnée insuffisante ».
- Biais d'observation (les espèces rares sont plus signalées). Parade : le dire dans la note de méthode du dossier.
- Mélanger la rareté française et américaine. Parade : fichiers et types séparés par région.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan ; en retard, un seul bassin pilote.
