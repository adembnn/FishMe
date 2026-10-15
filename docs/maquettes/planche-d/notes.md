# Planche D, Couleur prélevée
Idée : la carte est un aplat unique de la couleur du poisson ; le brochet, énorme et en diagonale, sort de la carte par le haut et par la droite. Écran blanc autour.
Police : Hanken Grotesk (400/600/700) ; IBM Plex Mono seulement pour 68 / 60 cm, la réglette et n° 014.
Tailles : carte 58 px (nom et taille) + 15 px ; écran 58 / 15 / 12.
Couleurs : fond de carte #DDC8A9 (moyenne des pixels opaques de brochet.png = #83663D, teinte 35°, éclaircie à 77 % pour que le dos sombre se lise), encre #2A1E0F, secondaire #5C4E3C, papier #FFFFFF, accent unique #C5472A (nageoires pectorales : palier 2 et repère 68 cm).
Un effet de lumière : reflet doux qui suit le pointeur (soft-light, 55 %), état figé joli sans mouvement.
Mouvement : le poisson se pose (expo.out, 1,3 s), la pastille glisse à 68 sur la réglette ; tout est fini à 2,2 s. Reduced-motion : simple fondu.
Verso (toucher la carte) : palier, phrase différenciante, source OFB, barre 4/11. Date et lieu sur une ligne sous la carte (heure 17 h 42 au verso seulement).
Détecteur : 1 reste, « main.screen clips a positioned child » = le cadre du téléphone (overflow hidden voulu, 393 x 852) ; le poisson déborde la carte, pas l'écran.
Limite : le poisson est la planche de Bloch (illustration, pas une photo détourée) ; le nez frôle le chiffre 20 de la réglette.
Apps réelles : Apple Music et Flighty (fond = couleur dominante de l'image, sujet qui sort du cadre), Fish Rules (verdict en un mot, réglette), Pokémon TCG Pocket (marque de rareté fixe en bas à gauche, forme pleine/creuse + couleur), CapWords (sujet détouré), HIG Liquid Glass (verre seulement sur la barre d'actions).
SwiftUI : couleur = UIImage.averageColor via CIAreaAverage (CIFilter) puis .brightness/HSB pour la clarté ; fond RoundedRectangle(cornerRadius: 30).fill(couleur) ; poisson = image détourée VisionKit, .rotationEffect(.degrees(-60)), scaleEffect(x:-1), non clipé (hors du clipShape), .shadow(radius: 18, y: 16) ; reflet = RadialGradient + .blendMode(.softLight) piloté par CoreMotion ou DragGesture ; barre = GlassEffectContainer / .glassEffect() ; verso = .rotation3DEffect.
