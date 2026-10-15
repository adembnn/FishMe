# E. Coque de poche (U8)

## Idée
Le jouet des années 90 : un LCD à une seule couleur dans une coque de plastique translucide. Le Liquid Glass iOS 26 est la coque : barre d'onglets, bouton Sortie, feuille du coin, boutons de la prise et l'œuf de la carte de prise sont tous en verre, avec les mêmes reflets et la même teinte turquoise. On voit la carte électronique à travers (pistes, puce, pile), floutée derrière la feuille et la barre. Le décor (LCD, sprites, grille) reste 100 % pixel.

## Références réelles
- Tamagotchi (Bandai, 1996), coques translucides et œuf à anneau de porte-clés : https://fr.wikipedia.org/wiki/Tamagotchi
- Pixelify Sans (Stefie Justprince, OFL) : https://fonts.google.com/specimen/Pixelify+Sans, installée via @fontsource/pixelify-sans (latin 400 et 600, fichiers .woff2 dans le dossier).
- Plaques de poissons de Bloch (domaine public, `assets/fish/`) : brochet, gardon, perche, sandre, truite fario. Chaque sprite est calculé (script du scratchpad) : réduction de l'illustration, contour 1 pixel, aplats sombres, tramage 2x2 sur les tons moyens, œil ajouté. Résultat dans `sprites.js`.
- Aucune image Nintendo ou Bandai copiée : pas de personnage, pas de logo, forme d'œuf générique.

## Palette et police
- Coque turquoise #4DC9D8 (ombre #1B8CA0), rose #FF6FA8, LCD #9EA88A, pixel #1E241A, texte sur coque #05303A, table #DCE3CF.
- Police unique : Pixelify Sans (titres, LCD, pastilles). Petits textes iOS en police système (SF).
- LCD : une couleur, aucun dégradé. Les pixels éteints sont de l'encre à 7 %.
- Rareté : commun = coque pleine crème, mate, contour noir. Peu commun = turquoise translucide. Rare = rose translucide pailleté. Légendaire = or chromé en bandes. Les losanges de l'écran (1 à 4) et le mot répètent la rareté. Vérifié en niveaux de gris : les 4 se distinguent.

## Ce qui rend l'univers enfantin
Un objet qu'on tient en main : œuf, porte-clés, boutons ronds roses, bip. Confettis carrés sur la table. Icônes 8x8 qui rebondissent (carte) ou clignotent (coin sélectionné). Une seule audace par écran : la coque en verre.

## Animation de la prise (prise.html)
Éclair plein écran + bip (0,35 s), balayage du sprite colonne par colonne, glitch de lignes décalées (1,13 s), image 2 (queue décalée d'un pixel), micro-glitch (1,9 s), état figé à 2,3 s. Toucher la coque rejoue. Le bip (Web Audio, 2 notes carrées) ne part qu'après un toucher : les navigateurs bloquent le son à l'ouverture. `prefers-reduced-motion` : état final avec un fondu de 0,35 s.

## Détecteur impeccable : constats et réponses
- low-contrast / dark-glow « sur #111 » : venait du fond de page derrière le téléphone, corrigé (fond turquoise ou table). Plus de constat.
- cramped-padding (lcd, sp, stage) : faux positifs. Le LCD est un canevas de pixels sans texte collé au bord, les pastilles `sp` contiennent un sprite et un mot centrés, `stage` est un décor.
- clipped-overflow-container (.phone) : voulu, l'écran iPhone coupe son contenu.
- gpt-thin-border-wide-shadow : c'est la matière Liquid Glass (liseré clair + ombre large) ; je la garde, elle fait la signature.
- nested-cards : pastilles d'espèces dans la feuille de verre ; choix assumé, c'est une collection de 3 sprites, pas une carte dans une carte.
- flat-type-hierarchy (prise) : 14 à 20 px sur du texte secondaire ; garde car le minimum de lisibilité est 13 pt, mais à resserrer.
- codex-grid-background : la grille de points de la table et la trame du LCD font partie de l'univers pixel ; justifié.
- side-tab (raretes) : ce n'est pas une carte à bord coloré, c'est le rebord de la coque chromée.

## Risques et faiblesses
- Retombée rétro : une couleur LCD, pas de dégradé dedans, mais l'œuf à anneau reste très Tamagotchi.
- Sprites issus d'un tramage automatique : lisibles mais pas dessinés à la main ; le brochet est maigre et son museau peu net. Un pixel artist les referait en 2 h.
- Carte : relief et rivière stylisés (boucle de la Marne simplifiée, pas la vraie géométrie). Le fish du coin B s'efface à côté du curseur.
- Le verre sur fond uni montre peu de réfraction : il faut la carte électronique et les confettis derrière pour que le flou se lise.
- Mode sombre non traité.
- Probabilité qu'un autre LLM propose cet univers : 30 % (courant, selon univers-jeux.md). L'accord verre = coque l'écarte du pastiche.

## Passe 2 : parcours complet
Fichiers : fiche, sortie, photo, verdict, paywall, pescedex, bredouille (html + png), planche.png (9 écrans, PIL), screens.css et app.js partagés. Chiffres harmonisés : gardon 24/29, brochet 10/29, sandre 3/29 (raretes.html corrigé).
- Les écrans du parcours gardent la face turquoise translucide ; prise et bredouille posent l'œuf sur la table. Tout contenu « de jeu » est dans un LCD ou une coque ; les contrôles sont en verre.
- Bredouille : coque quasi transparente (coque vide), LCD sans poisson, bobber et « zzz ».
- Pescedex : les 4 raretés en mini-coques, silhouettes tramées pour les espèces non prises, dans le même format.
- Détecteur sur les 7 nouveaux fichiers : mêmes familles que la passe 1 (cramped-padding du LCD et des lignes, thin-border-wide-shadow du verre, nested-cards, codex-grid de la table, dark-glow signalé à tort sur fond turquoise, clipped-overflow du téléphone) plus flat-type-hierarchy et tight-leading sur la bredouille. Justification identique : verre voulu, pixels voulus ; hiérarchie à resserrer.
- Faiblesses : sprites des silhouettes tramés en 36 à 44 px, peu lisibles à 2 px la case ; le slider de la photo est statique ; paywall sans visuel fort ; la planche a un titre qui touche les étiquettes.
