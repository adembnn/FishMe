# Lots de construction

Version du 15 oct., refaite pour la vision d'Adem du 15 oct. (3 volets, `vision.md`), le kit MWM, l'atelier de Titouan et la décision « l'app vise toute la France ». Remplace la version du 12 oct. (git la garde).
Le critère commun est `parcours-demo.md` (étapes E1 à E9). Un lot = un dossier = une personne. Un lot qui possède `App/<X>/` possède aussi ses tests, `AppTests/<X>/` et `AppUITests/<X>/`. L'atelier (H0) lit ce tableau : la colonne « Branche » dit à quel lot appartient une branche, la colonne « Dossier » où ce lot peut écrire. Un lot ne rejoint `main` que par `scripts/fusionner.sh`, qui lance `scripts/verif.sh`, puis le banc d'essai (`/banc`) pour tout lot qui touche `App/`.

## Ce qui a changé depuis le 12 oct.
- L'app a 3 volets (Pescedex, Carte, Mon club) : la barre d'onglets entre dans L0, Mon club devient un lot (L9).
- La session (E4) entre dans la version soumise : le défaut du paywall (première session gratuite) en dépend. L'écran verrouillé reste pour la mise à jour (L10).
- « Où chercher ? » devient un filtre d'espèce sur la carte (dans L2) ; les coins publics viennent dans la mise à jour (L7). La « mission première prise » et son score (ancien C7) disparaissent.
- Les règles visent toute la France (D3), et la reconnaissance a son lot d'entraînement et de test (R1).
- Le projet Xcode est celui de MWM (`BuildChallenge.xcodeproj`), importé sur `lot/squelette`.

## Qui (par défaut, question 3 du tour 1, posée le 15 oct.)
- **A** : Adem, sur son Mac. Seul à toucher au projet Xcode (cibles, capacités, clés Info, `RootView.swift`). Carte, paywall, Mon club, envoi.
- **B** : Titouan, sur le Mac de Sullyvan, avec Claude Code. Prise, carte à collectionner, Pescedex, session.
- **C** : des sessions Claude Code dans le cloud, lancées et surveillées par Adem ou Titouan : le paquet `Core` (testé par `swift test` sous Linux), les données, la fiche App Store.
- **S** : Sullyvan, sans Claude : deuxième paire d'yeux sur les règles, photos et entraînement de la reconnaissance, appel à la fédération, relecture de la fiche.
Sur chaque Mac, plusieurs lots avancent en même temps, chacun dans sa copie du dépôt (`scripts/lot.sh <code>`) avec son agent ; la personne vérifie sur l'iPhone et fusionne.

## Dans la version soumise jeudi soir (périmètre par défaut, `parcours-demo.md`)
| Lot | Branche | Dossier | Étapes | Qui | Dépend de | Test qui bloque la fusion | Durée (estimation) |
|---|---|---|---|---|---|---|---|
| H0 Atelier | `lot/atelier` | `.claude/`, `.githooks/`, `.github/`, `.mcp.json`, `.gitignore`, `env.exemple`, `scripts/`, `outils/atelier/`, `fastlane/` | toutes | A | rien | `python3 outils/atelier/essai.py` : chaque garde-fou bloque son erreur provoquée ; `python3 outils/atelier/verifier_claude.py` vert ; `scripts/docteur.sh` vert sur les 2 Mac et dans le cloud | fait le 13 oct. ; reprise des agents de Titouan 1 h |
| L0 Squelette et 3 volets | `lot/squelette` | `BuildChallenge.xcodeproj`, `TestConfig.storekit`, `mwm-spark-flash-sdk/`, `App/BuildChallengeApp.swift`, `App/RootView.swift`, `App/Assets.xcassets/`, `AppTests/BuildChallengeTests.swift`, `AppUITests/BuildChallengeUITests.swift`, `App/PrivacyInfo.xcprivacy`, `.mobilebuildmcp/` | toutes | A | kit MWM (reçu le 15 oct.), Xcode 27 sur le Mac A | le projet de MWM compile et s'ouvre sur l'iPhone de test, iPhone seul en portrait ; barre de 3 onglets (Pescedex, Carte, Mon club), ouverte sur Carte, VoiceOver lit « onglet 2 sur 3 » ; T1 à T5 de `architecture.md` verts ; ensuite A branche chaque écran fusionné dans `RootView.swift` | 1 à 2 h |
| C0 Contrats | `lot/contrats` | `Packages/Core/Package.swift`, `Packages/Core/Sources/Core/Modele/`, `Packages/Core/Sources/Core/Contrats/`, `Packages/Core/Tests/CoreTests/Contrats/` | toutes | C | H0 | `swift test` vert sous Linux et sur Mac ; chaque contrat (`architecture.md`) a son faux dans `Core`, que A ne branche que sous `#if DEBUG` | 1 à 1,5 h |
| L1 Moteur de données | `lot/moteur` | `Packages/Core/Sources/Core/Regles/`, `Packages/Core/Sources/Core/Rarete/`, `Packages/Core/Sources/Core/Geo/`, `Packages/Core/Sources/Core/Soleil/`, `Packages/Core/Sources/Core/Session/`, `Packages/Core/Tests/CoreTests/Moteur/` | E1 E2 E3 E4 E5 E6 E7 E9 | C | C0, puis D1, D2 | `swift test` : 5 points dans le bon département ; les cas d'or de `cas-verdicts.json` justes ; la liste de contrôle ne contient jamais « tu peux la garder » ; une règle périmée (`expire_le` passé) donne « vérifie l'arrêté » ; deux tailles contradictoires donnent la plus stricte avec les deux sources ; les niveaux de rareté du 94 égaux à `donnees.md` ; filtre d'espèce (E3) avec N et l'année ; lever et coucher à 2 min près sur 5 dates ; quota du jour au 3e carnassier ; droit d'accès (1re session gratuite, puis abonnement) ; lune juste sur 3 dates | 4 à 6 h |
| D1 Données embarquées et règles Île-de-France relues | `lot/donnees` | `Packages/Core/Sources/Core/Resources/`, `outils/verifier_donnees.py` | E2 E4 E5 E6 | C | brouillon de 98 règles (`reports/regles-75-94.md`), puis D3 | `outils/verifier_donnees.py` : JSON valides, chaque règle a sa source, sa citation exacte, sa date de lecture et sa date de fin ; chaque règle du 75, 92, 93, 94, 77 relue par S contre l'arrêté (champ `verifie_par`) ; `liens-federations.json` (site officiel de chaque fédération départementale) et `credits.json` livrés ; 10 cas d'or au moins dans `cas-verdicts.json`, dont brochet 55 cm et sandre 45 cm | 3 à 5 h (C), plus 2 à 3 h de relecture (S) |
| D3 Règles de toute la France | `lot/regles-france` | `outils/regles/` | E2 E5 | C | consigne testée sur 3 départements pilotes (01, 87, 44) | pour chaque département : textes signés téléchargés et lus sur un ordinateur d'Adem (pas dans le cloud), deux lectures automatiques indépendantes, et seules les règles où elles disent la même chose sur le fond (type, espèce, dates, nombres, cours d'eau) passent, sans étiquette à l'écran (Adem, 15 oct.) ; une ligne en désaccord devient « vérifie l'arrêté » ; `outils/regles/consensus.py` sort 0 ; les fichiers retenus sont remis à D1, qui les charge | 4 à 8 h de calcul, surveillé |
| D2 Données Hub'Eau | `lot/hubeau` | `outils/hubeau/` (hors app) | E1 E2 E3 E6 | C | rien | France entière, depuis le script de Titouan (`harnais-titouan/Tools/data-pipeline`), lancé par GitHub Actions ou sur un Mac (le proxy du cloud bloque Hub'Eau) ; une station n'appartient qu'à un département ; fichiers publiés en pièce jointe d'une release privée, jamais commités | 2 à 4 h |
| R1 Reconnaissance | `lot/reconnaissance` | `outils/reconnaissance/` | E5 | S | rien | le jeu de test (liste des photos, licences) est commité avant tout entraînement ; aucune photo d'iNaturalist à l'entraînement ; `outils/reconnaissance/score.py` sur ce jeu : bonne espèce parmi 3 dans 90 % des cas au moins, en premier dans 70 % au moins (seuils proposés), l'IA d'Apple passe le même test sur un iPhone éligible ; un modèle n'est remis à L3 que s'il passe | 3 à 5 h, dont l'entraînement Create ML sur un Mac |
| L2 Carte, fiche et Où chercher | `lot/carte` | `App/Carte/` | E1 E2 E3 | A | L0, C0, puis L1 et D2 | sur iPhone : la carte s'ouvre sur l'Île-de-France sans demander la position ; « Autour de moi » la demande ; un coin affiche ses espèces avec N et l'année, et la liste de contrôle avec ses sources ; « Où chercher ? » filtre la carte par espèce en 3 touchers au plus ; position refusée : choix du département ; moins de 10 s à froid | 3 à 5 h |
| L3 Prise | `lot/prise` | `App/Prise/` | E5 | B | L0, C0, puis L1 et D1 (cas d'or), R1 si son modèle passe | sur iPhone, mode avion : 3 propositions (modèle de R1 s'il passe son test, sinon l'IA d'Apple seulement si elle passe le même test, sinon grille des 14 espèces), « pas un poisson », « je ne sais pas », critère des paires proches ; bouton « essayer avec une photo d'exemple » ; aucun pourcentage ; cas d'or justes | 3 à 6 h |
| L4 Carte à collectionner et Pescedex | `lot/collection` | `App/Collection/` | E6 E9 | B | L3, L5 (la `Sortie` de E9) | carte relue après avoir tué l'app ; fichier sans clé GPS ; carte d'exemple marquée et hors du compte ; volet Pescedex avec silhouettes et « N sur les M relevées dans le département » ; carte bredouille rangée à part ; détourage en dernier, repli sur la photo cadrée | 3 à 6 h |
| L5 Session | `lot/session` | `App/Session/` | E4 E9 | B | L0, L1 | sur iPhone : départ à 18 h 30 un jour d'octobre à Paris, fin légale juste à 2 min près ; 3 carnassiers gardés, « quota du jour atteint » ; l'app tuée retrouve la session ; fin sans prise : la `Sortie` passée par `RootView.swift` donne à L4 une carte bredouille avec sa durée | 1,5 à 3 h |
| L6 Paywall et mesure | `lot/abonnement` | `App/Abonnement/`, `App/Mesure/` | E7 | A | L0, L5, kit MWM | achat test avec `TestConfig.storekit` puis « Restaurer » ; tarif fondateur : l'annuel à 34,99 présélectionné jusqu'au 31 décembre 2026, le produit à 49,99 ensuite (date simulée dans un test) ; mensuel avec sa semaine d'essai ; sans abonnement, la 2e session ouvre le paywall mais la fiche et ses règles restent ouvertes ; aucun événement envoyé avant le consentement ; liens conditions et confidentialité | 2 à 4 h |
| L9 Mon club | `lot/club` | `App/Club/` | E8 | A | L0 | sur iPhone : fédération, association et carte de pêche en 2 touchers au plus, par des liens officiels ; partage d'une carte en image sans coordonnée ni métadonnée GPS ; page Sources depuis `credits.json` ; confidentialité, contact, « signaler une erreur de règle » | 1 à 2 h |
| S1 Fiche et conformité | `lot/store` | `store/` | toutes | C | nom de l'app | check-list de `app-store.md` cochée ; textes écrits par C, puis confidentialité et conditions publiées par A depuis un Mac avec le serveur MCP de MWM (injoignable depuis le cloud), après confirmation d'Adem ; captures depuis TestFlight ; notes en anglais pour le relecteur d'Apple (photo d'exemple, achat test) ; relu par S | 3 à 6 h |

## Dans la mise à jour (vendredi matin, montrée depuis TestFlight, soumise après l'approbation de la première)
| Lot | Branche | Dossier | Étapes | Qui | Dépend de | Test qui bloque la fusion | Durée (estimation) |
|---|---|---|---|---|---|---|---|
| L10 Écran verrouillé | `lot/ecran-verrouille` | `Widget/` | E4 | A | L5 | iPhone verrouillé : le compte à rebours tourne, puis « fin légale » à l'heure calculée ; départ hors de la fenêtre légale sans plantage | 1,5 à 3 h |
| L7 Où chercher : coins publics | `lot/ou-chercher` | `App/OuChercher/` | E3 | B | L2, couche des coins publics (OpenStreetMap, fédérations), fabriquée par C dans `outils/hubeau/` avec D2 | une espèce donne les 3 coins publics les plus proches où l'OFB l'a relevée, chacun avec N, l'année et « ouverte aujourd'hui » ou « fermée » ; aucun « meilleur coin » | 3 à 5 h |
| L8 Amis | `lot/amis` | `App/Amis/` | E8 | B | L4, outil choisi par Adem (`reports/amis.md`, CloudKit recommandé) | deux iPhones, deux comptes iCloud : la carte passe sans coordonnée exacte ; signaler et retirer un ami marchent | 10 à 18 h |
| L11 Règles à jour | `lot/veille` | `outils/veille/`, `Packages/Core/Sources/Core/MiseAJour/`, `Packages/Core/Tests/CoreTests/MiseAJour/` | E2 | C | D3, hébergement du fichier de règles (choix d'Adem) | l'app télécharge la dernière version publiée du fichier de règles et garde sa copie sans réseau ; une règle périmée ne donne jamais de feu vert ; chaque nuit, la veille ouvre une alerte quand un texte source change | 3 à 5 h |

## Calendrier (proposé, à partir de maintenant)
**Sans attendre de Mac** : C lance C0 puis L1, D1 (brouillon de 98 règles), D2 et D3 (pilotes 01, 87, 44, puis la France). S relit les règles du 75 et du 94 ligne par ligne, rassemble les photos de test de R1 et appelle la fédération 75/92/93/94 pour les tailles. B installe l'atelier sur le Mac de Sullyvan (`atelier-mac.md`). A finit l'installation d'Xcode 27.

**Dès qu'Xcode 27 marche chez A** : L0 (T1 à T5), puis `main` part de `claude/project-thread-78e20q` avec L0 fusionné.

**Ensuite, en parallèle**
| Moment | A | B | C | S |
|---|---|---|---|---|
| L0 + 0 à 4 h | L2, puis L9 | L3 (grille et verdict d'abord, puis la reconnaissance) | L1, D1, D3 | relecture D1, R1 |
| **porte 1** (L0 + 4 h) | L2 fusionné | L3 avec la grille fusionné | L1 vert, D1 chargé | jeu de test R1 commité |
| L0 + 4 à 7 h | L6 | L5, puis L4 | S1, D3 | R1 : entraînement et score |
| **porte 2** (L0 + 7 h) | achat test vert | L4 et L5 fusionnés | fiche prête | modèle remis à L3 ou écarté |
| L0 + 7 à 8 h | archive et envoi à Apple ; MWM demande la relecture accélérée | captures depuis TestFlight | notes pour le relecteur | « première minute » sur TestFlight : position refusée, mode avion, hors Île-de-France |

**Vendredi 16 oct.** : dès 7 h, quelqu'un lit l'e-mail d'Apple et publie à la main. L10, puis L7 ou L8 selon la réponse d'Adem, sur une version montrée depuis TestFlight. Répétition de la démo avec une vidéo de secours par étape.

## Si une porte saute
- Porte 1 sans L3 grille + liste de contrôle : B lâche la reconnaissance, la grille devient le parcours.
- Porte 1 sans L2 : « Où chercher ? » (E3) part dans la mise à jour.
- Porte 2 sans achat test : paywall natif d'Apple sans le SDK ; sans paywall du tout, la session reste gratuite et E7 part dans la mise à jour.
- D3 pas prêt : hors Île-de-France, le socle national et le lien de l'arrêté de la préfecture.
- Envoi dépassé de plus d'une heure : on envoie ce qui est vert, la suite part dans la mise à jour.
