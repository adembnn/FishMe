# Univers F : Atlas en ligne claire (section U3)

Un album d'aventure pour enfants : chaque coin de pêche est une case de BD dessinée, chaque prise une planche.

## Références réelles
- Ligne claire franco-belge (Hergé, Edgar P. Jacobs, Yves Chaland) : un seul contour noir régulier, aplats saturés, pas de dégradé. https://fr.wikipedia.org/wiki/Ligne_claire
- Planches de pêche Rossignol et albums de l'École des loisirs (cités par `reports/univers-jeux.md`, U3). Pas de personnage de Tintin : l'enfant pêcheur est un personnage neutre (ciré jaune, casquette rouge).
- Police : Gochi Hand (Fontsource, licence OFL), https://fontsource.org/fonts/gochi-hand — fichier local `gochi-hand-latin-400-normal.woff2`. Seule police d'univers. Police système pour les petits textes (13 px).

## Palette
Encre #15120E (contour 3 px partout, poisson compris), papier #FBF1D6, ocre #E3B04B (fond d'album), bleu eau #3F9AD8 / ciel #7CC6EC, rouge #D6402B, jaune #FFD23F, vert #3E9B55, pierre #D9CDB4. Les hex viennent de la fiche U3 ; le jaune et les verts sont ajoutés pour garder des aplats vifs.

## Ce qui rend l'univers enfantin
Légendes jaunes à lettres capitales manuscrites, bulle qui pousse avec le nom, case sélectionnée décollée avec ombre portée dure, bandeau-titre incliné, enfant avec canne, canards, étoiles sur la légendaire. Les raretés se lisent au nombre de cases (1, 2, pleine page, pleine page + bandeau rouge + double cadre), avec un pictogramme de 8 carrés : lisible en noir et blanc.

## Raretés (raretes.html)
Gardon : 1 case. Brochet : 2 cases, le poisson passe par-dessus la gouttière. Sandre : pleine page. Truite fario : pleine page + bandeau + double cadre + bulle « Jamais relevée ici ! ». Les cases vides en pointillés (« ? ») montrent ce que le poisson ne prend pas. Chiffres 24/29 (gardon) et 2/29 (sandre) inventés pour la maquette ; 10/29 (brochet) vient du brief.

## Révélation (prise.html)
Cadre et dessin se tracent (stroke-dashoffset, pathLength=1), puis les aplats se remplissent, le poisson se trace de 1,1 s à 2,0 s, la bulle « BROCHET ! » pop à 1,95 s, la fiche et les boutons montent à 2,1–2,2 s. État final avant 2,5 s. `prefers-reduced-motion` : simple fondu.

## Liquid Glass
Seulement sur les contrôles : fiche du coin, barre d'onglets, bouton Partager (verre teinté ocre, reflet haut). Le bouton Sortie et le bouton Ranger sont teintés, contour encre. Le décor (cases, album) reste plat.

## Détecteur impeccable : constats et justification
- gpt-thin-border-wide-shadow (x3) : bordure 1,5 px + ombre large, c'est la recette du verre iOS 26 sur les contrôles ; gardé volontairement.
- flat-type-hierarchy (carte) : tailles proches (16 à 25 px) ; l'écriture manuscrite est fixée par rôle (légende 16, fiche 21, Sortie 23). Léger point faible assumé.
- cramped-padding (phone, page) et clipped-overflow-container (body) : faux positifs, canevas fixe 393x852 / 1600x900 dessiné à la main.
- Corrigés : contraste du bouton Sortie (blanc sur rouge foncé), easing « bounce » remplacé, rayures décoratives retirées.

## Risques
- Le risque de la fiche (« rétro-scolaire ») est contenu par les couleurs saturées, mais la police Gochi Hand reste un peu « cahier ». Alternative à tester : lettrage BD sur mesure.
- Le poisson est un dessin paramétrique (4 espèces) : proche, pas fidèle à la planche de Bloch ; vérifier les couleurs réelles avant production.
- Coût de production : une illustration de case par coin réel (les 5 scènes sont inventées, pas les vrais lieux).
- Pastille « 3 espèces ! » dans la case B répète la fiche : à supprimer si trop chargé.

## Probabilité qu'un autre LLM propose cet univers
9 % (fiche U3).

## Passe 2 : parcours complet
Écrans ajoutés : fiche, sortie, photo, verdict, pescedex, paywall, bredouille + `planche.png` (9 écrans dans l'ordre du parcours). Chiffres harmonisés : gardon 24/29, brochet 10/29, sandre 3/29 (raretes.html corrigé). Un perche dessiné a été ajouté.
- Pescedex : cartes gagnées = cases de taille variable (1 case, pleine largeur, double hauteur, bandeau rouge pour la légendaire) ; silhouettes grisées pour le reste, avec une forme de poisson de remplacement (chevesne, brème = formes gardon/brochet) : à redessiner.
- Prix du paywall : emplacement gris pointillé « Prix à fixer ».
- Détecteur passe 2 : tight-leading sur les gros titres Gochi Hand (verdict, paywall) : voulu, lettrage BD en grande taille ; autres constats identiques à la passe 1 (verre iOS, faux positifs de canevas fixe).
- Faiblesses : la bulle de la bredouille frôle la lune ; pictogrammes de cases du paywall peu parlants ; le pescedex se coupe sous la barre d'onglets (page qui défile).
