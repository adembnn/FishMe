# Réponses « App Privacy » (étiquettes de confidentialité), justifiées

Légende : **[F]** fait, **[I]** hypothèse, **⚠** non vérifié. Les noms exacts des écrans et des cases d'App Store Connect changent : relire à la saisie. Ces réponses valent **pour le code décrit par CLAUDE.md (règles 7, 8, 10)** ; elles sont fausses dès qu'un SDK d'analyse, de pub, de crash ou un serveur est ajouté. Avant de répondre : lancer une recherche dans le dépôt (`grep -ri "firebase\|amplitude\|sentry\|analytics\|URLSession"`) et confirmer que rien ne sort de l'appareil.

## Principe de la définition d'Apple ⚠
Apple appelle « collecter » une donnée **transmise hors de l'appareil** de façon à être conservée plus longtemps que nécessaire au traitement de la requête, par toi ou un partenaire tiers. Une donnée uniquement traitée et stockée sur l'iPhone n'est pas « collectée » [I, à relire sur la page Apple « App privacy details » avant de répondre].

## Réponse globale
**Question « Collectez-vous des données de cette app ? » → Non, nous ne collectons aucune donnée.**
Résultat attendu sur la fiche : « Aucune donnée collectée » (Data Not Collected).
URL de la politique de confidentialité : `[URL_POLITIQUE]` (privacy-policy-fr.md). Pas d'URL « options de confidentialité de l'utilisateur » (facultative, sans objet).

## Justification type de donnée par type

| Type Apple | Réponse | Pourquoi |
|---|---|---|
| Coordonnées (nom, e-mail, téléphone, adresse) | Non collecté | Aucun compte, aucun formulaire. |
| Santé et forme | Non | Sans objet. |
| Informations financières | Non | Le paiement passe par Apple (StoreKit). L'app ne voit jamais de carte bancaire. |
| **Localisation : position précise** | Non collecté | Jamais demandée en précis comme donnée conservée : la position ponctuelle sert à calculer un code de département sur l'appareil, puis est jetée. |
| **Localisation : position approximative** | **Non collecté** | Position approximative utilisée une fois, sur l'appareil, pour déduire le département. Seul le code département reste, sur l'appareil. Rien n'est transmis. Si un jour la position part vers un serveur (même ponctuellement), cocher « Localisation approximative » et revoir tout ce fichier. |
| Informations sensibles | Non | Sans objet. |
| Contacts | Non | Aucune permission contacts. |
| Contenu de l'utilisateur : **photos ou vidéos** | **Non collecté** | Photos prises ou choisies, traitées et stockées uniquement sur l'iPhone. Foundation Models / Core ML / Vision tournent sur l'appareil [I, à confirmer au code : aucune requête réseau envoyant l'image]. |
| Contenu de l'utilisateur : autre (taille, notes) | Non collecté | Idem, local. |
| Historique de navigation, de recherche | Non | Sans objet. |
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
[ligne retirée : mention d'identifiants ou de secret, voir le fichier d'origine en local]
| **Données d'usage** (interactions produit, publicité) | Non collecté | Aucune analyse, aucune publicité. |
| **Diagnostics** (plantages, performances) | Non collecté **par nous** | Les rapports de plantage que l'utilisateur partage avec Apple via TestFlight/Xcode Organizer sont gérés par Apple, pas collectés par l'app [I ⚠]. Aucun SDK de rapports de plantage. |
| Autres données | Non | |

## Suivi (tracking)
- **Non, l'app ne suit pas les utilisateurs** entre apps et sites. Aucune demande d'autorisation de suivi : ne pas ajouter `NSUserTrackingUsageDescription` (règle 7 du CLAUDE.md).
- Aucune donnée liée à l'utilisateur ; aucune donnée liée à l'identité.

## Cohérences à vérifier avant de cliquer
1. **Info.plist** : seulement `NSCameraUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSLocationWhenInUseUsageDescription`. Aucune clé « Always », ni contacts, ni micro, ni suivi (peche/07 §3).
2. **Manifeste de confidentialité** (`PrivacyInfo.xcprivacy`) présent : déclare `NSPrivacyTracking` à faux, aucun domaine de suivi, aucune donnée collectée, et les « API à raison requise » réellement utilisées (par exemple `UserDefaults`, horodatages de fichiers) avec leur code de raison ⚠. Apple peut rejeter à l'upload si une API à raison requise est utilisée sans déclaration ⚠.
3. **Aucun SDK** tiers dans `project.yml` (ni MWM, ni analytics, ni pub). Si le SDK MWM était branché plus tard, ces réponses, la politique et l'ATT seraient à refaire (peche/07 §3).
4. **Réseau** : le cœur fonctionne en mode avion (règle 8). La carte des relevés, si publiée, charge les fonds de plan Apple Plans : MapKit n'est pas une collecte par l'éditeur [I ⚠], mais la politique doit le dire (déjà prévu).
5. **Sauvegarde iCloud** de l'appareil : gérée par l'utilisateur et Apple, pas une collecte par l'éditeur [I]. Si une « synchronisation iCloud » (CloudKit) est ajoutée en V2, ré-évaluer : les données seraient stockées chez Apple pour l'utilisateur, la qualification « collecte » est à relire ⚠.
6. La politique en ligne et ces réponses disent la même chose (« tout reste sur l'appareil »). Une divergence est un motif classique de rejet 5.1.1.

## Questionnaire d'âge : voir age-rating-answers.md. Chiffrement : voir export-compliance.md.
