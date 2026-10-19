# R2 en une page : décisions débloquées, budget, questions restantes
Décision débloquée : valider R2 pour ouvrir la vague 2 (L21, L22, L23, L24, S2), ou revenir sur CloudKit (décision 2) ; chaque ligne dit ce qui manque.
Lu le 19/10/2026, corrigé le même jour après revue. Mesuré le : à mesurer (rien n'est mesuré, Sullyvan n'a pas encore lancé `outils/reseau/`).

## Où on en est
| Fichier | Contenu | État |
|---|---|---|
| `schema.md` | 11 types : 7 publics, 2 privés, 2 en zone partagée ; droits, index, requêtes du feed | écrit, à valider |
| `quota.md` | quota et projection | méthode écrite, **chiffres à mesurer** |
| `latence.md` | 20 abonnements publics + test 4c en zone partagée | méthode écrite, **chiffres à mesurer** |
| `moderation.md` | circuit de la règle 1.2, boîte lue par trois personnes | écrit ; **référent de la semaine à fixer par l'équipe** |
| `migration-clubs.md` | clubs locaux vers CloudKit | écrit, à valider |
| `cgu-confidentialite.md` | paragraphes à changer | brouillon, relecture MWM |
| `juridique-et-risques.md` | App Review 1.2, 5.1.1, 5.1.2, manifeste | écrit |
Prototype : `outils/reseau/` (code non compilé, mode d'emploi pour Sullyvan, modèle `RESULTATS.md`).

## Décidé le 19 oct. (par Titouan)
| # | Décision | Où elle s'écrit |
|---|---|---|
| 1 | Le réseau est **gratuit** | CGU article 3 |
| 2 | **15 ans minimum**, par déclaration, sans date de naissance | CGU article 2, `schema.md` |
| 3 | « Aucun lieu » = publication **absente du fil de région** | `schema.md` (`departement` vide) |
| 4 | Lieu par défaut : **département seul** | `schema.md`, écran de publication |
| 5 | Chat de club en **zone partagée par club**, jamais en base publique | `schema.md` type 10, CGU art. 8 |
| 6 | Chat d'ami en **zone partagée par paire** (créateur = identifiant `p-…` le plus petit) | `schema.md` type 11 |
| 7 | Le texte d'un message signalé (ami ou club) est **joint au `mailto:` et copié dans `Signalement`** | `schema.md` type 7, confidentialité |
| 8 | Signalement = `mailto:` + enregistrement ; l'écran ne dit « signalé » que si l'enregistrement a réussi ; pas d'e-mail automatique sans service payant | `moderation.md` |
| 9 | La boîte fishme.app@gmail.com est lue par **Titouan, Adem et Sullyvan**, un référent par semaine, réponse sous 24 h | `moderation.md` |
| 10 | **Juste un pseudonyme** : plus de nom ni de prénom | `schema.md`, CGU |
| 11 | **Mode démo** du feed et du chat en Release, pour le relecteur d'Apple | `juridique-et-risques.md` |
| 12 | Accord aux conditions à la création du profil | CGU, `juridique-et-risques.md` |
| 13 | Import d'une photo depuis la galerie autorisé (ré-encodée sans GPS) | `schema.md`, règles |
| 14 | Liste de mots interdits unique dans `Core` (LDNOOBW, CC-BY-4.0, attribution dans Sources) | `moderation.md` |

## Ce que chaque lot peut lancer, et à quelle condition
| Lot | Peut démarrer | Sous condition |
|---|---|---|
| L21 Profil et amis | oui, sur `schema.md` (`ProfilPublic` à `recordName` dérivé du surnom, `ProfilPrive` sans nom) | `Blocage` en base privée si Adem accepte ; mots interdits de `Core` fusionnés avant |
| L22 Clubs | oui | réponse sur la migration (`migration-clubs.md`, question 1) ; pas de type `CartePartageeClub` |
| L23 Feed | le fil **photo** oui ; la **vidéo** attend `quota.md` | quota mesuré ; fusion de `Core` avant `feed` |
| L24 Chat | oui, en zones partagées (club, paire) | test 4c : abonnement accepté sur la base partagée (`latence.md`) |
| S2 Juridique | oui | relecture des textes par MWM |

## Conseils et effet budget
| # | Recommandation | Change avec un budget |
|---|---|---|
| 1 | Rester sur CloudKit base publique jusqu'à ce que `quota.md` ou `latence.md` dise le contraire (décision 2) | non |
| 2 | `ProfilPublic.recordName` dérivé du surnom : l'unicité vient de l'identifiant | non |
| 3 | `Blocage` en base privée | non |
| 4 | Pas de 12e type : une carte de club est une `Publication` avec `club` | non |
| 5 | Signalement : `mailto:` + enregistrement `Signalement` (avec le texte du message), la boîte lit les deux | non |
| 6 | Trois lecteurs de la boîte, un référent par semaine | non (du temps de personne) |
| 7 | Vidéo de 15 s : réduire seulement après mesure ; photo d'abord si le quota est serré | non |
| 8 | E-mail de signalement vraiment automatique + liste noire d'auteurs | **oui** (un petit service, futur) |
| 9 | Chat « à la seconde » ou notification visible fiable | **oui** (service temps réel) |
| 10 | Modération externe 24 h / 7 j | **oui** |
| 11 | Hébergement vidéo hors CloudKit si le quota casse | **oui** |
| 12 | Consentement avant de mettre un club local en ligne | non |
| 13 | Chat de club et d'ami en zones partagées, pas de `MessageClub` public | non |
Cadre MWM après le jury (publie-t-il, finance-t-il) : pas encore connu (`CLAUDE.md`). Tout ce qui est « non » ci-dessus tient sans budget (estimation) ; les quatre « oui » demandent un financement ou un accord MWM.

## Règles d'or : vérifiées
| Règle | Où elle tient |
|---|---|
| Aucun coin exact public | `lieuTexte` jamais interrogeable ; seul le département est indexé ; filtre de coordonnées ; recompression des médias (`schema.md`, `moderation.md`) |
| Collections jamais publiques | aucun type `Collection` en base publique ; une `Publication` est un post choisi |
| Pas de marché, pas de monnaie | aucun champ de prix ni d'échange |
Zone grise restante : le nom d'un cours d'eau + département peut désigner un coin à un connaisseur (choix du pêcheur, décision 4). Les messages ne sont plus publics (zones partagées).

## Questions restantes pour Adem
1. Une version avec clubs a-t-elle été distribuée à des testeurs extérieurs (`migration-clubs.md`) ? Sinon la migration est remplacée par « recréer son club ».
2. `Blocage` en base privée (au lieu de publique comme dans la fiche) : d'accord ? Par défaut : oui.
3. Mesures : accord pour que Sullyvan lance le prototype sur un conteneur d'essai (pas celui de l'app), avec deux comptes iCloud pour le test 4c ; combien de temps de Mac ?
4. Les deux iPhones d'un même compte : accepter la limite (`migration-clubs.md`).

## Points ⚠ (non lus ou à vérifier)
- Quotas CloudKit (stockage par utilisateur, requêtes, taille d'un asset) : non lus sur les pages Apple ; page de quotas en 404.
- Rôles de sécurité par type en base publique, dont la lecture de `Signalement` réservée à l'équipe ; `IN` sur un champ texte.
- Abonnements `CKRecordZoneSubscription` et `CKDatabaseSubscription` sur base partagée (test 4c).
- Clés exactes du manifeste de confidentialité ; 5.1.1(v) pour un profil sans mot de passe.
- Le prototype n'a jamais été compilé.
