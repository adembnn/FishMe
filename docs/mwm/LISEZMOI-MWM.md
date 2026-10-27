# MWM : tout ce qu'il faut garder (sauvegarde du 27 octobre 2026)

MWM a annoncé le 27 octobre que **tous les accès invités à son App Store Connect sont retirés le mercredi 28 octobre à 18 h (heure de Paris)** et que les builds TestFlight de l'équipe sont supprimés de son compte. Ce dossier rassemble, dans le dépôt, tout ce qui concerne MWM pour ne rien perdre. **Aucun mot de passe, identifiant de connexion ni clé n'est stocké ici** (voir la section 5).

## 1. Chiffres techniques (non secrets)
- Identifiant de l'app (Bundle ID) donné par MWM : `ai.mwm.build.challenge.team.01`. Il **ne peut pas être transféré** vers un autre compte (Apple n'autorise pas le transfert d'une app jamais approuvée) : il faut en choisir un nouveau sous le nouveau compte, pour l'app, le widget, les droits (`Config/*.entitlements`) et le conteneur iCloud.
- Équipe MWM dans Xcode : `ZUQ3ZP29N4`. Conteneur iCloud prévu : `iCloud.ai.mwm.build.challenge.team.01` (il n'a jamais existé côté Apple : droits insuffisants dans l'équipe de MWM).
- Contact officiel du Build Challenge : `build-challenge@mwm.ai`.
- SDK de mesure **Spark Flash** 0.5.8 : dans ce dépôt, `mwm-spark-flash-sdk/` (code et binaire `SparkLib.xcframework`, 9,4 Mo, versionné : le build n'a pas besoin du compte MWM pour le compiler). Ses conditions interdisent les apps visant les moins de 13 ans. Le consentement à la mesure est dans les Réglages de l'app, éteint par défaut.
- **Six produits d'abonnement** (groupe « Premium Plan », fichier `TestConfig.storekit` du dépôt) : mensuels avec essai gratuit d'une semaine `ai.mwm.build.challenge.team.01.monthly.07.ft.04.99`, `…06.99`, `…09.99` ; annuels sans essai `ai.mwm.build.challenge.team.01.yearly.00.ft.34.99`, `…49.99`, `…69.99` (prix en euros 4,99, 6,99, 9,99, 34,99, 49,99, 69,99). Tarif fondateur : annuel à 34,99 € jusqu'au 31 décembre 2026, puis 49,99 €. **Ces produits vivent dans App Store Connect de MWM et seront perdus : à recréer dans le nouveau compte**, avec de nouveaux identifiants si l'on change le Bundle ID (les identifiants de produit commencent par celui de l'app).
- Serveur MCP de la console MWM : `https://mcp.mwm.ai/mcp` (déclaré dans `.mcp.json`). Il répondait 401 depuis le cloud (joignable mais non connecté au compte de l'équipe) et se connecte par OAuth, fait par l'utilisateur. Il ne sert plus sans accès MWM.

## 2. Où est chaque information dans le dépôt
| Sujet | Fichier |
|---|---|
| SDK Spark Flash, son manifeste de confidentialité | `mwm-spark-flash-sdk/` (README, `Package.swift`, `Sources/Resources/PrivacyInfo.xcprivacy`) |
| Produits d'abonnement et offres | `TestConfig.storekit`, `App/Abonnement/`, `docs/fiches/L6.md` |
| Droits de l'app (WeatherKit, iCloud, Push) | `Config/BuildChallenge.entitlements`, `Config/FishMeWidget.entitlements`, `Config/planb/` (variantes sans iCloud) |
| Appels prévus au serveur MCP de MWM | `store/appels-mwm.md` |
| Résultats déjà obtenus de la console MWM | `store/mwm-resultats.md` |
| Mesure, consentement, ce que collecte Spark Flash | `store/note-mwm-mesure.md`, `store/confidentialite-spark-flash.md`, `store/app-privacy.md` |
| Fiche App Store (textes, notes du relecteur) | `store/fiche-fishme.md`, `store/fiche-reseau.md`, `store/notes-relecteur-en.md`, `store/notes-relecteur-reseau-en.md` |
| Premiers messages à MWM, demandes d'accès | `docs/message-mwm.md` |
| Règles App Store et refus probables | `docs/app-store.md` |
| Ton et identité de MWM, évaluation | `docs/design/ton-mwm.md`, `docs/reports/eval-mwm.md` |
| Coordination avec l'agent d'Adem, blocage iCloud | branche `coordination`, `docs/coordination/` ; `adem/coordination-capacites` |
| Appel avec le CTO de MWM du jeudi 29 octobre | `docs/mwm/archive/call-mwm-29-oct.md` (ordre du jour, 20 questions, demandes) |

## 3. Archive de ce dossier (`docs/mwm/archive/`)
Ces fichiers n'existaient que sur l'ordinateur de Titouan (hors de tout dépôt) et sont maintenant sauvegardés ici, **avec les identifiants et clés retirés** (chaque ligne retirée est remplacée par une mention) :
- `kit-README-expurge.md` : le README du kit MWM (comment fonctionne le Build Challenge, le compte d'équipe, les environnements d'abonnement, le MCP).
- `spark-flash-sdk-README.md` : le README du SDK de mesure.
- `starter-kit-mwm.md` et `fiche-console-mwm.md` : notes de l'équipe sur le kit et sur la fiche à remplir dans la console MWM.
- `decisions-produit.md`, `app-privacy-answers.md`, `pitch-copy.md` : décisions produit, réponses de confidentialité et textes de pitch (ancien projet « Bredouille »).
- `02-marche-mwm-monetisation.md` : étude de la monétisation de MWM.
- `FORMULAIRE-candidature.md` et `BRIEF.md` : le dossier de candidature au Build Challenge.
- `call-mwm-29-oct.md` : la préparation de l'appel du 29 octobre.
- `mwm-ai-mcp-plugin-0.30.5.zip` : le plugin MCP fourni par MWM (documentation et commandes de leur console ; ne fonctionne qu'avec un accès MWM).

## 4. Ce qui n'existe QUE chez MWM (à exporter avant mercredi 28 octobre à 18 h)
Rien de tout cela n'est dans le dépôt, parce que c'est dans le compte de MWM :
1. **La fiche de l'app dans App Store Connect** : nom, sous-titre, mots-clés, description, texte promotionnel, URL de confidentialité et de conditions, catégorie, classification d'âge, captures d'écran, icône. Les versions que l'équipe a rédigées sont dans `store/` : comparer avec la fiche en ligne et copier ce qui en diffère.
2. **Les six produits d'abonnement** et leur groupe (noms affichés, localisations, prix par pays, durée d'essai).
3. **Les builds TestFlight** : supprimés, sans solution de sauvegarde. Tout se reconstruit depuis le code.
4. **Les résultats et réglages de la console MWM** (statistiques, document juridique publié, réglages de l'assistant). `store/mwm-resultats.md` contient ce qui a déjà été relevé.
5. **Les échanges avec MWM** (e-mails, fils de discussion) : exporter ou copier les messages utiles dans ce dossier.
6. **Les capacités du compte** (WeatherKit, iCloud, Push) : elles seront à recréer sur le nouvel identifiant, sous le nouveau compte.

## 5. Ce qui n'est volontairement PAS stocké ici
- Le mot de passe et l'identifiant du compte d'équipe de MWM, les clés du SDK de mesure : ils se trouvaient dans le README du kit, que Titouan garde en local (`Downloads\01.zip`). Ne pas les copier dans un dépôt. Ils ne serviront plus après le 28 octobre.
- Toute valeur de fichier `.env`.

## 6. À faire pour migrer vers le compte de Titouan (compte Apple Developer payant, 1 an)
- [ ] Sauvegarder la section 4 avant mercredi 18 h ; signaler à MWM tout blocage avant l'heure limite.
- [ ] Choisir le Bundle ID définitif et le remplacer dans le projet, le widget, `Config/*.entitlements`, `Config/*.plist` et le conteneur iCloud.
- [ ] Dans le nouveau compte : créer l'identifiant, activer iCloud (CloudKit), Push, WeatherKit et les groupes d'apps ; créer le conteneur.
- [ ] Recréer les six produits d'abonnement (ou ceux retenus) et mettre à jour `TestConfig.storekit` et `App/Abonnement/`.
- [ ] Déployer le schéma CloudKit (`outils/cloudkit/`) dans le nouveau conteneur, puis en production ; restreindre la lecture du type `Signalement` à l'équipe.
- [ ] Contrats, banque et fiscalité (Paid Apps Agreement) pour l'abonnement : prévoir plusieurs jours.
- [ ] Déclaration « professionnel » (DSA) pour la diffusion dans l'UE : à vérifier avec Apple.
- [ ] Rôles pour Adem et Sullyvan dans App Store Connect : à vérifier selon le type de compte.
- [ ] Décider si Spark Flash est conservé (les conditions du SDK, l'accès à la console de MWM, la mesure vide) : question à poser à MWM jeudi 29 octobre.
- [ ] Demander à MWM par écrit la validation du statut de lauréat et l'usage de leurs logos (le règlement du Build Challenge est introuvable).
