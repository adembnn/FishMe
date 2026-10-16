# Tests utilisateurs sur le Mac (nuit du 15 au 16 oct. 2026)

Parcours d'un nouveau pêcheur dans l'iPhone 18 Pro virtuel (iOS 27), app neuve, position simulée à Charenton-le-Pont (94), vers 1 h du matin. Branche `mac/integration`. Captures : `reports/ecrans/tests-utilisateurs/` sur le Mac d'Adem (non commitées).

## Ce qui marche
- Premier lancement : demande de position avec le texte FishMe, question « Ton niveau ? », premiers pas (12 espèces en vraies images), consentement « Peut-on compter… ».
- Carte : centrée sur la position, cercle du spot gratuit, poissons qui nagent, coins Hub'Eau.
- « Où chercher près d'ici » (L7) : choix de l'espèce, puis les 3 coins publics OpenStreetMap les plus proches, avec la station OFB reliée et « Ouverte aujourd'hui ».
- Session (L5) : chrono, fin légale, « pêche fermée à cette heure » de nuit, compteur de prises, reprise après relance de l'app.
- Écran verrouillé (L10) : la Live Activity démarre et se met à jour (vu dans le journal du simulateur ; l'écran verrouillé lui-même n'a pas pu être capturé).
- Prise (L3) : photo d'exemple, reconnaissance DINOv2, sosies (brochet / brochet aquitain avec le critère du MNHN), taille au curseur, poids estimé, verdict avec les vraies règles du Val-de-Marne.
- Paywall (L6) après la 1re session, « Continuer gratuitement sur mon spot ».
- Mon club (L9) et Amis (L8) : « Connecte-toi à iCloud » sans plantage quand iCloud est absent.

## Bugs trouvés et corrigés cette nuit
| Écran | Bug | Correctif |
|---|---|---|
| Prise | Sur la photo d'un brochet, l'app proposait « Barbeau fluviatile » et « Hotu_-Toxo-stome » | Deux bugs : la 1re proposition (un groupe de deux espèces) disparaissait parce que deux listes de la grille partageaient les mêmes identifiants ; le recadrage par masque cassait dans le simulateur. Propositions dans l'ordre du modèle, image entière comme dans l'évaluation vérifiée, CPU seul dans le simulateur. Le brochet sort 1er. |
| Prise | Nom brut « Hotu_-Toxo-stome » pour un groupe d'espèces | Libellé « Hotu ou toxostome », image de la 1re espèce du groupe |
| Pescedex | Toutes les cartes étaient perdues à la relance | SwiftData rangeait la base dans le conteneur de l'App Group du widget (absent sans provisionnement), retombait en mémoire et perdait tout. Base nommée dans Application Support (`cartes.store`, et `Amis` hors App Group). |
| Pescedex | Zone inconnue quand la prise n'est près d'aucune eau nommée (« Département 94 ») | `Formats.departement` lit aussi cette forme |
| À essayer | « Pas encore de conseil » pour la perche, le chevesne, l'ablette | En octobre, aucun conseil débutant dans `conseils.json` (ils couvrent avril à août). Repli sur le mois le plus proche. À valider par Adem (voir plus bas). |
| Paywall | Textes d'Apple en anglais | Langue de base `fr` (`CFBundleDevelopmentRegion`) ; à revoir à l'écran. Passer le StoreKit de test en France bloquait ses tests : laissé en `USA`. |
| Écran d'accueil | L'app s'appelait « BuildChallenge » | `CFBundleDisplayName` = FishMe |

## Reste à faire (non corrigé)
- **Lancement lent** : 15 à 20 s d'écran blanc dans le simulateur (risque que l'iPhone tue l'app). Core n'y est pour rien (0,3 s mesurées) ; suspects côté app : SwiftData, le modèle DINOv2, StoreKit, le rendu des images de partage. À mesurer avec Instruments, puis afficher un écran de lancement et construire le reste en tâche de fond.
- Où chercher : corrigé (9,5 s → 0,05 s dans Core, recherche hors du fil principal), pas encore revu à l'écran.
- La carte empile 4 boutons (« Autour de moi », « Choisir un autre spot », « Où chercher près d'ici », « changer de spot » en minuscule) et garde « Commencer une session » pendant une session.
- Premiers pas : l'ordre des espèces ne suit pas le coin (truites d'abord à Charenton).
- Prise : choisir entre brochet et brochet aquitain se fait deux fois (groupe, puis sosies).
- Données : « Brochet aquitain » est rangé dans les Cyprinidés ; « Poisson-chat (Ameiurus melas ; Ameiurus nebulosus [?]) » affiche son nom brut (lot D1).
- Verdict : la ligne « Brochet : pêche fermée du 26 janvier au 24 avril » porte une coche verte.
- Une prise faite avec « Essayer avec une photo d'exemple » devient une carte d'exemple (`exemple = 1` en base) : elle n'occupe pas sa place au Pescedex, c'est voulu par L4, mais le pêcheur ne le sait pas. À vérifier avec une vraie photo sur l'iPhone.
- L'écran Où chercher porte le titre « Choisir un autre spot », comme le filtre d'espèce de la carte.
- Au lancement, une fenêtre « Connectez-vous à votre compte Apple » est apparue une fois (StoreKit) : le schéma Run doit utiliser `TestConfig.storekit`.
- Pas de révélation de la carte avant le paywall de fin de session (prévu par L4).
- Tests unitaires : 122 sur 125 verts. Rouges : abonnement expiré (StoreKit de test), adresse de contact du club vide (à fournir par Adem), 2 espèces sans image. Le lanceur de tests reste bloqué après la suite StoreKit (fin de suite jamais rendue) : la lancer seule.

## Décisions pour Adem
1. Conseils hors saison : montrer ceux du mois le plus proche (choix fait cette nuit), ou enrichir `conseils.json` pour couvrir toute l'année ?
2. Adresse e-mail du club (règle 1.2 d'Apple, sert aux signalements des Amis).
3. SDK MWM configuré seulement après l'accord du pêcheur (choix actuel) ou dès le lancement comme dans le kit ?
