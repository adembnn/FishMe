# Lots de construction

Version du 12 oct., 17h. Remplace le premier jet de 15h40 après les quatre évaluations (`reports/eval-*.md`).
Le critère commun est `parcours-demo.md` (étapes E1 à E9). Un lot = un dossier = une personne. Un lot ne rejoint `main` que par `scripts/fusionner.sh`, qui lance `scripts/verif.sh` et refuse si un test échoue.

## Ce qu'on a appris en faisant attaquer le premier jet
- Le premier jet demandait environ deux fois le temps disponible avant le gel de 14 h, même en bas de fourchette (`reports/eval-ios.md` §1, estimation).
- Le relecteur d'Apple n'a ni poisson ni ami : E5 doit offrir une photo d'exemple, et E8 ne peut pas être prouvé par lui seul (`reports/eval-apple.md` R1, R5).
- Paris n'a que des relevés OFB de 1989 à 2011 : chaque fiche affiche « N pêches, dernier relevé AAAA » (`reports/eval-mwm.md` §1).
- Les données saisies (D1) demandent 8 à 12 h, pas 3 à 4 : elles se font avant jeudi.

## Qui
- **A** (Mac) : seul à toucher au projet Xcode (cibles, capacités, clés Info, `RootView.swift`). Carte, paywall, envoi.
- **B** (Mac) : prise, carte à collectionner, Pescedex.
- **C** (sans Mac) : le paquet `Core` depuis une session Claude Code dans le cloud (logique sans écran, testée par `swift test` sous Linux), les données, la fiche App Store.

## Dans la version soumise jeudi (périmètre par défaut, question 1 de `README.md`)
| Lot | Dossier | Étapes | Qui | Dépend de | Test qui bloque la fusion | Durée (estimation) |
|---|---|---|---|---|---|---|
| L0 Squelette et cas réel | `Projet.xcodeproj`, `App/App.swift`, `App/RootView.swift`, `scripts/`, `.gitignore` | toutes | A | accès MWM | T1 à T5 de `architecture.md` verts ; ensuite A branche chaque écran fusionné dans `RootView.swift` | 1,5 à 3 h |
| C0 Contrats | `Packages/Core/Package.swift`, `Packages/Core/Sources/Core/Modele/`, `Packages/Core/Sources/Core/Contrats/`, `Packages/Core/Tests/CoreTests/Contrats/`, `.github/` | toutes | C | rien | `swift test` vert sous Linux et sur Mac ; chaque contrat a son faux dans `Core`, que A ne branche que sous `#if DEBUG` ; CI Linux verte | 1 à 1,5 h |
| L1 Moteur de données | `Packages/Core/Sources/Core/Regles/`, `Packages/Core/Sources/Core/Rarete/`, `Packages/Core/Sources/Core/Geo/`, `Packages/Core/Sources/Core/Soleil/`, `Packages/Core/Tests/CoreTests/Moteur/` | E1 E2 E5 E6 E9 | C | C0, D1, D2 | `swift test` : 5 points dans le bon département ; 5 cas de `cas-verdicts.json` justes ; les 14 niveaux de rareté du 94 égaux à la liste de `donnees.md` (commun, peu commun, rare, légendaire) ; les espèces proches d'un quai de Charenton donnent N et l'année ; lever et coucher à 2 min près sur 5 dates ; phase de lune juste sur 3 dates | 3 à 5 h |
| L2 Carte et fiche | `App/Carte/` | E1 E2 | A | L0, C0, puis L1 et D2 | sur iPhone : la carte s'ouvre sur l'Île-de-France sans demander la position ; « Autour de moi » la demande ; un coin affiche ses espèces et « N pêches, dernier relevé AAAA » ; position refusée : choix du département ; moins de 10 s à froid | 2 à 4 h |
| L3 Prise | `App/Prise/` | E5 | B | L0, C0 | sur iPhone, mode avion : 3 propositions avec IA, grille des 14 espèces sans IA ; choix « pas un poisson » ; bouton « essayer avec une photo d'exemple » ; 5 cas de verdict justes | 3 à 6 h |
| L4 Carte à collectionner et Pescedex | `App/Collection/` | E6 E9 | B | L3 | carte relue après avoir tué l'app ; fichier sans clé GPS ; le bouton « je rentre sans poisson » crée la carte bredouille (lieu flouté, date, lune), rangée à part ; détourage en dernier, repli sur la photo cadrée | 3 à 6 h |
| L6 Paywall, mesure et page Sources | `App/Abonnement/`, `App/Mesure/`, `App/APropos/` | E7 | A | L0, kit MWM | achat test puis « Restaurer » ; essai affiché « 1 mois » depuis StoreKit ; liens conditions et confidentialité ; aucun événement avant le consentement ; page Sources avec les crédits de `credits.json` et un contact | 2 à 4 h |
| D1 Données saisies | `Packages/Core/Sources/Core/Resources/`, `outils/verifier_donnees.py` | E1 E2 E5 E6 | C | `donnees.md` | `cas-verdicts.json` inclus ; relecture croisée par une 2e personne contre l'arrêté ; jeudi 9 h, `outils/verifier_donnees.py` : JSON valides, chaque règle a sa source et sa date | 8 à 12 h, avant jeudi |
| D2 Données Hub'Eau | `outils/hubeau/` (hors app) | E1 E2 E6 | C | question 3 de `README.md` | une station n'appartient qu'à un département. Réponse a : export tableur pour les 5 départements, avant jeudi. Réponses b et c : script France entière. Dans les deux cas, fichiers publiés en pièce jointe d'une release privée, jamais commités | 2 à 4 h avant jeudi |
| S1 Fiche et conformité | `store/` | toutes | C | nom de l'app | check-list de `app-store.md` cochée ; fiche écrite depuis le build TestFlight | 5 à 9 h, textes avant jeudi |

## Dans la version suivante (vendredi matin, montrée depuis Xcode, soumise après l'approbation de la première)
| Lot | Dossier | Étapes | Qui | Dépend de | Test qui bloque la fusion | Durée (estimation) |
|---|---|---|---|---|---|---|
| L5 Session et Live Activity | `App/Session/`, `Widget/` | E4 E9 | A | L0, L1 (fin légale), L4 | iPhone verrouillé : compte à rebours, puis « fin légale » ; départ hors de la fenêtre légale sans plantage ; fin de session sans prise : la `Sortie` passée par `RootView.swift` donne à L4 une carte bredouille avec sa durée | 1,5 à 3 h |
| C7 Score de mission | `Packages/Core/Sources/Core/Mission/`, `Packages/Core/Tests/CoreTests/Mission/` | E3 | C | L1 | `swift test` : même position et même date donnent toujours la même proposition ; sans météo, proposition calculée sans elle et marquée « météo indisponible » | 1 à 2 h |
| L7 Mission première prise | `App/Mission/` | E3 | B | C7, WeatherKit | une position et une date donnent une proposition complète en 3 écrans ; mention Apple Weather visible | 2 à 4 h |
| L8 Amis | `App/Amis/` | E8 | B | L4, outil choisi par Adem (`reports/amis.md`) | deux iPhones, deux comptes iCloud : la carte passe sans coordonnée exacte ; signaler et retirer un ami marchent | 10 à 18 h |

## Calendrier
**Avant jeudi** : voir `avant-jeudi.md` (accès MWM, installations, iPhones, données D1 et D2, textes S1, photos de test). Aucune ligne de code de l'app. C seul ne tient pas les 15 à 25 h de D1, D2 et S1 (estimation) : A et B lisent chacun des arrêtés pour D1.

Les documents cités sans chemin (`lots.md`, `fiches/L3.md`, `reports/...`) sont dans `build/` du dossier du projet et dans `docs/` du dépôt.

**Jeudi 15 oct.**
| Heure | A | B | C |
|---|---|---|---|
| 8 h 30 | ligne 0 de `app-store.md` vérifiée | IA disponible sur son iPhone | session cloud prête, Docker lancé |
| 9 h à 10 h 30 | L0 : T1, T3, T4 (TestFlight à 10 h 30), T5 | T2 (IA + photo en mode avion), puis 20 photos réelles dans l'IA | C0 ; A ajoute `Core` au projet vers 9 h 45 ; contrats gelés à 10 h |
| 10 h 30 à 12 h 30 | L2 | L3 : grille et verdict, puis IA | L1 |
| 12 h 30 | **porte 1** : L2 et L3 (grille) fusionnés, sinon on réduit L2 à la fiche d'un coin | idem | CI Linux sur `Core` |
| 13 h à 14 h | tampon, 2e envoi TestFlight | L4 sans détourage | D1 chargé, `cas-verdicts.json` passé |
| 14 h | **gel des fonctions** | gel (L4 peut finir jusqu'à 15 h 30) | gel |
| 14 h à 15 h 30 | L6 paywall (SDK si livré) | fin de L4, corrections | S1 : notes en anglais pour le relecteur, pages web |
| 15 h 30 | **porte 2** : achat test vert, sinon paywall natif sans SDK | captures depuis TestFlight | questionnaire d'âge, étiquettes de confidentialité (rôle App Manager) |
| 16 h à 17 h 30 | archive, envoi à la relecture, MWM demande la relecture accélérée | vidéo de 60 s pour le relecteur | « première minute » sur TestFlight : position refusée, mode avion, hors des 5 départements |

**Vendredi 16 oct.** : dès 7 h, quelqu'un lit l'e-mail d'Apple et publie à la main. L5 d'abord, puis L8 ou L7 selon la réponse d'Adem, sur une version montrée depuis Xcode. Répétition de la démo avec une vidéo de secours par étape.

## Si une porte saute
- 12 h 30 sans L3 grille + verdict : B lâche l'IA, la grille devient le parcours.
- 15 h 30 sans achat test : paywall natif d'Apple sans le SDK ; sans paywall du tout, c'est le périmètre « minimum » (question 1, option c).
- Gel dépassé de plus d'une heure : on envoie ce qui est vert, la suite part dans la version suivante.
