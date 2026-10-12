# Architecture de l'app

Version du 12 oct., 17h. Décisions d'architecture prises après `reports/archi-ios.md` et `reports/eval-ios.md`. Le détail des API et leurs sources sont dans ces deux rapports.

## L'image simple
Un plan de travail commun pour tout ce qui se prépare sans écran (le paquet `Core` : règles, rareté, département, soleil), et un fourneau par cuisinier (un dossier par lot dans l'app). `Core` se teste en quelques secondes, sur Mac comme sous Linux, donc C peut l'écrire sans Mac.

## Décisions
| Sujet | Décision | Option la plus forte écartée |
|---|---|---|
| Outils | Xcode 27.0 (pas les bêtas 27.1 et 27.2), macOS Tahoe 26.6 ou plus, Mac Apple silicon. Plus aucune mise à jour de mercredi à vendredi. | Xcode 27.1 bêta |
| Cible | iOS 27.0 minimum, iPhone seulement (pas d'iPad). `Attachment`, qui joint la photo à l'IA, n'existe qu'en iOS 27 ([Apple](https://developer.apple.com/documentation/foundationmodels/attachment)). | iOS 26 avec repli : plus de monde, mais sans IA photo |
| Structure | Un seul paquet Swift `Core` (Foundation seulement) + la cible app et la cible widget en dossiers synchronisés (Xcode ne liste plus les fichiers, d'où peu de conflits entre les 2 Mac : [notes Xcode 16](https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes)). Un dossier par lot. | 12 paquets locaux : frontières imposées, mais 12 retouches du projet et des centaines de `public` |
| Frontières | Un dossier de l'app n'importe que `Core` et lui-même. Écrit dans le `CLAUDE.md` du dépôt et vérifié par un `grep` dans `verif.sh`. | aucune vérification |
| Barrière de fusion | `scripts/verif.sh` (sort 0 ou 1) et `scripts/fusionner.sh lot/<nom>`, seul chemin vers `main`. Les branches protégées de GitHub n'existent pas sur un dépôt privé gratuit ([GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)). CI Linux sur `Core` en plus. | CI macOS jeudi : image Xcode 27 encore en préversion, minutes payantes |
| Données | Embarquées dans `Core/Resources`. Les deux fichiers fabriqués par script (stations, raretés) ne sont jamais commités : publiés en pièce jointe d'une release privée et téléchargés par `scripts/donnees.sh` avant le build. | les commiter par exception |
| Faux services | Chaque contrat de `Core` a un faux, pour que chaque lot tourne seul. Côté app, les faux sont sous `#if DEBUG` : rien de factice dans le build envoyé (règle 2.1). | |
| Stockage | SwiftData, modèles dans `App/Collection` (jamais dans `Core`). Si SwiftData bloque plus de 45 min : fichiers JSON et PNG. Pas de synchro iCloud (`cloudKitDatabase: .none`). | |
| IA d'espèce | Foundation Models sur l'iPhone, `@Generable enum` des 14 espèces, tirage `.greedy`, 3 propositions, aucun pourcentage. L'IA propose, l'humain confirme, la table décide. Aucun appel à Private Cloud Compute (E5 marche en mode avion). | |

## Arborescence du dépôt
```
CLAUDE.md                      faits du dépôt et règles de lots
Projet.xcodeproj               A seul
App/App.swift, App/RootView.swift   A seul
App/Carte/   App/Prise/   App/Collection/   App/Abonnement/   App/Mesure/
App/Session/ App/Mission/ App/Amis/          version suivante
Widget/                        extension Live Activity (version suivante)
Packages/Core/Sources/Core/    Modele/ Contrats/ Regles/ Rarete/ Geo/ Soleil/ Mission/ Resources/
Packages/Core/Tests/CoreTests/ Contrats/ (C0) Moteur/ (L1) Mission/ (C7)
scripts/                       verif.sh, fusionner.sh, donnees.sh (A)
outils/                        script Hub'Eau, verifier_donnees.py (C, hors app)
store/                         textes de fiche, notes pour le relecteur, pages web (C)
```

## Ce que `Core` expose (contrats en mots, gelés jeudi 10 h, ajouts seulement ensuite)
- `departement(de: Coordonnee)` donne le code du département ou « inconnu » (point dans un polygone sur `departements.geojson`).
- `verdict(espece, tailleCm, date, departement)` donne `garde`, `relache` ou `verifie`, avec la phrase et la source. Hors des départements saisis, jamais `garde` (voir `donnees.md`).
- `rarete(espece, departement)` donne le palier, le nombre de pêches et l'année du dernier relevé.
- `especesProches(coordonnee)` donne les espèces relevées près d'un coin, avec N et l'année.
- `finLegale(date, coordonnee)` donne l'heure de fin légale (coucher + 30 min, avec 1 min de marge).
- `phaseLune(date)` donne la phase de lune de la carte bredouille (E9).
- Le type `Sortie` (début, fin facultative, prises, météo facultative) : L4 en fait la carte bredouille jeudi ; vendredi, L5 le remplit et A le passe à L4 dans `RootView.swift`, sans que deux dossiers de l'app s'importent.
- Trois contrats branchés côté app, chacun avec un faux : `IdentifieEspece` (IA), `Meteo`, `Achats`.

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
