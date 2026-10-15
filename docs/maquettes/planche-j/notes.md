# Planche J, La toise
Direction : la carte est une toise verticale de pêcheur (butée en haut avec le nom, graduations gravées à gauche, cran de taille mini). Le museau touche la butée, la queue tombe sur la longueur mesurée, et un curseur passe devant le poisson. Signature estimée à ~8 %.
Polices : Bricolage Grotesque 700 (nom 30 px, 68 en 32 px), Hanken Grotesk (15 et 12 px), IBM Plex Mono (graduations, n°). Aucun serif.
Couleurs : accent #1B6B5E (écran, curseur), encre #14201D, butée #17493F ; chaque palier a sa matière (voir raretes.html) : papier #E2E7E5, nacre #EBF3F1, chrome #F8FAFB/#A3AEB5, or #FFF1BF/#C79A33.
Audace unique : la révélation est une mesure. Le curseur descend la toise de 0 à 68 en 0,6 s, le chiffre compte avec lui, il se pose à 0,9 s (haptique rigide sur iPhone), le reflet balaie une fois, tout est fini à 1,4 s. Reduced-motion : fondu.
Raretés : plomb (disque fendu), bouchon (flotteur bicolore), cuiller (leurre ovale percé), mouche (hameçon, corps, aile, hackle), tracés à la main dans un sprite SVG, trait 1,6 sur grille 24. Lisibles à 13 px sans couleur (rangée en bas de raretes.png).
Matières : commun papier mat sans mouvement ; peu commun nacre limitée à la silhouette du poisson (masque alpha), intensité 0,33 ; rare chrome miroir, bandes à bords nets, stries brossées, lignes prismatiques au pointeur ; légendaire or, poisson qui déborde de 26 px, balayage de lumière continu.
Reprises : verdict en une ligne et barre de verre (planche G), barre d'état iOS (D/G). Le plan du poisson (liseré, ombre de contact + ombre longue, contraste +8 %) suit critique-g-h.md.
Valeurs d'exemple (à calculer) : tailles mini 60 / 50 / 25 cm, prises 24 / 68 / 61 / 52 cm, n° 03 / 06 / 09 / 12 sur 14, « 20 à 50 % des 29 pêches », « 0 pêche sur 29 » (donnée du coordinateur).
Détecteur : reste monotonous-spacing (pas de 8 px de la barre iOS reprise) et repeating-stripes (stries brossées et lignes prismatiques : ce sont la matière du chrome et de l'or, pas un décor).
Pas atteint : la cible « poisson ≥ 30 % de la surface » n'est pas tenue pour le brochet (≈ 22 % de la zone graduée, cadre 105 × 360 px) car il est mince et la queue doit rester sur 68 ; gardon 39 %, sandre 31 %, truite 32 % (cadre du poisson ÷ zone 361 × 468, calcul sur les cadres alpha). Le cran de 60 est un triangle peint, pas une vraie découpe.
La nacre est discrète à l'arrêt (plafond 0,35) : elle se lit surtout à l'inclinaison. Le haptique et l'inclinaison sont testés au pointeur, pas sur un iPhone.
## En SwiftUI
1. Toise : ZStack avec un Canvas pour les graduations (échelle = hauteur utile / taille max de l'espèce), butée = Rectangle avec dégradé et ombre intérieure.
2. Poisson : le détourage VisionKit, rotation -90°, museau calé à y = butée, hauteur = taille × échelle. Liseré : copie blanche décalée de 1,5 px derrière ; ombres : deux .shadow ; contraste : .contrast(1.08).
3. Inclinaison : CoreMotion (pitch, roll) vers deux CGFloat ; parallaxe .offset par plan (poisson ±6 pt, curseur ±10 pt) ; reflet = Metal shader (.colorEffect) ou LinearGradient avec blendMode .colorDodge, masqué par l'alpha du détourage (.mask) pour la nacre.
4. Chrome et or : bandes dures en LinearGradient dont le point de départ suit le roll, stries en Canvas.
5. Révélation : withAnimation(.spring(duration: 0.45, bounce: 0.28)) pour la montée, curseur en .easeInOut 0,6 s, UIImpactFeedbackGenerator(.rigid) à l'arrivée. Reduce Motion : .opacity seul.
