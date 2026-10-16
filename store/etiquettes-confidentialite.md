# Étiquettes « App Privacy » et questionnaire légal MWM (brouillon)

Le 16 oct. 2026. Réponses à jouer par la personne qui clique (App Manager) dans App Store Connect, et à saisir dans `get_legal_questionnaire` / `save_legal_answers` de MWM. Elles reprennent `confidentialite.md` et `conditions.md` : si l'un change, changer les trois. Rien n'est cliqué ni publié. Code lu sur `origin/mac/integration` (même contenu sur `origin/claude/finir-app-ud5swp` pour les fichiers cités), chemins `App/...` à la racine du dépôt.

**[?]** = non retrouvé dans le code ou non confirmé. **[à confirmer par MWM]** = ce que Spark Flash collecte, quand le manifeste du SDK ne le dit pas.

## 1. Étiquettes App Privacy (ce qui quitte l'iPhone)

Suivi (ATT) : **Non, aucun suivi.** `NSPrivacyTracking` est faux dans l'app et dans le SDK.

| Type de donnée (Apple) | Lié à l'utilisateur | Suivi | Finalité | Source |
|---|---|---|---|---|
| Achats : historique d'achats | Non | Non | Fonctionnement de l'app | Spark Flash, après accord ; manifeste du SDK |
| Utilisation : interaction avec le produit | Non | Non | Analytique | Spark Flash, après accord |
| Diagnostics : données de performance | Non | Non | Analytique | Spark Flash, après accord |
| Diagnostics : données de plantage | Non | Non | Analytique | Spark Flash, après accord |
| Diagnostics : autres données de diagnostic | Non | Non | Analytique | Spark Flash, après accord |
| Identifiants : identifiant utilisateur | Non (d'après le manifeste) | Non | Fonctionnement de l'app, Analytique | Spark Flash ; [à confirmer par MWM] car Apple range souvent un identifiant en « lié » |
| Identifiants : identifiant d'appareil | Non (d'après le manifeste) | Non | Analytique | idem [à confirmer par MWM] |
| Position approximative (déduite de l'IP par le SDK) | [à confirmer par MWM] | Non | Analytique | absente du manifeste, citée par les conditions du SDK : question n° 3 |

Ne se déclare pas (reste sur l'iPhone, ou ne nous parvient pas) :
- position précise, coins de pêche, photos de prises (jamais envoyés par l'app) ;
- cartes partagées entre amis : écrites dans l'iCloud du pêcheur (CloudKit, base privée), invisibles pour l'éditeur ; si Apple demande « Contenu utilisateur : photos », la réponse la plus prudente est de le déclarer **non collecté par nous** et de le dire dans les notes du relecteur [?] ;
- météo : un point arrondi ou une station OFB part vers WeatherKit (service d'Apple, sans lien avec une identité) : par défaut non déclaré, à confirmer avec MWM (question n° 9) ;
- Hub'Eau : un code de station, rien de personnel : non ;
- notifications : locales : non.

Réponses pour `get_legal_questionnaire` (mêmes données) :
- compte utilisateur : non ; publicité : non ; courtier de données : non ; vente de données : non ;
- SDK tiers : oui, Spark Flash (MWM), démarré seulement après accord ; refus = éteint ;
- contenu partagé entre utilisateurs : oui, facultatif, sur invitation, jamais public (iCloud) ;
- âge : pas « Made for Kids » ; non destinée aux moins de 13 ans [à confirmer par MWM, question n° 6] ;
- `jurisdictions` : FR et UE ; éditeur : [ÉDITEUR, à demander à MWM] ; contact : [EMAIL de contact, donné par Adem] ; date : 16 oct. 2026 ;
- chiffrement : `ITSAppUsesNonExemptEncryption` = NON (`Config/BuildChallenge-Info.plist:24-25`), SDK [à confirmer par MWM, question n° 7].

## 2. Tableau de preuves (flux, fichier:ligne)

| # | Flux | Preuve dans le code | État |
|---|---|---|---|
| 1 | Position précise sur l'iPhone seulement | demande `requestWhenInUseAuthorization` : `App/Carte/Modele/GestionPosition.swift:37` ; texte d'autorisation « Ta position reste sur ton iPhone » : `Config/BuildChallenge-Info.plist:28-29` ; aucun client réseau ne reçoit le coin exact (voir 2 et 3) | vérifié |
| 2 | WeatherKit : point arrondi ou station, jamais le coin exact | appel : `App/Conditions/SourceWeatherKit.swift:13` ; le point vient de `pointMeteo(spot:)` : `App/Conditions/ConditionsDuSpot.swift:38` ; station si à moins du rayon, sinon `Geodesie.arrondi`, et décalage si égal au spot : `Packages/Core/Sources/Core/Conditions/MoteurConditions.swift:142-150` ; capacité : `Config/BuildChallenge.entitlements:17-18` | vérifié |
| 3 | Hub'Eau : code de station seulement | `Packages/Core/Sources/Core/Conditions/HubEauNiveauService.swift:11` (base), `:71` et `:87` (paramètre `code_entite` + grandeur, dates, taille) ; station choisie par `stationHydro(pres:)` : `App/Conditions/ConditionsDuSpot.swift:43` | vérifié |
| 4 | Spark Flash : consentement avant démarrage, refus = éteint | `Spark.configure` appelé à un seul endroit : `App/BuildChallengeApp.swift:25` ; déclenché par `configurerUneFois` seulement si accord : `App/Mesure/CoucheMesure.swift:54-55, 75` ; événements gardés par `guard actif` : `:87, :92, :110` ; refus : `:65` ; demande au pêcheur : `App/Mesure/FeuilleConsentement.swift:11`, `App/RootView.swift:659`, retrait dans Mon club : `App/RootView.swift:299` ; appels SDK : `App/Mesure/PasserelleSpark.swift:18, 22, 26` | vérifié dans le code ; comportement réel du SDK avant `configure` : [?] (question n° 5 à MWM) |
| 5 | Ce que Spark Flash reçoit | 7 types, tous `Linked` faux, `Tracking` faux : `mwm-spark-flash-sdk/local-spm-repo/Sources/Resources/PrivacyInfo.xcprivacy:12, 27-111` ; version du dépôt 0.5.7 (`mwm-spark-flash-sdk/README.md:5`), la note S1 disait 0.5.8 | vérifié pour le manifeste ; liste réelle : [à confirmer par MWM] |
| 6 | Événements de mesure sans donnée personnelle | noms fixes `map_ready`, `capture_started`, `card_created`, `session_started`, `session_ended`, `paywall_viewed` : `App/Mesure/CoucheMesure.swift:96-104` ; `proprietes: [:]` : `:88` ; seul `declencheur` accompagne `paywall_viewed` : `:92-93` | vérifié |
| 7 | Abonnements StoreKit | `Product.products` : `App/Abonnement/AchatsStoreKit.swift:60, 131` ; `Transaction.updates` / `currentEntitlements` : `:83, :109` ; achat passé au SDK après accord : `App/Mesure/PasserelleSpark.swift:22` | vérifié |
| 8 | Photos enregistrées sans GPS | prise redressée puis `jpegData` (ré-encodage, sans bloc GPS) : `App/Prise/PriseModele.swift:64-65` ; copie de la toise « sans métadonnées » : `App/Prise/ToiseLecteur.swift:35` ; export de la carte : `App/Club/ImageSansGPS.swift:5-23` ; texte d'autorisation : `Config/BuildChallenge-Info.plist:30-31` | vérifié pour les copies exportées et partagées ; la photo prise par la caméra ne reçoit pas de GPS d'après ce chemin, mais aucun test ne le prouve [?] |
| 9 | Aucun coin exact ne quitte l'iPhone (amis) | clés d'un enregistrement CloudKit : `App/Amis/FabriqueRecords.swift:8` (espèce, rareté, date, taille, bredouille, zone, image) ; la zone est le département : `App/Amis/ConstructeurCartes.swift:20, 27` ; image sans GPS : `App/Amis/FabriqueRecords.swift:21`, `App/Amis/PngSansGPS.swift:15-23` | vérifié |
| 10 | Amis : CloudKit, zone partagée par CKShare, invités seulement | `CKShare(recordZoneID:)` : `App/Amis/ServiceAmisCloudKit.swift:69` ; `publicPermission = .none` : `:70` ; zone « Pescedex » privée : `:13` ; conteneur iCloud : `Config/BuildChallenge.entitlements:5-12` ; SwiftData local sans synchro : `App/Collection/DepotCartes.swift:19, 25` ; bloquer / retirer / supprimer mes cartes : `App/Amis/GestionAmis.swift:165-170, 202` ; signalement par e-mail sans coordonnée : `App/Amis/Signalement.swift:6` | vérifié |
| 11 | Widgets (App Group) | groupe : `Config/BuildChallenge.entitlements:13-15`, `Config/FishMeWidget.entitlements:7`, `WidgetAquarium/InstantaneAquarium.swift:69` ; contenu : espèces, rareté, rations, abonnement, « jamais de lieu » : `WidgetAquarium/InstantaneAquarium.swift:5-7` | vérifié |
| 12 | Live Activity / écran verrouillé | `Activity<SessionActivityAttributes>` : `Widget/Session/PilotageActivite.swift:13` ; contenu = début, fin légale, nombre de prises : `Widget/Session/EtatSession.swift:11-20` (« aucune coordonnée ») | vérifié |
| 13 | Modèle de reconnaissance sur l'appareil | `MLModel(contentsOf:)` sur un modèle du bundle : `App/Prise/IdentificationDino.swift:99` ; `Vision` local ; paquet : `App/Prise/Modele/PoissonsDino-int8.mlpackage` | vérifié |
| 14 | Aucun compte, aucune pub | aucun code de connexion ni de régie publicitaire trouvé dans `App/` (recherche de `ASAuthorization`, `GADMobileAds`, `AdSupport`, `ATTrackingManager` : zéro résultat) ; manifeste de l'app : `NSPrivacyTracking` faux, domaines vides : `App/PrivacyInfo.xcprivacy:5-8` | vérifié par absence |
| 15 | Notifications locales | `UNUserNotificationCenter` : `App/Conditions/PreviensMoi.swift:78, 82` ; aucun enregistrement APNs trouvé | vérifié par absence |
| 16 | Marque Apple Weather | téléchargement des images de marque (adresses fournies par WeatherKit) : `App/Conditions/MarqueMeteoView.swift:35`, attribution : `App/Conditions/SourceWeatherKit.swift:54` | vérifié ; requête réseau à ajouter à la liste des flux si Apple le demande |
| 17 | Mise à jour des règles par réseau | `TelechargeFichierHTTP(base: adresse())` : `App/Veille/ReglesAJour.swift:38` ; adresse lue dans `ReglesBaseURL`, vide : `Config/BuildChallenge-Info.plist:32-33` | **[?]** inactif dans ce build (adresse vide) ; si Adem renseigne une adresse, la politique doit le dire (le serveur voit l'IP, aucun paramètre n'est envoyé) |

## 3. Écarts à régler avant l'envoi

1. `App/PrivacyInfo.xcprivacy:9` déclare `NSPrivacyCollectedDataTypes` vide alors que Spark Flash en déclare 7 : Apple fusionne les manifestes, mais A doit relire « Generate Privacy Report » et s'assurer que l'app et les étiquettes ci-dessus s'accordent. Hors `store/` (A).
2. Version du SDK : 0.5.7 dans le dépôt, 0.5.8 dans la note S1 : demander la bonne à MWM.
3. Les crochets restants des trois textes : éditeur, e-mail de contact, durée de conservation Spark Flash, liste complète des données Spark Flash, âge minimal, médiateur, EULA propre à l'app, durée de conservation des messages de contact.
4. Les clauses de `confidentialite-spark-flash.md` §1 : la n° 4 (amis) décrit maintenant un partage réel (les amis sont dans la version soumise) ; la question n° 10 de MWM (version sans amis) tombe.
