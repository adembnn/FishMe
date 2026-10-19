# Risques App Review et étiquettes de confidentialité du réseau social
Décision débloquée : savoir si le réseau passe la relecture d'Apple (règles 1.2, 5.1.1, 5.1.2) et ce qu'il faut préparer avant L23 ; donne à S2 la liste des changements de `PrivacyInfo.xcprivacy` et d'« App Privacy ».
Lu le 19/10/2026 (règles : https://developer.apple.com/app-store/review/guidelines/ ; `App/PrivacyInfo.xcprivacy` ; `docs/reports/amis.md`). Aucune relecture n'a eu lieu : ce sont des risques lus, pas des refus constatés.

## En bref
Image : Apple est un inspecteur qui visite la place du village. Il vérifie trois portes : un bouton pour dénoncer et mettre dehors (1.2), une porte de sortie pour qui veut effacer son compte (5.1.1), et une affiche qui dit quelles données quittent la poche (5.1.2).

## 1.2 Contenu créé par les utilisateurs
Texte lu ([guidelines](https://developer.apple.com/app-store/review/guidelines/)) : filtre, signalement avec réponses rapides, blocage des abusifs, contact publié.
| Exigence | Où FishMe la tient | Risque | Parade |
|---|---|---|---|
| Filtre | liste de mots et motifs à la saisie (`moderation.md`) | un reviewer publie une insulte déguisée | tests de L23 ; réponse « filtre minimal + signalement » dans les notes |
| Signalement | menu sur publication, commentaire, message, profil, carte de club | un type de contenu sans bouton (le surnom, l'image de club) | liste de contrôle : un bouton par type, `/banc` |
| Réponse rapide | personne de garde, 24 h | boîte vide ou illisible quand le reviewer teste | une adresse qui répond ; réponse automatique ; nom de garde dans `moderation.md` |
| Blocage | « Bloquer l'auteur » sur chaque contenu | le blocage reste local (autre iPhone du même compte) | stocker `Blocage` en base privée (suit le compte, `schema.md`) |
| Contact | fishme.app@gmail.com dans les Réglages et les CGU | adresse non vérifiée par Apple | boîte vivante avant l'envoi |
Risque principal : le circuit de signalement envoie un e-mail **prérempli** que le pêcheur doit envoyer (`moderation.md`), et la personne de garde n'est pas nommée. Un reviewer qui signale et n'obtient aucune réponse peut refuser. Recommandation : nommer la garde, répondre aux signalements de la relecture, mettre un accusé de réception à l'écran ; change avec un budget : non.
⚠ Le texte lu ne cite pas de délai de 24 h. L'engagement est le nôtre.

## 5.1.1(v) Suppression du compte
Texte lu : « If your app supports account creation, you must also offer account deletion within the app » ([guidelines](https://developer.apple.com/app-store/review/guidelines/)).
- FishMe n'a ni mot de passe ni inscription ; la fiche amis disait « sans objet » (`docs/reports/amis.md`). Avec un surnom unique, un avatar et des publications, c'est un compte de fait ; ⚠ Apple ne l'a pas écrit. Traiter comme une obligation.
- La suppression existe déjà pour la sauvegarde et la zone partagée (`SauvegardeICloud.swift`, ligne « Suppression du compte »). Le réseau l'étend : `Profil`, avatar, `Publication`, `Commentaire`, `Like`, `MessageClub`, `Membre`, clubs fondés, `Blocage`, `ProfilPrive`.
- Risque : un enregistrement oublié. Parade : `EffaceurContenu` (L21) composé avec L22, L23 et L24 ; test sur le tableau de bord après suppression (fiches L21, L23). Un fondateur de club : le club et ses cartes disparaissent avec lui.
- Limite : la base publique n'efface que ce que le créateur peut supprimer ; les messages envoyés à un ami restent dans la zone partagée de l'ami tant que la zone n'est pas supprimée (à documenter dans les CGU).
Recommandation : le bouton « Supprimer mon profil » dans les Réglages, deux temps ; change avec un budget : non.

## 5.1.2 Données recueillies et partagées
Texte lu : pas d'usage, de transmission ni de partage de données personnelles sans permission, et information sur leur usage ; pas de réutilisation sans nouveau consentement (5.1.2(i) et (ii)) ([guidelines](https://developer.apple.com/app-store/review/guidelines/)).
| Donnée | Qui la voit | Risque | Parade |
|---|---|---|---|
| Surnom, avatar | tous | surnom = nom réel d'un tiers | règle de surnom dans les CGU ; signalement de profil |
| Photos, vidéos | tous (publication) | visage d'un tiers, mineur | motif de signalement ; mention dans l'écran de publication |
| Lieu choisi | tous | coin exact révélé par une légende | choix du pêcheur par publication ; filtre de coordonnées ; départements seulement indexés |
| Métadonnées (EXIF, GPS) | personne | fuite par un fichier brut | recompression, `exiftool` sur chaque média (fiche L23) |
| Nom, prénom | personne | écrits par erreur en base publique | base privée, test du tableau de bord (fiche L21) |
| Mesure d'usage (Spark de MWM) | un tiers : MWM | consentement obligatoire | uniquement dans les Réglages (décision 7) ; jamais dans le parcours |
- CloudKit appartient à Apple : ce n'est pas un tiers de la règle. Le tiers est le SDK Spark de MWM (consentement déjà géré par `App/Mesure/`).
- Le consentement du lieu est un choix de publication : le pêcheur le fait à chaque fois, donc la règle (ii) est respectée.
- Les clubs locaux qui passent en ligne exigent un consentement (`migration-clubs.md`).

## Manifeste `PrivacyInfo.xcprivacy` : ce qui change
Actuel : `PurchaseHistory`, `ProductInteraction`, `PerformanceData`, `CrashData`, `OtherDiagnosticData`, `UserID`, `DeviceID` ; `UserID` est déclaré non lié (`Linked` = faux) pour `AppFunctionality` et `Analytics`.
À ajouter ou à changer (S2, avec A, car le fichier est dans `App/`) :
| Type | Clé | Lié à l'identité | Finalité |
|---|---|---|---|
| Photos ou vidéos | `NSPrivacyCollectedDataTypePhotosorVideos` | oui | `AppFunctionality` |
| Autre contenu d'utilisateur | `NSPrivacyCollectedDataTypeOtherUserContent` | oui | `AppFunctionality` |
| Localisation approximative | `NSPrivacyCollectedDataTypeCoarseLocation` | oui | `AppFunctionality` |
| Identifiant utilisateur (surnom) | `NSPrivacyCollectedDataTypeUserID` | **oui** (au lieu de non) | `AppFunctionality` |
| Messages | `NSPrivacyCollectedDataTypeEmailsOrTextMessages` | oui | `AppFunctionality` |
⚠ Les clés viennent de ma mémoire et d'un résumé de la page Apple, non lue en entier ; à contrôler contre la page des types de données collectées dans Xcode (l'éditeur de manifeste propose la liste). Suivi (`NSPrivacyTracking`) reste faux.
Les catégories d'étiquette « App Privacy » (App Store Connect) correspondantes existent : Photos ou vidéos, autre contenu d'utilisateur, localisation approximative, identifiant utilisateur ([définitions](https://developer.apple.com/app-store/app-privacy-details/)). Le département d'une publication est une localisation approximative selon la définition d'Apple (moins précis que trois décimales). L'étiquette doit être **identique** à la politique de confidentialité et au manifeste (ligne 6 de `docs/app-store.md`). Change avec un budget : non.

## Notes pour la relecture d'Apple (App Review Notes)
À préparer par A et S2, avant l'envoi : comment signaler (chemin en 3 touchers), comment bloquer, où est le contact, l'engagement de retrait (24 h), que la collection n'est jamais publique, que le lieu est choisi par le pêcheur, qu'il n'y a aucune coordonnée. Un compte de démonstration n'est pas exigé (aucun mot de passe) ; ⚠ le reviewer a besoin d'un compte iCloud connecté pour publier : le dire. Change avec un budget : non.

## Risques résiduels classés
| # | Risque | Gravité | Qui |
|---|---|---|---|
| 1 | personne de garde non nommée | refus 1.2 | Adem |
| 2 | e-mail de signalement non automatique | refus possible | L23, Adem |
| 3 | un type de contenu sans bouton signaler | refus 1.2 | `/banc` |
| 4 | suppression qui oublie un type | refus 5.1.1 | L21 |
| 5 | manifeste et étiquette incohérents | refus 5.1.2 | S2, A |
| 6 | club local passé en ligne sans accord | plainte, 5.1.2(ii) | L22 |
| 7 | message de club lu par tous (décision 6) | plainte | Adem |

## Note à MWM : la mesure d'usage sera presque vide (décision 7)
Texte proposé pour S2 : « Le consentement à la mesure d'usage ne se demande plus dans le parcours de démarrage ; il se donne seulement dans les Réglages. Nous nous attendons donc à ce que presque aucune donnée Spark ne remonte pour FishMe. Ce n'est pas un défaut de l'intégration : c'est un choix de produit d'Adem, pour ne pas bloquer le parcours. » Change avec un budget : non ; un consentement dans le parcours changerait la mesure mais heurterait la décision 7. Écartée par Adem : un interrupteur dans l'écran du niveau.
