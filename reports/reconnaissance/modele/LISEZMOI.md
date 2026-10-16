# PoissonsDino (Core ML) — version 2 du 16 oct. 2026

Classifieur d'espèces de poissons d'eau douce, hors ligne sur iPhone (Vision, VNCoreMLRequest -> VNClassificationObservation).
DINOv2-small (facebook/dinov2-small, Apache 2.0) + régression logistique (C=2, class_weight=balanced) entraînée sur les vecteurs L2-normalisés [pooler 384 | moyenne des patchs 384].

- Entrée : image "image", RGB 224x224, valeurs 0-255 (normalisation ImageNet incluse). Fournir le poisson recadré (détourage Vision), Vision réglé en `.scaleFit`.
- Sortie : classifieur (labels + probabilités), **55 classes** (`labels.txt`), dont `pas-un-poisson` et `autre-poisson`. Lire les labels depuis le modèle, ne pas les coder en dur.
- Seuil de départ : sous 0,4 de confiance, ouvrir la grille (mesure v1 sur Mac : confiance moyenne 0,68 quand juste, 0,35 quand faux).
- Taille : 22 Mo (poids int8).

## Scores (même jeu de test fixe, découpé par photographe ; mesure sur les vecteurs, dans le cloud)
| Version | Photos d'entraînement | Classes | Prises AFFiNe (1 847) top-1 / top-3 | Tout le test top-1 / top-3 |
|---|--:|--:|--:|--:|
| v1 (15 oct. soir) | ~17 000 | 51 | 87,3 % / 96,3 % | 67,7 % / 84,0 % (5 657 photos) |
| **v2 (16 oct. nuit)** | **33 998** | **55** | **87,7 % / 96,4 %** | **72,8 % / 86,0 %** (10 452 photos) |

v1 vérifiée sur Mac avec Vision (int8) : 86,4 % / 96,3 % sur les 1 847 prises AFFiNe, 36 ms par photo. v2 : à revérifier sur Mac de la même façon.
Sur toutes les prises de pêcheurs hors AFFiNe (5 215 photos de test : Allemagne, Tchéquie, Hongrie, Europe, Amérique du Nord) : 80,7 % / 89,9 %.

Comparaison : Create ML (scenePrint v2) sur les mêmes prises AFFiNe : 67,9 % / 88,3 % (centerCrop). Modèle de secours à 6 espèces du fil de reprise : 83,9 % / 93,0 % sur son propre test.

Les photos d'entraînement ne sont pas incluses. Scripts de conversion : `scripts/`.
