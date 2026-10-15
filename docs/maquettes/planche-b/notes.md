# Planche B, Guide de terrain précis (passe de correction)

Direction : fiche de terrain lisible au soleil. Le verdict ouvre l'écran, la carte à collectionner a pour fond une topographie en aplats bleus et courbes, comme un extrait de carte IGN, avec le poisson détouré posé dessus et mesuré.

Polices : Hanken Grotesk 400/600/700 ; IBM Plex Mono 600 seulement pour 68 cm, n° 014 et la graduation. Locales (../assets/fonts). Barre d'état et barre d'actions : pile -apple-system.
Quatre tailles de texte : 48 (nom), 20 (verdict, cote 68 cm), 14 (corps), 12 (légendes, graduation).
Couleurs : #FFFFFF, bleu hydro #1F6FB5, vert verdict #1E7F4F (bandeau, réglette, rien d'autre). Encre #0B2238. Bandeau vert pâle #E8F4EC.
Audace unique : la topographie du spot en fond de carte, bolder qu'avant (palier de teintes bleues entre courbes, rivière claire bordée de bleu). Rivière : ligne Natural Earth Marne (assets/geo, réelle mais grossière) projetée avec d3-geo, ondulée par du bruit. Courbes de niveau SYNTHÉTIQUES (champ d'altitude inventé, d3.contours). Rien ne désigne un point précis : plus de coordonnées, de repère, de nom de commune, ni de limite du 94 ; le cadrage est décalé et non étiqueté.

Corrections appliquées (brief + critiques)
- Verdict en haut : bandeau vert avec pictogramme sceau + GARDER POSSIBLE, réglette 0, 20, 40, 60 mini, 80 avec repère 68, deux raisons, mention et lien. Un REMETTRE À L'EAU aurait une autre forme d'icône et un autre aplat ; non dessiné ici.
- Lieu : « La Marne, Val-de-Marne (94) ». Une seule fois « Palier 2 sur 3 » et « peu commun ». « Peu commun dans le Val-de-Marne » est retiré, car redit par la phrase « Commun en Seine-et-Marne, peu commun ici ».
- Bas de carte : n° 014 + barre segmentée 4/11 (« 4 espèces sur les 11 relevées dans le 94 », donnée mise à jour sur demande) + une ligne de rareté. Palier en ronds (2 pleins, 1 vide), plus de triangles. Pas de panneau, pas de filets.
- Titre sur zone blanche (dégradé), plus de croix de graticule. Fond du dock = prolongement de la carte, verre lisible ; Partager a sa propre forme (pilule blanche à contour bleu).
- Poisson plus grand (345 px sur 361). Barre d'état : barres, Wi-Fi, batterie dessinés, 9:41 semibold.
- Reflet palier 2 : courbes bleues renforcées révélées par masque radial qui suit le pointeur, inclinaison 7 degrés max, état figé joli ; mouvement réduit = fondu.
- Animation GSAP : rivière tracée, bandes de courbes qui émergent, poisson posé, cote 68 cm, réglette. Fini vers 2,3 s.

Reproduire sur iPhone : VisionKit pour le détourage ; CIMorphologyMaximum pour le liseré blanc ; courbes précalculées par secteur et floutées côté serveur au partage, rendues en CAShapeLayer (strokeEnd animé) ; reflet CIRadialGradient + CMMotionManager.

Limites : courbes synthétiques ; pas de Dynamic Type ni de safe-area dynamique (tailles en px, écran 393x852) ; Hanken à la place de SF Pro dans le corps ; pas de mode sombre ; gestes non câblés ; lien de signalement de 12 px sous 44 pt ; pas de recherche web.
