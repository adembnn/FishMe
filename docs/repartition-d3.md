# D3 : qui fait quels départements (15 oct. 2026, décision d'Adem)

> **Message de Titouan** pour Adem et Sullyvan, écrit par sa session Claude, qui tourne sur le PC d'Adem (les commits de ce PC sont donc signés « Adem Banni » ; c'est Titouan qui pilote cette session et ses lots).

Le lot D3 lit les arrêtés de pêche de toute la France : un collecteur télécharge les textes, deux lecteurs indépendants écrivent les règles, `consensus.py` ne garde que ce que les deux disent pareil. Le pilote (l'Eure) et les vagues 1 et 2 sont faits. Il reste 95 départements en 10 vagues de 10.

| Vagues | Départements | Qui |
|---|---|---|
| 1 à 6 | 75 77 78 91 92 93 94 95 01 02 · 03 04 05 06 07 08 09 10 11 12 · 13 14 15 16 17 18 19 21 22 23 · 24 25 26 28 29 2A 2B 30 31 32 · 33 34 35 36 37 38 39 40 41 42 · 43 44 45 46 47 48 49 50 51 52 | la session de Claude sur le PC d'Adem (déjà lancée, ne la refaites pas) |
| **7** | **53 54 55 56 57 58 59 60 61 62** | **Adem** |
| **8** | **63 64 65 66 67 68 69 70 71 72** | **Adem** |
| **9** | **73 74 76 79 80 81 82 83 84 85** | **Sullyvan** |
| **10** | **86 87 88 89 90** | **Sullyvan** |

Le 27 (Eure) est fait.

## Déjà fait, à ne pas relire (fil du plan, 15 oct. 19h58)
- **Sur `regles/local`** (c93dd79, 19h47) : 28 départements confirmés, 01 à 16, 19, 22, 23, 27, 75, 77, 78, 91 à 95. Avant chaque département : `git fetch origin regles/local`, puis `git ls-tree -r --name-only origin/regles/local | grep consensus/<code>.json` ; s'il y est, passer au suivant.
- **Sur le PC, avant de relire** : la session D3 du PC (dossier `C:\Users\Adem\Build Challenge`, dépôt peut-être sous `repo\`) a rapporté à 14h39 avoir lu deux fois les 96 départements de métropole (15 537 règles confirmées, dont Oise 179, Loire-Atlantique 306, Haute-Vienne 186 ; tableau dans `reports\regles-local\avancement.md`), sans les pousser. Ce chiffre n'a jamais été vérifié depuis GitHub. Si `outils\regles\consensus\<code>.json` existe dans ce dossier, le pousser avec `pousser.py` au lieu de le relire. Ce rapport laissait à lire 17, 26, 2A, 49, 82, 83, 84, 88 (préfecture refusée ; 04 et 15 sont lus depuis) et à compléter 05, 18, 23, 33, 40, 66, 71.
- **Déjà dans l'app** (`lot/donnees`) : 44 et 87 (deux lectures copiées dans le dossier partagé) et 60 (une seule lecture, tout en « vérifie l'arrêté »). Leur arrivée sur `regles/local` les remplacera. Les 28 de `regles/local` sont chargés au fil de l'eau par `outils/verifier_donnees.py --charger`.

## Comment faire un département (Adem et Sullyvan)
1. Récupérer le plan et l'outil : `git fetch origin`, puis `scripts/lot.sh D3` (copie de travail sur `lot/regles-france`). Les briefs sont dans `outils/regles/` : `brief-collecteur.md`, `brief-lecteur.md`, `consigne-departement.md`.
2. **Collecte** (un agent par département, **Haiku** suffit, 30 min au plus) : exécuter `brief-collecteur.md` avec `CODE` et `NOM`. Il télécharge les arrêtés dans `outils/regles/corpus/<code>/` et lance `python3 -I outils/regles/corpus.py <code>` (OCR Tesseract français si installé, sinon OCR de Windows).
3. **Deux lectures** (deux agents **Sonnet** distincts, le second sans jamais lire le travail du premier) : `brief-lecteur.md` en lecteur A (`outils/regles/dep/<code>.json`) puis en lecteur B (`dep-b/<code>.json`). `python3 -I outils/regles/valider.py <fichier>` doit afficher OK.
4. **Comparaison** : `REGLES_DIR=<dossier outils/regles> python3 -I outils/regles/consensus.py <code> --json`.
5. **Pousser** : `python3 -I outils/regles/pousser.py <code>` envoie `consensus/<code>.json` et son rapport sur la branche `regles/local`. Jamais `dep/`, `dep-b/` ni `corpus/` dans git.

## Règles
- Une règle que les deux lectures ne confirment pas devient « vérifie l'arrêté », jamais « tu peux la garder ».
- Deux textes qui se contredisent : on affiche la plus stricte avec les deux sources.
- `regles/local` n'est jamais fusionnée dans `main` : D1 en tire `docs/regles-local/consensus/` avec `git archive origin/regles/local docs/regles-local | tar -x -C <dossier>`.
- Sullyvan (plan à 20 €, une session) : un département à la fois, collecte en Haiku, lectures en Sonnet ; si le crédit s'arrête, noter dans le message de commit quels départements sont finis. Les 5 départements de la vague 10 d'abord si le crédit est court.
- Installer Tesseract est facultatif : `winget install UB-Mannheim.TesseractOCR`, puis déposer `fra.traineddata` (dépôt officiel `tesseract-ocr/tessdata_best`) dans un dossier `tessdata` et régler `TESSDATA_PREFIX`. Sans lui, `corpus.py` retombe sur l'OCR de Windows.
