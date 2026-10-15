# Modèle Core ML fabriqué sous Linux (secours de Create ML) — 15 oct. 2026

## Verdict
- **Repli à 6 espèces (brochet, sandre, perche, truite fario, carpe commune, black-bass) + « autre poisson » + « pas un poisson » : l'examen d'EXAMEN.md est PASSÉ (critères 1 à 6).** Modèle livré : `six/FishMeReco.mlpackage`, **22,4 Mo**. À copier dans `App/Prise/Modele/` par B (le crochet de git interdit à R1 d'écrire dans `App/Prise/` ; le modèle reste hors git, `*.mlpackage` est ignoré) : `/mnt/project-files/build/reconnaissance/cloud-coreml/six/FishMeReco.mlpackage`.
- **Modèle large (35 espèces + 2 refus) : critères 1 à 4 et 6 passés, critère 5 raté** (86,4 % des photos hors liste refusées, seuil 90 %). Livré dans `full/` pour information ; il ne rentre pas dans l'app tant que l'examen n'est pas passé. Impossible d'avoir les 77 espèces : 13 espèces n'ont pas assez de photos et 15 autres échouent aux critères 3 ou 4 (voir plus bas).
- Pas de Mac : `coremltools` convertit sous Linux mais ne peut pas exécuter le modèle. Les scores ci-dessous sont ceux du réseau PyTorch **identique** à celui qui a été converti (mêmes poids : cosinus 1,000 avec les vecteurs du banc), avec les poids du réseau quantifiés en int8 simulés (voir « Vérifications »). Reste à faire sur Mac : un passage sur 50 photos pour confirmer que Core ML (calcul en float16) donne les mêmes classes.

## Méthode
DINOv2-S (Apache 2.0, ViT-S/14, 22 M de paramètres) figé, image entière (pas de recadrage Fishial : l'app n'a pas le segmenteur) étirée à 224×224 (`scaleFill`), vecteur = jeton CLS + moyenne des jetons de patchs (768 nombres), normalisé, puis tête MLP 768-512-K (dropout 0,3, étiquettes lissées, classes pondérées), softmax avec température T. Tout est dans le modèle Core ML (normalisation ImageNet, DINOv2, tête, softmax) ; poids du réseau en int8 par canal : 22 Mo.
Photos : mêmes listes que le banc (`eval4/train.csv`, `eval4/jeu-test.csv`, un photographe sur quatre au test, 51 fuites déjà retirées), retéléchargées avec `telecharger.py` : 19 332 photos d'entraînement, 5 651 de test (24 983 sur 25 204 : 221 liens morts). Aucune photo dans git ni ici.
Espèces sorties du modèle (critères 3 et 4) : leurs photos d'entraînement passent dans « autre poisson ». Le critère 5 compte comme « hors liste » : pas un poisson, autre poisson, et toute espèce sortie du modèle. Refus = 1re proposition « autre poisson » / « pas un poisson », ou confiance < tau. T et tau sont fixés sur une validation prise dans l'entraînement (tau : plus petit seuil refusant ≥ 92 % des photos hors liste de la validation), jamais sur le test.

## Scores sur le jeu de test (sources : AFFiNe = prises de pêcheurs néerlandais, peche = prises tchèques/allemandes/hongroises, gbif = terrain, public = USGS/EOL)
| | Repli 6 espèces | Modèle large 35 espèces |
|---|--:|--:|
| Photos de test d'espèces gardées | 1 646 | 4 208 |
| Top-1 / top-3, toutes photos | 83,9 % / 93,0 % | 80,7 % / 91,1 % |
| **Top-1 / top-3 moyens par espèce (examen 2 et 1)** | **81,2 % / 93,0 %** | **79,3 % / 91,4 %** |
| AFFiNe | 98,1 % / 99,5 % (426) | 93,6 % / 98,6 % (1 695) |
| peche | 92,1 % / 96,7 % (151) | 81,6 % / 91,0 % (376) |
| gbif (terrain, le cas difficile) | 77,2 % / 89,9 % (1 066) | 70,3 % / 85,2 % (2 127) |
| public | 33 % / 67 % (3) | 60 % / 90 % (10) : trop peu de photos |
| Pire espèce, top-3 (examen 3, ≥ 80 %) | perche 87,5 % | goujon 82,1 % |
| Photos de test par espèce (examen 4, ≥ 10) | min 16 (black-bass) | min 13 (loche de rivière) |
| « Pas un poisson » refusés | 98,9 % (368) | 99,7 % (368) |
| Hors liste refusés, total (examen 5, ≥ 90 %) | **91,6 %** (4 005) | **86,4 %** (1 443) : RATÉ |
| Vrais poissons refusés à tort (confiance < tau) | 17,1 % | 31,6 % |
| Avec le seuil : part des poissons gardés / justesse de leur 1re proposition | 82,9 % / 94,5 % | 68,4 % / 94,9 % |
| Taille | 22,4 Mo | 22,4 Mo |
| **Examen** | **PASSÉ** | échoue au critère 5 |

Repli 6 espèces, par espèce (test, top-1 / top-3) : brochet 366 : 82,0 / 90,2 ; sandre 114 : 90,4 / 97,4 ; perche 224 : 75,0 / 87,5 ; truite fario 383 : 80,7 / 93,2 ; carpe commune 543 : 90,2 / 95,9 ; black-bass 16 : 68,8 / 93,8 (16 photos : marge ±15 points). Détail du modèle large : `full/scores.json`.
Espèces tombées du modèle large : ablette, black-bass, corégones, gambusie, lamproie de Planer, loche franche, mulet, perche, saumon, truite arc-en-ciel, vandoise (top-3 < 80 % sans recadrage), puis gardon, ombre au tour suivant. Hors modèle faute de photos (< 30 d'entraînement ou < 10 de test) : alose feinte, grande alose, cristivomer, goujon de l'Amour, huchon, lamproies fluviatile et marine, loche d'étang, pseudorasbora, spirlin, apron, etc. : ces espèces passent par la grille « Autre ».
Pour la démo : le repli à 6 espèces est le bon choix. Le modèle large est pénalisé par l'absence de recadrage (la chaîne du banc avec Fishial donnait 76 % toutes photos, 93 % sur AFFiNe) ; il passerait peut-être le critère 5 avec un recadrage ou plus de photos « autre poisson », à étudier après.

## Vérifications (500 photos de test tirées au hasard, `verif_quantification.json`)
- Réseau converti vs vecteurs du banc : cosinus moyen 1,0000 (min 0,9999998), mêmes 1res propositions à 100 %.
- Poids int8 (simulés) vs float32 : cosinus moyen 0,9992 ; même 1re proposition 98 % (six) et 99 % (large) ; top-3 inchangé à ±0,2 point. Les 22 Mo sont donc sans perte mesurable.
- Non vérifié : l'exécution Core ML elle-même (float16, Neural Engine) ; impossible sous Linux.

## Comment l'app le charge
- Fichier : `FishMeReco.mlpackage` dans `App/Prise/Modele/` (Xcode le compile en `FishMeReco.mlmodelc` et génère la classe `FishMeReco`). Réglages : `tau` = 0,55 (repli), classes dans `six/classes.txt`.
- **Entrée** : `image`, une image RGB 224×224 (valeurs 0-255, la division par 255 et la normalisation ImageNet sont dans le modèle). Avec Vision : `VNCoreMLRequest` avec `request.imageCropAndScaleOption = .scaleFill` (c'est ce qui a été entraîné : photo entière étirée, ni recadrée ni bordée de noir).
- **Sorties** : modèle de classification Core ML. `classLabel` (String, la 1re proposition) et `classLabel_probs` ([String: Double], probabilités par classe, somme 1). Avec Vision on reçoit des `VNClassificationObservation` triées (`identifier` = id d'espèce de `classes.tsv`, `confidence`) : prendre les 3 premières.
- **Règle d'affichage** : si la 1re observation est `pas-un-poisson` ou `autre-poisson`, ou si sa confiance est < `tau` (0,55 pour le repli), ouvrir la grille « Autre ». Sinon proposer les 3 espèces (en ignorant `pas-un-poisson` et `autre-poisson` dans les 3 images) plus la case « Autre ». Le pêcheur confirme toujours : le modèle ne décide jamais si le poisson se garde.
- Classes (repli) : autre-poisson, black-bass, brochet, carpe-commune, pas-un-poisson, perche, sandre, truite-commune (truite-commune = fario).

## Refaire
`scripts/` : `telecharger.py` + `aff.py` (photos), `mklist.py`, `feats.py` (vecteurs ; 2 à 7 photos/s sur ce serveur partagé), `train2.py` (tête, examen, T, tau), `convert.py` (Core ML + int8), `verify.py`. Les vecteurs plein cadre (`all.npz`, 25 000 × 768) restent dans /home/user/r1/work (conteneur).
