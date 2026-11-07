# Règles américaines : lecture IA en double (niveaux 2 et 3)

Même principe qu'en France (`outils/regles/`) : deux lectures indépendantes d'un texte d'agence, comparées sur le fond ; seules les règles confirmées par les deux sont chargées. Le reste est « à vérifier ». Le verdict a trois valeurs : `interdit`, `a_verifier`, `donnee_absente`. Jamais de verdict permissif.

## Qui lit quoi, avec quel outil
1. **Collecte** : sur la machine de Titouan, télécharger le PDF ou la page de l'agence dans `corpus/<ETAT>/` (URL, édition et date notées). Rien n'est téléchargé par ce lot.
2. **Lecteur A** et **lecteur B** : deux sessions Claude distinctes, chacune avec `consigne-lecture.md`, sans jamais ouvrir le fichier de l'autre. A écrit `lecture-a/<ETAT>.json`, B écrit `lecture-b/<ETAT>.json`.
3. **Contrôle** : `python3 -I outils/us/regles/verifier_us.py lecture-a/<ETAT>.json` (idem pour B). Il vérifie le schéma, la source (URL https, date), la citation (200 caractères au plus) et l'absence de mots interdits dans les champs libres. `--prod` refuse un exemple FIXTURE.
4. **Consensus** : `python3 -I outils/us/regles/consensus_us.py <ETAT> --json` écrit `consensus/<ETAT>.json` avec `regles` (confirmées, sans réserve), `incertaines` et `a_verifier` (seulement A, seulement B). Il refuse de tourner si un fichier est invalide ou si les deux lectures portent le même lecteur.

Niveau 2 : règle par espèce pour l'État (ou une zone). Niveau 3 : règle d'un plan d'eau ou d'un tronçon, lue sur le jeu ouvert de l'État (WI, MI, MN, CA…).

## Ce que le consensus compare
Type, espèce, dates (années ignorées : 12-01 au 03-15 vaut 2025-12-01 au 2026-03-15), nombres convertis en pouces et en livres (38 cm = 15 pouces), code d'engin ou d'appât, portée (nom d'eau normalisé : « St. » = Saint, sans Lake/River/Creek, comté, lac distinct de rivière). Les citations ne sont pas comparées. Limite connue : pour un appât ou un engin, seul le `code` court tranche.

## Où vont les fichiers
- Versionnés : ce dossier, `consensus/<ETAT>.json` après vérification, `fixtures/`.
- Restent sur la machine de Titouan (`.gitignore` local) : `corpus/`, `lecture-a/`, `lecture-b/`, `tmp/`.
- `REGLES_US_DIR` change le dossier des lectures.

## Tests
Depuis la racine du dépôt : `python3 -I -m unittest discover -s outils/us/regles -p "test_*.py"`.
`fixtures/ZZ-*.json` : exemple factice (État « ZZ », URL `example.invalid`), marqué FIXTURE, jamais chargé dans l'app.

## Reste à faire
Chargement de `consensus/` dans le Core (lot us-core), relecture d'un échantillon par une personne, avis juridique américain (`reports/us/synthese.md`).
