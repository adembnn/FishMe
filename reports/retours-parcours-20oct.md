# Retours du parcours dans le simulateur (20 oct. 2026)

Parcours E1 à E9 joué avec le regard d'un pêcheur sur l'iPhone 17e (iOS 27.0), build Debug de `lot/compile-20oct`, iCloud coupé (`FISHME_ICLOUD=NO`), build non signé, position simulée à Charenton (94), installation neuve. Chaque ligne dit si elle est **vue à l'écran**, **déduite du code ou des tests**, ou **non confirmée**. Rien ici n'est une note ni une validation.

## Étapes vues
| Étape | Vu à l'écran | Résultat |
|---|---|---|
| E1 | onboarding « Où pêches-tu ? », fenêtre iOS de position, « Tu pêches depuis… », tunnel de 12 cartes, « 6 dans ton Pescedex », « Voir mon spot », carte | joué ; la carte ne se centre pas d'elle-même (R4) |
| E2 | fiche « La Marne » (« Ouvert aujourd'hui », espèces du jour, « Y aller », « Poser mon spot ici ») | joué ; contenu masqué par la barre d'onglets (B5) |
| E3 | « Quel poisson ? » (99 espèces, raretés en mots), filtre sur la perche | joué ; la carte ne garde que les coins relevés |
| E4 | « Mon spot · La Marne · 94 », « Commencer une session », session avec compteur et « Fin légale 19:20 » | joué ; bouton recouvert (B5) |
| E5 | « Photographier ta prise », photo d'exemple, trois espèces en images + « Autre », « Confirmer : brochet » | joué ; une étape « Brochet / Brochet aquitain » s'intercale (B8) |
| E6 | carte « Brochet » (28 %, peu commun, 8 pêches sur 29 · OFB 2025, rang 002), révélation animée | joué |
| E7 | paywall « FishMe Pro » à la fin de la première session | joué ; conforme à la règle du 15 oct. |
| E8 | onglet Communauté (Fil, Amis, Club), « Finis ton profil » | ouvert seulement ; fil, amis et club non parcourus |
| E9 | « La pêche du jour » et carte de sortie « Eau calme » (session sans prise, terminée à la fin légale) | joué ; carte moins riche que la spec (R7) |
Non vu : chat, publication d'un cadeau, repères, aquarium, widget, réglages, Pescedex (volet gauche), glissement des cartes (testé aux boutons seulement), appui sur la photo d'une vraie caméra (le simulateur n'en a pas).

## Bugs (envoyés en correction)
| # | Où | Ce qui se passe | État |
|---|---|---|---|
| B1 | Bloc de règles | Mot « autorisé » dans les lignes d'horaires de 94, 75, 69 et dans la phrase du moteur (décision 10). Corrigé en « prévus ». 13 cas d'or sur 13 passent. | **corrigé** |
| B1bis | Horaires de 09, 58, 62, 85, 91 | Même défaut, cinq formulations ; celle de 85 est une vraie permission. | **à décider** (mots) |
| B2 | Tunnel des 12 cartes (premier simulateur, sous charge 15 à 80) | Compteur « 1 / 12 » sur une carte qui avait changé, rareté qui passe de « commun » à « peu commun ». Ne s'est pas reproduit sur l'iPhone 17e (compteur juste, « 6 » correct à la fin). | non reproduit |
| B3 | Fenêtre de position | Plusieurs dizaines de secondes sous forte charge ; environ 8 s sur machine calme, sans retour visuel sur le bouton. | partiellement expliqué par la charge |
| B4 | Cartes du tunnel | Sur l'iPhone 17e aucune rareté n'est affichée sous le nom, alors que le premier simulateur en montrait une. | non confirmé |
| B5 | Barre d'onglets | Elle recouvre le bas des feuilles : noms de poissons et « Ouvert » de la fiche, miniatures du panneau « Mon spot », et la moitié du bouton principal « Commencer une session ». | **à corriger** |
| B6 | Écran de carte révélée, fin de session | Deux lignes de texte du bas se chevauchent (« Les textes lus font foi… » et « Carte d'exemple… ») ; « Session terminée à la fin légale » passe sous le bouton « Terminer » ; la date « 20 oct. 2… » est tronquée. | **à corriger** |
| B7 | Météo (panneau « Mon spot ») | « Pas de météo pour l'instant. Vérifie ta connexion. » : trompeur si la cause est une autorisation (build non signé). | **à corriger** (distinguer l'erreur) |
| B8 | Confirmation d'une espèce | Après « Confirmer : brochet », l'app ouvre un choix « Brochet / Brochet aquitain ». Explication d'A (code) : la tuile « brochet » est un groupe du modèle ; « Confirmer » ouvre la grille de ce groupe. Son test modifié (confirmation directe d'une espèce) décrit un autre chemin ; aucun test ne couvre le chemin de groupe ; l'ancien écran des sosies n'est plus atteint. La décision du 16 oct. qu'A cite n'est pas retrouvée dans les documents. | **à trancher** : garder l'étape de groupe, la retirer, ou retirer aussi l'ancien écran |
| B11 | Relance de l'app | Le spot posé (« Mon spot · La Marne · 94 ») n'est pas restauré : on revient à « Choisir mon spot ». Le niveau repasse de « Débutant » à « Pêcheur » quelques secondes après le lancement (clignotement). Les cartes sont bien sur le disque (`cartes.store`). Cause probable du spot : trousseau de l'iPhone refusé par un build non signé. | non confirmé ; à refaire avec un build signé |
| B12 | Corrections B5 à B9 d'A | B5 : le contenu est rogné au bord de la barre d'onglets, plus caché dessous, mais les noms de poissons ne se lisent qu'en faisant défiler (vu à l'écran). B7 vérifié à l'écran par A. B6 et B9 non vérifiés à l'écran. | partiel |
| B9 | Carte d'exemple | Le bouton dit « Ajouter au Pescedex » alors que la ligne au-dessus dit qu'elle ne compte pas. | **à corriger** (texte) |
| B10 | Démarrage de la session | Le paywall s'est ouvert à « Commencer une session » (deux touchers lents), alors que la règle dit à la fin. Il s'est aussi ouvert à la fin, correctement. | **à reproduire** avec un seul toucher |
| B13 | Aquarium | Aucune sortie : le bouton « Décors » recouvrait la croix de fermeture (même coin). « Décors » est passé en haut à droite. | corrigé, non revu à l'écran |
| B14 | Communauté | Sections longtemps sur « Chargement… » ; l'onglet Amis attend ~20 s avant « Tes amis ne peuvent pas s'ouvrir ». Le compte iCloud est lu d'abord (4 s max). | partiel : l'attente de 20 s sur Amis n'est pas expliquée |
| B15 | Communauté | La barre du bas recouvrait « J'aime / Commenter ». `ignoresSafeArea` retiré. | corrigé, non revu à l'écran |
| B16 | Publication | Pas d'âge lisible. Ajout de « à l'instant », « il y a N min / h / j » (libellés inventés par A, gardés). | corrigé, non revu à l'écran |
| B17 | Carte d'un poisson | Centile et trois colonnes vides sur une carte déclarée ; « CEN · centile de taille ». Maintenant « Sans photo ni mesure » et « Taille comparée aux prises » (libellés inventés, gardés). | corrigé, non revu à l'écran |
| B18 | Création de club | Le champ « Nom du club » ne prenait pas le toucher. Zone de toucher étendue à la rangée (hypothèse, non reproduit). | non confirmé |

**B8 tranché par Adem (20 oct.) : on garde l'étape « Brochet / Brochet aquitain ».**
**B11 expliqué :** le trousseau refuse l'écriture (code −34018) dans un build non signé ; à refaire avec un build signé. Les deux tests du trousseau sont ignorés tant que l'app n'est pas signée.
**R1, R4, R6 :** filtre d'espèce visible (nom sur le bouton + croix, vu à l'écran, croix très faible) ; recentrage de la carte corrigé et couvert par un test (pas revu à l'écran) ; Réglages et Repères derrière un bouton « Plus », espaces resserrés (vu à l'écran).
**Run du 20 oct. 22:48 (xcresult) : 691 réussis, 5 échoués, 2 ignorés sur 698.** Échecs : 2 tests Aquarium (rendu à 0 pixel), 1 test des décors (contredit le cadre voulu), 2 tests StoreKit (simulateur d'achats).

## Remarques d'utilisateur (choix à faire)
- **R1.** Le pêcheur ne sait pas qu'un filtre d'espèce est actif : le bouton « Espèces » ne change pas d'aspect.
- **R2.** Le « ? » du badge de la fiche n'est expliqué nulle part.
- **R3.** « CEN · centile de taille » sur la carte est du jargon ; « Taille – » sans mesure laisse un tiret.
- **R4.** Après la permission de position, la carte reste sur le centre de la France (Cher) jusqu'à « Ma position ». La spec E1 dit « autour du pêcheur ». À vérifier si la position arrive trop tard ou si l'app ne recentre pas.
- **R5.** Fond de carte vide (grille) pendant une quinzaine de secondes au premier zoom, puis les tuiles arrivent.
- **R6.** Les boutons à droite (Météo, Ma position, Espèces, Réglages, Repères) recouvrent des marqueurs.
- **R7.** La carte de sortie n'affiche pas la phase de lune ni les conditions du départ que la spec prévoit.
- **R8.** Le compteur « 0:55 » ne dit pas s'il est écoulé ou restant, alors que la fin légale est dans 3 minutes. Le calcul de la fin légale paraît juste (coucher vers 18 h 50 plus une demi-heure).
- **R9.** Prix du paywall en dollars (« $34.99 », « $49.99 ») : probablement le fichier d'achats de test ; à lire en euros dans App Store Connect avant l'envoi.
- **R10.** La photo d'exemple montre un visage reconnaissable : droits à vérifier, car elle est livrée dans l'app.
- **R11.** « Ce que tu peux pêcher ici aujourd'hui » : « tu peux » est proche d'une permission ; à confirmer face à la décision 10.
- **R12.** « Y aller » ouvre Plans directement, sans la feuille de choix de la décision 9 (peut être voulu : seule app installée dans le simulateur). Plans a ensuite affiché ses propres fenêtres de premier lancement.
- **R13.** La carte « Camille · Département 94 · 25 min et 3 s » (club d'exemple) : le sens de « 25 min et 3 s » n'est pas clair.
- **R14.** Les cartes du tunnel glissent selon la spec, mais seul le toucher des boutons a été essayé.

## Sujet de produit à trancher
- **3 075 phrases de règles affichables contiennent « autoris… » dans 86 fichiers de départements.** La décision 10 ne s'applique aujourd'hui qu'aux 13 cas d'or testés. Choix : (a) reformuler partout, (b) l'interdire seulement dans l'état de tête du bloc, (c) laisser pour la carpe de nuit, qui décrit une exception réglementaire.
