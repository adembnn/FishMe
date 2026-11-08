# Polices « masques clignotants » (widget Aquarium)

Technique de Bryce Bostwick (MIT) : https://github.com/brycebostwick/WidgetAnimation

- `modele-clignotant.otf` : la police de son exemple (licence dans `LICENCE-modele-clignotant.txt`). Elle n'est pas déclarée dans l'app.
- `FishMeClignoteChiffre0.otf` à `FishMeClignoteChiffre9.otf` (PostScript `FishMeClignoteChiffreK-Regular`) : faites à partir
  du modèle. Les deux chiffres des secondes d'un chrono forment une ligature : carré plein (`ligaturefull`) quand le chiffre
  des unités vaut K, vide (`ligatureempty`) sinon. Tout le reste est vide. CFF, em 500, montée 500, descente 0.

Dans un `Text(date, style: .timer)`, la police K donne un masque plein 1 s toutes les 10 s. Deux masques décalés d'1/8 s
se recoupent 1/8 s : c'est la fenêtre d'une copie (`HorlogeAnimation.masques`, `AnimationWidget.swift`).

## Polices de parité (lot widget-fluide, 7 nov.)

`FishMeClignotePair0.otf` et `FishMeClignotePair1.otf` (PostScript `FishMeClignotePairK-Regular`) : pleines quand le
chiffre des unités est pair (0) ou impair (1). Une boucle de 2 s n'a plus besoin que d'un chrono par masque
(`HorlogeAnimation.masquesParite`). Elles ne sont pas dans `UIAppFonts` (Config/ hors du lot) : `PolicesMasque.pairesDisponibles`
les enregistre au lancement de l'extension (`CTFontManagerRegisterFontsForURL`). Vu dans le simulateur : l'hôte des
widgets les dessine (témoins Debug en haut du widget : orange = chiffre 0, vert = pair, bleu = impair). À ajouter
quand même à `UIAppFonts` des deux cibles (lot A), par sûreté.

## Mesures du 7 nov. (simulateur iPhone 17 iOS 27.2, petit format, 3 poissons, Debug)

Pic = `phys_footprint_peak` de l'extension (`footprint`), cadence = changements par seconde de la zone du widget
dans une vidéo `simctl io recordVideo`, après 4 s.

| Piste | Copies | Entrées | Pic | Cadence vue | Verdict |
|---|---|---|---|---|---|
| statique | 0 | 19 / 7 / 4 | 27 / 20 / 19 Mo | 0 | repli |
| battement (16 images de queue, union de chronos) | 16 | 19 | 67 Mo | placeholder gris | non |
| nage10 (déplacement 10 s) | 80 | 19 | 70 Mo | placeholder gris | non |
| ondule (4 images de queue) | 16 | 19 | 56 Mo | placeholder gris | non |
| calques (un calque par poisson) | 48 | 19 | 48 Mo | placeholder gris | non |
| parite / parite4 (4 images de queue, parité) | 16 / 8 | 19 | 45 / 46 Mo | figée / 4 par s | trop lourd |
| parite2 / parite1 (2 images de queue) | 4 / 2 | 19 | 35 / 35 Mo | 2/s, 1/s | trop lourd |
| fixe16 / fixe24 / fixe32 (1 image) | 16 / 24 / 32 | 19 | 29 / 31 / 32 Mo | 9 / 13 / 17 par s | entrées à réduire |
| fixe16 / fixe24 / fixe32 | | 7 | 23 / 25 / 26 Mo | 9 / 12 / 17 par s | |
| **fixe24 (retenue)** / fixe32 | 24 / 32 | **4** | **23** / 24 Mo | 13 / 17 par s, écart max 0,10 s | retenue |
| glisse (entrée toutes les 10 s + `.animation`) | 0 | 60 | 38 Mo | saut, pas de glissement | non |
| chrono (`ProgressView(timerInterval:)`) | 0 | 19 | 27 Mo | la barre système avance seule ; style perso et `symbolEffect` immobiles | non |

Ce qui coûte : les IMAGES distinctes (chaque image de queue en plus ≈ 5 Mo de pic pour 3 poissons) et le nombre
d'entrées de la timeline (l'extension les rend toutes d'un coup) ; les copies et les chronos presque rien.

## Régénérer

    pip install fonttools
    python3 WidgetAquarium/Polices/fabriquer_polices.py

## Branchement (lot A : cibles et Info.plist)

Les cibles FishMeWidget et BuildChallenge doivent :
- avoir les 10 `FishMeClignoteChiffreK.otf` dans Copy Bundle Resources ;
- les déclarer dans leur Info.plist, clé `UIAppFonts` ;
- les appeler par leur nom PostScript : `Font.custom("FishMeClignoteChiffre3-Regular", size:)`.

## Poisson unique (lot W1, 7 nov. soir) : pistes `seul4/6/8/12`

Un seul poisson (vraies images `ImagePoisson`, vues 3D), trajet `NageWidget.traversees` de 10 s, une copie par pose à
la taille du poisson (`NageSeule.swift`), 1 image de queue (ondulation par transformation), timeline de 4 entrées.
Simulateur iPhone 17 iOS 27.2, petit format, Debug, `phys_footprint_peak` de l'extension (`footprint`), 1 poisson :

| Piste | Copies | Pic mesuré | Plafond 28 Mo |
|---|---|---|---|
| seul4 (4 images/s) | 40 | 21 à 24 Mo | tient |
| **seul6 (6 images/s, retenue)** | 60 | 22 à 25 Mo | tient |
| seul8 (8 images/s) | 80 | 27 à 31 Mo | dépasse (29, 30, 31) |
| seul12 (12 images/s) | 120 | 34 à 35 Mo | dépasse |

Non essayé : 4 images de queue distinctes. Vu à l'écran : le vrai poisson (truite, même décor que l'app) est dessiné
dans le widget et change de place entre deux captures (`reports/widget/diag-1.png`, `diag-3.png`).
NON PROUVÉ : la fluidité. Mes séries de captures et vidéos (`simctl`, simulateur) montrent le poisson immobile la
plupart du temps, y compris pour la piste témoin `fixe24` : la mesure d'images par seconde dans ce simulateur n'est pas
fiable. Seul un vrai iPhone dit si la nage est lisse (tester en Release, widget petit format).
Piège : un fichier `piste-widget.txt` oublié dans l'App Group du simulateur (ici `douce`) remplace la piste retenue.

## Fluidité du poisson unique (8 nov.)

Mesure de la pose de chaque copie (`AppTests/WidgetAquarium/FluiditeSeuleTests.swift`, widget petit de 170 pt, 30 poissons-trajets
essayés : 6 identifiants × 5 espèces). Pas maximal entre deux copies visibles successives, saut d'échelle maximal, raccord de la boucle :

| Copies (images/s) | Passages par boucle | Pas max | Saut d'échelle max | Raccord visible |
|---|---|---|---|---|
| 40 (4/s) | 3 | 18,8 pt | 10,8 % | 0/30 |
| 60 (6/s) | 3 | 13,8 pt | 7,5 % | 0/30 |
| 80 (8/s) | 3 | 10,9 pt | 5,4 % | 0/30 |
| 120 (12/s) | 3 | 7,6 pt | 3,8 % | 0/30 |
| **60 (6/s)** | **1 (retenu)** | **6,4 pt** | **3,5 %** | 0/30 |

Un seul passage de 10 s par boucle (`passagesMax: 1` dans `NageWidget.traversees`, paramètre ajouté, 3 par défaut : l'app est inchangée)
donne à 6 images/s un pas plus petit qu'à 12 images/s avec 3 passages, sans mémoire en plus. Le poisson est visible 96 % du temps ;
départ et arrivée de la boucle sont hors cadre ou invisibles (opacité 0) : aucun saut visible au raccord. Demi-tours : le poisson
change de sens hors du cadre ou en profondeur (il vient vers nous), pas en plein cadre.
Mémoire de l'extension, piste `seul6` avec ce trajet (3 relances) : 17 Mo, pic 22 Mo ; un premier rendu juste après
installation monte à 46 Mo une fois (Debug simulateur). Simulateur : 53 images sur 53 différentes sur une vidéo de 14 s (poisson
visible à des positions, tailles et sens différents : `reports/widget/nage-1.png` à `nage-6.png`).
Seule une vidéo sur iPhone réel juge le rendu final.

### Alternative « tous les poissons » (3 poissons à 4 images/s) : ESTIMATION, non mesurée

3 poissons × 40 copies = 120 copies, comme `seul12` (34 à 35 Mo pour UN poisson avec une image), plus deux images de poissons
en plus (chaque image distincte coûte environ 5 Mo de pic pour 3 poissons, voir plus haut) : environ 38 à 40 Mo, au-dessus des
28 à 30 Mo. Ça ne tient pas. Le code ne dessine d'ailleurs que le premier poisson (`NageSeule`) ; tout essai demande d'écrire la
variante à 3 poissons.

### Images de queue distinctes (8 nov. soir)
Poisson unique, `seul6`, pic `phys_footprint_peak` du widget (Debug, simulateur, machine chargée) : 1 image de queue 22 Mo, 4 images 25 Mo, 8 images 27 Mo. Retenu : 4 (défaut de `NageSeule.imagesQueueRetenues`). NON PROUVÉ : ces mesures sont faites alors que le widget restait figé dans le simulateur (captures identiques sur 7 s, machine à forte charge) ; l'œil n'a donc pas vu le battement de queue. Seule une vidéo sur un vrai iPhone ou un simulateur au calme le juge.
