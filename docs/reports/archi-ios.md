# Architecture iOS : projet Xcode, API par étape et lots de jeudi
Décision débloquée : la structure du projet Xcode et la liste des modules qui deviennent les lots de jeudi (un lot = un dossier = une personne, sans conflit entre les 2 Mac).
Lu le 12/10/2026. [?] = non vérifié. « Estimation » = chiffre non mesuré. Rien n'a été compilé ici (pas de Mac) : les commandes Xcode sont à valider jeudi.

## Version simple
Une maison de 13 pièces. Chaque pièce (un module) est un dossier tenu par une seule personne et ne parle aux autres que par une porte écrite d'avance (un contrat : une liste de fonctions). Une pièce « coque » assemble le tout. Le fichier central du projet Xcode (`project.pbxproj`, qui liste tout et crée des conflits quand deux Mac le modifient) n'est touché qu'une fois, jeudi matin, par une seule personne.
Côté IA : l'iPhone reçoit la photo et une liste fermée d'espèces, en choisit trois, l'humain confirme, la table de règles décide. Sans IA d'Apple sur l'iPhone, un choix manuel prend le relais et la suite marche pareil.
Mini-lexique : Xcode = le logiciel d'Apple qui fabrique l'app ; SwiftUI = le cadre moderne d'Apple pour dessiner les écrans ; UIKit = l'ancien cadre d'écrans ; SDK = kit de développement fourni par un tiers ; MapKit = cartes Apple ; Core Location = position ; WeatherKit = météo Apple ; ActivityKit et WidgetKit = écran verrouillé et widgets ; StoreKit = achats ; SwiftData = base locale ; Vision et VisionKit = analyse d'image ; ImageIO = lecture et écriture de fichiers image ; EXIF = étiquettes cachées dans une photo (date, GPS) ; CloudKit = stockage iCloud ; scheme = préréglage de lancement d'Xcode.

## 1. Versions à choisir
- Xcode 27.0 (sorti le 14 sept. 2026, exige macOS Tahoe 26.6 ou plus, Mac Apple silicon seulement) : https://xcodereleases.com/ et https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes . Pas les 27.1 et 27.2 (bêtas). Les 2 Mac doivent être en macOS 26.6 avant jeudi.
- Cible minimale (la plus ancienne version d'iOS acceptée) : iOS 27.0. `Attachment`, la façon de joindre une image à une requête IA, est marqué « iOS 27.0+ » : https://developer.apple.com/documentation/foundationmodels/attachment . Avec une cible iOS 26, E5 passerait par `#available(iOS 27, *)` (un test qui adapte le code à la version) et les iPhone en iOS 26 n'auraient jamais de proposition par photo. Aucun appareil perdu : iOS 27 s'installe sur tous les iPhone compatibles iOS 26, dès l'iPhone 11 : https://arstechnica.com/gadgets/2026/06/ios-27-and-ipados-27-dont-drop-support-for-any-iphones-and-just-a-few-ipads . Les gens restés en iOS 26 ne pourront pas installer l'app ; part d'iOS 27 dans le parc : non trouvée [?].
- Liquid Glass (le matériau translucide du nouveau design Apple) s'applique seul aux composants standards avec le SDK 27 ; la clé d'opt-out `UIDesignRequiresCompatibility` est ignorée en iOS 27 : https://developer.apple.com/documentation/bundleresources/information-property-list/uidesignrequirescompatibility . Règle : composants système, pas de verre dessiné à la main : https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass .

## 2. Étape par étape : frameworks et API (détail et sources dans les sous-sections)
| Étape | Frameworks et API exactes sur iOS 27 | Point d'attention |
|---|---|---|
| E1 carte | MapKit pour SwiftUI (`Map`, `Annotation`, `UserAnnotation`, `MapUserLocationButton`), Core Location (`CLLocationUpdate.liveUpdates()`), `MKGeoJSONDecoder` (lecture des formes) | pas de regroupement natif en SwiftUI, §2.3 |
| E2 fiche | SwiftUI `.sheet`, JSON embarqué lu via `Bundle.module` (https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package), département par point-dans-polygone | règle = texte source ; l'IA n'y touche pas |
| E3 mission | WeatherKit (`WeatherService.shared.weather(for:)`), calcul maison sur l'abondance OFB | mention Apple Weather obligatoire, §2.4 |
| E4 session | ActivityKit + WidgetKit (cible extension), `Text(timerInterval:)`, `Activity.request` | 8 h maximum, §2.5 |
| E5 prise | PhotosUI et `UIImagePickerController`, Foundation Models (l'accès à l'IA d'Apple dans l'iPhone) avec `Attachment` et `@Generable`, table de règles | repli sans IA obligatoire, §2.1 |
| E6 carte | Vision (détourage), `ImageRenderer`, ImageIO (retrait du GPS), SwiftData | test GPS sur le fichier, §2.2 |
| E7 paywall | StoreKit 2 (`SubscriptionStoreView`, `AppStore.sync()`), fichier de configuration StoreKit, SDK Spark Flash (kit fourni par MWM) | restauration des achats, §2.6 |
| E8 amis | à décider après `reports/amis.md` ; si CloudKit : `CKShare`, `UICloudSharingController`, capacité iCloud | SwiftData ne synchronise que la base privée, §2.6 |
| E9 bredouille | briques d'E6 + WeatherKit + lune calculée | rang à part : champ `genre` dans le modèle |
| Réserve | App Intents (`AppIntent`, `AppShortcutsProvider`) | phrase Siri liée au nom de l'app, §2.6 |

### 2.1 IA d'espèce (E5)
- Passer la photo : `Attachment(image)` dans la requête. Types acceptés : CGImage, CIImage, pixel buffer, URL de fichier, et UIImage d'après la session WWDC ; le framework redimensionne seul : https://developer.apple.com/documentation/FoundationModels/analyzing-images-with-multimodal-prompting . Image sortie d'AVFoundation (capture maison) : ajouter `orientation:` sinon elle arrive couchée.
- Liste fermée : la doc Apple montre ce cas, une `@Generable enum` de 4 étiquettes avec `.greedy` (toujours l'option la plus probable), même page. V1 : une enum à la main, une valeur par espèce, avec des noms français lisibles (`truiteFario`) car le modèle les voit. Variante : `DynamicGenerationSchema(name:anyOf:)` si la liste doit venir du JSON : https://developer.apple.com/documentation/FoundationModels/generating-swift-data-structures-with-guided-generation (combinaison avec une image non vérifiée [?]).
- Trois propositions : un tableau avec `.count(3)` : https://developer.apple.com/documentation/foundationmodels/generationguide . Doublons possibles : dédoublonner et compléter par les espèces les plus fréquentes du département [?, à tester].
- Aucun score de confiance trouvé dans l'API [?] : n'afficher aucun pourcentage (il serait inventé), seulement « 1re, 2e, 3e proposition ».
- Disponibilité : `SystemLanguageModel.default.availability` vaut `.available` ou `.unavailable(.deviceNotEligible | .appleIntelligenceNotEnabled | .modelNotReady)` : https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel .

| Cas | Ce que l'app fait |
|---|---|
| deviceNotEligible | grille d'espèces directe, sans message d'erreur |
| appleIntelligenceNotEnabled | grille + une phrase « active Apple Intelligence dans Réglages pour avoir des propositions » |
| modelNotReady | grille + nouvel essai quand l'app revient au premier plan |
| erreur ou refus pendant la génération | même grille ; jamais d'écran bloqué |

Squelette d'exemple, non compilé [?], calqué sur l'exemple de la doc Apple :
```swift
@Generable enum EspeceID { case brochet, sandre, perche, blackBass, truiteFario /* ... */ }
@Generable struct Propositions { @Guide(.count(3)) var meilleures: [EspeceID] }
guard case .available = SystemLanguageModel.default.availability else { return .grilleManuelle }
let session = LanguageModelSession(instructions: "Tu identifies des poissons d'eau douce français.")
let r = try await session.respond(generating: Propositions.self,
                                  options: GenerationOptions(samplingMode: .greedy)) {
    "Quelles sont les 3 espèces les plus probables sur cette photo ?"
    Attachment(cgImage)
}
```
- Appareils : iPhone 15 Pro et Pro Max, toute la gamme 16, iPhone Air, 17 ; jusqu'à 8 Go libres (14 Go sur iPhone 17 Pro) ; langue de l'iPhone et de Siri identiques et prises en charge (français ok, UE comprise) : https://support.apple.com/en-us/121115 . Les iPhone 11 à 15 non Pro tournent sous iOS 27 sans IA : le relecteur d'Apple peut en avoir un, d'où le repli.
- Hors ligne : oui pour le modèle de l'iPhone, non pour Private Cloud Compute (modèle serveur d'Apple : réseau, quota par jour, autorisation à demander à Apple) : https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute . PCC écarté en v1 : E5 doit marcher en mode avion.
- Français : modèle multilingue, `SystemLanguageModel.default.supportsLocale()` pour tester : https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models . Instructions écrites en français.
- Contexte : la session WWDC affiche `contextSize` = 8192, la doc PCC dit 4K pour le modèle local : lire `contextSize` au lancement [?]. Une image coûte des jetons (les unités de texte que le modèle compte) et du temps : https://developer.apple.com/videos/play/wwdc2026/241/ . Envoyer le poisson détouré et réduit (estimation : 1024 px sur le grand côté ; à mesurer avec `tokenCount`).
- Simulateur : Apple exige macOS Tahoe avec Apple Intelligence active sur le Mac : https://developer.apple.com/forums/thread/815397?answerId=878358022 ; des erreurs sont rapportées sur simulateur iPhone ; l'entrée image en simulateur n'est documentée nulle part [?]. E5 se teste sur l'iPhone. Pour essayer le repli : Edit Scheme > Run > Options > « Simulated Apple Foundation Models Availability » (valeurs : source secondaire https://kyawthemonkey.com/blog/Everything%20I've%20seen%20so%20far%20about%20Apple's%20Foundation%20Models%20Framework ).
- Mesurer d'abord : Evaluations (nouveau framework Apple) chiffre la qualité d'une fonction IA quand on change le prompt, et l'outil terminal `fm` (macOS 27) sait décrire une image : https://developer.apple.com/videos/play/wwdc2026/241/ . Test sur 20 photos réelles possible avant le code si un Mac est en macOS 27 [?].

### 2.2 Carte à collectionner (E6, E9)
- Détourage : Vision `GenerateForegroundInstanceMaskRequest` (iOS 18+), puis `InstanceMaskObservation.generateMaskedImage(for: allInstances, imageFrom:, croppedToInstancesExtent: true)` rend une image à fond transparent : https://developer.apple.com/documentation/vision/instancemaskobservation . Sans vue, donc testable. VisionKit `ImageAnalysisInteraction.subjects` fait pareil mais demande une interaction posée sur une vue : https://developer.apple.com/documentation/visionkit/imageanalysisinteraction (second choix). Risque : prendre la main ou la personne comme sujet ; remède : `instanceAtPoint` après un tap, ou la segmentation par tap ou rectangle d'iOS 27 (page encore marquée Beta [?]) : https://developer.apple.com/documentation/vision/segmenting-objects-using-taps-scribbles-or-rectangles . Marche-t-il en simulateur : [?].
- Rendu : `ImageRenderer(content: CarteView(...))`, `scale = 3`, `.uiImage` (à appeler sur le fil principal), export PNG : https://developer.apple.com/documentation/swiftui/imagerenderer .
- GPS : une photo chargée en `Data` depuis la photothèque peut garder ses métadonnées EXIF, GPS compris [?, à constater]. La ré-encoder avec ImageIO (`CGImageDestination`) et l'option `kCGImageMetadataShouldExcludeGPS` : https://developer.apple.com/documentation/imageio/kcgimagedestinationmetadata . Test d'E6 : relire le fichier avec `CGImageSourceCopyPropertiesAtIndex` et vérifier l'absence de la clé GPS. Ne stocker que la version nettoyée.
- Stockage : SwiftData, `@Attribute(.externalStorage)` pour les images : https://developer.apple.com/documentation/swiftdata/schema/attribute/option/externalstorage .

### 2.3 Carte et position (E1)
- Pas de regroupement natif des points dans `Map` SwiftUI que j'aie trouvé [?] (issue de juin 2026 : https://github.com/AmyDe/town-crier/issues/542 ). Il existe côté UIKit (l'ancien cadre d'écrans) : `MKMapView`, `clusteringIdentifier`, `MKClusterAnnotation` : https://developer.apple.com/documentation/mapkit/mapkit-annotations . V1 : afficher seulement les coins de la zone visible, plafonnés à 150 (estimation, à tester) ; `MKMapView` dans un `UIViewRepresentable` seulement si la carte rame.
- Carte : `Map`, `Annotation`, `UserAnnotation` : https://developer.apple.com/documentation/mapkit/mapkit-for-swiftui ; bouton de position : `.mapControls { MapUserLocationButton() }` : https://developer.apple.com/documentation/swiftui/view/mapcontrols(_:) .
- Position « quand l'app est active » : clé `NSLocationWhenInUseUsageDescription`, jamais « Always » : https://developer.apple.com/documentation/bundleresources/information-property-list/nslocationwheninuseusagedescription . `CLLocationUpdate.liveUpdates()` expose `authorizationDenied` et `accuracyLimited` : https://developer.apple.com/documentation/corelocation/cllocationupdate . Prévoir « position refusée » avec choix du département à la main.

### 2.4 Météo, soleil, lune (E3, E4, E9)
- WeatherKit : activer WeatherKit sur l'identifiant de l'app dans le portail développeur (onglets « App Services » ET « Capabilities »), puis la capacité dans Xcode : https://developer.apple.com/help/account/services/weatherkit . 500 000 appels par mois inclus : https://developer.apple.com/weatherkit . Une erreur d'authentification peut durer environ 30 min après la création (source secondaire : https://betterprogramming.pub/wwdc22-get-started-with-weatherkit-202794853c01 ) : créer l'identifiant avant jeudi.
- Mention obligatoire : `WeatherService.shared.attribution` donne le logo Apple Weather (`combinedMarkLightURL` et `combinedMarkDarkURL`) et `legalPageURL`, à afficher avec toute météo : https://developer.apple.com/documentation/weatherkit/weatherattribution .
- Lever et coucher « calculés sur l'iPhone » : WeatherKit les donne (`SunEvents`) mais avec le réseau : https://developer.apple.com/documentation/weatherkit/sunevents . Pas d'API Apple hors ligne trouvée [?]. Voie : algorithme de l'US Naval Observatory en Swift pur (la bibliothèque MIT `Solar` le fait : https://github.com/ceeK/Solar ), recopié dans le module Meteo, vérifié sur 5 dates contre WeatherKit.

### 2.5 Live Activity (E4)
- Une Live Activity (affichage en direct sur l'écran verrouillé et dans la Dynamic Island, l'îlot autour de la caméra frontale) vit dans une extension : File > New > Target > Widget Extension : https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension . Clé `NSSupportsLiveActivities` = YES dans les réglages de l'app : https://developer.apple.com/documentation/bundleresources/information-property-list/nssupportsliveactivities . Le type `ActivityAttributes` (les données de l'activité) est compilé par l'app ET l'extension : il va dans un paquet partagé (§3).
- Écran verrouillé et Dynamic Island se déclarent dans le même `ActivityConfiguration` (vue verrouillée + `DynamicIsland` compacte, étendue, minimale) : https://developer.apple.com/documentation/widgetkit/activityconfiguration . Les iPhone sans Dynamic Island (avant le 14 Pro) n'ont que l'écran verrouillé [?].
- Démarrage : `Activity.request(attributes:content:pushType: nil)`, app au premier plan seulement : https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:) . Aucun serveur, aucune notification push.
- Compte à rebours : `Text(timerInterval: maintenant...finLegale, countsDown: true)` : https://developer.apple.com/documentation/swiftui/text/init(timerinterval:pausetime:countsdown:showshours:) . Qu'il avance écran verrouillé sans l'app : c'est le test d'E4 sur iPhone [?]. Pour afficher « fin légale » à l'heure : `staleDate` = heure de fin et `context.isStale` dans la vue : https://developer.apple.com/documentation/widgetkit/activityviewcontext/isstale . Redessin automatique à cette date : non vérifié [?].
- Limite : 8 h d'activité, retrait de la Dynamic Island ensuite, et 4 h de plus au plus sur l'écran verrouillé : https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities . Un jour de pêche dépasse souvent 8 h (en octobre, environ 11 h de jour : estimation) : décision produit à prendre avec Adem (démarrer plus tard, ou relancer l'activité).

### 2.6 Achats, amis, Siri
- StoreKit 2 : `SubscriptionStoreView(groupID:)` (iOS 17+) affiche prix, essai et achat : https://developer.apple.com/documentation/storekit/subscriptionstoreview . « Restaurer les achats » est exigé (`AppStore.sync()`) : https://developer.apple.com/documentation/storekit/testing-in-app-purchases-in-xcode et https://developer.apple.com/documentation/storekit/appstore/sync() . Test local : fichier de configuration StoreKit choisi dans Edit Scheme > Run > Options, mode développeur actif sur l'iPhone : https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode . Partager le scheme (case « Shared ») pour que le fichier suive sur le 2e Mac [?]. Spark Flash : doc reçue jeudi [?].
- Amis : la synchro CloudKit de SwiftData ne couvre que la base privée, donc pas le partage entre personnes (source secondaire : https://www.hackingwithswift.com/quick-start/swiftdata/how-to-sync-swiftdata-with-icloud ). Un partage entre amis passe par `CKShare` et `UICloudSharingController` : https://developer.apple.com/documentation/cloudkit/shared-records , code à écrire à la main.
- App Intents : un `AppIntent` avec `openAppWhenRun = true` et un `AppShortcutsProvider`. Chaque phrase doit contenir le nom de l'app (source secondaire : https://bleepingswift.com/blog/app-intents-siri-shortcuts ) : « Dis Siri, j'en ai un » devient « ... dans [nom] », donc attendre le nom.

## 3. Deux Mac sans conflit sur `project.pbxproj`
| Option | Principe | Conflits restants | Coût pour des débutants |
|---|---|---|---|
| A. Dossiers synchronisés (Xcode 16+) | Xcode ne liste plus les fichiers, il suit le dossier : https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes | cibles, capacités, clés Info, paquets, fichier commun à 2 cibles | nul ; mais aucune frontière entre modules |
| B. Paquets Swift locaux | un dossier par module avec son `Package.swift`, compilé comme bibliothèque : https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages | un seul, à l'ajout du paquet au projet | moyen : écrire `public` (mot-clé qui rend visible hors du module) sur ce qui sort ; Claude Code le fait bien (estimation) |
| C. XcodeGen | le `.xcodeproj` est généré depuis un `project.yml` et non commité : https://tuist.dev/blog/2025/03/21/git-conflicts | aucun | outil à installer, signature et capacités à écrire en YAML, réglages faits dans Xcode perdus |
| D. Tuist | même idée, manifeste en Swift : https://tuist.dev/blog/2025/02/25/project-generation | aucun | le plus lourd, déconseillé |

Choix : A pour la coque (App, Widget) + B pour les modules. C en secours si un conflit `pbxproj` survient malgré tout (décidé d'avance). À surveiller, hors jeudi : Xcode 27.2 (bêta) sait stocker le projet en JSON (`project.xcproj`), effet sur les conflits inconnu [?] : https://github.com/tuist/xcodeproj .
- Règle 1 : une seule personne (le chef du squelette) crée le projet jeudi matin : cibles app et extension, capacités, clés Info (stockées dans la cible, donc dans `pbxproj` [?]), paquets vides, scheme partagé, commit. Ensuite personne ne modifie le `.xcodeproj` sans lui.
- Règle 2 : `Core` (contrats) est écrit en premier (estimation : 1 h), puis gelé ; toute modification passe par son propriétaire.
- Règle 3 : les modules ne dépendent que de `Core`, jamais entre eux. La coque branche les vrais services. Chaque module livre aussi un faux service pour tourner seul.
- Règle 4 : un lot = une branche `lot/<module>`. Fusion seulement si build et tests du paquet passent. Commande à valider dès le début de jeudi [?] : `xcodebuild test -scheme <Module> -destination 'platform=iOS Simulator,name=<iPhone>'`. Les modules de pure logique (Core, Donnees, Meteo, Mission) déclarent aussi macOS pour lancer `swift test` en quelques secondes [?].
- Règle 5 : `.gitignore` avec `xcuserdata`, `DerivedData`, `.build` ; `Package.resolved` (le fichier qui fige les versions des dépendances) commité pour que les 2 Mac aient les mêmes versions : https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app .
```
depot/            CLAUDE.md (faits du dépôt : Xcode 27.0, iOS 27.0, règles de lots) · reports/ (rapports d'agents)
  Projet.xcodeproj    chef du squelette seul
  App/  Widget/       dossiers synchronisés : coque @main ; extension Live Activity
  Packages/<Module>/  Package.swift · Sources/<Module>/ · Tests/<Module>Tests/ · Resources/ (JSON sourcés)
```

## 4. Carte des modules (un module = un lot)
| Module | Dossier | Étapes | Expose aux autres | Dépend de | Vérification qui bloque la fusion |
|---|---|---|---|---|---|
| Core | Packages/Core | toutes | types `Espece`, `Coin`, `Regle`, `Verdict`, `Prise`, `Session` ; protocoles `SpotCatalog`, `RulesProviding`, `SpeciesIdentifying`, `WeatherProviding`, `SunMoonProviding`, `CollectionStoring`, `FriendsSyncing`, `EntitlementChecking` ; un faux de chacun | rien | build ; les faux répondent |
| Donnees | Packages/Donnees | E1 E2 E5 | `SpotCatalog`, `RulesProviding.verdict(espece, taille, date, zone)`, raretés, département par point-dans-polygone | Core | 5 coins (75, 92, 93, 94, 77) = texte source ; 5 verdicts préparés ; 5 points dans le bon département |
| Carte | Packages/Carte | E1 E2 | `CarteView`, fiche d'un coin | Core | build ; filtre des coins visibles plafonné |
| Identification | Packages/Identification | E5 | `SpeciesIdentifying.propose(photo, zone)` et repli | Core | 4 cas d'indisponibilité, dédoublonnage (faux modèle) ; précision réelle mesurée sur iPhone, hors fusion |
| Prise | Packages/Prise (+ réserve Siri) | E5 | `PriseFlowView` : photo, 3 choix, curseur, verdict | Core | curseur → verdict avec les faux |
| CarteStudio | Packages/CarteStudio | E6 E9 | détourage, rendu PNG, retrait du GPS | Core | fichier de sortie sans clé GPS |
| Pescedex | Packages/Pescedex | E6 E9 | `CollectionStoring` (SwiftData), `PescedexView` (« 12 sur 31 ») | Core | carte relue après recréation du conteneur ; rang bredouille à part |
| Session | Packages/Session + Widget/ | E4 E9 | `SessionAttributes` (app et extension), démarrer et finir | Core | heure de fin calculée ; compte à rebours : test manuel sur iPhone |
| Meteo | Packages/Meteo | E3 E4 E9 | `WeatherProviding`, `SunMoonProviding` (hors ligne), vue Apple Weather | Core | lever et coucher sur 5 dates connues |
| Mission | Packages/Mission | E3 | `MissionPlanner.propose(position, date)` | Core | une position + une date = proposition complète |
| Abonnement | Packages/Abonnement | E7 | `EntitlementChecking`, `PaywallView` | Core | achat et restauration avec le fichier StoreKit (StoreKitTest) |
| Amis | Packages/Amis | E8 | `FriendsSyncing` (zone floue seulement) | Core | le message envoyé n'a aucune coordonnée exacte |
| App (coque) | App/ | toutes | `@main`, onglets, injection des vrais services | tous | build ; lancement sur l'iPhone |
Vagues proposées. Vague 1 : Donnees, Carte, Identification, Prise. Vague 2 : CarteStudio, Pescedex, Session. Vague 3 : Meteo, Mission, Abonnement, Amis. Parcours héros d'abord : E1, E2, E4, E5, E6, E8 (ordre de `parcours-demo.md`). Répartition possible à 3 : A = Donnees, Carte, Meteo ; B = Identification, Prise, CarteStudio ; C = Pescedex, Session, puis Abonnement et Amis.

## 5. Pièges de débutant
- Rôles : un membre « Developer » signe avec Xcode et envoie des builds : https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds . Il ne peut pas soumettre à la revue (Account Holder, Admin ou App Manager seulement) : https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app . Un Admin peut aussi lui interdire d'enregistrer appareils et identifiants : https://developer.apple.com/help/account/access/automatic-signing-controls . Alors un Admin enregistre les iPhone à la main : https://developer.apple.com/help/account/devices/register-a-single-device .
- Équipe : l'invitation doit être acceptée, puis Xcode > Settings > Apple Accounts sur chaque Mac, équipe MWM choisie dans Signing & Capabilities : https://developer.apple.com/documentation/xcode/running-your-app-in-simulator-or-on-a-device .
- Identifiant de bundle (le nom unique de l'app, type `com.mwm.nomprovisoire`, à valider avec MWM) : le choisir une fois. Il est distinct du nom affiché, donc le nom d'app pas encore choisi ne bloque rien. L'extension Live Activity reprend cet identifiant comme préfixe [?].
- Capacités (autorisations Apple liées à l'identifiant) à activer sur le portail : WeatherKit (2 onglets) ; In-App Purchase [?] ; iCloud seulement si E8 choisit CloudKit : https://developer.apple.com/documentation/cloudkit/sharing-cloudkit-data-with-other-icloud-users . Ni App Groups ni Push pour une Live Activity sans serveur [?]. PCC non demandé.
- iPhone de test : câble, « Faire confiance », puis Réglages > Confidentialité et sécurité > Mode développeur (redémarrage, code) : https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device . Le menu n'apparaît qu'après un premier appairage. Xcode enregistre l'appareil seul ; 100 appareils par type et par an : https://developer.apple.com/help/account/devices/devices-overview .
- Apple Intelligence sur l'iPhone de test : activée, modèle téléchargé (jusqu'à 8 Go), langue de l'iPhone = langue de Siri ; sinon `modelNotReady` : https://support.apple.com/en-us/121115 . Vérifier `availability` avant jeudi.
- Caméra absente du simulateur : tester `UIImagePickerController.isSourceTypeAvailable(.camera)` et offrir `PhotosPicker` (sans permission photothèque, source secondaire https://github.com/dpearson2699/swift-ios-skills/blob/main/skills/photos-camera-media/SKILL.md ). Clé `NSCameraUsageDescription` : https://developer.apple.com/documentation/bundleresources/information-property-list/nscamerausagedescription .
- Clés Info à poser le jour 0 : caméra, position (pendant l'usage), `NSSupportsLiveActivities`, et `ITSAppUsesNonExemptEncryption` = NO, sinon un questionnaire de conformité export revient à chaque envoi : https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption .
- Manifeste de confidentialité (`PrivacyInfo.xcprivacy`) exigé pour l'app et pour le SDK Spark Flash s'il touche des API à raison requise : https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api . À vérifier avec MWM.
- App Store Connect : nouvelles questions de classification d'âge depuis le 9 sept. 2026 ; Xcode 26 minimum depuis le 28 avril 2026 (https://developer.apple.com/news/upcoming-requirements/?id=04282026a), SDK 27 obligatoire en avril 2027 : https://developer.apple.com/news/?id=k1mtkt1k .
- Premier lancement du simulateur iOS 27 : plusieurs minutes signalées (notes de 27.1 bêta) : https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes . Le lancer une fois avant jeudi.
- SwiftData + CloudKit (si E8 le choisit) : pas de `@Attribute(.unique)`, tout en optionnel ou avec valeur par défaut : https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices .

## 6. À préparer avant jeudi, sans code de l'app
1. Mac : macOS Tahoe 26.6, Xcode 27.0, runtime du simulateur iOS 27, premier lancement de Xcode et du simulateur. Contrôler que les 2 Mac sont Apple silicon.
2. MWM (via Adem) : invitation des 3 comptes Apple, identifiant d'app avec WeatherKit et In-App Purchase, fiche App Store Connect avec nom provisoire, fichier StoreKit et doc Spark Flash dès que possible.
3. iPhone : lister les modèles ; iOS 27.0 installé ; Apple Intelligence active, modèle téléchargé, langue et Siri identiques ; 20 Go libres (estimation : le modèle prend jusqu'à 8 Go, 14 Go sur iPhone 17 Pro) ; Services de localisation actifs ; mode développeur après un premier branchement.
4. Un iPhone sans IA (iPhone 14 ou 15 non Pro) pour tester le repli, sinon l'option de scheme du §2.1.
5. 20 photos de poissons réels, une espèce confirmée par le pêcheur pour chacune, dans un dossier : sert au test d'identification et aux cartes de démo.
6. Git : dépôt privé, `.gitignore` Xcode, branches `lot/<module>`, Claude Code et `gh` connectés sur les 2 Mac.
7. Avec l'accord d'Adem : un projet jetable (estimation : 15 min), hors dépôt de l'app, pour faire passer la chaîne signature, installation, mode développeur, `availability` sur l'iPhone avant de lancer des lots en parallèle.

## Corrections à `faisa-tech.md`
- « Une cible » devient deux cibles (app et extension Live Activity) et des paquets locaux, car E4 est maintenant un livrable.
- Contexte du modèle : 4K ou 8192, les sources d'Apple se contredisent, à lire à l'exécution.
- `ImageRenderer` (iOS 16+), Vision `VNGenerateForegroundInstanceMaskRequest` (iOS 17+) et `GenerateForegroundInstanceMaskRequest` (iOS 18+) sont vérifiés ; le détourage Vision est préféré à VisionKit.
- Image jointe : la doc écrit `CGImage` et URL, la session WWDC écrit UIImage ; ajouter l'orientation quand l'image n'est pas déjà tournée.

## Recommandation
1. Xcode 27.0, cible iOS 27.0. Option la plus forte écartée : cible iOS 26 avec `#available`, qui touche plus de gens mais retire l'identification par photo à une partie d'entre eux.
2. Projet unique : coque en dossiers synchronisés + 12 modules en paquets Swift locaux, selon le §4. Option la plus forte écartée : XcodeGen (zéro conflit garanti, mais un outil et du YAML de plus pour des débutants) ; il reste le plan de secours.
3. Jeudi, première heure : un seul « chef du squelette » crée le projet, `Core` avec ses faux services, les clés Info et le scheme, puis commit. Preuve : l'app vide se lance sur l'iPhone de test. Les lots démarrent ensuite, par vagues (§4).
4. E5 : enum à la main, `.greedy`, trois propositions sans pourcentage, grille manuelle dans tous les cas d'indisponibilité. Tester sur l'iPhone, jamais seulement en simulateur.
5. À mesurer avant de promettre : l'IA sur 20 photos, le compte à rebours verrouillé, le GPS retiré du fichier, la mention Apple Weather visible.

Décor : le projet Xcode doit exister jeudi sous le compte MWM, et la version minimale d'iOS fixe ce que l'IA peut faire.
Questions pour Adem :
1. Cible : a) iOS 27.0 (ma recommandation, défaut) / b) iOS 26 avec repli.
2. MWM avant jeudi : a) inviter les 3 comptes en App Manager, créer l'identifiant d'app et nous laisser faire un test jetable de signature / b) inviter seulement / c) rien avant jeudi (le squelette prend alors environ une heure de plus, estimation). Défaut si pas de réponse : c.
