# CloudKit : types et index à poser dans le tableau de bord

Décision débloquée : Adem peut préparer le tableau de bord CloudKit (fil, chat, clubs, repères) sans lire de code. Lu dans le code le 20/10/2026, rien compilé ni testé. Conteneur : `iCloud.ai.mwm.build.challenge.team.01` (`Config/BuildChallenge.entitlements:9`). Le rapport R2 `docs/reports/reseau/schema.md` n'existe pas encore dans le dépôt : « les notes de Titouan » = `docs/fiches/R2.md` (liste des types) et les commentaires du code qui citent `schema.md`.

Image : le tableau de bord est le classeur de l'app dans iCloud. Un « type » est un onglet (Publication, Like...), un « champ » est une colonne, un « index » est le tri du classeur : sans index sur une colonne, l'app ne peut pas chercher ou trier dessus et la requête échoue.

## 1. Types, champs, index

Types CloudKit : `STRING` texte, `INT(64)` entier, `DOUBLE` décimal, `DATE/TIME` date, `ASSET` fichier, `REFERENCE` lien, `LIST<STRING>` liste de textes. Un type est unique pour tout le conteneur (public, privé, zones) : deux lots qui écrivent le même nom de type partagent un seul schéma.
Index sur `recordName` « Queryable » : à mettre sur CHAQUE type interrogé (réglage Apple par défaut absent pour les types créés à la main).

### Base publique (tout le monde lit, les gens écrivent)
| Type (fichier:ligne) | Champs : type | Index requis, d'après la requête réelle |
|---|---|---|
| `Publication` (`App/Communaute/FabriqueFeed.swift:8`, aussi `App/Club/FabriqueRecordsClub.swift:11`) | `auteur` REFERENCE, `auteurNom` STRING, `media` ASSET, `genre` STRING, `vignette` ASSET, `dureeS` INT, `legende` STRING, `lieuMode` STRING, `lieuTexte` STRING, `departement` STRING, `espece` STRING, `rarete` STRING, `tailleCm` DOUBLE, `club` STRING, `creeLe` DATE (`FabriqueFeed.swift:31-47`) | `creeLe` Queryable + Sortable (`ServiceFeedCloudKit.swift:76-78`) ; `departement`, `club`, `auteurNom` Queryable (`:67-72` `IN`, `:190` `==`, `ServiceClubsCloudKit.swift:164,234`) ; `recordName` Queryable |
| `Like` (`FabriqueFeed.swift:9`) | `publication` STRING, `auteurNom` STRING, `creeLe` DATE (`:53-55`) | `publication` Queryable (`ServiceFeedCloudKit.swift:109`, `IN`) ; `auteurNom` Queryable (`:190`) |
| `Commentaire` (`FabriqueFeed.swift:10`) | `publication` STRING, `auteurNom` STRING, `texte` STRING, `creeLe` DATE (`:61-64`) | `publication` Queryable ; `creeLe` Queryable + Sortable (`ServiceFeedCloudKit.swift:143-147`) ; `auteurNom` Queryable (`:190`) |
| `ProfilPublic` (`App/Profil/ServiceProfilCloudKit.swift:10`) | `surnomAffiche` STRING, `surnomNorm` STRING, `avatar` ASSET, `creeLe` DATE, `version` INT (`:20-24`) | `surnomNorm` Queryable (`BEGINSWITH`, `:136`) ; `createdBy` (champ système, ligne « Created By ») Queryable (`:176`, marqué « à vérifier » dans le code) ; `recordName` Queryable |
| `Club` (`FabriqueRecordsClub.swift:9`) | `nom` STRING, `poissonId` STRING, `image` ASSET, `fondateur` STRING, `retires` LIST<STRING>, `ferme` INT, `creeLe` DATE (`:14,37-42`) | aucune requête (lu par `recordName`, `ServiceClubsCloudKit.swift:58,78`) ; `recordName` Queryable par prudence |
| `Membre` (`FabriqueRecordsClub.swift:10`) | `club` STRING, `profil` STRING, `role` STRING, `depuis` DATE (`:47-50`) | `club` Queryable (`ServiceClubsCloudKit.swift:68`) ; `profil` Queryable (`:75`) |
| `Signalement` (`FabriqueFeed.swift:11`, `ServiceProfilCloudKit.swift:11`, `FabriqueRecordsClub.swift:12`, `FabriqueRecordsChat.swift:16`) | `cible` STRING, `typeCible` STRING, `motif` STRING, `signalePar` STRING, `creeLe` DATE ; plus `texte` STRING, écrit par le chat seulement (`FabriqueRecordsChat.swift:17,32`) | aucune requête dans l'app. Pour l'équipe : `recordName` Queryable + `creeLe` Sortable, afin de trier dans la console (non exigé par le code) |

Cartes d'un club : ce n'est PAS un type. `CartePartageeClub` est un modèle Swift ; en base c'est une `Publication` dont le nom commence par `pc-<club>-` (`FabriqueRecordsClub.swift:24,57`). Rien à créer en plus.

### Base privée de chaque pêcheur (invisible pour nous, sauf les index de requête)
| Type (fichier:ligne) | Où | Champs | Index |
|---|---|---|---|
| `Blocage` (`FabriqueFeed.swift:12`) | zone par défaut | `bloque` STRING, `creeLe` DATE (`:81-82`) | `recordName` Queryable (requête `TRUEPREDICATE`, `ServiceFeedCloudKit.swift:174`) |
| `MessageClub` (`FabriqueRecordsChat.swift:8`) | zone partagée `chatclub-<id du club>` (propriétaire : le fondateur, `ServiceChatCloudKit.swift:20`) | `club`, `auteurNom`, `surnom`, `texte` STRING, `creeLe` DATE (`:13,39-55`) | `recordName` Queryable (`ServiceChatCloudKit.swift:113`, `TRUEPREDICATE` dans la zone) |
| `MessageAmi` (`FabriqueRecordsChat.swift:9`) | zone partagée `chat-<id>-<id>` | `auteurNom`, `surnom`, `texte` STRING, `creeLe` DATE (`:14`) | idem |
| `Carte` (`App/Amis/FabriqueRecords.swift:7`) | zone `Pescedex` (`ServiceAmisCloudKit.swift:24`) | `cardID`, `espece`, `rarete`, `datePrise`, `taille`, `bredouille`, `zone`, `image` (`FabriqueRecords.swift:8`) | aucun (lecture par zone) |
| `Carte`, `Bredouille`, `Profil` (`App/Compte/SauvegardeICloud.swift:134-138`) | zone `Sauvegarde` (`:46`) | `Carte` : `especeId, codeSandre, origine, longueurCm, mesure, stade, date, lieuFlou, gardee, exemple, conditions, dureeSecondes, photo` (`:218-230`) ; `Bredouille` : `debut, fin, lieuFlou, conditions` (`:194-197`) ; `Profil` : `fichier` ASSET (`:111`) | aucun (`recordZoneChanges`, `:163`) |
| `Repere` (`App/Reperes/SauvegardeReperes.swift:34`) | zone `Reperes` (`:32`) | `nom, icone, note, latitude, longitude, idsPrises, photos, cree, modifie, passageManuel, supprime` (`:38-39,174-184`) | aucun ; champs en `encryptedValues` (chiffrés, non indexables, illisibles dans la console : voulu) |
| `PhotoRepere` (`SauvegardeReperes.swift:35`) | zone `Reperes` | `fichier` ASSET, `octets` INT (`:241-242`, chiffrés) | aucun |

Total : 15 noms de types distincts : 7 publics (`Publication, Like, Commentaire, ProfilPublic, Club, Membre, Signalement`) et 8 privés (`Blocage, MessageClub, MessageAmi, Carte, Bredouille, Profil, Repere, PhotoRepere` ; `Carte` compte une fois).

## 2. Droits (onglet « Security Roles »)
- `Signalement` : « World » (tout le monde) = aucun droit ; « Authenticated » (iCloud connecté) = Create seulement ; ni Read ni Write. L'équipe lit dans la console, qui ignore ces rôles. Le code ne relit jamais un signalement. Le commentaire `ServiceChatCloudKit.swift:315` demande exactement cela. À vérifier avec un vrai envoi : `publique.save` doit réussir sans droit de lecture.
- `Publication, Like, Commentaire, ProfilPublic, Club, Membre` : World = Read ; Authenticated = Create ; Creator = Write (valeur par défaut). Cela interdit à un pêcheur de modifier ou effacer l'enregistrement d'un autre. Le code s'y appuie : seul le fondateur écrit `Club` (`ServiceClubsCloudKit.swift:137`). Conséquence : seule la console efface le contenu d'un tiers (décision 5).
- Types privés : rien à régler, ils vivent dans l'iPhone du propriétaire ; chat par `CKShare`.

## 3. Procédure à l'écran (dans l'ordre)
1. Ouvrir icloud.developer.apple.com, connexion avec le compte développeur de l'équipe, puis « CloudKit Database ».
2. Choisir le conteneur `iCloud.ai.mwm.build.challenge.team.01`, puis en haut l'environnement « Development ».
3. Voie courte recommandée : Sullyvan lance l'app depuis Xcode sur un iPhone connecté à iCloud et fait chaque action une fois (publier, aimer, commenter, signaler un post et un message, créer un surnom, créer un club et le rejoindre, écrire un message de club, créer un repère). En Development, CloudKit crée les types et les champs tout seul, avec le bon type. Sans cela, créer à la main : « Schema » > « Record Types » > « + », nom exact du tableau, puis « Add Field » pour chaque ligne.
4. Vérifier les types : « Schema » > « Record Types » : les 15 noms doivent s'afficher, aucun doublon d'orthographe (`Publications`, `publication`).
5. Index : cliquer le type > onglet « Indexes » > « Add Index » (ou « Add Basic Index ») > choisir le champ > cocher « Queryable » (et « Sortable » pour `creeLe`) > « Save Changes ». Faire toutes les lignes de la colonne « Index » du tableau, y compris `recordName`. Ne rien cocher « Searchable » : le code n'utilise pas la recherche par mots (`CONTAINS`/tokens), `BEGINSWITH` suffit.
6. Droits : « Security Roles » > rôle > cocher selon la section 2 > « Save Changes ».
7. Tester en Development avec une vraie app (voir section 5), puis « Schema » > « Deploy Schema Changes… » > relire la liste des changements > « Deploy » : cela copie types, champs et index vers « Production ».
8. Passer sur « Production » et vérifier que les 15 types et leurs index y sont. Les données d'essai ne sont pas copiées, seulement le schéma.
9. L'app des testeurs TestFlight et de l'App Store parle à Production seule ; celle lancée depuis Xcode parle à Development.

## 4. Écarts code / notes de Titouan (`docs/fiches/R2.md:20`)
- `Profil` (notes) devient `ProfilPublic` : le nom `Profil` est pris en base privée par la sauvegarde (`ServiceProfilCloudKit.swift:7`, `SauvegardeICloud.swift:137`). Les champs du code sont `surnomAffiche, surnomNorm, avatar, creeLe, version` ; les notes disent « surnom, avatar, date » : à comparer avec `schema.md` quand il existera.
- `ProfilPrive` (nom, prénom) des notes : aucune occurrence dans le code. Rien à créer.
- `MessageClub` : les notes le rangent en base publique ; le code l'écrit dans une zone partagée privée, jamais en public (`ServiceChatCloudKit.swift:15`). `Blocage` : notes publiques, code privé (`FabriqueFeed.swift:78`).
- `Signalement.texte` n'existe que dans le chat : le commentaire du code dit « à ajouter au schéma » (`FabriqueRecordsChat.swift:23`).
- `auteurNom` porte un identifiant de profil dans `MessageClub/MessageAmi`, un surnom dans `Publication/Like/Commentaire` (`FabriqueRecordsChat.swift:11`) : même nom, deux sens. Pas de blocage, mais piège pour une requête future.
- `Carte` existe deux fois en privé avec des champs différents (`FabriqueRecords.swift:8` : `datePrise, taille, zone` ; `SauvegardeICloud.swift:218-230` : `date, longueurCm, lieuFlou`). CloudKit fusionne les champs dans un seul type : accepté, mais les deux zones restent distinctes.
- Types de champs : aucun écart relevé, sauf ceux ci-dessus. Les types donnés en tableau viennent des valeurs écrites par le code ; en cas de création à la main avec un autre type, l'écriture échoue.

## 5. Risques
- Production est à sens unique : un type ou un champ déployé ne se supprime plus. Une faute dans un nom reste. Tester en Development d'abord, déployer ensuite.
- Index oublié : l'app marche en Development (CloudKit crée les index à la volée là-bas seulement) et casse en Production avec « Field is not marked queryable ». Parade : refaire un tour complet de l'app sur une build TestFlight après le déploiement.
- Écran qui promet « lu » : le code n'affiche que « Envoyé / En attente / Pas parti » et dit « Aucun accusé de lecture » (`App/Chat/BulleMessageView.swift:4`, `ModelesChat.swift:23`). À garder : un test d'interface doit refuser les mots « lu » et « vu » sur le chat. Idem « Signalé » : affiché seulement si l'écriture a réussi (`ServiceChatCloudKit.swift:316`, `ServiceProfilCloudKit.swift:190`), donc si les droits de `Signalement` sont faux, l'utilisateur voit une erreur, pas un faux succès.
- Quota : la base publique a un quota par utilisateur actif (CLAUDE.md, décision 2), non mesuré ; les `media` des `Publication` (photo, vidéo) en sont le gros poste. À mesurer par R2 (prototype de Sullyvan), aucun chiffre ici.
- Un abonnement (`CKDatabaseSubscription`, `CKRecordZoneSubscription`) crée aussi des types d'abonnement et exige les notifications push : `aps-environment` est `development` dans l'entitlement (`BuildChallenge.entitlements:6`) ; l'archive App Store le passe en production, à vérifier au premier TestFlight.
- Chat de club : sans serveur, seul le fondateur ajoute des membres à la zone et un `CKShare` a un plafond de participants non lu (`ServiceChatCloudKit.swift:24-27`).
- À vérifier sur le Mac (écrit sans compilateur) : index `createdBy` (`ServiceProfilCloudKit.swift:175`), `recordName` queryable pour les `TRUEPREDICATE` (`ServiceFeedCloudKit.swift:173`), `recordType` d'un abonnement de zone (`ServiceChatCloudKit.swift:221`), droit « Create seulement » de `Signalement`, taille maximale de `IN` (`ServiceFeedCloudKit.swift:54`).
