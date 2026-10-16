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

## Couche de base et vérification sans écran d'accueil (16 oct., 05h45)
- Sous les 80 copies animées, une couche fixe dessine toujours les poissons à leur place de départ. Chaque copie porte
  l'eau derrière ses poissons : la copie visible recouvre la couche fixe (jamais deux fois le même poisson). Si l'hôte
  ne dessine pas les masques, le widget montre au moins les poissons, immobiles. En mode teinté, poissons fixes.
- Tests : `renduAnimeMontreLePoisson` est remplacé par `renduFixeMontreLePoisson` et `coucheDeBaseVisibleSousLAnimation`
  (ImageRenderer ne dessine pas les chronos, la couche fixe doit rester). Logique image par image sous Linux :
  `huitImagesDifferentesParSeconde`, `poseAvanceDUneCopieALaSuivante` (37 tests verts, `AppTests/WidgetAquarium/lancer-tests.sh`).
- Aperçus Xcode : `#Preview(as: .systemMedium)` dans `AquariumWidget.swift` (timeline datée de maintenant : le canevas
  fait tourner les chronos) et `#Preview("Aquarium animé (vue du widget)")` dans `ApercuAnimationAquarium.swift`.
- Sans l'écran d'accueil du simulateur : dans `RootView`, ajouter `.apercuWidgetSiDemande()` (DEBUG, ne fait rien sans
  l'argument), puis :
  ```
  xcrun simctl launch booted ai.mwm.build.challenge.team.01 -FishMeApercuWidget YES
  xcrun simctl io booted screenshot reports/ecrans/L15/nage-a.png; sleep 0.5; xcrun simctl io booted screenshot reports/ecrans/L15/nage-b.png
  xcrun simctl io booted recordVideo --codec=h264 reports/ecrans/L15/nage.mp4   # Ctrl-C après 12 s
  ```
  L'écran montre les 3 tailles de l'aquarium avec les vrais masques chronos, et en bas la copie attendue par le calcul.
  Les deux captures doivent différer ; si les poissons restent immobiles avec « polices ok », ce sont les masques.

## Nage calée sur l'aquarium 3D (16 oct., 06h)
- Trajet : `NageWidget.boucle` porte `Nageur.pas` de nage.js (buts au hasard dans la bande de l'espèce, virage limité,
  repos `calme`, réglages ESPECES). La boucle de 10 s est un morceau du trajet où le poisson revient à son point de départ.
  Chaque poisson se tient près de son coin (placements sur 2 colonnes en moyen et grand) ; le fond est dessiné d'abord.
- Queue : `fabriquer_cycle_nage.py` refait les 8 images avec l'ondulation de NAGE.md (amplitude par espèce) ;
  la fréquence suit la vitesse (f = 0.9 + 2.2 v/L, au plus 3,5 par seconde).
- Rien à changer dans les cibles : mêmes fichiers, même catalogue NagePoissons.

## Écran verrouillé de la session (16 oct., 06h, maquette P41 A choisie)
- `SessionWidget` ajoute `.accessoryInline` : « Fin légale 19:29 » au-dessus de l'heure.
- Rectangle : « Session » et la durée écoulée en grand. Rond : jauge du temps restant jusqu'à la fin légale
  (`ProgressView(timerInterval:countsDown:)`), le reste au centre. Blanc translucide, une seule teinte.
- 3 aperçus `#Preview` (en ligne, rectangle, rond) dans `SessionWidget.swift`. Capture attendue de l'écran verrouillé
  dans `reports/ecrans/L15/`.

## 16 images par seconde (16 oct., 06h10)
- Adem trouve 8 images/s saccadé : `HorlogeAnimation.imagesParSeconde = 16` (160 copies sur 10 s). Rien d'autre à changer.
- À surveiller sur l'iPhone : mémoire de l'extension (limite d'environ 30 Mo) et fluidité. Si le widget ne s'affiche plus ou
  se fige, essayer 12 (une seule constante), et le dire au fil Widget avec la mesure.

## Pleine eau (Adem, 16 oct. 07h)
- Plus de décor : `FondsWidget.xcassets` contient un océan provisoire (dégradé, rayons, particules), en attendant le fond
  en perspective du fil « Aquarium 3D des prises », qui refait aussi les poissons (plus cartoon).
- Nage : `NageWidget.traversees` remplace `boucle` dans la vue. Chaque poisson traverse en perspective (point de fuite
  au centre, plus petit et plus transparent au loin), sort par un bord et rentre ailleurs, parfois du fond de l'océan.
  Un widget ne dessine jamais hors de son cadre : le poisson sort par le bord et disparaît.
- 07h20 : fonds « Lagon » et 23 poissons cartoon du fil aquarium 3D intégrés (lot/aquarium 7a7e7fc).
  `WidgetAquarium/PoissonsOcean/` (sources, hors catalogue) nourrit `fabriquer_cycle_nage.py`. Les 74 autres espèces
  gardent la planche d'origine. Rien à changer dans les cibles.
- 07h30 : 60 espèces cartoon de plus (lot/aquarium 7ec09a7), 83 en tout. Écrevisses, crabes et grenouilles n'ondulent pas.
  07h25 : les 14 dernières (lot/aquarium 02e801a) : les 97 espèces sont cartoon.

## Poissons en volume (Adem, 16 oct. 07h51 : « on voit que c'est du carton en 2D »)

Le widget sait afficher des vues en volume dès qu'elles sont dans `NagePoissons.xcassets`, sans changer le code :

- `<slug>-nage-0` à `-7` : profil, tête à DROITE (déjà là ; à remplacer par le rendu 3D du fil Aquarium) ;
- `<slug>-vue-1-0` à `-7` : trois-quarts, tourné de 45° vers le fond (il s'éloigne en allant à droite) ;
- `<slug>-vue-2-0` à `-7` : trois-quarts, tourné de 45° vers nous (il approche en allant à droite).

Cycle de queue en 16 images (`-0` à `-15`, caméra à 20°, environ 600×200) ; le widget lit encore les anciens
cycles de 8. Si la mémoire ne suit pas, `NageWidget.imagesParBattementMax = 8` ne garde que les images paires.
Quand les rendus arrivent, ils remplacent les poissons cartoon (`PoissonsOcean/`). Même cadrage serré (6 px de marge), PNG transparents, 600 px de large au plus.
Les poses passent en vue 1 ou 2 au-delà de 22,5° du profil (`PoseNage.vue`) ; une vue trois-quarts n'est jamais
aplatie, seulement retournée vers la gauche. Une espèce sans vues garde le profil aplati.

### Virages sans téléportation (Adem, 16 oct. 08h35)

Le lacet de chaque pose (`PoseNage.lacet`, en degrés, + vers le fond, − vers nous) varie en continu, et le widget
fond les deux rendus les plus proches (`NageWidget.melange`) : aucun saut d'une vue à l'autre. Rendus attendus, en
plus du profil `-nage-k` : `<slug>-lacet-15-k`, `-30-`, `-45-`, `-60-` (vers le fond) et `-lacet-m15-k`, `-m30-`,
`-m45-`, `-m60-` (vers nous), tête à droite, 16 images par battement. Plus il y a d'angles, moins le fondu se voit ;
avec 15° d'écart, il ne se voit plus. Les anciennes `-vue-1-`/`-vue-2-` comptent pour 45° et −45°.

### Poissons en volume intégrés

`python3 WidgetAquarium/integrer_poissons_3d.py <poissons-3d>` range chaque espèce rendue (lot/aquarium,
reports/aquarium-3d/widget-ocean/poissons-3d/<slug>/) dans NagePoissons.xcassets à la place de son cycle cartoon :
320 px de large, 256 couleurs avec transparence (environ 1,9 Mo pour 208 images). `fabriquer_cycle_nage.py` refuse
désormais d'écraser un catalogue qui contient des poissons en volume. Brochet intégré le 16 oct. (394f7079), fonds
océan v2 (46d876a4).

### Poissons pêchés et astuce « ajouter le widget » (Adem, 16 oct. 09h45)

- Le widget montre déjà les poissons du Pescedex : `RootView.publierAquarium()` écrit `aquarium-widget.json` dans
  l'App Group `group.ai.mwm.build.challenge.team.01` (appelé au lancement et après chaque prise). Si le widget reste
  vide après une prise, c'est que l'App Group n'est pas sur l'identifiant MWM (portail Apple, puis profils).
- Avant la 1re prise : un gardon d'accueil nage, voilé, derrière « Ta 1re prise nagera ici ».
- `AstuceAjouterWidget.swift` (app seulement : à mettre dans les exceptions de la cible FishMeWidget, comme
  PontAquariumWidget.swift) : brancher `.astuceAjouterWidget(prises: <nombre de vraies prises>)` sur la vue racine
  de RootView. Feuille unique, trois gestes, après la 1re prise.
- Ajouter aussi `integrer_poissons_3d.py` aux exceptions des deux cibles.
