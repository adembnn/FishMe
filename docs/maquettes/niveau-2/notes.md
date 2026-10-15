# Niveau 2 tempéré : parcours de démo en 9 écrans (+ raretés)

Cible : le niveau 2 de l'échelle (carte de jeu soignée, eaux claires, pastilles, boutons pilule), tenu en laisse par le calme des niveaux 0 et 1. Pas de contour noir, pas de poisson dessiné, pas de confettis. Le poisson est toujours la vraie planche de Bloch détourée (`assets/fish`).

## Choix
- Police : Nunito 700/800/900 (celle du niveau 2), locale. Chiffres et titres en 900, texte en 700/800, rien sous 13 pt.
- Couleurs : eau (#CBEFF7 vers #2380AA), marine #06384D pour le texte, papier #F6FDFF pour les cartes. Raretés : gris-ardoise #4F6673, vert #157A4E, bleu #1E5BB8, or #F2B63A.
- Verre (Liquid Glass) seulement sur les contrôles : barre d'onglets, boutons, bouton fermer, feuille du coin B. Les cartes sont opaques.
- Raretés lisibles en noir et blanc (vérifié sur `raretes.html` passé en niveaux de gris) : forme du badge (rond, hexagone, losange, étoile), 1 à 4 points, filet de cadre de plus en plus riche, fond d'illustration de plus en plus sombre.
- Données alignées sur le brief : gardon 24/29, brochet 10/29, sandre 3/29, truite fario jamais relevée ici. Pescedex : 3 sur 11 espèces du 94 (gardon, brochet, sandre) ; la truite fario est comptée à part dans les légendaires (1 sur 3), car elle n'est pas relevée dans le 94.
- Silhouettes du Pescedex : calculées par PIL depuis le canal alpha de chaque PNG d'espèce (perche, chevesne, brème, silure, tanche, carpe, barbeau, rotengle), pas une forme réutilisée.
- Barre d'onglets : Carte, Pescedex, Sortie (bouton rond surélevé), Moi, en quatre colonnes égales. Le bouton Sortie est donc à 30 px à droite du centre exact (compromis, voir faiblesses).
- Prise : portée de niveau-2. Le titre n'est plus posé sur le dégradé du fond mais sur une bande claire propre, ce qui règle l'alerte de contraste.
- La prise, la fiche et les autres écrans reprennent l'état final (animation de la prise finie en moins de 2,5 s, `prefers-reduced-motion` = fondu).

## Détecteur impeccable : constats et justifications
- `gpt-thin-border-wide-shadow`, `dark-glow`, `side-tab` : matière Liquid Glass (bord de 1 px + ombre large) et relief inférieur du bouton principal. Voulus, comme aux niveaux précédents. `dark-glow` : le détecteur lit le bas du dégradé comme page sombre.
- `clipped-overflow-container` (html, body, main.screen) : cadre d'iPhone 393x852, voulu.
- `cramped-padding` : `.op` corrigé (padding vertical ajouté), `.mc` corrigé (5 px en bas). Reste sur la jauge `.g` du verdict : les libellés sont posés en absolu autour de la piste, faux positif.
- `flat-type-hierarchy` (sortie, photo) : tailles 14 à 18 px de petits textes de service autour d'un seul gros chiffre ; hiérarchie portée par le poids 900 et le gros chiffre. Gardé.
- `repeating-stripes-gradient` (fiche) : hachures de la ligne « jamais relevée ici », qui disent « pas encore dans ce coin ». Gardé.
- Raretés : contraste 4,2 et interligne 1,2 corrigés. Restent les deux alertes de `base.css` (bouton jamais utilisé sur cette page).

## Faiblesses
- Bouton Sortie décentré (voir plus haut).
- Carte : fond sans tuiles réelles (aplats, tracé de la Marne à la main), les noms de communes sont indicatifs.
- La « photo » de l'écran d'identification est le poisson détouré dans un cadre de visée, pas une vraie photo.
- Contrastes lus sur capture et par le détecteur, pas mesurés sur tous les verres.
- Animations vérifiées sur l'état final à 2,8 s, pas en vidéo.
