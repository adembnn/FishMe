# US3 Règles US : double lecture et consensus
B (Titouan) · branche `lot/us-regles` (créée par `scripts/lot.sh US3`) · étapes : hors parcours · travail d'une session seule : 2 à 4 j · lancé le 7 nov. (décision 8)

## But
Lire les règles par espèce de chaque État par deux lectures indépendantes, les comparer comme `outils/regles/consensus.py` le fait pour la France, et ne retenir que ce qui concorde. Ce qui diverge reste « à vérifier ».
Décisions du 7 nov. (`CLAUDE.md`) : 3 (double lecture indépendante par État, comparée comme `consensus.py`, verdict à trois valeurs) et 2 (niveau 2, règles par espèce au niveau de l'État).

## Avant de commencer
- [ ] `outils/regles/consensus.py`, `outils/regles/brief-lecteur.md`, `outils/regles/consigne-departement.md` lus : le modèle à copier (sans le modifier).
- [ ] `reports/us/` sur la réglementation par État lu ; `CLAUDE.md`, décisions 2 et 3 du 7 nov.
- [ ] Le format de sortie de US1 repéré (ce que le dossier `RegionUS/` attend).

## Dossiers
- Permis : `outils/us/regles/`.
- Interdit : `outils/regles/` (la France, intact), `Packages/Core`, `outils/us/etats/` (US2), `App/`. Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- Deux lectures par État, produites par deux passages indépendants (consignes distinctes, sans que l'une voie l'autre) ; chaque lecture cite le passage source.
- `consensus_us.py` : accord exact sur la valeur → règle gardée avec source, date, lien agence ; désaccord ou lecture manquante → « à vérifier » et les deux lectures en pièce jointe du rapport.
- Sortie : seulement des verdicts « interdit », « à vérifier », « donnée absente » ; jamais « autorisé ».
- Fichier fabriqué : publié en pièce jointe de release privée, jamais dans git ; tests en stdlib dans le dossier.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US3), docs/atelier.md et docs/fiches/US3.md.
Travaille seulement dans : outils/us/regles/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd outils/us/regles && python3 -I -m unittest discover -s . -p 'test_*.py'` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-regles`. Test qui bloque : `cd outils/us/regles && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : deux lectures indépendantes d'une même règle sont comparées ; si elles divergent la règle sort en « à vérifier » avec les deux lectures gardées ; aucune règle sans source, date et lien agence ; aucun verdict autre que les trois valeurs.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Deux lectures qui se copient (même consigne, même modèle sans variation). Parade : consignes distinctes et test qui refuse deux lectures identiques octet pour octet venues du même fichier.
- Un consensus qui arrondit un désaccord (3 poissons contre 5). Parade : égalité stricte, sinon « à vérifier ».
- Une règle de pêche ancienne. Parade : la date de lecture et l'année du règlement sont obligatoires.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan ; en retard, traite d'abord les États du niveau 3 prévus (WI, MI, MN, CA) et laisse le reste « donnée absente ».
