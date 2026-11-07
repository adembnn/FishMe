# US9 Localisation US : langue et unités
B (Titouan) · branche `lot/us-i18n` (créée par `scripts/lot.sh US9`) · étapes : hors parcours · travail d'une session seule : 1 à 3 j · lancé le 7 nov. (décision 8)

## But
Préparer la langue anglaise et les formats américains (dates, unités, vocabulaire de pêche) comme tables et vérifications, pour que les lots d'écrans les branchent. Ce lot n'écrit aucun fichier de l'app.
Décisions du 7 nov. (`CLAUDE.md`) : 7 (langue et unités par région) et 3 (aucun mot de permission : ni « legal » ni « allowed »).

## Avant de commencer
- [ ] `docs/banc/mots-interdits.md` et `reports/us/` sur la localisation lus.
- [ ] La liste des textes français de l'app repérée (sans modifier `App/`).
- [ ] `outils/us/` : formes de US1 repérées pour les unités.

## Dossiers
- Permis : `outils/us/i18n/`, `reports/us/i18n/`.
- Interdit : `App/` (chaque écran a son lot), `Packages/Core`, `Localizable.xcstrings`. Tout le reste du dépôt, y compris les dossiers des autres lots du 7 nov. (W1, US1 à US9, C1, F2, M2, H3).

## Contrat
- Table des textes anglais par clé, avec contexte ; un vérificateur compare les clés avec le français.
- Vocabulaire interdit contrôlé : « legal », « allowed », « you can keep it ».
- Formats : dates mois/jour/année, 12 h, pouces, livres, °F.
- Rapports de relecture dans `reports/us/i18n/`.

## Consigne à coller dans Claude Code
```text
Je suis débutant. Lis CLAUDE.md (« Décisions du 7 nov. »), docs/lots.md (ligne US9), docs/atelier.md et docs/fiches/US9.md.
Travaille seulement dans : outils/us/i18n/, reports/us/i18n/. Fais un plan de 4 lignes et attends mon « ok ».
Construis par petits morceaux, un agent par morceau indépendant, avec un test par morceau. Une phrase après chaque fichier pour m'expliquer.
À la fin, lance `cd outils/us/i18n && python3 -I -m unittest discover -s . -p 'test_*.py'` et colle la sortie complète.
```

## Test « fini »
Commande de fusion : `scripts/fusionner.sh lot/us-i18n`. Test qui bloque : `cd outils/us/i18n && python3 -I -m unittest discover -s . -p 'test_*.py'` vert : chaque clé de texte française a son équivalent anglais, aucun texte anglais ne contient « legal », « allowed » ou « you can keep it », les formats de date et d'unité suivent la région.
Puis `git diff --name-only fishme-tout` ne montre que les dossiers permis.

## Pièges
- Traduire littéralement « autorisé » par « allowed ». Parade : le vérificateur le refuse.
- Des unités changées sans changer le verdict. Parade : voir US1, comparaison en métrique.
- Toucher `App/`. Parade : produire des tables, demander le branchement au lot propriétaire de l'écran.

## Si ça coince
- Après 20 min : message de 3 lignes à Titouan ; en retard, les textes de la carte et de la prise d'abord.
