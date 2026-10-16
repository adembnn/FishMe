# Lecture de la toise : seuils mesurés sur 13 photos (16 oct. 2026)

Photos : 13 prises publiques de fisch-hitparade.de où le poisson est posé sur une toise, un ruban ou un mètre pliant (`mac/toise10.csv`, liens seulement). Lecture par Vision sur le Mac (`mac/toise_ocr.swift`, même requête que `ToiseLecteur` : `RecognizeTextRequest`, `.accurate`, sans correction de langue). Textes lus : `mac/toise_ocr.json`.

## Ce que Vision lit
- Graduations exploitables sur 4 photos sur 13 (1, 3, 7, 8). Rien sur 7 photos : chiffres trop petits sur ces images de 450 à 700 px de large. Sur une photo d'iPhone (environ 4 000 px), les petits chiffres seront bien plus lisibles.
- **Vision rend souvent toute la graduation en un seul texte** (« 10 11 12 … 33 », « 10. 20. 30. 40. 50. »), parfois avec des chiffres collés (« 19200 ») ou du bruit (« 405@8--7==8 »). L'ancien lecteur n'acceptait qu'un nombre seul par texte : il ne lisait **aucune** des 13 photos.
- Les autres textes de la photo donnent des chiffres parasites : marque du tapis, journal (prix, « 107 cm/42" »), carton de concours (« 2012 »).
- Le zéro n'est pas toujours sous la bouche : sur 3 photos il est côté queue. L'app fait toucher les deux bouts (ou mesure de la butée), elle ne suppose rien.

## Ce qui change dans le lecteur (`App/Prise/ToiseCalibrage.swift`)
1. Chaque nombre d'un texte est pris à part, sa position estimée par l'indice de ses caractères dans le rectangle.
2. Ajustement robuste : chaque paire de repères propose une droite, on garde celle qui explique le plus de repères à 1,5 cm près, puis les moindres carrés.
3. Échelle plausible : un centimètre occupe entre 0,25 % et 12 % de la longueur de l'image.

## Seuils retenus
| Seuil | Avant | Après | Pourquoi |
|---|--:|--:|---|
| Repères distincts au moins | 3 | **4** | avec 3, la photo 7 (journal) donnait une fausse toise (2, 9, 95) |
| Étendue au moins | 20 cm | **15 cm** | une perche de 20 à 25 cm doit pouvoir être lue ; la photo 8 couvre 22 cm |
| Écart maximal | 1,5 cm | 1,5 cm | pire écart sur les toises lues : 0,46 cm |
| Échelle | aucune | **0,25 % à 12 %** de l'image par cm | seconde barrière contre les chiffres parasites |

Résultat : toises lues sur les photos 1, 3 et 8 (pire écart 0 ; 0,38 ; 0,46 cm) ; **aucune fausse lecture** sur les 10 autres (la 7 n'a que « 10 » et « 20 » du mètre, insuffisant). Vérifié en Swift (même code compilé sous Linux) et par 4 tests tirés de ces textes réels (`PriseLogiqueTests`, `vraiePhoto…`).

Reste à vérifier : 10 photos prises avec un iPhone sur une vraie toise, pour confirmer que la plupart des toises sont lues en pleine résolution.
