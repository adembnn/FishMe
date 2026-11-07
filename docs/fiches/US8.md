# US8 Reconnaissance US
B (Titouan) · branche `lot/us-reco` (créée par `scripts/lot.sh US8`) · étapes : E5 · travail d'une session seule : 3 à 6 j · lancé le 7 nov. (décision 8)

## But
Préparer l'entraînement et l'examen de la reconnaissance pour les espèces américaines : jeu de photos avec licence enregistrée, séparation par observateur, examen comme `outils/reconnaissance/`. Ne publie ni ne vend aucune photo.
Décisions du 7 nov. (`CLAUDE.md`) : 4 (photos d'entraînement US, y compris non libres, jamais publiées ni vendues, licence de chaque photo enregistrée ; risque iNaturalist assumé par Titouan, avis écrit recommandé avant toute publication du modèle).

## Avant de commencer
- [ ] `outils/reconnaissance/EXAMEN.md`, `preparer_jeu.py`, `examen.py` lus (le modèle à suivre, sans les modifier).
- [ ] `CLAUDE.md`, décision 4 du 7 nov. et décision du 15 oct. sur les photos lus.
- [ ] `outils/us/especes/` repéré (US7).

## Dossiers
- Permis : `outils/us/reconnaissance/`.
- Interdit : `outils/reconnaissance/` (R1), `App/`, `Packages/Core`, tout dépôt de photos. Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- Chaque photo : fichier, espèce, observateur, source, licence ; une photo sans licence est écartée.
- Aucune photo ni aucun jeu dans git ; ils restent sur la machine de Titouan.
- Séparation entraînement et test par observateur (jamais le même observateur des deux côtés).
- Aucune phrase qui affirme que les conditions d'iNaturalist l'autorisent ; le risque est écrit dans le dossier, avis écrit recommandé avant publication.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US8), docs/atelier.md et docs/fiches/US8.md.
Travaille seulement dans : outils/us/reconnaissance/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd outils/us/reconnaissance && python3 -I -m unittest discover -s . -p 'test_*.py'` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-reco`. Test qui bloque : `cd outils/us/reconnaissance && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : chaque photo d'entraînement a sa licence enregistrée avec elle, un jeu sans licence est refusé, aucune photo n'est dans git, et le script d'examen sépare les observateurs entre entraînement et test.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Des photos des mêmes observateurs des deux côtés : examen trop beau. Parade : test de séparation.
- Une photo publiée dans un rapport. Parade : seul un identifiant et une licence sortent.
- Dire que l'entraînement est permis. Parade : la réserve de la décision 4 recopiée.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan ; en retard, 6 espèces d'abord.
