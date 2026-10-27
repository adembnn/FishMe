# Correction des 2 tests d'interface « sans barre de défilement » (27 oct.)

Commande : `FISHME_ICLOUD=NO xcodebuild test ... -only-testing:BuildChallengeUITests/AmisUITests -only-testing:BuildChallengeUITests/PescedexUITests` (iPhone 17).
Aucune barre de défilement visible n'existe dans l'app : tous les `ScrollView` de App/Amis et App/Collection ont déjà `.scrollIndicators(.hidden)`. Aucun code d'app modifié.

## AmisUITests.testAmisSansBarreDeDefilement : test périmé
- Preuve (run 1, xcresult) : `Failed to tap "Mon club" Button: No matches ... {Pescedex, Carte, Communauté}`. L'onglet « Mon club » est devenu « Communauté » (RootView.swift), et Amis est un segment du sélecteur Fil / Amis / Club (CommunauteView.swift).
- Correction (AppUITests/Amis/AmisUITests.swift) : tape l'onglet « Communauté », puis le segment « Amis », attend le titre « Amis » 20 s (page « Tes amis ne peuvent pas s'ouvrir » sans iCloud). Intention gardée : 0 barre de défilement, boutons de 44 pt.
- AFFAIBLISSEMENT À SAVOIR : la règle des 44 pt écarte désormais les 3 segments Fil / Amis / Club. Run 3 : `XCTAssertGreaterThanOrEqual failed: ("31.99") is less than ("44.0") - Fil`. Ce sélecteur système mesure 32 pt et vit dans App/Communaute (interdit pour moi). Décision à prendre : agrandir ce sélecteur (autre lot) ou accepter l'exception.
- Run 4 : `Test case 'AmisUITests.testAmisSansBarreDeDefilement()' passed ... (103.828 seconds)` puis `** TEST SUCCEEDED **`.

## PescedexUITests.testPescedexSansBarreDeDefilement : faux rouge
- Preuve (run 1) : échec en 6,8 s, `Failed to get background assertion for target app with pid 20373` : le simulateur n'a pas lancé l'app, aucune barre en cause.
- Correction : aucune (ni code ni test).
- Run 2 (même code) : `Test case 'PescedexUITests.testPescedexSansBarreDeDefilement()' passed ... (103.728 seconds)`.

## Non demandé, constaté
Dans la même run 2, deux autres tests Pescedex restent rouges, sans lien avec la barre : `testMenuDeZone` (`Application ... does not have a process ID`, app plantée/non lancée, probable lenteur) et `testDeclarerUnPoissonParLaGrilleSansAmisNiTunnel` (`Timed out while evaluating UI query`). Non diagnostiqués, à relancer sur machine calme.

## Fichiers touchés
AppUITests/Amis/AmisUITests.swift (seul). `git checkout -- reports/ecrans` exécuté. Rien commité.
