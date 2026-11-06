# D2B Hub'Eau température (D2 bis)
S · branche `lot/hubeau-temperature` (créée par `scripts/lot.sh D2B`) · étapes : E2 E6 · 2 à 3 h

> **Fiche à compléter.** Elle a été écrite le 27 oct. à partir de la seule ligne du lot dans `docs/lots.md`, pour que la vérification des documents passe. Les décisions de produit et les critères d'acceptation ne sont écrits nulle part : ils sont marqués « à décider » plus bas et doivent être remplis par Adem ou par l'auteur du lot (Titouan) avant que le lot démarre.

## But
Hub'Eau température (D2 bis). Le détail du besoin est **à décider** (voir « Contrat »).

## Avant de commencer
- [ ] `main` à jour ; `scripts/verif.sh` lancé une fois sur `main`.
- [ ] Ce dont le lot dépend est fait : rien.
- [ ] Les décisions d'Adem de cette fiche (section « Contrat ») sont écrites : tant qu'elles ne le sont pas, le lot ne démarre pas.

## Dossiers
- Permis :
- `outils/hubeau-temperature/`
- Interdit : tout le reste du dépôt, y compris `docs/lots.md` et les dossiers des autres lots.

## Contrat
- **À décider (Adem ou l'auteur du lot)** : ce que le lot livre exactement, point par point, avec des critères d'acceptation vérifiables.
- Le test de la colonne « Test qui bloque la fusion » de `docs/lots.md` : fichier `stations-temperature.json` (stations de température de Hub'Eau en service, France entière) fabriqué par un script de ce dossier ; demandé par `docs/fiches/N3.md`.
- Aucun lieu exact ni donnée personnelle n'est écrit ou envoyé hors de l'iPhone sans décision écrite d'Adem.

## Consigne à coller dans Claude Code
```text
Je suis Adem. Lis CLAUDE.md, docs/lots.md (ligne D2B) et docs/fiches/D2B.md.
Si la section « Contrat » de la fiche contient encore « À décider », arrête-toi et demande-moi les décisions : n'en invente aucune.
Sinon, travaille seulement dans les dossiers permis de la fiche, un commit par étape terminée, et à la fin lance
scripts/verif.sh complet et colle la sortie entière.
```

## Test « fini »
fichier `stations-temperature.json` (stations de température de Hub'Eau en service, France entière) fabriqué par un script de ce dossier ; demandé par `docs/fiches/N3.md`.
Puis `scripts/verif.sh` complet vert, et `git diff --name-only main` ne montre que les dossiers permis.

## Pièges
- Démarrer sans que le « Contrat » soit rempli : le lot construirait des décisions de produit que personne n'a prises. Parade : la consigne ci-dessus s'arrête.
- Sortir des dossiers permis : la fusion refuse (`scripts/fusionner.sh`).

## Si ça coince
- Après 20 min : message de 3 lignes à Adem ; toute décision de produit, de design ou de périmètre lui revient.
