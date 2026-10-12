# Amis : quel outil pour voir la collection de ses amis invités
Décision débloquée : choisir l'outil qui laisse les amis invités voir le Pescedex les uns des autres vendredi (étape E8 de `build/parcours-demo.md`).
Lu le 12/10/2026

## En bref
Image : chaque pêcheur a déjà un coffre chez Apple, son iCloud. CloudKit (la base de données d'Apple, utilisable sans serveur à nous) sait ouvrir une pièce de ce coffre à des amis précis, par un lien envoyé dans Messages. Les cartes restent chez Apple : la base privée d'un utilisateur n'apparaît pas dans le portail développeur ([en-tête CloudKit](https://docs.rs/objc2-cloud-kit/0.3.2/x86_64-apple-darwin/src/objc2_cloud_kit/generated/CKContainer.rs.html)), donc ni MWM ni nous ne pouvons les lire.
Détail : SwiftData (le stockage local de l'app) ne partage pas. Un ingénieur Apple écrit que SwiftData avec la base partagée ou publique de CloudKit « isn't supported today » ([forum](https://developer.apple.com/forums/thread/756721)), et la session WWDC26 « What's new in SwiftData » n'en parle pas (transcription lue : [source](https://github.com/pixelfolio/WWDC26-Transcripts/blob/main/wwdc2026-274%20-%20What%E2%80%99s%20new%20in%20SwiftData.md)). [?] Pas de confirmation écrite d'Apple pour iOS 27. On garde donc SwiftData pour la collection locale et on écrit une petite couche CloudKit pour la partie partagée.

## Les 11 options (probabilité qu'un autre LLM la propose : estimation, pas mesure)
| # | Option | Proba | Verdict |
|---|---|---|---|
| 1 | CloudKit, zone partagée (`CKShare` : l'objet qui représente l'invitation de partage), SwiftData reste local | 65 % | Recommandée |
| 2 | CloudKit via Core Data (`NSPersistentCloudKitContainer` : l'ancien stockage d'Apple, qui sait synchroniser et partager) | 40 % | Refaire le stockage, risque de fuite du coin |
| 3 | CloudKit base publique (lisible par tous les utilisateurs de l'app) + codes d'amis | 40 % | Lisible par tous |
| 4 | Firebase (service de Google : connexion, base Firestore, fichiers Storage) | 70 % | Serveur tiers, carte bancaire pour les photos |
| 5 | Supabase (base hébergée, ouverte, à configurer en SQL) | 50 % | Serveur tiers, pause après une semaine |
| 6 | **Game Center (réseau d'amis et classements d'Apple)** | **18 %** | Ne montre pas les cartes |
| 7 | Fichier `.pescedex` envoyé par AirDrop (envoi direct entre iPhones proches) ou Messages | 25 % | Meilleur repli |
| 8 | **Extension iMessage (cartes en messages)** | **8 %** | Cartes isolées, pas de collection |
| 9 | **SharePlay (activité partagée pendant un appel FaceTime)** | **4 %** | Rien n'est conservé |
| 10 | **Proximité directe (Multipeer Connectivity : échange direct entre iPhones proches)** | **6 %** | Même pièce seulement, utile en démo hors ligne |
| 11 | **Base publique CloudKit chiffrée sur l'iPhone, clé dans le lien** | **3 %** | Public quand même, modération impossible |

## Comparaison (une colonne par option, 8 critères)
Rien n'a été installé ni testé ici : ce sont des lectures de documentation Apple et des estimations. Un « Oui » veut dire « possible d'après la doc », pas « vu à l'écran ».
### Tableau 1 : les deux façons de partager avec CloudKit
| Critère | 1. CKShare + SwiftData local | 2. Core Data + NSPersistentCloudKitContainer |
|---|---|---|
| Temps (estimation) | 6 à 10 h, dont 1 h de portail | 10 à 16 h : sortir la collection de SwiftData |
| Coût | 0 € de plus que l'adhésion MWM ([incluse](https://developer.apple.com/programs/whats-included)) ; les données comptent dans l'iCloud du pêcheur ([en-tête CloudKit](https://docs.rs/objc2-cloud-kit/0.3.2/x86_64-apple-darwin/src/objc2_cloud_kit/generated/CKContainer.rs.html)) | idem |
| Compte | Aucun compte à nous, pas de Sign in with Apple ; iCloud connecté obligatoire ([doc](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)) | idem |
| Démo 2 iPhones | Oui, avec 2 comptes iCloud différents ([exemple Apple](https://developer.apple.com/documentation/cloudkit/sharing-cloudkit-data-with-other-icloud-users)) | Oui ([exemple Apple](https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users)) |
| App Store | 1.2 : exige filtre, signalement, blocage, contact publié, et le texte ne prévoit pas d'exception pour un groupe privé ([règle](https://developer.apple.com/app-store/review/guidelines/)) : donc signaler et bloquer, même entre amis [?] application aux groupes privés non confirmée. 5.1.1(v) : l'app ne crée aucun compte, donc a priori sans objet [?] | idem |
| Moins de 13 ans | Compte enfant obligatoire sous 13 ans ([Apple](https://www.apple.com/ca/child-safety)) ; partage CloudKit entre comptes enfants [?] non vérifié | idem |
| Ce qui sort | Seulement les champs que nous écrivons, vers l'iCloud du pêcheur puis les amis acceptés | L'objet entier et ses relations partent dans la zone partagée ([doc](https://developer.apple.com/documentation/coredata/sharing-core-data-objects-between-icloud-users)) : le coin exact partirait avec |
| Réseau coupé | Collection locale intacte ; envoi à rejouer et cache des cartes d'amis à coder | CloudKit rejoue les envois seul [?] |

### Tableau 2 : bases publiques et Game Center
| Critère | 3. Base publique + codes | 11. Publique chiffrée | 6. Game Center |
|---|---|---|---|
| Temps (estimation) | 6 à 8 h + modération | 12 h et plus | 3 à 5 h |
| Coût | 0 € (quota de l'app, [doc](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)) | idem | 0 € |
| Compte | Lecture sans iCloud, écriture avec iCloud | idem | Compte Game Center de chaque joueur |
| Démo 2 iPhones | Oui | Oui | Amis et scores seulement : `GKLeaderboard` porte un score, pas une photo ([doc](https://developer.apple.com/documentation/gamekit/gkleaderboard)) |
| App Store | 1.2 complet (contenu public) | idem | Pas de contenu d'utilisateur ; Game Center dans une app non-jeu [?] |
| Moins de 13 ans | Photos d'enfants lisibles par tous : à éviter | idem | Parents peuvent bloquer l'ajout d'amis ([Apple](https://discussions.apple.com/thread/253640468)) ; `isUnderage` ([doc](https://developer.apple.com/documentation/gamekit/gklocalplayer)) |
| Ce qui sort | Lisible par tous les utilisateurs de l'app et visible dans le portail développeur ([doc](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)) : contredit « jamais en public » | Données illisibles, métadonnées publiques | Score et identifiant de joueur ; l'ami doit accepter le partage de sa liste ([doc](https://developer.apple.com/documentation/gamekit/connecting-players-with-their-friends-in-your-game)) |
| Réseau coupé | Plus de lecture ni d'écriture | idem | Classement indisponible |

### Tableau 3 : serveurs tiers
| Critère | 4. Firebase | 5. Supabase |
|---|---|---|
| Temps (estimation) | 8 à 12 h : SDK, console, clé Apple, règles | 8 à 12 h : SQL et règles d'accès |
| Coût | Firestore gratuit (1 GiB, 50 000 lectures/jour : [quotas](https://firebase.google.com/docs/firestore/quotas)) mais Cloud Storage exige le plan Blaze, donc une carte bancaire ([Firebase](https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024)) | Gratuit : 500 Mo, 1 Go de fichiers, 50 000 utilisateurs ; projet mis en pause après 1 semaine sans activité ; Pro 25 $/mois ([tarifs](https://supabase.com/pricing)) |
| Compte | Oui : Sign in with Apple via Firebase Auth ([doc](https://firebase.google.com/docs/auth/ios/apple)) | Oui, ou connexion anonyme ([tarifs](https://supabase.com/pricing)) |
| Démo 2 iPhones | Oui | Oui, si le projet n'est pas en pause |
| App Store | 1.2 complet ; 5.1.1(v) suppression de compte dans l'app, avec révocation du jeton Apple ([doc](https://firebase.google.com/docs/auth/ios/apple)) | 1.2 complet ; 5.1.1(v) idem |
| Moins de 13 ans | Pas d'analytique tiers pour les apps d'enfants ([1.3 et 5.1.4](https://developer.apple.com/app-store/review/guidelines/)) ; Sign in with Apple d'un compte enfant [?] | idem |
| Ce qui sort | Photos, espèces, zone vers Google ; nous pouvons tout lire ; une règle mal écrite expose tout | Tout vers Supabase ; un serveur de plus à surveiller |
| Réseau coupé | Cache hors ligne de Firestore [?] | Rien sans réseau |

### Tableau 4 : sans serveur, de téléphone à téléphone
| Critère | 7. Fichier `.pescedex` | 10. Multipeer Connectivity |
|---|---|---|
| Temps (estimation) | 3 à 5 h : `Transferable` + type de fichier ([doc](https://developer.apple.com/documentation/coretransferable/filerepresentation)) | 5 à 8 h ([doc](https://developer.apple.com/documentation/multipeerconnectivity)) |
| Coût / compte | 0 € ; aucun compte | 0 € ; aucun compte |
| Démo 2 iPhones | Oui, mais instantané figé : renvoyer à chaque nouvelle carte. AirDrop demande Wi-Fi et Bluetooth ([Apple](https://support.apple.com/en-us/119857)) | Oui si les deux apps sont ouvertes côte à côte |
| App Store | Pas de service hébergé ; 1.2 minimal [?] | idem [?] |
| Moins de 13 ans | Réglages parentaux de Messages et AirDrop [?] | Permission « réseau local » à accepter [?] |
| Ce qui sort | Ce que l'expéditeur choisit ; le fichier peut être retransmis, donc pas de vrai « amis invités seulement » | Direct entre les deux iPhones |
| Réseau coupé | AirDrop sans internet : la page Apple ne l'exige pas [?] | Prévu sans point d'accès : Wi-Fi pair à pair et Bluetooth ([doc](https://developer.apple.com/documentation/multipeerconnectivity)) |

### Tableau 5 : messages et appels
| Critère | 8. Extension iMessage | 9. SharePlay |
|---|---|---|
| Temps (estimation) | 8 à 12 h : nouvelle cible ([doc](https://developer.apple.com/documentation/messages/msmessage)) | 6 à 10 h ([doc](https://developer.apple.com/documentation/groupactivities)) |
| Coût / compte | 0 € ; iMessage | 0 € ; FaceTime, Messages ou AirDrop ([notes WWDC23](https://wwdcnotes.com/documentation/wwdc23-10239-add-shareplay-to-your-app)) |
| Démo 2 iPhones | Oui, une carte par message, sans page « collection » | Oui, mais seulement pendant la session |
| App Store | Contenu envoyé à des destinataires choisis [?] | Rien de conservé |
| Moins de 13 ans | Limites de communication des comptes enfants [?] | idem [?] |
| Ce qui sort | Le message va aux destinataires choisis | Les données vont aux participants de l'appel |
| Réseau coupé | Message en attente | Session impossible |

## Mise en place de l'option 1
### Portail Apple et Xcode (une fois)
1. Il faut l'équipe payante de MWM : une équipe gratuite « Personal Team » n'a pas iCloud ([réponse Apple](https://developer.apple.com/forums/thread/811929)). Sans accès MWM avant jeudi, personne ne peut tester CloudKit.
2. MWM ajoute les trois étudiants avec accès à « Certificates, Identifiers & Profiles », qui inclut la console CloudKit ([rôles](https://developer.apple.com/help/account/manage-your-team/roles/)). Les deux Mac se connectent à Xcode avec ces comptes. [?] Le tableau des rôles est illisible dans ma lecture : demander Admin, ou App Manager avec cette permission.
3. Figer le bundle ID (l'identifiant unique de l'app) avant de créer le conteneur (le compartiment iCloud de l'app) : l'un détermine le nom de l'autre ([doc](https://developer.apple.com/documentation/cloudkit/enabling-cloudkit-in-your-app)).
4. Xcode, cible, Signing & Capabilities : équipe MWM, signature automatique, `+ Capability` iCloud, cocher CloudKit, bouton `+` pour créer `iCloud.<bundle ID>`. Xcode l'enregistre chez MWM et ajoute Push Notifications ([doc](https://developer.apple.com/documentation/xcode/configuring-icloud-services)).
5. `Info.plist` : `CKSharingSupported` = YES, sinon le lien d'invitation n'ouvre pas l'app ([doc](https://developer.apple.com/documentation/bundleresources/information-property-list/cksharingsupported)).
### Schéma des données partagées
| Élément | Contenu |
|---|---|
| Zone | `Pescedex`, un dossier personnalisé de la base privée du pêcheur, une seule `CKShare` pour toute la zone, un participant par ami, 100 au plus ([doc](https://developer.apple.com/documentation/cloudkit/shared-records), [limite](https://developer.apple.com/documentation/cloudkit/ckshare)) |
| Type `Carte` | `cardID`, `espece` (code de la liste fermée), `rarete`, `datePrise`, `taille`, `bredouille` (0/1), `zone` (département, ex. « 94 »), `image` (`CKAsset` : fichier joint à l'enregistrement, PNG détouré sans GPS) |
| Jamais écrit | coordonnées exactes, nom du coin, texte libre, pseudo saisi. Si Adem veut une position, arrondie à 0,1° (environ 11 km, estimation) |
| Nom de l'ami | celui de son compte Apple (`CKShare.Participant`) : aucun texte saisi, donc rien à filtrer |
| Cache de l'ami | table SwiftData `AmiCarte` + images sur disque, pour lire hors ligne |
Réciprocité : un partage va dans un seul sens. Après avoir accepté, l'app propose « Inviter en retour » en un toucher, pour que chacun voie l'autre.
### API exactes
- État iCloud : `accountStatus()` ([doc](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)).
- Zone et cartes : `modifyRecordZones(saving:deleting:)` ([doc](https://developer.apple.com/documentation/cloudkit/ckdatabase/allrecordzones())), puis `modifyRecords` sur `privateCloudDatabase` ([CKContainer](https://developer.apple.com/documentation/cloudkit/ckcontainer)).
- Partage : `CKShare(recordZoneID:)`, `publicPermission = .none` ([CKShare](https://developer.apple.com/documentation/cloudkit/ckshare)) ; options lecture seule et destinataires précis via `CKAllowedSharingOptions` ([doc](https://developer.apple.com/documentation/cloudkit/ckallowedsharingoptions)) [?] noms exacts des options à vérifier dans Xcode.
- Invitation en SwiftUI : `ShareLink` + `CKShareTransferRepresentation`, cas `.prepareShare(container:allowedSharingOptions:preparationHandler:)` ([doc](https://developer.apple.com/documentation/cloudkit/cksharetransferrepresentation/exportedshare)). `UICloudSharingController(preparationHandler:)` est déprécié depuis iOS 17 ([doc](https://developer.apple.com/documentation/uikit/uicloudsharingcontroller/init(preparationhandler:))).
- Acceptation : `windowScene(_:userDidAcceptCloudKitShareWith:)` puis `CKContainer.accept(_:)` en async ([doc](https://developer.apple.com/documentation/cloudkit/ckcontainer)). En SwiftUI, un développeur signale qu'il faut un adaptateur de delegate qui désigne la classe de scène ([retour](https://medium.com/%40manojisnow/how-i-got-cloudkit-sharing-right-by-not-touching-my-real-app-557f0c5b527a)) [?].
- Lecture chez l'ami : `sharedCloudDatabase.allRecordZones()` puis `recordZoneChanges(inZoneWith:since:)`, avec le jeton de changement sauvegardé (un marque-page qui évite de tout retélécharger : [doc](https://developer.apple.com/documentation/cloudkit/ckdatabase/recordzonechanges(inzonewith:since:desiredkeys:resultslimit:))). Préférer cela aux requêtes `CKQuery`, qui demandent des index à déployer [?].
- Alertes : `CKDatabaseSubscription` sur la base partagée ([doc](https://developer.apple.com/documentation/cloudkit/shared-records)), avec la capacité Background Modes, case Remote notifications ([doc](https://developer.apple.com/documentation/cloudkit/cksyncengine)). Prévoir aussi un bouton « Actualiser », les notifications ne se testent pas bien au simulateur [?].
- Bloquer ou quitter : le propriétaire appelle `removeParticipant(_:)` ; un participant qui supprime le partage en sort seulement lui ([doc](https://developer.apple.com/documentation/cloudkit/ckshare)). « Supprimer mes cartes partagées » = supprimer la zone.
- Pas `CKSyncEngine` au départ : il rejoue les envois hors ligne mais demande de sauvegarder son état ([doc](https://developer.apple.com/documentation/cloudkit/cksyncengine)). Avis, non mesuré.
### Mise en production
Les builds lancés depuis Xcode utilisent l'environnement Development, TestFlight et l'App Store utilisent Production ([doc](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema)). Avant le premier build TestFlight : console CloudKit, « Deploy Schema Changes » vers Production. Les deux iPhones de test doivent avoir le même type de build.
### Test E8 (deux iPhones, deux comptes iCloud différents)
1. A et B : même build, connectés à deux comptes iCloud distincts, iOS 27.
2. A crée une carte (E6), ouvre « Inviter un ami », envoie le lien à B par Messages.
3. B touche le lien : l'app s'ouvre sur « Pescedex de A » avec la carte. A crée une 2e carte, B actualise et la voit.
4. Preuve sans coordonnées : test unitaire sur la fabrique de `CKRecord` (seules les clés autorisées existent), plus `exiftool -gps:all carte.png` qui n'affiche rien. Commande à écrire : `xcodebuild test -scheme <Scheme> -destination 'platform=iOS Simulator,name=<iPhone>' -only-testing:<Cible>/CarteRecordTests`.
5. Essai en mode avion sur A, puis retour du réseau : la carte arrive chez B (à coder).

## Plan de repli si l'option 1 bloque jeudi soir
Arrêt : un seul test, une carte de A vers B avec deux comptes iCloud. S'il échoue jeudi soir, on bascule sur l'option 7, sans nouvelle tentative.
1. Dès le début, écrire la structure `CartePartagee` (champs autorisés seulement). Elle sert à CloudKit et au fichier : le repli ne coûte pas de refonte.
2. Repli : export en `.pescedex` (JSON + PNG) par `ShareLink`, import par `onOpenURL`, section « Amis » en lecture seule. Ce repli satisfait le test E8 tel qu'il est écrit (A envoie, B voit), sans mise à jour automatique.
3. Si le fichier bloque aussi : retirer E8 de la démo et garder le partage d'une carte en image, déjà prévu dans `kickoff/reports/faisa-tech.md`. Aucune fausse donnée d'ami.
4. Démo sans réseau : l'option 10 peut servir de plan C dans la salle [?] non estimée en détail.

## Recommandation
Option 1 : CloudKit, zone partagée par `CKShare`, SwiftData gardé en local. Elle seule répond aux quatre contraintes d'Adem à la fois : aucun serveur à nous, aucun compte à créer, des données que nous ne pouvons pas lire, et une lecture réservée aux amis invités. Un autre LLM la proposerait avec 65 % de chances (estimation) : je l'ai gardée parce qu'elle passe ces quatre contraintes, que les options rares (6, 8, 9, 10, 11) ne passent pas.
Option la plus forte écartée : Firebase. Elle est la mieux documentée, mais elle ajoute un serveur tiers, un compte, une suppression de compte à coder et une carte bancaire pour les photos. Meilleur repli : l'option 7, fichier `.pescedex`.
À transmettre à l'agent appstore : signalement par e-mail, blocage par retrait du participant, contact publié, aucun texte libre ; politique de confidentialité ([5.1.4](https://developer.apple.com/app-store/review/guidelines/)). Le questionnaire d'âge distingue « contenu d'utilisateurs » (large diffusion) et « réseaux sociaux » (fil visible par beaucoup) ([définitions](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions)) : un partage entre amis invités n'est ni l'un ni l'autre à mon avis [?]. Moins de 13 ans, point ouvert, non bloquant jeudi : `requestAgeRange` donne la tranche d'âge de la personne connectée à l'appareil ([doc](https://developer.apple.com/documentation/declaredagerange/agerangeservice)), donc un enfant sur le compte d'un parent reste invisible. Ma recommandation par défaut : partage ouvert à tous, puisqu'il n'y a ni texte libre ni contenu public, avec politique de confidentialité ; à faire valider par MWM [?] avis juridique non cherché.

Contexte des questions : sans équipe payante, CloudKit ne se teste pas ; et un lien de partage peut être restreint aux invités ou ouvert à qui l'a.
1. Qui ouvre l'accès à l'équipe MWM, et quand ?
   a. MWM ajoute les trois étudiants avant jeudi (ma recommandation).
   b. Un des trois a un compte développeur payant : on prototype dessus, on change de conteneur jeudi.
   c. Aucun des deux : on commence par l'option 7 et on tente CloudKit après.
   Par défaut si pas de réponse : a, à demander à MWM.
2. Mode du lien d'invitation ?
   a. Seulement les personnes invitées, ajoutées par e-mail ou numéro (ma recommandation, plus proche de « jamais en public »).
   b. Quiconque a le lien, en lecture seule (un seul lien, mais il peut être retransmis).
   Avec a, un tiers qui touche le lien voit « indisponible » ([retour d'un développeur](https://medium.com/%40manojisnow/how-i-got-cloudkit-sharing-right-by-not-touching-my-real-app-557f0c5b527a)). Par défaut : a.
