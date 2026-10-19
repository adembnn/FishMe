# Passation de Titouan à Adem et Sullyvan : lots du 19 octobre (rôle B)

Écrit le 19 octobre 2026 par Titouan (avec ses agents Claude). Titouan n'a pas de Mac : **tout le Swift ci-dessous a été écrit sans compilateur**. Rien n'est compilé, aucun test n'est exécuté, rien n'est testé sur iPhone. Sullyvan compile et teste (répartition du 19 octobre, option C), Adem tranche et branche (L25).

## 0 bis. Mise à jour de la nuit du 19 octobre : à lire avant tout le reste (les hashes de ci-dessous et du tableau 1 sont remplacés par ceux-ci)

**État en une phrase :** huit branches de lots corrigées après revue, six nouvelles fonctions (N1 à N6) écrites sans Mac, une fusion simulée de tout sans conflit, et **508 tests du paquet `Packages/Core` exécutés et passés dans Docker (Swift 6.0 sous Linux)** sur cette fusion. **Le code de `App/` n'est ni compilé ni exécuté nulle part** : c'est le travail de Sullyvan (compiler, tests d'app et d'interface) et d'Adem (branchement L25).

### Branches et derniers commits (aucune n'est poussée au moment de l'écriture, sauf indication)
| Branche | Commit | Contenu |
|---|---|---|
| `lot/core-moderation` | `0c0cbc0b` | mots interdits (pluriels et accords ajoutés), 13 régions. **À fusionner en premier.** |
| `lot/profil` (L21) | `ce375b46` | corrections de revue : id ASCII, reprise de profil, plus de nom ni prénom, case des conditions, signalement honnête, `ListeBlocages`, type public `ProfilPublic` |
| `lot/collection-2` (L18) | `fc713db4` | inchangé sur le fond |
| `lot/prise-2` (L19) | `0d69c4ea` | inchangé sur le fond |
| `lot/feed` (L23) | `e4bc24e9` | mode démo Release, lieu par défaut au département seul, signalement honnête et file de reprise, vidéo sans GPS contrôlée, pagination |
| `lot/chat` (L24) | `9b7e2a96` | un créateur de zone par paire, abonnements aux deux bases, file de messages, stockage protégé, mode démo Release ; trois types renommés (`ResultatSignalementMessage`, `SignalementMessageEnAttente`, `DonneesExempleChat`) |
| `lot/rapport-reseau` (R2) | `0a055da4` | schéma réseau (11 types, chat en zones partagées) |
| `lot/store-2` (S2) | `cf8df9a2` | notes du relecteur, App Privacy |
| `lot/hubeau-d5` (D5) | `733ee94c` | prototype de recalage ; la mesure sur toute la France n'était pas terminée à l'écriture |
| `lot/n1` | `36eeb7f8` | skins d'aquarium |
| `lot/n2` | `4f455b2c` | liste d'envies (sans les accroches Pescedex et sauvegarde) |
| `lot/n3` | `891484b3` | pression et mesures de l'eau (sans les alertes N3b) |
| `lot/n4` | `274c3b37` | records et statistiques |
| `lot/n5` | `eb21b0a0` | Ma fédération, carte de pêche, numéros utiles |
| `lot/n6` | `7f02a1b3` | repères privés |
| `titouan/fiches-backlog` | `81c7fd72` | fiches N1 à N6 et `docs/reports/sullyvan-sans-compiler.md` |

### Ordre de fusion
`lot/core-moderation`, `lot/profil`, **puis les alignements** (voir `docs/reports/alignement-fusion.md` sur cette même branche : `EffaceurFeed` et `EffaceurChat` adoptent `EffaceurContenu`, les deux motifs deviennent des `typealias` de `MotifSignalement`, `AnnuaireChat.bloques()` lit `ListeBlocages.partage`), `lot/collection-2`, `lot/prise-2` (avant L17), `lot/feed`, `lot/chat`, puis `lot/n1` à `lot/n6` (N6 après L17 et L19). La simulation complète (core, profil, collection-2, prise-2, feed, chat, n1 à n6) se fusionne **sans conflit** et les 508 tests Core passent.

### Ce qui a été vérifié, et ce qui ne l'a pas été
- **Exécuté :** `swift test` dans `Packages/Core` (image `swift:6.0`) : 508 tests passés sur la fusion ; un test déjà sauté sur main (liste des 23 espèces « courant »). Ces essais ont trouvé et fait corriger quatre erreurs dans des tests écrits à l'aveugle (N1, N2, N4, N5) ; elles sont corrigées sur les branches.
- **Non exécuté :** tout `App/`, `AppTests/`, `AppUITests/`. Chaque branche liste ses points `// ⚠ à vérifier`. Sullyvan : `scripts/verif.sh`, tests d'app, `/ecran`, `/banc`.

### Avertissements à lire avant de brancher
1. **Droits de lecture du type `Signalement`** (base publique) : le texte du message signalé y est copié (500 caractères). Restreindre la lecture à l'équipe dans la console CloudKit, et l'écrire dans la politique de confidentialité et les CGU art. 8.
2. **`creeLe` doit être interrogeable ET triable** (Publication, Commentaire) ; `schema.md` de R2 lignes 28 et 39 à corriger. Index aussi sur `ProfilPublic.recordName`, `surnomNorm` et le champ système `createdBy`. Types à créer : `Signalement`, `Repere`, `PhotoRepere`.
3. **Nom et prénom ne sont plus collectés** : `ProfilEmplacement` collecte encore `profil.nom`, à remplacer par le surnom (L25).
4. **Chat** : adaptateur de scène à brancher (code fourni dans le rapport de L24), `aps-environment` et `UIBackgroundModes = remote-notification`, mode démo `GestionChat.exemple()` quand pas d'iCloud.
5. **Bug hors périmètre** : `MoteurCore.lireLiens` lit les clés `federation` et `carte`, alors que `liens-federations.json` contient `federation_url` et `carte_peche_url`. N5 a sa propre lecture correcte.
6. **Textes faux à remplacer dans `App/`** (liste dans le rapport S2) : `TexteConditions` (à régénérer avec `python3 outils/legal/generer_conditions.py`), `ConfidentialiteView`, `RootView.swift:1209`.
7. **Attribution CC-BY-4.0** de la liste de mots interdits à ajouter dans Profil, Sources (texte plus bas).

### Décisions qui reviennent à Adem
- **N6 :** les coordonnées exactes des repères vont dans l'iCloud privé chiffré du pêcheur ; la phrase de `CLAUDE.md` « aucun coin de pêche exact ne quitte l'iPhone » est à réécrire. Refus : supprimer `App/Reperes/SauvegardeReperes.swift`.
- **N1 :** décor de départ (rivière, étang ou grotte) ; aucune illustration de skin n'existe, la galerie masque ceux sans image, seule « Rivière » s'affiche.
- **N2 :** exposer la date de réouverture côté Core, sinon « Fermée ce jour ».
- **N3 :** seuils (±2 hPa sur 6 h, ±0,5 °C sur 24 h, ±5 % sur 6 h), alertes N3b en lot séparé, `stations-temperature.json` à fournir par D2, licence Hub'Eau de la température non lue.
- **N4 :** seuil du badge Trophée au 95e centile (40 espèces sur 76), records gratuits et séparés de « Mes statistiques ».
- **N5 :** phrase exacte sur les règles locales (provisoire dans `TextesMaFederation.reglesLocales`), source du geste de mesure inconnue, numéros 112, 18, 15 puis 17 et 114.
- Déjà listées plus bas : 55 cm du brochet, pastille orange à 65 cm, « règle lue » au lieu de « respectée », signalement, mode démo de S2 vrai seulement si L25 l'étend.

### Demandes à L25 (Adem)
Brancher dans `RootView.swift` et `BuildChallengeApp.swift` : effaceurs (`RegistreEffaceurs`), mode démo Feed et Chat, skins (`ContexteSkin`, `SkinsGalerieView`), « Mes records » et l'appel de `MoteurRecords.evenement` avant l'insertion de carte, bloc `MesuresSourceesView`, envies, repères (9 accroches dans `App/Reperes/LISEZMOI.md`). Ajouter N1 à N6 à `docs/lots.md` et `scripts/lot.sh`, les nouveaux dossiers aux cibles Xcode, déclarer `stations-temperature.json` dans `donnees.sh`. Les demandes détaillées de chaque lot sont dans son dernier commit et dans sa fiche `docs/fiches/N*.md`.

## 0. Mise à jour du 19 octobre (soir) : à lire d'abord
- **Nouvelle branche `lot/core-moderation` (1996a575)** : dans `Packages/Core`, la **liste de mots interdits complète** (`Moderation/MotsInterditsFR.swift`, LDNOOBW CC-BY-4.0, **sans** les faux positifs de pêche : tanche, bite, gueule, turlutte, pédale, gerbe…) et la **table des 13 régions** (`Regions/RegionsFrance.swift`, 96 départements, vérifiée). Tests écrits, non exécutés. **À fusionner EN PREMIER** : L21, L23 et L24 en dépendent maintenant.
- **L21, L23 et L24 utilisent cette liste unique** (un seul `MotsInterditsFR.contient(...)`), ce qui règle les trois filtres en double. Hash : `lot/profil` 6f07d28b, `lot/feed` 55401bdb, `lot/chat` d050acfe. Un bug de l'ancienne liste de L23 est supprimé : elle réduisait les lettres doubles des deux côtés, donc « coule » (l'eau) était refusé comme « couille ».
- **Ordre de fusion conseillé** : `lot/core-moderation`, puis `lot/profil`, `lot/collection-2`, `lot/prise-2`, `lot/feed`, `lot/chat`. Simulé dans une copie de `main` : aucun conflit de texte, aucune collision de type.
- **Collisions de noms corrigées** : `MotifSignalement` (défini trois fois) renommé `MotifSignalementPublication` (L23) et `MotifSignalementMessage` (L24) ; `LigneRegleView` de L19 renommé `LigneRegleBlocView`. `lot/prise-2` est maintenant à 7758521e.
- **Régions** : `RegionsFrance.region(deDepartement:)` et `departementsDeLaRegion(de:)` donnent à A de quoi brancher `regionDe:` (L18) et `departementsDeMaRegion` (L23) sans écrire la table.
- **Attribution à ajouter dans Profil, Sources** (CC-BY-4.0) : « Liste de mots interdits : LDNOOBW, https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words ».
- **Amis** : retirés du Pescedex (L18) ; ils ne vivent que dans Communauté. Il reste dans `PescedexView` un paramètre `voirAmis` inutilisé, conservé pour que l'appel actuel de `RootView` compile ; A le retire avec L25.

## 1. Ce qui est livré : six branches, toutes issues de `origin/main` du 19 octobre
| Lot | Branche | Dernier commit | Commits | Contenu |
|---|---|---|---|---|
| L18 Pescedex direct | `lot/collection-2` | `fbb6dfc6` | 6 | grille « Déclarer un poisson déjà pêché » avec recherche, plus d'« Amis » dans le Pescedex, photo en 1 toucher, « Enregistrer dans Photos » sans GPS, libellés en toutes lettres, menu de zone Mon spot / Ma région / France |
| L19 Prise | `lot/prise-2` | `7758521e` | 7 | caméra visible d'emblée, vue de capture maison, carte retournable puis bloc de règles à deux états avec sources (`App/Style/BlocRegles/`) |
| R2 Rapport réseau social | `lot/rapport-reseau` | `638d751a` | 13 | 8 fichiers `docs/reports/reseau/`, prototype CloudKit `outils/reseau/` pour Sullyvan |
| L21 Profil et amis | `lot/profil` | `6f07d28b` | 6 | surnom unique et avatar, recherche en 3 lettres, « Finis ton profil », suppression, signaler et bloquer un profil, déclaration « 15 ans ou plus » |
| L23 Feed | `lot/feed` | `55401bdb` | 8 | publier photo ou vidéo de 15 s sans GPS, lieu au choix, fil clubs / amis / région, likes, commentaires, signalement, blocage |
| L24 Chat | `lot/chat` | `d050acfe` | 8 | chat d'amis et de club, notifications au premier message, signalement, blocage |

Les branches sont **indépendantes** : aucune ne contient le travail des autres. Elles touchent des dossiers différents (périmètre vérifié par `git diff --name-only origin/main` pour chacune), sauf `App/Amis/` (L21 modifie des fichiers de L8, voir 4).

## 2. Décisions de Titouan (19 octobre) à valider
1. **Le réseau social est gratuit** : rien n'est derrière le Pro (feed, chat, profil).
2. **15 ans minimum** pour avoir un profil public, publier, commenter ou écrire : déclaration simple « J'ai 15 ans ou plus », sans date de naissance stockée. En dessous, le feed et le chat sont en lecture seule ; collection, règles et carte restent utilisables. À faire relire par un juriste de MWM ; l'outil Declared Age Range d'Apple n'a pas été étudié ⚠.
3. **« Aucun lieu »** : une publication sans lieu n'apparaît pas dans « Dans ta région » (visible des amis et clubs seulement).
4. **Chat d'un club réservé aux membres** (pas de base publique lisible avec le lien).
5. **Signalement** : e-mail pré-rempli (`mailto:` vers fishme.app@gmail.com) **et** enregistrement `Signalement` en base publique, lu par la personne de garde ; contenu masqué tout de suite sur l'iPhone qui signale. Sans serveur, l'e-mail n'est pas automatique : un vrai envoi automatique demande un petit service payant (budget : oui).
6. **Qui lit fishme.app@gmail.com** : Titouan, Adem et Sullyvan. **Proposition** : un référent par semaine, à tour de rôle, qui regarde la boîte et la liste des `Signalement` chaque jour, retrait ou masquage dans les 24 heures ; un prénom de référent écrit dans les CGU. L'ordre des semaines est à fixer par l'équipe.
7. Rappel : la décision 1 du 19 octobre (réseau social complet, remplace « collections jamais publiques ») est celle d'Adem ; Titouan souhaitait en reparler. Les remarques du Notion demandent la même chose.

## 3. À brancher par Adem (L25), tout regroupé
**`RootView.swift` et projet**
- L21 : `CommunauteView{…}.finisTonProfil()` (autour de la ligne 909) ; dans `ouvrir(url:)`, pour l'hôte `ami` : `RelaisLienAmi.partage.recevoir(url)` puis onglet Communauté.
- L23 : `CommunauteView(fil: FeedVue(gestion: GestionFeed.reel(source: …)))` avec une implémentation de `SourceContexte` branchée sur L21, L22 et le spot ; bouton « Publier » sur une carte du Pescedex avec `ContexteLieu(lieuFlou:, typeEau:)` (sans le vrai type d'eau, le choix « cours d'eau » n'est jamais proposé).
- L24 : `ListeConversationsView` dans Communauté ; `BoutonEcrire` et `ConversationView` sur les pages ami et club ; `registerForRemoteNotifications()` au lancement ; `didReceiveRemoteNotification` vers `GestionChat.traiterNotificationCloudKit()` ; router les liens de conversation vers `GestionChat.accepter(...)` dans `RelaisInvitations`.
- L18 : retirer `declarer: { app.montrer(.tunnel) }` et `voirAmis` (facultatif) ; `regionDe:` sur `PescedexModele`, qui demande une **table des 13 régions dans Core** (nom, locution « en Île-de-France », départements) que personne n'a écrite.
- Effacement : composer `EffaceurContenu` (défini par L21) avec ceux de L23 (`effacerMesContenus`) et L24 (`EffaceurChat`) via `RegistreEffaceurs.partage.ajouter(...)`.
- Vérifier que le projet Xcode prend les nouveaux dossiers (dossiers synchronisés) et que le contrôle de frontières de `scripts/verif.sh` accepte `App/Style/BlocRegles/` (sinon choisir un autre emplacement).

**Capacités et `Info.plist`** : Push Notifications ; iCloud / CloudKit base publique ; accès photothèque (`PhotosPicker`). Pour L18, rien à ajouter (les deux clés existent).

**Tableau de bord CloudKit (à créer avant la production)**
- Types en base publique : `Profil`, `Publication`, `Like`, `Commentaire`, `Signalement` ; types de chat par zone partagée.
- `Blocage` : base privée (recommandation R2) ; aujourd'hui L21 filtre en local (`UserDefaults`).
- Index : `surnomNorm` queryable (recherche `BEGINSWITH`), `creeLe` sortable, `club`, `auteurNom`, `departement`, `publication` queryable, `recordName` queryable sur `MessageAmi` et `MessageClub`.
- Droits : « World lit, Authenticated crée » sur `Profil` et `Signalement` ; lecture de `Signalement` réservée à l'équipe ; déployer le schéma en Production.

## 4. Conflits et alignements à prévoir à la fusion
- **L21 modifie `App/Amis/`** (`AmisPageView`, `AmisView`, `GestionAmis`, `RelaisInvitations`, `ServiceAmis`, `ServiceAmisCloudKit`, `Signalement`). L24 ajoute un routage dans `RelaisInvitations` (à faire par A). Fusionner L21 avant L24.
- **Liste de mots interdits** : unifiée dans `Core` (voir 0). `AucunFiltre` (L21) ne sert plus que pour les tests et aperçus.
- **Protocoles marqués `À aligner L21`, `À aligner L22`** : `SourceContexte` (L23), `AnnuaireChat`, `InterlocuteurChat`, `ClubChat`, `EffaceurMessages` (L24). Ils attendent les types réels de L21 (profil) et L22 (clubs, lot d'Adem). `Club.fondateur` et `Membre.profil` doivent contenir l'identifiant `p-<surnom normalisé>` de `ProfilModele.id`.
- **Repères `// R2:`** dans le code : endroits à réaligner une fois R2 validé.

## 5. Écarts avec le plan, la fiche ou R2 (à trancher par Adem)
- **L21** : « Inviter » depuis un profil partage **ma** collection (`ShareLink`, L8) ; CloudKit ne peut pas pousser une invitation à quelqu'un à partir de son surnom. Pour que les cartes de A arrivent chez B, A accepte puis touche « Inviter en retour ». Cibler par surnom demande un type `DemandeAmi`, absent de R2. Le test d'acceptation de la fiche ne tient donc pas tel quel.
- **L21** : nom et prénom sont dans `UserDefaults` (`IdentitePriveeLocale`) ; `ProfilPrive` (zone « Sauvegarde », `App/Compte/`) à brancher. Un iPhone neuf ne retrouve pas son profil (il recevrait « surnom pris »).
- **L24** : les messages d'amis ne passent **pas** par la zone « Pescedex » de L21 (lisibles par tous les amis invités) mais par une zone partagée par paire d'amis, ce qui oblige l'ami à accepter un lien une fois. Abonnements par zone (`CKRecordZoneSubscription`) au lieu de `CKDatabaseSubscription`.
- **L24 (club)** : une zone partagée par club, possédée par le fondateur. Limites : seul le fondateur admet des membres (il doit ouvrir l'app, le membre doit accepter) ; fondateur parti = plus d'admission (la fiche L22 prévoit un transfert de rôle, impossible ici) ; plafond de participants d'un `CKShare` (environ 100, non lu) ; retirer un membre ne lui retire pas l'accès. Le texte d'un message d'ami signalé est joint à l'e-mail (l'équipe ne peut pas lire une zone privée) : à confirmer côté vie privée.
- **L23** : la vignette de 640 px existe aussi pour les photos (le schéma la réserve à la vidéo) ; « Tes clubs » filtre sur le champ `club` de la publication, pas sur les membres ; « Dans ta région » n'utilise que les départements fournis par la source (pas de table département vers région).
- **L19** : le groupe « Horaires » est masqué pour le brochet (pas de ligne de nuit dans Core), donc **deux groupes au lieu de trois** pour le cas 65 cm ; les lignes « autre » (espèce protégée) vont dans « Garder ou relâcher » ; la pastille orange suit toute ligne « à vérifier », réserve du 94 comprise ; **l'import depuis la galerie contredit l'ancienne règle « une carte ne naît que d'une photo prise »** (la fiche le demande, à confirmer) ; l'écran d'explication de permission peut déborder à AX5 (hors périmètre).
- **L18** : « Ma région » est grisé tant que `regionDe:` n'est pas fourni ; la photo qui rétrécit au début de la révélation est gardée (`photoRetrecitAuDepart = false` pour l'enlever) ; un PNG ajouté à Photos en `.photo` est à vérifier sur iPhone.
- **R2** : un « retrait sous 24 h » est notre engagement, la règle 1.2 lue ne donne aucun délai chiffré ; l'exclusion d'un auteur est impossible sans serveur (il peut recréer un surnom) ; `CartePartageeClub` de L22 est un 10e type, à replier dans `Publication` avec un champ `club`.

## 6. Questions ouvertes pour Adem (reprises de `docs/reports/reseau/decisions.md`)
1. Le nom du référent par semaine (voir 2.6) et son suppléant.
2. Une publication « aucun lieu » dans le fil de région : décision de Titouan = non (appliquée dans L23).
3. `Blocage` en base privée plutôt que publique : d'accord ?
4. Des testeurs externes ont-ils des clubs locaux ? Sinon la migration de L22 devient « recréer son club ».
5. Âge minimal 15 ans : confirmé par le juridique ?
6. Chat de club avec les limites du 5 : acceptable pour une première version ?
7. Budget pour un e-mail de signalement automatique (petit service) : oui ou non.

## 7. Pour Sullyvan : compiler, mesurer
- **Compiler chaque branche une à une** (`scripts/verif.sh`, `/banc Lxx`) dans l'ordre L21, L18, L19, L23, L24 ; renvoyer à Titouan en 3 lignes les erreurs.
- **Lancer le prototype CloudKit** (`outils/reseau/README.md`) sur son Mac et **coller les chiffres** dans `outils/reseau/RESULTATS.md` : quota après 1 000 photos de 300 Ko et 100 vidéos de 15 s en 720p, taille réelle d'une vidéo, fil de 50 avec et sans médias, requête `IN` pour les likes, 20 latences sur 3 passages (app ouverte, arrière-plan, fermée), `exiftool` sur la vidéo exportée. **Aucun chiffre n'a été mesuré** : tout est « à mesurer ». La vidéo de L23 et le chat de L24 attendent ces chiffres pour être promis.
- **API à relire à la compilation (⚠, marquées dans le code)** : `records(matching:inZoneWith:desiredKeys:resultsLimit:)`, `records(continuingMatchFrom:)`, le prédicat `IN` combiné à `creeLe <`, `BEGINSWITH` sur `surnomNorm`, `serverRecordChanged` pour un enregistrement neuf déjà existant, `shareParticipant(forUserRecordID:)`, `participant.permission`, `CKRecordZoneSubscription.recordType`, `CKDatabase.subscription(for:)`, `AVAssetExportSession.export(to:as:)`, `metadataItemFilter`, `AVAssetImageGenerator.image(at:)`, `PhotosPicker` et `loadTransferable`, `@Previewable`, `.onChange` à deux paramètres, `defaultScrollAnchor`, `videoRotationAngle`, `DisclosureGroup(isExpanded:)`, isolation par défaut MainActor (Swift 6) des types `nonisolated`.

## 8. Ce qui n'est pas fait
- Aucun test d'interface pour L23 (écrit pour L21 et L24 mais jamais lancé) ; les tests sur deux et trois iPhones (délai de 10 s, notification app fermée, club à trois, `exiftool`) sont à faire sur Mac.
- Les textes de CGU et de confidentialité de R2 sont des **brouillons** (`docs/reports/reseau/cgu-confidentialite.md`) : `docs/legal/` n'a pas été touché. Relecture par un juriste de MWM.
- Les clés du manifeste de confidentialité (types de données collectées) sont écrites de mémoire : à contrôler dans Xcode.
- L20 (ouverture fluide), D5 (stations recalées), S2 (juridique) et les lots L16, L17, L22, L25 ne sont pas à Titouan.
