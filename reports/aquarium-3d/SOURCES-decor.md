# Décors aquarium : sources et échelles

Tout est CC0 (domaine public, usage commercial libre, attribution non requise). Textures 2K JPG, normales au format OpenGL (`normale.jpg`), cartes : `couleur`, `normale`, `rugosite`, `hauteur` (displacement), `ao`. Toutes les textures sont tileables.
Échelle : « couvre » = taille réelle de la surface photographiée pour un tile UV 0-1 (largeur x hauteur). Pour un aquarium, un galet de 1-5 cm doit mesurer 1-5 cm : on règle donc le tiling pour que le tile couvre ce chiffre (ex. galets : 1 tile = 2,16 m, donc pour un tile de 1 m mettre un scale UV de 2,16).

## Textures

| Dossier | Source / id | Page | Auteur | Couvre un tile | Remarque |
|---|---|---|---|---|---|
| `sol-gravier-riviere/` | ambientCG `Gravel019` | https://ambientcg.com/view?id=Gravel019 | ambientCG (Lennart Demes) | 1,40 m x 1,40 m | gravier fin de rivière, grains de 3 à 15 mm, mélange gris-bleu / beige |
| `sol-galets-riviere/` | Poly Haven `ganges_river_pebbles` | https://polyhaven.com/a/ganges_river_pebbles | Amal Kumar | 2,16 m x 2,16 m | galets roulés de 1 à 6 cm multicolores dans du gravier : le plus crédible pour 1-5 cm |
| `sol-sable-clair/` | ambientCG `Ground061` | https://ambientcg.com/view?id=Ground061 | ambientCG (Lennart Demes) | NON PUBLIÉ par ambientCG ; estimé 1,0 m x 0,5 m (image 2048x1024, ratio 2:1) | sable clair humide à légères ondulations. Échelle à caler à l'oeil : les ondulations doivent faire 3-5 cm |
| `sol-sable-vaseux/` | Poly Haven `brown_mud` | https://polyhaven.com/a/brown_mud | Rob Tuytel | 1,30 m x 1,30 m | boue/sable sombre humide pour l'étang |
| `roche-moussue/` | Poly Haven `mossy_rock` | https://polyhaven.com/a/mossy_rock | Rob Tuytel | 3,0 m x 3,0 m | roche grise avec lichens et mousse verte (grain fin à cette échelle : utiliser un tiling serré sur de gros rochers) |
| `roche-pierre-lisse/` | Poly Haven `seaside_rock` | https://polyhaven.com/a/seaside_rock | Dimitrios Savva | 2,0 m x 2,0 m | pierre sombre lisse au grain fin, pour galets/dalles |
| `bois-flotte-grisaille/` | Poly Haven `wood_planks_grey` | https://polyhaven.com/a/wood_planks_grey | Rob Tuytel | 1,5 m x 1,5 m | bois vieilli sombre. ATTENTION : ce sont des planches avec joints verticaux (pas de vrai bois flotté en texture CC0 trouvé) ; sur une branche, projeter en cadrant sur une seule planche ou préférer les modèles 3D de branches ci-dessous |
| `bois-ecorce/` | Poly Haven `bark_willow_02` | https://polyhaven.com/a/bark_willow_02 | Charlotte Baglioni | 2,15 m x 2,15 m | écorce de saule brun-gris, fibres verticales, pour racines/souches/troncs |

Candidats écartés (comparés sur aperçu) : clean_pebbles, rocks_ground_01, river_small_rocks, dry_river_pebbles, Gravel017/020/021 (gravier) ; dense_sand, Ground055L, Ground057, sand_01-03, damp_sand (sable) ; brown_mud_02/03, mud_forest, coral_mud_01 (vase) ; rock_pitted_mossy, lichen_rock, Rock057/063/064 (moussue) ; rock_surface, dark_rock, Rock041 (lisse) ; tree_bark_03, pine_bark, bark_brown_01, Bark001/013 (écorce).

## Modèles 3D (`modeles/<id>/<id>_2k.gltf`, glTF + .bin + textures 2K, Y vers le haut, unités en mètres)

Tous Poly Haven, CC0, page https://polyhaven.com/a/<id>. Triangles comptés dans le glTF (mesh complet, pas de LOD).

| id | Auteur | Triangles | Contenu et taille réelle (cm, X x Y(haut) x Z) | Usage |
|---|---|---|---|---|
| `rock_moss_set_01` | Kless Gyzen | 63 127 (6 rochers) | 6 pierres grises mousseuses de 180-265 x 110-177 x 196-337 cm chacune | pierres/rochers : mettre à l'échelle 0,03 à 0,1 pour 6 à 30 cm |
| `rock_moss_set_02` | Kless Gyzen | 57 647 (7 rochers) | 7 pierres de 120-250 x 53-131 x 98-180 cm, plus plates | idem, plus plates, bonnes pour des dalles |
| `namaqualand_boulders_01` | Greg Zaal (photo), Jenelle van Heerden (modèle) | 40 850 (2 pierres) | 2 galets arrondis beiges, 36 x 25 x 55 et 34 x 21 x 59 cm | les plus proches d'un gros galet roulé ; x0,2 pour 7-12 cm |
| `rock_09` | Jenelle van Heerden | 12 416 | pierre brune de 7 x 3 x 14 cm | déjà à l'échelle d'un petit galet/pierre plate |
| `tree_stump_01` | Rob Tuytel | 41 046 | souche de 143 x 57 x 159 cm (hauteur 57) | souche : x0,15 pour ~20 cm de large |
| `dead_quiver_branch_01` | Greg Zaal / Jenelle van Heerden | 14 834 | branche fourchue pâle type bois flotté, 25 x 44 x 23 cm | bois flotté prêt à l'emploi |
| `dry_branches_medium_01` | Rico Cilliers | 16 803 (3 branches) | 3 branches grises sèches de 78, 104 et 130 cm de long | bois flotté fin : x0,2 à 0,3 |
| `fern_02` | Rob Tuytel / Rico Cilliers | 6 232 (4 touffes) | 4 touffes de 55-99 cm de large (cartes alpha) | plante de berge/fond ; x0,2 pour 15-20 cm. Très léger |
| `weed_plant_02` | Rob Tuytel / Rico Cilliers | 11 116 (5 pousses) | 5 plantes à larges feuilles de 12-22 cm de large, 6-29 cm de haut | le plus proche d'une plante aquatique à large feuille |

Pas de vraie plante aquatique, de roseau ou d'élodée CC0 trouvée chez Poly Haven ; les herbes (grass_medium_01/02, grass_bermuda_01) et moss_01 existent mais font 220 000 à 1,6 M de triangles : écartés. Pas de fichier .blend livré (le glTF s'importe tel quel dans Blender avec ses 3 textures).

## HDRI 2K (`hdri/`, format .hdr)

| Fichier | Id / page | Auteur | Usage |
|---|---|---|---|
| `kloofendal_overcast_2k.hdr` | `kloofendal_overcast` https://polyhaven.com/a/kloofendal_overcast | Greg Zaal | lumière douce et diffuse de ciel couvert |
| `studio_small_08_2k.hdr` | `studio_small_08` https://polyhaven.com/a/studio_small_08 | Sergej Majboroda | lumière de studio douce, cyclorama blanc à faible contraste |

## Origine des fichiers
Poly Haven : API https://api.polyhaven.com/files/<id> (jpg 2k). ambientCG : https://ambientcg.com/get?file=<id>_2K-JPG.zip (NormalGL, Color, Roughness, Displacement, AmbientOcclusion). Planche de comparaison : `apercu.jpg` (couleurs retenues, de gauche à droite, haut puis bas, dans l'ordre du tableau).
