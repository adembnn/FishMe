# Lot 3 : collectionner (K2, X1, V1, F1, F3, K4, K3)
Source de style : planche-k (CSS et JS de la carte copiés, pas redessinés ; cartes figées, sans animation, lumière du soleil de la prise). Génération par un script hors dossier ; les HTML sont autonomes. Données de cartes ajoutées (perche, silure, carpe, tanche, amis, 001) : valeurs d'exemple, à calculer en vrai.

## Références par écran
- K2 Pescedex : Pokémon TCG Pocket (vue Pokédex, manquantes en silhouette) et Merlin Life List. Grille 3 colonnes, carte K à l'échelle 0,313.
- X1 état vide : mêmes références ; silhouettes seules, une phrase, un bouton.
- V1 paywall : Finch et fiches d'essai gratuit (ScreensDesign) ; fond = la carte qui vient d'être gagnée ; fermeture et restauration visibles.
- F1 amis : Apple Fitness (partage d'activité), Find My ; ni recherche ouverte ni inconnus.
- F3 Pescedex d'un ami : Apple Fitness ; menu Signaler / Bloquer / Retirer ouvert (règle Apple 1.2) ; « nouvelle » en vert sur les espèces qu'on n'a pas.
- K4 image de partage : Spotify Wrapped, Duolingo Friends Quest (une carte, fond plein). K4-image-9x16.png fait 1080x1920 ; K4-image-partage = l'aperçu avant envoi.
- K3 bredouille : Finch (streak qui pardonne) ; la lune remplace le poisson ; reflet de la lune sur l'eau, lignes de fond de la Marne comme sur la carte K.

## Écarts avec le parcours (notés, non tranchés)
1. « 4 espèces sur les 11 relevées » : la truite fario est légendaire, donc hors des 11 relevées (donnees.md : 14 jouables, 3 légendaires jamais relevées). Les 4 cartes montrées (gardon, brochet, sandre, truite) comptent donc 3 sur 11 + 1 hors relevé. J'ai gardé le compteur imposé pour montrer les 4 finitions.
2. K3 : le parcours E9 donne lieu, date, lune ; météo et durée viennent avec la session (version suivante). La carte montre la météo (14 °C, exemple) comme la carte-ecrans, pas la durée.
3. Phase de lune de K3 calculée en JS (lunaison moyenne) : 2 % le 12 oct. 2026 à 17 h 42.
4. V1 : les deux bénéfices (« raretés et règles de chaque département », « Pescedex de tes amis ») sont des propositions à valider ; le périmètre payant n'est pas décidé. Prix en emplacement gris « à fixer ». Les états achat en cours, échec, hors ligne, déjà abonné ne sont pas dessinés.
5. Nom de l'app : emplacement « nom de l'app » en pointillés sur K4 ; aucun nom écrit.
6. Barre d'onglets : trois onglets en verre + bouton rond Sortie détaché (carte-ecrans §3, recommandation non validée).

## Détecteur impeccable (apres correction : halo vert du bouton Sortie remplacé par une ombre neutre)
- gradient-text (tous) : hérité de la carte K peu commune (vernis du chiffre CEN), justifié dans planche-k.
- flat-type-hierarchy (F1, K3, K4) : tailles de l'écran iOS (12/15/17), comme planche-k.
- cramped-padding F1 (ligne de liste sans encadré, séparateur seul) et K4 (l'image 9:16 est un aplat plein cadre, texte à 100 px des bords) : faux positifs.

## Faiblesses
- Lune de K3 : à 2 % l'éclairage est un filet à droite ; le disque se lit comme une lune sombre. Une autre date donnerait un croissant plus net.
- Dans la grille, le texte des cartes à 113 px est illisible hors nom ; le nom est repris en légende (petite redondance assumée).
- K2 et F3 : la quatrième ligne passe sous la barre de verre (défilement) ; X1 ne montre que 6 silhouettes.
- Avatars de F1 : initiales sur aplat, pas de vraies photos. Les cartes d'amis sont des valeurs d'exemple.
- Pas testé sur iPhone ; le coût des filtres feTurbulence (cartes rare et légendaire en grille) reste à mesurer.

## Passe 2 (critique-ecrans.md, décisions par défaut a / a)
- K2 : compteur « 3 espèces sur les 11 relevées dans le 94 », « Légendaires · 1 sur 3 », « Sorties · 1 ». Carte « mini » = même carte K, stats et libellés cachés, on garde centile, poisson, nom (42 px) et pictogramme de rareté ; plus de légende sous les cartes gagnées, légende gardée sous les silhouettes. Segment « Les miens / Amis ». Heure 17:45.
- X1 : une seule action (bouton dans la page, bouton rond retiré, barre d'onglets pleine largeur). F3 : légende « nouvelle » seulement, retour et « ··· » en ronds de verre 44 pt, 17:46. F1 : Léa, Malo, Inès, 17:46.
- V1 : carte entière à 0,6 (216 x 312 pt), inclinée de -4°, sans masque ; bénéfices : raretés et règles de tous les départements, cartes en nombre illimité ; plus d'amis ; fermeture en rond de verre ; 17:44.
- K3 : seul le croissant éclairé (#F3F5EF) et un contour de 1 pt à 25 %, descendu de 24 pt ; heure 18 h 55 (barre d'état 18:55, 12 oct.) ; bouton « Ranger avec mes sorties ».
- K4 : l'image porte « Rejoins-moi avec ce code » + code d'exemple 7K2 M9Q (Bricolage) ; 17:45 ; fermeture en rond de verre.
- Sortie = flotteur (bouton rond et bouton de X1). Détecteur : mêmes constats justifiés qu'en passe 1.
- Reste : lune à 2 % = filet très fin ; plaques mini avec un vide sous le nom ; code d'invitation fictif ; la barre d'onglets de C1 relève du lot 1.
