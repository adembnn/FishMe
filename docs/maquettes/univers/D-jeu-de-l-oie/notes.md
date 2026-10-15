# Univers D : Jeu de l'oie des étangs (U7)

## Références réelles
- Jeu de l'oie, jeux de plateau familiaux, cartes à jouer (indices dans les coins, dos à losanges) : codes repris, aucun visuel copié.
- Source du fond de carte : `maquettes/assets/geo/` (Natural Earth 10 m pour la Marne et la Seine, départements simplifiés IGN/Etalab). Police : DM Serif Display via @fontsource (https://www.npmjs.com/package/@fontsource/dm-serif-display), OFL.
- Section U7 de `reports/univers-jeux.md`.

## Palette et police
Vert tapis #1F6B4F, crème #F6EBCF / papier #FBF3DC, rouge #C73E2E, bleu nuit #1B2A49, plus deux ajouts : or #E0A526 (légendaire) et eau #6BB4E0. Une seule police d'univers, DM Serif Display ; système (SF/Arial) pour les petits textes.

## Le risque géographie, et la réponse
Le plateau n'est pas une spirale : le ruban de cases suit la vraie Marne (tracé Natural Earth, lissé), de la confluence avec la Seine à Charenton (Départ) vers l'amont. La boucle de Saint-Maur est lisible d'un coup d'œil, la Seine, Paris, le contour du 94 et six communes réelles sont dessous. Les coins A à E sont des octogones posés sur le fleuve à leur position approximative (A Charenton, B Joinville, C pointe de Saint-Maur, D Champigny, E amont). Les distances (4,1 / 2,4 / 1,2 / 3,8 / 6,3 km) sont illustratives, pas calculées.

## Ce qui rend l'univers enfantin
Cases numérotées, pions, dés, dos de carte à losanges, tapis de feutre, contours bleu nuit épais et ombres pleines sous les boutons. Une seule audace : le plateau qui épouse la rivière ; sur la prise, le dé qui roule puis le pion qui saute.

## Raretés (lisibles en noir et blanc, vérifié par rendu en niveaux de gris)
1 pip / pion crème / 1 bague / cadre simple ; 2 pips / pion vert / 2 bagues / cadre double ; 3 pips / pion rouge / 3 bagues / cadre double pointillé + 4 rivets ; 4 pips / pion or couronné / cadre or triple + couronne + rayons. Sur la carte, le dé d'un coin = meilleure rareté relevée là.

## Animation de la prise
Dé (0 à 0,9 s) → pion saute 2 cases jusqu'à B (0,65 à 1,6 s) → carte se retourne (1,4 à 2,25 s) → boutons (2 à 2,4 s). État final avant 2,5 s. `prefers-reduced-motion` : aucune transformation, fondu seul. Poissons : SVG dessinés pour l'univers (aplats + contour), pas de planche de Bloch.

## Constats du détecteur (impeccable)
- low-contrast #1b2a49 sur #1f6b4f (prise) : faux positif, l'outil lit le texte des cartes sur le fond du tapis ; le texte est sur papier crème (contraste > 12:1). Le vrai cas (blanc sur vert verdict, 3,8:1) est corrigé (#247F55).
- bounce-easing : corrigé.
- gpt-thin-border-wide-shadow (carte) : c'est la recette Liquid Glass imposée sur les contrôles ; gardé.
- dark-glow #1b2a49 : ombres pleines décalées sous les boutons (style jeu), pas de halo ; gardé.
- repeating-stripes-gradient : tissage du feutre, voulu ; gardé.
- flat-type-hierarchy (carte), clipped-overflow (body 393x852 fixe), cramped-padding (raretes : enfants en position absolue, marges réelles ≥ 20 px) : justifiés.

## Risques
- Le contour du 94 est très simplifié (polygone anguleux) et la Marne est approximée à ~100 m près : à remplacer par un vrai fond (tuiles) en production.
- Cases numérotées en 13 px : limite basse. Densité forte sur la carte si 5 coins + dés + communes.
- Barre d'onglets déséquilibrée (2 onglets à gauche du bouton Sortie, 1 à droite).
- Jouabilité : le sens « avancer d'une case par prise » est une métaphore, pas encore une règle produit (décision de périmètre à valider).

## Probabilité qu'un autre LLM propose cet univers
7 % (estimation de la section U7).

## Passe 2 : parcours complet (fiche, sortie, photo, verdict, pescedex, paywall, bredouille + planche.png)
- Métaphore : la sortie est un pion posé sur un parcours en serpentin de 14 cases (de l'heure de départ 17 h 16 au drapeau de fin légale 18 h 54, pion en case 4) ; la prise est un dé ; le Pescedex est une boîte de cartes (couvercle rouge, cartes en petit format, silhouettes pointillées pour les espèces non gagnées) ; le verdict est une « case verte ».
- Perche : SVG ajouté pour l'écran photo. Gardon harmonisé à 24/29 (raretes.html, fiche).
- Choix à valider : « 1 h 39 au Coin B » (bredouille) est déduit de 17 h 16 à 18 h 55 ; les cartes 75 / 77 / 94 du paywall sont une métaphore des « plateaux » à débloquer ; les avatars Léa et Malo sont des pions colorés.
- Détecteur sur les 7 nouveaux écrans : mêmes faux positifs que passe 1 (low-contrast navy sur felt : texte sur papier crème ou verre à 84 % d'opacité, le détecteur ne lit que le fond du body), plus : tight-leading corrigé (fiche), skipped-heading corrigé (h2), nested-cards (rangées d'espèces dans le panneau de la fiche, gardé : chaque rangée est une case de jeu).
- Faiblesses : barre d'onglets sur le Pescedex toujours 2+1 ; la 3e rangée du Pescedex passe sous la barre (défilement) ; l'icône de dé sur le couvercle du Pescedex est décorative.
