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
   - `InstantaneAquarium.swift`, `NageWidget.swift`, `NourrirAquariumIntent.swift` : FishMeWidget + BuildChallenge ;
   - `AquariumWidget.swift`, `VuesAquariumWidget.swift`, `PoissonsWidget.xcassets` : FishMeWidget seulement ;
   - `PontAquariumWidget.swift` : BuildChallenge seulement.
3. `Widget/FishMeWidgetBundle.swift` (lot L10, A) : ajouter `AquariumWidget()` dans `body`.
4. URL `fishme://` (clé Info `CFBundleURLTypes`, schéma `fishme`) ; dans `RootView.swift`, `.onOpenURL` :
   `fishme://aquarium` ouvre « Voir mon aquarium » (L14), `fishme://pro?source=widget` ouvre le paywall (déclencheur `widget`).
5. Branchements dans `RootView.swift` (A) : `PontAquariumWidget.publier(...)` après chaque carte ajoutée au Pescedex,
   à la fin d'une session et quand l'abonnement change ; `PontAquariumWidget.ajouterRations(_:)` à la fin d'une session
   (même règle que les rations de l'aquarium L14). Les poissons passés : les plus rares d'abord, sans carte d'exemple
   ni bredouille, 12 au plus (même sélection que l'aquarium).
6. Compiler le schéma BuildChallenge. Tests de la logique : `sh AppTests/WidgetAquarium/lancer-tests.sh`.
7. Essai sur l'iPhone : ajouter le widget en petit, moyen, grand et très grand, puis sur l'écran verrouillé ;
   avec et sans Pro (StoreKit de test) ; toucher « nourrir » ; « Réduire les animations » ; mode teinté de l'écran d'accueil.
   Capture de chaque format dans `reports/ecrans/L15/`.

Fusion : après l'envoi (étiquette `v1.0-soumise`), comme L10 et L14.
