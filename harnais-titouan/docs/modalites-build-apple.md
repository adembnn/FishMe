# Modalités de build Apple - Bredouille (octobre 2026)

Légende : ✔ = vérifié à la source Apple (développeur) ; ⚠ = non vérifié à la source (mémoire / source secondaire), à recontrôler.
Répartition : **Adem = dev Mac** (seul à pouvoir compiler, signer, archiver, envoyer) ; **Titouan = dev Windows** (édition de code/YAML/plist/JSON, pas de compilateur).
⚠ Hypothèse : Adem = Mac, Titouan = Windows. Si c'est l'inverse, permuter les noms partout.

Sources Apple consultées : developer.apple.com/news/upcoming-requirements, docs TestFlight (App Store Connect Help), doc `SystemLanguageModel` (Foundation Models). Le reste vient de connaissances antérieures non rouvertes aujourd'hui.

---

## 1. SDK exigé à la soumission aujourd'hui (13 oct. 2026)

- ✔ Depuis le **28 avril 2026**, tout build envoyé à App Store Connect doit être compilé avec **Xcode 26 ou plus récent**, avec le SDK iOS 26 / iPadOS 26 / tvOS 26 / watchOS 26 / visionOS 26.
- ✔ Depuis le **9 sept. 2026**, cible de déploiement iOS minimale à l'envoi : iOS 13 (sans objet pour nous, iOS 26 minimum).
- ✔ La page "Upcoming Requirements" ne mentionnait **aucune exigence Xcode 27 / SDK iOS 27** à la date de lecture.
- ⚠ Xcode 27 / iOS 27 existent probablement déjà (cycle annuel, sortie en septembre). Rien n'oblige à les utiliser tant qu'Apple n'annonce pas de nouvelle date. Revérifier la page avant la soumission finale.
- Piège : un Mac resté sur Xcode 16.x ou une image CI/Xcode Cloud épinglée sur une ancienne version = rejet à l'upload (avant review). Autre piège : une bêta d'Xcode (même 26.x bêta ou 27 bêta) ne peut pas toujours uploader sur l'App Store ; ⚠ utiliser une version "Release" de Xcode.
- Qui : **Adem** (installer/maintenir Xcode 26.x Release). Titouan : rien.

## 2. Cibles et schémas (XcodeGen)

- Règle : `project.yml` est la source de vérité ; le `.xcodeproj` est généré (`xcodegen generate`) et ne doit pas être édité à la main ni, idéalement, committé (⚠ à vérifier selon la convention du dépôt).
- Une cible app (type `application`, plateforme iOS, `deploymentTarget: "26.0"`), éventuellement une cible de tests. PecheCore (logique pure, Swift Package) et PecheApple (code lié aux frameworks Apple) sont des **packages Swift locaux** référencés dans `packages:` puis en `dependencies: - package:` de la cible app.
- Schéma : le générer explicitement dans `schemes:` (build, test, run, **archive en configuration Release**). Un schéma non partagé (`shared: true` absent) n'est pas vu par xcodebuild/CI.
- Piège : ajouter un fichier sur Windows sans relancer `xcodegen` côté Mac = fichier absent du projet ; modifier le `.xcodeproj` local = écrasé à la prochaine génération. Les `swift-tools-version` des packages doivent être compatibles avec Xcode 26 (6.2 ou inférieur).
- Piège : les ressources (assets, `.xcprivacy`, `.storekit`) doivent être déclarées dans `sources`/`resources` de `project.yml`, pas seulement présentes sur disque.
- Qui : Titouan édite `project.yml` et la structure des dossiers ; **Adem** lance `xcodegen generate`, corrige les erreurs de résolution de packages et valide le build.

## 3. Identifiant de bundle

- Règle : un Bundle ID unique, en notation DNS inversée (ex. `fr.<équipe>.bredouille`), défini dans `PRODUCT_BUNDLE_IDENTIFIER` de `project.yml`. Il doit correspondre exactement à l'App ID enregistré dans le portail Developer et à l'app dans App Store Connect.
- Il est **définitif** une fois l'app créée dans App Store Connect (pas de renommage possible). Les identifiants de produits StoreKit et les App Groups en dérivent souvent.
- Piège : un Bundle ID déjà pris par un autre compte donne "identifier not available" ; choisir avant le 1er build. Les extensions (widget, etc.) doivent avoir un ID préfixé par celui de l'app.
- Qui : décision commune ; **Adem** l'enregistre (Xcode crée l'App ID avec la signature automatique) ; Titouan l'écrit dans `project.yml` une fois décidé.

## 4. Signature automatique et profils

- Règle : `CODE_SIGN_STYLE: Automatic` + `DEVELOPMENT_TEAM: <Team ID à 10 caractères>` dans `project.yml`. Xcode crée certificats de développement/distribution et profils de provisioning.
- Piège : sans Team ID dans `project.yml`, chaque `xcodegen generate` efface le choix d'équipe fait dans l'interface Xcode. Autre piège : compte gratuit (Personal Team) = pas d'envoi TestFlight, certaines capacités indisponibles ; il faut le **programme Apple Developer payant (99 USD/an)**. ⚠ Vérifier si un accès hackathon/Challenge fournit un compte d'équipe.
- Appareil de test : l'iPhone doit être enregistré (automatique à la première connexion en mode développeur : réglage "Mode développeur" activé sur l'iPhone).
- Pour l'archive de distribution, la signature automatique crée un certificat "Apple Distribution" géré dans le cloud (limité par le rôle du compte).
- Qui : **Adem** (compte connecté dans Xcode > Settings > Accounts, rôle Admin ou App Manager au minimum, ⚠). Titouan fournit la config dans `project.yml`.
- Pour qu'Adem puisse tout faire seul : être invité dans l'équipe Developer et App Store Connect avec un rôle adéquat (Admin/App Manager).

## 5. Capacités et entitlements

- Règle : une capacité = (1) activée sur l'App ID, (2) une clé dans le fichier `.entitlements`, (3) reflétée dans le profil. Avec la signature automatique, (1) et (3) sont gérés par Xcode au premier build.
- Dans XcodeGen : `entitlements: path:` + `properties:` sur la cible app, et le fichier est généré.
- À n'activer que si utilisé : un entitlement superflu peut provoquer un rejet ou une alerte de profil. Pour l'instant, a priori **aucune capacité spéciale** n'est requise pour : caméra, photothèque (via PhotosPicker), localisation en usage, StoreKit (l'achat intégré n'a pas d'entitlement), Foundation Models (aucun entitlement). ⚠ Notifications push, iCloud/CloudKit, App Groups, HealthKit, etc. seraient à ajouter explicitement si on s'en sert.
- Piège : modifier un entitlement sur Windows sans le déclarer dans `project.yml` = perdu à la régénération.
- Qui : Titouan écrit les clés ; **Adem** valide que le profil se régénère (erreur "profile doesn't include entitlement" = relancer le build avec comptes connectés).

## 6. Clés Info.plist utiles

Avec XcodeGen, les déclarer dans `info: properties:` (ou `INFOPLIST_KEY_*` en build settings). Le fichier Info.plist généré est écrasé : ne pas éditer à la main.

- ✔/⚠ **Chaînes d'usage** (obligatoires dès qu'on touche l'API, sinon crash à l'exécution ET rejet) :
  - `NSCameraUsageDescription` (photo de la prise)
  - `NSPhotoLibraryUsageDescription` (lecture, seulement si accès direct à la photothèque ; **PhotosPicker n'en a pas besoin**)
  - `NSPhotoLibraryAddUsageDescription` (enregistrer une photo dans la photothèque)
  - `NSLocationWhenInUseUsageDescription` (spot de pêche, météo/marées)
  - Éviter `NSLocationAlwaysAndWhenInUseUsageDescription` sauf besoin réel (revue plus sévère).
- Règle de rédaction : en français, concret, dire **pourquoi** ("Bredouille utilise votre position pour enregistrer le lieu de la prise"). Un texte vague ("nécessaire à l'app") est un motif de rejet fréquent (⚠ guideline 5.1.1).
- **`ITSAppUsesNonExemptEncryption`** : booléen. Si l'app n'utilise que HTTPS/URLSession et le chiffrement système, mettre `NO` (⚠ exemption standard). Évite la question de conformité export à chaque build dans App Store Connect/TestFlight. Piège : si on ajoute du chiffrement propriétaire/personnalisé, la valeur `NO` devient fausse. ✔ TestFlight renvoie à "Cryptography and US export compliance" si la clé est absente.
- Autres : `UILaunchScreen` (dictionnaire, écran de lancement simple), `UISupportedInterfaceOrientations` (portrait seul si voulu), `CFBundleDisplayName` ("Bredouille"), `UIApplicationSceneManifest` (SwiftUI).
- `CFBundleLocalizations`/`CFBundleDevelopmentRegion` : `fr` (⚠ si l'app est française seulement).
- Qui : Titouan rédige les chaînes (français) dans `project.yml` ; **Adem** teste sur appareil que les invites s'affichent.

## 7. PrivacyInfo.xcprivacy et API à raison requise

- ✔ Depuis le **1er mai 2024**, l'envoi doit contenir des raisons approuvées pour les API à raison requise, **y compris celles des SDK tiers**.
- Fichier `PrivacyInfo.xcprivacy` (plist) dans la cible app (et idéalement dans chaque package qui utilise ces API : PecheCore/PecheApple en ressource).
- Clés : `NSPrivacyTracking` (false), `NSPrivacyTrackingDomains` ([]), `NSPrivacyCollectedDataTypes` (types de données collectées si on en envoie hors de l'appareil), `NSPrivacyAccessedAPITypes`.
- Catégories d'API à raison requise (constantes `NSPrivacyAccessedAPICategory...`) :
  - `UserDefaults` : `CA92.1` (lecture/écriture de données propres à l'app) ; `1C8F.1` si App Group. ⚠ codes cités depuis une source secondaire.
  - `FileTimestamp` (dates de création/modification de fichiers) : `C617.1` (conteneur de l'app), `3B52.1`, `DDA9.1`.
  - `DiskSpace` : `85F4.1` (afficher à l'utilisateur), `E174.1` (vérifier l'espace avant écriture).
  - `SystemBootTime` (`systemUptime`, `mach_absolute_time`) : `35F9.1` (mesure d'intervalle), `8FFB.1`.
  - `ActiveKeyboards` : `3EC4.1`.
- Piège : `UserDefaults`/`@AppStorage` est très courant et exige la déclaration ; le chronométrage (`ProcessInfo.systemUptime`, `ContinuousClock` selon implémentation) déclenche `SystemBootTime`. La raison déclarée doit correspondre à l'usage réel. Les données collectées déclarées doivent concorder avec les "App Privacy" (étiquettes de confidentialité) d'App Store Connect.
- Vérification : Xcode > Product > Archive > "Generate Privacy Report" (⚠ nom exact du menu) agrège les manifestes.
- Qui : Titouan écrit le `.xcprivacy` (texte) en listant les API réellement employées (grep dans le code) ; **Adem** génère le rapport de confidentialité à l'archive ; décision commune pour les étiquettes App Privacy.

## 8. Numéro de version vs numéro de build

- `MARKETING_VERSION` (= `CFBundleShortVersionString`) : version visible, ex. `1.0.0` ; `CURRENT_PROJECT_VERSION` (= `CFBundleVersion`) : numéro de build, entier croissant.
- Règle : pour une même version, **chaque envoi doit avoir un build strictement supérieur** aux précédents (sinon "bundle version already exists"). Même chose sur TestFlight.
- Piège : oublier d'incrémenter après un envoi refusé en traitement ; avoir un `project.yml` qui remet la valeur à 1 lors du commit d'un autre dev.
- Bonne pratique : fixer la version dans `project.yml`, incrémenter le build avant chaque archive (⚠ ou utiliser un horodatage/numéro de CI).
- Qui : Titouan peut bumper dans `project.yml` ; **Adem** vérifie avant d'archiver.

## 9. Archive et export

- Règle : Xcode > Product > Archive (destination "Any iOS Device (arm64)", configuration Release) ; ou en ligne de commande : `xcodebuild archive -scheme <schéma> -configuration Release -destination 'generic/platform=iOS' -archivePath build/Bredouille.xcarchive`, puis `xcodebuild -exportArchive -archivePath ... -exportOptionsPlist ExportOptions.plist -exportPath build/export`.
- `ExportOptions.plist` : `method` = `app-store-connect` (⚠ anciennement `app-store`), `teamID`, `signingStyle` = `automatic`, `destination` = `upload` (envoie directement) ou `export` (produit un .ipa).
- Piège : archiver un simulateur ou en Debug ; oublier `xcodegen generate` avant ; l'archive échoue si un package utilise un SDK plus ancien.
- Qui : **Adem**. Titouan ne peut rien archiver ; il peut préparer `ExportOptions.plist`.

## 10. Envoi vers App Store Connect

- **Xcode Organizer** (recommandé) : Window > Organizer > Archives > Distribute App > App Store Connect > Upload. Gère signature et validations.
- **Transporter** (app Mac gratuite) : glisser un `.ipa` exporté. Utile si l'envoi se fait depuis une autre machine que celle qui a archivé.
- **`xcrun altool --upload-app`** : ⚠ obsolète pour les nouveaux flux ; ✔ `altool` ne sert plus à la notarisation (depuis nov. 2023, utiliser `notarytool` - ce qui concerne macOS uniquement, **pas pertinent pour une app iPhone**). Pour l'iOS, préférer `xcodebuild -exportArchive` avec `destination: upload` ou Transporter/`iTMSTransporter`.
- **Clé d'API App Store Connect** (⚠) : créée par un Admin (Utilisateurs et accès > Intégrations > Clés), donne Issuer ID + Key ID + fichier `.p8` (téléchargeable **une seule fois**). Sert à automatiser l'envoi (`xcodebuild -authenticationKeyPath ...` ou `altool --apiKey/--apiIssuer`) sans mot de passe. Ne jamais committer le `.p8`.
- Après envoi : traitement côté Apple (quelques minutes à ~1 h), email "build processed" ou erreurs (clé manquante, icône, privacy, SDK).
- Qui : **Adem**. La clé API : à créer par l'Admin du compte, stockée en dehors du dépôt.

## 11. Enregistrement de l'app dans App Store Connect

- Règle : avant tout envoi, créer l'app : App Store Connect > Apps > "+" > Nouvelle app (plateforme iOS, nom, langue principale, Bundle ID existant, SKU libre).
- Champs requis à la soumission App Store (pas pour TestFlight interne) : captures d'écran (tailles iPhone exigées), description, mots-clés, URL de support, **URL de politique de confidentialité**, catégorie, classification d'âge (✔ questionnaire mis à jour : à remplir pour chaque app depuis le 31 janv. 2026), étiquettes App Privacy, infos de contact de la review, compte de démonstration si connexion.
- ⚠ Pour l'UE : statut de "trader" (DSA) requis pour distribuer en UE (✔ exigence listée depuis octobre 2024).
- Piège : nom d'app déjà pris (ASC refuse) ; vérifier avant. Pas de renommage du Bundle ID après coup.
- Qui : **Adem** (créer l'app et saisir les métadonnées) ; Titouan rédige textes FR, mots-clés, politique de confidentialité, captures (Titouan peut fournir les textes ; les captures viennent du simulateur Mac).

## 12. TestFlight : interne vs externe

- ✔ **Interne** : jusqu'à 100 utilisateurs ayant un rôle dans App Store Connect ; pas de review Apple ; build disponible dès la fin du traitement.
- ✔ **Externe** : jusqu'à 10 000 testeurs (email ou lien public) ; ✔ le **premier build** de chaque groupe passe la **Beta App Review** (délai possible d'un jour ou plus), les suivants n'en ont pas forcément besoin.
- ✔ Un build reste testable **90 jours**.
- ✔ Les builds doivent inclure l'identifiant d'application dans le profil de provisioning, et gérer la conformité export (voir `ITSAppUsesNonExemptEncryption`).
- Piège : un testeur interne doit être invité comme utilisateur ASC (accepter l'invitation) ; Titouan doit être ajouté à l'équipe ASC pour tester en interne sur son iPhone. Les "informations de test bêta" (description, email de contact) sont requises pour l'externe.
- Piège : un compte de reviewer qui ne peut pas accéder à une fonction (ex. localisation sans pêche réelle) = blocage ; prévoir un mode démo.
- Qui : **Adem** crée les groupes et ajoute les builds ; Titouan accepte l'invitation, installe TestFlight sur iPhone, remonte les retours.

## 13. Produits StoreKit : fichier .storekit local vs App Store Connect

- **Fichier `.storekit` (Configuration StoreKit locale)** : sert au développement/tests dans le simulateur et sur appareil via Xcode (schéma > Run > Options > StoreKit Configuration). Aucun lien avec ASC, aucun compte nécessaire, transactions simulées (test d'abonnements accélérés, remboursements, erreurs). **Ne part pas en production** ; il ne doit pas être sélectionné dans le schéma Archive/Release.
- **Produits App Store Connect** : à créer pour TestFlight/production (App Store Connect > l'app > Monétisation > Achats intégrés / Abonnements). Les identifiants de produit **doivent être identiques** à ceux du fichier `.storekit`. Il faut aussi : contrat "Paid Apps" signé, coordonnées bancaires et fiscales saisies par le titulaire du compte, métadonnées (nom localisé, prix, capture pour review), statut "Prêt à soumettre".
- ✔ Dans TestFlight, les achats utilisent le **sandbox** (aucun débit réel).
- Piège : produits en "Missing Metadata" = `Product.products(for:)` renvoie vide ; le premier IAP doit être soumis avec une version de l'app. Vérification de reçu : ✔ utiliser les API `Transaction`/`AppTransaction` (le SHA-1 de l'ancien certificat a expiré en janv. 2025).
- Qui : Titouan écrit/édite le `.storekit` (JSON) et le code StoreKit 2 ; **Adem** (ou titulaire du compte, rôle Account Holder) crée les produits dans ASC et signe les contrats.

## 14. Icône 1024

- Règle : une icône App Store de **1024 x 1024 px**, PNG, **sans transparence** (⚠ ni coins arrondis : Apple les applique), espace colorimétrique sRGB ou Display P3, dans le catalogue `Assets.xcassets/AppIcon.appiconset` (plateforme iOS, entrée "single size"/universelle). ⚠ Avec Xcode 26 / iOS 26, Apple propose aussi le format **Icon Composer** (`.icon`, calques "Liquid Glass") ; un PNG simple reste accepté.
- Piège : canal alpha ou image trop petite = erreur "Invalid large app icon" à l'upload ; l'icône doit être listée dans `project.yml` (`ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`) et le catalogue inclus dans les ressources.
- Qui : Titouan (création/export du PNG 1024, vérification sans alpha) ; **Adem** vérifie le rendu dans Xcode et à l'upload.

## 15. Foundation Models (IA sur appareil)

- ✔ Framework `FoundationModels`, **iOS 26.0+** (aussi iPadOS, macOS, visionOS 26). L'accès se fait via `SystemLanguageModel.default`.
- ✔ Disponible **uniquement sur appareil prenant en charge Apple Intelligence**, dans une région/langue prise en charge, avec Apple Intelligence **activé** par l'utilisateur. À tester à l'exécution : `SystemLanguageModel.default.availability` renvoie `.available` ou `.unavailable(raison)`.
- Raisons d'indisponibilité (source secondaire) : `deviceNotEligible`, `appleIntelligenceNotEnabled`, `modelNotReady` (modèle encore en téléchargement). ⚠ liste exacte à confirmer dans la doc.
- ⚠ Appareils compatibles : iPhone 15 Pro / 15 Pro Max et tous les iPhone 16 et ultérieurs (iPhone 17 compris). Les iPhone 15 et 14 ne le sont pas. Liste officielle : page "Apple Intelligence" d'Apple, non relue ici.
- ✔ Le **simulateur** : ⚠ fonctionne seulement si le Mac hôte (Apple silicon) a Apple Intelligence activé.
- ✔ Le modèle évolue avec les mises à jour d'OS (versions 26.0-26.3, 26.4, 27.0 listées par Apple).
- ⚠ Langue : le français est pris en charge par Apple Intelligence depuis iOS 26 ; un appareil avec langue Siri non supportée voit le modèle indisponible (✔ cas rapporté sur le forum développeur).
- Règle de conception : **toujours prévoir un repli** (saisie manuelle, texte statique) quand le modèle est indisponible ; ne jamais rendre une fonction vitale dépendante.
- Piège : revue App Store sur un iPhone sans Apple Intelligence = la fonction est indisponible ; le reviewer doit encore pouvoir valider l'app. Pas d'entitlement ni de chaîne Info.plist spécifique.
- Qui : Titouan écrit le code de repli côté PecheCore/PecheApple (logique sans appareil) ; **Adem** teste sur un iPhone compatible.

---

## Checklist d'envoi (ordre conseillé)

1. Titouan : `project.yml` à jour (version, build, Team ID, Bundle ID, Info.plist, entitlements, icône, `PrivacyInfo.xcprivacy`, ressources) et poussé.
2. Adem : `git pull` + `xcodegen generate` + build sur appareil iPhone ; vérifier les invites (caméra, localisation, photos).
3. Adem : créer l'app dans App Store Connect (si absent) et les produits IAP (si utilisés).
4. Adem : incrémenter le build, Archive (Release, Xcode 26+), Distribute > Upload.
5. Adem : attendre le traitement ; ajouter le build au groupe TestFlight interne ; inviter Titouan.
6. Titouan : installer via TestFlight, tester, remonter les bugs. Ensuite groupe externe + Beta App Review si besoin.
7. Soumission App Store : métadonnées, captures, confidentialité, âge, review.

## Points à revérifier avant la soumission finale (⚠)

- Page "Upcoming Requirements" (nouvelle exigence Xcode 27 possible).
- Liste officielle des appareils Apple Intelligence et des langues (dont le français).
- Codes de raison exacts du `.xcprivacy` dans la doc "Describing use of required reason API" (la page n'a pas pu être relue directement).
- Méthode d'export (`app-store-connect` vs `app-store`) selon la version d'Xcode installée.
- Rôles ASC nécessaires (Admin/App Manager) et accès au compte développeur du Challenge.
