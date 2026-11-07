# Migration vers le compte Developer personnel de Titouan

Décision du 7 nov. (`CLAUDE.md`, « Décisions du 7 nov. », point 5) : FishMe sort sous le compte Developer personnel de Titouan, avec nouveau Bundle ID, nouveau conteneur iCloud, nouveaux App Groups, abonnements recréés, WeatherKit et Push réactivés. MWM a retiré ses accès le 28 oct.

Cette page est une checklist. Rien n'est fait par le dépôt : aucun source, aucun entitlement et aucun fichier du projet Xcode n'a été modifié par ce lot. Le script `scripts/migration/migrer-identifiants.py` fait l'inventaire et, seulement sur ordre, les remplacements.

Perte d'abonnés : aucune, l'app n'est pas publiée. Les anciens identifiants MWM ne servent plus à rien dès que l'étape 13 est faite.

## Ce que Titouan doit fournir (le dépôt n'a rien de tout cela, et ne le demandera jamais dans le chat)
- Les 5 valeurs : `NOUVEAU_BUNDLE_ID`, `NOUVEAU_ID_WIDGET` (doit commencer par le Bundle ID + point), `NOUVEAU_CONTENEUR_ICLOUD` (`iCloud.` + …), `NOUVEAU_APP_GROUP` (`group.` + …), `NOUVEAU_TEAM_ID` (10 caractères, lu dans developer.apple.com > Membership).
- Son Apple ID, son mot de passe et la double authentification (code sur son iPhone) : lui seul les tape, sur apple.com, dans Xcode et dans App Store Connect.
- Ses données de paiement du programme, de banque et de fiscalité (étape 4). Aucun mot de passe ni clé ne va dans git. Le README du kit MWM contient un mot de passe MWM : ne pas l'ouvrir ni le recopier, et supprimer le dossier du kit au moment de retirer Spark si on le retire.

## Ordre sûr

### A. Avant tout compte (sans risque, sans Apple)
1. Choisir les 5 valeurs. Le Bundle ID d'une app créée dans App Store Connect ne change plus : le choisir avec le nom définitif en tête.
2. `python3 -I scripts/migration/migrer-identifiants.py` : rapport seul. Puis, sur une copie : `... --nouveau-… (5 valeurs) --appliquer --copie /chemin/vide` et relire le diff. Rien n'est écrit dans le dépôt tant qu'on ne dit pas `--sur-depot-courant`.

### B. Chez Apple (Titouan, dans cet ordre)
3. Programme Apple Developer (developer.apple.com/programs, inscription comme particulier : le nom légal de Titouan sera le vendeur affiché sur l'App Store). Payant à l'année. Double authentification obligatoire.
4. App Store Connect > Business (ou Agreements, Tax, and Banking) : accepter le « Paid Applications Agreement », renseigner compte bancaire et formulaires fiscaux. Sans cela, les abonnements ne peuvent pas être vendus. La validation peut prendre quelques jours : à faire tôt.
5. Certificates, Identifiers & Profiles > Identifiers : créer le Bundle ID de l'app, avec les capacités :
   - iCloud, case CloudKit cochée (le code n'utilise que CloudKit) ;
   - App Groups (le groupe `NOUVEAU_APP_GROUP`) ;
   - WeatherKit (aussi cochée dans l'onglet « App Services » : le bloc météo ne charge pas sans) ;
   - Push Notifications (L25, chat « à la minute » via abonnements CloudKit) ;
   - Associated Domains : seulement si un lien universel est ajouté plus tard ; le dépôt n'en utilise aucun aujourd'hui (aucune clé dans les entitlements), donc ne pas la cocher.
6. Créer le second Bundle ID, celui du widget (`NOUVEAU_ID_WIDGET`), avec App Groups (même groupe) uniquement. Créer l'App Group (type « App Groups ») et le conteneur iCloud (type « iCloud Containers ») puis les associer aux Bundle ID. Les cibles de test (`…BuildChallengeTests`, `…UITests`) n'ont pas besoin d'être enregistrées.
7. App Store Connect > Apps > « + » : nouvelle app iOS, nom, langue principale fr, Bundle ID de l'étape 5, SKU libre. Le nom d'app est réservé à vie pour ce compte.
8. Conteneur CloudKit (voir `outils/cloudkit/LISEZMOI.md`, les 4 commandes) :
   - jeton de gestion créé par Titouan dans CloudKit Console > Settings > Tokens & Keys, `xcrun cktool save-token --type management` (il va dans le trousseau, jamais dans un chat ni un fichier) ;
   - `cktool validate-schema` puis `import-schema --team-id <NOUVEAU_TEAM_ID> --container-id <NOUVEAU_CONTENEUR> --environment development --file outils/cloudkit/schema-development.ckdb` ; le fichier n'a jamais été validé par Apple : corriger selon l'erreur ;
   - tester l'app en Development ; vérifier les index (dont `createdBy` de ProfilPublic) ; puis « Deploy Schema Changes » vers Production. Non réversible : un type déployé ne se supprime plus.
   - Le conteneur Production doit être déployé AVANT d'envoyer le build TestFlight externe/public : les builds TestFlight et App Store parlent à Production.
9. Abonnements (App Store Connect > l'app > Monétisation > Abonnements), 6 produits dans un seul groupe « Premium Plan », identifiants EXACTS : `<NOUVEAU_BUNDLE_ID>.` + `yearly.00.ft.34.99`, `yearly.00.ft.49.99`, `yearly.00.ft.69.99`, `monthly.07.ft.04.99`, `monthly.07.ft.06.99`, `monthly.07.ft.09.99` (le script réécrit seulement le préfixe ; si Titouan préfère d'autres suffixes, c'est à la main dans `TestConfig.storekit`, `App/Abonnement/Produits.swift`, `Packages/Core/.../MoteurSession.swift`).
   - Durées : 3 annuels (1 an), 3 mensuels (1 mois). Essai : 1 semaine gratuite sur les 3 mensuels, aucun sur les annuels.
   - Prix : 4,99 / 6,99 / 9,99 (mensuels) et 34,99 / 49,99 / 69,99 (annuels) en dollars, puis contrôle des prix par pays (FR, DE, NL, UK, ES, IT, US) ; les euros sont ceux du fichier de prix d'Apple, à relire dans `docs/reports/prix.md`.
   - Tarif fondateur : annuel 34,99 jusqu'au 31 déc. 2026, puis 49,99 à partir du 1er janv. 2027 : programmer le changement de prix en conservant le prix des abonnés existants.
   - Chaque abonnement exige nom affiché, description, capture pour la relecture ; le groupe exige une localisation. Les abonnements sont soumis avec la première version.
   - Un identifiant de produit supprimé ne peut jamais être réutilisé : ne pas improviser, créer avec le bon nom du premier coup.
10. Fichier StoreKit local `TestConfig.storekit` : mêmes 6 identifiants (le script le fait). Le fichier ne parle pas à Apple : il sert au simulateur ; le contrôle réel est le bac à sable (étape 11).
11. TestFlight interne : Titouan se connecte dans Xcode (Settings > Apple Accounts), met son équipe sur les 2 cibles (signature automatique), puis `SCHEMA=… scripts/envoi.sh --a-blanc`, puis l'envoi réel. `envoi.sh` utilise le compte Xcode ; une clé d'API (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`, créée par Titouan dans App Store Connect > Users and Access > Integrations) reste dans `.env`, hors git. Testeurs internes : seulement des membres de l'équipe Titouan (jusqu'à 100) ; ajouter Adem et Sullyvan comme utilisateurs App Store Connect s'ils doivent tester. Testeurs bac à sable : App Store Connect > Users and Access > Sandbox : créer des Apple ID de test, jamais le vrai. Tester achat, essai, restauration, résiliation.
12. Politique de confidentialité et CGU : leur URL publique est obligatoire dans App Store Connect (champs « Privacy Policy URL » et « Terms »). L'hébergement MWM (son serveur MCP) n'est plus disponible : héberger ailleurs (GitHub Pages, un site gratuit) et renseigner l'URL ; la clé `ReglesBaseURL` de `Config/BuildChallenge-Info.plist` est vide et reste à décider. Les textes de `docs/legal/` nomment MWM comme éditeur (9 fichiers, 49 mentions) : remplacer par l'identité de Titouan (ou son statut), son adresse, l'hébergeur, le médiateur. Toujours relus par un juriste avant publication. Le contact `fishme.app@gmail.com` (49 occurrences, 27 fichiers dont `ContactClub.adresse`, testé par `ClubTests`) ne change pas, sauf choix de Titouan. Reprendre aussi les « étiquettes App Privacy » (`docs/app-store.md`, ligne 6 du tableau).

### C. Code (après les étapes 5 à 9, sur une branche, par Titouan ou sur son ordre)
13. `--appliquer --copie` puis relecture, puis `--appliquer --sur-depot-courant --portee code` sur un dépôt propre, un commit isolé. Le projet Xcode est modifié en texte (pbxproj) : le rouvrir dans Xcode, vérifier Signing & Capabilities des 2 cibles, build, `scripts/verif.sh`, tests.
14. Rien n'est remplacé par le script (à la main) : schéma d'URL `fishme://` (inchangé, il ne dépend pas du compte), `CFBundleURLName` (= Bundle ID, remplacé car identifiant), `aps-environment` (reste `development` dans le fichier ; Xcode passe en production à l'archive), clé Spark.

## SDK de mesure Spark de MWM : décision à prendre
Où : package local `mwm-spark-flash-sdk/local-spm-repo`, appel unique `BuildChallengeApp.configurerSpark` (App/BuildChallengeApp.swift), seulement après le consentement dans les réglages. Deux clés d'API (bac à sable, production) sont écrites en dur dans ce fichier : elles ont été fournies par MWM pour l'app de MWM. Ni le script ni ce document ne les recopient.
- Garder : exige l'accord écrit de MWM, une clé liée au nouveau Bundle ID, la mention de MWM comme destinataire (politique, étiquettes) et que le SDK soit encore sous licence. Risque : MWM a coupé ses accès, la clé peut être révoquée ou ne plus rien recevoir ; les données d'usage vont chez un tiers dont Titouan devient responsable.
- Remplacer (mesure Apple App Analytics, gratuite, ou un outil sans clé MWM) : écrire un nouvel adaptateur derrière `Passerelle` ; plus de travail, plus de dépendance à MWM.
- Retirer : le plus sûr pour une première version. Retirer le package du projet, `configurerSpark`, la feuille de consentement et le § 7 de la politique ; mettre à jour les étiquettes App Privacy. Ce changement touche des sources : à confier à un lot dédié, il n'est pas fait ici.
Recommandation : ne pas livrer avec la clé MWM actuelle sans accord écrit ; décision de Titouan.

## Fichiers que le code oblige à changer (inventaire du 7 nov., script, portée `code` : 44 occurrences ; avec documents : 79 dans 41 fichiers)
- Projet : `BuildChallenge.xcodeproj/project.pbxproj` (Bundle ID app et widget, équipe ×4, cibles de test ×4).
- Entitlements : `Config/BuildChallenge.entitlements` (conteneur, groupe), `Config/FishMeWidget.entitlements` (groupe), `Config/planb/app-sans-icloud.entitlements`, `Config/planb/app-sans-icloud-weatherkit.entitlements` (groupe).
- Info.plist : `Config/BuildChallenge-Info.plist` (`CFBundleURLName`).
- Sources conteneur iCloud : `App/Amis/ServiceAmis.swift`, `App/Chat/ServiceChatCloudKit.swift`, `App/Communaute/ServiceFeedCloudKit.swift`, `App/Compte/SauvegardeICloud.swift`, `App/Reperes/SauvegardeReperes.swift`.
- Sources App Group : `App/Session/ActionSessionEnAttente.swift`, `Widget/Session/IntentsSession.swift`, `WidgetAquarium/InstantaneAquarium.swift`, `WidgetAquarium/ApercuAnimationAquarium.swift`.
- Produits : `App/Abonnement/Produits.swift`, `Packages/Core/Sources/Core/Session/MoteurSession.swift`, `TestConfig.storekit`.
- Scripts : `scripts/lancer-simu.sh` (identifiant de l'app). `scripts/envoi.sh` et `scripts/archive-planb.sh` ne contiennent aucun identifiant : ils lisent le projet.
- Outils : `outils/cloudkit/LISEZMOI.md` (conteneur, équipe, commandes `cktool`).
- Documents (portée `tout`) : `CLAUDE.md`, `docs/`, `reports/`, `store/`, `.claude/` : historique ; on remplace de préférence après coup, en gardant les rapports passés tels quels.

## Ce qui n'est pas réversible
- Bundle ID d'une app créée dans App Store Connect, et nom de l'app.
- Identifiants de produits d'abonnement créés puis supprimés (jamais réutilisables).
- Types de schéma CloudKit déployés en Production, et les conteneurs iCloud créés.
- Politique et CGU publiées, URL déclarées à Apple.
- Pas de retour au compte MWM : les accès sont retirés.
Le script, lui, est réversible : simulation par défaut, copie ou dépôt git propre (un `git checkout` suffit).

## Risques
- Perte d'abonnés : aucune (non publiée).
- WeatherKit : l'activation prend parfois quelques heures, tester sur iPhone réel.
- Push : l'environnement passe de développement à production à la distribution ; tester sur un build TestFlight.
- Données iCloud de test : le nouveau conteneur est vide, les repères et sauvegardes faits sous l'ancien identifiant sont perdus (sans importance avant publication).
- Widget : le groupe et le Bundle ID du widget doivent correspondre aux profils, sinon le widget reste sur son écran de chargement.
- Mesure Spark : voir plus haut.
