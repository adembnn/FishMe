# L15 Widget aquarium : ce que le Mac doit faire (lot/widget-aquarium, non compilé)

Idée d'Adem (15 oct. 21h47) : l'aquarium sur l'écran d'accueil et l'écran verrouillé.
Ce que iOS permet : un widget est une image redessinée quelques dizaines de fois par jour au plus ; iOS fait glisser
les poissons d'une place à l'autre entre deux entrées de la timeline (environ 2 s). Pas de nage continue,
pas de fond d'écran animé (aucune API). Aucune API privée (`clockHandRotationEffect` et consorts : risque de refus).

Prérequis : la cible widget de L10 (`FishMeWidget`, voir `L10-ecran-verrouille.md`) existe.

1. Capacité **App Groups** sur les DEUX cibles (BuildChallenge et FishMeWidget), groupe `group.ai.mwm.build.challenge.team.01`.
   Le projet est signé chez MWM : si Xcode refuse de créer le groupe, le demander à MWM. Sans groupe, le widget
   reste sur « Ta 1re prise nagera ici » (il ne plante pas).
2. Glisser le dossier `WidgetAquarium/` du dépôt. Appartenance :
   - `InstantaneAquarium.swift`, `NageWidget.swift`, `NourrirAquariumIntent.swift`, `ChoixPoissonsAquarium.swift` : FishMeWidget + BuildChallenge
     (`ChoixPoissonsAquarium.swift` porte les types AppIntents du choix des poissons : il doit être sur les deux cibles) ;
   - `AquariumWidget.swift`, `VuesAquariumWidget.swift`, `PoissonsWidget.xcassets` : FishMeWidget seulement ;
   - `PontAquariumWidget.swift` : BuildChallenge seulement.
3. `Widget/FishMeWidgetBundle.swift` (lot L10, A) : ajouter `AquariumWidget()` dans `body`.
4. URL `fishme://` (clé Info `CFBundleURLTypes`, schéma `fishme`) ; dans `RootView.swift`, `.onOpenURL` :
   `fishme://aquarium` ouvre « Voir mon aquarium » (L14), `fishme://pro?source=widget` ouvre le paywall (déclencheur `widget`).
5. Branchements dans `RootView.swift` (A) : `PontAquariumWidget.publier(...)` après chaque carte ajoutée au Pescedex,
   à la fin d'une session et quand l'abonnement change ; `PontAquariumWidget.ajouterRations(_:)` à la fin d'une session
   (même règle que les rations de l'aquarium L14). Les poissons passés : TOUT le Pescedex (une entrée par carte ou par
   espèce regroupée, les plus rares d'abord, 200 au plus, sans carte d'exemple ni bredouille), avec `Poisson.nom` = nom
   commun de l'espèce (liste de choix seulement). Le pêcheur choisit ceux qui nagent : appui long sur le widget,
   « Modifier le widget », « Poissons » (5 au plus ; le widget petit en montre 3). Sans choix : les plus rares d'abord.
   Le widget est un `AppIntentConfiguration` (`ChoixAquariumIntent`, fournisseur `AppIntentTimelineProvider`), plus un
   `StaticConfiguration`. Les images des poissons sont dans le catalogue du widget : la liste de choix les prend là.
6. Compiler le schéma BuildChallenge. Tests de la logique : `sh AppTests/WidgetAquarium/lancer-tests.sh`.
7. Essai sur l'iPhone : ajouter le widget en petit, moyen, grand et très grand, puis sur l'écran verrouillé ;
   avec et sans Pro (StoreKit de test) ; toucher « nourrir » ; « Réduire les animations » ; mode teinté de l'écran d'accueil.
   Capture de chaque format dans `reports/ecrans/L15/`.

Fusion : dans la version soumise (tout d'un coup), juste après L10. Sans L14, les rations viennent de `PontAquariumWidget.ajouterRations(_:)` à la fin de chaque session.

Points à vérifier à la compilation (écrits sans Mac) : `.widgetAccentedRenderingMode(.desaturated)` sur `Image` ;
`#Preview(as:) timeline:` avec deux entrées ; `openAppWhenRun` encore valide en iOS 27 ; `nonisolated` sur l'intent
(les retirer si le compilateur râle) ; `@Parameter(title:size:)` avec `size: 5` sur un tableau (sinon enlever `size:`,
la limite de 5 est déjà faite dans le code) ; `DisplayRepresentation.Image(named:)` et son image absente du catalogue de l'app ;
`AppIntentConfiguration(kind:intent:provider:)` avec `#Preview(as:)` ; symbole `circle.grid.2x2.fill` ; `.accessoryInline` cité pour rien dans `FondEau`.

## Animation continue (16 oct., écrit sans Mac)

Les poissons battent de la queue, des bulles montent et des rayons ondulent, en continu, dans le widget (technique de Bryce Bostwick, MIT). Fichiers : `AnimationWidget.swift`, `PoissonVivant.swift`, `DecorAnime.swift` (cible widget ET app), logique pure `HorlogeAnimation.swift` (testée sous Linux : `AppTests/WidgetAquarium/lancer-tests.sh`).

1. Ajouter à la cible widget (et à l'app si on montre le poisson vivant dans l'app) les deux polices `FishMeMasquePair-Regular` et `FishMeMasqueImpair-Regular` (fichiers fabriqués par l'autre agent) : case de la cible cochée, phase « Copy Bundle Resources ».
2. Les déclarer dans `UIAppFonts` de l'`Info.plist` de la cible widget (et de l'app si besoin) avec le nom de FICHIER exact (`.ttf` ou `.otf`). Le nom passé à `Font.custom` est le nom PostScript : `FishMeMasquePair-Regular`, `FishMeMasqueImpair-Regular`. Si le texte est en police système, c'est ici que ça casse.
3. Vérifier sur un VRAI iPhone (le simulateur et `ImageRenderer` ne rafraîchissent pas les chronos comme le vrai système) : 8 images/s ; une seule image visible à la fois (pas de fantôme, ni de clignotement noir entre deux images) ; boucle de 2 s ; batterie (un widget en vue tout le temps : regarder la consommation après quelques minutes dans Réglages > Batterie).
4. Si le carré plein n'est pas aligné (masque trop haut ou trop bas), c'est la ligne de base de la police : le masque doit couvrir toute la vue, vérifier la hauteur de ligne de 1 em.
5. Repli : si ça ne tourne pas (fantômes, polices ignorées, batterie), passer `anime: false` dans `PoissonVivant` (image entière fixe) et retirer `LumiereAnimee()` / `BullesAnimees()` de `CoucheNage` dans `VuesAquariumWidget.swift`. Avec « Réduire les animations » et sur l'écran verrouillé, l'animation est déjà coupée.

## Voir les widgets en images

Pour montrer les widgets à Adem sans passer par la galerie : `AppTests/WidgetRendu/RenduWidgetsTests.swift` les rend en PNG avec `ImageRenderer` (14 images, échelle 3, dans `reports/ecrans/L15/`).

1. Mettre aussi les fichiers de vues de `WidgetAquarium/` (vues, entrées, exemples de rendu) dans la cible BuildChallenge : WidgetKit s'importe sans problème dans une app, et le test fait `@testable import BuildChallenge`. Les exemples `exempleRendu` n'existent qu'en DEBUG.
2. Lancer : `xcodebuild test -scheme BuildChallenge -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:BuildChallengeTests/RenduWidgetsTests` (cible de test `BuildChallengeTests`, déjà dans le projet ; adapter le nom du simulateur).
3. Puis `git add reports/ecrans/L15 && git push`.

Limite connue d'`ImageRenderer` : `Button(intent:)`, `widgetURL` et `containerBackground` sont sans effet hors widget, c'est voulu (d'où `fondVisible: true`). Les accessoires sont posés sur un fond gris foncé (#1C2A33) en mode sombre : c'est une simulation de l'écran verrouillé, pas un rendu exact. Les images de poissons viennent du catalogue de l'app hôte des tests.

## Widget Ma session (16 oct., écrit sans Mac)

Demande d'Adem : « un widget où on a notre session de pêche en temps réel ». Gratuit. Familles : petit, moyen, écran verrouillé (rectangle et rond).
Le chrono tourne tout seul (`Text(timerInterval:)`, rendu par le système) ; la timeline n'a que deux entrées (maintenant, fin légale), politique `.never`.

1. Fichiers (dossier `WidgetAquarium/`) :
   - `DepotSessionWidget.swift` (+ `Widget/Session/EtatSession.swift` et `InstantaneAquarium.swift`, qui porte le nom du groupe) : FishMeWidget + BuildChallenge ;
   - `SessionWidget.swift`, `VuesSessionWidget.swift` : FishMeWidget seulement ;
   - `PontSessionWidget.swift` : BuildChallenge seulement.
2. Même App Group que l'aquarium (`group.ai.mwm.build.challenge.team.01`) ; fichier partagé `session-widget.json` (absent = pas de session).
3. `Widget/FishMeWidgetBundle.swift` : ajouter `SessionWidget()` dans `body`.
4. Branchements dans `RootView.swift` / la session (A) : `PontSessionWidget.publier(etat)` aux mêmes endroits que `PilotageActivite` (démarrer, reprendre, mettreAJour) et `PontSessionWidget.publier(nil)` à `terminer`.
5. Schéma `fishme://` (déjà déclaré pour l'aquarium), à gérer dans `.onOpenURL` :
   - `fishme://session` : ouvre l'écran de la session (ou le lancement d'une session s'il n'y en a pas) ;
   - `fishme://session/prise` : ouvre l'ajout de prise (bouton « Prise » du widget moyen) ;
   - `fishme://session/pause` : met la session en pause (bouton « Pause », maquette P15 A). Il n'existe pas d'intent de pause côté app : le bouton est un `Link`. Si une `AppIntent` de pause est ajoutée plus tard, remplacer ce `Link` par `Button(intent:)` dans `VuesSessionWidget.swift` (`boutonLien`).
6. Le petit format n'a pas de bouton. Orange seulement pour « pêche fermée » et fin légale dépassée.
7. Tests de la logique : `sh AppTests/WidgetAquarium/lancer-tests-session.sh` (passent sous Docker swift:6.4).
8. À vérifier à la compilation : `AccessoryWidgetBackground` dans `accessoryCircular`; `Text(timerInterval:pauseTime:countsDown:showsHours:)`; `Link` dans un widget moyen; symboles `sunset.fill`, `pause.circle.fill`, `plus.circle.fill`; `#Preview(as:)` avec une seule entrée; `containerBackground(for:)` appelé dans `ecranAccueil` après un `let` dans un `@ViewBuilder`.
   Capture de chaque format dans `reports/ecrans/L15/`.

## Widget « Ma carte » (16 oct., demande d'Adem : « juste une carte, recto et verso, sans informations »)

Une carte du Pescedex sur l'écran d'accueil, petit et grand (la carte est verticale : pas de moyen). Aucun texte ni chiffre
sur la carte, aucune coordonnée, photos sans métadonnées. Un toucher retourne la carte ; le réglage « Choisir la carte »
(appui long, Modifier le widget) choisit laquelle, sinon la plus rare puis la plus récente. Dessin repris de `.fc` dans
`docs/design/fishme-ds.css` (ratio 69/100), première version avant les maquettes du fil design.

1. App Groups : déjà fait pour l'aquarium (même groupe). Le widget écrit `cartes-widget.json` et `cartes-photos/<id>.jpg` dans le conteneur.
2. Appartenance des fichiers de `WidgetAquarium/` :
   - `InstantaneCartes.swift`, `RetournerCarteIntent.swift` : FishMeWidget + BuildChallenge ;
   - `CarteWidget.swift`, `VuesCarteWidget.swift` : FishMeWidget seulement ;
   - `PontCartesWidget.swift` : BuildChallenge seulement.
   Les images des poissons (`<slug>` et `<slug>-silhouette`) viennent de `PoissonsWidget.xcassets`, déjà dans la cible widget.
3. `Widget/FishMeWidgetBundle.swift` : ajouter `CarteWidget()` dans `body`.
4. Branchements dans l'app (A, `RootView.swift`) :
   - après la révélation d'une carte : `PontCartesWidget.enregistrerPhoto(image, id:)` (photo du verso, réduite à 600 px, JPEG sans EXIF/GPS),
     puis `PontCartesWidget.publier(cartes:)` (plus récentes d'abord, 60 au plus, `rarete` 0 à 3 venue de la collection, `nom` pour la liste de choix seulement, `aPhoto` vrai si la photo est écrite) ;
   - à la suppression d'une carte, au recalcul de rareté et à l'ajout d'une carte déclarée (sans photo) : `publier(cartes:)` ; les photos orphelines sont rangées par le pont.
5. Essai sur l'iPhone : ajouter le widget en petit et en grand ; toucher la carte (retournement) ; choisir une carte ; carte sans photo (dos marine) ;
   aucune carte (emplacement en pointillés) ; « Réduire les animations » (fondu au lieu du retournement) ; mode teinté. Captures dans `reports/ecrans/L15/`.

Points à vérifier à la compilation : `AppIntentConfiguration` avec `AppIntentTimelineProvider` ; `@Parameter` sur un `AppEntity?` ;
`rotation3DEffect` dans une transition de widget (si le retournement ne joue pas, il reste un fondu) ;
`.widgetAccentedRenderingMode` après `.resizable()` ; `UIImage` dans une `TimelineEntry` (`@unchecked Sendable`) ; `nonisolated` sur les intents.

## Démo sans achat (DEBUG seulement)
- Dans `RootView`, au lancement : `.task { PontAquariumWidget.appliquerProForce() }` (ne fait rien sans l'argument, ni en Release).
- Lancer avec `-FishMeForcerPro YES` : le widget aquarium passe en Pro (poissons visibles, bouton nourrir) ; chaque `publier` le garde.
- Simulateur : `xcrun simctl launch booted ai.mwm.build.challenge.team.01 -FishMeForcerPro YES`

## Vraie nage (16 oct., 05h30)
- Polices : remplacer dans `UIAppFonts` (FishMeWidget ET BuildChallenge) les deux `FishMeMasque*.ttf` par les 10 fichiers
  `FishMeClignoteChiffre0.otf` … `FishMeClignoteChiffre9.otf` (WidgetAquarium/Polices/). `modele-clignotant.otf` n'est pas à déclarer.
- Nouveau catalogue `WidgetAquarium/NagePoissons.xcassets` (cycle de battement, 8 images par espèce) dans FishMeWidget et BuildChallenge.
- `DecorAnime.swift` est supprimé (bulles et lumière animées retirées, le décor 3D est fixe).
- Preuve attendue : AquariumDepuisJSONTests (4 tests) vert, puis 2 captures du widget à 0,5 s d'écart qui diffèrent.
