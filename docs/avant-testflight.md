# Avant TestFlight (L25, 7 nov.)

État du build préparé sans le compte Apple. Rien ici ne change le Bundle ID ni l'équipe : `scripts/migration/migrer-identifiants.py` le fera quand le compte de Titouan existera.

## Fait dans le dépôt (lot L25)
- Onglet Communauté : écran « Bientôt » seul (`CommunauteBientotView`, sans date, sans capture, sans fil, chat ni club). Le réseau ne s'ouvre que par `ReglagesCommunaute.reseauActif()` : constante `false` en Release ; l'argument `-communaute.reseau YES` n'est lu que sous `#if DEBUG`. Liens `fishme://ami` et `fishme://club`, notifications silencieuses et `registerForRemoteNotifications` sont aussi coupés tant que le réseau est éteint.
- Démo : `App/Demo/` est sous `#if DEBUG` (en Release, des noms vides pour que le reste compile) ; le chat d'exemple et le « Mode démo » du profil (RootView) sont DEBUG seulement ; `modeDemo` vaut `false` en Release ; une phase de script « Retirer la démo (Release) » retire les 5 photos de `App/Demo/Photos` du bundle. `-FishMeForcerPro`, `-FishMeApercuWidget` et `-prise-test` étaient déjà sous `#if DEBUG`.
- `App/PrivacyInfo.xcprivacy` : UserDefaults (CA92.1 et 1C8F.1, groupe d'app) et FileTimestamp (C617.1, `CartesClub`), suivi `false`, 7 types de données du SDK Spark.
- `Config/InfoPlist.xcstrings` : textes d'autorisation caméra, position et ajout à la photothèque, français et anglais.
- Contrôlés, rien à changer : iPhone seul (`TARGETED_DEVICE_FAMILY = 1`), portrait, `ITSAppUsesNonExemptEncryption = NO`, icône 1024 px, launch screen `UILaunchScreen` (couleur `FondLancement`), `UIAppFonts` des 12 polices `FishMeClignote*` dans les deux Info.plist, version 1.0 (build 3).

## Ce qui bloque encore
1. Compte Apple Developer de Titouan : sans lui, ni archive signée, ni TestFlight. Rien n'est envoyé à Apple avant.
2. Bundle ID, équipe, conteneur iCloud (`iCloud.ai.mwm.build.challenge.team.01`), groupe d'app (`group.ai.mwm.build.challenge.team.01`), identifiant du widget : à remplacer par `scripts/migration/migrer-identifiants.py` (simulation d'abord), puis créer l'identifiant, les capacités (iCloud/CloudKit, App Groups, WeatherKit, Push) et le conteneur dans le compte.
3. Abonnements : les 6 produits du groupe « Premium Plan » sont ceux de MWM (`App/Abonnement/Produits.swift`, `TestConfig.storekit`) ; à recréer dans App Store Connect avec le nouveau Bundle ID, puis rejoindre le paywall.
4. Clé api.data.gov (US, lot US5) à fournir par Titouan, et proxy US (`outils/us/proxy/`) à héberger : sans lui, les conditions américaines (USGS, NWS) ne répondent pas. L'app doit connaître l'adresse du proxy ; la clé ne va jamais dans l'app.
5. Page de confidentialité et conditions : `ParcoursApp.confidentialiteProvisoire` pointe encore vers une page d'Apple. À remplacer par l'adresse réelle avant tout envoi, ainsi que `FishMeLienAppStore` (clé Info absente) et l'adresse de contact.
6. Étiquettes « App Privacy » et questionnaire d'âge dans App Store Connect : à remplir avec les réponses de `store/app-privacy.md`, d'accord avec le manifeste.
7. Textes d'App Store en anglais (US) : fiche, notes du relecteur (`store/`), captures en Release sur le simulateur.
8. Cible de déploiement : l'app est à iOS 26.6, les tests à 27.0 ; à aligner avec ce que vise Titouan.
9. Le widget n'a pas de `PrivacyInfo.xcprivacy` propre (il lit les UserDefaults du groupe) : à ajouter au projet depuis Xcode (cible FishMeWidget, contenu partiel : UserDefaults 1C8F.1).
10. Dernier tour avant l'archive : « Generate Privacy Report » dans l'organiseur d'Xcode, et un `grep` des mots de `docs/banc/mots-interdits.md`.

## Dossiers de lots à nettoyer (hors L25, à dire à leurs propriétaires)
Ce code reste compilé en Release, inatteignable tant que le réseau est éteint, mais il contient des données d'exemple : `App/Communaute/ServiceFeedExemple.swift` (avec `FauxServiceFeed`, `DemoFeed` dans `PublicationVue.swift`, et `GestionFeed.reel` qui retombe sur l'exemple), `App/Chat/ChatExemple.swift`, `App/Club/DemoClub.swift` (texte « Démo »), `App/Amis/DemoAmis.swift`, `App/Conditions/LectureExemple.swift` et `TesConditionsMeteoView` (`@AppStorage("demo.communaute")` : lecture météo d'exemple), `App/Amis/AmisPageView.swift`, `App/Abonnement/ReglagesView.swift` (la ligne « Mode démo » et la ligne « Crédits photos » sont visibles en Release : à mettre sous `#if DEBUG`), `App/Collection/PescedexView.swift` (pastille « Démo », inerte en Release), `WidgetAquarium/*` (`exempleRendu`, utilisé par les aperçus et en placeholder).

## À retirer avant publication sans accord MWM (Spark Flash et identifiants MWM)
Rien n'a été modifié ; liste seulement.
- Le SDK : dossier `mwm-spark-flash-sdk/` (paquet local `local-spm-repo`), référence `XCLocalSwiftPackageReference` et produit `Spark` de la cible BuildChallenge dans `BuildChallenge.xcodeproj/project.pbxproj`.
- Le code : `App/BuildChallengeApp.swift` (`import Spark`, `configurerSpark`, les deux clés `pk_sbox_…` et `pk_prod_…`), `App/Mesure/PasserelleSpark.swift`, le câblage dans `RootView.swift` (`PasserelleSpark`, `CoucheMesure`, `configurerMesure`), puis la feuille « Mesure d'usage » si on retire toute la mesure.
- Le manifeste `App/PrivacyInfo.xcprivacy` : les 7 types de données collectées (achats, interactions, performances, plantages, diagnostics, identifiant utilisateur, identifiant d'appareil) viennent du SDK ; à retirer avec lui, ainsi que les lignes correspondantes de `store/app-privacy.md` et `store/note-mwm-mesure.md`.
- Les identifiants du compte MWM (traités par la migration) : Bundle ID `ai.mwm.build.challenge.team.01`, équipe `ZUQ3ZP29N4` dans le projet, conteneur et groupe d'app, identifiants des 6 abonnements, schéma d'URL `CFBundleURLName`, mentions MWM des textes juridiques et de la fiche.
- Ne jamais commiter le README du kit MWM (il contient un mot de passe) ; les clés Spark de production sont déjà dans l'historique du dépôt : à considérer comme exposées si MWM ne les révoque pas.
