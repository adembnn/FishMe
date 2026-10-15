# L7 Où chercher : à faire sur le Mac

Branche `lot/ou-chercher`. Code : `App/OuChercher/` (modèle, vue), tests `AppTests/OuChercher/`, parcours `AppUITests/OuChercher/`.

## Branchement (A seul)
- `App/RootView.swift` : présenter `OuChercherVue(especes: core.coins(), position: <Coordonnee de l'iPhone ou centre du département choisi>)` depuis le bouton « Choisir un autre spot » de la carte (à côté du filtre d'espèce de L2). L'écran ne demande jamais la position.
- Aucune capacité ni clé Info propre à L7 (la position vient de L2). Aucun `.xcodeproj` à changer : dossiers synchronisés.
- Ordre de compilation : après `lot/donnees` (Core et ressources) et L2 ; un seul build à la fois (Mac à 8 Go).
- Lancer : tests `AppTests/OuChercher/OuChercherModeleTests`, puis `AppUITests/OuChercher/OuChercherUITests` (position simulée à Charenton, sandre).

## Risques de compilation
- `@Observable` : `import Observation` ajouté ; types de données en `nonisolated` (réglage MainActor par défaut).
- `ImageEspece` renommée `ImageEspeceCoin` (collision avec `App/Conseils/ImageEspece.swift`).
- Les fichiers ne sont vérifiés que par `swiftc -parse` sous Linux, jamais compilés.
- `App/Style/Style.swift` (lot D0) n'est pas encore dans `mac/integration` : la vue utilise les styles système en SF Pro Rounded gras ; à passer sur les jetons Marine quand D0 est fusionné.

## Choix par défaut pris
- `Core.coins(ou:pres:)` rend des stations OFB (type `Coin`), pas des coins OSM. L7 les affiche donc comme « relevée à proximité », titrées par l'eau. Relier un coin public OSM (`coins-osm.geojson`, sur `lot/donnees`) à la station OFB la plus proche est un ajout à `Core` (B, copie de L1), pas fait ici.
- Au plus 3 coins, jamais complétés ; aucun relevé : « Aucun relevé OFB à proximité » ; ligne « © contributeurs OpenStreetMap » sous la liste.

## Mise à jour du 15 oct. : vrais coins OpenStreetMap (Core, dossier `Coins/`)
- Nouveau dans `Core` (dossier `Packages/Core/Sources/Core/Coins/`, ajouté à la ligne L7 de `docs/lots.md`) : `MoteurCoins`, `ServiceCoinsPublics` (`coinsProches(ou:pres:)`, `coinsPublicsDans(_:)`, `coinsPublics(pres:rayonM:)`), `CoinProche`, `CoinPublic`, `CoinsFaux`. Aucun fichier de L1 ni de C0 n'est modifié.
- **Branchement (A)** : dans `RootView.swift`, `OuChercherVue(especes: core.coins(), position: ...)`. `core.coins()` lit `Resources/coins-osm.geojson` (embarqué par `lot/donnees`) ; `MoteurCoins` remplit aussi `ServiceEspeces` : `core.coins()` peut remplacer `core.especes` dans `ServicesCarte` si L2 veut de vrais coins dans son filtre (`coins(ou:pres:)` rend alors des coins OSM, `eau` porte le nom du coin ; fichier vide ou absent : stations OFB comme avant, aucun appelant ne casse). Pour les pastilles de la carte : `coinsPublicsDans(region)`.
- Liaison : chaque coin est relié à la station OFB la plus proche où l'espèce a été vue, à 5 km au plus (`MoteurCoins.rayonStationM`, par défaut, à confirmer par Adem) ; sans station, le coin est omis. N et année sont ceux de la station : l'écran dit « relevée à proximité » et « Station OFB à proximité : <eau>, à <distance> ». Les coins privés ou d'accès inconnu du fichier sont sautés à la lecture.
- L7 a besoin de la couche : sans `coins-osm.geojson` rempli, `coinsProches` rend `[]` et l'écran dit « Aucun relevé OFB à proximité » (fusionner `lot/donnees` avant de tester sur l'iPhone).
- Vue : sous le nom du coin, la ligne d'accès (« Accès libre », « Sur permis », « Accès payant ») et la ligne de la station OFB reliée. Tests à compiler : `AppTests/OuChercher/OuChercherModeleTests` (`coinPublicTitreAccesEtStation`). `OuChercherModele` prend maintenant `any ServiceEspeces & ServiceCoinsPublics` (les tests et l'aperçu passent `CoinsFaux()`).
