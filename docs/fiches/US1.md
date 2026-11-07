# US1 Région US : modèle de règles, verdict à trois valeurs, unités
B (Titouan) · branche `lot/us-core` (créée par `scripts/lot.sh US1`) · étapes : hors parcours · travail d'une session seule : 1 à 2 j · lancé le 7 nov. (décision 8)

## But
Donner à `Core` le modèle de règles américaines : une règle par État (puis par plan d'eau), un verdict à trois valeurs, une source, une date, le lien de l'agence, et les unités américaines. Rien d'écran, rien de réseau : du Swift testé sous Linux.
Décisions du 7 nov. (`CLAUDE.md`) : 3 (verdict à trois valeurs, jamais « tu peux la garder » ni « autorisé », lien de l'agence, source et date toujours affichés) et 7 (région vient de la position et des réglages, unités par région).

## Avant de commencer
- [ ] `Packages/Core/Sources/Core/Modele/Controle.swift` et `Packages/Core/Sources/Core/Regions/` lus : comment la France est modélisée aujourd'hui.
- [ ] `reports/us/synthese.md` (décision 2, trois niveaux) et `CLAUDE.md` (décisions 2, 3, 7 du 7 nov.) lus.
- [ ] `swift test` vert dans `Packages/Core` avant ta première ligne.

## Dossiers
- Permis : `Packages/Core/Sources/Core/RegionUS/`, `Packages/Core/Tests/CoreTests/RegionUS/`.
- Interdit : `outils/` (US2 à US9), `App/`, `Widget/`, les autres sous-dossiers de `Packages/Core` (rien à y changer ; si un contrat manque, demande-le à Titouan). Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- Un `VerdictUS` à trois cas, sans quatrième : « interdit », « à vérifier », « donnée absente ». Aucun cas « autorisé » ni « permis » ; ce qui n'est pas interdit est « à vérifier ».
- Chaque règle porte : État, espèce, valeur, `source` (texte), `lienAgence` (URL https), `date` de lecture ; sans ces champs elle ne se construit pas.
- Niveaux 1, 2, 3 de la décision 2 comme valeur (`niveau`) ; le niveau 1 ne donne jamais autre chose que « à vérifier ».
- Unités : `Longueur`, `Poids`, `Temperature`, `Distance` avec conversion exacte et arrondi documenté ; la région (`FR` ou `US`) choisit l'unité d'affichage, `Core` stocke en métrique.
- `Core` n'importe que Foundation ; aucune règle d'État dans le code, tout vient de données fournies par US2 et US3.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US1), docs/atelier.md et docs/fiches/US1.md.
Travaille seulement dans : Packages/Core/Sources/Core/RegionUS/, Packages/Core/Tests/CoreTests/RegionUS/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd Packages/Core && swift test --filter RegionUS` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-core`. Test qui bloque : `cd Packages/Core && swift test --filter RegionUS` vert, puis `swift test` complet vert sous Linux (`scripts/cloud-pret.sh`) ; un test énumère les cas du verdict et en trouve exactement trois (« interdit », « à vérifier », « donnée absente ») ; un autre vérifie les conversions d'unités (pouces et centimètres, livres et kilos, °F et °C, miles et kilomètres) dans les deux sens.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Un « autorisé » qui se glisse dans un nom de cas ou un texte. Parade : test qui parcourt `allCases` et `grep -rniE "autorisé|allowed|legal" Packages/Core/Sources/Core/RegionUS` vide.
- Le verdict qui dépend de l'unité (55 cm contre 21,65 pouces). Parade : comparer en métrique, afficher en unité de la région.
- Un modèle qui ne sait représenter que la France. Parade : le test du niveau 1 et un État fictif.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan (le contrat qui manque dans `Core`) ; en retard, livre le verdict à trois valeurs et les unités d'abord, les niveaux ensuite.
