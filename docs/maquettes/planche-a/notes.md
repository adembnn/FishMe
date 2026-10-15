# Planche A, Carte de sport brillante
Direction : écran blanc froid (#F4F7F8), la carte saturée porte toute la couleur ; anatomie Topps/Panini (plaque du nom, longueur en haut à droite comme les PV de TCG Pocket, symbole de palier en pied, dos imprimé).
Police : Bricolage Grotesque 700 à largeur naturelle, interlettrage serré (-0,035 em) ; IBM Plex Mono seulement pour les mesures et le numéro. Couleurs : eau #0E6B5C, balise #F2C230, encre #101418.
Audace : le foil du palier 2 = une seule couche de reflets mous d'eau (caustiques déformés, plus de fines lignes) dont l'origine suit le pointeur ; état figé joli.
Mouvement : une séquence GSAP (dos, retournement, reflets qui se posent, verdict en fondu, tampon qui tombe en dernier) finie vers 1,8 s. prefers-reduced-motion : fondu seul, pas de suivi du pointeur.
Poisson (détourage simulé par ../assets/fish/brochet.png) : contour blanc d'autocollant (feMorphology dilate sur l'alpha) + ombre + saturation 1,12. Sur iPhone : masque VisionKit, CIMorphologyMaximum sur l'alpha, CIColorControls, ombre CALayer. Foil : shader Metal colorEffect piloté par CoreMotion.
Sources : brief ; ecrans-references.md 4 et 5 ; inspirations.md (méthode pokemon-cards-css réécrite, aucun code copié) ; Fish Rules (verdict + réglette). Pas de recherche web.

## Passe de correction (ce qui a changé)
- Verdict en haut : bandeau teal plein (rond + coche + GARDER POSSIBLE, texte blanc) ; réglette graduée 0, 20, 40, 60 mini, 80 avec repère 68 ; raisons et « Règle nationale, indicative · Signaler une erreur » en petit dessous.
- Lieu : « La Marne, Val-de-Marne (94) », plus de commune. Donnée : « 4 espèces sur les 11 relevées dans le 94 ».
- Face de carte allégée : nom, taille, poisson, phrase de rareté, source, une ligne date/lieu, palier, tampon. Plus de feuille de mono ; latin en Bricolage (italique synthétique).
- Un seul effet brillant (suppression de la bande de reflet, du liseré et des anneaux fixes). Fausse condensation scaleX supprimée.
- Dock : barre de verre translucide (flou, saturation) unique, qui contient les deux boutons ; bouton principal plein dedans (pas de verre sur verre). Lueur colorée plus forte derrière pour que le verre se lise.
- Geste propre : le numéro de série est un tampon de licence jaune, légèrement tourné, posé sur l'eau et qui tombe en dernier.
- Barre d'état : SVG dessinés, 9:41 semibold.
Détecteur, restes justifiés : clipped-overflow (cadre iPhone .screen, voulu) ; nested-cards (cadre imprimé intérieur de la carte à collectionner) ; repeating-stripes (hachures sous 60 cm de la réglette, elles portent le sens) ; low-contrast x3 = faux positif : encre #101418 sur le disque jaune du tampon (ratio d'environ 11:1), le détecteur lit le fond teal derrière.
Non fait / à noter : « peu commun » apparaît deux fois (titre de rareté et phrase différenciante imposée par le brief) ; texte sur arc du tampon abandonné (rendu SVG cassé) ; gyroscope réel, Dynamic Type, mode sombre ; SF Pro remplacée par Bricolage en capture Linux.
