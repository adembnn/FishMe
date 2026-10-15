# Planche I. Vignette Panini (remplace la version « carte numérique », changement de cap demandé par Adem)
Direction : l'album d'autocollants. La prise arrive comme une vignette décollée de son support et pressée dans la case 06 d'une page du Pescedex.
Police : Hanken Grotesk seule (400/600/700). Couleurs : #F3F5F5 fond, #FFFFFF page, #E3EFE9 champ de la vignette, #EDF0F1 cases vides, #14181B encre, #1E7F4F accent unique (verdict, bandeau du nom, bouton).
Audace unique : le geste. Le support (feuille blanche) s'écarte, la vignette flotte puis s'enfonce dans sa case, l'ombre se resserre, un éclat passe une fois (fini vers 2,3 s). Reduced-motion : fondu.
Anatomie vérifiée (web, 12 oct. 2026) : paninigroup.com (collection Coupe du monde 2026 : 20 vignettes par équipe, 18 joueurs en buste, photo d'équipe, écusson ; codes type CAN 1…20 ; 980 au total), Wikipedia « Sticker album » (cases numérotées dans l'album, nom sous la photo), cardboardconnection.com (vignettes brillantes ou hologrammes, 1982 pour les premiers écussons brillants).
Repris : portrait avec liseré blanc de découpe, numéro en coin, bandeau de nom en couleur d'équipe (ici la couleur du verdict), case creuse numérotée, vignette brillante = foil.
Pas repris : logo, typographie, cadres, drapeaux, écusson, mise en page Panini.
Brillante (palier 2) : couche dégradé teal/paille/bleu glacé décalée par la position du pointeur sous un mode de fusion color-dodge, plus un reflet doux. Méthode simeydotme, code réécrit. Inclinaison 3D de la vignette au pointeur, gyroscope iPhone (autorisation au premier toucher).
Rareté : 3 demi-disques « écailles » (2 pleins, 1 vide) sur la vignette, forme et remplissage. « 4 sur les 11 » : barre segmentée de 11 + 2 voisines remplies (perche, gardon) + 06.
Détecteur : cramped-padding x4 et nested-cards = faux positifs (le liseré de la vignette est le décor voulu, la case creuse est la page d'album, pas une carte) ; flat-type-hierarchy : 16/17/20 px viennent de la barre d'état et des icônes.
Limites : gyroscope non testable en capture ; la vignette 06 est à son pose de repos (légère inclinaison), le foil est discret par choix ; les 2 voisines sont d'autres espèces des assets (perche, gardon) ; texte de vignette 12 px.
Sur iPhone : SwiftUI, rotation3DEffect + CoreMotion ; la découpe de la vignette = le détourage VisionKit sur fond uni.
