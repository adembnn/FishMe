# Univers B : Écussons brodés (U4)

Veste d'aventure d'enfant : chaque poisson est un badge de mérite scout cousu, la carte est une toile cirée de rando.

## Références réelles
- Écussons de mérite scouts (bordure « merrow », chevrons de grade) : https://en.wikipedia.org/wiki/Merit_badge_(Boy_Scouts_of_America)
- Broderie « merrowed edge » (bord surjeté épais, strié) : https://en.wikipedia.org/wiki/Overlock
- Toile cirée vichy (carte) : motif vichy cousu/imprimé, simulé en CSS (deux bandes crème à 20 %).
- Police : Alfa Slab One (SIL OFL), via `@fontsource/alfa-slab-one`, copiée en local. Petits textes : police système iOS.
- Spécification de départ : `reports/univers-jeux.md`, section U4.

## Palette (point de départ du doc, vérifié à l'écran)
forêt #2F5D3A, kaki #CBB98A, moutarde #D9B64A, brique #B5452E. Ajouts : crème #F5EDD3 (fil, rubans), encre #25301F (texte), denim #3B5163 / #41708A (veste et rivière). Argent et or uniquement pour les fils des raretés 3 et 4.

## Ce qui rend l'univers enfantin
- Aplats de feutre, contours épais, poissons en appliqué avec fil crème pointillé.
- Pastilles-boutons lettrées A à E, sentier en points cousus, « tac ! » à la révélation.
- Rareté lue par la forme : rond (commun, 1 ligne, 1 chevron), ovale (peu commun, 2 lignes, 2 chevrons), écu (rare, bord argenté strié, 3 chevrons), rosace dorée + sceau cousu (légendaire, 4 chevrons). Lisible en niveaux de gris (bandeau de contrôle en haut à droite de `raretes.html`).
- Révélation (prise.html) : bord cousu point par point (masque sur dasharray), poisson en feutre puis contour cousu, ruban, puis « tac » (patch qui s'écrase de 4 %, anneau, mot). État final à 2,5 s. `prefers-reduced-motion` : simple fondu, tout est déjà cousu.
- Liquid Glass : seulement barre d'onglets, fiche, puces, boutons. Un liseré pointillé crème en fait une poche transparente cousue sur le tissu.

## Constats du détecteur (impeccable) et décisions
- Contraste crème sur brique : corrigé (dégradé #AE4029 vers #8E2F1C).
- Bordure fine + grande ombre : ombres du verre réduites à un liseré de 2 px.
- Lueur colorée : le bouton « Sortie » garde une ombre brune douce (0 6px 14px), conservée : ombre portée d'un bouton de feutre moutarde, pas un halo.
- Échelle typo plate (13 à 17 px) : volontaire, ce sont les tailles iOS des petits textes ; la hiérarchie vient d'Alfa Slab (22 à 26 px).
- Rayures répétées : c'est le sergé du denim de la veste (prise et raretes), texture voulue.
- « Illustration en formes primitives » : les écussons sont du dessin d'appliqué en SVG fait pour cet univers, pas un décor générique. Assumé.
- `overflow:hidden` sur body (prise) : cadre d'iPhone fixe de 393x852, sans effet sur le contenu.

## Risques
- Texture feutre (bruit SVG à 50 %) : à la limite du skeuomorphisme 2012 si on l'appuie ; ici ombres plates de 2 px, pas de biseaux.
- Poissons de 4 espèces seulement dessinés à la main ; pour 27 espèces il faudra un gabarit paramétré (corps, nageoires, motif).
- Alfa Slab fatigue en texte long ; réservé aux titres et chiffres.
- Texte de la carte (noms de communes) en police système, pas en broderie : compromis de lisibilité.
- Positions des coins A à E illustratives, pas géolocalisées.

## Probabilité qu'un autre LLM propose cet univers
11 % (doc U4). Sous 20 %.

## Passe 2 : parcours complet
Fichiers : fiche, sortie, photo, verdict, pescedex, paywall, bredouille (+ planche.png, 9 écrans dans l'ordre du parcours).
- Raretés des listes (fiche, photo, pescedex) : même gabarit d'écusson en miniature (rond / ovale / écu / rosace dorée), générés par `patch({mini:true})`. Silhouettes du Pescedex : contour pointillé sur feutre éteint, sans motif.
- Sortie : fil du temps cousu (17 h 16 à 18 h 54), partie cousue en moutarde, aiguille à l'heure courante.
- Bredouille : l'écusson existe, le poisson n'est qu'un contour pointillé « pas encore cousu ». Choix de design à valider : pas de poisson, donc pas de mérite, mais le badge se range quand même.
- Détecteur : plus aucun low-contrast ; restent les trois constats déjà justifiés (sergé denim, écussons dessinés pour l'univers, overflow du cadre iPhone).
- Faiblesses : la perche est un nouveau dessin (la seule des 4 espèces illustrées en plus) ; pour chevesne, brème, silure, tanche, carpe, barbeau, une silhouette unique de gardon sert de placeholder ; le texte 13 px de la fiche (règle, source) reste petit ; « Truite fario » est montrée gagnée au Pescedex et « à chercher » sur la fiche (cohérent avec « légendaire hors 94 », à confirmer).
