# R2 en une page : décisions débloquées, budget, questions pour Adem
Décision débloquée : valider R2 pour ouvrir la vague 2 (L21, L22, L23, L24, S2), ou revenir sur CloudKit (décision 2) ; chaque ligne dit ce qui manque.
Lu le 19/10/2026. Mesuré le : à mesurer (rien n'est mesuré, Sullyvan n'a pas encore lancé `outils/reseau/`).

## Où on en est
| Fichier | Contenu | État |
|---|---|---|
| `schema.md` | 9 types d'enregistrement + 2 hors base publique, droits, index, requêtes du feed | écrit, à valider |
| `quota.md` | quota et projection | méthode écrite, **chiffres à mesurer** |
| `latence.md` | 20 abonnements | méthode écrite, **chiffres à mesurer** |
| `moderation.md` | circuit de la règle 1.2 | écrit ; **nom de la personne de garde à renseigner par Adem** |
| `migration-clubs.md` | clubs locaux vers CloudKit | écrit, à valider |
| `cgu-confidentialite.md` | paragraphes à changer | brouillon, relecture MWM |
| `juridique-et-risques.md` | App Review 1.2, 5.1.1, 5.1.2, manifeste | écrit |
Prototype : `outils/reseau/` (code non compilé, mode d'emploi pour Sullyvan, modèle `RESULTATS.md`).

## Ce que chaque lot peut lancer, et à quelle condition
| Lot | Peut démarrer | Sous condition |
|---|---|---|
| L21 Profil et amis | oui, sur `schema.md` (`Profil` à `recordName` dérivé du surnom, `ProfilPrive`) | personne de garde nommée avant la fusion ; `Blocage` en base privée si Adem accepte |
| L22 Clubs | oui | réponse sur la migration (`migration-clubs.md`, question 1) ; pas de type `CartePartageeClub` |
| L23 Feed | le fil **photo** oui ; la **vidéo** attend `quota.md` | quota mesuré ; choix « sans lieu » (question 3) |
| L24 Chat | le chat de club oui ; les messages d'amis attendent `latence.md` | `CKQuerySubscription` sur base partagée à vérifier |
| S2 Juridique | oui | relecture des textes par MWM |

## Conseils et effet budget
| # | Recommandation | Change avec un budget |
|---|---|---|
| 1 | Rester sur CloudKit base publique jusqu'à ce que `quota.md` ou `latence.md` dise le contraire (décision 2) | non |
| 2 | `Profil.recordName` dérivé du surnom : l'unicité vient de l'identifiant | non |
| 3 | `Blocage` en base privée | non |
| 4 | Pas de 10e type : une carte de club est une `Publication` avec `club` | non |
| 5 | Signalement : `mailto:` + enregistrement `Signalement`, la garde lit les deux | non |
| 6 | Deux personnes nommées pour la boîte (titulaire + remplaçant) | non (du temps de personne) |
| 7 | Vidéo de 15 s : réduire seulement après mesure ; photo d'abord si le quota est serré | non |
| 8 | E-mail de signalement vraiment automatique + liste noire d'auteurs | **oui** (un petit service) |
| 9 | Chat « à la seconde » ou notification visible fiable | **oui** (service temps réel) |
| 10 | Modération externe 24 h / 7 j | **oui** |
| 11 | Hébergement vidéo hors CloudKit si le quota casse | **oui** |
| 12 | Consentement avant de mettre un club local en ligne | non |
Cadre MWM après le jury (publie-t-il, finance-t-il) : pas encore connu (`CLAUDE.md`). Tout ce qui est « non » ci-dessus tient sans budget (estimation) ; les quatre « oui » demandent un financement ou un accord MWM.

## Règles d'or : vérifiées
| Règle | Où elle tient |
|---|---|
| Aucun coin exact public | `lieuTexte` jamais interrogeable ; seul le département est indexé ; filtre de coordonnées ; recompression des médias (`schema.md`, `moderation.md`) |
| Collections jamais publiques | aucun type `Collection` en base publique ; une `Publication` est un post choisi |
| Pas de marché, pas de monnaie | aucun champ de prix ni d'échange |
Mais deux zones grises : le nom d'un cours d'eau + département peut désigner un coin à un connaisseur (choix du pêcheur, décision 4), et un message de club en base publique est lisible par tous (`schema.md`).

## Questions ouvertes pour Adem
1. Qui lit fishme.app@gmail.com chaque jour, et qui le remplace ? [à renseigner par Adem]. Bloque la fusion de L23.
2. Chat de club en base publique (décision 6) = lisible par quiconque a le lien. Acceptable, ou chat de club seulement par amis de la zone partagée en v1 ? Par défaut : accepté avec une phrase d'avertissement dans l'écran.
3. Une publication « Aucun lieu » doit-elle quand même apparaître dans « Dans ta région » ? Pour cela il faudrait publier le département, ce qui contredit « aucun lieu ». Par défaut : non, elle reste dans les sections amis et clubs.
4. `Blocage` en base privée (au lieu de publique comme dans la fiche) : d'accord ? Par défaut : oui.
5. Le réseau est-il gratuit ou dans le Pro ? Les CGU (article 3) doivent le dire. Par défaut : gratuit, à confirmer par Adem.
6. Réponse sur les clubs déjà distribués à des testeurs extérieurs (`migration-clubs.md`).
7. Mesures : accord pour que Sullyvan lance le prototype sur un conteneur d'essai (pas celui de l'app) ; combien de temps de Mac ?
8. Âge minimal 15 ans pour publier : confirmé ?

## Points ⚠ (non lus ou à vérifier)
- Quotas CloudKit (stockage par utilisateur, requêtes, taille d'un asset) : non lus sur les pages Apple ; page de quotas en 404.
- Rôles de sécurité par type d'enregistrement en base publique ; `IN` sur un champ texte ; `CKQuerySubscription` sur base partagée.
- Clés exactes du manifeste de confidentialité.
- 5.1.1(v) pour un profil sans mot de passe.
- Le prototype n'a jamais été compilé.
