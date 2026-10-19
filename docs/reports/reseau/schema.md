# Réseau social : le schéma CloudKit des 9 types d'enregistrement
Décision débloquée : lancer L21 (`Profil`), L22 (`Club`, `Membre`), L23 (`Publication`, `Like`, `Commentaire`, `Signalement`, `Blocage`) et L24 (`MessageClub`, `MessageAmi`) sur CloudKit sans changer de fournisseur (décision 2 du 19 oct.).
Lu le 19/10/2026 (code existant `App/Amis/`, `App/Club/`, `App/Communaute/`, fiches L21 à L24 ; pages Apple citées en bas). Aucune mesure ici : les chiffres sont dans `quota.md` et `latence.md`.

## En bref
Image : la base publique est un tableau d'affichage de la place du village. Tout le monde lit, chacun n'écrit que sur ses propres affiches. Les secrets vont dans le coffre de chacun (base privée) ou dans la pièce partagée à deux (zone partagée).
Neuf types sont publics ou presque : `Profil`, `Publication`, `Like`, `Commentaire`, `Club`, `Membre`, `MessageClub`, `Signalement`, `Blocage`. Deux autres types ne sont jamais publics : `ProfilPrive` (base privée) et `MessageAmi` (zone partagée par `CKShare`, celle du lot Amis). Ils complètent la liste de la fiche R2.
Tout ce qui est en base publique est lisible par n'importe quelle app qui connaît l'identifiant du conteneur, et visible dans le tableau de bord ([base publique](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)). Rien de privé n'y entre : ni nom, ni prénom, ni message d'ami, ni coordonnée.

## Règles qui valent pour tous les types
- Jamais d'enregistrement avec : latitude, longitude, altitude, `CLLocation`, nom d'un plan d'eau comme champ interrogeable, EXIF GPS. Un test de fabrique de `CKRecord` (liste blanche de clés, comme `FabriqueRecords` du lot Amis) le prouve ; `exiftool -gps:all` sur chaque média téléchargé du conteneur d'essai n'affiche rien.
- Pas de type « Collection » en base publique, ni de requête qui liste les cartes d'un pêcheur : les collections ne sont jamais publiques (règle d'or). Une `Publication` est un post choisi par le pêcheur, pas sa collection.
- Pas de monnaie, pas de marché : aucun champ prix, aucun type d'échange.
- Droits : en base publique le rôle « World » lit, « Authenticated » crée, le créateur seul modifie et supprime son enregistrement ([rôles de sécurité](https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase)). ⚠ La page ne détaille pas la grille par type : à régler et lire dans le tableau de bord, « Security Roles ».
- Conséquence : personne ne peut supprimer l'enregistrement d'un autre depuis l'app. La suppression d'un contenu signalé se fait à la main dans le tableau de bord (décision 5). Un fondateur de club ne peut pas supprimer un `Membre` : il l'écarte par une liste (voir `Club.retires`).
- Index : un champ doit être marqué « queryable » (filtre) ou « sortable » (tri) dans le tableau de bord pour servir dans un `CKQuery` ; on les crée en Development puis on déploie vers Production avant le premier TestFlight ([déploiement](https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema)). Après le déploiement on ne peut plus supprimer un champ, seulement en ajouter ([conception](https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database)) : ce schéma est donc à relire avant de déployer.

## Les 9 types de la base publique
### 1. `Profil` (L21)
- `recordName` = `p-` + surnom normalisé (minuscules, sans accents, tirets). Idée : l'unicité vient de l'identifiant, pas d'un contrôle fait avant l'écriture. Deux iPhones qui prennent « gros-brochet » en même temps écrivent le même `recordName` ; avec `savePolicy: .ifServerRecordUnchanged` le second reçoit `serverRecordChanged` et choisit un autre surnom. Plus fiable que « vérifier avant, relire après » de la fiche L21 (les deux se combinent). Recommandation : ce schéma d'identifiant ; change avec un budget : non.
- Champs : `surnomAffiche` (texte, 3 à 20 caractères), `avatar` (`CKAsset` JPEG 256 px sans EXIF), `creeLe` (date), `version` (entier).
- Index : `recordName` queryable (recherche `BEGINSWITH` sur `surnomNorm`, champ texte queryable, 3 lettres au moins), `creeLe` sortable.
- Lit : tout le monde. Écrit : son créateur. Jamais : nom, prénom, e-mail, identifiant Apple en clair, lieu.
- Retrouver « mon » profil : le champ système `creatorUserRecordID` ⚠ n'est peut-être pas interrogeable ; le plus sûr est de garder le `recordName` dans `ProfilPrive`.

### 2. `Publication` (L23)
- `recordName` = UUID. Champs : `auteur` (`CKRecord.Reference` vers `Profil`, action `.none`), `auteurNom` (copie du `recordName` du profil, texte), `media` (`CKAsset`), `genre` (`photo` ou `video`), `vignette` (`CKAsset` JPEG 400 px, vidéo seulement), `dureeS` (entier, 15 au plus), `legende` (280 caractères au plus, filtrée), `lieuMode` (`cours-eau` / `departement` / `aucun`), `lieuTexte` (« La Marne · 94 », vide si département seul ou aucun ; **jamais interrogeable**), `departement` (« 94 », vide si `lieuMode` = `aucun`), `espece`, `rarete`, `tailleCm` (facultatifs : la carte liée), `club` (texte, `recordName` du club, vide si publique), `creeLe`.
- Index : `departement` queryable, `club` queryable, `auteurNom` queryable, `creeLe` sortable.
- Point d'attention : si `lieuMode` = `aucun`, `departement` reste vide, sinon le « lieu aucun » serait trahi par la section « Dans ta région ». Conséquence : une publication sans lieu n'apparaît ni dans la région, ni dans une requête par département ; elle reste dans « Tes amis » et « Tes clubs ». Question pour Adem dans `decisions.md`.
- Sur un plan d'eau nommé, `lieuMode` ne peut pas être `cours-eau` (décision 4) ; le test d'unité de L23 vérifie la fabrique.
- Lit : tout le monde. Écrit : l'auteur. Jamais : coordonnée, GPS, EXIF, nom d'un plan d'eau, nom réel.

### 3. `Like` (L23)
- `recordName` = `l-` + `recordName` de la publication + `-` + `recordName` du profil : un like par personne et par publication, par construction (sauvegarder deux fois écrase). Champs : `publication` (texte, queryable), `auteurNom` (queryable), `creeLe`.
- Le compte s'affiche depuis une requête, jamais un compteur sur la `Publication` (piège de la fiche L23). CloudKit n'a pas de `COUNT` : on lit les enregistrements. Pour un fil de 50, une seule requête `publication IN [50 identifiants]` ⚠ (prédicat `IN` à vérifier sur le prototype) plutôt que 50 requêtes. Coût mesuré : `quota.md`, « à mesurer ».
- Lit : tout le monde. Écrit : l'auteur.

### 4. `Commentaire` (L23)
- `recordName` = UUID. Champs : `publication` (texte, queryable), `auteurNom` (queryable), `texte` (280 caractères au plus, filtré), `creeLe` (sortable). Requête : `publication == X`, tri `creeLe`, 20 par page.
- Lit : tout le monde. Écrit : l'auteur. Jamais : lieu.

### 5. `Club` (L22)
- `recordName` = UUID du `ClubLocal` d'origine (clé de la migration, voir `migration-clubs.md`). Champs : `nom` (queryable pour « Rejoindre », mais **aucun annuaire** : la recherche par nom est seulement exacte), `poissonId` ou `image` (`CKAsset` JPEG sans EXIF), `fondateur` (`recordName` de `Profil`), `retires` (liste de textes : membres écartés), `ferme` (0/1), `creeLe`.
- Lit : tout le monde (nécessaire pour ouvrir un lien `fishme://club/<id>`). Écrit : le fondateur. Aujourd'hui « jamais d'annuaire public » (`MesClubs`) : un club existe en base publique mais n'est joignable que par son lien. ⚠ Ce n'est pas un secret : quiconque connaît l'identifiant lit nom et image.
- Passer le rôle de fondateur au plus ancien membre (fiche L22) est impossible : seul le créateur d'un enregistrement l'écrit. Choix : `Club.fondateur` ne change jamais ; si le fondateur quitte et qu'il reste des membres, le club reste sans fondateur actif (plus d'écart de membre possible) et sa suppression se fait à la main. Recommandation : accepter cette limite pour la v1 ; change avec un budget : non (un serveur de fonctions la lèverait, hors périmètre).

### 6. `Membre` (L22)
- `recordName` = `m-` + club + `-` + profil (une adhésion par personne et par club). Champs : `club` (queryable), `profil` (queryable), `role` (`fondateur` / `membre`), `depuis` (date).
- Lit : tout le monde. Écrit : le membre lui-même (il peut donc se retirer en supprimant son enregistrement).

### 7. `MessageClub` (L24)
- `recordName` = UUID. Champs : `club` (queryable), `auteurNom`, `texte` (500 caractères au plus, filtré), `creeLe` (sortable). Sert de cible à un `CKQuerySubscription` filtré par club (`latence.md`).
- **Lisible par tous** en base publique : un club n'a donc aucun secret. Le dire dans l'écran du chat de club (« ce que tu écris ici peut être lu par n'importe qui qui trouve le lien »). ⚠ Le chat de club n'est pas privé, c'est une conséquence de la décision 6 : Adem peut la juger inacceptable (voir `decisions.md`, question 2).

### 8. `Signalement` (L21 à L24)
- `recordName` = UUID. Champs : `cible` (`recordName`), `typeCible` (`publication` / `commentaire` / `message` / `profil` / `club`), `motif` (liste fermée, pas de texte libre), `signalePar` (`recordName` du profil), `creeLe`.
- Droits à régler dans le tableau de bord : « Authenticated » crée, personne ne lit sauf l'équipe. ⚠ À vérifier : si le rôle « World » ne peut pas être privé de lecture par type, mettre `Signalement` en base privée du pêcheur n'a pas de sens (l'équipe ne la lirait pas) ; dans ce cas la preuve reste l'e-mail automatique (`moderation.md`).
- Le signalement réel est l'e-mail ; l'enregistrement sert de trace et de dédoublonnage.

### 9. `Blocage` (L21 à L24)
- Recommandation : **base privée** du pêcheur, pas la base publique de la fiche : une liste publique de « qui a bloqué qui » nourrit le harcèlement. Le blocage est un filtre local : l'app masque ce qui vient de `bloque`. Apple demande « la possibilité de bloquer les utilisateurs abusifs » ([1.2](https://developer.apple.com/app-store/review/guidelines/)), pas un blocage côté serveur ; change avec un budget : non.
- Champs : `bloque` (`recordName` du profil), `creeLe`. Zone `Sauvegarde` de `App/Compte/` (accord de A) ou nouvelle zone `Blocages`.

## Types hors base publique
- `ProfilPrive` (base privée, zone `Sauvegarde`, `App/Compte/`) : `nom`, `prenom` facultatifs, `recordNameProfil`. Jamais affiché à un autre, jamais publié (décision 3).
- `MessageAmi` (zone partagée `Pescedex`, `CKShare` du lot Amis) : `auteurNom`, `texte` (500 caractères au plus), `creeLe`. ⚠ Le partage de L8 est en lecture seule ; l'écriture par l'ami exige `readWrite`. Les abonnements sur base partagée passent par `CKDatabaseSubscription`, pas `CKQuerySubscription` ⚠ (la fiche L24 dit l'inverse ; à vérifier sur le prototype, `latence.md`).
- Un type absent de la liste : `CartePartageeClub` (fiche L22). Recommandation : ne pas créer un 10e type ; une carte partagée à un club est une `Publication` avec `club` rempli. Change avec un budget : non.

## Requêtes du feed et coût
| Section | Requête | Index | Coût |
|---|---|---|---|
| Tes clubs | `Publication`, `club IN [mes clubs]`, tri `creeLe` desc, 20 | `club`, `creeLe` | à mesurer |
| Tes amis | `Publication`, `auteurNom IN [mes amis]`, 20 | `auteurNom`, `creeLe` | à mesurer |
| Dans ta région | `Publication`, `departement == "94"`, 20 | `departement`, `creeLe` | à mesurer |
| Likes du fil | `Like`, `publication IN [20 ids]` | `publication` | à mesurer |
| Commentaires | `Commentaire`, `publication == X`, 20 | `publication`, `creeLe` | à mesurer |
Une section = 1 requête de publications + 1 requête de likes. Le feed entier = 6 requêtes à l'ouverture (estimation). Les médias ne se téléchargent qu'à l'affichage (`desiredKeys` sans `media`). Le prototype `outils/reseau/` mesure le fil de 50 ; les amis du lot Amis ne passent pas par ces requêtes (zone partagée).

## Sources lues le 19/10/2026
- https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database (bases publique et privée, additif en production).
- https://developer.apple.com/documentation/cloudkit/ckcontainer/publicclouddatabase (base publique).
- https://developer.apple.com/documentation/cloudkit/deploying-an-icloud-container-s-schema (déploiement).
- ⚠ Non lus (pages Apple vides à la lecture automatique) : rôles de sécurité par type, comportement de `IN`, `CKQuerySubscription` sur base partagée.
