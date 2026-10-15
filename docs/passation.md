# Passation du 15 oct. 2026, 12h15 (fil « Plan de construction de l'app »)

Pour la session qui reprend. Adem n'avait plus de crédit : tout a été arrêté proprement et poussé. Lire d'abord `CLAUDE.md`, puis `docs/README.md`, puis ce fichier.

## Où sont les choses
- **Le plan** : cette branche, `claude/project-thread-78e20q` (devient `main` à L0). `python3 docs/verifier.py` doit afficher « 0 trou : 19 lots ».
- **Les outils de lecture des règles** : `outils/regles/` (consigne v2, `valider.py`, `consensus.py`). `REGLES_DIR=<dossier>` dit où sont `dep/`, `dep-b/`, `consensus/`.
- **Les lectures et les rapports (données, jamais sur cette branche)** : dossier partagé du projet `/mnt/project-files/build/regles/` et `/mnt/project-files/build/reports/`, copiés sur GitHub par la copie automatique, branche `claude/push-docs-projet-t0aglk`, sous `docs/regles/` et `docs/reports/`. Pour les récupérer ailleurs : `git fetch origin claude/push-docs-projet-t0aglk && git archive origin/claude/push-docs-projet-t0aglk docs/regles | tar -x`.
- **Recherches du fil Maquettes sur le spot** : `/mnt/project-files/maquettes/reports/spot-reglementation.md`, `spot-technique.md`, `pescedex-par-zone.md` (aussi sur la branche de copie, `docs/maquettes/reports/`).

## Ce qui a été arrêté à 12h10
- 12 lecteurs dans le cloud, coupés en cours : 75-A, 77-A, 77-B, 78-B (avait déjà écrit un fichier valide), 91-A, 92-A, 92-B, 93-A (avait fini), 93-B, 95-B, 60-A, et la relecture du Code national au mot près (FR-A). Rien de partiel n'est resté sauf ce qui passe `valider.py` (tableau ci-dessous).
- La session sur le PC Windows d'Adem (dossier `Documents\claude-logs`), arrêtée deux minutes après son démarrage : aucune lecture locale n'a été rendue (`/mnt/project-files/build/regles/local/` n'existe pas). Son brief complet est le dernier message « Handed the machine session instructions » du fil ; à relancer tel quel.

## Règles de toute la France (D3), état mesuré à 12h12
`python3 -I consensus.py --tous` dans `/mnt/project-files/build/regles/` :
| Dép. | Lecture A | Lecture B | Confirmées par les deux | Remarque |
|---|---|---|---|---|
| 01 Ain | 287 (v1) | 273 (v1) | 205 (71 %) | pilote, ancienne forme : `valider.py` signale des défauts |
| 44 Loire-Atl. | 303 (v2) | 162 (v1) | 76 (25 %) | B à relire en forme v2 |
| 78 Yvelines | 44 | 43 | 42 (95 %) | |
| 87 Haute-Vienne | 102 (v1) | 104 (v1) | 42 (41 %) | les deux lecteurs n'ont pas lu les mêmes textes |
| 94 Val-de-Marne | 64 | 78 | 47 (73 %) | |
| 93 Seine-St-Denis | 27, toutes `incertain` | non | | arrêté 2025-0988 scanné, illisible sans OCR |
| 95 Val-d'Oise | 102 | non | | |
| 60 Oise, 75 Paris, 91 Essonne | non | 142, 49, 95 | | |
| 77, 92, FR (Code) | non | non | | |
Ce qui bloque dans le cloud : sites de l'État et des fédérations refusés (403), extraits de 125 caractères, recherche web épuisée, 20 agents à la fois. D'où la décision d'Adem : « tu fais tout en local ».

À faire ensuite, dans l'ordre : relancer la session sur le PC (Eure de bout en bout, point de 3 lignes, puis la file du brief) ; relire en local au mot près les départements lus dans le cloud ; porter les 13 corrections nationales E1 à E13 (`/mnt/project-files/build/reports/especes-national.md`) dans `brouillon-75-94.json`.

## Questions qui attendent Adem (chacune a un défaut, le travail avance dessus)
1. Forme de la règle pour une prise (`docs/README.md`, question 1) : défaut b, liste de contrôle sourcée.
2. Ce que bloque le paywall (`docs/README.md`, question 2) : défaut b. Idée d'Adem du 15 oct. (fil Maquettes) : le gratuit propose UN spot ; tranché le 15 oct. 12h26 : sessions illimitées sur ce spot. Reste : ce qui déclenche le paywall, puisque « 2e session » ne tient plus.
3. Rôle de l'IA d'Apple dans la reconnaissance : défaut a (notre modèle Create ML partout, l'IA d'Apple sur 15 Pro et plus pour la légende, et pour l'espèce seulement si elle passe le même examen).
4. Taille et poids : défaut a (curseur, poids estimé par la formule longueur-poids ; à 2 cm ou moins de la taille légale, mesurer au mètre), réalité augmentée dans la mise à jour.
5. Forme du spot : tranché le 15 oct. 12h26, cercle de 1 km vendredi, tronçon ou lac entier dans la mise à jour (`reports/spot.md`).
6. Pack de lots reconnaissance R0 à R4 (examen, photos, entraînement, IA d'Apple au même examen, taille et poids) : plan en 4 lignes envoyé, ok d'Adem attendu ; il faut aussi savoir qui a un iPhone 15 Pro ou plus et qui rassemble les photos de vraies prises.
7. Toujours ouverts : nom de l'app, prix mensuel retenu, prix en euros (colonne France d'App Store Connect), compteur du Pescedex par zone (fil Maquettes).
Règle d'Adem : jamais plus de 3 questions à la fois. Poser 3, 5 et 6 en premier.

## Ce qui tourne encore
- Une tâche planifiée d'un autre fil, « Relance de la copie GitHub », se réveille à chaque heure (minute 4) et relance la boucle qui copie le dossier partagé vers `claude/push-docs-projet-t0aglk`. Elle consomme un peu à chaque réveil. Pour la suspendre sans la supprimer : créer le fichier `/mnt/project-files/.outils/STOP`.

## Pour reprendre
```bash
git fetch origin claude/project-thread-78e20q && git checkout claude/project-thread-78e20q
python3 docs/verifier.py                      # 0 trou : 19 lots
python3 outils/atelier/essai.py               # 180/180
REGLES_DIR=/mnt/project-files/build/regles python3 -I outils/regles/consensus.py --tous
```
Mémoire du projet : `regles-france-chaine`, `token-maxing`, `grill-me-jury`, `maquettes-trois-volets`, `fusion-titouan`.
