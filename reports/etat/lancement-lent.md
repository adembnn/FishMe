# Lancement lent (15 à 20 s d'écran blanc) : causes classées

Lecture seule du code (branche mac/integration). Rien n'a été mesuré sur Mac : les coûts sont des estimations, à confirmer avec Instruments (Time Profiler, fil principal, 20 s de lancement).

Écran blanc = `UILaunchScreen_Generation = YES` sans couleur (project.pbxproj:553, 588) puis `ParcoursApp.init` qui bloque le fil principal avant le 1er rendu.

## 1. Moteur de Core construit en synchrone dans init (avant tout rendu)
- RootView.swift:90-91, `RootView.init` -> `State(initialValue: ParcoursApp(...))` -> `MoteurCore(donnees: .embarque(...))` (Packages/Core/.../Session/MoteurCore.swift:34-62).
- Fil principal : décode departements.geojson (254 Ko), especes.json (95 Ko), puis stations-especes.json (jusqu'à 16 142 stations, 1 à 2 Mo, docs/reports/donnees.md:20), rarete-departements.json et stations-hydro.json, tous lus par `Data(contentsOf:)` dans `Bundle.main.resourceURL` (scripts/donnees.sh). Ces 3 fichiers ne sont pas dans le dépôt : le test de 0,3 s de Core seul ne les avait probablement pas. En plus `State(initialValue:)` évalue `ParcoursApp(...)` à chaque appel de `RootView.init`, donc possiblement 2 fois.
- Coût estimé : 1 à 6 s en simulateur (décodage JSON de dizaines de milliers d'éléments + `centresDepartements()` + index des stations).
- Correction : `ParcoursApp.init` ne construit plus le moteur ; `@State private var app: ParcoursApp?`, un écran de lancement marine (ProgressView) et `.task { app = await Task.detached { MoteurCore(...) }.value }` (MoteurCore est Sendable). Au minimum `State(initialValue:)` -> `@State private var app = ParcoursApp(...)` créé une seule fois. Dossier : App/RootView.swift (A).

## 2. rafraichirCollection() : un rendu d'image par carte sur le fil principal, au démarrage
- RootView.swift:156-165 (appelé par `demarrer()` l.131) -> DepotCartes.swift:110-114 `imagePNG` -> `MainActor.run { ImagePartage.png }` (ImagePartage.swift:9-25).
- Fil principal : pour chaque carte du Pescedex, un `detaillees()` complet (fetch SwiftData + décodage JSON des conditions, donc N fois N lignes) puis un `ImageRenderer` à l'échelle 3 (1 096 x 1 700 px environ) avec deux essais possibles, `UIImage(named:)` de l'image de l'espèce. Des cartes « déclarées » du tunnel (12 swipes) comptent aussi.
- Coût estimé : 100 à 300 ms par carte en simulateur ; 12 cartes = 1 à 4 s ; 40 cartes = 4 à 12 s. C'est la cause qui grossit avec l'usage (un simulateur neuf n'en a pas, un simulateur utilisé oui).
- Correction : ne plus rendre les PNG au lancement. Garder seulement les ids et titres dans `cartesAPartager`, et rendre le PNG à la demande quand le pêcheur ouvre le partage (L9). Ou le faire après 5 s dans un `Task` de priorité basse, une carte à la fois. Dossiers : App/RootView.swift (A) et App/Collection/ (lot L4).

## 3. Tâches de `demarrer()` en série sur le fil principal
- RootView.swift:125-140 : `mesure.demarrerSiAccorde()` (Spark.configure, SDK qui lit disque et réseau, BuildChallengeApp.swift:20-24), `moteur.reprendre()` (relecture du fichier de session et du Trousseau : `TrousseauSpotGratuit.lire`), `await marque.rafraichir()` (réseau : WeatherKit + 2 images, tant qu'elle n'a pas répondu, la fin de `demarrer()` attend), puis `publierAquarium()` (reconstruit l'index des espèces, filtres en N x M, `pescedex.detaillees`).
- Coût estimé : 0,3 à 2 s de CPU ; `marque.rafraichir()` peut bloquer 5 à 15 s sans réseau ou sans entitlement WeatherKit dans le simulateur, mais ne bloque pas le rendu (c'est un `await`).
- Correction : lancer chaque appel lent dans son propre `Task` (`Task { await marque.rafraichir() }`), et ne pas les mettre dans la même suite que `rafraichirCollection()`. Dossier : App/RootView.swift (A).

## 4. SwiftData : ModelContainer ouvert dans init
- RootView.swift:110 -> DepotCartes.swift:20-27 `ModelContainer(for:...)` sur fichier cartes.store, repli en mémoire. Un 2e conteneur (CacheAmis) est créé plus tard et seulement à l'écran Amis (bien).
- Coût estimé : 100 à 500 ms au premier lancement (création du schéma, migration), puis 50 à 150 ms. Si la base est mise à jour d'un schéma ancien : jusqu'à 1 à 2 s.
- Correction : dans le même `Task.detached` que la cause 1 (le `ModelContainer` est Sendable), ou ouvrir le dépôt quand on affiche le volet Pescedex. Dossier : App/RootView.swift (A) ; App/Collection/DepotCartes.swift reste tel quel.

## 5. Fichiers de règles et conseils : faibles
- Les 95 fichiers regles/*.json (19 Mo au total, 340 Ko le plus gros, 97 fichiers avec index et national) sont lus à la demande (ChargeurRegles.swift:40-80, cache par nom) : au lancement seul `departementsCouverts()` ou le lieu courant les lit, soit 2 à 3 fichiers (< 100 ms). `conseils.json` (93 Ko) est lu en synchrone dans init (RootView.swift:106) : < 50 ms.
- Corrections : aucune urgente. Vérifier que rien n'appelle `departementsCouverts()` au lancement (il décode les 97 fichiers : 1 à 3 s).

## Écartés (vérifié dans le code)
- Modèle Core ML DINOv2 (22 Mo) : chargé paresseusement, seulement à la 1re identification (IdentificationDino.swift:89-101, actor `MoteurDino`). Pas une cause.
- StoreKit : `Product.products` seulement à l'ouverture du paywall (ModeleOffres.swift:25) ; `Transaction.updates` dans un `Task.detached` (AchatsStoreKit.swift:82). Pas une cause.
- Rivières geojson : lacs.geojson fait 43 octets, coins-osm.geojson (318 Ko) est lu par le moteur de coins, lazy (RootView.swift:62).

## À faire en plus, tout de suite (gain de perception)
- Écran de lancement marine : dans Info.plist, `UILaunchScreen` avec `UIColorName` = une couleur « LancementMarine » #0D4A85 de Assets.xcassets (ou remplacer `INFOPLIST_KEY_UILaunchScreen_Generation` par un dictionnaire `UILaunchScreen`). Dossier : Info.plist / Assets.xcassets (A seul).
- Mesure à faire avant de corriger : `os_signpost` autour de `ParcoursApp.init`, de `MoteurCore.init` et de `rafraichirCollection()` ; la somme dira laquelle domine.
