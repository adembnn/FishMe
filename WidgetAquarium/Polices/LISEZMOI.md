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
