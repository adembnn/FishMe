# Planche C, Empreinte gyotaku (passe de correction)

Direction : la photo détourée devient une empreinte d'encre sumi sur papier washi ; le cachet hanko rouge porte la rareté, le vert est réservé au verdict.
Polices : Darker Grotesque 700 (titre, 68 cm, n° 014, verdict), Bricolage Grotesque (tout le texte courant), DM Mono (date et graduations seulement). Pas de serif. 3 styles.
Couleurs : papier #F6F7F5 (blanc froid, plus de crème), feuille #FCFCFA avec fibres visibles, encre #14110F, gris #4B4B49, hanko #C8321E, verdict #1E7F4F / texte #16603A sur aplat #D6EBDF.
Audace unique : la révélation par pression. L'encre monte de la queue vers la tête (masque) et est absorbée par la fibre (seuil de bruit animé dans le filtre SVG), puis le cachet tombe en dernier. Fin vers 2,3 s ; reduced-motion : fondu.

## Corrections de la passe
Verdict en bandeau vert en haut (pictogramme rond coché plein + GARDER POSSIBLE + réglette 0 à 80 avec 60 mini et repère 68, reprise de la planche B), raisons et mention "Règle nationale, indicative · Signaler une erreur" dessous. REMETTRE À L'EAU aurait un autre aplat et un autre pictogramme (croix dans un hexagone), pas le même vert.
Lieu "La Marne, Val-de-Marne (94)", progression "4 espèces sur les 11 relevées dans le 94". Vraie barre d'état iOS (barres, Wi-Fi, batterie dessinés). Poisson horizontal incliné, à 18 px des bords de feuille. Cachet plein (filtre sur le fond seulement, bords irréguliers, texte net) : "PALIER 2" + 3 marques dont 2 pleines ; "Peu commun" n'apparaît que dans la phrase du lieu. Trait de pinceau supprimé. Barre de verre unique avec les deux boutons.

## Traitement réel
Le PNG passe dans le filtre SVG `#ink` : gris, densité = inverse de la luminance, passe-haut pour les écailles, courbe, déplacement feTurbulence, halo, grain et nuages, aplat #14110F.

## Sur iPhone (Core Image)
1. VisionKit (ImageAnalysisInteraction ou VNGenerateForegroundInstanceMaskRequest) donne l'image détourée avec alpha.
2. CIColorControls (saturation 0, contraste 1,6) ou CIPhotoEffectNoir, puis CIColorInvert pour la densité.
3. Écailles : CIUnsharpMask (rayon 2-3 pt, intensité 2) ou CIEdges ajouté par CIAdditionCompositing.
4. Bavure : CIGaussianBlur 0,5 pt + CIDisplacementDistortion avec un bruit (CIRandomGenerator flouté).
5. Densité inégale : bruit multiplié (CIMultiplyCompositing), CIColorMatrix pour teinter l'alpha en #14110F.
6. Révélation : seuil animé (CIColorPolynomial) par CADisplayLink + masque en dégradé (.mask SwiftUI) ; CoreMotion pour le reflet ; Réduire les animations : fondu. Cachet : PNG + .spring. Un seul CIContext, résultat mis en cache.

## Risque : vraie photo
La maquette part d'une gravure déjà contrastée. Sur une photo de brochet, le seuil peut donner une tache noire sans écailles (dos et ventre sombres, reflets). Repli : (a) normaliser d'abord (CIHighlightShadowAdjust + égalisation locale CLAHE via Metal ou vImage) avant le passe-haut ; (b) fonder la densité sur le passe-haut seul (les écailles) plutôt que sur la luminance ; (c) si le contraste mesuré est trop faible ou trop sombre, bascule automatique sur un simple niveau de gris contrasté, ou sur le contour au sumi (CIEdges) sans aplat. À prototyper sur 3 vraies photos avant de s'engager.

## Références
Gyotaku : Japan Times (31 mai 2026), Tenkara USA / Fresh Catch Gyotaku, Wikipedia. CapWords (ADA 2025) : developer.apple.com/articles/capwords. TCG Pocket (symbole de rareté fixe), Fish Rules (verdict + réglette), pokemon-cards-css (méthode du reflet, réécrite). Icônes Phosphor, un seul style.

## Limites
Pas d'annotations au pinceau (texte typographique). Verre Liquid Glass approché en CSS (.glassEffect() sur iPhone). Filtre animé non mesuré sur appareil. Aucune capture réelle de gyotaku ou de CapWords analysée.
