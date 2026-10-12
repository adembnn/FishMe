# Points encore ouverts dans les fiches de lot (marqueurs `[?]`)

Mise à jour du 12 oct., après alignement des 13 fiches sur `lots.md`, `parcours-demo.md`, `donnees.md`, `architecture.md`, `app-store.md`, `avant-jeudi.md` et `README.md`. Fiche nouvelle : `fiches/C7.md`.
Marqueurs `[?]` : 55 avant, 29 après le 12 oct. vers 18 h, presque tous des commandes à lancer sur la machine concernée.
Un point = une ligne : fiche, question, qui tranche. La plupart se lèvent en lançant la commande sur la machine concernée.

## À vérifier sur machine (celui qui lance la commande tranche)
- C0 et L1 : la chaîne Docker `swift:6.4` finit-elle `swift test` sans erreur ? (`architecture.md` : à tester mercredi, 3 marqueurs) | C, A en repli.
- C0 : texte exact de l'erreur Swift quand un `public` manque (aussi dans L0) | C.
- L0 : commandes `sw_vers`, `xcodebuild -version`, `xcrun simctl list runtimes` | A, sur son Mac.
- L0 et L5 : `xcrun devicectl list devices` liste-t-il l'iPhone ? | A.
- L0 : commandes `xcodebuild test` de `verif.sh` (`architecture.md` : à valider en T3) | A.
- L0 : le premier envoi de L0 sur `main` se fait-il à la main, puisque `fusionner.sh` naît dans ce lot ? | A.
- L0 : un nouveau projet Xcode 27 coche-t-il iPhone et iPad ? | A.
- L0 : l'équipe gratuite « Personal Team » ne permet ni WeatherKit ni achats réels ? | A, ou MWM.
- L3 : option de scheme « Simulated Apple Foundation Models Availability » : nom exact | B.
- L5 : le redessin automatique à l'heure `staleDate` marche-t-il ? (c'est le test 1) | A.
- L6 : la console du SDK reste-t-elle vide si le consentement est refusé ? | A, avec la doc de MWM.
- L6 : « Shared » dans le scheme suffit-il à faire suivre le fichier StoreKit sur le 2e Mac ? | A.
- L7 : erreur d'authentification WeatherKit d'environ 30 min après la création | A.
- L7 : WeatherKit marche-t-il dans le build publié et pas seulement depuis Xcode ? | B, sur TestFlight.
- L8 : l'adaptateur de scène SwiftUI pour accepter l'invitation CloudKit | B.

## Données et session cloud (C tranche)
- D1 : la requête Overpass (France entière, 180 s) n'a jamais été exécutée ; relever les coordonnées sur openstreetmap.org marche-t-il ? (2 marqueurs) | C, Adem si le plan B change le périmètre.
- D2 : la session cloud joint-elle Hub'Eau (le rapport a dû passer par un outil web) ? | C.
- D2 : une release privée peut-elle être créée depuis la session cloud (`gh auth status`) ? | C, avec A.
- D2 : champs exacts de `rarete-departements.json`, à figer avant que L1 les lise (jeudi 10 h 30) | C (D2) avec C (L1).
- D2 : nom et options du script (`outils/hubeau/<script> --departement 94`) | C.
- D2 : étiquette de la release (`gh release view <étiquette>`) | C, avec A pour `scripts/donnees.sh`.
- D2 : plafond réel de `size` de l'API | C.
- D2 : les chiffres du 94 (29 pêches, gardon 27, perche 18) viennent d'un outil web ; le test les recoupe | C.

## Structure et périmètre
- L1 : le soleil (version suivante) peut-il être fusionné à part sans bloquer les autres morceaux, alors que son test est dans le test de L1 ? | C, avec A (`fusionner.sh`).
- L3 : entrée de test dans l'app avant la fusion de L3, puisque A branche chaque écran après la fusion | A et B.
- L6 : manifeste de confidentialité et `ITSAppUsesNonExemptEncryption` pour le SDK (point 4 de `message-mwm.md`) | MWM.
- S1 : mots-clés fins et texte promo peuvent-ils suivre l'envoi à la relecture ? | C, en vérifiant dans App Store Connect.

## Tranchés par défaut le 12 oct. vers 18 h (techniques et réversibles, sans attendre Adem)
- D2, mode a : les fichiers du tableur partent dans la même release privée que b et c, jamais commités (règle d'Adem).
- C7 : C saisit `saisons-montages.json`, un pêcheur de l'équipe le relit.
- C7, météo absente : calcul sans le facteur météo, avec la mention « météo indisponible ».
- Tests de `Core` : `Packages/Core/Tests/CoreTests/` est découpé en `Contrats/` (C0), `Moteur/` (L1) et `Mission/` (C7).
- E9 et L5 : le type `Sortie` de `Core` passe de L5 à L4 par `RootView.swift` (A), sans import entre dossiers.

## Tranchés par déduction (à contrôler)
- D1 : `cas-verdicts.json` va dans `Resources/` (lots.md le met dans le test de D1, dont `Resources/` est le seul dossier de données) ; relecture croisée : `avant-jeudi.md`.
- L1 et S1 : `fusionner.sh` retiré des doutes (lots.md : seul chemin vers `main`, `verif.sh` testé sous Linux en T3).
- L2 : les crédits OSM, OFB et IGN sont montrés par la page Sources de L6 (`credits.json`).
- L6 et S1 : porte 2 = paywall natif sans le SDK (plus de Spark Flash dans la fiche) ; sans paywall du tout, plus d'abonnement non plus (`lots.md`, « Si une porte saute »).

## Écarts des sources, corrigés le 12 oct. vers 18 h
- `README.md`, question 3 option a : l'export tableur y est cité.
- `lots.md` : L5 dépend de L4 et rend une `Sortie` ; `architecture.md` décrit ce type.
- `donnees.md` : `cas-verdicts.json` a sa ligne ; `saisons-montages.json` a son responsable.
