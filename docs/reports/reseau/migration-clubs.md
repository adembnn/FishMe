# Migration des clubs locaux vers CloudKit
Décision débloquée : faire (ou non) la migration de `MesClubs` dans L22, et dans quel ordre avec L21 ; valider le consentement avant qu'un club local devienne lisible en ligne (décisions 1 et 6 du 19 oct.).
Lu le 19/10/2026 (code `App/Club/MesClubs.swift`, `ClubPageView.swift` l.387, `ClubDonnees.swift`, `DemoClub.swift` ; fiche L22).

## En bref
Image : aujourd'hui un club est un carnet dans la poche du pêcheur. Le mettre dans CloudKit, c'est afficher le carnet au tableau de la place du village : même contenu, autre public. Il faut donc demander avant, et pouvoir revenir en arrière.

## Ce qui existe sur l'iPhone
| Donnée | Où | Contenu |
|---|---|---|
| `ClubLocal` | `UserDefaults`, clé `club.mesClubs`, JSON | `id` (UUID), `nom`, `poissonId` ou `fichierPhoto`, `amisInvitesSeulement` (toujours vrai) |
| Photo du club | Application Support, `club-<uuid>.png` | PNG réécrit sans métadonnées par `ImageSansGPS` |
| Cartes partagées | `UserDefaults`, clé `club.cartesPartagees` | dictionnaire `id de club -> ensemble d'identifiants de cartes` : des identifiants, pas les images |
| Membres | nulle part | `ClubLocal` n'a pas de liste de membres : le seul membre d'un club local est son propriétaire |
| Démo | `DemoClub.swift` | deux clubs fictifs, jamais écrits dans CloudKit |
Conséquence : migrer un club, c'est créer un `Club`, un `Membre` fondateur et des `Publication` pour ses cartes. Il n'y a **aucun autre membre à reconstituer**.

## Correspondance vers le schéma (`schema.md`)
| Local | CloudKit | Remarque |
|---|---|---|
| `ClubLocal.id` | `Club.recordName` | même UUID : la migration est idempotente |
| `nom`, `poissonId` | `Club.nom`, `Club.poissonId` | |
| `fichierPhoto` | `Club.image` (`CKAsset`) | recompresser en JPEG sans EXIF, 512 px (estimation raisonnable, à régler en L22) |
| (le pêcheur) | `Membre` `m-<club>-<profil>`, rôle fondateur | exige un `Profil` (L21) |
| carte partagée | `Publication` `pc-<club>-<carte>`, champ `club` rempli | image = PNG de `Collection`, sans GPS, lieu = département seul |
| `amisInvitesSeulement` | supprimé | n'a plus de sens : un club est lisible par son lien |

## Ce qui change pour le pêcheur : le consentement
Un club local était privé. En base publique, **quiconque connaît l'identifiant du club peut lire son nom, son image et ses cartes** (`schema.md`). Même sans annuaire, ce n'est plus « amis invités seulement » (le texte actuel de `ClubLocal` et de la ligne du 12 oct.). La décision 1 du 19 oct. remplace cette ligne, mais le pêcheur qui a créé son club avant ne l'a pas accepté.
Recommandation : un écran unique à la première ouverture après la mise à jour. Pour chaque club : « Mettre en ligne » ou « Garder sur cet iPhone », avec un texte sur ce qui devient visible. Pas de migration silencieuse. Appui : [5.1.2(ii)](https://developer.apple.com/app-store/review/guidelines/) (une donnée recueillie pour un usage ne se réutilise pas sans nouveau consentement). Change avec un budget : non.
Un club gardé sur l'iPhone reste un club local : il continue de fonctionner comme avant, sans chat ni fil de club.

## Ordre et déclenchement
1. L21 d'abord : pas de `Membre` sans `Profil`. Si le pêcheur n'a pas de surnom, l'écran de migration lui demande « Finis ton profil » avant de continuer, sans bloquer le reste de l'app.
2. Migration lancée au démarrage par A (`RootView`), jamais en arrière-plan sans écran.
3. Un club à la fois : `Club`, puis `Membre`, puis les cartes par lots de 20 (limite de lots du code existant `ServiceAmisCloudKit`).
4. Un drapeau **par club** (`clubs.migre.<uuid>`), plus un drapeau global quand tous sont faits. La fiche L22 ne prévoit qu'un drapeau global (`clubs.migres`) : si la migration échoue au 3e club, un drapeau global rejouerait les trois. Recommandation : drapeau par club ; change avec un budget : non.
5. Idempotence : les identifiants (`recordName`) sont déterministes, donc une écriture rejouée ne crée pas de doublon. Si l'enregistrement existe déjà (`serverRecordChanged`), c'est un succès. Pas de recherche préalable par `id` local (piège de la fiche L22) : l'identifiant suffit.

## Cas limites
| Cas | Comportement |
|---|---|
| Pas de compte iCloud | les clubs restent locaux, la page le dit, réessai au lancement suivant ; `CloudKitPermis.actif` est faux dans les archives de repli |
| Réseau coupé en cours | reprise au lancement suivant, club par club |
| Deux iPhones du même compte | chaque appareil a ses propres UUID : deux clubs distincts, pas de fusion (limite acceptée, à dire) |
| Pas de carte retrouvée (carte supprimée entre-temps) | ignorée, jamais une erreur bloquante |
| Surnom refusé ou déjà pris | retour à L21, la migration attend |
| Nom de club inapproprié | passe par le filtre de `moderation.md` ; refusé, le club reste local |
| Photo avec EXIF (ancien fichier) | recompressée avant envoi ; test `exiftool` sur le fichier téléchargé |
| Désinstallation et réinstallation | le club en ligne existe, le local non : « Rejoindre » par lien ; la sauvegarde `App/Compte/` reprend les clubs (accord de A) |

## Retour en arrière
- Garder la copie locale (`club.mesClubs`) 30 jours après la migration (estimation, à fixer par Adem), puis la supprimer. Recommandation : sans copie, une erreur de migration est irréparable. Change avec un budget : non.
- « Fermer le club » (fondateur seul) : `Club.ferme` = 1 et suppression de ses propres `Publication` ; les cartes des autres membres restent lisibles tant qu'ils ne les ont pas retirées (seul le créateur d'un enregistrement le supprime) : l'écran le dit.
- « Supprimer mon profil » (L21) efface aussi les clubs dont il est fondateur et leurs cartes, via `EffaceurContenu`.

## À demander à Adem avant de coder
1. Une version avec clubs a-t-elle déjà été distribuée à des testeurs extérieurs à l'équipe ? FishMe n'est pas encore publiée (`CLAUDE.md`, « Après le jury »). Si non, les seuls clubs locaux sont ceux de l'équipe et la migration (environ 1,5 h, estimation de la fiche L22) peut être remplacée par « recréer son club ». Recommandation : sauter la migration si la réponse est non ; change avec un budget : non.
2. Un club migré passe en ligne : confirmer le texte du consentement (`cgu-confidentialite.md`).
3. Les deux iPhones d'un même compte : accepter la limite.

## Tests (pour L22)
Club local créé sur l'ancienne version -> mise à jour -> écran de consentement -> club en ligne avec ses cartes ; second lancement sans doublon ; refus du consentement : club local intact ; mode avion pendant la migration, reprise ; `exiftool` sur la photo du club et sur une carte ; `DemoClub` inchangé.
