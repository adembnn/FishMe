# Examen du modèle v2 (PoissonsDino-int8, 55 classes), 16 oct. 2026

Règle (`docs/fiches/R1.md`, « Examen ») : le modèle n'entre dans l'app que s'il passe l'examen fixé avant l'entraînement. Jeu de test fixé avant tout entraînement, découpé par photographe (`sha1(photographe) % 4 == 0`), jamais vu à l'entraînement ; doublons retirés (cosinus > 0,95). Le modèle examiné est celui de l'app : DINOv2-small + tête logistique, pas la chaîne Fishial du README.

## Verdict : **le modèle passe**, sans 4 classes
| Critère (seuil proposé dans R1) | Mesure | Résultat |
|---|--:|:-:|
| Bonne espèce dans les 3 propositions ≥ 90 %, prises de pêcheurs | 91,7 % (7 057 prises) ; AFFiNe seule 96,7 % | passe |
| Bonne espèce en 1re proposition ≥ 70 %, prises de pêcheurs | 82,6 % ; AFFiNe seule 87,9 % | passe |
| « Pas un poisson » refusé ≥ 90 % (seuil 0,4 ou classe spéciale en tête) | 97,3 % (368 photos) ; une espèce proposée dans 2,7 % | passe |
| Une classe dont le top-3 < 80 % sur ses propres photos sort du modèle | 4 classes sous 80 % (ci-dessous) | retirées dans l'app |
| Recadrage juste ≥ 90 % sur 300 boîtes tracées à la main | non mesuré : l'app envoie la photo entière (choix vérifié sur Mac, aucun recadrage à noter) | sans objet |
| Même examen avec Vision sur le Mac (int8, `.scaleFit`) | 1 851 prises AFFiNe : top-1 86,4 %, top-3 96,3 %, 8,4 ms par photo ; confiance moyenne 0,72 quand juste, 0,39 quand faux | passe |

Tout le test (photos de terrain GBIF et Unsplash comprises, 9 849 poissons) : 72,6 % / 85,5 %. Ces photos ne ressemblent pas aux prises ; l'examen porte sur les prises, le cas de l'app.

Au seuil de 0,4, 20 % des vraies prises ouvrent la grille au lieu de 3 propositions ; quand le modèle propose, la 1re proposition est juste dans 93,0 % des cas.

## Classes retirées (top-3 < 80 % sur au moins 10 photos)
chabot (79,7 %, 59 photos), grande alose (50 %, 12), mulet (75 %, 76), omble chevalier (72,7 %, 11). Ces 4 espèces se choisissent dans la grille ; l'app ne les propose plus (correctif `correctifs/lot-prise-tuiles-familles.patch`, `IdentificationDino.horsExamen`).

Les sosies regroupés par l'app passent au niveau du groupe : lamproies 80,2 %, ablette et able de Heckel 81,3 %, loches 84,8 %, carassins 97,1 %. Le pêcheur choisit ensuite l'espèce dans le groupe.

## Points faibles qui restent dans le modèle (top-1 sous 65 %)
gardon 56 % (pris pour le rotengle), rotengle 61 %, carassin commun 64 % (le groupe carassin est à 94 %), vairon 63 %, carpe argentée 63 %, chabot 58 %, ablette 33 %. Le top-3 de ces espèces reste au-dessus de 80 % sauf le chabot, retiré.

## Détail
Scores par classe et par groupe : `examen-v2.json`. Script : `scripts/examen_v2.py` (lit `m.pkl` de l'entraînement v2 et `banc-essai/eval8/jeu-test.csv`).
