# Planche G, Carte classique (anatomie Écarlate et Violet, traduite pêche)
Direction : une vraie carte de jeu (cadre plein couleur de type, fenêtre, zone de texte claire), calme autour, le poisson en héros.
Polices : Bricolage Grotesque 700 (nom, taille, attaques), Hanken Grotesk (texte), IBM Plex Mono (mesures, 06/14, réglette).
Couleurs : eau calme #2F7F6F (cadre, verdict, bouton, un seul accent), zone de texte #EEF4F1, liseré laiton #D9C98A, encre #14181B, papier #FFFFFF.
Audace : l'holo est limité à la fenêtre d'illustration (dégradé teal/or pâle/bleu glace en color-dodge, masque radial qui suit le pointeur) ; la carte se retourne une fois, le reflet la balaie, état final à 2,5 s. Reduced-motion : fondu.
Anatomie vérifiée (pokemon.com, fiches SV01 Tatsugiri 62/198, Varoom 140/198, Espathra 103/198 ; Bulbapedia SV) : nom + PV + type en haut, illustration, attaques avec coût en énergies, rangée Faiblesse / Résistance / Retraite, numéro « 62/198 » + rareté + illustrateur en pied ; cadre gris depuis SV, symbole d'extension remplacé par un code.
Traduction : PV = 68 cm + pictogramme eau calme ; coût d'attaque = 1 à 3 ronds de difficulté ; faiblesse/résistance/retraite = Taille mini / Ouvert / Quota ; numéro 06/14 + pictogramme poisson (collection).
Reproduction iPhone : holo = SwiftUI + Core Motion (inclinaison -> deux paramètres) sur un shader/Metal ou deux dégradés en blendMode(.colorDodge) masqués à la fenêtre ; cadre/zones = RoundedRectangle ; détourage VisionKit posé dans la fenêtre.
Non repris volontairement : cadre jaune, symboles d'énergie, police du jeu, mot « Poké ».
Résidu detect.mjs : flat-type-hierarchy. Les 16/17/20 px viennent de la barre d'état iOS et des icônes ; sur la carte 4 tailles (21/15/12/11), min 11 px. Accepté.
Écart au brief : « n° 014 » remplacé par 06/14 (brief 3e série). Date sur la carte seulement ; heure et lieu sous la carte.
Limites : holo peu visible au repos sur fond clair (voulu, « discret ») ; pas de verso ; pas testé sur appareil réel.
