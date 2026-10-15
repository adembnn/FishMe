# Compiler sur Mac : ordre et pièges

Écrit le 15 oct. 2026 (Adem, « fais en sorte que ça se passe bien quand on compile dans Xcode »). Les lots L3, L4, L5 et L13 ont été écrits sans Xcode : syntaxe vérifiée par `swiftc -parse` dans Docker, signatures de `Core` relues une à une, aucune compilation. Ce fichier dit dans quel ordre compiler et ce qui cassera d'abord.

## Avant tout (lot L0, A)
1. **Lier le paquet local `Packages/Core` à la cible app et à la cible de tests** (File > Add Package Dependencies > Add Local). Sans ça, `import Core` échoue partout. Constaté à la relecture de L3 et L5 : `BuildChallenge.xcodeproj` ne référence que le SDK Spark.
2. **Choisir Swift 5 ou Swift 6.** Le projet de MWM est en `SWIFT_VERSION = 5.0` avec `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` sur la cible app (pas sur la cible de tests). Le plan dit Swift 6 (décision d'Adem). Les lots sont écrits pour Swift 6 (`@MainActor`, `Sendable`). Si une erreur dit qu'un type de l'app ne peut pas se conformer à un protocole de `Core`, la cause est l'isolation MainActor par défaut : déclare ce type `nonisolated` (exemple connu : `IdentificationAbsente: IdentifieEspece`, `App/Prise/PriseServices.swift:33`).
3. Faire passer `python3 docs/verifier.py` puis `scripts/verif.sh`.

## Ordre de fusion et de compilation
1. `lot/contrats` (C0) : 19 tests. Ses ressources viennent de `lot/donnees` (D1) et `lot/conseils` (D4) : fusionner D1 et D4 en même temps ou juste avant.
2. `lot/donnees` (D1), `lot/conseils` (D4, `conseils.json` vide au départ), `lot/moteur` (L1).
3. `lot/squelette` (L0) avec le lien vers `Core` posé.
4. Un lot d'écran à la fois, dans cet ordre : `lot/session` (L5), `lot/prise` (L3), `lot/collection` (L4), `lot/premier-pas` (L13), `lot/club` (L9). Après chaque fusion, compiler (`xcodebuild` sur `generic/platform=iOS Simulator`), corriger, passer au suivant. Le Mac A (8 Go) compile un lot à la fois.
5. Brancher chaque écran dans `App/RootView.swift` (A seul) : la liste de ce que chaque lot attend est dans la réponse finale de son agent (`PriseRacineView(services:contexte:terminer:)`, `PescedexView(modele:emplacements:)`, `BandeauSession(moteur:ajouterPrise:)`, `TunnelPremiersPasView`, `CarteAEssayerView`).

## Ce qui peut encore casser (non vérifié, par lot)
- **L3 :** `ToiseLecteur.swift` (Vision `RecognizeTextRequest().perform(on:)` et `boundingBox`), `PhotosPicker` sous DEBUG, `date.formatted` sans `import Foundation`.
- **L4 :** `Nage.metal` doit être compilé par le dossier synchronisé ; `ShaderLibrary.ondeNage` avec `distortionEffect` ; `ImageRenderer` ; `ModelConfiguration(cloudKitDatabase: .none)` ; handler CoreMotion en Swift 6 ; test qui compare deux PNG (instable) ; les images d'espèces doivent exister dans `App/Assets.xcassets`.
- **L5 :** `@Observable` avec `onChange(of:)` à deux paramètres, `TimelineView(.periodic)`, Keychain (`kSecAttrSynchronizable`) ; `HorlogeFausse`, `StockageMemoire` et `CoffreMemoire` sont sous `#if DEBUG`, donc les tests ne compilent pas en Release.
- **L13 :** `presentationBackgroundInteraction(.enabled(upThrough:))`, `.onChange(of:)` sans paramètre, `flatMap(URL.init(string:))`.
- **Tous :** les jetons de style sont provisoires dans un fichier par lot (`App/Style/` n'existe pas) : à remplacer par ceux du lot D0.

## Preuves à coller après la compilation
`xcodebuild build` (BUILD SUCCEEDED), `xcodebuild test`, puis le lot passe `scripts/fusionner.sh`. Un lot non compilé n'est pas fusionné.
