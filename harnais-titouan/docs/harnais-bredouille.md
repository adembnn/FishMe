# Harnais Bredouille : qui appelle quoi, et quand

Carte à lire en 3 minutes. Principe : peu d'agents, appelés **aux jalons**, jamais à chaque modification. Le détail des critères est dans les skills (`.claude/skills/`), les agents les lisent au lieu de les recopier.

## Carte des agents

| Agent | Quand | Qui l'appelle | Lit |
|---|---|---|---|
| `verificateur-wording` | Tout texte affiché, métadonnées, pitch, fiches espèces, avant commit du lot | Auteur du lot (Titouan, business, Adem) | skill `wording-interdits-bredouille` |
| `revue-ux-2taps` | Tout écran, parcours, permission, paywall, contrôle tactile | Auteur du lot | skill `zero-friction-2-taps` |
| `auditeur-donnees` | Tout JSON de données ou script de pipeline | Titouan | skills `donnees-ofb-rarete`, `securite-livrable` |
| `revue-appstore` | Avant TestFlight, avant soumission (vendredi 9-10 h), et sur diff touchant permissions, paywall, Info.plist, mentions légales | Adem | skill `revue-appstore-checklist` |
| `critique` | Fin d'un lot non trivial (M de plus de 2 h), jamais pour un lot de moins d'1 h | Auteur du lot | `CLAUDE.md`, fiche du lot |
| `coupeur` | Jeudi 15 h, vendredi 9 h, ou dès qu'un lot M glisse | Adem ou Titouan | `plan/SUIVI.md`, fiches |
| `inspecteur-harnais` | Une fois, mercredi 14 octobre | Titouan | tout le harnais |
| `reparateur-build` | Dès qu'un build CI ou Xcode est rouge (3 essais max, puis escalade) | Titouan, Adem | journal `gh run view --log-failed`, `docs/flux-windows-mac.md` |
| `architecte-apple` | Avant de toucher `project.yml`, capacités, Info.plist, StoreKit | Adem | `docs/modalites-build-apple.md` |
| `builder-swiftui` | Lot de vue (Titouan, sans compilateur) | Titouan | fiche de lot, thème, skills Swift |
| `builder-coeur` | Lot de logique pure `PecheCore` | Titouan | contrats, tests |
| `integrateur-apple` | Branchement frameworks Apple, sur Mac et iPhone | Adem | `PecheCore/Contracts` |
| `ingenieur-release` | Build à blanc mercredi, TestFlight jeudi, envoi vendredi | Adem | `docs/preflight-appstore.md` |
| `designer-apple` | Avant tout lot de vue, pour chaque nouvel écran | Titouan | socle `docs/apple-design/00-socle.md`, parcours |
| `redacteur-fr` | Tout texte visible, puis `verificateur-wording` | Titouan, business | `docs/copy/`, skill wording |
| `evaluateur-design` | Avant de choisir la direction artistique, à chaque jalon de design (juge, ne corrige pas) | Titouan | socle |
| `testeur-coeur` | Fin de lot du cœur, avant fusion sur main | Titouan | `Tools/check/`, `PecheCore/Tests` |
| `testeur-parcours` | Jalon de parcours (maquette ou iPhone) | Titouan, Adem | `docs/parcours.md` |
| `testeur-identification` | Mercredi 14 octobre, décision à 21 h | Titouan, Adem | `Tools/eval/` |
| `gardien-appstore` | Fin de lot sensible, jeudi 16 h, vendredi 10 h et 14 h ; bloque la soumission | Adem, Titouan | `docs/preflight-appstore.md` |

Les skills `ecrire-swift-sans-compiler`, `liquid-glass-swiftui`, `anti-sur-ingenierie`, `discipline-code` ne sont pas des agents : on les relit en écrivant.

## Boucle de travail (un lot)

1. Réserver la ligne dans `plan/SUIVI.md`, lire la fiche `plan/lots/Lxx.md`.
2. Construire petit, dans le périmètre.
3. Vérifier : `python Tools/check/check_all.py` (hook `fin-de-tour` si installé), plus `swift test` sur le cœur si la toolchain existe.
4. Agents de revue selon la nature du lot (colonne « Quand »). Corriger les bloquants.
5. `critique` si le lot est non trivial. Corriger, ne pas rediscuter.
6. Formule « Vérifié : … Non vérifié, à compiler sur Mac : … », commit `Lxx: …`, état du suivi (`à compiler` pour le Swift de Titouan, `fini` quand Adem a compilé).

## Exemple 1 : lot de Titouan, L18 « Album, détail, progression » (3 h, Swift sans Mac)

- Périmètre : `Features/Collection/{AlbumView,CardDetailView,ProgressHeader}.swift`. Interdit : `AppEnvironment.swift`, `project.yml`.
- Il écrit trois vues autonomes avec `#Preview` et données factices ; toute API non connue porte `// ⚠ à vérifier`.
- Vérifie : `check_all.py` (pas d'emoji, pas de mot interdit, textes OK). Pas de compilation possible.
- Appelle : `verificateur-wording` (textes « 14 / 31 espèces du département », silhouettes), `revue-ux-2taps` (retrouver une carte en 2 taps), puis `critique`.
- Compte rendu : « Vérifié : check_all.py, 0 erreur. Non vérifié, à compiler sur Mac : les 3 vues, rendu des `#Preview`, fluidité à 100 cartes. » Ligne du suivi : `à compiler`, note pour Adem : « brancher dans RootTabView ».

## Exemple 2 : lot d'Adem, L14 « Capture et import » (2 h, sur Mac)

- Périmètre : `Features/Capture/*`, `App/Config/Info.plist` (chaînes d'usage). Interdit : tout `PecheCore/`.
- Il construit la caméra, `PhotosPicker` et le lien « Essayer avec une photo d'exemple », compile avec XcodeGen puis `xcodebuild`, teste sur iPhone et en mode avion.
- Appelle : `revue-ux-2taps` (ouverture sur la caméra, permission au tap), `revue-appstore` (chaînes d'usage, photo d'exemple visible), `critique`.
- Compte rendu : « Vérifié : compilation OK, parcours 2 taps sur iPhone, mode avion OK. Non vérifié : appareil sans Apple Intelligence. » Ligne du suivi : `fini`.

## Les deux niveaux de preuve (rappel)

Windows : scripts Python, tests purs, lint, JSON. Mac : tout le reste (compilation, rendu, caméra, Foundation Models, StoreKit). Un agent qui lit du code Swift ne remplace jamais une compilation : il le dit dans « Non vérifié ».

## Garde-fous et hooks

Spécification dans `.claude/HOOKS-A-INSTALLER.md` (à valider par l'utilisateur avant installation). Sans hooks, les règles 13 et 17 reposent sur la discipline : lancer `check_all.py` à la main avant chaque commit.
