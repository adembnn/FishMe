# US7 Espèces US
B (Titouan) · branche `lot/us-especes` (créée par `scripts/lot.sh US7`) · étapes : hors parcours · travail d'une session seule : 1 à 2 j · lancé le 7 nov. (décision 8)

## But
Établir la liste des espèces pêchables aux États-Unis, avec noms scientifique et anglais et identifiants de taxon, qui alimente règles (US3), rareté (US6) et reconnaissance (US8).
Décisions du 7 nov. (`CLAUDE.md`) : 1 (plusieurs États, puis tous) et 7 (données par région).

## Avant de commencer
- [ ] `Packages/Core/Sources/Core/Especes/` et le fichier d'espèces français lus : la forme à respecter.
- [ ] Le rapport espèces et photos de `reports/us/` lu.
- [ ] `docs/donnees.md` lu : source et licence de chaque fichier.

## Dossiers
- Permis : `outils/us/especes/`.
- Interdit : `Packages/Core`, `outils/especes` ou fichiers français, `App/`. Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- `especes-us.json` : nom scientifique, nom anglais, famille, identifiants de taxon (sources citées), eau douce ou salée, source.
- Aucun nom de marque dans les champs ; aucun doublon ; chaque nom scientifique est accepté par sa source.
- Fichier fabriqué : publié en pièce jointe de release privée, jamais dans git.
- Tests en stdlib dans le dossier.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US7), docs/atelier.md et docs/fiches/US7.md.
Travaille seulement dans : outils/us/especes/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd outils/us/especes && python3 -I -m unittest discover -s . -p 'test_*.py'` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-especes`. Test qui bloque : `cd outils/us/especes && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : chaque espèce a un nom scientifique, un nom courant en anglais, un identifiant de taxon, aucun doublon, et la liste couvre les espèces visées par l'App.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Une même espèce sous deux noms. Parade : clé = nom scientifique, test d'unicité.
- Espèces hybrides ou sous-espèces. Parade : champ `rang`, décision écrite dans le dossier.
- Noms régionaux contradictoires. Parade : un seul nom courant, les autres en alias.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan ; en retard, la liste des espèces d'eau douce d'abord.
