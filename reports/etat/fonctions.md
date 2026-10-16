# État des fonctions de FishMe (16 oct. 2026, lecture seule)

Base : copie de `origin/mac/integration` (db62680, 351 commits, dernier : 16 oct. 04h01). Sources lues : `CLAUDE.md`, `docs/parcours-demo.md`, `docs/lots.md`, `docs/app-store.md`, `/mnt/project-files/tests-utilisateurs.md` (nuit du 15 au 16), le code de `App/`, `Widget/`, `WidgetAquarium/`, `Packages/Core/`, `Config/`. Aucun Swift n'a été compilé ici (pas de Mac) : « vu » veut dire « vu au simulateur d'après le rapport de tests de la nuit », jamais vu par moi.

Légende des statuts : **Vu** = fait et vu au simulateur ; **Codé** = codé mais jamais vu à l'écran ; **Partiel** = il manque un morceau qui change ce que voit le pêcheur ; **Absent** = rien dans la branche.

## Pourcentage d'avancement

| Mesure | Résultat | Comment |
|---|---|---|
| Fonctions de la version soumise (39 lignes du tableau) | **69 %** | Vu = 1, Codé = 0,6, Partiel = 0,4, Absent = 0, chaque ligne pèse pareil. 15 Vu, 13 Codé, 10 Partiel, 1 Absent. |
| Même mesure, mais seul « Vu » compte | 38 % | 15 lignes sur 39 : ce qui est prouvé à l'écran. |
| Conformité pour l'envoi à Apple (24 points, tableau plus bas) | 37 % | 9 points faits sur 24 (textes d'autorisation, manifeste de confidentialité, droits WeatherKit, adresse de contact, etc.). |
| **Avancement honnête vers « soumis à 100 % »** | **environ 62 %** | 0,8 x 69 % + 0,2 x 37 %. La version soumise exclut ce que `CLAUDE.md` met dans la mise à jour (L10 écran verrouillé, L7 coins publics, L8 amis, L11 règles à jour, L14 aquarium) : ces 5 lignes sont dans un tableau à part (en les ajoutant, les fonctions tombent à 67 %). |

Pourquoi pas plus : presque tout est écrit, mais (1) les droits d'Apple manquent (caméra, WeatherKit, confidentialité), donc un iPhone réel planterait ou n'aurait pas la météo ; (2) la moitié des écrans n'ont jamais été regardés ; (3) la palette Marine n'est pas branchée ; (4) le lancement dure 15 à 20 s.

## Branches : ce qui est fusionné dans mac/integration

Fusionnés (0 commit en retard) : squelette, contrats, moteur, données (D1), carte, prise, collection, session, abonnement, club, conditions, conseils, premier-pas, ou-chercher, amis, veille, écran verrouillé, widget-aquarium, atelier.

Travail non fusionné (commits que mac/integration n'a pas) :

| Branche | Commits | Ce que ça apporterait |
|---|---|---|
| `lot/store` | 26 | fiche, notes du relecteur en anglais, check-list, `store/` (S1) |
| `regles/local` | 77 | règles confirmées par le PC d'Adem, jamais fusionnée dans `main` par décision ; D1 les recharge dans `Core/Resources/regles/` |
| `lot/regles-france` | 10 | outils de lecture D3 |
| `lot/hubeau` + `sullyvan/hubeau` + `donnees/hubeau` | 8 + 7 + 1 | outils D2 (hors app) ; les fichiers sont dans la release GitHub `donnees` (elle existe, vérifié) |
| `lot/images-poissons` | 8 | images des espèces manquantes : 13 espèces n'ont aucune image dans `App/Assets.xcassets/Especes` (spirlin, lamproie de Planer, écrevisses à pattes rouges / virile / à taches rouges, grenouilles verte et rousse, hybrides, truite tigre, carpe koï, vandoise rostrée, vandoise du Béarn, rayé hybride) ; c'est la cause des 2 tests rouges « espèce sans image » |
| `lot/style` | 4 | `App/Style/Style.swift` (palette Marine) : absent de mac/integration |
| `sullyvan/aquarium` | 4 | `App/Aquarium/` (1 453 lignes, jamais compilées) |
| `lot/reconnaissance`, `modele/reconnaissance` | 4, 1 | outils et modèle R1 (le modèle DINOv2 v2 à 55 classes est déjà dans `App/Prise/Modele/`) |
| `sullyvan/ou-chercher`, `sullyvan/veille`, `sullyvan/relecture-*`, `sullyvan/store` | 1 à 12 | renommages et relectures, à vérifier avant de les ignorer |

## Tableau principal : version soumise

| Fonction | Statut | Ce qui manque | Qui |
|---|---|---|---|
| E1 Position demandée, carte centrée sur le pêcheur, coins OFB sur toute la France (regroupés, 150 points au plus) (`App/Carte/`) | Vu | rien de bloquant | |
| E1 Position refusée : choix du département ou de la commune, redemande une seule fois (`ChoixDeZoneView`, `GestionPosition`) | Codé | jamais testé en refus ; jouer le parcours refusé | Mac |
| E1 Question du niveau en demi-écran, « passer » (`QuestionNiveauView`) | Vu | rien | |
| E1 Tunnel des 3 premières minutes : 12 espèces à swiper, cartes « déclarées » (`TunnelPremiersPasView`) | Vu | l'ordre ne suit pas le coin (truites d'abord à Charenton, `EspecesDuTunnel.choisir`) | cloud (L13, B) |
| E1 Poissons qui nagent sur les stations rares (`PoissonsNageurs`) | Vu | rien | |
| E1 Lancement rapide (moins de 10 s) | Partiel | 15 à 20 s d'écran blanc au simulateur (SwiftData, modèle DINOv2, StoreKit, rendu des images de partage) ; pas d'écran de lancement ; Instruments à passer | Mac |
| E2 Fiche d'un coin : cours d'eau, département, catégorie, espèces en images avec rareté et « N pêches, dernier relevé AAAA » (`FicheCoinView`) | Codé | la fiche elle-même n'est pas dans le rapport de la nuit (seule la carte l'est) | Mac |
| E2 Règles du jour en liste de contrôle, source et citation d'un toucher (`LigneRegleView`, `MoteurRegles`) | Vu | la ligne « fermé du 26 janv. au 24 avril » porte une coche verte (bug d'affichage du verdict) | cloud (`PriseVuesResultat.swift`) |
| E2 Couverture des règles : 95 départements chargés (`Core/Resources/regles/`) | Partiel | tous au niveau « partiel » dans `index.json` (18 151 règles confirmées, 8 379 « vérifie l'arrêté ») ; le 49 (Maine-et-Loire) n'a pas de fichier ; les fichiers de `regles/local` (77 commits plus récents) ne sont pas chargés ; une règle tirée d'un avis 2026 expire le 31/12/2026 ; 75, 92, 93, 94, 77 « relus à la main » : relecture non prouvée | D1 (B) / D3 (A, PC) |
| E2 Rangée « maintenant » (vent, pluie, pression, aube, crépuscule, fin légale) + marque Apple Weather (`RangeeMaintenantView`, `SourceWeatherKit`) | Partiel | l'entitlement `com.apple.developer.weatherkit` est absent de `Config/BuildChallenge.entitlements` : sans lui, WeatherKit échoue en silence (`try?`) et la rangée reste vide ; service à cocher chez Apple sur l'identifiant | Adem + Mac |
| E2 Jauge de la rivière Hub'Eau, courbe 48 h Pro (`JaugeRiviereView`, `HubEauNiveauService`) | Codé | `Core/Resources/stations-hydro.json` vaut `[]` dans git : il faut lancer `scripts/donnees.sh` avant chaque build, sinon aucune jauge ; jamais vue | Mac (A) |
| E2 7 jours heure par heure, Pro (`SeptJoursView`) | Partiel | dépend de WeatherKit (ligne ci-dessus) ; jamais vu | Adem + Mac |
| E1/E2 Vigilance orage et crue en bandeau (`BandeauVigilanceView`) | Partiel | la partie orage dépend de WeatherKit ; jamais vue | Adem + Mac |
| E2 « Préviens-moi » (notifications locales, `PreviensMoi.swift`) | Codé | jamais vu ; aucune clé d'autorisation nécessaire pour les notifications locales, mais à tester sur l'iPhone | Mac |
| E3 Filtre d'espèce « Choisir un autre spot » sur la carte (`FiltreEspeceView`) | Codé | la carte empile 4 boutons dont « changer de spot » en minuscule, et garde « Commencer une session » pendant une session ; l'écran Où chercher porte le même titre que le filtre | cloud (`VueCarte.swift`) |
| E4 Session : chrono, fin légale, quota, reprise après relance (`App/Session/`) | Vu | rien | |
| E4 Carte « à essayer » avec 1er conseil (`CarteAEssayerView`) | Vu | rien | |
| E4/E6 Conseils par espèce : tous les conseils Pro, « comment la pêcher » au dos du Pescedex | Codé | 161 conseils pour 53 espèces sur 99 : les 46 autres n'ont rien ; le repli « mois le plus proche » est une décision que le CLAUDE.md dit validée par Adem le 16 oct. ; `RootView.swift:97` retombe sur `ConseilsFaux()` (faux de Core) si `conseils.json` ne charge pas, hors `#if DEBUG` | S / cloud (`RootView.swift`, A) |
| E5 Photo : 3 espèces en images, « Autre » (grille limitée à la France), « Pas un poisson », aucun pourcentage (`PriseVuesEspece`) | Vu | choisir brochet / brochet aquitain se fait deux fois (groupe, puis sosies) | cloud (`App/Prise/`, B) |
| E5 Modèle de reconnaissance (`PoissonsDino-int8.mlpackage`, 22 Mo, 55 classes) | Partiel | cible 77 espèces ; aucun compte rendu d'examen trouvé dans le dépôt (la règle dit : le modèle n'entre que s'il passe l'examen fixé avant l'entraînement) ; « Poisson-chat (Ameiurus ...) » affiche un nom brut ; « Brochet aquitain » rangé dans les Cyprinidés (données D1) | B / S (R1) |
| E5 Sosies avec critère, stade de l'anguille toujours demandé | Vu | sosies brochet vus ; stade de l'anguille codé, pas vu | Mac |
| E5 Taille au curseur, poids estimé « estimé » | Vu | rien | |
| E5 Toise lue par Vision (`ToiseLecteur`, `ToiseCalibrage`) | Codé | seuils « à mesurer sur 10 photos de toise » : jamais mesurés ; jamais testé avec une vraie toise | Mac + B |
| E5 Verdict : relâche-la avant confirmation, « trop près de la maille », jamais « tu peux la garder » | Vu | coche verte sur une ligne « fermé » (voir E2) | cloud |
| E5 Photo d'exemple pour le relecteur (`App/Prise/photo-exemple.jpg`) | Vu | la carte née d'une photo d'exemple ne compte pas au Pescedex (`exemple = 1`) et le pêcheur n'en est pas prévenu | cloud (B) |
| E6 Pescedex : classeur, toutes les espèces, compteur par zone (`PescedexView`, `CompteurPescedex`) | Vu | 13 espèces sans image (voir branche `lot/images-poissons`) ; le compteur affiche « Département 94 » quand aucune eau nommée | cloud : fusionner `lot/images-poissons` |
| E6 Carte recto / verso, nage dans la carte, reflet holographique rare et légendaire, plein écran (`CarteRectoView`, `NageView`, `RefletHolographique`) | Codé | jamais vu ; le reflet suit l'inclinaison (CoreMotion) donc à voir sur un vrai iPhone ; détourage Vision de la photo : absent du code | Mac / iPhone |
| E6 Révélation de la carte juste après la prise | Absent | `terminerPrise` écrit en base puis ferme : aucune animation de révélation ; le CLAUDE.md dit « pas de révélation avant le paywall (prévu par L4) » donc aucun écran de révélation n'existe nulle part | cloud (B, `App/Collection/`, branchement A dans `RootView.swift`) |
| E6 Météo de la prise au dos de la carte (`BlocConditionsPriseView`) | Partiel | dépend de WeatherKit | Adem + Mac |
| E6 « Tes conditions » après 10 sorties, Pro (`TesConditionsView`) | Codé | branchée dans le Pescedex seulement (le commentaire de `RootView.swift:550` dit qu'elle n'a pas de place dans Mon club) ; jamais vue | Mac |
| E9 Carte bredouille rangée à part (`BredouilleView`) | Codé | jamais vue | Mac |
| E7 Paywall à la fin de la 1re session, qui se ferme | Vu | textes d'Apple en anglais : correctif `CFBundleDevelopmentRegion = fr` posé, à revoir à l'écran | Mac |
| E7 Offres : annuel 34,99 présélectionné, mensuel, achat test, « Restaurer » | Partiel | `ChoixOffres.mensuelRetenu = nil` : le mensuel n'est pas choisi, le paywall n'affiche que l'annuel ; aucune phrase d'essai sans mensuel ; test « abonnement expiré » rouge ; schéma Run à régler sur `TestConfig.storekit` (une fenêtre « compte Apple » est apparue) ; prix en euros à lire dans App Store Connect ; lien de confidentialité du paywall = page générique d'Apple (`RootView.swift:405`, marqué PROVISOIRE) | Adem (choix du mensuel, page de confidentialité) + A |
| E7 Spot gratuit (cercle de 1 km) et 2e spot qui bloque ; « 7 jours » qui ouvre le paywall nommé | Codé | seul le paywall de fin de session a été vu ; tester une session hors du cercle | Mac |
| E7 Consentement avant le SDK Spark Flash, refus = SDK éteint (`App/Mesure/`) | Vu | décision d'Adem sur le moment du SDK : le CLAUDE.md (db62680) dit « après l'accord » ; rien à faire | |
| E8 Mon club : fédération, association, carte de pêche, sécurité, sources, confidentialité, contact | Partiel | `ContactClub.adresse = ""` (le contact et « signaler une erreur de règle » n'existent pas ; test rouge exprès) ; `association: nil` en dur dans `RootView.swift` (le bouton « Mon association » renvoie à la carte de pêche) ; `confidentialite: nil` (pas de lien de confidentialité dans le club) ; pas de `NSPhotoLibraryAddUsageDescription` | Adem (adresse, pages MWM) + cloud (`RootView.swift`, A) |
| E8 Partage d'une carte en image sans GPS (`PartageCarteView`, `ImageSansGPS`) | Codé | l'image n'est jamais passée par le simulateur ; il faut la clé d'ajout à la photothèque pour « Enregistrer l'image » | Mac |
| L15 Widget aquarium (petit à très grand), pont App Group (`WidgetAquarium/`) | Codé | App Group `group.ai.mwm.build.challenge.team.01` déclaré mais non provisionné chez MWM (le rapport de la nuit l'a vu : SwiftData retombait en mémoire) ; jamais vu en taille réelle | Adem (MWM) + Mac |
| Style Marine (D0) : palette #0D4A85, encre, orange pour les alertes, raretés ardoise / vert / violet / or bruni | Partiel | `App/Style/` n'existe pas dans mac/integration (il est sur `lot/style`, 4 commits) ; chaque lot a ses jetons provisoires en couleurs hors palette (vert d'eau #1E7F4F, bordeaux, orange `0.78,0.25,0.16`, bleu `0.118,0.357,0.722`, etc., dans `Collection/Jetons.swift`, `Carte/StyleCarte.swift`, `Prise/PriseJetons.swift`, `Conditions/JetonsConditions.swift`, `Session/JetonsSession.swift`, `Conseils/JetonsConseils.swift`, `Abonnement/JetonsAbonnement.swift`, `Amis/JetonsAmis.swift`, `Widget`, `WidgetAquarium`) | cloud pour fusionner `lot/style` et remplacer les jetons ; Mac pour compiler (A) |

## Mise à jour (hors version soumise, d'après CLAUDE.md)

| Fonction | Statut | Ce qui manque | Qui |
|---|---|---|---|
| L7 Où chercher : 3 coins publics OpenStreetMap près d'ici (`App/OuChercher/`) | Vu | revoir la vitesse corrigée (9,5 s à 0,05 s) ; `coins-maison.json` vaut `[]` | Mac |
| L10 Écran verrouillé (Live Activity) | Codé | démarre et se met à jour dans le journal, jamais capturé verrouillé ; l'aperçu `demarrerFaux` est bien sous `#if DEBUG` | Mac / iPhone |
| L8 Amis CloudKit | Codé | deux iPhones et deux comptes iCloud ; « Deploy Schema Changes » vers Production ; déjà branché dans Mon club alors que `docs/app-store.md` (R5) dit « amis hors du build soumis, code retiré » : décision à prendre (retirer le bouton « Mes amis » de `RootView.swift`, ou assumer la règle 1.2 d'Apple avec adresse de contact) | Adem |
| L11 Règles à jour | Codé | `ReglesBaseURL` vide dans `Config/BuildChallenge-Info.plist` : aucun téléchargement tant qu'Adem n'a pas choisi l'hébergement ; workflow `.github/workflows/veille.yml` pas copié | Adem + A |
| L14 Aquarium + bouton « Voir mon aquarium » | Absent | le code est sur `sullyvan/aquarium` (1 453 lignes, jamais compilées) ; `RootView.ouvrir` renvoie `fishme://aquarium` vers le Pescedex (« L14 absent ») ; décision d'Adem : stand-by | Adem puis Mac |

## Étapes E1 à E9

| Étape | Statut | Preuve | Ce qui manque |
|---|---|---|---|
| E1 Premier lancement, carte, niveau, tunnel | Vu (sauf refus de position) | rapport de tests : demande de position, « Ton niveau ? », 12 espèces, consentement | refus de position, 15 à 20 s de lancement |
| E2 Fiche d'un coin, conditions, règles | Partiel | règles vues via le verdict du Val-de-Marne ; fiche, rangée et jauge non vues | WeatherKit, `stations-hydro.json`, fiche à regarder |
| E3 Choisir un autre spot / espèce | Partiel | Où chercher vu (L7) ; filtre d'espèce de la carte non cité | encombrement des boutons |
| E4 Session | Vu | chrono, fin légale, « pêche fermée de nuit », reprise | écran verrouillé (mise à jour) |
| E5 Prise | Vu (avec défauts) | photo d'exemple, DINOv2, sosies, curseur, poids, verdict | toise Vision, doublon de choix, coche verte |
| E6 Carte et Pescedex | Partiel | Pescedex conservé après relance | carte vue en grand, reflet, nage, révélation, météo du dos |
| E7 Paywall | Partiel | paywall vu après la 1re session | mensuel, achat test, 2e spot, "7 jours", confidentialité |
| E8 Mon club | Partiel | écran ouvert sans plantage | contact, association, confidentialité, partage en image |
| E9 Bredouille | Codé | `BredouilleView`, test à l'écran absent | à voir |

## Conformité pour l'envoi à Apple (24 points)

Faits : nom affiché FishMe, langue de base `fr`, iPhone seul (`TARGETED_DEVICE_FAMILY = 1`, portrait), iOS 27.0, identifiant MWM inchangé, icône 1024 présente, texte de position en français, `NSSupportsLiveActivities`, URL `fishme://`, photo d'exemple, aucune barre de défilement visible (tous les `ScrollView`, `List` et `Form` portent `.scrollIndicators(.hidden)`), aucun mot interdit dans les textes de l'app, rien en anglais dans les textes de l'app, aucun TODO/FIXME, faux services sous `#if DEBUG`, sélecteur de photos du simulateur sous `#if DEBUG`.

Manquants :

| Point | Détail | Qui |
|---|---|---|
| `NSCameraUsageDescription` | absente de `Config/BuildChallenge-Info.plist` et du `.pbxproj` : `UIImagePickerController(.camera)` fait planter l'app sur un iPhone réel dès « Ajouter une prise » | cloud (A, `Config/BuildChallenge-Info.plist`) |
| `NSPhotoLibraryAddUsageDescription` | absente : « Enregistrer l'image » de la feuille de partage fait quitter l'app | cloud (A) |
| `App/PrivacyInfo.xcprivacy` | n'existe pas dans le dépôt (check-list lignes 7 et 19) ; `UserDefaults`, dates de fichiers et données déclarées du SDK à lister | cloud (A) pour l'écrire, Mac pour le rapport de confidentialité de l'archive |
| `ITSAppUsesNonExemptEncryption = NO` | absente de l'Info.plist | cloud (A) |
| Entitlement WeatherKit | absent de `Config/BuildChallenge.entitlements` ; service à cocher sur l'identifiant dans le portail | cloud pour la ligne, Adem / MWM pour le portail |
| Profil de signature | iCloud / CloudKit et App Group sont déclarés ; si le profil de l'équipe MWM ne les porte pas, l'archive échoue ou les données retombent en mémoire | Adem (MWM) |
| Adresse de contact | `ContactClub.adresse = ""` | Adem |
| Page de confidentialité et conditions | pas publiées (MCP de MWM, `publish_legal_document`, sur le oui d'Adem) ; le paywall pointe sur la page générique d'Apple | Adem |
| Clé d'orientation iPad | `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad` encore présente (sans effet, iPhone seul) | cloud (A), facultatif |
| Données fabriquées | `stations-especes.json`, `rarete-departements.json`, `stations-hydro.json` ne sont pas dans git ; `scripts/donnees.sh` les met dans `App/Donnees/` (ignoré) ; un build sans ce script n'a ni stations, ni raretés, ni jauge | Mac (A) : le lancer avant `scripts/envoi.sh` |
| Tests | 122 sur 125 verts ; rouges : abonnement expiré, adresse du club, 2 espèces sans image ; le lanceur reste bloqué après la suite StoreKit | Mac |
| Build Release | rien ne dit qu'un build Release (sans `#if DEBUG`) a été compilé et lancé | Mac |
| Captures, fiche, notes du relecteur | sur `lot/store` (26 commits), non fusionnée ; la liste `store/fonctions-du-build.md` est entièrement décochée | A / Adem |
| Départements dans la fiche | ne nommer que les départements chargés ; tous sont « partiel » | A |
| Mensuel retenu | décision d'Adem (4,99 / 6,99 / 9,99) | Adem |
| Compte MWM, Paid Apps Agreement, questionnaire d'âge, App Privacy | comptes et clics sur le site d'App Store Connect | Adem |
| Version et build | `MARKETING_VERSION = 1.0`, `CURRENT_PROJECT_VERSION = 1` : à incrémenter à chaque envoi | A |
| TestFlight / archive | `scripts/envoi.sh` jamais lancé | A (Mac) |
| WeatherKit : quota et marque | marque et lien légal sont lus dans WeatherKit (bien) ; quota 500 000 appels à confirmer avec MWM | Adem |
| SDK Spark Flash | initialisé seulement après l'accord (bien) ; liste de données collectées à confirmer avec MWM | Adem |
| Photo d'exemple | la carte née d'une photo d'exemple ne doit pas tromper (message) | cloud |
| Textes d'Apple en anglais | correctif posé, à vérifier à l'écran | Mac |
| Écran de lancement | aucun ; sert aussi à masquer les 15 à 20 s | cloud (A) + Mac |

## Contrôles demandés

- **Faux services hors `#if DEBUG`** : un seul vrai cas. `App/RootView.swift:97` utilise `ConseilsFaux()` (de `Core/Contrats/Faux.swift`) comme repli si `conseils.json` ne charge pas. Les autres faux (`SourceMeteoFaux`, `NotifieurFaux`, `GeoFaux` de `ServicesCarte`, `IdentifieEspeceFaux`, `FauxServiceAmis`, `PilotageActivite.demarrerFaux`, `PriseSelecteurDebug`) sont sous `#if DEBUG`. `Core/Contrats/Faux.swift` n'est pas sous `#if DEBUG` (c'est un paquet) : ses types sont donc dans le binaire Release, mais seul `ConseilsFaux` est appelé. `PhotoExemple` (rustine bleue quand `photo-exemple.jpg` manque) est hors `#if DEBUG` mais le fichier existe.
- **Textes en anglais** : aucun trouvé dans `App/`, `Widget/`, `WidgetAquarium/`. Seules les notes du relecteur sont en anglais, voulu (`store/notes-relecteur-en.md`).
- **Mots interdits** : aucun dans les textes affichés. Les occurrences sont dans `ValidationConseils.swift` (liste de contrôle) et `cas-verdicts.json` (phrases qui disent que « tu peux la garder » n'existe jamais). `Pokémon` : zéro.
- **TODO / FIXME** : aucun dans `App/`, `Widget/`, `WidgetAquarium/`, `Core/Sources`. Les vrais « à faire » sont des commentaires « provisoire » (liste plus bas).
- **Barres de défilement** : aucune en défaut (tous les `ScrollView`, `List`, `Form` sont masqués). Le paywall n'a pas de `ScrollView` : sur un petit iPhone le texte peut être coupé.
- **Couleurs hors palette Marine** : tout l'app, car `App/Style/` n'est pas fusionné (voir ligne « Style Marine »). Aucune couleur n'est ni #0D4A85 ni #E8571C dans le code actuel.

## Liste des « à faire » trouvés dans le code (commentaires)

| Fichier | À faire |
|---|---|
| `App/RootView.swift:96` | « Repli sur le faux de Core si conseils.json ne se charge pas (à vérifier sur le Mac) » |
| `App/RootView.swift:403-405` | `confidentialiteProvisoire` : remplacer par la vraie page MWM avant l'envoi |
| `App/RootView.swift:416-417`, `RootView.ouvrir` | `// styleFishMe()` : App/Style/ absent ; `aquarium` renvoie au Pescedex (« L14 absent ») |
| `App/RootView.swift:550` | « Tes conditions » non branchée dans Mon club |
| `App/RootView.swift` (`club`) | `association: nil`, `confidentialite: nil` |
| `App/Club/ClubDonnees.swift:44` | `ContactClub.adresse = ""` |
| `App/Abonnement/Produits.swift:21` | `ChoixOffres.mensuelRetenu = nil` |
| `App/Collection/Jetons.swift`, `Carte/StyleCarte.swift`, `Session/JetonsSession.swift`, `Conditions/JetonsConditions.swift`, `Conseils/JetonsConseils.swift`, `Abonnement/JetonsAbonnement.swift`, `Prise/PriseJetons.swift`, `Amis/JetonsAmis.swift` | jetons provisoires à remplacer par `App/Style/` |
| `App/Conseils/LogiqueConseils.swift:27` | pictogramme provisoire en SF Symbols |
| `App/Prise/ToiseCalibrage.swift` | seuils à mesurer sur 10 photos de toise |
| `Config/BuildChallenge-Info.plist` | `ReglesBaseURL` vide |
| `docs/mac-a-faire/*.md` | listes de branchement de L7, L8, L10, L11, L15 (la plupart déjà faites dans `RootView.swift`) |

## Ce que le cloud peut corriger tout de suite (sans Mac)

1. `Config/BuildChallenge-Info.plist` : ajouter `NSCameraUsageDescription`, `NSPhotoLibraryAddUsageDescription` (en français), `ITSAppUsesNonExemptEncryption = false`.
2. `Config/BuildChallenge.entitlements` : ajouter `com.apple.developer.weatherkit` = true.
3. Créer `App/PrivacyInfo.xcprivacy` (UserDefaults, dates de fichiers, pas de suivi), d'accord avec le SDK.
4. Fusionner `origin/lot/images-poissons` (13 espèces sans image) et `origin/lot/style` (puis remplacer les jetons provisoires des 8 fichiers `Jetons*.swift`).
5. `App/RootView.swift` : retirer le repli `ConseilsFaux()` hors DEBUG, brancher `association` et `confidentialite`, brancher `styleFishMe()`.
6. `App/Collection/` + `RootView.swift` : écran de révélation de la carte après la prise (E6 absent).
7. `App/Carte/Vues/VueCarte.swift` : réduire les 4 boutons ; `App/Conseils/` : ordre des espèces du tunnel selon le coin ; verdict : coche verte sur une ligne « fermé » (`PriseVuesResultat.swift`).
8. Un écran de lancement (`UILaunchScreen`) pour masquer le démarrage lent.

## Ce qui demande Adem, un compte ou un Mac

- Adem : mensuel retenu, adresse de contact, page de confidentialité et conditions (MCP MWM), amis dans ou hors du build soumis, aquarium (stand-by), choix de l'hébergement des règles (`ReglesBaseURL`), WeatherKit coché chez Apple, App Group et iCloud provisionnés par MWM.
- Mac : compiler, lancer `scripts/donnees.sh`, tester refus de position, fiche d'un coin, météo, jauge, carte en grand et reflet sur un vrai iPhone, achat test, build Release, Instruments pour le lancement, `scripts/envoi.sh`.
