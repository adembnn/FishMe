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
| `ete` | Été | Pro, du 21 juin au 31 août | **rien de dessiné** (en attente de nouvelles propositions) |

Été reste au catalogue sans fond dessiné (nouvelles propositions en cours). Comme il n'a ni illustration ni dessin, la galerie le masque (`skinAffichable`) :
aucune vignette vide. Dès qu'un dessin ou une illustration existe, il apparaît sans autre changement.

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
| `DecorsDessinesVues.swift` | `CoucheDecor`, `CoucheDecorAvant`, `filtreDecor`, `FondDecorFige`, `FondDecorWidget` |
| `FondWidget.swift` | `decorsDessines`, `aUnDessin`, `source` (déjà partagé, sans SwiftUI) |

Ils ne dépendent ni de `App/`, ni de `Core`, ni de l'état de l'app : seulement l'identifiant du décor (un texte) et la taille.
Aucun texte, aucun emoji dans les fonds.

- **App** : `FondSkin` / `CoucheSkin` / `CoucheSkinAvant` / `FondSkinVue` posent ces vues sur le fond d'origine (aquarium, aperçu, galerie).
  Le décor a sa propre lumière : l'ambiance blanche d'origine (`CoucheFondEau`, poussières et bulles de `CoucheAvantEau`) s'efface
  sous un décor dessiné ; les ondes du toucher restent. 20 images par seconde au plus ; « Réduire les animations » : image fixe.
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
  `DecorsDessinesScenes.swift`, l'identifiant dans `FondWidget.decorsDessines`, puis le skin dans `CatalogueSkins` (Core).
  Les tests `DecorsDessinesTests` vérifient que la liste, le catalogue et les réglages vont ensemble.

## Cibles Xcode

Le projet utilise des dossiers synchronisés : `WidgetAquarium/` est déjà dans l'app **et** dans l'extension `FishMeWidget`
(sauf les exceptions listées dans le .xcodeproj). Les nouveaux fichiers n'ont donc normalement rien à recevoir ; **à vérifier dans
Xcode, panneau « Target Membership »**, que ces six fichiers sont cochés pour `BuildChallenge` ET `FishMeWidget` :

```
WidgetAquarium/FondWidget.swift
WidgetAquarium/DecorsDessinesBase.swift
WidgetAquarium/DecorsDessinesAmbiance.swift
WidgetAquarium/DecorsDessinesScenes.swift
WidgetAquarium/DecorsDessinesNoel.swift
WidgetAquarium/DecorsDessinesVues.swift
```

À corriger dans le .xcodeproj (non touché ici) :

- `AppTests/WidgetAquarium/FondWidgetTests.swift` importe `WidgetAquariumLogique` (le paquet jetable de `lancer-tests.sh`) : à ajouter aux
  exceptions d'appartenance de la cible `BuildChallengeTests`, comme `HorlogeAnimationTests.swift` et `NageWidgetTests.swift`.
- `App/Aquarium/Skins/LISEZMOI-N1.md` (ce fichier) : à ajouter aux exceptions de la cible `BuildChallenge`, comme les autres `LISEZMOI.md`.

## Tests

- Core (Linux, Docker) : catalogue (huit skins, Sous-bois), galerie, règle d'application, libellés VoiceOver, frontière des mots interdits.
- Widget (Linux, `AppTests/WidgetAquarium/lancer-tests.sh`) : `FondWidget.source` choisit le dessin pour chacun des six décors,
  l'illustration reste prioritaire, Été retombe sur le fond d'origine, un identifiant douteux donne le décor de départ.
- App (Mac) : `AppTests/Aquarium/DecorsDessinesTests.swift` (l'app et le widget font le même choix pour chaque skin, la galerie masque
  Été, cadre et graine) et `SkinsGalerieTests.swift`.

## À vérifier sur le Mac

- Que tout compile (les six fichiers de dessin ont été écrits sans compilateur).
- Chaque décor dans l'aquarium plein écran, en clair et en sombre, avec 1 poisson puis 8 : les poissons restent lisibles, rien d'illisible
  sur la Grotte et Halloween (les plus sombres) ; le sapin de Noël ne doit pas cacher les poissons.
- Les vignettes de la galerie (160 x 120) et l'aperçu ; Dynamic Type AX5 : le décor ne dépend pas du texte.
- Le widget petit, moyen et grand : le sol reste en bas et le plafond en haut, rien ne se chevauche ; le changement de décor dans
  l'app change bien le fond du widget au rechargement.
- Fluidité (20 images par seconde pour le décor) sur un iPhone ancien ; « Réduire les animations » : image fixe, rais et poussières figés.
- Mémoire du widget (l'image rendue fait au plus la taille du widget x l'échelle de l'écran, plafonnée à 3).
