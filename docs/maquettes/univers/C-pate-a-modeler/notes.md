# Univers C : Pâte à modeler (U5)

## Références réelles
- Aardman (Wallace et Gromit, Shaun le mouton) : https://www.aardman.com/ — empreintes de doigts visibles, pâte qui « bout » à 12 images par seconde.
- Kirby's Epic Yarn (volumes gonflés, monde fait de matière) : https://kirby.fandom.com/wiki/Kirby%27s_Epic_Yarn
- DynaPuff (police, Google Fonts / Fontsource) : https://fontsource.org/fonts/dynapuff
- Technique : feDiffuseLighting / feSpecularLighting sur alpha flouté (MDN) https://developer.mozilla.org/en-US/docs/Web/SVG/Element/feDiffuseLighting

## Palette
Turquoise #2FB5B0 (planche, arbres, boutons C/E), orange #FF7A3D (coin choisi, Sortie), jaune beurre #FFD84A (cadre peu commun), rose #FF8FB0 (collines, boutons A/D), crème #FFF0C4 (face des cartes), brun d'encre #32190B (texte), rivière bleue #2F9ED6. Police unique : DynaPuff 500/700 (woff2 local) ; police système seulement pour la barre d'état.

## Ce qui rend l'univers enfantin
Tout est modelé : boules, boudins, boutons à deux trous, arbres sur bâtonnets, poissons à gros yeux. Une seule lumière (haut gauche, azimut 225) pour le CSS (box-shadow) comme pour le SVG (filtres), donc les ombres tombent toutes en bas à droite. Vraies empreintes de doigts (empreinte.svg, anneaux déformés par feTurbulence) posées sur le dos du poisson, les collines, la rivière, la tranche des cartes. Le coin choisi « bout » à 12 i/s (steps(1), une pose toutes les 2 images). Révélation : boule lâchée, écrasée, étirée, rebond, poisson ; 30 images en 2,5 s via steps(n) par intervalle, état final à 2,5 s ; prefers-reduced-motion = simple fondu.

## Raretés (lisibles en noir et blanc, vérifié avec un filtre grayscale)
Mat (gardon) : tranche 5 px, grain visible, aucun reflet, 1 perle. Satiné (brochet) : tranche 11 px, un reflet large, 2 perles. Vernis (sandre) : tranche 15 px, reflets serrés humides, 3 perles. Vernis + paillettes dorées (truite fario) : tranche 20 px, liseré doré, étoiles qui scintillent à 12 i/s, 4 perles. Le mot de la matière est écrit sur chaque carte.

## Liquid Glass
Seulement sur les contrôles (pastille de lieu, fiche, barre d'onglets, Sortie, boutons de la prise) : « couvercle de boîte » avec reflet diagonal. Le décor reste en pâte.

## Constats du détecteur impeccable
- low-contrast 3,3 / 4,4 (carte) : faux positifs, le détecteur compare le texte au fond de page sans voir le verre dépoli. La pastille de lieu a un fond crème à 55 % et le texte brun foncé sur le verre mesure plus de 7:1 à l'écran ; texte des boutons C/E : brun #1d0c03 sur turquoise ≈ 6:1.
- low-contrast blanc sur #ffd84a / #a5cdcc (prise) : lecture de la couleur de repli ; le bouton « Garder possible » est blanc sur turquoise #2FB5B0 avec ombre portée brune (à surveiller : contraste ≈ 2,5 hors ombre, voir risques).
- shape-assembled-illustration : assumé, le diorama est un montage de volumes simples, c'est le langage de l'univers.
- dark-glow #a03200 : ombre de tranche brune des boutons orange, décalée (pas un halo) ; faux positif.
- clipped-overflow / nested-cards : cadre d'écran iPhone fixe et carte dans carte voulus (face en creux dans le cadre de pâte).

## Risques
- Le grain feTurbulence est fort : très tactile, mais peut fatiguer sur grand écran ; à calmer en production.
- Contraste du texte blanc sur turquoise de la pastille « Garder possible » proche de la limite AA : passer en brun sur beurre si le design est retenu.
- Coût de rendu : une quinzaine de filtres SVG d'éclairage par écran ; à pré-rendre en images pour une vraie app.
- Barre d'onglets : Sortie est au centre, avec 2 onglets à gauche et 1 à droite (asymétrie assumée).
- Poissons générés par code, quatre morphologies : crédibles mais pas encore du modelage « fait main ».

## Probabilité qu'un autre LLM propose cet univers
13 % (source : univers-jeux.md, U5). Sous 20 %.

## Passe 2 : parcours complet
Écrans ajoutés : fiche, sortie, photo, verdict, pescedex, paywall, bredouille + planche.png (9 écrans). Bouton « Garder possible » corrigé : texte brun #1d0c03 sur turquoise (≈ 6:1) au lieu de blanc. Chiffres harmonisés : gardon 24/29, brochet 10/29, sandre 3/29.
Éléments propres à l'univers : jauge de taille en règle de pâte (60 mini / bille à 68), pile de cartes de raretés (paywall), lune de pâte en croissant (bredouille), silhouettes en creux pour les espèces non relevées.
Pescedex : « 3 espèces sur les 11 relevées dans le 94 » + « Légendaires · 1 sur 3 » (la truite fario est légendaire, hors des 11) ; 4 cartes gagnées.
Détecteur passe 2 : cramped-padding, clipped-overflow, nested-cards, flat-type-hierarchy, repeating-stripes (zone « trop petit » hachurée) = voulus ou faux positifs (cadre iPhone fixe, face en creux dans cadre de pâte). low-contrast blanc sur #a5cdcc (sortie, prise) = couleur de repli du creux, le texte est sur la planche turquoise sombre (≥ 5:1). dark-glow = ombres de tranche brunes, pas des halos.
