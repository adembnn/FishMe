# Univers A · Aventure douce

## Références réelles (inspiration de codes, aucune copie)
- Pokémon GO / Pokémon Sleep : carte claire, médaillons, Pokédex à étoiles. https://note.com/futurize/n/n7fbf5be3ba95?hl=en
- Pikmin Bloom : sentier de fleurs semées vers la destination. https://en.wikipedia.org/wiki/Pikmin_Bloom
- Animal Crossing New Horizons (pêche + musée) : formes en pastilles, fiches d'espèce. https://fontsinuse.com/uses/51354/animal-crossing-new-horizons
- Duolingo : ombre basse de 4 à 5 px sous les boutons, contours épais (codes sourcés). https://design.duolingo.com/identity/color

## Palette
Marine d'encre #1F2D5C (contours et texte), crème #FFF7E0, soleil #FFC83D, ciel #3FB8E8 / #8DDCFA, herbe #8BDF5C, corail #FF5A4D. Aucun violet.
Raretés : vert #5FC26B, bleu #3AB0F0, orange #FF9A1F, rose-rouge #FF5A7E.

## Police
Fredoka 500/600/700 (`@fontsource/fredoka`, licence OFL, copie locale dans `fonts/`). Chiffres de la barre d'état en police système (fidélité iOS).

## Ce qui rend l'univers enfantin
Contour marine de 4 à 5 px partout, formes sans angle, poissons « jouet » (dégradé vertical, reflet blanc, grand œil, joue rose), carte en aplats avec maisons-jouets et flotteur-joueur, étoiles qui éclatent, poisson qui jaillit d'une gerbe d'eau et retombe dans la carte.
Raretés (lisibles en noir et blanc, vérifié par capture en niveaux de gris) :
- commun : badge cercle, 1 étoile, cadre bois, bord fin
- peu commun : losange, 2 étoiles, cadre argent, 4 rivets, motif de points
- rare : hexagone, 3 étoiles, cadre or plus épais, rivets, bandeau RARE, rayons
- légendaire : étoile à 8 branches, 4 étoiles, cadre prismatique le plus épais, couronne, étincelles, halo

## Animation signée (prise.html)
Carte qui rebondit (0,15 s), gerbe d'eau, poisson qui saute et retombe (0,7 à 1,75 s), étoiles qui s'allument une à une (1,45 s), texte puis boutons (jusqu'à 2,45 s). État final à 2,5 s. `prefers-reduced-motion` : simple fondu de 0,4 s.

## Écart au brief
Barre d'onglets : Carte / Pescedex à gauche, Moi à droite, bouton Sortie au centre et surélevé. Trois onglets et un bouton central ne se répartissent pas de façon symétrique ; la barre est donc un peu déséquilibrée. Alternative possible : Sortie détaché à droite (modèle iOS 26).
Le flotteur du joueur est allongé avec antenne, sans bande centrale, pour ne pas évoquer une Poké Ball.

## Constats du détecteur impeccable, traités ou justifiés
- low-contrast 4,46 et 4,3 (marine sur corail) : corrigé (texte plus foncé, bandeau plus clair).
- tight-leading 1,25 : corrigé, une occurrence restante dans raretes.html (ligne de légende), sans conséquence (une seule ligne).
- bounce-easing : voulu, c'est la signature « rebond joyeux » de l'univers, limitée à la révélation.
- gpt-thin-border-wide-shadow : c'est la recette du Liquid Glass (liseré 1,5 px + ombre portée) ; uniquement sur les contrôles.
- dark-glow : halo or autour du cadre légendaire et ombre marine des boutons ; voulu, rareté la plus haute. Le détecteur parle de « dark page », la page est claire.
- clipped-overflow-container : voulu, le poisson doit rester dans sa carte (scène à overflow hidden) et la page est à taille d'iPhone fixe.
- repeating-stripes-gradient : rayons de soleil (conic-gradient) en décor, voulu.
- border-accent-on-rounded (colline de raretes.html) : décor, trait d'herbe sur colline ronde, voulu.
- flat-type-hierarchy (carte) : petits textes d'interface 13 à 18 px, hiérarchie portée par le poids (700) et la forme.

## Risques
- Le style « jouet marine + soleil » peut sembler proche d'une appli de jeu mobile générique ; le côté pêche tient aux poissons et au flotteur.
- Les poissons sont dessinés à la main en SVG : 4 espèces seulement, il faudra dessiner les 25 (même grille de formes, couleurs changées).
- Liquid Glass sur fond vert vif : lisibilité assurée par un voile blanc à 52 à 80 %, au prix d'un verre moins transparent.
- Ressemblance de codes avec Pokémon GO : pas de personnage, pas de ball, pas de logo.

## Probabilité qu'un autre LLM propose cet univers
Environ 60 % : c'est la direction « jeu de collection » la plus attendue.

## Passe 2 : parcours complet
Fichiers : fiche, sortie, photo, verdict, pescedex, paywall, bredouille (.html + .png) et planche.png (9 écrans dans l'ordre du parcours, PIL). Chiffres harmonisés : gardon 24/29, brochet 10/29, sandre 3/29 (carte, prise et raretés mis à jour).
Ajouts : poisson perche (SVG), mini-cartes du Pescedex (cadre selon rareté, silhouette pointillée pour les espèces non gagnées), flotteur de pêche comme motif récurrent, bredouille en lumière de fin de journée.
Constats du détecteur sur ces 7 écrans : mêmes familles que la passe 1 et mêmes justifications (verre iOS = liseré 1,5 px + ombre ; halo or = légendaire ; rayons = décor ; overflow = poisson dans sa carte ; rebond = signature du verdict). Précisions : side-tab (bord bas de 4 px du bandeau d'en-tête de fiche/sortie) = trait de contour de l'univers ; cramped-padding de la scène de bredouille = illustration pleine cadre, voulue ; tight-leading 1,2 sur paywall = titre sur une ligne.
Faiblesses : le Pescedex montre 4 cartes gagnées pour « 3 espèces sur 11 relevées » (la truite légendaire n'est pas dans les 11, texte du brief respecté) ; les silhouettes réutilisent 4 formes de poisson, les vraies silhouettes par espèce restent à dessiner ; sur le Pescedex la liste passe sous la barre de verre, la dernière carte est donc coupée (comportement de défilement voulu).
