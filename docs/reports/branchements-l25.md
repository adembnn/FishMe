# Branchements de la racine (L25), lot « Racine et projet »

Branche `lot/racine`. Tout est écrit SANS Mac ni Xcode : rien n'est compilé ni testé (`// ⚠ à vérifier` dans le code). Les appels viennent de signatures lues dans les dossiers des lots ; en cas de doute, rien n'a été câblé et la ligne est dans « Pas branché ».

## Branché (RootView.swift, BuildChallengeApp.swift, Config/)
| Lot | Branchement | Où |
|---|---|---|
| Fusion | `lot/carte-2` (L17) et `lot/club-2` (L22) fusionnés sans conflit | commits de fusion |
| Alignements | `EffaceurFeed` et `EffaceurChat` adoptent `EffaceurContenu`, `MotifSignalementMessage` et `MotifSignalementPublication` sont des `typealias` de `MotifSignalement`, `bloques()` lit `ListeBlocages.partage.profilsCaches()` : déjà présents dans la base fusionnée (commit « sim: alignements L21 »), rien à refaire ; motifs « harcelement » et « haine » : une seule liste (L21) | App/Chat, App/Communaute |
| L16 | plus de feuille de consentement au premier lancement ; astuce widget retirée (appel et fichier `WidgetAquarium/AstuceAjouterWidget.swift`) ; `departement:` et `rarete:` passés au tunnel | `proposerSuitePremierLancement`, `vue(de:)` |
| L17 | `ReglageNavigationView` dans le profil (rangée « Y aller avec ») ; `prisesDuPecheur:` donné à `VueCarte` (prises du dépôt et photos sans GPS) ; `LSApplicationQueriesSchemes` = `waze`, `comgooglemaps` | `ProfilEmplacement`, `ParcoursApp.prisesPourLaCarte`, Info.plist |
| L18 | « Déclarer » écrit la carte et ouvre la grille de L18 (plus le tunnel) | `declarerEspece` |
| L21 | surnom seul (plus de `profil.nom`), « Finis ton profil » (feuille et `.finisTonProfil()`), `fishme://ami/<id>` | `ProfilEmplacement`, `ouvrir(url:)` |
| L22 | `fishme://club/<id>` ; clubs lus par le fil (`mesClubs`) et le chat (`clubs()`, table de `ClubPourChat.swift`) ; `EffaceurClubs` dans le registre | `ouvrir(url:)`, `InstantaneRacine`, `enregistrerEffaceurs` |
| L23 | page principale de Communauté = le fil (`FeedVue`) avec `SourceFeedRacine` | `club` |
| L24 | `ListeConversationsView` (bouton Messages), `AnnuaireChatRacine`, notifications CloudKit silencieuses : délégué `AdaptateurFishMe` (remplace `AdaptateurPartage` dans `BuildChallengeApp`, garde sa scène pour les invitations), `registerForRemoteNotifications()` sans fenêtre, pont `RelaisNotificationsChat`, `aps-environment` = `development`, `UIBackgroundModes` = `remote-notification` | `BuildChallengeApp.swift`, Config/ |
| Effacement | `RegistreEffaceurs` : feed, chat, clubs (le profil s'efface lui-même dans `GestionProfil.supprimer`) | `enregistrerEffaceurs` |
| Mode démo | clé `demo.communaute` : fil et messages d'exemple, lecture seule | `modeDemo`, `chat` |
| N1 | décors : bouton « Décors » sur l'aquarium, `SkinsGalerieView`, décor passé à `AquariumView` ; départ rivière (0 espèce), étang (5), grotte (un légendaire) : déjà dans le catalogue de Core | `aquariumView(modele:skin:fermer:)` |
| N2 | `EnviesModele` créé et câblé (règles du spot, conseil d'appât, choix du spot) ; une espèce qui reçoit une carte sort de la liste à chaque rafraîchissement | `ParcoursApp.envies` |
| N3 | `MesuresSourceesView` sous la rangée « maintenant » de la fiche d'un coin ; `ModeleMesures` (Hub'Eau température) | `MesuresEmplacement`, `ParcoursApp.mesuresEau` |
| N4 | « Mes records » dans le profil ; bandeau « nouveau souvenir » sur la carte révélée, `MoteurRecords.evenement` appelé avec les cartes d'avant l'insertion | `MesRecordsEmplacement`, `annonceRecord` |
| N5 | « Ma fédération » (liens, carte de pêche, numéros utiles) dans le profil | `ProfilEmplacement` |
| N6 | `ContexteReperes.courant.configurer(...)` et `abonne` au lancement et à chaque changement d'abonnement ; repères chargés ; « Mes repères » (`ListeReperesView`) dans le profil ; `SauvegardeReperes.synchroniser()` avec la sauvegarde des cartes (un échec n'arrête pas celle des cartes) et `effacerTout()` à « Effacer mes données iCloud » ; 3 repères gratuits (`ReglesReperes`) | `SauvegardeAvecReperes`, `configurerReperes` |
| docs | lots N1 à N6 ajoutés à `docs/lots.md` (`scripts/lot.sh` les lit dans ce tableau, rien à changer dans le script) ; `lots.py verifier` : 21 lots, 0 trou | docs/lots.md |

## Pas branché, et pourquoi
Ces points demandent d'écrire dans un dossier qui n'est pas à L25. Chaque ligne dit quoi y mettre.

| Quoi | Où | Pourquoi / quoi faire |
|---|---|---|
| N6 : calque des repères sur la carte, interrupteur (5e rangée de `ColonneBoutonsCarte`, changer l'icône `mappin.and.ellipse` déjà prise par « Ma zone »), appui long qui ouvre `NouveauRepereView(position:)`, fiche d'un repère en 3 hauteurs | `App/Carte/` | dossier de L17. Les repères sortent du plafond de 60 : soustraire leur nombre visible de `Regroupeur.maximum` (ModelesCarte.swift:156). Jamais dans `PrisesDuPecheurCarte`, `CacheCarte` ni le lieu flou |
| N6 : « Y aller » vers un repère sans « Toujours utiliser » | `App/Carte/` (`DecisionYAller`) | la règle de N6 (`AllerAuRepere`) ne mémorise rien et n'utilise pas `PreferenceItineraire` (vérifié par grep) ; ne jamais brancher un repère sur `DecisionYAller` |
| N6 : « Ajouter un repère ici » en session, rattachement à une prise (`RepereProche.plusProche`) | `App/Session/` | autre lot |
| N6 : déclencheur de paywall propre aux repères | `App/Mesure/CoucheMesure.swift` (`DeclencheurPaywall`) | pour l'instant `.paywall(.widget)` (comme les décors N1) : la mesure d'usage dira « widget ». Ajouter `case reperes` et son texte dans `TextesPaywall.swift` |
| N3 : le même bloc dans la feuille « Conditions du jour » | `App/Conditions/ConditionsDuJourView.swift` | `enFeuille: true`, détent à revoir |
| N3 : ligne « Eau » | `stations-temperature.json` | le fichier n'existe pas (D2 doit le fournir) : l'ajouter aux ressources de l'app, le code le cherche dans le bundle ; sans lui, pression et débit seulement. Déclarer le fichier dans `donnees.sh` |
| N2 : ligne « Mes envies » du Pescedex, bouton sur les fiches, menu contextuel | `App/Collection/` | Pescedex traité par un autre agent. Le modèle est prêt : `app.envies`, vue `MesEnviesView(modele: app.envies, cartes: ..., ouvrirFiche: ...)` |
| N2 : liste d'envies dans la sauvegarde iCloud | `App/Compte/` | non livré par N2 ; la liste est locale (`envies.json`). Date de réouverture : Core ne l'expose pas, « Fermée ce jour » |
| N5 : `MesureGuideView` (geste de mesure) | `App/Prise/` | aucun appel : la source du geste n'est pas connue, texte provisoire |
| N1 : décor sur le widget | `WidgetAquarium/` | `publierAquarium` n'envoie pas le décor |
| L18 : `regionDe:` de `PescedexModele` (« Ma région » est grisé) | `RootView.init`, ligne `PescedexModele(depot:services:)` | table prête dans Core (`RegionsFrance.region(deDepartement:)`), à brancher avec le Pescedex pour éviter un conflit avec l'autre agent |
| L23 : bouton « Publier » depuis une carte du Pescedex | `App/Collection/` | Pescedex |
| L24 : « Écrire » (`BoutonEcrire`, `ConversationView`) sur les pages ami et club ; routage des liens de conversation vers `GestionChat.accepter(...)` dans `RelaisInvitations` | `App/Amis/`, `App/Club/` | dossiers de L21 et L22 |
| L22 : chat de club, membres sans `idCloudKit` | | listés avec un identifiant vide : pas admissibles dans la zone du chat |
| L19 : `BlocReglesView` dans `App/Style/BlocRegles/` | | à vérifier avec `scripts/verif.sh` (frontières) |
| Commentaire périmé dans `App/Club/ModelesClub.swift` ligne 118 (« L23 a sa propre liste ») | `App/Club/` | faux depuis l'alignement ; à effacer par L22 |

## À faire à la main dans Xcode (pas de .xcodeproj touché ici)
1. Capacités de la cible app : iCloud (CloudKit, conteneur `iCloud.ai.mwm.build.challenge.team.01`, déjà dans le fichier) et Push Notifications (le fichier `BuildChallenge.entitlements` a maintenant `aps-environment`). Background Modes : cocher « Remote notifications » (la clé est dans l'Info.plist). Plan B : les variantes de `Config/planb/` n'ont pas `aps-environment`, c'est voulu (compte gratuit).
2. Dossiers : les dossiers de `App/` sont synchronisés, donc `App/Envies`, `Records`, `MaFederation`, `Reperes`, `Aquarium/Skins` sont pris tout seuls ; vérifier qu'aucun n'est dans une liste d'exceptions. Les tests `AppTests/…` et `AppUITests/…` de chaque dossier vont dans leurs cibles. Retirer la ligne `AstuceAjouterWidget.swift` de l'exception « WidgetAquarium » (project.pbxproj ligne 65) : le fichier n'existe plus.
3. `PrivacyInfo.xcprivacy` : y mettre les lignes de `store/app-privacy.md` (S2) : identifiant utilisateur (surnom), contenu utilisateur (photos, vidéos, messages), position approximative non, coordonnées de repères dans l'iCloud privé de la personne (à décider, voir ci-dessous).
4. CloudKit, tableau de bord (développement puis production). Base publique : `Signalement`, `Club`, `Membre`, `CartePartageeClub`, ainsi que `ProfilPublic`, `Publication`, `Commentaire`, `Like` de L21 et L23. Base privée (zone `Reperes`) : `Repere` et `PhotoRepere`. Index : `creeLe` interrogeable ET triable (Publication, Commentaire), `surnomNorm` interrogeable (début de mot), champ système `createdBy`, `recordName` interrogeable sur `ProfilPublic`, `MessageAmi` et `MessageClub`. Lecture de `Signalement` réservée à l'équipe. Déployer en production. Schéma complet : `docs/reports/reseau/schema.md` (lignes 28 et 39 à corriger pour `creeLe`).
5. Lancer `scripts/verif.sh`, compiler, puis dans l'ordre : fil (L23), chat (L24, deux iPhones), clubs (L22), profil, repères, décors.

## À vérifier au premier BUILD
- `AdaptateurFishMe` : signature async de `didReceiveRemoteNotification`, isolation `@MainActor`, `UIApplicationDelegateAdaptor`. `AdaptateurPartage` n'est plus utilisé (la scène `SceneDuPartage` oui).
- `SauvegardeAvecReperes` (struct `nonisolated` qui tient deux acteurs), `ParcoursApp.sauvegarde` devenu `(any ServiceSauvegarde)?`.
- `ContexteReperes.configurer` : fermeture `prises:` lue sur le fil principal sans `@Sendable` ; `chargeur: .embarque()` ne lit pas les règles téléchargées (`ReglesAJour`), seulement celles du paquet.
- `MesuresEmplacement` : `@ObservedObject` posé dans l'init ; hauteur de la fiche d'un coin avec le bloc en plus.
- `EnviesExternes` (initialiseur par défaut avec les quatre fermetures) ; `PrisesDuPecheurCarte.photo` lit `dossierPhotos` hors de l'acteur.
- `ReglageNavigationView` dans une `List` (ses marges `Espace.l` sont déjà dans la vue : `listRowInsets` vidé).
- `GestionClubs.partage` est créé à la première lecture de `instantaneRacine()` (hors démo, iCloud actif) : vérifier qu'aucun `CKContainer` n'est ouvert sans compte iCloud.
- Scan des noms en double (`python3 C:\w\scan_dups.py C:\w\l25`) : 18 noms dans plusieurs fichiers, tous dans des types imbriqués ou privés (`Cle`, `Genre`, `Distant`, `Etat`…) ; seuls `Repere` (AppTests/Prise/IdentificationDinoTests contre Core) et `Message` sont à regarder au build.

## Décisions pour Adem
1. Repères dans l'iCloud privé chiffré : appliqué (décision de Titouan). La phrase de `CLAUDE.md` « aucun coin de pêche exact ne quitte l'iPhone » est à réécrire ; `PrivacyInfo` et la fiche App Store à adapter.
2. « Effacer mes données iCloud » efface aussi les repères sur l'iPhone (`effacerTout` supprime le fichier local) : le texte de `CompteView` dit « Tes cartes restent sur cet iPhone ». Le texte est à compléter, ou `SauvegardeReperes.effacerTout` à scinder (iCloud seul).
3. Paywall des repères et des décors : un cas `DeclencheurPaywall` dédié, ou on garde `.widget` ?
4. Ordre de présentation : « Mes repères », « Ma fédération » et « Mes records » sont dans le profil faute d'entrée plus naturelle tant que la carte n'est pas câblée.
5. Âge 15 ans, réseau gratuit, pseudonyme seul : appliqués (un profil existe seulement avec la déclaration 15 ans, aucun nom saisi dans la racine).
