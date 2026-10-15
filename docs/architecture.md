# Architecture de l'app

Version du 15 oct. (3 volets, session, liste de contrôle, toute la France). Décisions d'architecture prises après `reports/archi-ios.md` et `reports/eval-ios.md` ; le projet Xcode est celui du kit MWM. Le détail des API et leurs sources sont dans ces deux rapports.

## L'image simple
Un plan de travail commun pour tout ce qui se prépare sans écran (le paquet `Core` : règles, rareté, département, soleil), et un fourneau par cuisinier (un dossier par lot dans l'app). `Core` se teste en quelques secondes, sur Mac comme sous Linux, donc C peut l'écrire sans Mac.

## Décisions
| Sujet | Décision | Option la plus forte écartée |
|---|---|---|
| Outils | Xcode 27.0 (pas les bêtas 27.1 et 27.2), macOS Tahoe 26.6 ou plus, Mac Apple silicon. Plus aucune mise à jour de mercredi à vendredi. | Xcode 27.1 bêta |
| Cible | iOS 27.0 minimum, iPhone seulement (pas d'iPad). `Attachment`, qui joint la photo à l'IA, n'existe qu'en iOS 27 ([Apple](https://developer.apple.com/documentation/foundationmodels/attachment)). | iOS 26 avec repli : plus de monde, mais sans IA photo |
| Navigation | La barre d'onglets standard d'iOS 27 (`TabView`), 3 volets : Pescedex, Carte, Mon club ; ouverture sur Carte. Le glissement d'un volet à l'autre seulement par les bords de l'écran, plus tard, car il se bat avec la carte (`vision.md`). | une barre faite maison : plus libre, mais VoiceOver ne dit plus « onglet 1 sur 3 » |
| Structure | Un seul paquet Swift `Core` (Foundation seulement) + la cible app et la cible widget en dossiers synchronisés (Xcode ne liste plus les fichiers, d'où peu de conflits entre les 2 Mac : [notes Xcode 16](https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes)). Un dossier par lot. | 12 paquets locaux : frontières imposées, mais 12 retouches du projet et des centaines de `public` |
| Frontières | Un dossier de l'app n'importe que `Core` et lui-même. Écrit dans le `CLAUDE.md` du dépôt et vérifié par un `grep` dans `verif.sh`. | aucune vérification |
| Barrière de fusion | `scripts/verif.sh` (sort 0 ou 1) et `scripts/fusionner.sh lot/<nom>`, seul chemin vers `main`. Les branches protégées de GitHub n'existent pas sur un dépôt privé gratuit ([GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)). CI Linux sur `Core` en plus. | CI macOS jeudi : image Xcode 27 encore en préversion, minutes payantes |
| Données | Embarquées dans `Core/Resources`. Les deux fichiers fabriqués par script (stations, raretés) ne sont jamais commités : publiés en pièce jointe d'une release privée et téléchargés par `scripts/donnees.sh` avant le build. | les commiter par exception |
| Faux services | Chaque contrat de `Core` a un faux, pour que chaque lot tourne seul. Côté app, les faux sont sous `#if DEBUG` : rien de factice dans le build envoyé (règle 2.1). | |
| Stockage | SwiftData, modèles dans `App/Collection` (jamais dans `Core`). Si SwiftData bloque plus de 45 min : fichiers JSON et PNG. Pas de synchro iCloud (`cloudKitDatabase: .none`). | |
| IA d'espèce | Dans l'ordre : le modèle Create ML de R1 s'il passe son test, sinon Foundation Models sur l'iPhone seulement s'il passe le même test (`reports/reconnaissance.md` §5) (`@Generable enum` des 14 espèces, tirage `.greedy`), sinon la grille. 3 propositions, aucun pourcentage. L'IA propose, l'humain confirme, la table décide. Aucun appel à Private Cloud Compute (E5 marche en mode avion). | Foundation Models seul : rien à entraîner, mais seulement sur iPhone 15 Pro et plus avec Apple Intelligence |

## Arborescence du dépôt
```
CLAUDE.md                      faits du dépôt et règles de lots
BuildChallenge.xcodeproj       A seul (projet fourni par MWM, importé au lot L0)
TestConfig.storekit, mwm-spark-flash-sdk/   A seul (kit MWM)
App/BuildChallengeApp.swift, App/RootView.swift   A seul ; RootView porte la barre des 3 volets
App/Carte/ (volet central)   App/Prise/   App/Collection/ (volet gauche)   App/Session/
App/Abonnement/   App/Mesure/   App/Club/ (volet droit)
App/OuChercher/   App/Amis/   Widget/              mise à jour
Packages/Core/Sources/Core/    Modele/ Contrats/ Regles/ Rarete/ Geo/ Soleil/ Session/ Resources/ ; MiseAJour/ (mise à jour)
Packages/Core/Tests/CoreTests/ Contrats/ (C0) Moteur/ (L1)
scripts/                       verif.sh, fusionner.sh, donnees.sh, lot.sh (A)
outils/                        hubeau/ (D2), regles/ (D3), reconnaissance/ (R1), verifier_donnees.py (D1), veille/ (mise à jour)
store/                         textes de fiche, notes pour le relecteur, pages web (C)
```

## Ce que `Core` expose (contrats en mots, gelés au début de L1, ajouts seulement ensuite)
- `departement(de: Coordonnee)` donne le code du département ou « inconnu » (point dans un polygone sur `departements.geojson`).
- `controle(espece, tailleCm, date, lieu, prisesDuJour)` donne la liste de contrôle par défaut (question 1 de `README.md`) : une ligne par règle qui s'applique (taille, période, quota, mode de pêche, nuit, réserve possible, consommation), chacune avec son état (respectée, non respectée, à vérifier sur place), sa phrase, sa source, sa citation et sa date de lecture, puis une consigne globale : « relâche-la » si une ligne n'est pas respectée, « vérifie l'arrêté » si une ligne est à vérifier, et sinon « aucune règle saisie ne l'interdit ; l'arrêté fait foi » (texte par défaut, à valider par Adem). Jamais « tu peux la garder ». Une règle périmée (`expire_le` passé) ou non relue selon la question 1 devient « à vérifier ». Deux textes contradictoires : la valeur la plus stricte, avec les deux sources.
- `reglesDuJour(lieu, date)` donne les lignes de la fiche d'un coin (E2), même forme.
- `rarete(espece, departement)` donne le niveau (commun, peu commun, rare, légendaire), le nombre de pêches où l'espèce est relevée, le nombre total de pêches (« 9 sur 29 »), l'année du dernier relevé, et l'échelle du calcul (département, ou région quand le département a moins de 20 pêches).
- `lieuFlou(coordonnee)` donne le cours d'eau et le département (« La Marne · 94 ») depuis la station OFB la plus proche, jamais le point exact ; sans cours d'eau connu, le département seul.
- `especesProches(coordonnee)` et `coins(ou: espece, pres: coordonnee)` donnent les espèces relevées près d'un coin, ou les stations OFB où une espèce a été relevée, triées par distance (filtre de E3), avec N, l'année et « ouverte aujourd'hui » ou la date de réouverture. Les coins publics (accès au bord de l'eau) viennent avec L7.
- `finLegale(date, coordonnee)` donne l'heure de fin légale (coucher + 30 min, avec 1 min de marge) ; `phaseLune(date)` la phase de lune.
- Le type `Prise` (espèce confirmée, taille, date, lieu flou, chemin de la photo sans GPS, `gardee` déclarée par le pêcheur, `exemple`) : L3 la fabrique ; après la liste de contrôle, le pêcheur touche « je la relâche » ou « je la garde » (sa déclaration, jamais une permission de l'app ; défaut à valider par Adem), ce qui compte pour le quota.
- Le type `Sortie` (début, fin facultative, prises, poissons gardés par espèce) et `quota(sortie, departement)` : L5 remplit la sortie et tient le nombre de sessions terminées ; L4 fait la carte d'une `Prise` et la carte bredouille d'une `Sortie` sans prise.
- Le contrat `Collection` (lire les cartes enregistrées) : L4 le remplit, L8 le lit dans la mise à jour, sans importer `App/Collection/`.
- Les critères qui séparent les paires proches (gardon, brème, chevesne ; fario, arc-en-ciel) sont des données de D1 (`especes.json`, champ `critere_distinctif`), lues par L3.
- `acces(sessionsTerminees, abonne)` donne ce qui est ouvert : par défaut, la 1re session gratuite, puis les sessions sur abonnement ; la carte, les règles et le Pescedex en lecture toujours ouverts.
- `offreAffichee(date)` donne le produit annuel à montrer : 34,99 jusqu'au 31 décembre 2026, 49,99 ensuite (tarif fondateur).
- Trois contrats branchés côté app, chacun avec un faux : `IdentifieEspece` (modèle de R1, IA d'Apple ou grille), `Achats`, `Mesure`.

## Qui assemble les volets
`App/RootView.swift` (A seul) est le seul endroit qui connaît plusieurs dossiers de l'app. Il pose la barre des 3 volets ; sur le volet Carte (L2), il superpose le bandeau de session (L5) quand une session tourne, et il ouvre la prise (L3), la révélation de la carte (L4) puis, à la fin de la 1re session, le paywall (L6). Il passe les valeurs de `Core` (`Prise`, `Sortie`, nombre de sessions terminées) d'un écran à l'autre. Le bouton « Commencer une session » vit dans `App/Carte/` et appelle une action que RootView fournit. Si la pêche est fermée à l'heure du départ, la session démarre quand même avec le message de fermeture : le relecteur d'Apple, qui teste peut-être de nuit, doit pouvoir aller jusqu'à la fin de session et au paywall.

## Le cas réel de jeudi 9 h (avant tout lot en parallèle)
| # | Qui | Test | Réussi si |
|---|---|---|---|
| T1 | A | projet signé avec l'équipe MWM et l'identifiant définitif, installé sur l'iPhone de test | l'app s'ouvre, aucune alerte de profil |
| T2 | B | sur son iPhone, mode avion : une photo de poisson donne 3 espèces de la liste fermée | 3 valeurs en moins de 10 s (seuil à confirmer) |
| T3 | A, B, C | `verif.sh` vert chez A, chez B sur une copie fraîche, et sous Linux chez C | une commande verte sur 3 machines |
| T4 | A | archive et envoi TestFlight du squelette | build « prêt à tester », sans question de chiffrement |
| T5 | A | kit MWM : SDK ajouté et initialisé ; sinon fichier `.storekit` local | build et lancement sans erreur, « Restaurer » répond |

## Inconnues, dans l'ordre où on les lève
1. Accès MWM et signature (T1). Bloque tout.
2. IA avec photo sur un vrai iPhone (T2), puis 20 photos réelles : part de bonnes espèces dans les 3 propositions.
3. SwiftData : écrire, tuer l'app, relire (45 min au plus).
4. Détourage Vision sur un poisson tenu à la main (10 photos, 30 min). Repli : photo cadrée.
5. Live Activity (version suivante) : 8 h au plus dans la Dynamic Island, démarrage app ouverte ([Apple](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)).
6. Partage entre amis (version suivante), après le choix de l'outil par Adem.
7. SDK Spark Flash dès l'arrivée du kit : manifeste de confidentialité, chiffrement, consentement.

## Points ouverts techniques, sans effet sur le découpage
- La chaîne Docker `swift:6.4` dans le cloud n'a pas encore tourné : le démon était éteint dans le bac à sable de l'évaluateur. À tester mercredi.
- Taille de contexte du modèle local (4K ou 8192 selon les pages Apple) : lire `contextSize` au lancement.
- Commandes `xcodebuild` écrites sans Mac : à valider en T3.
