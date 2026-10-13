# Calendrier : mardi 13 au vendredi 16 octobre 2026

Rédigé le 13 octobre 2026 (mardi). Base : `peche/04-plan-build-lots.md` §3 et §4, mis à jour avec la caméra en ouverture, le tap unique de confirmation et les 42 lots de `plan/SUIVI.md`. **[F]** = horaire ou règle écrit dans les documents ; **[I]** = proposition à valider. Les heures de mardi et mercredi sont des **créneaux proposés** : on ignore la disponibilité réelle de chacun ces deux jours [I].

Équipe : **Adem** (A : Mac, iPhone, Claude Code, soumission), **Titouan** (T : PC Windows, Swift sans compiler, Python), **Sullyvan** (S) et **Alexandre** (X) : profils business avec un Mac chacun. Répartition proposée [I] : Sullyvan = produit, pêcheurs, tests d'usage, pitch, entraînement Create ML ; Alexandre = App Store (métadonnées, captures, ASO, confidentialité), relecture des textes et des fiches espèces.

Jalons : **J-0** build à blanc TestFlight (mercredi 18 h) · **G** go/no-go (mercredi 21 h) · **Jalon 1** TestFlight « coquille + capture » (jeudi 12 h) · **Jalon 2** MVP de bout en bout sur iPhone (jeudi 18-19 h) · **Gel du code** vendredi 11 h · **Upload** vendredi 12 h · soumission à la revue 12-13 h · **marge** jusqu'à 14 h · pitch 15-18 h.

## 1. Mardi 13 octobre (soir)

| Heure [I] | Adem | Titouan | Sullyvan | Alexandre |
|---|---|---|---|---|
| 18 h-19 h | **Faire compiler le squelette** (`xcodegen generate`, `xcodebuild` simulateur) : il n'a jamais été compilé ; corriger les erreurs (L0) | `swift test` sous Windows sur le Core existant ; relire le contrat v1 ; lister les ajouts de L1 | Rassembler les photos de pêcheurs (5 contacts, consentement écrit) | Poser la question aux organisateurs (code préparé avant, définition de « soumis ») ; ouvrir les comptes manquants |
| 19 h-21 h | Mini-app de test d'identification (1 h avec Claude Code) puis **première mesure sur 40 photos** (étape A, voir §4) | Terminer `test40` (vérité terrain dans `Tools/eval/eval_manifest.csv`) ; L1 (contrat v2) | Préparer la liste des 40 photos avec Titouan, relire les espèces | Vérifier compte Developer, accord Paid Apps, nom « Bredouille » (INPI/ASC) |
| 21 h-22 h | Résultat A communiqué à l'équipe (indicatif : 40 photos = ±11 points) | L2 : relancer les départements pilotes manquants (71, 69, 33, 31, 13, 29, 74) | | |

## 2. Mercredi 14 octobre (avant)

| Heure [I] | Adem | Titouan | Sullyvan | Alexandre |
|---|---|---|---|---|
| 9 h-10 h | Squelette vert en CI (GitHub Actions) ; décider dépôt public ou privé (minutes macOS x10 en privé [F, 04]) | L1 contrat v2 (ajouts additifs, journal `docs/contrats.md`) | Contacter 5 pêcheurs : 10 photos chacun, consentement écrit | Compte de secours (Sullyvan ou Alexandre) : inscription Developer si Adem est bloqué |
| 10 h-12 h | **L12 : build à blanc** (signature, archive, upload TestFlight) ; Xcode Cloud ou archive manuelle | L2 (suite), L3 (statuts, incohérence protegé), L5 (polygones, fédérations) | Collecter les photos ; premières interviews courtes de pêcheurs | Fiches d'espèces : relecture ; textes `docs/store/*` |
| 12 h-14 h | T2 holo sur appareil (G2) ; T5 CI (durée jobs, version de Xcode) | L4 (décodeur des départements + règles), L7 (stockage, brouillon, corbeille) | Entraînement Create ML de secours sur les 12 espèces (2 h, L11) | ASO : mots-clés sans marque ; politique de confidentialité en ligne |
| 14 h-18 h | **Étape B de la mesure d'identification : 120 à 200 photos** (dont ≥ 20 photos de pêcheurs) ; build à blanc visible dans TestFlight avant 18 h (**J-0**) | L8 (manuel assisté, fusion), L9 (prompt, schéma), L40 (direction graphique, tokens), L39 (contrôles) | Tests T1 du protocole sur 2 personnes (non pêcheurs) avec le questionnaire de repli | Captures de référence, brouillon description |
| 18 h-21 h | Compiler les premiers fichiers de Titouan (L1, L4) ; ajuster | Seuils de rareté : comparer A et B, trancher avec Adem (SUIVI §5.3) ; L5/L7 tests | Pitch v0 (script 3 min) | Notes de revue v0 (français/anglais) |
| **21 h** | **Go/no-go G1 à G8** (30 min d'appel, §3-§4) ; décisions : IA primaire, seuils, durée de sortie, grille Pro, durée de l'essai, direction graphique | idem | idem | idem |
| 21 h 30-22 h | Agent `inspecteur-harnais` une fois (`docs/harnais-bredouille.md`) ; coucher avant minuit | idem | | |

## 3. Points go/no-go chiffrés (décision mercredi 14, 21 h)

| # | Critère | GO | Si NO : plan B |
|---|---|---|---|
| **G1** | Identification (Foundation Models image, appareil iOS 27 + Apple Intelligence), jeu de 120 à 200 photos dont la moitié en conditions de pêcheur | **top-3 ≥ 85 % ET top-1 ≥ 60 % ET chaque groupe de confusion ≥ 70 % ET latence p50 ≤ 4 s** (p95 ≤ 8 s [I]) ET 0 espèce hors liste ET refus ≤ 5 % | Voir §4 (trois branches) |
| G2 | Holographique sur iPhone réel | ≥ 55 i/s moyens, pas de surchauffe en 5 min | `DragGesture` ou carte statique (L17) |
| G3 | Squelette (jamais compilé) | `xcodegen generate` + build simulateur verts en ≤ 60 min chronométrées ; `swift test` vert | Adem fait générer par Claude Code les fichiers qui cassent ; Titouan limite ses vues à des composants simples |
| G4 | CI | push → vert en ≤ 12 min ; Xcode Cloud → TestFlight fonctionne | Archive manuelle par Adem ; Titouan corrige sur les retours de la CI Actions |
| G5 | Comptes et accords | build à blanc « Prête à tester » et accord Paid Apps signé le 14 à 18 h | `FeatureFlags.paywallEnabled = false`, soumission sans achat intégré ; compte de secours d'un coéquipier |
| G6 | Données | 11 départements pilotes en < 30 min, taille < 6 Mo, statuts cohérents | 4 départements déjà générés (75, 78, 92, 95) + liste nationale de repli ; démo sur le 78 |
| G7 | Cible OS | un iPhone iOS 27 avec Apple Intelligence pour mesurer ; déploiement iOS 26 | Aucun iPhone iOS 27 : vision non testable → Core ML + manuel assisté |
| G8 | Décisions de produit | durée de sortie (20 min), grille (15 cartes), seuils (profil B), essai (3 ou 7 jours), direction graphique A-E : tous tranchés | Prendre la valeur par défaut proposée dans `plan/SUIVI.md` §5 et ne plus rouvrir |

## 4. Mesure d'identification : protocole et décision

**Étapes.** A (mardi soir) : 40 photos, 10 espèces x 4 (brochet, perche, sandre, carpe commune, gardon, truite fario, black-bass, silure, chevaine, brème), tri rapide. B (mercredi 14 h-18 h) : 120 à 200 photos, dont ≥ 20 photos de pêcheurs « tenu en main » et ≥ 10 « sur herbe » (collectées par les business), mêmes mesures. Conditions : appel à froid, appels à chaud après `prewarm`, mode avion, iPhone chaud après 20 appels. Variante B : classifieur Core ML (L11). Variante C : questionnaire (L8) par deux non-pêcheurs. `Tools/eval/score.py` produit le verdict.

**Pourquoi deux étapes [I, calcul binomial approché]** : à 85 % de réussite réelle, l'intervalle à 95 % vaut environ ±11 points pour 40 photos, ±6 points pour 120, ±5 points pour 200. Quarante photos servent à trier (très bon ou très mauvais) ; la décision se prend sur B. Le critère de 200 photos de 00 est tenu seulement si les photos de pêcheurs arrivent à temps ; sinon décider sur 120.

**Trois branches** :
| Résultat | Décision | Conséquences |
|---|---|---|
| GO (critères G1 tous remplis) | Foundation Models en moteur principal, repli Core ML puis manuel | Pitch : « l'app propose, tu confirmes » ; L15 plein (5 h) |
| GO conditionnel (70 % ≤ top-3 < 85 %) | IA en suggestion ; « Aucune de ces espèces » mis en avant ; fusion avec la fréquence locale | L11 Create ML passe de C à S ; l'entraînement Core ML est lancé jeudi 9 h ; formulation du pitch sans chiffre |
| NO-GO (top-3 < 70 % ou latence > 8 s ou refus > 10 %) | **Plan B** : manuel assisté en premier (liste du département + questionnaire L30), IA en suggestion discrète ou retirée | L15 réduit à 2 h (garde-fou Vision + éventuelle suggestion) ; L30 et L8 ne se coupent plus ; pitch : « tu décides, l'app te guide » ; aucune promesse de reconnaissance dans l'App Store |

## 5. Jeudi 15 octobre (J1), 9 h-20 h

| Heure | Adem | Titouan | Sullyvan | Alexandre |
|---|---|---|---|---|
| 9-10 | Kick-off ; **contrat v2 gelé à 10 h** ; vérifier CI verte ; clone sur site | Idem ; `swift test` sur le poste ; lancer L16 (vues contre `.demo`) | Cadrage pitch ; liste des écrans pour captures | Notes de revue et description : version 1 |
| 10-11 | **L13** coquille (RootView, AppEnvironment, ouverture sur la caméra) | L16 ConfirmationView, RevealView (tap unique = enregistre) | Interviews express (3 pêcheurs) | Classification d'âge (brouillon) |
| 11-12 | **L14** capture, galerie, photo d'exemple, permissions en contexte | L16 fin ; L17 CardView par palier | Consignes de test T1-T8 | Confidentialité : étiquettes cohérentes avec le code |
| **12** | **Jalon 1 : build TestFlight « coquille + capture »** (upload dès 11 h 30, traitement 15-60 min) | L17 fin ; PR | Installe la build ; premiers retours | |
| 13-14 | **L15** Foundation Models (schéma dynamique, image) ou branche plan B | L18 Collection ; L40 retouches | Teste TestFlight | Mots-clés, captures de référence |
| **15** | Agent `coupeur` : revue des retards (coupes 1 à 7 de SUIVI §8 sans réunion si L15 n'est pas en bon état) | L20 logique (sortie, bredouille) | | |
| 15-16 | L15 repli Core ML, factory, mesures de latence ; câblage L16 | L20 vues, L28 bannière, L37 styles de carte | Premiers tests T1 sur 2 testeurs | |
| 16-17 | L17 holo (Core Motion) ; câblage L20 | L21 légal ; L29 édition ; L33 profil/réglages | Retours testeurs | Premières captures 6,9" |
| 17-18 | Intégration bout en bout ; L22 config StoreKit si retenu | L30 questionnaire, L34 règles locales | Liste de bugs | |
| 18-19 | **Jalon 2 : MVP de bout en bout** (photo → 3 espèces → tap → carte → collection, bredouille) sur iPhone ; build TestFlight n° 2 | Correctifs CI et nommage | Tests T1 à T3 sur la build n° 2 | |
| 19-20 | Triage ; décisions de coupe pour le lendemain | Textes de soumission, données manquantes | **Vidéo de secours** : enregistrement d'écran (90 s) avec la build du moment | Script du pitch |
| Soir | **Coucher avant 1 h** ; build n° 3 nocturne via CI | idem | idem | idem |

## 6. Vendredi 16 octobre (J2), 9 h-18 h

| Heure | Adem | Titouan | Sullyvan | Alexandre |
|---|---|---|---|---|
| 9-10 | Bugs bloquants de la liste J1 ; agent `coupeur` (SUIVI §8) ; L22 test appareil | Bugs UI ; L19/L38 retouches | Tests d'usage T4-T8 (extérieur si possible) | Captures finales 6,9" |
| **10** | **Décision paywall (go/no-go)** et durée d'essai ; polish Liquid Glass (2-3 éléments) | Polish cartes, états vides, accessibilité, VoiceOver | Retours T-tests | Description finale |
| **11** | **GEL DU CODE** ; archive | Relit notes de revue, politique, textes | Notes de revue (FR/EN) | Métadonnées finales |
| **12** | **Upload App Store Connect** (build traitée 15-60 min) | Relecture croisée des notes de revue | Pitch | Formulaires ASC avec Adem |
| 12-13 | Formulaires : confidentialité, âge, chiffrement, URL ; **soumission à la revue** | Check final 2.1 / 4.3 / 5.1 | Vidéo de secours (montage) | Captures dans ASC |
| 13-14 | Test de la build traitée via TestFlight ; si bug majeur : build n° 2 (**dernier rattrapage à 14 h**) | Aide pitch : chiffres de données (« X départements, 48 espèces ») | Répétition pitch n° 1 | |
| 14-15 | Démo de répétition, iPhone en mode avion ; 2e appareil prêt | idem | Répétition n° 2 | Réponses aux éventuelles questions de la revue |
| 15-16 | Marge (revue Apple) | Marge | Répétition n° 3 (3 min chronométrées) | |
| 16-18 | Pitch / démo | | | |

## 7. Règles de calendrier
1. **Rien de nouveau après le gel (vendredi 11 h).** La build soumise est celle testée sur TestFlight.
2. **Si le MVP de bout en bout n'est pas atteint jeudi 19 h**, couper le lendemain matin selon `plan/SUIVI.md` §8 (L36, L35, L23, L32, L41, L31, L19) puis L22, sans réunion.
3. **Jeudi 15 h et vendredi 9 h** : revue des retards avec l'agent `coupeur`.
4. **La vidéo de secours** est tournée jeudi 19-20 h puis refaite vendredi 12-13 h.
5. **Aucune nuit blanche** : coucher avant 1 h jeudi soir.
6. **Définition de « soumis »** à demander aux organisateurs : build uploadée ou envoyée à la revue ? Le plan vise les deux pour 12-13 h.
