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
| N6 (suite, branche `lot/racine-carte`, délégation de Titouan pour `App/Carte/` et `App/Session/`) | `CalqueReperes` dans la `Map` de `VueCarte`, derrière la clé `InterrupteurCalqueReperes.cle` (éteint par défaut) ; 5e rangée « Repères » de `ColonneBoutonsCarte` (libellé, valeur « activé » / « désactivé ») ; appui long (0,6 s) sur la carte = `NouveauRepereView(position:)`, geste à part du toucher qui pose le cercle (ni le spot ni la caméra ne bougent), refusé si la carte est dézoomée, pendant « Choisir un autre spot » ou si le doigt a glissé de plus de 12 pt ; toucher une épingle = `FicheRepereView` (feuille, deux hauteurs) ; repères masqués au-dessus de 2,5 degrés de latitude (`CalqueReperes.visible`) et HORS du plafond de 60 (`Regroupeur` ne les voit pas : `ReperesSurCarte.visibles`, 300 au plus, zone visible seulement) ; icône de l'interrupteur et du calque = `signpost.right` (« Ma zone » garde `mappin.and.ellipse`) ; « Y aller » = le flux de la fiche N6 (`AllerAuRepere`, Plans sans question, Waze et Google Maps après confirmation, rien mémorisé, `DecisionYAller` jamais utilisé) ; « Mon spot » : rangée « Mes repères » = `ListeReperesView` ; « Règles ici » = `ReglesDuSpotView` sur la coordonnée (lieu flou affiché), via `ContexteReperes.brancherReglesIci` posé par `VueCarte` quand elle est à l'écran | `VueCarte`, `CommandesCarte`, `MonSpotView`, `ReperesSurCarte`, `ContexteReperes` |
| N6 (session) | bouton « Ajouter un repère ici » dans le bandeau de session et sous « Ajouter une prise » dans l'écran de session (position de l'iPhone, sinon « Mes repères » pour choisir le point sur la carte) ; après une prise, « Rattacher au repère X ? » (`RepereProche.plusProche` sur la position de l'iPhone, jamais le centre du spot, puis `ModeleReperes.rattacher` seulement après un toucher) | `BandeauSessionView`, `SessionEnCoursView`, `RattachementRepere`, `ParcoursApp.ajouterRepereIci`, `repondreRattachement` |
| N6 / N1 (paywall) | `DeclencheurPaywall.reperes` (4e repère) et `.decors` (décor Pro de l'aquarium), mesure `reperes` / `decors`, ligne de liste Pro et texte dans `TextesPaywall`, bouton « Pas maintenant » ; `ContexteReperes.configurer(ouvrirPaywall:)` ouvre `.reperes` ; `NouveauRepereView` présente le paywall elle-même (`vuePaywall`) parce qu'une feuille déjà ouverte ne laisse pas la racine en ouvrir une autre | `CoucheMesure.swift`, `TextesPaywall.swift`, `RootView`, `NouveauRepereView` |
| N3 (croisé) | `MesuresSourceesView(enFeuille: true)` dans « Conditions du jour » (paramètre `mesures: AnyView?` de `ConditionsDuJourView`), détents `.medium`/`.large`, défilement sans indicateur ; ligne « hPa » retirée de `RangeeMaintenantView` | `App/Conditions/`, `MesuresEmplacement` |
| N5 (croisé) | lien « Comment mesurer ? » (feuille `MesureGuideView`) sous le curseur de taille de l'ajout manuel ; « Ma fédération » est bien dans le profil (`ProfilEmplacement`) | `App/Collection/AjoutManuelPriseView.swift` |
| L24 (croisé) | `BoutonEcrire` + `FeuilleConversationView` sur la page d'un ami (icône dans la barre de `PescedexAmiView`) et d'un club (sous « Membres ») ; `RelaisChat` : `SceneDuPartage.acheminer` envoie un partage dont `InvitationChat.estUneConversation` est vrai à `RelaisChat`, `RootView` appelle `app.chat.accepter(...)` puis ouvre les messages ; jamais par `RelaisInvitations` | `App/Chat/RelaisChat.swift`, `App/Amis/RelaisInvitations.swift`, `RootView.onglets` |
| N2 (croisé) | `lot/envies-accroches` fusionnée ; `PescedexView(..., envies: app.envies)` ; `ProfilLocal.lire()/ecrire()` lisent et écrivent les envies (`envies.json`, URL partagée `ProfilLocal.fichierEnvies`) ; `EnviesModele.relire()` après chaque synchro (`SauvegardeAvecReperes.apresProfil`) | `RootView`, `App/Compte/ProfilLocal.swift` |
| docs | lots N1 à N6 ajoutés à `docs/lots.md` (`scripts/lot.sh` les lit dans ce tableau, rien à changer dans le script) ; `lots.py verifier` : 21 lots, 0 trou | docs/lots.md |

## Pas branché, et pourquoi
Ces points demandent d'écrire dans un dossier qui n'est pas à L25. Chaque ligne dit quoi y mettre.

| Quoi | Où | Pourquoi / quoi faire |
|---|---|---|
| N3 : ligne « Eau » | `stations-temperature.json` | le fichier est produit par `outils/hubeau/stations_temperature.py` (lot D2B, branche `lot/hubeau-temperature`, 872 stations dont 24 en service sur 30 jours) : l'ajouter aux ressources de l'app et à `donnees.sh`, le code le cherche dans le bundle ; sans lui, pression et débit seulement. Mention à mettre dans les crédits : « Données : Hub'Eau / Naïades, Licence Ouverte (Etalab) » |
| L18 : `regionDe:` de `PescedexModele` (« Ma région » est grisé) | `RootView.init`, ligne `PescedexModele(depot:services:)` | table prête dans Core (`RegionsFrance.region(deDepartement:)`), à brancher avec le Pescedex pour éviter un conflit avec l'autre agent |
| L23 : bouton « Publier » depuis une carte du Pescedex | `App/Collection/` | Pescedex |
| L22 : chat de club, membres sans `idCloudKit` | | listés avec un identifiant vide : pas admissibles dans la zone du chat |
| L19 : `BlocReglesView` dans `App/Style/BlocRegles/` | | à vérifier avec `scripts/verif.sh` (frontières) |
| Commentaire périmé dans `App/Club/ModelesClub.swift` ligne 118 (« L23 a sa propre liste ») | `App/Club/` | faux depuis l'alignement ; à effacer par L22 |

## Câblage N6 dans la carte et la session : à vérifier au build
- `appuiLongPourReperer` : `LongPressGesture.sequenced(before: DragGesture)` avec `including: .all` posé à côté de `toucherPourPoser` ; vérifier sur iPhone qu'il ne bloque ni le glissement ni le pincement de `Map`, que le toucher d'une épingle ne déclenche pas aussi l'appui long, et que le motif `case .second(true, let doigt?)` compile.
- `CalqueReperes` dans `contenuCarte` (`if` dans `@MapContentBuilder`) ; le calque lit `ModeleReperes.partage.reperes` et `modele.regionVisible` (suivi d'observation à confirmer ; la région n'est mise à jour qu'à la fin d'un mouvement).
- Les feuilles des repères sont des feuilles système (`.sheet`), pas le `PanneauRedimensionnable` de l'accroche 4 : la mention légale de Plans n'est pas réservée. À revoir si Adem tient aux trois hauteurs.
- « Règles ici » ferme d'abord la fiche ou la liste puis ouvre `ReglesDuSpotView` 0,5 s plus tard (une feuille ne peut pas en ouvrir une autre) : la fiche du repère n'est pas rouverte ensuite.
- `ContexteReperes.vuePaywall` : le paywall est présenté dans la feuille « Nouveau repère » ; `PaywallVue` hors racine (même `app.paywall(...)` que les autres emplacements). `ouvrirPaywall` reste le repli.
- Colonne de droite à 5 boutons : hauteur, AX5 et 44 pt à re-mesurer ; bandeau de session à trois boutons en AX5 ; écran de session avec le bouton « Ajouter un repère ici » (le chrono est positionné depuis le haut, le bouton ajoute 44 pt en bas).
- `Modal.nouveauRepere(Coordonnee)` garde la coordonnée en mémoire dans la file d'attente des feuilles, jamais sur disque ni dans un journal.
- Pas de photo du repère dans `PrisesDuPecheurCarte`, rien de nouveau dans `CacheCarte` ni dans le lieu flou : à relire au build.

## N1 : décor sur le widget (branché, écrit sans Mac, jamais compilé ni testé sur iPhone)
- `InstantaneAquarium.skin: String?` (absent = `riviere`, `skinEffectif`) ; `publierAquarium()` envoie `skinAffiche().valeur` (repli saison finie / Pro perdu) et le pont recharge la timeline ; `auChangement` de la galerie rappelle déjà `publierAquarium()`.
- `WidgetAquarium/FondWidget.swift` (pur, aussi copié dans `lancer-tests*.sh`) : `fond-<skin>-<petit|moyen|grand>`, repli `fond-<format>` si l'image manque dans `FondsWidget.xcassets`. Tests : `AppTests/WidgetAquarium/FondWidgetTests.swift`.
- Xcode : ajouter `FondWidget.swift` aux cibles app ET widget si les groupes ne sont pas synchronisés (comme `InstantaneAquarium.swift`) ; `FondWidgetTests.swift` à la cible de tests. Les images `fond-<skin>-<format>` des décors sont à poser dans `FondsWidget.xcassets` (sans elles le widget garde le fond d'origine).
- À vérifier sur Mac : `UIImage(named:)` dans l'extension trouve bien `FondsWidget.xcassets` ; changer de décor change le widget en moins d'une minute ; fin du Pro = retour du widget au décor gagné.

## À faire à la main dans Xcode (pas de .xcodeproj touché ici)
1. Capacités de la cible app : iCloud (CloudKit, conteneur `iCloud.ai.mwm.build.challenge.team.01`, déjà dans le fichier) et Push Notifications (le fichier `BuildChallenge.entitlements` a maintenant `aps-environment`). Background Modes : cocher « Remote notifications » (la clé est dans l'Info.plist). Plan B : les variantes de `Config/planb/` n'ont pas `aps-environment`, c'est voulu (compte gratuit).
2. Dossiers : les dossiers de `App/` sont synchronisés, donc `App/Envies`, `Records`, `MaFederation`, `Reperes`, `Aquarium/Skins` sont pris tout seuls ; vérifier qu'aucun n'est dans une liste d'exceptions. Les tests `AppTests/…` et `AppUITests/…` de chaque dossier vont dans leurs cibles. Retirer la ligne `AstuceAjouterWidget.swift` de l'exception « WidgetAquarium » (project.pbxproj ligne 65) : le fichier n'existe plus.
3. `PrivacyInfo.xcprivacy` : y mettre les lignes de `store/app-privacy.md` (S2) : identifiant utilisateur (surnom), contenu utilisateur (photos, vidéos, messages), position approximative non, coordonnées de repères dans l'iCloud privé de la personne (à décider, voir ci-dessous).
4. CloudKit, tableau de bord (développement puis production). Base publique : `Signalement`, `Club`, `Membre`, `CartePartageeClub`, ainsi que `ProfilPublic`, `Publication`, `Commentaire`, `Like` de L21 et L23. Base privée (zone `Reperes`) : `Repere` et `PhotoRepere`. Index : `creeLe` interrogeable ET triable (Publication, Commentaire), `surnomNorm` interrogeable (début de mot), champ système `createdBy`, `recordName` interrogeable sur `ProfilPublic`, `MessageAmi` et `MessageClub`. Lecture de `Signalement` réservée à l'équipe. Déployer en production. Schéma complet : `docs/reports/reseau/schema.md` (lignes 28 et 39 à corriger pour `creeLe`).
5. Lancer `scripts/verif.sh`, compiler, puis dans l'ordre : fil (L23), chat (L24, deux iPhones), clubs (L22), profil, repères, décors.

## À vérifier au premier BUILD
- Croisé (cette branche) : `ConditionsDuJourView` (`ScrollView` + `AnyView`, détents conditionnels) ; `FeuilleConversationView` dans `.sheet(item:)` depuis un `fullScreenCover` (ami) ; `MainActor.assumeIsolated` dans `SceneDuPartage.acheminer` ; `.onChange(of: RelaisChat.partage.enAttente != nil, initial: true)` (lecture d'un `@Observable` statique dans le corps) ; `apresProfil` capturant `[weak self]` dans une fermeture `@Sendable` ; `ProfilLocal` écrit `envies.json` hors de `EnviesModele` (relu juste après). Aucun test d'app ajouté (ProfilLocal touche UserDefaults et le disque réels).
- Pas de ligne « Mes envies » grisée : la ligne n'apparaît qu'à partir d'une envie (voulu par N2).
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
