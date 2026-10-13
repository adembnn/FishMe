# Méthode « lots » : travail en parallèle sur Bredouille

Adaptée du template `mon-harness`. Ici elle est **obligatoire** : deux développeurs (Adem sur Mac, Titouan sur PC Windows sans compilation Swift), deux jours (15-16 octobre 2026, gel du code vendredi 11 h) et des sous-agents qui travaillent en parallèle. Règle de fond : **un fichier = un propriétaire** (règle 16 du `CLAUDE.md`).

## Propriétaires

| Propriétaire | Machine | Droit d'écrire | Ne touche jamais |
|---|---|---|---|
| **Adem** | Mac + iPhone | `PecheApple/`, `project.yml`, `ci_scripts/`, `.github/workflows/`, `App/Config/`, câblage (`AppEnvironment.swift`), vues `Features/{Shell,Capture,Map,Paywall}/`, signature, App Store Connect | `Tools/`, `PecheCore/` (sauf accord écrit dans la fiche) |
| **Titouan** | PC Windows, pas de compilation de l'app | `PecheCore/`, `Tools/` (pipeline, `check/`, `eval/`), `docs/` (hors `docs/business/`), vues `Features/{Collection,Card,Identify,Trip,Legal}/` hors câblage, `Resources/SampleFish/`, textes et prompts | `project.yml`, `PecheApple/`, `App/Config/`, tout `.xcodeproj` |
| **Business** (2 personnes) | Mac | `docs/business/` uniquement : métadonnées App Store, textes marketing, relecture des fiches espèces, pitch, vidéo de secours, photos avec consentement écrit | Tout le code |

Besoin dans le périmètre d'un autre : l'écrire dans la ligne de `plan/SUIVI.md` (colonne notes) ou dans un message. Ne pas éditer.

## Les trois objets

1. **`plan/SUIVI.md`** : une ligne par lot. Colonnes : lot, priorité (M indispensable / S souhaitable / C bonus), propriétaire, dépendances, état (`libre`, `en cours`, `à compiler`, `compilé`, `fini`, `coupé`), notes. L'état **`à compiler`** est propre à ce projet : le code de Titouan y reste jusqu'à ce qu'Adem l'ait compilé.
2. **`plan/lots/Lxx.md`** : une fiche par lot, 25 lignes maximum :
   - Objectif en une phrase ; propriétaire ; priorité ; estimation en heures.
   - **Fichiers autorisés** (liste stricte) et **fichiers interdits** (au moins les voisins tentants).
   - **Critères d'acceptation vérifiables**, chacun étiqueté **[Win]** (vérifiable sous Windows : script, test pur, lint) ou **[Mac]** (compilation, `#Preview`, appareil).
   - Agents de revue prévus (voir `docs/harnais-bredouille.md`).
3. **Réservation** : avant de commencer, passer la ligne à `en cours` avec son nom, commit `Lxx: réserve` et push de cette seule ligne. Deux personnes ne prennent jamais le même lot.

## Règles de travail

- **Un lot de Titouan qui contient du Swift** suit le skill `ecrire-swift-sans-compiler` : fichiers autonomes, `#Preview` avec données factices, marqueur ⚠ sur toute API non vérifiée. Il se termine à l'état `à compiler`, pas `fini`.
- **Le câblage appartient à Adem** : un lot mixte (vue par Titouan, câblage par Adem) est découpé en deux lignes de suivi, `Lxx-vue` et `Lxx-cablage`.
- **Contrats gelés** : les types et protocoles partagés (`PecheCore/Contracts/`) sont fixés tôt. Un ajout est permis s'il est documenté dans le même commit (jamais de changement silencieux) ; une modification casse Adem et se discute avant.
- **Fix forward** : un build cassé sur Mac se corrige dans les 15 minutes par le propriétaire du fichier fautif, ou par Adem si c'est un correctif d'une ligne (il l'indique dans le commit).
- **Commits** : `Lxx: résumé court`, un lot ou une partie de lot par commit. Jamais `git push --force`. Rien d'autre que le périmètre du lot dans le commit.
- **Fin de lot** : formule de la règle 13 (« Vérifié : X. Non vérifié, à compiler sur Mac : Y. »), état du suivi mis à jour, agents de revue du lot passés.
- **Business** n'a pas de lot Swift : ses lots sont des fichiers texte dans `docs/business/`, relus par `verificateur-wording` avant d'être considérés finis.

## Lien avec les règles

C'est la règle 16 (« une tâche ne touche que son périmètre ») appliquée à plusieurs personnes. Elle ne remplace pas la règle 13 : un lot « fini » sans vérification réelle n'existe pas ; il est au mieux `à compiler`.
