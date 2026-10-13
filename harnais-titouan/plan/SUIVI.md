# SUIVI des lots - Bredouille

Rédigé le 13 octobre 2026 (mardi). Méthode : « lots » du harness de l'équipe (un tableau de suivi, une fiche par lot avec périmètre de fichiers strict, réservation d'une ligne avant de commencer) et « contrat central » (types et événements décidés une fois, dans `PecheCore/Sources/PecheCore/Contracts/`, que les modules consomment au lieu de s'appeler entre eux).

Légende : **[F]** fait tiré d'un document source cité ou d'une exigence écrite ; **[I]** inférence, estimation ou choix proposé, à valider. Responsables : **A** = Adem (Mac, iPhone, Claude Code, soumission) ; **T** = Titouan (PC Windows : Swift sans compiler, Python) ; **B** = Sullyvan et Alexandre (business, Mac). Priorités : **M** indispensable au MVP, **S** souhaitable, **C** bonus. Fiches détaillées : `plan/lots/<code>.md`. Parcours : `docs/parcours.md`. Calendrier : `docs/calendrier.md`. Checklists : `docs/checklists.md`.

## 1. Règles de fonctionnement (valables pour tous les lots)

1. **Réserver avant de commencer** : passer l'état du lot à `en cours (prénom)` dans ce tableau, commit d'une seule ligne, push. États possibles : `à faire`, `en cours (X)`, `à compiler` (Swift écrit par Titouan, pas encore compilé par Adem ; convention de `docs/harnais-bredouille.md`), `à relire`, `fini` (compilé et vérifié), `coupé`. Fin de lot : formule « Vérifié : … Non vérifié, à compiler sur Mac : … » (CLAUDE.md, règle 13).
2. **Un fichier = un seul propriétaire** (CODEOWNERS). Un lot ne touche que son périmètre déclaré dans sa fiche ; `Tools/check/check_scope.py` (L39) le vérifie.
3. **Contrat gelé jeudi 10 h** : après le gel, une modification de `Contracts/` est additive et passe par une PR relue par les deux développeurs. Un module qui a besoin d'un événement manquant l'ajoute dans `AppEvent.swift` avec un commentaire.
4. **`PecheCore` n'importe que `Foundation`** (compilable sous Windows et Linux). Tout ce qui touche un capteur ou une API Apple vit dans `PecheApple`.
5. **Les vues s'écrivent contre `AppEnvironment.demo`** (MockIdentifier, photos d'exemple, département 95). Adem fournit `.live`.
6. **Commits** : `Lxx: message`. **Fix forward** : un build cassé sur `main` se corrige dans les 15 minutes par celui qui l'a cassé, ou par Adem avec Claude Code.
7. **Chemins** : tous relatifs à la racine du dépôt `bredouille-app/` : `PecheCore/Sources/PecheCore/{Contracts,Mocks,Rarity,Identification,Store,Geo,Trips,Prompts,Resources}`, `PecheCore/Tests/PecheCoreTests`, `PecheApple/Sources/PecheApple/{Identification,Camera,Motion,Intents,Store}`, `App/{Features/{Shell,Capture,Identify,Card,Collection,Bestiary,Achievements,Map,Trip,Prepare,Legal,Paywall,Profile,Onboarding},Design,Resources}`, `Tools/{data-pipeline,eval,check}`, `docs`, `plan`, `project.yml`. Un sous-dossier peut être créé librement sous un dossier listé.
8. **Gel du code vendredi 11 h**, upload final vendredi 12 h. Rien de nouveau après 11 h.

## 2. Tableau des lots

| Code | Intitulé | Resp. | Dépend de | État | Prio | Heures [I] | Jalon | Parcours |
|---|---|---|---|---|---|---|---|---|
| [L0](lots/L0.md) | Dépôt initial et squelette | A | - | à faire | M | 1,5 (A 1,5) | Avant jeu. 9 h | transverse |
| [L1](lots/L1.md) | Contrat v2 : ajouts additifs au contrat existant, compilation et mocks | T | L0 | à faire | M | 3 (T 3) | Avant jeu. 9 h | transverse |
| [L2](lots/L2.md) | Pipeline Hub'Eau vers profils de département | T | L1 | à faire | M | 6 (T 6) | Avant jeu. 9 h | 2, 6, 11 |
| [L3](lots/L3.md) | Catalogue d'espèces (~45 à 55) | T | L2 | à faire | M | 7 (T 6 + B 1) | Avant jeu. 9 h | 2, 5, 6, 11, 16 |
| [L4](lots/L4.md) | Rareté côté Swift : lecture des classes pré-calculées, exotique et protégée | T | L1, L2 | à faire | M | 3 (T 3) | Avant jeu. 9 h | 2, 6, 10, 11 |
| [L5](lots/L5.md) | Départements : résolution, polygones, fédérations | T | L1 | à faire | M | 4 (T 4) | Avant jeu. 9 h | 1, 17, 18, 20 |
| [L6](lots/L6.md) | Stations OFB en GeoJSON | T | L2 | à faire | S | 2,5 (T 2,5) | Avant jeu. 9 h | 18 |
| [L7](lots/L7.md) | Stockage de la collection et des réglages | T | L1 | à faire | M | 2,5 (T 2,5) | Avant jeu. 9 h | 2, 7, 8, 9, 10, 12, 20 |
| [L8](lots/L8.md) | Identification manuelle assistée, fusion, pipeline | T | L1, L3 | à faire | M | 4 (T 4) | Avant jeu. 9 h | 5 |
| [L9](lots/L9.md) | Prompts, schéma guidé, jeu d'évaluation | T | L1, L3 | à faire | M | 3 (T 3) | Avant jeu. 9 h | 2, 5 |
| [L10](lots/L10.md) | Jeu d'images d'identification | T | L3 | à faire | M | 7 (T 6 + B 1) | Avant jeu. 9 h | 2, 5 |
| [L11](lots/L11.md) | Entraînement Create ML (classifieur de secours) | B | L10 | à faire | C | 3,5 (A 1 + T 0,5 + B 2) | Avant jeu. 9 h | 2 |
| [L12](lots/L12.md) | Comptes, signature, build à blanc TestFlight | A | L0 | à faire | M | 2 (A 2) | Avant jeu. 9 h | transverse |
| [L13](lots/L13.md) | Coquille de l'app, ouverture sur la caméra | A | L0, L1 | à faire | M | 2 (A 2) | Jalon 1 : jeu. 12 h | 1, 2, 10, 20 |
| [L14](lots/L14.md) | Capture, import galerie, photo d'exemple, permissions en contexte | A | L13 | à faire | M | 2 (A 2) | Jalon 1 : jeu. 12 h | 1, 2, 3, 4 |
| [L15](lots/L15.md) | Moteurs d'identification Apple | A | L1, L8, L9, L14 | à faire | M | 5 (A 5) | Jalon 2 : jeu. 19 h (MVP) | 2, 3, 4, 5 |
| [L16](lots/L16.md) | Confirmation en un tap et révélation de la carte | T | L1, L8, L40 | à faire | M | 4 (A 1 + T 3) | Jalon 2 : jeu. 19 h (MVP) | 2, 3, 4, 5, 6 |
| [L17](lots/L17.md) | Carte à collectionner et effet holographique | T | L1, L4, L40 | à faire | M | 5,5 (A 2,5 + T 3) | Jalon 2 : jeu. 19 h (MVP) | 2, 6, 10, 13 |
| [L18](lots/L18.md) | Collection, détail de carte, progression | T | L7, L17, L40 | à faire | M | 3 (T 3) | Jalon 2 : jeu. 19 h (MVP) | 10, 11, 12 |
| [L19](lots/L19.md) | Carte des stations OFB | T | L6, L13 | à faire | S | 2,5 (A 0,5 + T 2) | Jalon 2 : jeu. 19 h (MVP) | 18 |
| [L20](lots/L20.md) | Sortie : minuteur, ajout de prise, bredouille | T | L7, L17 | à faire | M | 3,5 (A 0,5 + T 3) | Jalon 2 : jeu. 19 h (MVP) | 8, 9 |
| [L21](lots/L21.md) | Légal, sources, règle locale de base, textes responsables | T | L5, L40 | à faire | M | 3 (T 3) | Jalon 2 : jeu. 19 h (MVP) | 1, 17, 20 |
| [L22](lots/L22.md) | Abonnement Pro et paywall doux à la 16e carte | T | L13 | à faire | S | 2,5 (A 1 + T 1,5) | Gel : ven. 11 h | 14 |
| [L23](lots/L23.md) | Siri, raccourcis, Action Button | A | L13, L17 | à faire | C | 1 (A 1) | Gel : ven. 11 h | 15 |
| [L24](lots/L24.md) | Assets : icône, cadres, silhouettes, captures | T | L3, L10, L40 | à faire | M | 3 (T 2 + B 1) | Jalon 2 : jeu. 19 h (MVP) | transverse |
| [L25](lots/L25.md) | Intégration, QA appareil et tests utilisateurs | A | L14, L15, L16, L17, L18, L19, L20, L21, L28, L29, L30, L33, L34, L37, L38 | à faire | M | 4 (A 2,5 + B 1,5) | Gel : ven. 11 h | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20 |
| [L26](lots/L26.md) | Soumission App Store Connect | A | L25 | à faire | M | 8 (A 3 + T 2 + B 3) | Upload : ven. 12 h | transverse |
| [L27](lots/L27.md) | Pitch et vidéo de secours | B | L25 | à faire | M | 5 (A 1 + B 4) | Pitch : ven. 15-18 h | transverse |
| [L28](lots/L28.md) | Premier lancement : carte responsable et permissions en contexte **(nouveau)** | T | L13, L14, L21, L40 | à faire | M | 1,5 (A 0,5 + T 1) | Jalon 2 : jeu. 19 h (MVP) | 1 |
| [L29](lots/L29.md) | Détail et modification d'une carte **(nouveau)** | T | L7, L17, L18, L40 | à faire | M | 3 (A 0,5 + T 2,5) | Jalon 2 : jeu. 19 h (MVP) | 2, 7 |
| [L30](lots/L30.md) | Espèce incertaine : « Aucune de ces espèces », questionnaire visuel, carte À identifier **(nouveau)** | T | L8, L16, L40 | à faire | M | 3 (T 3) | Jalon 2 : jeu. 19 h (MVP) | 5 |
| [L31](lots/L31.md) | Bestiaire en détail **(nouveau)** | T | L18, L3, L40 | à faire | S | 2 (T 2) | Gel : ven. 11 h | 11 |
| [L32](lots/L32.md) | Niveaux, succès, « Ma saison » **(nouveau)** | T | L7, L17, L18, L20, L40 | à faire | S | 3 (T 3) | Gel : ven. 11 h | 12 |
| [L33](lots/L33.md) | Profil et réglages **(nouveau)** | T | L7, L13, L5, L21, L40 | à faire | M | 2,5 (A 0,5 + T 2) | Jalon 2 : jeu. 19 h (MVP) | 20 |
| [L34](lots/L34.md) | Règles locales : données et points d'entrée **(nouveau)** | T | L5, L21, L3 | à faire | M | 2 (T 2) | Jalon 2 : jeu. 19 h (MVP) | 17 |
| [L35](lots/L35.md) | Mes coins privés floutés **(nouveau)** | T | L19, L7, L40 | à faire | C | 3,5 (A 1 + T 2,5) | Gel : ven. 11 h | 18 |
| [L36](lots/L36.md) | Rappel d'ouverture de saison **(nouveau)** | T | L13, L33 | à faire | C | 2 (A 1 + T 1) | Gel : ven. 11 h | 19 |
| [L37](lots/L37.md) | Cartes spéciales « Exotique » et « Protégée » **(nouveau)** | T | L3, L4, L17, L34 | à faire | M | 1,5 (T 1,5) | Jalon 2 : jeu. 19 h (MVP) | 6 |
| [L38](lots/L38.md) | Partage d'une carte **(nouveau)** | T | L17, L14, L40 | à faire | S | 2 (A 1 + T 1) | Jalon 2 : jeu. 19 h (MVP) | 2, 13 |
| [L39](lots/L39.md) | Garde-fous automatiques : compléter Tools/check **(nouveau)** | T | L0, L1 | à faire | S | 2 (T 2) | Avant jeu. 9 h | transverse |
| [L40](lots/L40.md) | Design system : tokens, haptique, cibles tactiles **(nouveau)** | T | L0 | à faire | M | 2 (T 2) | Avant jeu. 9 h | transverse |
| [L41](lots/L41.md) | Préparer (mode débutant) **(nouveau)** | T | L3, L5, L13, L34, L2 | à faire | S | 3,5 (T 3 + B 0,5) | Gel : ven. 11 h | 16 |

Jalons : P = avant jeudi 9 h ; Jalon 1 = jeudi 12 h, build TestFlight « coquille + capture » ; Jalon 2 = jeudi 18-19 h, MVP de bout en bout sur iPhone ; Gel = vendredi 11 h ; Upload = vendredi 12 h.

## 3. Heures par personne [I]

| Ensemble | Adem (A) | Titouan (T) | Business (B) | Total |
|---|---|---|---|---|
| Lots d'origine L0-L27 | 26,5 | 63 | 13,5 | 103 |
| Nouveaux lots L28-L41 | 4,5 | 28,5 | 0,5 | 33,5 |
| **Tous les lots** | 31 | 91,5 | 14 | 136,5 |
| dont fait avant jeudi 9 h (jalon P) | 4,5 | 44,5 | 4 | 53 |
| dont sur site (jeu. 9 h - ven. 18 h) | 26,5 | 47 | 10 | 83,5 |
| sur site, priorité M | 21 | 31 | 9,5 | 61,5 |
| sur site, priorité S | 2,5 | 12,5 | 0,5 | 15,5 |
| sur site, priorité C | 3 | 3,5 | 0 | 6,5 |

Capacité réelle sur site : Adem ~20 h, Titouan ~20 h (jeudi 9-20 h = 11 h, vendredi 9-18 h = 9 h). Voir la critique de faisabilité en section 9.

## 4. Nouveaux lots (L28 à L41) et ce qu'ils changent

| Lot | Pourquoi il existe | Parcours |
|---|---|---|
| L28 | Aucun lot ne portait le premier lancement (ouverture sur la caméra, permissions en contexte, carte responsable) | 1 |
| L29 | Le détail existait (L18) mais pas la modification (taille, relâché, correction d'espèce en 3 taps) | 2, 7 |
| L30 | « Aucune de ces espèces » + questionnaire visuel + carte À identifier ; la logique est dans L8, l'interface manquait | 5 |
| L31 | Le bestiaire n'avait qu'un compteur ; il faut des fiches | 11 |
| L32 | Niveaux, 8 succès et « Ma saison » n'étaient dans aucun lot | 12 |
| L33 | Profil et réglages (département, mode démo, gants, corbeille) | 20 |
| L34 | Les règles locales n'avaient qu'une vue (L21) ; il faut les données par département et les points d'entrée | 17 |
| L35 | Spots privés floutés (extension de la carte des coins) | 18 |
| L36 | Rappel d'ouverture de saison | 19 |
| L37 | Cartes « Exotique » et « Protégée » (éthique) | 6 |
| L38 | Le partage était un `ShareLink` de bonus dans L23 ; c'est un parcours à part (2 taps, sans lieu) | 2, 13 |
| L39 | Garde-fous automatiques pour un développeur qui ne compile pas | transverse |
| L40 | Socle de design (tokens, haptique, cibles 64 pt) pour que les vues écrites sur PC et sur Mac se ressemblent | transverse |
| L41 | Préparer (mode débutant) n'avait aucun lot malgré la maquette 7 | 16 |

Dépendances ajoutées sur des lots existants (sans en retirer) : L16, L17, L18, L21, L24 dépendent aussi de L40 (fait avant jeudi) ; L25 dépend aussi des lots M nouveaux (L28, L29, L30, L33, L34, L37) et de L38 ; L20 reste inchangé. Aucune dépendance circulaire (vérifié à la main : L40, L39, L28 n'ont pas de lot aval qui leur dépende en retour).

## 5. Contradictions connues et résolution proposée

### 5.1 Durée minimale d'une sortie : 20 ou 30 minutes
- **Constat** : 02 §2.4 dit 20 min et un maximum d'une bredouille par jour ; 04 (L20) et 00 §7 disent 30 min ; 06 et 09 ne tranchent pas.
- **Proposition [I]** : **20 minutes**, paramètre `GameRules.minTripMinutes` (JSON), une carte par sortie, plafond d'une bredouille par jour civil, série Patience à 5 bredouilles distinctes. L'anti-abus repose sur le plafond quotidien et l'absence de classement public, pas sur la durée. 20 min évite de décevoir une sortie du soir ou avec un enfant (aucune punition, valeur du produit).
- **Pour la démo** : un réglage **Réglages → Mode démo** ramène le seuil à 1 minute ; il est décrit dans les notes de revue et n'est jamais présenté comme le fonctionnement normal.
- **Qui décide, quand** : Adem et Sullyvan, mercredi 21 h. Impact : L20 seulement (un nombre).

### 5.2 Grille gratuite : 15 cartes ou 1 département + 30 prises
- **Constat** : 02 §8.2, 00 §11, 06 §3.8 et 09 (E13) disent 15 cartes gratuites, bredouilles illimitées, paywall à la 16e ; 04 (L22) dit 1 département + 30 prises.
- **Proposition [I]** : **15 cartes gratuites, bredouilles hors quota, paywall doux à la 16e** (`EntitlementLimits.freeCardLimit = 15`, `bredouilleCountsTowardLimit = false` : [F] valeurs par défaut du contrat v1, qui note lui-même le doute). Raisons : quatre documents sur cinq, un test déjà écrit (T6 de 09), et « 1 département » pénalise un pêcheur qui voyage alors que le département est détecté automatiquement. Les cartes déjà obtenues restent visibles et exportables, y compris après expiration (E13). Prix de départ 24,99 €/an avec 3 jours offerts ou 3,99 €/mois [I, non validés].
- **Qui décide, quand** : Adem, vendredi 10 h avec la décision paywall (R-06). Impact : L22 (+ texte de notes de revue).

### 5.3 Seuils de rareté : 30/10/3/1 ou 30/12/4/1 (et deux autres versions)
- **Constat** : 02 §2.2 : 30/10/3/1 % ; 00 §5 : « autour de 30, 12, 4 et 1 %, à recalibrer » ; **04 §1.6 et 05 donnent une troisième échelle (50/25/10/3 %)** ; `CLAUDE.md` le rappelle. Avec 50/25/10/3, la truite à 40 % en Isère [F, 00] ne serait que « peu commune » : incohérent, échelle écartée.
- **Mesure réelle [F, `Tools/data-pipeline/reports/seuils_comparaison.json`, 5 départements : 71, 75, 78, 92, 95]** : profil A (30/10/3/1) donne 32 % commune, 44 % peu commune, 9 % rare, 14 % très rare, 1 % remarquable ; profil B (30/12/4/1) donne 32 / 41 / 7 / 18 / 1. **Les deux profils ne diffèrent que de 2 à 4 espèces sur 87** : le choix n'est pas déterminant. Pour le 95 : A = 8 / 11 / 1 / 2 / 0, B = 8 / 11 / 0 / 3 / 0. **Le pipeline a été construit avec le profil B** (`profil_actif: "B"`).
- **Proposition [I]** : **garder le profil B (déjà généré)**, une seule source de vérité (`Tools/data-pipeline/config.json`, recopiée dans chaque JSON de département) ; L4 ne duplique pas les seuils en Swift. Ne pas viser la cible 35/25/20/12/8 % écrite dans 04 : elle est irréaliste (la classe Remarquable vaut ~1 % mesuré). Critère de remplacement : si, mercredi, un jeu de seuils donne au 78 ou au 71 une meilleure répartition visible en démo, on relance `build_departments.py` (quelques minutes).
- **Alerte démo** : le 95 n'a que **9 stations et 51 opérations** (fiabilité « faible », 0 Remarquable) ; faire la démo filmée sur un département plus fourni (78 : 87 opérations) ou accepter des cartes Commune et Peu commune seulement.
- **Libellés** : le contrat affiche « Épique / Légendaire » alors que 02 et les maquettes disent « Très rare / Remarquable » ; trancher dans L1 (proposition : « Très rare / Remarquable »).
- **Qui décide, quand** : Titouan avec Adem, mercredi 14 en fin d'après-midi. Impact : L1 (libellés), L2 (relance éventuelle), L4.

### 5.4 Autres incohérences repérées dans les documents
| # | Constat | Résolution proposée [I] |
|---|---|---|
| a | 00 §6 dit « décision mardi 14 octobre au soir » ; le 14 octobre 2026 est un **mercredi** (le 13 est un mardi) | Première mesure mardi 13 au soir, **décision mercredi 14 à 21 h** (04 : G1-G6 mercredi 21 h) |
| b | Critères d'identification : 04 G1 = top-3 ≥ 70 %, p50 ≤ 5 s ; 00/consigne = top-3 ≥ 85 %, top-1 ≥ 60 %, chaque groupe de confusion ≥ 70 %, latence ≤ 4 s | Les critères de 00 font foi (voir calendrier §4). 40 photos donnent un intervalle trop large pour trancher : 40 photos = tri mardi, 120 à 200 photos = décision mercredi |
| c | Budget de friction : E1 de 09 dit ≤ 4 taps et ≤ 15 s ; 06 et 00 disent 2 taps | **2 taps** est l'objectif de conception, 4 taps est le seuil d'échec du test (E1) |
| d | Photo d'exemple : 04 la met en évidence ; 06 et 09 la cachent derrière un réglage ; la revue Apple en a besoin (R-07) | Appui long sur l'obturateur, Réglages → Mode démo, **proposée dans l'écran « Je ne vois pas de poisson »** et si la caméra est absente ; décrite dans les notes de revue |
| e | Onboarding : 04 n'en prévoit pas, 06 « aucun écran avant la caméra », 09 « ≤ 1 écran passable », 07 (paywall/onboarding) non lu | Aucun écran avant la caméra ; une bannière non bloquante (L28) ; permissions en contexte |
| f | Écran « Détails » (taille, relâché, lieu) de la maquette 4 vs enregistrement automatique (06) | Enregistrement automatique à la confirmation ; détails modifiables après coup (L29) |
| g | Noms de paliers : 04 `epique/legendaire`, 02 « Très rare / Remarquable » | Voir 5.3 (code vs affichage) |
| h | « Carte responsable » (parcours 1) n'est définie dans aucun document | [I] interprétée comme un bandeau de rappel responsable (relâcher si la règle locale l'autorise, pas de verdict légal) ; à confirmer |
| i | Nom de code : `peche-dex`, `PecheDex` dans 04/05 ; le squelette utilise `Bredouille` (schéma, `BredouilleApp`) ; le nom n'est pas vérifié (INPI, ASC) | Garder `Bredouille` partout côté app, préfixe `Peche` pour les paquets ; ne jamais utiliser « Pokédex » |

| j | **Unité de calcul** : le pipeline compte des **opérations de pêche** (une station, une date) ; 02, 04, le contrat et `CLAUDE.md` parlent de **stations** (« présent sur X % des stations scientifiques ») | Calculer sur les opérations est statistiquement plus solide (9 stations seulement dans le 95). Proposition : libellé « présent dans X % des relevés de pêche scientifiques de l'OFB » ; mettre à jour `RarityInfo.libelle` (L1), la règle A3 de `CLAUDE.md` et `LegalTexts` (L21) |
| k | **Format** des fichiers de département du pipeline (clés courtes `c, n, o, s, p, k, st`) différent de `DepartmentProfile`/`SpeciesPresence` du contrat | Décodeur dédié `DepartmentFileDecoder` (L4) plutôt que de changer le pipeline |
| l | **Durée de l'essai gratuit** : 3 jours (00, 02, 06, 09) ou 7 jours (`docs/store/checklist-soumission.md` §2) | Décision d'Adem au plus tard jeudi (les produits ASC et le texte du paywall doivent concorder) |
| m | **Direction graphique** : cinq directions A à E dans `Theme.swift`, aucune choisie | Choix mercredi 21 h (L40) ; tant que rien n'est choisi, ne coder aucune couleur en dur |
| n | **Statuts de protection** : `departments/95.json` marque chabot, anguille, bouvière « protege » ; `species.json` n'a qu'une espèce `protege` | Vérifier la cohérence (L3) avant que L37 s'appuie dessus |
| o | **Onglets** : 04 prévoyait Collection, Prendre, Carte, Réglages ; le squelette en a 4 (Prendre, Collection, Préparer, Profil) | Garder le squelette ; la carte est ouverte depuis Préparer |

## 6. Écarts avec 04 et 05 (à connaître avant de lire les anciennes fiches)

- Chemins : `Packages/PecheCore` et `App/Sources/App/...` de 05 deviennent `PecheCore/...` et `App/...` (arborescence du squelette). Noms de types : ceux du contrat v1 (`CatchCard`, `Trip`, `CollectionStore`…), pas ceux de 04 §1.3.
- L16 ne contient plus `ManualQuestionnaireView` : elle passe dans L30.
- L23 ne contient plus le partage `ShareLink` : il passe dans L38 (L23 devient Siri et Action Button).
- L14 : le bouton « Photo d'exemple » n'est plus en évidence (voir 5.4 d) ; le conseil de cadrage disparaît après 3 usages.
- L13 : l'onglet par défaut est la caméra, plus « Aujourd'hui » ; 4 onglets (squelette).
- L1 et L7 sont étendus (statut À identifier, spéciale, corbeille, brouillon, réglages, événements) : sinon les nouveaux parcours obligeraient à rouvrir le contrat après le gel. L4 ne recalcule plus les seuils (le pipeline Python les applique déjà). L22 n'invente plus de `FreeTier`/`FeatureFlags` : le contrat les fournit.
- L20 : 20 minutes (voir 5.1). L22 : 15 cartes (5.2). L4 : seuils (5.3).
- L15 : critères de G1 durcis (5.4 b). L17 : +1 h optionnelle pour le détourage Vision (`SubjectCutout`).

## 6bis. État réel du dépôt constaté le 13 octobre et ajustements nécessaires

Un squelette et plusieurs lots de préparation existent déjà (créés par d'autres agents, **jamais compilés** côté Swift). Les états du tableau restent « à faire » : seul Adem ou Titouan passe un lot à `fini` après vérification réelle. Les fiches signalent, lot par lot, ce qui existe (« Déjà dans le dépôt »).

| Zone | Constat [F, lecture du dépôt] | Conséquence |
|---|---|---|
| Contrat | `Contracts/*.swift` v1, `docs/contrats.md`, mocks, un fichier de tests ; noms : `CatchCard`, `Trip`, `CollectionStore`, `RarityProvider`, `DepartmentResolver`, `Entitlements`, `FeatureFlags` | Les noms de 04 §1.3 (`CatchRecord`, `CollectionStoring`…) sont caducs ; L1 devient « contrat v2 additif » |
| Données | 4 départements générés (75, 78, 92, 95), 71 partiel ; `species.json` 48 espèces ; profil de seuils B actif | L2 : compléter, pas recommencer ; L3 : vérifier les statuts ; L4 : lire, pas recalculer |
| Images | 12 espèces téléchargées dans `Tools/eval/images/` ; `eval_manifest.csv` non rempli | L10 : le chantier restant est la vérité terrain de `test40` et les photos « en main » |
| App | `RootView` à 4 onglets (Prendre par défaut, Collection, Préparer, Profil) ; placeholders dans chaque Feature ; `Theme.swift` à cinq directions non choisies | L13 réutilise RootView ; la carte est atteinte depuis Préparer ; **choisir la direction graphique (L40)** |
| PecheApple | Squelettes `FoundationModelsIdentifier`, `CoreMLIdentifier`, `MotionService`, `PhotoPreprocessor`, `StoreService`, intents en commentaire | L15, L17, L22, L23 partent de ces fichiers |
| Harnais | `CLAUDE.md` (règles A à D), 7 agents de revue, 9 skills, `Tools/check/check_all.py`, `docs/store/*`, `docs/copy/*` | L39 complète `check_all.py` ; L26 relit `docs/store/*` au lieu de les réécrire |

**Ajustements de CODEOWNERS à faire (Adem, L0)** : le fichier attribue au niveau du dossier `Onboarding`, `Map` et `Paywall` à Adem, alors que les fiches confient des vues à Titouan (« le dernier motif qui correspond l'emporte » : ajouter des lignes par fichier après les lignes de dossier).
- Titouan : `App/Features/Onboarding/{FirstLaunchBanner,ResponsibleNoticeSheet,PermissionPrimer,TipsCoordinator}.swift` (L28) ; `App/Features/Map/{CoinsMapView,StationDetailSheet,StationListFallbackView,MySpotsLayer,SpotEditSheet}.swift` (L19, L35) ; `App/Features/Paywall/{PaywallView,SoftPaywallTrigger}.swift` (L22).
- Adem dans un dossier de Titouan : `App/Features/Identify/IdentifyFlowCoordinator.swift` (L16), `App/Features/Card/{HolographicModifier,ShareWiring,CardEditWiring}.swift` (L17, L38, L29), `App/Features/Profile/SettingsWiring.swift` (L33), `App/Features/Onboarding/FirstLaunchWiring.swift` (L28), `App/Features/Collection/` : aucun (le câblage passe par RootView).
- Ces exceptions sont déjà nommées dans les périmètres des fiches ; sans elles, `check_scope.py` (L39) signalera des faux conflits.

## 7. Garde-fous de sécurité du plan
- Aucun fichier exécutable ni `settings.json` n'est créé par ce plan ; les scripts de `Tools/check` (L39) sont à écrire pendant la préparation.
- Rien n'est poussé sur GitHub par ce plan : tout est local dans `bredouille-app/plan` et `bredouille-app/docs`.

## 8. Ce qu'il faut couper en premier

Principe : on coupe dans l'ordre du **moins de parcours perdus par heure récupérée**, et on ne coupe jamais ce qui porte le thème de l'événement (la caméra, la carte, la bredouille) ni l'éthique (L37, L34 minimal). « Heures » = heures de A + T + B récupérées [I].

| Ordre | Lot | Gain | Effet sur les parcours | Condition / remarque |
|---|---|---|---|---|
| 1 | L36 Rappel d'ouverture | 2 h | parcours 19 disparaît (V2) | Aucun impact sur le reste |
| 2 | L35 Coins privés floutés | 3,5 h | parcours 18 réduit aux stations | La carte des stations (L19) reste |
| 3 | L23 Siri / Action Button | 1 h | parcours 15 disparaît ; le bouton volume (L14) reste | À couper avant tout lot M |
| 4 | L32 « Ma saison » et niveaux (garder 3 succès codés en dur au pire) | 3 h | parcours 12 réduit | Ne jamais afficher d'XP sur la révélation |
| 5 | L41 Préparer | 3,5 h | parcours 16 disparaît (V2) | Maquette 7 devient une capture « bientôt » |
| 6 | L31 Bestiaire en détail | 2 h | parcours 11 réduit à la grille de L18 | |
| 7 | L19 Carte des stations (et L6) | 4,5 h | parcours 18 disparaît | Remplacer par une liste par commune ou rien |
| 8 | L11 Create ML | 3,5 h | repli IA perdu | **Ne pas couper si G1 échoue** : il devient M |
| 9 | L22 Paywall | 2,5 h | parcours 14 disparaît ; soumission sans IAP | Décision vendredi 10 h, drapeau `paywall = false` |
| 10 | L38 Partage | 2 h | partage = capture d'écran système | Dernier des S : le partage est le canal d'acquisition |
| 11 | L17 (A) détourage et holo (garder le dégradé statique) | 3,5 h | effet « wow » réduit | G2 : repli `DragGesture` ou statique |
| 12 | L30 questionnaire visuel (garder « Aucune » + liste + carte À identifier) | ~2 h | parcours 5 simplifié | L8 garde la logique |
| 13 | L29 édition (garder taille, relâché, correction d'espèce) | ~1 h | parcours 7 réduit | |
| 14 | L39 Tools/check (sauf `check_forbidden_words`) | ~1,5 h | moins de filets | À faire avant jeudi ou jamais |

**Ne se coupe pas** : L0, L12, L1, L7, L13, L14, L15 (avec ses replis), L16, L17 (mise en page), L18, L20, L21, L25, L26, L27, L28 (version minimale), L33 (département et mode démo), L34 (lien fédération), L37 (au moins le badge), L40 (version minimale), et les données L2 à L5, L8 à L10.

**Version « MVP strict » du jeudi 19 h** (si le retard dépasse 3 h) : parcours 1, 2, 3, 4, 6, 8, 9, 10, 17, 20 et le partage par capture système. Les parcours 5 (version courte), 7, 11, 12, 13, 14, 16, 18, 19 passent derrière.

## 9. Critique honnête de la faisabilité (~20 h par personne)

1. **Le plan complet ne tient pas.** Total estimé : voir le tableau de la section 3. Sur site, il reste pour Titouan bien plus de lots M qu'il n'a d'heures (priorité M seule : plus de 30 h pour ~20 h disponibles) ; pour Adem, la priorité M seule consomme à peu près tout son temps (~21 h pour ~20 h), **sans compter l'intégration de ce que Titouan écrit sans compiler**. Les estimations de 04 ne l'incluent que partiellement (L25) ; 02 conseille +25 % d'intégration [I], soit ~6 h d'Adem en plus. Adem est le goulot d'étranglement unique (Mac, iPhone, signature, soumission, Claude Code).
2. **« Avant jeudi 9 h » est surchargé.** Le travail marqué P représente ~53 h (dont ~44 h pour Titouan) à faire entre ce soir et mercredi soir, soit deux jours dont une nuit. Titouan peut en faire, au mieux, 20 à 25 h sur cette période [I]. Soit une partie (L6, L10 au-delà de 12 espèces, L39) glisse sur site, soit le travail avait déjà commencé : à vérifier ce soir.
3. **Le règlement peut tout renverser.** Si les organisateurs interdisent le code écrit avant l'événement (question Q12 du formulaire, R-10), les ~45 h de lots M « avant » deviennent des heures sur site, et le plan ci-dessus devient impossible. Le plan de secours est alors « MVP strict + département 95 seul + données en dur », et on abandonne L2 (96 départements) au profit de 3 à 5 départements. **Poser la question aux organisateurs aujourd'hui.**
4. **Le Swift écrit sans compiler coûte cher.** Le squelette DoIt n'a jamais compilé [F, 04]. Chaque vue de Titouan est une dette d'intégration, d'où : CI < 12 min, `.demo`, `#Preview`, composants simples, L40, L39. Les vues à fort risque sont L16, L17 et L30.
5. **Le risque n°1 n'est pas du code.** L'identification (G1) n'est pas mesurée ; les critères 85 % / 60 % / 4 s sont ambitieux pour un modèle généraliste sur des cyprinidés [I, 04 §0]. Une mesure sur 40 photos ne permet pas de conclure (écart de ±11 points environ à 95 % [I, calcul binomial approché]). Si NO-GO, le pitch change (« tu décides, l'app te guide ») : la préparer avant, pas après.
6. **Le marché est étroit et déjà occupé** (HOOKfr, FishVerify) ; l'avantage « bredouille, carte partageable, honnêteté » est faible techniquement [F, 00 §2]. Ce n'est pas un problème pour un hackathon, mais le pitch ne doit pas promettre une part de marché.
7. **Ce qui rend l'ensemble plausible malgré tout** : un contrat gelé tôt, des replis à chaque étage (IA, GPS, capteurs, paywall), des lots indépendants dont on peut couper la moitié sans casser le reste, et la section 8 qui dit quoi couper. Un MVP strict de bout en bout jeudi 19 h est crédible ; le plan complet (tous les parcours) ne l'est pas.
8. **Ce qu'il faut mesurer dès jeudi midi** pour savoir si on est en retard : nombre de lots M à l'état `fini` à 12 h (cible : L13, L14, plus tous les « avant »), build TestFlight n° 1 reçu, CI verte. Si à 14 h L15 n'est pas en bon état, déclencher la coupe 1 à 7 sans réunion.
