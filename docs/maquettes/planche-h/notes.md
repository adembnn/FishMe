# Planche H : carte argent, d'après les cartes Ultimate Team (EA SPORTS FC)
Direction : une carte de joueur dont le « joueur » est le brochet, gravée dans un métal argenté, sur un écran blanc calme (ligne verdict + réglette de la planche E, barre de verre, « Je le relâche » en lien).
Vérifié par recherche web (futwiz.com, fut.gg, fifauteam.com, easportsfifa.fandom.com) : note globale et poste en haut à gauche, puis drapeau, ligue, club ; joueur détouré ; nom ; six stats PAC SHO PAS DRI DEF PHY en deux colonnes ; matière par note (bronze jusqu'à 64, argent 65 à 74, or dès 75).
Palier 2 = argent, donc la note est 72 (pas 78 : 78 serait de l'or).
Traduction : 72 = score de rareté de la prise dans le 94 ; CAR = carnassier ; badges = eau calme (vagues) et département 94 ; une seule couleur d'accent vert #1E7F4F (écran) et vert profond #0F4C3E (taille).
Six stats : TAI 68 (cm, mesurée, seule vraie mesure) ; VIT 79 vitesse d'attaque ; COM 81 combativité ; DIF 74 difficulté de capture ; AFF 83 affût (patience du poste) ; SAI 75 (9 mois ouverts sur 12). Pas de RAR : c'est déjà la note globale. VIT, COM, DIF, AFF sont des indices éditoriaux 0 à 99 par espèce, à sourcer avant la vraie app.
Pas de trade dress : forme à deux coins coupés (en haut à droite, en bas à gauche), pas la forme EA ; Bricolage Grotesque 700 et Hanken Grotesk, pas la police EA ; pas de logos de ligue.
Polices : Bricolage Grotesque 700 (note, nom, stats), Hanken Grotesk, IBM Plex Mono (06/14 et réglette seulement). Couleurs : argent #EEF1F2 / #9AA6AD, encre #172125, vert #1E7F4F.
Audace unique : l'holo argent, réécrit d'après la méthode simeydotme (variables CSS depuis le pointeur, trois couches en mix-blend-mode overlay / soft-light, masques texturés : écailles en arcs + grain fractal). Teintes eau et champagne très basses, aucun arc-en-ciel. Au repos : état figé placé ; au pointeur : reflet et inclinaison de 5 degrés.
Mouvement : la carte remonte, un reflet la traverse une fois et se pose, fini avant 2,5 s. prefers-reduced-motion : simple fondu.
Sur iPhone : le reflet vient de CoreMotion (inclinaison) ou d'un DragGesture ; les couches = Metal shader ou 3 CALayer avec compositingFilter ; matière selon la note.
Non fait : drapeau/club (pas d'équivalent honnête ; remplacés par eau + 94), version bronze/or, texte de ligne de lieu sur la carte (volontairement sous la carte pour le partage).
Détecteur impeccable : zéro anti-pattern après remplacement du repeating-linear-gradient.
