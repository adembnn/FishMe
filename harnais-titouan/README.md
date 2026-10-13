# Bredouille

App iPhone (SwiftUI, iOS 26 minimum, Liquid Glass) de pêche en eau douce en France : on photographie sa prise, l'app propose 3 espèces du département, on confirme, une carte est créée. Une sortie bredouille rapporte aussi une carte. Pas de compte, tout reste sur l'appareil, fonctionne hors ligne.

Statut (13 octobre 2026) : **rien n'a été compilé**. Le code Swift est écrit sous Windows, sans compilateur. Attendre des corrections au premier build sur Mac. Les règles non négociables sont dans [CLAUDE.md](CLAUDE.md) (lire avant de coder).

## Architecture

```
project.yml        XcodeGen : SEULE source du projet Xcode (Bredouille.xcodeproj est ignoré par Git)
PecheCore/         Swift pur (Foundation seulement), compilable sous Windows/Linux/Mac. Titouan.
PecheApple/        Adaptateurs Apple : Foundation Models, Core ML, Vision, Core Motion, StoreKit. Adem.
App/               Cible SwiftUI : BredouilleApp, Features/*, Design/ (thèmes en jetons), Resources/, Config/
Tools/             data-pipeline (Hub'Eau, Python), check (vérifications), eval
ci_scripts/        Xcode Cloud (ci_post_clone.sh)
.github/           workflows (core, ios, python) et CODEOWNERS
```

Dépendances : `App` -> `PecheApple` -> `PecheCore`. Aucune dépendance externe.
Direction graphique : pas encore choisie. Cinq pistes (A à E) dans `App/Design/Theme.swift` (`ThemeKind`), tout passe par des jetons.

## Qui vérifie quoi

| Vérifiable sous Windows (Titouan) | Vérifiable seulement sur Mac (Adem) |
|---|---|
| `python Tools/check/check_all.py` : formulations interdites, JSON valides, PecheCore sans framework Apple | `xcodegen generate` et compilation de l'app |
| `swift test` dans `PecheCore` (si la toolchain Swift Windows est installée) | Rendu des `#Preview`, Liquid Glass réel |
| Scripts Python de `Tools/data-pipeline` | Caméra, Core Motion (effet holo), Foundation Models (appareil obligatoire) |
| Lecture et relecture du code Swift | StoreKit, mode avion, accessibilité, TestFlight |

Les workflows GitHub complètent : `core.yml` (tests Core sur Linux et Windows), `python.yml`, `ios.yml` (compilation simulateur, uniquement sur `main`). Aucun n'a encore tourné.
Formule de fin de lot : « Vérifié : X (commande, résultat). Non vérifié, à compiler sur Mac : Y. »

## Mise en route sur Mac (Adem)

1. Xcode 26 ou plus récent. `brew install xcodegen`.
2. Dans `project.yml`, remplacer `fr.REMPLACER` (identifiant de bundle) et `DEVELOPMENT_TEAM: REMPLACER`. Reporter le même identifiant dans `App/Config/Pecheur.storekit` et `PecheApple/.../StoreService.swift`.
3. `xcodegen generate && open Bredouille.xcodeproj`.
4. Lancer sur simulateur ou iPhone (schéma Bredouille : le fichier `Pecheur.storekit` est déjà branché).
5. Tester sur un vrai iPhone avec Apple Intelligence pour Foundation Models : le simulateur ne suffit pas.
6. Variantes `Debug27` / `Release27` : définissent `IOS27_SDK` (image Foundation Models, SDK iOS 27, ⚠). La CI utilise `Debug` sans cette condition.

## Mise en route sur Windows (Titouan)

L'app ne se compile pas sous Windows. Ce qui se fait :

1. Python 3.12 : `python Tools/check/check_all.py` (ajouter `--skip-swift` pour ignorer `swift test`). Code de sortie 0 = tout est bon, 1 = échec. Si `swift` est absent du PATH, l'étape est affichée « NON EXÉCUTÉ » (pas un échec).
2. Swift (optionnel) : `winget install --id Swift.Toolchain -e --source winget`, Visual Studio 2022 avec le SDK Windows 11, mode développeur activé. Puis `cd PecheCore && swift test`. ⚠ non essayé ici.
3. Pipeline de données : voir `Tools/data-pipeline/`.
4. Les vues SwiftUI de Titouan ne sont validées que par la CI macOS (`ios.yml`) ou par Adem.

Une ligne qui cite volontairement un mot interdit (par exemple un commentaire qui l'interdit) se marque avec `wording-ok` sur la même ligne.

## Règles de collaboration

- `main` reste vert ; branches courtes ; commits `Lxx: résumé` ; « fix forward » : un build cassé se corrige dans les 15 minutes.
- Un fichier = un propriétaire (`.github/CODEOWNERS`). Hors périmètre : ouvrir une issue, ne pas éditer.
- Chaque vue de Titouan est autonome, avec `#Preview` et données factices.

## CI et coûts

- `ios.yml` ne tourne que sur `main` (et à la demande) pour économiser les minutes macOS. En dépôt privé elles comptent x10 ; en dépôt public elles sont gratuites. Décision à prendre : dépôt public ou privé.
- Xcode Cloud : `ci_scripts/ci_post_clone.sh` installe XcodeGen et génère le projet. À configurer une fois depuis Xcode. Le fichier doit être exécutable : `git update-index --chmod=+x ci_scripts/ci_post_clone.sh`.

## Règles App Store à respecter

2.1 pas de compte + photo d'exemple pour le relecteur ; 4.3 différenciation ; 5.1.1 politique de confidentialité, localisation facultative avec choix manuel du département ; 5.2.1 aucun nom ni visuel de marque tierce ; jamais de verdict légal sur les règles de pêche (lien vers la fédération du département seulement).

## Points ouverts

Seuils de rareté, grille gratuit/Pro, plafond de friction, JSON ou SwiftData, moment de la demande de localisation : voir la fin de [CLAUDE.md](CLAUDE.md). Abonnement dans `Pecheur.storekit` : groupe « Pêcheur+ », annuel 24,99 EUR (essai 7 jours), mensuel 3,99 EUR (⚠ durée d'essai à confirmer, le descriptif parle de 3 jours).
