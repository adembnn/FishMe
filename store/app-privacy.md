# Manifeste de confidentialité, « App Privacy » et âge : ce qui change avec le réseau social (S2)

**Brouillon, à faire relire par un juriste de MWM.** L'équipe n'est pas juridique. Écrit par S2 le 19 octobre 2026 pour A, qui pose les lignes dans `App/PrivacyInfo.xcprivacy` pendant L25 (vague 2) : S2 ne touche pas ce fichier. Remplace, pour le build qui porte le réseau, les réponses de `confidentialite-spark-flash.md` §2 et §3 (celles-ci restent justes pour le build du 16 octobre, sans réseau).

Règle d'Apple : on déclare ce qui quitte l'appareil et que le développeur ou un tiers peut lire. Elle est lue dans les pages « App privacy details » et « Privacy manifest files » d'Apple, mais **l'équipe n'a pas relu ces pages en entier** : tout ce qui est marqué ⚠ est à contrôler contre l'éditeur de manifeste d'Xcode (il propose la liste exacte des clés) et contre App Store Connect.

Source des données : `docs/reports/reseau/schema.md` (R2), décisions du 19 octobre (`CLAUDE.md`), `docs/legal/politique-confidentialite.md` (le même contenu, en phrases). Les trois (manifeste, étiquettes, politique) doivent dire la même chose : c'est le risque n° 5 de R2 (refus 5.1.2).

## 1. `App/PrivacyInfo.xcprivacy` : ce que L25 change

Aujourd'hui le fichier déclare 7 types, tous non liés, dont `UserID` (finalités `AppFunctionality` et `Analytics`) : ce sont ceux du SDK Spark. `NSPrivacyTracking` est faux, `NSPrivacyTrackingDomains` est vide. Ces deux lignes ne changent pas.

| Type (clé `NSPrivacyCollectedDataType...`) | Action | `Linked` | `Tracking` | Finalités | Pourquoi |
|---|---|---|---|---|---|
| `UserID` | **passer `Linked` de faux à vrai** ; garder les finalités | vrai | faux | `AppFunctionality`, `Analytics` | le surnom et l'identifiant du profil (`recordName` CloudKit) identifient la personne dans la base publique ; Apple ne prend qu'une réponse par type |
| `PhotosorVideos` | **ajouter** | vrai | faux | `AppFunctionality` | photos et vidéos des publications, avatar |
| `OtherUserContent` | **ajouter** | vrai | faux | `AppFunctionality` | légendes, commentaires, likes, signalements, noms de club |
| `CoarseLocation` | **ajouter** | vrai | faux | `AppFunctionality` | le département (et le cours d'eau) choisi à chaque publication ; le tronçon du compteur de fréquentation. R2 range un département dans la localisation approximative d'Apple (⚠ non vérifié) |
| `EmailsOrTextMessages` | **ajouter** | vrai | faux | `AppFunctionality` | messages de club et d'amis (chat). ⚠ Si ces messages restent dans des zones partagées illisibles par l'équipe, Apple peut les juger « non collectés » ; par prudence on les déclare (déclarer trop coûte moins cher qu'un refus 5.1.2) |
| `PurchaseHistory`, `ProductInteraction`, `PerformanceData`, `CrashData`, `OtherDiagnosticData`, `DeviceID` | **inchangés** (Spark, non liés, `Analytics`) | faux | faux | inchangées | le manifeste déclare ce que l'app peut collecter : Spark ne collecte qu'après accord dans les Réglages, mais la déclaration reste |

Aucun type « Contact » (nom, e-mail, téléphone, adresse) : FishMe n'en reçoit aucun. Le nom et le prénom facultatifs vivent dans la base privée du pêcheur, que l'équipe ne lit pas (⚠ à confirmer avec L21 : si un jour ils passent en base publique, il faudra déclarer `Name`).

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
| Contenu de l'utilisateur | Photos ou vidéos | **oui** | non | fonctionnalités de l'app | si le pêcheur publie ou choisit un avatar |
| Contenu de l'utilisateur | Autre contenu d'utilisateur | **oui** | non | fonctionnalités de l'app | si le pêcheur publie, commente, aime, signale |
| Contenu de l'utilisateur | E-mails ou SMS (messages) | **oui** | non | fonctionnalités de l'app | si le pêcheur écrit à un ami ou dans un club |
| Localisation | Localisation approximative | **oui** | non | fonctionnalités de l'app | département et cours d'eau d'une publication ; tronçon du compteur de fréquentation ; ⚠ plus l'analyse (`Analytics`) si MWM confirme que Spark tire une position de l'adresse IP |
| Identifiants | Identifiant utilisateur | **oui** (changé : c'était non) | non | fonctionnalités de l'app et analyse | surnom du profil ; identifiant d'installation de Spark |
| Identifiants | Identifiant d'appareil | non | non | analyse | Spark, après accord seulement |
| Achats | Historique d'achats | non | non | fonctionnalités de l'app | Spark, après accord |
| Données d'utilisation | Interaction avec le produit | non | non | analyse | Spark, après accord |
| Diagnostics | Données de performance, données de plantage, autres données de diagnostic | non | non | analyse | Spark, après accord |
| Coordonnées (nom, e-mail, téléphone) | aucune | | | | |
| Données de santé, financières, contacts, historique de navigation, recherche | aucune | | | | |

Sur les lignes Spark, la case « collecté seulement après accord » n'existe pas dans le formulaire : on déclare le maximum. Photothèque : la ligne 8 de `docs/app-store.md` dit « pas d'import de photos ». ⚠ La fiche L21 ajoute un avatar choisi dans la galerie : A vérifie qu'il passe par le sélecteur système (aucune autorisation de lecture de la photothèque, aucune clé Info à ajouter) et corrige la ligne 8.

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
| ce qui ne part jamais : position précise, GPS des photos (§5) | aucun type « Localisation précise » | aucune « Localisation précise » |

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
| Signaler | menu « Signaler » sur chaque publication, commentaire, message, profil et carte de club ; e-mail préparé à fishme.app@gmail.com et enregistrement `Signalement` | idem |
| Réponse rapide | CGU article 10 : retrait sous 24 heures d'un contenu signalé qui enfreint les conditions ; un référent par semaine lit la boîte | idem |
| Bloquer | « Bloquer » sur chaque contenu ; plus rien de la personne chez le pêcheur | idem |
| Contact publié | fishme.app@gmail.com dans les Réglages et les CGU | idem |
| Suppression du compte dans l'app (5.1.1) | « Supprimer mon profil » et « Supprimer mon compte et mes données iCloud » (⚠ libellés à relire dans le build) | idem |

## 6. Attribution de la liste de mots interdits (Profil, Sources)

À ajouter par le lot qui possède la page Sources (CC BY 4.0 impose l'attribution). Texte proposé, ⚠ à vérifier contre le dépôt d'origine (auteur à nommer exactement, modifications à décrire) quand L23 aura lu la liste :

« Filtre de mots : liste « List of Dirty, Naughty, Obscene, and Otherwise Bad Words » (LDNOOBW), licence Creative Commons Attribution 4.0 (CC BY 4.0), https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words — adaptée pour FishMe : [mots retirés ou ajoutés, à décrire par L23]. Licence : https://creativecommons.org/licenses/by/4.0/ »

## 7. Preuve que c'est posé

| Ce que A pose | Commit de L25 | Vérifié par |
|---|---|---|
| `PrivacyInfo.xcprivacy` : `UserID` lié + 4 types ajoutés | [à remplir par A] | « Generate Privacy Report » sur l'archive finale |
| « App Privacy » cliqué dans App Store Connect | sans objet (site) : date et nom de la personne qui a cliqué : [à remplir] | relecture du tableau §3 |
| questionnaire d'âge rejoué, classement noté | idem | §4 |
