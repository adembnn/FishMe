# US5 Conditions US : proxy, unités, fuseaux
B (Titouan) · branche `lot/us-conditions` (créée par `scripts/lot.sh US5`) · étapes : E2 E6 · travail d'une session seule : 2 à 4 j · lancé le 7 nov. (décision 8)

## But
Lire les conditions américaines (débit et niveau des cours d'eau, prévisions, météo) pour la région US : un proxy avec cache qui garde la clé, et un module `ConditionsUS` dans `Core` qui traduit en unités et fuseaux américains.
Décisions du 7 nov. (`CLAUDE.md`) : 7 (conditions, langue et unités par région) et 5 (WeatherKit réactivé sur le compte de Titouan : jamais de clé dans le dépôt).

## Avant de commencer
- [ ] Le rapport conditions de `reports/us/` lu (services, limites d'appel, licences).
- [ ] `Packages/Core/Sources/Core/Conditions/` (France) lu pour copier la forme, sans y toucher.
- [ ] Aucune clé dans le chat ni dans git : `.env` est créé par Titouan lui-même.

## Dossiers
- Permis : `Packages/Core/Sources/Core/ConditionsUS/`, `Packages/Core/Tests/CoreTests/ConditionsUS/`, `outils/us/proxy/`.
- Interdit : `Packages/Core/Sources/Core/Conditions/` (France), `App/Conditions/`, `.env`, `outils/us/geo/` (US4). Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- Le proxy lit la clé dans l'environnement ; la réponse au client ne la contient jamais ; cache avec durée de vie par service.
- `ConditionsUS` : un modèle `Core` avec unité (ft³/s, pieds, °F, mph) et fuseau de la station ; l'heure se lit dans le fuseau du lieu, pas celui de l'iPhone.
- Panne d'un service : « donnée absente », jamais une valeur fabriquée.
- Aucun appel réseau dans `Core` ; il reçoit des données déjà lues. Tests Linux sans réseau.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US5), docs/atelier.md et docs/fiches/US5.md.
Travaille seulement dans : Packages/Core/Sources/Core/ConditionsUS/, Packages/Core/Tests/CoreTests/ConditionsUS/, outils/us/proxy/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd Packages/Core && swift test --filter ConditionsUS` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-conditions`. Test qui bloque : `cd Packages/Core && swift test --filter ConditionsUS` vert ; `cd outils/us/proxy && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : le proxy met en cache, ne renvoie jamais la clé, applique le fuseau de la station, convertit les unités.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- La clé qui part dans une réponse ou un journal. Parade : test qui cherche la clé dans toute sortie.
- Un fuseau mal choisi (un lac à cheval sur deux fuseaux). Parade : fuseau de la station, test sur trois États.
- Des unités mélangées dans un même écran. Parade : conversion unique dans `Core`.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan (la clé ou le service) ; en retard, un seul service (niveau d'eau) d'abord.
