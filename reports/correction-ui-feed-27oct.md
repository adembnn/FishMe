# Correction des 2 tests d'interface du fil (27 oct.)

Cible : BuildChallengeUITests/FeedUITests (iPhone 17, FISHME_ICLOUD=NO).

## Diagnostic (run 1, avant correction)
Sortie réelle : `FeedUITests.swift:26: XCTAssertTrue failed` (testLeModeDemo..., 82 s) et `:35: XCTAssertTrue failed` (testTresGrandTexte..., 34 s), `** TEST FAILED **`.
Preuve : images extraites de l'enregistrement d'écran du xcresult. Le fil d'exemple EST affiché (pastille « Exemple », « Camille », « Commenter »), donc pas un faux rouge de lenteur.

### Test 1, mode démo : test périmé (+ lenteur réelle)
- Cause : `PublicationVue.pastilleExemple` porte `.accessibilityLabel("Publication d'exemple")`. L'arbre expose donc ce libellé, plus « Exemple » : `staticTexts["Exemple"]` ne trouve rien.
- Lenteur : `GestionFeed.actualiser()` attendait la réponse iCloud (jusqu'à 4 s) même en mode démo, où elle ne sert à rien.
- Correction : test cherche « Publication d'exemple » (intention gardée : fil rempli, marqué exemple, sans « Publier »), délai 5 s portée à 15 s ; code : `compte = demo ? false : await compteAvecDelai()` (GestionFeed.swift).

### Test 2, très grand texte : test périmé (même libellé) + test sans défilement
- Même cause à la ligne 35. Ensuite, en AX5 l'en-tête et le bandeau remplissent l'écran (B15 : la page garde la marge de la barre), « Commenter » est plus bas, hors de la liste construite (LazyVStack).
- Correction du test : même libellé, puis `swipeUp` (8 fois au plus) jusqu'à ce que « Commenter » existe. Les contrôles gardés : hauteur ≥ 44 pt, `maxX` dans l'écran.
- Vrai défaut trouvé sur la capture AX5 : le titre « Communauté » se coupe au milieu du mot (« Communau-té ») et passe sous l'icône de messages. Titre corrigé dans CommunauteView.swift (`lineLimit(1)` + `minimumScaleFactor(0.5)`). Le chevauchement avec l'icône (posée hors de mon périmètre, côté RootView/chat) n'est pas traité : à vérifier à l'écran par celui qui tient RootView.

Aucun test affaibli : seuls le libellé et l'attente ont changé, le défilement ajouté rend le test plus exigeant sur l'existence de « Commenter ».

## Run 2 (après correction), sortie réelle
```
Test Case 'FeedUITests testLeModeDemoMontreUnFilRempliEnLectureSeule' passed (66.095 seconds).
Test Case 'FeedUITests testSignalerEstAccessible' passed (37.658 seconds).
Test Case 'FeedUITests testTresGrandTexteSansDebordement' passed (22.455 seconds).
** TEST SUCCEEDED **
```
Non vérifié : le titre en AX5 après `minimumScaleFactor` (pas regardé à l'écran).

Fichiers touchés : App/Communaute/GestionFeed.swift, App/Communaute/CommunauteView.swift, AppUITests/Communaute/FeedUITests.swift. Rien commité.
