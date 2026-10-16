# Captures à faire après chaque build (16 oct.)

But : noter les VRAIS écrans contre les maquettes. Simulateur iPhone 17 (390 × 844), français, région France, StoreKit `TestConfig.storekit` (fr_FR, FRA), faux services DEBUG.
Une capture par ligne, nom du fichier = le code : `docs/captures/<build>/<code>.png` sur la branche `captures`.
Pour repartir de zéro : effacer l'app (premier lancement) avant P44.

| Code | Écran | Comment y arriver |
|---|---|---|
| P44 | Écran de lancement | Lancer l'app, capture immédiate |
| P01 | Niveau du pêcheur | Premier lancement |
| P05 | Accord mesure (SDK MWM) | Après P01 |
| P02 | Tes poissons (swipe) | Après P05 ; 2e capture `P02-b` après un swipe à droite |
| P37 | Fenêtre de position | Après P02 (alerte système) |
| P03 | Où pêches-tu | Avant/à la place de P37 (refuser la position) |
| P42 | Sans position | Refuser la position |
| P04 | Zone sans position | Depuis P42/P03, « Choisir sur la carte » |
| P06 | Carte et ton spot | Accepter la position (Paris), onglet Carte |
| P07 | Fiche du spot | Toucher une station OFB |
| P08 | Règle d'une espèce | Dans P07, toucher un poisson |
| P09 | Quel poisson cherches-tu | Bouton filtre de la pastille du haut |
| P10 | Choisir un autre spot | « Choisir un autre spot » |
| P11 | Conditions du jour | Onglet ou bouton météo du spot |
| P12 | Sept jours | Depuis P11 |
| P13 | Alerte orage ou crue | Faux service d'alerte DEBUG |
| P14 | Session en cours | « Commencer » sur le spot |
| P47 | Session bredouille | Finir une session sans prise |
| P16 | Fin de session | Finir une session avec 1 prise |
| P17 | Mes sorties | Menu ou Réglages → Mes sorties |
| P38 | Accès appareil photo | Session → Prise (avant l'autorisation) |
| P18 | Photo de la prise | Après P38 (photo de test DEBUG) |
| P19 | Espèce proposée | Après la photo |
| P20 | Autre espèce (grille) | « Autre » dans P19 |
| P21 | Taille et poids | Après le choix de l'espèce |
| P22 | Détails de la prise | Après P21 |
| P23 | Verdict et révélation | Après P22 ; `P43` pendant l'animation, `P23` à la fin |
| P24 | Recto de la carte | Pescedex → toucher une carte |
| P25 | Verso de la carte | Retourner la carte |
| P33 | Partager une carte | Bouton partager du recto |
| P49 | Image partagée | Aperçu de l'image dans P33 |
| P26 | Pescedex | Onglet Pescedex (avec des cartes) |
| P45 | Pescedex vide | Onglet Pescedex au premier lancement sans prise |
| P48 | Compteur du Pescedex | Haut du Pescedex (gros plan si besoin) |
| P27 | Fiche d'une espèce | Pescedex → case d'une espèce non prise |
| P28 | Carte déclarée | Pescedex → carte venue du swipe P02 |
| P29 | Mon club | Onglet Club |
| P30 | Créer un club | « Créer un club » |
| P31 | Inviter des amis | « Inviter » dans le club |
| P32 | Profil d'un ami | Toucher un ami (faux ami DEBUG) |
| P34 | Paywall | « Choisir un autre spot » après la 1re session, ou toucher une fonction Pro |
| P50 | Paywall petit iPhone | Même écran sur iPhone SE / 16e (667 pt) |
| P35 | Réglages | Bouton réglages |
| P39 | Notifications | Réglages → Alertes |
| P46 | Pas de réseau | Mode avion / faux réseau coupé DEBUG |
| P15, P41 | Écran verrouillé, widgets | Verrouiller pendant une session (si le simulateur le permet) |
