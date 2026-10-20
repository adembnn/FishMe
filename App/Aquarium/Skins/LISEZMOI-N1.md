# N1 : skins d'aquarium

Un skin change trois choses de l'aquarium, jamais les poissons ni leur nage : le fond, une lumière, quelques objets posés.
Le choix du pêcheur est publié au widget (`InstantaneAquarium.skin`) : **si le décor de l'aquarium change, le fond du widget change aussi.**

Rien de ce dossier n'a été compilé ni lancé (pas de Mac). Tout ce qui est marqué « à vérifier » est à regarder sur l'iPhone.

## Les huit skins

| Id | Nom | Comment | Fond |
|---|---|---|---|
| `riviere` | Rivière | décor de départ, toujours disponible | le fond actuel `fond-<format>` (aucune retouche) |
| `etang` | Étang | gagné : 5 espèces différentes | dessiné en code (direction C) |
| `grotte` | Grotte | gagné : un poisson légendaire | dessiné en code (direction C) |
| `sous-bois` | Sous-bois | gagné : 10 sessions de pêche | dessiné en code (direction C de la rivière) |
| `halloween` | Halloween | Pro, du 15 octobre au 4 novembre | dessiné en code (direction C) |
| `noel` | Noël | Pro, du 1er décembre au 6 janvier | dessiné en code (proposition B « Sapin immergé » : glace givrée, flocons, graviers givrés, sapin à peine éclairé) |
| `ouverture-truite` | Ouverture | Pro, du 1er mars au 30 avril | dessiné en code (direction C, avec un sol) |
| `ete` | Été | Pro, du 21 juin au 31 août | dessiné en code (proposition C « Fête sur l'eau » : trois bouées corail / jaune / turquoise de plus en plus floues, ballon de plage, rubans de lumière colorés, bokeh, sable clair avec graviers et galets colorés, reflets dorés qui glissent) |

Les sept décors du catalogue (hors le décor de départ) ont un fond dessiné : la galerie les montre tous (`skinAffichable`).
Un futur skin sans illustration ni dessin serait masqué, sans vignette vide.

## D'où vient le fond d'un skin

Une seule règle, la même dans l'app (`sourceFond` de Core, via `FondSkin.source`) et dans le widget (`FondWidget.source`, testée sous Linux) :

1. l'illustration `fond-<id>-<petit|moyen|grand>` si elle est dans les images ;
2. sinon le **décor dessiné en code**, posé sur le fond d'origine ;
3. sinon le fond d'origine `fond-<format>`.

### Le dessin en code

Les décors sont dessinés dans des fichiers **partagés** par l'app et l'extension du widget, dans `WidgetAquarium/` :

| Fichier | Rôle |
|---|---|
| `DecorsDessinesBase.swift` | cadre 390 x 844, générateur reproductible, sol, galets, roches, cristaux, herbes, brins |
| `DecorsDessinesAmbiance.swift` | rais de lumière, reflets, poussières / feuilles / pollen / lueurs, bulles, brume |
| `DecorsDessinesScenes.swift` | les décors : filtre sur le fond, calques de lumière, dessin fixe, dessin qui bouge |
| `DecorsDessinesNoel.swift` | le décor de Noël (glace, lit givré, sapins, boules, guirlande) |
| `DecorsDessinesEte.swift` | le décor d'Été (sol en trois plans, bouées et ballon flous, rubans de lumière, bokeh, reflets du sol) |
| `DecorsDessinesCache.swift` | `CacheDecor` : les images pré-rendues (une fois par décor, couche, taille et échelle) |
| `DecorsDessinesVues.swift` | `CoucheDecor`, `CoucheDecorAvant`, `filtreDecor`, `FondDecorFige`, `FondDecorWidget` |
| `BudgetDecor.swift` | le budget de performance (plafonds + charge déclarée de chaque décor), Foundation seulement |
| `FondWidget.swift` | `decorsDessines`, `aUnDessin`, `source` (déjà partagé, sans SwiftUI) |

Ils ne dépendent ni de `App/`, ni de `Core`, ni de l'état de l'app : seulement l'identifiant du décor (un texte) et la taille.
Aucun texte, aucun emoji dans les fonds.

- **App** : `FondSkin` / `CoucheSkin` / `CoucheSkinAvant` / `FondSkinVue` posent ces vues sur le fond d'origine (aquarium, aperçu, galerie).
  Le décor a sa propre lumière : l'ambiance blanche d'origine (`CoucheFondEau`, poussières et bulles de `CoucheAvantEau`) s'efface
  sous un décor dessiné ; les ondes du toucher restent. 20 images par seconde au plus (10 en économie d'énergie) ; « Réduire les animations » : image fixe.
- **Widget** : le widget est une image fixe. `FondDecorWidget` rend le fond d'origine filtré + le décor **une seule fois** en image
  (`ImageRenderer`, mise en cache), sans `TimelineView`, sans animation. Mêmes couleurs, même lumière, mêmes objets au fond ;
  la végétation d'avant-plan et les bulles (qui n'existent qu'en mouvement) ne sont pas dessinées dans le widget.
  En rendu teinté (écran verrouillé, accentué), le widget garde son dégradé neutre.

### Ajouter ou remplacer un décor

- **Remplacer un dessin par une vraie illustration** : ajouter les images `fond-<id>-petit`, `fond-<id>-moyen`, `fond-<id>-grand`
  (app : jeu d'images de l'app ; widget : `WidgetAquarium/FondsWidget.xcassets`). L'illustration est prioritaire : le dessin en code
  n'est plus utilisé pour ce décor, ni dans l'app ni dans le widget, et on peut laisser son code en place ou le retirer de
  `DecorDessin.reglage` et de `FondWidget.decorsDessines`. Les petits objets (`Skin.objets`) restent des images.
- **Dessiner un nouveau décor** : un cas dans `DecorDessin.reglage` (filtre, calques, ambiance) et dans les quatre temps de
  `DecorsDessinesScenes.swift`, l'identifiant dans `FondWidget.decorsDessines`, **sa charge dans `BudgetDecor.charge`**, puis le skin
  dans `CatalogueSkins` (Core). Les tests `DecorsDessinesTests` et `BudgetDecorTests` vérifient que la liste, le catalogue, les
  réglages et le budget vont ensemble : un décor sans charge déclarée, ou au-dessus du budget, fait échouer les tests.

## Performance : l'aquarium doit rester fluide, même sur un iPhone ancien

C'est l'exigence n°1. Sept règles, valables pour TOUS les décors dessinés :

1. **Le statique est rendu une fois en image.** Sol, galets, roches, dégradés, bouées floues, ballon, herbes fixes, rais fixes :
   `CacheDecor` les rend par `ImageRenderer` (une `Canvas` fixe), les garde en mémoire (plafond 96 Mo, les plus anciennes sortent
   d'abord) sous la clé « décor | couche | taille | échelle ». La graine du dessin est fixe : même clé, même image. Jamais redessiné à chaque image.
2. **Aucun flou sur une couche animée.** Le flou (`drawLayer` + `.blur`) n'existe que dans le dessin fixe, donc appliqué une seule fois, dans l'image mise en cache.
3. **Peu de choses bougent, et légèrement** : rubans de lumière (au plus 6, dégradés simples, chemins calculés une fois et seulement
   déplacés), bokeh (au plus 12 disques pleins), bulles (au plus 15), anneaux (au plus 6), particules (au plus 24), reflets du sol
   (images pré-rendues glissées par `offset`, jamais recalculées).
4. **20 images par seconde au plus** : une `TimelineView(.animation(minimumInterval: 1/20))` par couche (deux par décor : derrière et
   devant les poissons), **en pause** quand l'aquarium n'est pas à l'écran (`onDisappear`) ou que l'app n'est pas active (`scenePhase`).
5. **« Réduire les animations »** : une seule image fixe, aucune `TimelineView` (couches `figeeArriere` / `figeeAvant`).
   **Mode économie d'énergie** (`ProcessInfo.isLowPowerModeEnabled`, suivi par notification) : 10 images par seconde, moitié moins de
   particules, de bokeh et d'anneaux, une seule famille de reflets de surface, plus de bulles.
6. **Pas d'allocation dans `body`** : les chemins coûteux sont des `static let` (rubans de lumière, guirlande de Noël) ou sont dans
   l'image ; un seul `GeometryReader` par couche, jamais imbriqué ; les vues sont `Equatable`.
7. **Un budget chiffré** (`BudgetDecor`, vérifié par `BudgetDecorTests` sous Linux ET par `DecorsDessinesTests` sur Mac).

### Le budget (`BudgetDecor.swift`)

| Quoi | Plafond |
|---|---|
| images par seconde | 20 (10 en économie d'énergie) |
| vues animées (`TimelineView`) par décor | 2 |
| images fixes pré-rendues par décor | 3 (arrière, avant, reflets) ; images qui glissent : 2 |
| rubans de lumière / bokeh / bulles / anneaux | 6 / 12 / 15 / 6 |
| particules (derrière + devant) / rais / lignes de reflets / brume | 24 / 5 / 9 / 10 |
| plaques de lumière / halos / lames d'herbe animées | 7 / 16 / 64 |
| opérations de dessin par image (deux couches) | 360, soit 7 200 par seconde (4 000 en économie d'énergie) |

Une « opération » est un remplissage, un trait ou une image ; `BudgetDecor.Charge.operations` pèse chaque élément (une bulle compte 3,
une lame avec nervure 3, un brin fleuri 4, une ligne de reflets 4…). Charge déclarée, par image, normal / économie d'énergie :
Sous-bois 120 / 72, Étang 164 / 116, Grotte 82 / 34, Halloween 118 / 58, Noël 118 / 70, Ouverture 266 / 218, **Été 64 / 28**.

### Ce qui a été corrigé dans les décors existants (apparence inchangée, sauf mention)

- **Tous** : le dessin fixe (sol, roches, berges, nénuphars, lune, citrouilles, toiles, flous de la Grotte et de Noël…) était une `Canvas`
  vectorielle redessinée à chaque invalidation ; c'est maintenant une image mise en cache. Aucune `TimelineView` en « Réduire les animations ».
  Les `TimelineView` se mettent en pause hors écran et en arrière-plan, et passent à 10 images par seconde en économie d'énergie.
  Audit : aucun flou animé n'existait (les seuls `.blur` sont dans le dessin fixe de la Grotte et de Noël).
- **Noël** : les galets flous du premier plan (`avantNoel`) étaient redessinés à chaque image avec les poussières ; ils sont dans l'image
  fixe de l'avant-plan. La guirlande (15 ampoules, tableaux et générateur) était recalculée à chaque image ; elle est calculée une fois (`static let`).
- **Ouverture** : les 26 herbes basses du sol (balancement de 4 points au plus) étaient redessinées à chaque image ; elles sont maintenant
  dans l'image fixe, à l'instant figé (elles ne se balancent plus ; les hautes herbes fleuries bougent toujours). Les cinq pétales
  d'une fleur sont UN seul tracé (un remplissage, un trait) au lieu de dix : environ 190 opérations de moins par image, pour le même dessin
  (seul changement visible possible : un fin trait de contour à l'intérieur des pétales qui se chevauchent).
  Sans ces deux changements, Ouverture dépassait le budget (70 lames, 355 opérations par image).
- **Tous** : particules 35 -> 24 au total (16 derrière, 8 devant) : un peu moins dense, même allure ; les reflets de surface ne dépassent
  jamais 9 lignes ; en économie d'énergie, une seule famille de reflets.

### Mesurer sur un Mac (Instruments) : à faire, rien n'a été mesuré

Sur un iPhone réel, de préférence le plus ancien disponible (un décor à la fois, 8 poissons à l'écran, l'écran Aquarium ouvert) :

1. **Time Profiler** : au repos (aucun toucher), l'écran Aquarium doit rester **sous 10 % de CPU**. Regarder `CoucheDecor`, `Canvas`,
   `DecorDessin.mobileArriere` / `mobileAvant` : aucun appel de `fixeArriere` ni de `ImageRenderer` ne doit revenir après l'ouverture.
2. **Core Animation FPS** (ou instrument « Animation Hitches ») : viser **60 images par seconde côté interface**, aucun hitch.
   Le décor lui-même se redessine à 20 images par seconde, c'est normal ; la nage et l'interface restent à 60.
3. **SwiftUI** (View Body, View Properties) : `CoucheDecor` et `CoucheDecorAvant` ne doivent pas réévaluer leur `body` à chaque image de la
   nage (elles sont `Equatable`) ; la `TimelineView` interne réévalue seulement son contenu, 20 fois par seconde.
4. Vérifier la **pause** : quitter l'onglet Aquarium (ou verrouiller l'iPhone) -> le CPU du décor tombe à zéro.
5. Activer le **mode économie d'énergie** (Réglages) : 10 images par seconde, moins de particules ; **Réduire les animations** : image fixe, 0 % de CPU.
6. **Allocations** : le premier rendu des images pré-rendues (Été : environ 1 à 2 images plein écran @3x, 12 Mo chacune au plus) ne doit
   pas se répéter ; la mémoire ne doit pas croître en changeant de décor plusieurs fois (plafond du cache : 96 Mo).
7. Au premier affichage d'un décor, noter le temps du rendu de l'image fixe (`CacheDecor.image`, au fil principal, dans un `.task`) : si
   l'ouverture saccade sur un iPhone ancien, le rendre au lancement de l'app ou dans la galerie.

Si un décor dépasse ces seuils : alléger d'abord (moins de particules, de lames), ne jamais relever un plafond sans mesure.

## Cibles Xcode

Le projet utilise des dossiers synchronisés : `WidgetAquarium/` est déjà dans l'app **et** dans l'extension `FishMeWidget`
(sauf les exceptions listées dans le .xcodeproj). Les nouveaux fichiers n'ont donc normalement rien à recevoir ; **à vérifier dans
Xcode, panneau « Target Membership »**, que ces neuf fichiers sont cochés pour `BuildChallenge` ET `FishMeWidget` :

```
WidgetAquarium/FondWidget.swift
WidgetAquarium/DecorsDessinesBase.swift
WidgetAquarium/DecorsDessinesAmbiance.swift
WidgetAquarium/DecorsDessinesScenes.swift
WidgetAquarium/DecorsDessinesNoel.swift
WidgetAquarium/DecorsDessinesEte.swift
WidgetAquarium/DecorsDessinesCache.swift
WidgetAquarium/DecorsDessinesVues.swift
WidgetAquarium/BudgetDecor.swift
```

À corriger dans le .xcodeproj (non touché ici) :

- `AppTests/WidgetAquarium/BudgetDecorTests.swift` n'a PAS besoin d'exception : il importe `WidgetAquariumLogique` s'il existe (Linux),
  sinon `BuildChallenge` (cible de tests de l'app).
- `AppTests/WidgetAquarium/FondWidgetTests.swift` importe `WidgetAquariumLogique` (le paquet jetable de `lancer-tests.sh`) : à ajouter aux
  exceptions d'appartenance de la cible `BuildChallengeTests`, comme `HorlogeAnimationTests.swift` et `NageWidgetTests.swift`.
- `App/Aquarium/Skins/LISEZMOI-N1.md` (ce fichier) : à ajouter aux exceptions de la cible `BuildChallenge`, comme les autres `LISEZMOI.md`.

## Tests

- Core (Linux, Docker) : catalogue (huit skins, Sous-bois), galerie, règle d'application, libellés VoiceOver, frontière des mots interdits.
- Widget (Linux, `AppTests/WidgetAquarium/lancer-tests.sh`) : `FondWidget.source` choisit le dessin pour chacun des sept décors,
  l'illustration reste prioritaire, un identifiant douteux donne le décor de départ ; `BudgetDecorTests` : cadence 20 / 10 images par
  seconde, plafonds, charge déclarée de chaque décor dans le budget (normal et économie d'énergie), Été nettement plus léger que le plus lourd.
- App (Mac) : `AppTests/Aquarium/DecorsDessinesTests.swift` (l'app et le widget font le même choix pour chaque skin, la galerie masque
  Été compris, cadre et graine), la charge déclarée comparée aux réglages réels, la clé et le rendu unique du cache d'images, et
  `SkinsGalerieTests.swift`.

## À vérifier sur le Mac

- Que tout compile (les neuf fichiers de dessin ont été écrits sans compilateur).
- Chaque décor dans l'aquarium plein écran, en clair et en sombre, avec 1 poisson puis 8 : les poissons restent lisibles, rien d'illisible
  sur la Grotte et Halloween (les plus sombres) ; le sapin de Noël ne doit pas cacher les poissons.
- Les vignettes de la galerie (160 x 120) et l'aperçu ; Dynamic Type AX5 : le décor ne dépend pas du texte.
- Le widget petit, moyen et grand : le sol reste en bas et le plafond en haut, rien ne se chevauche ; le changement de décor dans
  l'app change bien le fond du widget au rechargement.
- Fluidité (20 images par seconde pour le décor) sur un iPhone ancien ; « Réduire les animations » : image fixe, rais et poussières figés.
- Mémoire du widget (l'image rendue fait au plus la taille du widget x l'échelle de l'écran, plafonnée à 3).
