# Banc d'essai de la reconnaissance des poissons (15 oct. 2026)

Mesures réelles, faites dans le cloud le 15 oct. sur 22 648 photos téléchargées. Les photos restent dans le conteneur (jamais dans git ni ici), réduites à 640 px et réencodées sans EXIF, donc sans GPS. Ce dossier garde les listes, les scores, les vecteurs et les scripts.

## En bref
- **Photos de prises (AFFiNe, poisson tenu ou posé) : la bonne espèce en 1re proposition dans 93,5 % des cas, dans les 3 propositions dans 98,2 %** (1 842 photos de test).
- Photos de terrain (GBIF : poissons dans l'eau, morts, de loin, au bocal) : 64 % et 81 %. C'est le cas difficile, et pas celui de l'app.
- Toutes photos confondues : 76 % et 89 % ; sur les 20 espèces les plus pêchées : 74 % et 87 %.
- **Refus** : 96,7 % des photos « pas un poisson » sont refusées ; 0,5 % des vrais poissons sont refusés à tort.
- **Seuil de confiance** : au-dessus de 0,37 (après calibration, T = 0,75), 95 % des 1res propositions sont justes et cela couvre 97,8 % des photos de prises. Toutes photos confondues (terrain compris), il faut 0,78 et cela ne couvre que 66 % des photos : le reste ouvre la grille.
- **47 classes reconnues** (45 poissons, « pas un poisson », « autre poisson »). 13 espèces restent en grille faute de photos, plus l'apron (0 photo).
- Seuils de R1 (top-3 ≥ 90 %, top-1 ≥ 70 %, ≥ 90 % de « pas un poisson » refusés) : **atteints sur les photos de prises**, pas encore sur les photos de terrain.

## Mise à jour du 15 oct., 18h30 : prises hongroises, tchèques, allemandes et photos américaines
3 356 photos de plus (carnet de pêche hongrois haldorado, nachytano.cz, fisch-hitparade.de en partie, Flickr CC, domaine public USGS/USFWS) : 26 951 photos en tout. Mesure dans `eval4/` (et `scores.json`, `seuils.json` à la racine).
- **Carpe argentée et hotu sortent de la grille** : carpe argentée 74 % en 1re proposition (94 % dans les 3), surtout confondue avec la carpe à grosse tête ; hotu 69 % (86 %), surtout confondu avec le barbeau. 51 classes reconnues.
- **Black-bass** : 30 → 44 % (16 photos de test), encore faible.
- Brochet 76 → 78 %, omble chevalier 80 → 87 %, omble de fontaine 70 → 77 %, saumon 54 % (83 % dans les 3).
- Baisses : silure 99 → 85 % (121 photos de test au lieu de 89, confondu avec le saumon sur 5 photos), carpe à grosse tête 94 → 65 % (confondue avec l'argentée, et le carnet hongrois mêle sans doute les deux sous le nom « busa »). Les nouvelles photos de test sont plus dures ou parfois mal étiquetées : à vérifier à la main.
- Toutes prises de pêcheurs (hors AFFiNe, 456 photos de test) : 83 % et 90 %. AFFiNe : 93,3 %. Toutes photos : 76,5 % et 88,3 %. 20 espèces les plus pêchées : 75 % et 86 %.
- Restent en grille : aloses, cristivomer, goujon de l'Amour, huchon (28 photos d'entraînement sur 30), lamproies fluviatile et marine, loche d'étang, pseudorasbora, spirlin.

## Mise à jour du 15 oct. au soir : prises de pêcheurs tchèques
Ajout de 926 prises de chytej.cz (photos de pêcheurs, « tous droits réservés », entraînement seulement, jamais commercialisées) et 21 photos EOL. Même jeu de test, même règle par photographe ; 53 fuites retirées. Les fichiers `scores.json`, `seuils.json`, `jeu-test.csv` et `train.csv` sont ceux de cette mesure ; le tableau par espèce plus bas est celui d'avant.
- **Nouvelles prises de pêcheurs (228 au test) : 90 % en 1re proposition, 96,5 % dans les 3.** Ce sont des photos d'un autre pays que l'entraînement AFFiNe : le modèle tient hors des Pays-Bas.
- Prises AFFiNe : 93,4 % et 98,1 % (inchangé). Toutes photos : 76,9 % et 88,8 %. 20 espèces les plus pêchées : 75,5 % et 87,4 % (avant 74 % et 87 %).
- **Carpe à grosse tête sort de la grille : 94 % (17 photos de test).** Carpe argentée (29 photos d'entraînement, il en faut 30) et hotu (20) restent en grille de justesse.
- Gains nets : ablette 60 → 69 %, ombre 78 → 82 %, perche 59 → 62 %, brème 81 → 83 %, brochet 74 → 76 %. Petites baisses dans le bruit : truite arc-en-ciel 72 → 70 %, carassin commun 64 → 60 %.
- En cours : environ 8 000 prises de fisch-hitparade.de (Allemagne) en cours de lecture.

## Les photos
| Source | Photos gardées | Type | Licence | Remarque |
|---|--:|---|---|---|
| GBIF hors iNaturalist, Observation.org et musées | 10 774 | Terrain, varié, souvent mauvais | CC BY, CC BY-NC, « tous droits réservés » (1 661) | 2 500 photographes |
| AFFiNe (Kaggle, sans compte) | 7 482 | Prises de pêcheurs néerlandais, déjà recadrées, longueur en mm | CC BY-NC-SA 4.0 | 30 espèces ; ok d'Adem le 15 oct. 12h13 |
| Openverse (photos Flickr) | 2 274 | Souvent des photos trophées, mots-clés bruités | CC, sans « ND » | Gardées à l'entraînement seulement si Fishial confirme l'espèce ; jamais au test |
| Unsplash Lite | 2 124 | « Pas un poisson » (eau, bateaux, mains, oiseaux…) et « autre poisson » | Licence Lite : entraînement interne commercial permis | Les « autres poissons » que Fishial prend pour une de nos espèces sont retirés |

Écartés : iNaturalist et Observation.org (en attente de la décision d'Adem), Wikimedia Commons (l'API refuse ce serveur, 429), INPN (bloqué par Cloudflare depuis le cloud, joignable peut-être depuis le PC d'Adem), FishBase (son robots.txt bloque les robots d'IA), NINA (vidéo sous l'eau, 28 Go). Repérés pour plus tard : les murs de photos des ~94 fédérations de pêche (500 à 750 prises légendées, autorisation demandée par leurs conditions).

## La chaîne testée
1. **Recadrage** : le segmenteur de Fishial (FPN-ResNet18, MIT, 49 Mo) trouve le poisson et le remet à l'horizontale, même quand le pêcheur pose avec. Il ne sait pas dire « pas de poisson » : il entoure toujours quelque chose (chat, personne). Le refus passe donc par la classe « pas un poisson ».
2. **Vecteurs** : Fishial v0.10.2 (DINOv2 + tête ArcFace, 866 espèces, MIT, 352 Mo) et DINOv2-S (Apache 2.0, 88 Mo).
3. **Tête** : régression logistique sur les vecteurs, classes équilibrées.
4. **Test** : un photographe sur quatre, choisi par l'empreinte de son nom, avant tout entraînement (`jeu-test.csv`). AFFiNe ne donne pas de photographe : chaque photo y compte pour un. 51 photos de test presque identiques (similarité > 0,95) à une photo d'entraînement ont été retirées du test.

| Modèle | 1re proposition | Dans les 3 | Prises AFFiNe (1re) | Terrain GBIF (1re) |
|---|--:|--:|--:|--:|
| Fishial seul, sans entraînement | 52 % | 59 % | 78 % | 45 % |
| DINOv2-S + tête (taille iPhone, ~22 Mo) | 67 % | 85 % | 87 % | 52 % |
| Fishial + tête | 71 % | 84 % | 91 % | 59 % |
| **Fishial + DINOv2-S + tête (retenu)** | **76 %** | **89 %** | **93 %** | **64 %** |

## Par espèce (modèle retenu, tout le test)
| Espèce | Photos entraînement | Photos test | 1re proposition | Dans les 3 | Confondu surtout avec |
|---|--:|--:|--:|--:|---|
| Bouvière | 40 | 9 | 100 % | 100 % | — |
| Poisson-chat | 52 | 20 | 100 % | 100 % | — |
| Aspe | 296 | 80 | 99 % | 100 % | Ide mélanote (1) |
| Silure glane | 312 | 75 | 99 % | 99 % | Brochet (1) |
| Esturgeon européen | 227 | 71 | 97 % | 99 % | Anguille (1), Saumon atlantique (1) |
| Grémille | 259 | 99 | 97 % | 97 % | Perche commune (2), Pas un poisson (1) |
| Sandre | 315 | 106 | 96 % | 98 % | Gambusies (1), Mulets (1), Ombre commun (1) |
| Barbeau fluviatile | 288 | 90 | 94 % | 97 % | Aspe (2), Anguille (1), Carassin argenté et poisson rouge (1) |
| Gobies à taches noires, fluviatile, de Kessler | 333 | 106 | 94 % | 98 % | Chabots (2), Rotengle (1), Loches franches (1) |
| Tanche | 451 | 114 | 94 % | 96 % | Silure glane (2), Épinoche (2), Aspe (1) |
| Ide mélanote | 295 | 106 | 92 % | 93 % | Chevesne (3), Aspe (1), Brème commune (1) |
| Flet | 191 | 60 | 87 % | 88 % | Silure glane (2), Autre poisson (1), Saumon atlantique (1) |
| Perche soleil | 372 | 100 | 85 % | 86 % | Épinoche (3), Grémille (2), Gambusies (2) |
| Carpe amour | 257 | 99 | 84 % | 88 % | Chevesne (6), Carpe commune (5), Carassin argenté et poisson rouge (1) |
| Pas un poisson | 1032 | 368 | 83 % | 100 % | Autre poisson (49), Anguille (4), Mulets (2) |
| Lotte | 49 | 41 | 83 % | 93 % | Anguille (2), Gobies à taches noires, fluviatile, de Kessler (2), Lamproie de Planer (1) |
| Brème bordelière | 228 | 74 | 81 % | 97 % | Brème commune (5), Aspe (4), Ablette (2) |
| Brème commune | 356 | 115 | 81 % | 94 % | Brème bordelière (15), Silure glane (1), Ide mélanote (1) |
| Goujons | 318 | 111 | 80 % | 87 % | Vairons (4), Gobies à taches noires, fluviatile, de Kessler (2), Loche de rivière (2) |
| Omble chevalier | 76 | 30 | 80 % | 90 % | Pas un poisson (2), Truite commune (fario, de mer) (1), Autre poisson (1) |
| Carpe commune | 1317 | 535 | 78 % | 90 % | Carpe amour (21), Carassin argenté et poisson rouge (17), Autre poisson (10) |
| Ombre commun | 94 | 18 | 78 % | 89 % | Truite arc-en-ciel (2), Chevesne (1), Barbeau fluviatile (1) |
| Vandoise | 75 | 27 | 78 % | 82 % | Chevesne (3), Brème bordelière (1), Goujons (1) |
| Loche de rivière | 36 | 13 | 77 % | 85 % | Épinoche (1), Perche commune (1), Gambusies (1) |
| Chevesne | 448 | 114 | 75 % | 90 % | Ide mélanote (6), Gardon (3), Carpe amour (3) |
| Chabots | 144 | 59 | 75 % | 80 % | Gambusies (5), Gobies à taches noires, fluviatile, de Kessler (4), Silure glane (1) |
| Brochet | 718 | 264 | 74 % | 83 % | Carpe commune (13), Anguille (8), Mulets (5) |
| Autre poisson | 541 | 167 | 73 % | 90 % | Pas un poisson (28), Saumon atlantique (4), Aspe (2) |
| Truite arc-en-ciel | 165 | 65 | 72 % | 80 % | Carpe commune (3), Saumon atlantique (3), Poisson-chat (2) |
| Rotengle | 599 | 186 | 72 % | 88 % | Gardon (18), Gambusies (5), Mulets (5) |
| Vairons | 208 | 65 | 71 % | 82 % | Épinoche (4), Gambusies (4), Lamproie de Planer (2) |
| Loches franches | 51 | 20 | 70 % | 70 % | Chevesne (1), Loche de rivière (1), Vairons (1) |
| Gambusies | 227 | 68 | 69 % | 90 % | Vairons (4), Épinoche (3), Brochet (2) |
| Carassin argenté et poisson rouge | 453 | 140 | 69 % | 87 % | Carassin commun (15), Carpe commune (7), Rotengle (5) |
| Truite commune (fario, de mer) | 1008 | 365 | 68 % | 82 % | Truite arc-en-ciel (20), Gambusies (13), Saumon atlantique (13) |
| Épinoche | 734 | 212 | 67 % | 86 % | Gambusies (19), Ablette (7), Anguille (7) |
| Corégones | 56 | 18 | 67 % | 78 % | Aspe (1), Ablette (1), Black-bass (1) |
| Omble de fontaine | 62 | 27 | 67 % | 82 % | Brochet (2), Omble chevalier (2), Truite arc-en-ciel (1) |
| Able de Heckel | 63 | 26 | 65 % | 81 % | Gambusies (4), Épinoche (2), Ablette (1) |
| Anguille | 714 | 218 | 65 % | 91 % | Lamproie de Planer (33), Truite commune (fario, de mer) (7), Épinoche (6) |
| Carassin commun | 343 | 89 | 64 % | 84 % | Carassin argenté et poisson rouge (15), Carpe commune (4), Tanche (3) |
| Mulets | 131 | 69 | 62 % | 81 % | Poisson-chat (5), Flet (3), Ablette (3) |
| Ablette | 85 | 42 | 60 % | 76 % | Gambusies (3), Rotengle (3), Able de Heckel (3) |
| Perche commune | 711 | 214 | 59 % | 79 % | Poisson-chat (24), Épinoche (12), Vairons (7) |
| Gardon | 618 | 171 | 57 % | 73 % | Rotengle (14), Saumon atlantique (10), Gambusies (5) |
| Saumon atlantique | 100 | 35 | 57 % | 77 % | Truite commune (fario, de mer) (8), Flet (2), Vairons (2) |
| Lamproie de Planer | 158 | 64 | 38 % | 81 % | Anguille (26), Vairons (6), Gambusies (2) |
| Black-bass | 91 | 10 | 30 % | 40 % | Sandre (2), Tanche (1), Poisson-chat (1) |

Espèces en grille (pas assez de photos : moins de 30 pour entraîner ou moins de 5 pour tester) :
Alose feinte (11 + 3), Carpe argentée (29 + 10 depuis chytej), Carpe à grosse tête (sortie de la grille le soir, 94 %), Cristivomer (2 + 0), Goujon de l'Amour (15 + 2), Grande alose (3 + 7), Hotu (20 + 10 depuis chytej), Huchon (4 + 2), Lamproie fluviatile (17 + 16), Lamproie marine (45 + 3), Loche d'étang (7 + 0), Pseudorasbora (11 + 8), Spirlin (11 + 1).

## Ce qu'on en tire
- Le cas de l'app (photo de prise, poisson net) marche déjà. Les faiblesses viennent surtout des photos de terrain de GBIF, et des espèces à peu de photos : black-bass (71 photos sans iNaturalist, 30 %), saumon, lamproie de Planer (prise pour l'anguille), gardon et rotengle entre eux, carassin commun et argenté.
- **iNaturalist** multiplie les photos par 10 à 100 pour ces espèces. La décision est à Adem (carte dans le fil).
- **Taille et poids** : la photo seule ne donne pas la taille (le recadrage efface l'échelle). AFFiNe donne la longueur réelle de 7 482 poissons (`manifestes/affine_longueurs.csv`) : elle servira à vérifier les courbes longueur-poids, pas à mesurer sur la photo. La toise reste la méthode retenue.
- **Sur l'iPhone** : Fishial pèse 352 Mo, trop lourd tel quel. Options à mesurer sur Mac : DINOv2-S seul (87 % sur les prises, ~22 Mo), ou distiller le modèle retenu dans un petit modèle Create ML. La comparaison avec Create ML ne peut pas se faire ici (Create ML n'existe que sur Mac).
- BioCLIP 2 n'a pas été testé : 10 fois plus lent sur ce serveur sans carte graphique.

## Refaire les mesures
Scripts dans `scripts/` : `gbif_meta.py` et `openverse.py` (listes), `telecharger.py` (photos, sans EXIF), `traiter.py` (recadrage et vecteurs, reprend où il s'est arrêté), `evaluer.py` (jeu de test, têtes, scores), `seuils.py` (calibration, seuil, refus). Vecteurs dans `vecteurs/` (`traite.jsonl` donne la photo, la boîte et le top-5 Fishial de chaque ligne ; `.f32` = 768 nombres par photo).
