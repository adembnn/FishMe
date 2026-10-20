# Manifeste de confidentialité, « App Privacy » et âge : ce qui change avec le réseau social (S2)

**Brouillon, à faire relire par un juriste de MWM.** L'équipe n'est pas juridique. Écrit par S2 le 19 octobre 2026, mis à jour le même jour avec les décisions de Titouan (un surnom seulement, aucun nom ni prénom ; département par défaut ; photo importée de la galerie ; texte d'un message signalé transmis à l'équipe ; chats en zones partagées), pour A, qui pose les lignes dans `App/PrivacyInfo.xcprivacy` pendant L25 (vague 2) : S2 ne touche pas ce fichier. Remplace, pour le build qui porte le réseau, les réponses de `confidentialite-spark-flash.md` §2 et §3 (celles-ci restent justes pour le build du 16 octobre, sans réseau).

Règle d'Apple : on déclare ce qui quitte l'appareil et que le développeur ou un tiers peut lire. Elle est lue dans les pages « App privacy details » et « Privacy manifest files » d'Apple, mais **l'équipe n'a pas relu ces pages en entier** : tout ce qui est marqué ⚠ est à contrôler contre l'éditeur de manifeste d'Xcode (il propose la liste exacte des clés) et contre App Store Connect.

Source des données : `docs/reports/reseau/schema.md` (R2), décisions du 19 octobre (`CLAUDE.md`), `docs/legal/politique-confidentialite.md` (le même contenu, en phrases). Les trois (manifeste, étiquettes, politique) doivent dire la même chose : c'est le risque n° 5 de R2 (refus 5.1.2).

Mise à jour S2 du 20 octobre : (a) repères privés (coordonnées exactes des coins) sauvegardés dans l'iCloud privé chiffré du pêcheur, jamais partagés : base privée lisible par le seul pêcheur, donc non déclarée comme collectée (⚠ position à faire confirmer : voir `docs/legal/questions-juriste.md`, point 6) ; (b) carte de pêche importée : stockée sur l'iPhone, protégée, sauvegarde iPhone, aucun numéro ni nom lu : rien à déclarer, rien ne quitte l'appareil via FishMe ; (c) le type `Signalement` copie le texte du message signalé (500 caractères), lecture réservée à l'équipe : `EmailsOrTextMessages` reste déclaré.

## 1. `App/PrivacyInfo.xcprivacy` : ce que L25 change

Aujourd'hui le fichier déclare 7 types, tous non liés, dont `UserID` (finalités `AppFunctionality` et `Analytics`) : ce sont ceux du SDK Spark. `NSPrivacyTracking` est faux, `NSPrivacyTrackingDomains` est vide. Ces deux lignes ne changent pas.

| Type (clé `NSPrivacyCollectedDataType...`) | Action | `Linked` | `Tracking` | Finalités | Pourquoi |
|---|---|---|---|---|---|
| `UserID` | **passer `Linked` de faux à vrai** ; garder les finalités | vrai | faux | `AppFunctionality`, `Analytics` | le surnom (seule identité du profil, aucun nom ni prénom) et l'identifiant du profil (`recordName` CloudKit) identifient la personne dans la base publique ; Apple ne prend qu'une réponse par type |
| `PhotosorVideos` | **ajouter** | vrai | faux | `AppFunctionality` | photos et vidéos des publications, avatar, y compris une photo importée de la galerie (ré-encodée, sans GPS) |
| `OtherUserContent` | **ajouter** | vrai | faux | `AppFunctionality` | légendes, commentaires, likes, signalements, noms de club |
| `CoarseLocation` | **ajouter** | vrai | faux | `AppFunctionality` | le département (par défaut) ou le département et le cours d'eau, choisi à chaque publication ;  le tronçon du compteur de fréquentation. R2 range un département dans la localisation approximative d'Apple (⚠ non vérifié) |
| `EmailsOrTextMessages` | **ajouter** | vrai | faux | `AppFunctionality` | messages de club et d'amis (chat), dans des zones partagées, jamais en base publique. Le texte d'un message **signalé** est joint à l'e-mail de signalement et copié dans l'enregistrement `Signalement` : l'équipe peut donc le lire, ce qui est une collecte au sens d'Apple. À déclarer sans hésitation (⚠ le texte des messages non signalés reste illisible par l'équipe ; Apple ne propose pas de case « seulement si signalé », on déclare le type) |
| `PurchaseHistory`, `ProductInteraction`, `PerformanceData`, `CrashData`, `OtherDiagnosticData`, `DeviceID` | **inchangés** (Spark, non liés, `Analytics`) | faux | faux | inchangées | le manifeste déclare ce que l'app peut collecter : Spark ne collecte qu'après accord dans les Réglages, mais la déclaration reste |

Aucun type « Contact » (nom, e-mail, téléphone, adresse) : FishMe n'en reçoit aucun. Décision de Titouan du 19 octobre : le profil n'a qu'un surnom, **plus aucun nom ni prénom n'est demandé ni collecté** (donc pas de `Name`). ⚠ L'écran de réglages du profil (`ReglagesProfilView.swift:73-80`, L21) demande encore nom et prénom d'après la revue : à retirer par L21/A, sinon cette ligne devient fausse.

Lignes à ajouter dans le tableau `NSPrivacyCollectedDataTypes` (⚠ clés recopiées de R2 et de la mémoire de l'équipe, à contrôler dans l'éditeur d'Xcode ; l'ordre ne compte pas) :

```xml
<dict>
	<key>NSPrivacyCollectedDataType</key>
	<string>NSPrivacyCollectedDataTypePhotosorVideos</string>
	<key>NSPrivacyCollectedDataTypeLinked</key>
	<true/>
	<key>NSPrivacyCollectedDataTypeTracking</key>
	<false/>
	<key>NSPrivacyCollectedDataTypePurposes</key>
	<array>
		<string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
	</array>
</dict>
```

Même bloc, avec seulement la ligne `<string>NSPrivacyCollectedDataType...</string>` changée, pour `NSPrivacyCollectedDataTypeOtherUserContent`, `NSPrivacyCollectedDataTypeCoarseLocation` et `NSPrivacyCollectedDataTypeEmailsOrTextMessages`. Pour `UserID` : remplacer le `<false/>` qui suit `NSPrivacyCollectedDataTypeLinked` par `<true/>`.

Interfaces à justifier (`NSPrivacyAccessedAPITypes`) : rien de connu ne s'ajoute (`UserDefaults`, `CA92.1`, est déjà déclaré). ⚠ Un cache hors ligne (L23, L24) peut lire des dates de fichiers : lancer « Generate Privacy Report » sur l'archive finale (`docs/app-store.md`, ligne 19) et déclarer ce qu'il liste.

Le SDK a son propre `PrivacyInfo.xcprivacy` (⚠ question 2 à MWM) : celui de l'app doit s'accorder avec lui.

## 2. « App Privacy » (App Store Connect) : mêmes réponses

Questions d'ensemble :
- « Collectez-vous des données de cette app ? » **Oui** (avant le réseau c'était déjà oui, à cause de Spark).
- Suivi (ATT) : **non**, aucun suivi ; aucune publicité ; pas de partage avec des courtiers de données.
- URL de la politique de confidentialité : [URL publiée par MWM, jamais inventée]. Elle doit dire les mêmes choses que `docs/legal/politique-confidentialite.md`.

| Catégorie (libellé d'App Store Connect, à relire) | Type | Lié à l'identité | Suivi | Finalité | Quand |
|---|---|---|---|---|---|
| Contenu de l'utilisateur | Photos ou vidéos | **oui** | non | fonctionnalités de l'app | si le pêcheur publie ou choisit un avatar (y compris depuis sa galerie) |
| Contenu de l'utilisateur | Autre contenu d'utilisateur | **oui** | non | fonctionnalités de l'app | si le pêcheur publie, commente, aime, signale |
| Contenu de l'utilisateur | E-mails ou SMS (messages) | **oui** | non | fonctionnalités de l'app | si le pêcheur écrit à un ami ou dans un club ; texte d'un message signalé lu par l'équipe |
| Localisation | Localisation approximative | **oui** | non | fonctionnalités de l'app | département (par défaut) et cours d'eau (au choix) d'une publication ; tronçon du compteur de fréquentation ; ⚠ plus l'analyse (`Analytics`) si MWM confirme que Spark tire une position de l'adresse IP |
| Identifiants | Identifiant utilisateur | **oui** (changé : c'était non) | non | fonctionnalités de l'app et analyse | surnom du profil ; identifiant d'installation de Spark |
| Identifiants | Identifiant d'appareil | non | non | analyse | Spark, après accord seulement |
| Achats | Historique d'achats | non | non | fonctionnalités de l'app | Spark, après accord |
| Données d'utilisation | Interaction avec le produit | non | non | analyse | Spark, après accord |
| Diagnostics | Données de performance, données de plantage, autres données de diagnostic | non | non | analyse | Spark, après accord |
| Coordonnées (nom, e-mail, téléphone) | aucune : ni nom ni prénom, seulement un surnom | | | | |
| Données de santé, financières, contacts, historique de navigation, recherche | aucune | | | | |

Sur les lignes Spark, la case « collecté seulement après accord » n'existe pas dans le formulaire : on déclare le maximum. Photothèque : décision de Titouan du 19 octobre, l'import d'une photo depuis la galerie est autorisé (avatar et publication), sans GPS, ré-encodée. La ligne 8 de `docs/app-store.md` dit encore « pas d'import de photos » : à corriger par A (fichier hors du périmètre de S2). ⚠ A vérifie que l'import passe par le sélecteur système (aucune autorisation de lecture de la photothèque, aucune clé Info à ajouter) ; sinon une phrase d'usage de la photothèque s'ajoute dans `Info.plist`.

À contrôler avec MWM avant de cliquer (A, rôle App Manager) : `confidentialite-spark-flash.md` §4, questions 1 à 5 (liste de Spark, lien à l'identité).

## 3. Cohérence à vérifier avant l'envoi

| Ce que dit la politique | Manifeste | « App Privacy » |
|---|---|---|
| surnom, avatar, publications, commentaires, likes publics (§3) | `UserID`, `PhotosorVideos`, `OtherUserContent` liés | mêmes types, liés |
| lieu choisi par publication (§4) | `CoarseLocation` lié | Localisation approximative, liée |
| messages d'amis et de club (§2) | `EmailsOrTextMessages` | E-mails ou SMS |
| signalements : identifiant du contenu et de l'auteur, motif (§6) | `OtherUserContent`, `UserID` | idem |
| mesure d'usage dans les Réglages seulement, éteinte par défaut (§7) | 6 types Spark, non liés, `Analytics` | idem, non lié |
| aucun suivi, aucune publicité | `NSPrivacyTracking` faux | « Non » |
| ce qui ne part pas : position précise, carte de pêche, GPS des photos ; repères privés seulement vers l'iCloud privé du pêcheur (§5) | aucun type « Localisation précise » | aucune « Localisation précise » |

Une différence entre deux colonnes est un refus 5.1.2 probable : A relit ce tableau contre l'archive finale.

## 4. Questionnaire d'âge et classement (site d'App Store Connect)

Les réponses de `confidentialite-spark-flash.md` §3 changent : le réseau est du contenu d'utilisateur.
- Contenu généré par les utilisateurs : **oui**. Messagerie et chat entre utilisateurs : **oui**. Accès web sans restriction : non (aucun navigateur). Publicité : non. Jeux d'argent, armes, alcool, etc. : non.
- L'ancienne cible « 4+ » ne tient plus. ⚠ Le classement est calculé par Apple à partir des réponses ; l'équipe n'a pas relu la grille actuelle et ne sait pas si elle propose un palier « 15+ ». Le seuil de 15 ans de FishMe est une règle de l'app (CGU article 2, déclaration « J'ai 15 ans ou plus » avant le profil), pas le classement d'Apple. À rejouer sur le formulaire officiel et à noter ici : classement obtenu = [à lire].
- Ne pas cocher « Made for Kids » : le SDK Spark l'interdit sous 13 ans (`confidentialite-spark-flash.md` §3) et le réseau est réservé aux 15 ans et plus.

## 5. Règle 1.2 d'Apple (contenu d'utilisateur) : où chaque exigence est tenue

| Exigence | Où dans FishMe | Preuve à montrer au relecteur |
|---|---|---|
| Filtre | liste de mots LDNOOBW à la saisie (légende, commentaire, message, surnom, nom de club) ; ⚠ pas de filtre d'image | `notes-relecteur-reseau-en.md` |
| Signaler | menu « Signaler » sur chaque publication, commentaire, message, profil et carte de club ; e-mail préparé à fishme.app@gmail.com (envoyé par le pêcheur, pas automatique) et enregistrement `Signalement` en base ; pour un message d'ami ou de club, son texte est joint à l'e-mail et copié dans l'enregistrement | idem |
| Réponse rapide | CGU article 10 : retrait sous 24 heures des contenus publics (publications, commentaires, profils) signalés qui enfreignent les conditions et, pour les messages privés, des messages signalés dont le texte nous est transmis ; la boîte est lue par Titouan, Adem et Sullyvan, référent de la semaine à fixer par l'équipe | idem |
| Bloquer | « Bloquer » sur chaque contenu ; plus rien de la personne chez le pêcheur | idem |
| Contact publié | fishme.app@gmail.com dans les Réglages et les CGU | idem |
| Suppression du compte dans l'app (5.1.1) | « Supprimer mon profil » et « Supprimer mon compte et mes données iCloud » (⚠ libellés à relire dans le build) | idem |

## 6. Attribution de la liste de mots interdits (Profil, Sources)

À ajouter dans le texte de la page Sources de l'app (Profil, Sources ; `ReglagesView.swift:35`, qui ne cite aujourd'hui que l'OFB et Hub'Eau, d'après la revue) : la licence CC BY 4.0 impose l'attribution. Texte exact (vérifié le 20 octobre contre la page du dépôt : CC BY 4.0, © Shutterstock, Inc.) : `docs/legal/remplacements-app.md`, §12, à appliquer par L25.

## 7. Preuve que c'est posé

| Ce que A pose | Commit de L25 | Vérifié par |
|---|---|---|
| `PrivacyInfo.xcprivacy` : `UserID` lié + 4 types ajoutés | [à remplir par A] | « Generate Privacy Report » sur l'archive finale |
| « App Privacy » cliqué dans App Store Connect | sans objet (site) : date et nom de la personne qui a cliqué : [à remplir] | relecture du tableau §3 |
| questionnaire d'âge rejoué, classement noté | idem | §4 |
