# Correction du test ProfilUITests (27 oct.)

Test : `ProfilUITests.testFinisTonProfilEtRechercheSansBarreDeDefilement` (AppUITests/Profil/ProfilUITests.swift).

## Cause : test périmé (pas de défaut de l'app)
- Run 1 : échec ligne 19, `XCTAssertTrue` sur `textFields["profil.recherche"]` (65 s).
- Le champ `profil.recherche` n'est plus sur la page d'ouverture de la Communauté (« Fil » depuis L23) : il vit dans la page « Amis » (`App/Amis/RechercheAmis.swift`, posé par `SectionProfilAmis`). Le test n'ouvrait jamais « Amis ».
- Run 2 (test corrigé pour toucher « Amis ») : échec ligne 23. Arbre d'accessibilité du xcresult : la page Amis affiche seulement « Tes amis ne peuvent pas s'ouvrir pour l'instant » (`AmisPageView` : `gestion == nil` quand `FISHME_ICLOUD=NO`). Sans iCloud, le champ n'existe pas par construction. Ce n'est pas un faux rouge de lenteur : deux runs, même résultat structurel.
- « Finis ton profil » : la feuille est montrée une fois par 7 jours (`RappelProfil`, clé `profil.rappel` gardée dans le simulateur) ; le test la traite déjà comme facultative (`profil.plustard`). Inchangé.

## Correction (AppUITests/Profil/ProfilUITests.swift seulement ; App/ non touché)
- Le test touche le segment « Amis » avant de chercher le champ.
- Si le champ manque ET que « Tes amis ne peuvent pas s'ouvrir pour l'instant » est affiché : `XCTSkipIf` avec message explicite. Si le champ manque alors que la page est disponible : `XCTFail`.
- Le commentaire d'en-tête (« non exécuté ») est remplacé.

## Affaiblissement, à lire
Sous `FISHME_ICLOUD=NO` (tous les runs du Mac A), la partie « recherche sans barre de défilement + boutons de 44 pt » est SAUTÉE, pas passée : le test n'est plus rouge mais ne prouve plus la recherche tant qu'on ne le rejoue pas sur un build avec iCloud (conteneur Apple pas créé, voir CLAUDE.md). Restent vérifiés : la Communauté s'ouvre, la page Amis s'ouvre, aucune barre de défilement (`scrollBars.count == 0`).
Pour tester la recherche sans iCloud il faudrait un faux service Amis en DEBUG dans `App/Amis` ou `RootView.swift` (hors de mon périmètre) : décision à prendre.

## Sortie réelle de la run 3 (log scratchpad/ui-profil3.log)
```
Test Case '-[BuildChallengeUITests.ProfilUITests testFinisTonProfilEtRechercheSansBarreDeDefilement]' skipped (50.137 seconds).
Executed 1 test, with 1 test skipped and 0 failures (0 unexpected) in 50.137 (50.166) seconds
** TEST SUCCEEDED **
```
Runs 1 et 2 : `Test Case ... failed (65.604 seconds)` ligne 19, puis `failed (78.060 seconds)` ligne 23.
