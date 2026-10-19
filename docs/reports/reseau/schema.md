# Réseau social : le schéma CloudKit des 11 types d'enregistrement
Décision débloquée : lancer L21 (`ProfilPublic`), L22 (`Club`, `Membre`), L23 (`Publication`, `Like`, `Commentaire`, `Signalement`, `Blocage`) et L24 (`MessageClub`, `MessageAmi`) sur CloudKit sans changer de fournisseur (décision 2 du 19 oct.).
Lu le 19/10/2026, corrigé le même jour après revue (code existant `App/Amis/`, `App/Club/`, `App/Communaute/`, fiches L21 à L24, code de `lot/chat` ; pages Apple citées en bas). Aucune mesure ici : les chiffres sont dans `quota.md` et `latence.md`.

## En bref
Image : la base publique est un tableau d'affichage de la place du village. Tout le monde lit, chacun n'écrit que sur ses propres affiches. Les secrets vont dans le coffre de chacun (base privée) ou dans une pièce partagée dont seuls les invités ont la clé (zone partagée).
Onze types, en trois endroits (décisions de Titouan du 19 oct.) :
| Où | Types | Qui lit |
|---|---|---|
| Base publique (7) | `ProfilPublic`, `Publication`, `Like`, `Commentaire`, `Club`, `Membre`, `Signalement` | tous ; le `Signalement` : l'équipe seulement (droits à régler) |
| Base privée (2) | `Blocage`, `ProfilPrive` | le pêcheur seul |
| Zone partagée (2) | `MessageClub` (une zone par club), `MessageAmi` (une zone par paire d'amis) | les membres du club ; les deux amis |
Le chat n'est **jamais** en base publique. Un type `Profil` existe déjà en base privée (`App/Compte/SauvegardeICloud.swift`, champs `fichier`, `origine`) : le type public s'appelle `ProfilPublic`, pour qu'un même nom ne désigne pas deux formes dans le schéma.
Tout ce qui est en base publique est lisible par n'importe quelle app qui connaît l'identifiant du conteneur, et visible dans le tableau de bord ([base publique](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)). Rien de privé n'y entre : pas de nom ni de prénom (le profil n'a qu'un surnom), pas de message, pas de coordonnée.

## Règles qui valent pour tous les types
- Jamais d'enregistrement avec : latitude, longitude, altitude, `CLLocation`, nom d'un plan d'eau comme champ interrogeable, EXIF GPS. Un test de fabrique de `CKRecord` (liste blanche de clés, comme `FabriqueRecords` du lot Amis) le prouve ; `exiftool -gps:all` sur chaque média téléchargé du conteneur d'essai n'affiche rien. Une photo importée de la galerie est ré-encodée sans GPS comme une photo prise dans l'app.
- Pas de type « Collection » en base publique, ni de requête qui liste les cartes d'un pêcheur : les collections ne sont jamais publiques (règle d'or). Une `Publication` est un post choisi par le pêcheur, pas sa collection.
- Pas de monnaie, pas de marché : aucun champ prix, aucun type d'échange. Le réseau est gratuit.
- Droits : en base publique le rôle « World » lit, « Authenticated » crée, le créateur seul modifie et supprime son enregistrement ([rôles de sécurité](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)). ⚠ La page ne détaille pas la grille par type : à régler et lire dans le tableau de bord, « Security Roles ».
- Conséquence : personne ne peut supprimer l'enregistrement d'un autre depuis l'app. La suppression d'un contenu signalé se fait à la main dans le tableau de bord (décision 5). Un fondateur de club ne peut pas supprimer un `Membre` : il l'écarte par une liste (`Club.retires`).
- Index : un champ doit être marqué « queryable » (filtre) ou « sortable » (tri) dans le tableau de bord pour servir dans un `CKQuery` ; on les crée en Development puis on déploie vers Production avant le premier TestFlight ([déploiement](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema)). Après le déploiement on ne peut plus supprimer un champ, seulement en ajouter ([conception](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)) : ce schéma est à relire avant de déployer. La liste complète est au tableau « Index requis » plus bas.

## Les 7 types de la base publique
### 1. `ProfilPublic` (L21)
- `recordName` = `p-` + surnom normalisé (minuscules, sans accents, tirets). Idée : l'unicité vient de l'identifiant, pas d'un contrôle fait avant l'écriture. Deux iPhones qui prennent « gros-brochet » en même temps écrivent le même `recordName` ; avec `savePolicy: .ifServerRecordUnchanged` le second reçoit `serverRecordChanged` et choisit un autre surnom. Plus fiable que « vérifier avant, relire après » de la fiche L21 (les deux se combinent). Recommandation : ce schéma d'identifiant ; change avec un budget : non.
- Champs : `surnomAffiche` (texte, 3 à 20 caractères), `surnomNorm` (texte, le surnom normalisé, sert à la recherche), `avatar` (`CKAsset` JPEG 256 px sans EXIF), `creeLe` (date), `version` (entier).
- Lit : tout le monde. Écrit : son créateur. Jamais : nom, prénom, e-mail, identifiant Apple en clair, lieu, date de naissance (la majorité de 15 ans est déclarée, pas stockée).
- Retrouver « mon » profil : le champ système `creatorUserRecordID` ⚠ n'est peut-être pas interrogeable ; le plus sûr est de garder le `recordName` dans `ProfilPrive`.

### 2. `Publication` (L23)
- `recordName` = UUID. Champs : `auteur` (`CKRecord.Reference` vers `ProfilPublic`, action `.none`), `auteurNom` (copie du `recordName` du profil, texte), `media` (`CKAsset`), `genre` (`photo` ou `video`), `vignette` (`CKAsset` JPEG 400 px, vidéo seulement), `dureeS` (entier, 15 au plus), `legende` (280 caractères au plus, filtrée), `lieuMode` (`departement` par défaut / `cours-eau` / `aucun`), `lieuTexte` (« La Marne · 94 », vide si département seul ou aucun ; **jamais interrogeable**), `departement` (« 94 », vide si `lieuMode` = `aucun`), `espece`, `rarete`, `tailleCm` (facultatifs : la carte liée ; valeur bornée à la lecture, car écrite par n'importe quel client), `club` (texte, `recordName` du club, vide si publique), `creeLe`.
- Décidé le 19 oct. : « aucun lieu » = publication **absente du fil de région**. Si `lieuMode` = `aucun`, `departement` reste vide, sinon le choix serait trahi par « Dans ta région ». Elle reste dans « Tes amis » et « Tes clubs ». Le lieu par défaut proposé à la publication est « département seul ».
- Sur un plan d'eau nommé, `lieuMode` ne peut pas être `cours-eau` (décision 4) ; le test d'unité de L23 vérifie la fabrique.
- Lit : tout le monde. Écrit : l'auteur. Jamais : coordonnée, GPS, EXIF, nom d'un plan d'eau, nom réel. Change avec un budget : non.

### 3. `Like` (L23)
- `recordName` = `l-` + `recordName` de la publication + `-` + `recordName` du profil : un like par personne et par publication, par construction (sauvegarder deux fois écrase). Champs : `publication` (texte), `auteurNom`, `creeLe`.
- Le compte s'affiche depuis une requête, jamais un compteur sur la `Publication`. CloudKit n'a pas de `COUNT` : on lit les enregistrements, page après page (le curseur doit être suivi). Pour un fil de 50, une requête `publication IN [50 identifiants]` ⚠ (prédicat `IN` et sa taille maximale à vérifier sur le prototype ; sinon découper par paquets) plutôt que 50 requêtes. Coût : `quota.md`, « à mesurer ».
- Lit : tout le monde. Écrit : l'auteur. Change avec un budget : non.

### 4. `Commentaire` (L23)
- `recordName` = UUID. Champs : `publication` (texte), `auteurNom`, `texte` (280 caractères au plus, filtré), `creeLe`. Requête : `publication == X`, tri `creeLe`, 20 par page, page suivante par `creeLe >`.
- Lit : tout le monde. Écrit : l'auteur. Jamais : lieu. Change avec un budget : non.

### 5. `Club` (L22)
- `recordName` = UUID du `ClubLocal` d'origine (clé de la migration, voir `migration-clubs.md`). Champs : `nom` (queryable pour « Rejoindre », mais **aucun annuaire** : la recherche par nom est seulement exacte), `poissonId` ou `image` (`CKAsset` JPEG sans EXIF), `fondateur` (`recordName` de `ProfilPublic`), `retires` (liste de textes : membres écartés), `ferme` (0/1), `creeLe`.
- Lit : tout le monde (nécessaire pour ouvrir un lien `fishme://club/<id>`). Écrit : le fondateur. Un club existe en base publique mais n'est joignable que par son lien. ⚠ Ce n'est pas un secret : quiconque connaît l'identifiant lit le nom et l'image. Seul le **chat** du club est réservé aux membres (type 10).
- Passer le rôle de fondateur au plus ancien membre (fiche L22) est impossible : seul le créateur d'un enregistrement l'écrit. Choix : `Club.fondateur` ne change jamais ; si le fondateur quitte et qu'il reste des membres, le club reste sans fondateur actif et sa suppression se fait à la main. Recommandation : accepter cette limite pour la v1 ; change avec un budget : non (un serveur de fonctions la lèverait, hors périmètre).

### 6. `Membre` (L22)
- `recordName` = `m-` + club + `-` + profil (une adhésion par personne et par club). Champs : `club`, `profil`, `role` (`fondateur` / `membre`), `depuis` (date).
- Lit : tout le monde. Écrit : le membre lui-même (il peut se retirer en supprimant son enregistrement). Change avec un budget : non.

### 7. `Signalement` (L21 à L24)
- `recordName` = UUID. Champs : `cible` (`recordName`), `typeCible` (`publication` / `commentaire` / `message` / `profil` / `club`), `motif` (liste fermée, un seul vocabulaire pour L21 à L24), `signalePar` (`recordName` du profil), `creeLe`, `texte` (500 caractères au plus, **rempli pour un message d'ami ou de club signalé** : le texte est copié ici, joint au `mailto:` et déclaré dans la confidentialité, car l'équipe ne peut pas lire une zone partagée).
- Droits à régler dans le tableau de bord : « Authenticated » crée, personne ne lit sauf l'équipe. ⚠ À vérifier : si le rôle « World » ne peut pas être privé de lecture par type, l'enregistrement serait lisible de tous, texte de message compris ; dans ce cas, ne pas copier le texte et le laisser au seul `mailto:`.
- Le signalement réel = l'e-mail prérempli (`mailto:`) **et** cet enregistrement ; l'écran ne dit « signalé » que si l'enregistrement a réussi (`moderation.md`). Pas d'e-mail automatique sans service payant. Change avec un budget : non pour l'enregistrement ; oui pour un e-mail automatique.

## Types hors base publique
### 8. `Blocage` (base privée, L21 à L24)
- Recommandation : **base privée** du pêcheur, pas la base publique de la fiche : une liste publique de « qui a bloqué qui » nourrit le harcèlement. Le blocage est un filtre local : l'app masque ce qui vient de `bloque`. Apple demande « la possibilité de bloquer les utilisateurs abusifs » ([1.2](https://developer.apple.com/app-store/review/guidelines/)), pas un blocage côté serveur ; change avec un budget : non.
- Champs : `bloque` (`recordName` du profil), `creeLe`. Zone `Sauvegarde` de `App/Compte/` (accord de A) ou nouvelle zone `Blocages`. L23 doit relire ces enregistrements à l'ouverture (réinstallation, autre iPhone).

### 9. `ProfilPrive` (base privée, zone `Sauvegarde`, `App/Compte/`)
- Plus de nom ni de prénom (décision : juste un pseudonyme). Il ne garde que `recordNameProfil` (retrouver « mon » profil) ; ⚠ à aligner sur le code de L21. Jamais affiché à un autre. Change avec un budget : non.

### 10. `MessageClub` (zone partagée du club, L24)
- **Une zone par club**, `chatclub-<id du club>`, créée dans la base privée du fondateur et partagée aux membres par `CKShare` (fondateur propriétaire, membres en `readWrite`). Jamais de `MessageClub` en base publique : un message de club n'est lisible que par les membres admis.
- Champs (liste blanche de `FabriqueRecordsChat`) : `club`, `auteurNom` (identifiant du profil, écrit par le client donc **falsifiable** : l'auteur réel se lit dans `creatorUserRecordID`), `surnom` (affichage sans relire le profil), `texte` (500 caractères au plus, filtré), `creeLe`. `recordName` = UUID du message ; queryable (requête `value: true`).
- Limites : le fondateur doit ouvrir l'app pour admettre un membre ; un membre `readWrite` peut aussi modifier les messages des autres ; plafond de participants d'un `CKShare` ⚠ non lu. Change avec un budget : non.

### 11. `MessageAmi` (zone partagée de la paire, L24)
- **Une zone par paire d'amis**, `chat-<A>-<B>`. Créateur = celui dont l'identifiant `p-…` est le plus petit ; l'autre n'écrit qu'après avoir accepté le lien et cherche d'abord la zone en base partagée (sinon deux zones homonymes, l'une jamais lue par l'autre). Mêmes champs que `MessageClub`, sans `club`.
- ⚠ Le partage de L8 (collection, zone `Pescedex`) est en lecture seule ; l'écriture exige `readWrite` sur la zone du chat. Les zones `chat…` et `chatclub…` ne doivent pas être prises pour des amis par `collectionsRecues()` (filtrer `zoneName == "Pescedex"`).
- Notifications : le créateur s'abonne par `CKRecordZoneSubscription` sur sa zone privée ; pour l'invité, la base partagée accepte-t-elle `CKRecordZoneSubscription` (choix de L24) ou faut-il `CKDatabaseSubscription` ? ⚠ **non vérifié**, c'est le test 4c du prototype (`latence.md`). Change avec un budget : non.
- Un type absent de la liste : `CartePartageeClub` (fiche L22). Recommandation : ne pas créer de 12e type ; une carte partagée à un club est une `Publication` avec `club` rempli. Change avec un budget : non.

## Index requis (tableau de bord, à créer en Development)
| Type | Champ | Queryable | Sortable | Pourquoi |
|---|---|---|---|---|
| `ProfilPublic` | `recordName` | oui | | recherche d'un profil |
| `ProfilPublic` | `surnomNorm` | oui | | `BEGINSWITH`, 3 lettres au moins |
| `Publication` | `creeLe` | oui | oui | `creeLe <` (voir plus) et tri |
| `Publication` | `departement`, `club`, `auteurNom` | oui | | sections région, clubs, amis, suppression |
| `Like` | `publication`, `auteurNom` | oui | | compte du fil, suppression du profil |
| `Commentaire` | `publication`, `auteurNom` | oui | | liste, suppression du profil |
| `Commentaire` | `creeLe` | oui | oui | tri et page suivante `creeLe >` |
| `Club` | `nom` | oui | | « Rejoindre » (recherche exacte) |
| `Membre` | `club`, `profil` | oui | | membres d'un club, mes clubs |
| `MessageClub`, `MessageAmi` | `recordName` | oui | | requête `value: true` |
Un index manquant fait échouer la requête avec « not marked queryable » : relever chaque cas dans `outils/reseau/RESULTATS.md`.

## Requêtes du feed et coût
| Section | Requête | Index | Coût |
|---|---|---|---|
| Tes clubs | `Publication`, `club IN [mes clubs]`, tri `creeLe` desc, 20 | `club`, `creeLe` | à mesurer |
| Tes amis | `Publication`, `auteurNom IN [mes amis]`, 20 | `auteurNom`, `creeLe` | à mesurer |
| Dans ta région | `Publication`, `departement == "94"`, 20 | `departement`, `creeLe` | à mesurer |
| Likes du fil | `Like`, `publication IN [20 ids]` | `publication` | à mesurer |
| Commentaires | `Commentaire`, `publication == X`, 20 | `publication`, `creeLe` | à mesurer |
Une section = 1 requête de publications + 1 requête de likes. Le feed entier = 6 requêtes à l'ouverture (estimation). Les médias ne se téléchargent qu'à l'affichage (`desiredKeys` sans `media`). Le prototype `outils/reseau/` mesure le fil de 50 ; les messages (ami, club) et la collection des amis ne passent pas par ces requêtes (zones partagées).

## Sources lues le 19/10/2026
- https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database (bases publique et privée, additif en production).
- https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase (base publique).
- https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema (déploiement).
- ⚠ Non lus (pages Apple vides à la lecture automatique) : rôles de sécurité par type, comportement de `IN`, abonnements `CKRecordZoneSubscription` / `CKDatabaseSubscription` sur base partagée, plafond de participants d'un `CKShare`.
