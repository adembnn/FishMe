# Évaluation iOS : structure, vérification et calendrier de jeudi
Décision débloquée : la structure du projet, la vérification qui bloque la fusion et le calendrier réaliste de jeudi
Lu le 12/10/2026. [?] = non vérifié. « Estimation » = mon chiffre, pas une mesure. Rien n'a été compilé : ce bac à sable n'a ni Mac, ni Xcode, ni Swift.

## Version simple
Une cuisine à trois cuisiniers : au lieu de douze petits plans de travail séparés, un seul plan commun pour tout ce qui se prépare sans feu (le paquet `Core`), et chacun garde son fourneau (son dossier). Les lots de `lots.md` demandent le double du temps disponible, même en version minimale (estimation). Douze paquets Swift (des dossiers de code compilés chacun comme une petite bibliothèque) coûtent plus de temps aux débutants qu'ils n'en font gagner. `Core` regroupe la logique sans écran (règles, rareté, département, soleil, score de mission) : elle se teste en secondes sur Mac et sous Linux, donc le 3e étudiant peut l'écrire depuis le cloud. Pour tenir le gel de 14 h, il faut renoncer à E8, à l'écran de E3 et à E4 (Live Activity), qui passent à vendredi.
Lexique : `xcodebuild` = Xcode en ligne de commande ; `swift test` = lance les tests d'un paquet sans Xcode ; simulateur = iPhone virtuel sur le Mac ; CI = ordinateur loué qui lance les tests à chaque envoi de code ; `project.pbxproj` = fichier central du projet Xcode, source de conflits entre deux Mac ; TestFlight = envoi d'un build de test via Apple ; Live Activity = affichage sur écran verrouillé ; Foundation Models = IA d'Apple dans l'iPhone ; SwiftData = base locale ; CloudKit = stockage iCloud.

## 1. Re-chiffrage des lots (2 débutants + Claude Code, fourchettes = estimations)
Disponible avant 14 h : 5 h par Mac, environ 4 h utiles après repas et attentes (build, simulateur, iPhone).
| Lot | lots.md | Ma fourchette | Ce qui va coincer | Dérisquer |
|---|---|---|---|---|
| L0 squelette | 1 h | 1,5 à 3 h | invitation MWM, identifiant d'app, cible widget, capacités, isolation « main-actor » des nouveaux projets | mercredi : Xcode 27.0, simulateur iOS 27 lancé une fois ; cas réel de 9 h (§5) |
| L1 moteur | 2 h | 3 à 5 h (par C) | une règle de département remplace la nationale, MultiPolygon, PDF de préfecture illisibles (77, 92, 94, donnees.md) | 5 règles et 5 points en fixtures mercredi ; `incertain` bloque le verdict |
| L2 carte | 2 h | 2 à 4 h | `Map` SwiftUI sans regroupement, JSON de 1 à 2 Mo lu sur le fil principal, « 10 s à froid » à mesurer sur iPhone | 150 coins au plus, chargement en tâche de fond, département choisi à la main |
| L3 prise | 2 à 3 h | 3 à 6 h | pas de caméra au simulateur ; API iOS 27 sans doute absentes du savoir de Claude (arrêté en juin 2026) ; doublons dans les 3 propositions | donner à Claude les pages Apple en `.md` ; grille et verdict d'abord, IA ensuite |
| L4 carte | 2 à 3 h | 3 à 6 h (sans détourage), 4 à 8 h avec | design de la carte (décision d'Adem), détourage, retrait du GPS, SwiftData | sans détourage d'abord ; SwiftData bloqué 45 min : JSON + PNG |
| L5 session | 2 h | 1,5 à 3 h | extension widget, 4 présentations obligatoires, test écran verrouillé = attente réelle | vendredi (Q1), minuteur de 2 min au cas réel si gardé |
| L6 paywall | 1 à 1,5 h | 2 à 4 h | kit MWM jeudi, contrat « Paid Apps », produit prêt pour relecture, consentement avant le SDK | écran natif StoreKit + fichier `.storekit` local, SDK ensuite |
| L7 mission | 2 h | 3 à 5 h | WeatherKit : environ 30 min d'attente après création de l'identifiant (archi-ios.md) | score pur dans `Core` (C) ; écran après le dépôt |
| L8 amis | 6 à 10 h | 10 à 18 h | 2 comptes iCloud, schéma à déployer en Production, signaler/bloquer/supprimer (3 à 5 h, app-store.md) | hors build soumis |
| D1 données | 3 à 4 h | 8 à 12 h | 3 PDF à lire à la main, 14 espèces à recouper (donnees.md : 10 à 12 h pour 3 personnes) | avant jeudi |
| S1 fiche | 4 à 6 h | 5 à 9 h | bloquée tant que le nom manque ; formulaires réservés aux rôles Admin et App Manager | textes avant jeudi, captures de 14 h à 16 h |
Arithmétique, versions minimales, bas / milieu / haut : Mac A (L0, L2, L5, L6) 7 / 10,5 / 14 h ; Mac B (L3, L4) 6 / 9 / 12 h ; une heure d'archive, captures et envoi en plus. Disponible de 9 h à 16 h hors repas : 6,5 h. Même en bas de fourchette, A ne boucle pas L0 + L2 + L5 + L6 avant 16 h, et le gel de 14 h ne tient pour aucun Mac. Deux worktrees Claude Code par Mac (L2 et L5 sont dans des dossiers disjoints) gagneraient 30 % au plus (estimation), non compté.
Tient avant 14 h, fourchette basse : L0, L1 (par C), L2 minimale, L3 grille + verdict. Tient avant 16 h, fourchette basse : L3 avec IA, L4 sans détourage, L6. Ne tient pas : E4 avec E7, écran L7, L8, détourage, D1 complet jeudi.
Portes : 12 h 30, L2 et L3 grille fusionnés, sinon B reprend la fiche de A. 14 h, gel : un lot commencé (L4) finit au plus tard à 15 h 30. 15 h 30, L6 vert, sinon paywall natif sans SDK, puis sans E7.

## 2. Structure du projet (probabilité qu'un autre LLM la propose : estimation)
| # | Option | Proba | Verdict |
|---|---|---|---|
| 1 | coque + 12 paquets locaux (archi-ios.md) | 55 % | écartée : coût de débutant |
| 2 | un paquet `Core` + app en dossiers synchronisés, un dossier par lot (lots.md) | 45 % | retenue, `Core` compatible Linux |
| 3 | aucun paquet, tout en dossiers synchronisés | 25 % | écartée : la logique ne se teste plus sans simulateur ni Linux |
| 4 | projet généré par XcodeGen ou Tuist | 30 % | secours, si le fichier projet est en conflit |
| 5 | **`Core` dans un dépôt Git séparé, versionné par étiquette** | **8 %** | écartée : deux dépôts, deux Mac à mettre à jour |
| 6 | **un Mac écrit, l'autre teste sur iPhone** | **10 %** | écartée : capacité divisée par deux |
Raisons, avec sources Apple :
- Fichier projet : les notes d'Xcode 16 décrivent des dossiers constructibles (« buildable folders », les dossiers synchronisés d'archi-ios.md) qui « n'enregistrent que le chemin du dossier » dans le fichier projet et évitent les conflits (https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes.md). Chaque paquet local s'ajoute à la main à chaque cible (https://developer.apple.com/documentation/xcode/organizing-your-code-with-local-packages.md) : 12 paquets font 12 retouches du fichier central, toutes par Mac A, donc une file d'attente pour Mac B.
- `public` (mot-clé qui rend visible hors du module) : l'accès `Bundle.module` aux ressources est interne au paquet, il faut une constante publique pour l'ouvrir (https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package.md). Douze paquets font douze façades et des centaines de `public` ; un seul `Core` en demande une.
- Isolation (quel fil a le droit de toucher quoi) : les projets créés avec Xcode 26 passent en « main-actor par défaut », d'où des erreurs aux frontières de protocoles (fil de forum : https://forums.swift.org/t/explosion-of-isolation-violations-in-xcode-26-beta-6/81696 ; valable en Xcode 27 [?]). Moins de frontières, moins d'erreurs.
- Vitesse : archi-ios.md compte 4 paquets de logique pure sur 12. Les 8 autres touchent SwiftUI, Vision ou ActivityKit et se testent au simulateur de toute façon.
- Perte : le compilateur n'interdit plus à `Carte` de lire `Prise`. Remède : une règle dans le `CLAUDE.md` du dépôt (un dossier n'importe que `Core` et lui-même) et un `grep` dans `verif.sh`.
Règles du dépôt : A seul touche cibles, capacités, clés Info, cible `AppTests` et `RootView.swift` ; `Core/Contrats` (3 protocoles : IA d'espèce, météo, achats, avec un faux chacun) gelé à 10 h, ajouts seulement ; JSON dans `Packages/Core/Sources/Core/Resources/`, tenus par C ; `@Model` SwiftData dans `App/Collection`, jamais dans `Core`. `Core` n'importe que Foundation ; `SessionAttributes` est entouré de `#if canImport(ActivityKit)`. Ni `MKGeoJSONDecoder` ni `CLLocationCoordinate2D` : une structure `Coordonnee` et un décodeur GeoJSON en `Codable`.

## 3. Vérification qui bloque la fusion
Choix : un script local sert de barrière, la CI ne sert pas de barrière. Sur un dépôt privé en GitHub Free, les branches protégées (le réglage qui interdit de fusionner tant qu'un test échoue) ne sont pas disponibles : Pro, Team ou Enterprise requis (https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches). Si le dépôt de MWM est sous un forfait Team, cela change [?].
`scripts/verif.sh` (sort 0 ou 1, à valider jeudi 9 h [?]) :
1. `swift test --package-path Packages/Core` : 20 à 60 s (estimation), même commande sur Mac et sous Linux.
2. `xcodebuild test -project <Projet>.xcodeproj -scheme App -destination 'platform=iOS Simulator,name=<iPhone>' -only-testing:AppTests/<Lot>Tests -quiet` : compile l'app, lance les tests du lot ; 3 à 6 min la 1re fois, 1 à 3 min ensuite (estimation). Syntaxe lue dans https://keith.github.io/xcode-man-pages/xcodebuild.1.html ; nom du simulateur : `xcrun simctl list devices available`.
3. un `grep` des frontières entre dossiers.
`scripts/fusionner.sh lot/<nom>` : copie propre (`git worktree`), fusion avec `main`, `verif.sh`, puis fusion et envoi seulement si 0. C'est le seul chemin vers `main`. C fusionne seul ses changements de `Core` qui ne font qu'ajouter (étapes 1 et 3 sous Linux) ; les Mac lancent l'étape 2 à chaque `git pull`.
Limite : E5 et E7 se jugent sur l'iPhone (parcours-demo.md). Le script teste la logique avec un faux de l'IA ; StoreKit passe par StoreKitTest ; l'IA réelle se coche à la main dans le message de fusion.
CI Linux, utile et presque gratuite : `ubuntu-latest`, conteneur `swift:6.4`, `swift test` sur `Core`. Linux coûte 0,006 $/min contre 0,062 $ pour macOS, 2 000 minutes incluses en Free privé (https://docs.github.com/en/billing/concepts/product-billing/github-actions). Elle donne un retour à C sans Mac. À écrire jeudi, 10 min.
CI macOS, à garder pour vendredi : étiquette `xcode-27` ou `xcode-27-xlarge`, arm64 seulement, « public preview » (https://github.blog/changelog/2026-09-10-xcode-27-runner-image-now-runs-on-macos-27). Image du 6/10 : Xcode 27.0 par défaut, 27.1 et 27.2 bêta 2, macOS 27.0.1 (https://github.com/actions/runner-images/blob/releases/xcode-27-arm64/20261006/images/macos/xcode-27-arm64-Readme.md, lu par un résumeur [?]). `macos-26` plafonne à Xcode 26.6 (image du 31/08) : pas de SDK iOS 27. Un site tiers donne 200 minutes macOS incluses (https://cicdcalculator.com/github-actions-free-tier [?]) ; sans moyen de paiement, l'usage est bloqué une fois le quota épuisé. Exécuteur standard ou « larger » (facturé toujours) : non dit [?]. Pas d'Apple Intelligence dans une machine virtuelle [?] : l'IA ne s'y teste pas.

## 4. Le 3e étudiant sans Mac
Tranché : oui, il écrit du Swift utile, dans `Core` seulement, à condition que `swift test` tourne avant jeudi 9 h.
- Convient : règles et verdict, rareté, point dans un polygone, distance, soleil (formule NOAA, tolérance 2 min : écarts de 32 et 67 s mesurés dans donnees.md), score de mission, lecture des JSON.
- Ne convient pas : tout ce qui importe SwiftUI, MapKit, CoreLocation, SwiftData, Vision, ActivityKit ou FoundationModels (cadres d'Apple, absents de Linux ; à confirmer au premier test [?]).
- Chaîne : la session cloud est un Ubuntu 24.04 x86_64 avec Docker mais sans Swift (https://code.claude.com/docs/en/cloud-environments). Voie Docker : Docker Hub est dans la liste blanche par défaut, l'image `swift:6.4` existe en amd64 et arm64 (`docker manifest inspect`, mesuré aujourd'hui), et Swift 6.4 est celui de Xcode 27 (https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes.md, https://www.swift.org/install/linux/). Commande : `docker run --rm -v "$PWD":/w -w /w swift:6.4 swift test --package-path Packages/Core`. Le démon Docker est éteint dans mon bac à sable (`docker ps` échoue) : à démarrer, non essayé [?]. Voie `swiftly` : `download.swift.org` ne répond pas depuis ce bac à sable (mesuré) alors que `swift.org` répond 200 ; il faudrait l'ajouter aux domaines autorisés.
- Mise en place : script d'environnement de 5 min au plus pour être mis en cache (même page) ; forfait Claude avec sessions cloud pour C [?].
- Pièges Linux : dates en UTC avec un `Calendar` grégorien explicite, pas de `DateFormatter` dans la logique, tolérances sur les flottants.
- Risque : D1 et S1 jeudi font 13 à 21 h de travail pour C (§1) ; il n'écrirait alors aucun code. D'où D1 et les textes de S1 avant jeudi.

## 5. Cas réel de jeudi 9 h (45 à 60 min, estimation) : le squelette L0 lui-même, pas un projet à part
| # | Qui | Test | Réussi si |
|---|---|---|---|
| T1 | A | app, équipe MWM, identifiant final, installée sur l'iPhone de test (avec widget et Live Activity de 2 min seulement si Q1 = b) | l'icône s'ouvre, aucune alerte de profil ; si widget : iPhone verrouillé, le compte à rebours descend puis « fin légale » (`staleDate`) sans rouvrir l'app |
| T2 | B | sur son iPhone, mode avion : 1 photo de poisson, `availability`, puis 3 espèces d'une liste fermée via `Attachment(imageURL:)` | 3 valeurs en moins de 10 s (seuil à moi, estimation), temps noté |
| T3 | A, B, C | `verif.sh` vert chez A, chez B sur copie fraîche, sous Linux chez C ; fusion par script | 3 machines, une commande verte |
| T4 | A | archive + envoi TestFlight du squelette | build « prêt à tester » sans question de conformité de chiffrement |
| T5 | A | kit MWM arrivé : ajouter le SDK et l'initialiser ; sinon `.storekit` local | build + lancement sans erreur ; « Restaurer » répond |
Si T1 dépasse 60 min : Mac A continue en équipe gratuite « Personal Team » ; elle n'a pas iCloud (d'après amis.md) et WeatherKit comme les achats réels demandent l'équipe MWM [?].

## 6. Inconnues risquées, dans l'ordre où les lever
1. Accès MWM et signature : confirmation écrite mercredi, T1 jeudi 9 h. Bloque tout le reste.
2. IA avec image : T2, puis 20 photos réelles de 10 h à 11 h par B (part de bonnes espèces dans les 3 propositions). `Attachment` est « iOS 27.0+ » (https://developer.apple.com/documentation/foundationmodels/attachment.md) ; la version texte de la page n'affiche aucune marque Bêta, la page web peut en afficher une [?]. Parade : aucune mise à jour de Xcode de mercredi à vendredi.
3. SwiftData : écrire, tuer l'app, relire, 45 min au plus dans L4 ; repli JSON + PNG.
4. Détourage Vision sur un poisson tenu à la main : 10 photos réelles, 30 min, après L3. Risque de prendre la main pour le sujet (non mesuré). Repli : photo cadrée sans détourage.
5. Live Activity (vendredi si Q1 = a) : 8 h au plus, puis retrait de la Dynamic Island ; l'écran verrouillé garde 4 h de plus (12 h en tout) ; démarrage app au premier plan ; ni réseau ni position dans l'activité (https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities.md). La démo ne dure pas 8 h ; relancer l'activité est une décision produit pour Adem plus tard.
6. `CKShare` : en dernier, hors build soumis (2 iPhones et 2 comptes iCloud, schéma Production avant TestFlight, adaptateur de scène SwiftUI non vérifié, règle 1.2 : amis.md et app-store.md). Repli déjà prévu : fichier `.pescedex`.
7. Spark Flash : dès l'arrivée du kit (T5) ; manifeste de confidentialité, chiffrement et consentement à demander à MWM.

## 7. Calendrier de jeudi 15 oct. (scénario Q1 = a, fourchette basse ; gel 14 h)
| Heure | Mac A | Mac B | C (sans Mac, cloud) |
|---|---|---|---|
| Mer. 14 | macOS 26.6, Xcode 27.0, simulateur iOS 27 lancé une fois, invitation MWM acceptée, plus aucune mise à jour | liste des iPhone (IA : 15 Pro ou plus récent), iOS 27, modèle IA téléchargé, mode développeur, 20 photos copiées | dépôt privé, `swift:6.4` testé en cloud, D1 et textes S1 (si Q2 = a) |
| 8 h 30 | ligne 0 d'app-store.md vérifiée | `availability` de l'iPhone | session cloud prête |
| 9 h à 10 h 30 | T1, T3, T4, T5 | T2 | crée `Packages/Core` (types, un test) ; A l'ajoute au projet vers 9 h 45 |
| 10 h 30 à 12 h 30 | L2 carte et fiche minimales | L3 grille, verdict, puis IA | L1 : département, règles, rareté ; une PR par morceau |
| 12 h 30 | porte 1 | porte 1 | CI Linux écrite |
| 12 h 30 à 13 h | déjeuner par roulement | déjeuner par roulement | déjeuner |
| 13 h à 14 h | tampon : retards de L2, 2e envoi TestFlight, `.storekit` local | L4 sans détourage | D1 chargé dans `Core`, score de mission |
| 14 h | gel | gel | gel |
| 14 h à 15 h 30 | L6 paywall natif (SDK si livré) | fin de L4 (exception de gel), puis bugs | S1 : textes, notes de relecture, pages web |
| 15 h 30 à 16 h | archive, TestFlight | 20 photos, captures iPhone | questionnaire d'âge, étiquettes (rôle App Manager) |
16 h tient seulement en fourchette basse, sans marge. Au milieu des fourchettes : 17 h 30 à 19 h (estimation), ce qui, d'après app-store.md, laisse environ une chance sur deux d'une relecture avant vendredi 15 h. Vendredi matin : E4, puis L8, hors build soumis, montrés depuis Xcode.

## Recommandation
1. Structure : un paquet `Core` (Foundation seulement, testable sous Linux) + app et widget en dossiers synchronisés, un dossier par lot. Option la plus forte écartée : 12 paquets, qui donnent des frontières imposées par le compilateur mais coûtent 12 retouches du fichier projet et des centaines de `public`.
2. Barrière de fusion : `verif.sh` + `fusionner.sh` en local. CI Linux sur `Core` ; pas de CI macOS jeudi.
3. C écrit `Core` depuis le cloud via l'image `swift:6.4`, après un test de la chaîne mercredi (voie Docker, démon à démarrer).
4. Jeudi 9 h : T1 à T5 avant tout lot en parallèle. Pas de projet Xcode jetable mercredi, sauf accord (Q2) : « aucun code avant jeudi » (kickoff/5-faisabilite-peche.md).
5. Coupes : E8, écran E3, détourage, et E4 si le gel de 14 h est ferme. Portes à 12 h 30, 14 h et 15 h 30.
6. À corriger : lots.md place L6 après le gel de 14 h, D1 doit vivre dans `Packages/Core/.../Resources/`, L1 passe à C, le TestFlight de 12 h passe à 10 h 30 ; archi-ios.md : « projet jetable » devient T1.
Décor : tout ne tient pas avant 14 h, même en bas de fourchette ; le choix porte sur ce qui sort du build soumis.
1. Périmètre : a) gel de 14 h tenu, E4 renvoyé à vendredi, envoi 16 h à 17 h 30 (ma recommandation, défaut) / b) E4 gardé, gel glissant à 15 h 30 si les organisateurs l'acceptent, envoi 17 h 30 à 19 h / c) E8 aussi gardé : 10 à 18 h de plus, je le déconseille.
2. Avant jeudi : a) environnement et données seulement : JSON, script Hub'Eau hors app, textes de fiche (défaut) / b) a + un projet Xcode vide de 15 min / c) rien.
3. Fichiers générés (stations, raretés) contre « jamais commitées » : a) release GitHub privée téléchargée par script (ma recommandation, défaut) / b) commit par exception / c) régénérés sur chaque machine, environ 1 h.
