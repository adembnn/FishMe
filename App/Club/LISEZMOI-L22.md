# L22 Clubs dans CloudKit : à brancher et à vérifier

Tout ce lot a été écrit sans Mac ni Xcode. Rien n'a été compilé ni exécuté côté app (`// ⚠ à vérifier`). Seul le Core se teste sous Docker.

## À brancher (A, L25) : rien d'autre à faire dans App/Club/
1. `ouvrir(url:)` de `RootView.swift` : pour l'hôte `club`, appeler `RelaisLienClub.partage.recevoir(url)` ; si vrai, ouvrir Communauté, page Club (la page montre la feuille « Rejoindre »).
2. Effacement du compte : à la composition, `EffaceurClubs.enregistrer(service: <le même ServiceClubs que GestionClubs.partage>)` (pris par `RegistreEffaceurs.partage`, L21).
3. Chat de club (L24) : branché dans `RootView` (`AnnuaireChatRacine.clubs()` lit `GestionClubs.partage.clubsPourChat()` ; la table de correspondance est du code, `ClubChat.init(_: ClubPourChat)` dans `App/Chat/AdaptateurClubChat.swift`).
4. Migration : elle se lance d'elle-même quand la page Club s'ouvre (pas au démarrage de l'app). Si Adem la veut au lancement, appeler la même `MigrationClubs` depuis la racine (pas indispensable).
5. Capacités Xcode : iCloud / CloudKit, conteneur déjà celui des Amis (`ConfigurationAmis.conteneurParDefaut`). Schéma `Club`, `Membre`, `CartePartageeClub`, `Signalement` à créer dans le tableau de bord CloudKit d'après `docs/reports/reseau/schema.md`, puis à déployer en production.
6. `MotifSignalement` : L23 a sa propre liste (« haine » contre « harcelement » chez L21) ; à harmoniser à la composition.

## Membres sans `idCloudKit` (traité)
Un membre sans `idCloudKit` n'est plus listé avec un identifiant vide qui bloque l'admission des autres.
- `GestionClubs.resoudreIdentites` lit son `ProfilPublic` (par `p-<surnom>`, `ResolveurIdentiteCloudKit`) et retient le `creatorUserRecordID` de cet enregistrement (jamais un champ reçu), gardé dans le cache (`EtatCacheClubs.identites`).
- Tant qu'il est inconnu : « En attente de son profil » dans la liste des membres, aucune erreur, exclu de l'admission au chat sans bloquer les autres.
- Nouvel essai : à chaque ouverture de la page (`charger(ouverture: true)`), puis à chaque rafraîchissement de 8 s (profil introuvable : pas avant 60 s ; panne réseau : réessai immédiat au tour suivant), et depuis le chat (`actualiserClubs`).
- Les membres de la démo locale (`demo-…`) ne sont jamais résolus ni admis. `GestionClubs.init(resolveur:)` est optionnel (`nil` : pas de résolution).
- Tests : `AppTests/Club/IdentiteMembresTests.swift`. À vérifier au Mac : voir `docs/reports/branchements-l25.md`.

## Écarts avec la fiche (voir R2, `migration-clubs.md`)
- Un drapeau par club (`clubs.migre.<uuid>`) en plus du drapeau global `clubs.migres` : si la migration échoue au 3e club elle ne rejoue pas les 2 premiers.
- La migration demande le consentement (un club local était privé, en ligne il se lit par son lien) : feuille « Mettre en ligne / Garder sur cet iPhone ». La copie locale est gardée.
- Effacement : un fondateur qui supprime son profil alors que d'autres membres restent laisse le club sans fondateur (pas de transfert possible) ; il ne détruit pas le club des autres.
- Le signalement n'envoie pas d'e-mail seul : la personne l'envoie ; l'enregistrement `Signalement` est la trace.

## À vérifier sur le Mac
- Compilation de tout `App/Club/` (Swift 6, `nonisolated`, isolation des `@MainActor`), de `AppTests/Club/` et `AppUITests/Club/`.
- `ServiceClubsCloudKit` contre le vrai conteneur : champ `idCloudKit` du `Membre` lisible par un autre compte (ModelesClub.swift:41), index de requêtes (`recordName` interrogeable), cohérence à terme (garde-fous 90 s).
- Test fini de la fiche : deux iPhones, membre visible sous 10 s (rafraîchissement toutes les 8 s tant que la page est ouverte ; un abonnement `CKQuerySubscription` ferait mieux avec les notifications), carte sans GPS (`exiftool`), mode avion, `DemoClub` inchangé.
- Quitter un club ne retire pas l'accès à la zone partagée du chat (L24) : seul le fondateur peut retirer un participant du `CKShare`.
- Taille 44 pt, texte AX5, aucune barre de défilement, aucun emoji, `/banc L22`.
