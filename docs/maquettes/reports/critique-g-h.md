# G et H : les ingrédients d'une carte qui n'appartient qu'à nous
En image : G et H sont deux beaux formulaires en forme de carte, et ils ressemblent encore trop à leurs modèles (Pokémon, EA FC), qui ne devaient servir que d'inspiration. Ce qui suit ne corrige pas ces copies : on garde ce qui marche dans chacune pour en faire une seule carte originale. Mesures prises sur les captures et l'index.html (écran 393 × 852).

## Ce que G apprend : 5 ingrédients pour la carte maison
1. **Le poisson est le sujet, pas une vignette.** Dans G, la fenêtre fait 206 px sur 482 (43 %) et le poisson couvre environ 12 % de la carte, contre 52 % pour le texte. Règle maison : illustration ≥ 55 % de la hauteur, poisson ≥ 30 % de la surface, nageoire ou museau qui déborde du cadre de 10 à 14 px.
2. **La carte prend toute la scène.** Dans G, 144 px au-dessus répètent la règle (68 et 60 apparaissent chacun 3 fois). Règle maison : carte de 361 px de large (16 px de marge), haut de carte à y ≈ 104, verdict en pastille de 28 px accrochée au bord de la carte ; chaque chiffre une seule fois.
3. **Une matière à nous, pas un cadre de jeu.** Le cadre plein de couleur et le liseré laiton de G font gabarit de TCG. Règle maison : cadre en dégradé de couleur à 2 étapes (écart de clarté 6 %), biseau de 1 px, filet doré visible seulement quand on incline (opacité 0 → 0,8) ; infos gravées en creux, pas de pilule.
4. **Deux tailles de texte sous le nom.** G met nom et chiffres à 21 px. Règle maison : nom 30 px, « 68 » en 32 px (« cm » 14 px), puis 15 et 12 px seulement ; une seule info de pêche au recto, le reste au verso.
5. **Lumière et révélation.** Règle maison : 3 plans qui se décalent quand on penche le téléphone (fond d'eau 0, poisson ±6 px, herbes de premier plan ±10 px pour ±8°), liseré de lumière 1,5 px sur le dos du poisson, ombre de contact floue de 24 px. Révélation : la carte remonte avec un léger rebond (450 ms), un reflet la balaie (350 ms), une vibration quand « 68 cm » se pose à 900 ms, fini à 1,4 s ; un toucher passe l'animation.

**Signature n° 1 : le cadre est une toise.** Le bas de la carte est la planche à mesurer des pêcheurs : graduations gravées, butée à gauche, museau calé contre elle, queue posée sur le trait 68, cran au trait 60. Le verdict se lit sur l'objet, la réglette du haut disparaît. Aucun jeu de cartes n'a ça. Probabilité qu'un autre LLM le propose : 8 %.

## Ce que H apprend : 5 ingrédients de plus
1. **Le métal doit avoir l'air de métal.** L'argent de H est un brouillard gris. Règle maison : 3 à 4 bandes de reflet à bords nets (#FAFBFC / #7E8A91), stries de métal brossé à 15°, chanfrein de 2 px, chiffres estampés (ombre interne et reflet de 1 px).
2. **Un seul grand nombre, et il est vrai.** Dans H, le « 72 » écrase le « 68 » mesuré, et « CAR » ne parle pas à un pêcheur. Règle maison : le grand nombre est un chiffre calculable et expliqué (partie 4), avec un libellé en clair.
3. **Le poisson sort de la carte, exprès.** Dans H, il touche le haut sans le franchir et passe derrière les badges. Règle maison : diagonale assumée, tête qui dépasse de 16 px avec son ombre sur la carte, corps qui passe derrière la plaque du nom, longueur visible ≈ 115 % de la hauteur.
4. **Pas de texte sur la texture.** Règle maison : plaque d'infos lisse, motif seulement dans le tiers haut, contraste ≥ 7:1.
5. **Des motifs à nous.** Les chevrons et losanges de H viennent d'EA FC et de TCG Pocket. Règle maison : lignes de profondeur de la rivière de la prise, gravées à 0,5 px, opacité 8 % ; symboles de rareté maison (partie 3). Variante de révélation : la carte sort de l'eau, des gouttes glissent sur le métal (600 ms), le soleil la traverse une fois (400 ms).

**Signature n° 2 : la lumière de l'heure de prise.** Le reflet et le liseré viennent de la vraie position du soleil au lieu et à l'heure de la prise (calculée depuis la date, l'heure et le GPS). Pour 17 h 42 un 12 octobre à Champigny : soleil bas et chaud venant de l'ouest ; une prise de midi a une lumière blanche par le haut, une prise de nuit un reflet de lune froid. Probabilité : 4 %. Les deux signatures s'additionnent sur la même carte.

## Le poisson en vrai sujet de carte
Détourage VisionKit + 4 traitements Core Image : liseré de lumière côté soleil, ombre de contact + ombre portée longue, contraste +8 % et nageoires un peu plus saturées (+10 %), herbes au premier plan devant le poisson. Le poisson ne fait jamais moins de 80 % de la largeur de la fenêtre.

## Rareté maison : quatre objets de la boîte à pêche
Chaque symbole a sa propre forme, lisible en 13 px même sans couleur ; la matière monte d'un cran par palier.
- **Commun : le plomb** (disque plein). Papier mat sans reflet, encre seule, pas d'effet à l'inclinaison.
- **Peu commun : le bouchon** (flotteur vertical bicolore). Nacre sur l'illustration seulement, motif tiré des cristaux qui rendent les écailles irisées, teintes eau et champagne, intensité 0,35 au plus.
- **Rare : la cuiller** (leurre ovale percé). Chrome miroir sur toute la carte, fines lignes prismatiques qui suivent l'inclinaison, le poisson déborde du cadre sur 1 côté.
- **Légendaire : la mouche** (petit triangle ailé sur un hameçon, montée à la main, donc unique). La carte devient de l'eau : reflets de fond qui bougent en continu (cycle de 6 s), tranche dorée, poisson qui déborde sur 3 côtés, révélation plus longue de 800 ms avec une vibration en deux temps. Numéro « 1er du 94 cette saison » au lieu du simple 06/14.

## Stats honnêtes ou inventées (bloc d'infos de la carte)
Inventées, à retirer : VIT, COM, DIF, AFF (notes de rédaction sans source), et le « 72 » tant que sa formule n'est pas dite.
Honnêtes et calculables, chacune dans son unité réelle plutôt que sur 99 (valeurs ci-dessous = exemples, pas encore calculées) :
1. **TAI 68 cm** : mesurée sur la photo.
2. **CEN 84e** : rang de cette taille sur 100 parmi les brochets mesurés dans le 94 (pêches électriques de l'OFB, données publiques Naïades / Hub'Eau).
3. **FRQ 18 %** : part des stations de l'OFB du 94 où l'espèce est relevée (c'est la base du palier de rareté).
4. **ÂGE ≈ 4 ans** : estimé depuis la taille par la courbe de croissance de l'espèce (FishBase), toujours avec « ≈ ».
5. **SAI 273 j** : jours ouverts dans l'année selon l'arrêté départemental.
6. **EAU 14 °C** : température de l'eau au relevé Hub'Eau le plus proche, à l'heure de la prise.
Le grand nombre devient CEN ou FRQ inversée, avec sa formule en une ligne au verso.
