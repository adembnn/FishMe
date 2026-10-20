# Carte juste et légère (lot L17)

Code écrit sans Mac et sans compilateur Swift : **jamais compilé, jamais exécuté ; tests écrits, non lancés**. Adem ou Sullyvan compile `App/Carte/` sur Mac avant toute fusion, puis `/banc L17`.

## Ce que le lot fait
Ouverture sur le pêcheur, recentrage sans déplacer le spot, re-choix du département, grappes (60 éléments au plus), halo pour `recalee == false`, fiche d'un coin en trois hauteurs avec pastille de fréquentation, « Y aller » (Plans, Waze, Google Maps) avec préférence, « Mon spot » (changer de spot, Règles du spot, météo), vignettes de ses propres prises, libellés sur chaque icône.

## À brancher par A (hors du dossier)
- Réglages : poser `ReglageNavigationView()` (`Vues/ChoixNavigationView.swift`) dans l'écran des réglages ; même clé `PreferenceItineraire.cle`.
- `Info.plist` : `LSApplicationQueriesSchemes` avec `waze` et `comgooglemaps` (sinon `canOpenURL` répond toujours non et Waze n'est jamais proposé).
- Prises du pêcheur : fournir un `PrisesDuPecheurCarte` (par défaut `.aucune`, donc aucune vignette) lu depuis le stockage des prises.
- L19 : `BlocReglesView` doit rester dans `App/Style/BlocRegles/` (utilisé par `ReglesDuSpotView`).

## Points d'accroche N6 « repères privés » (câblés sur lot/racine-carte, voir docs/reports/branchements-l25.md)
N6 fournit (`App/Reperes/LISEZMOI.md`) : `CalqueReperes` (un `MapContent`), `InterrupteurCalqueReperes` (clé `reperes.calque`), `NouveauRepereView(position:)`, `FicheRepereView(repere:)`, `ListeReperesView()`, `RepereProche.plusProche`, `ReglesReperes.peutAjouter`. Où les poser dans la carte :
1. **Calque** : dans `VueCarte.contenuCarte` (`Vues/VueCarte.swift`), après `ForEach(modele.elements)` : `CalqueReperes(reperes:afficherNoms:ouvrir:)` si `InterrupteurCalqueReperes.cle` est allumé. Il compte hors du budget de 60 éléments de `Regroupeur` : prévoir de soustraire le nombre de repères visibles de `Regroupeur.maximum` au moment du câblage.
2. **Interrupteur** : une 5e rangée dans `ColonneBoutonsCarte` (`Vues/CommandesCarte.swift`) avec libellé. Attention : N6 utilise `mappin.and.ellipse`, déjà pris par « Ma zone » ; changer l'un des deux symboles. Hauteur de la colonne à re-mesurer (AX5, 44 pt).
3. **Appui long** pour poser un repère : dans `carteMapKit`, un geste à côté de `toucherPourPoser`, avec `MapProxy.convert`. Il ne doit jamais déplacer le spot ni la caméra (deux états séparés).
4. **Fiche d'un repère** : une feuille de plus dans `PanneauRedimensionnable`, mêmes trois hauteurs que la fiche d'un coin, donc même `DetentPanneau.reservation` (la mention légale de Plans reste lisible).
5. **Liste** : une rangée dans `MonSpotView`, ou dans `SansPositionView` (« Toujours accessibles »).
6. **Y aller vers un repère** : N6 a sa propre règle (Plans sans question, autres applications après « X saura où se trouve ce repère »). Ne pas réutiliser `DecisionYAller` / « Toujours utiliser » pour un repère : ne jamais mémoriser un choix qui envoie une coordonnée exacte.
7. **Halo et réserve** : `AvertissementReserve` de N6 s'affiche dans la fiche d'un repère, pas dans celle d'un coin.
8. **Confidentialité** : une coordonnée de repère n'entre jamais dans `PrisesDuPecheurCarte`, `CacheCarte` ni le lieu flou (`AppariementPrises.lieuFlou`).
`docs/fiches/N6.md` est sur une autre branche (`origin/lot/n6`) : comparer avec sa section « Accroches » (1 à 9) au câblage.

## Pastille de fréquentation (proposition C « Silhouettes »)
`PastilleFrequentationView(niveau:)` (API inchangée) dessine un carré arrondi avec 1 (calme), 2 (moyen) ou 3 (fréquenté) silhouettes de pêcheur (`SilhouettePecheur`, une `Shape`), gris / ambre / bleu nuit, en clair et en sombre (`CouleursCarte.frequentation*` ; ambre et bleu locaux faute de jeton dans `Style.swift`). Niveau inconnu : carré neutre avec « ? ». Aucune phrase affichée ; VoiceOver : « Fréquentation calme / moyenne / forte / inconnue ». Non touchable : 32 pt qui suit le Dynamic Type, borné à 44 pt. `EtatPastille` : `.calme`, `.moyen`, `.frequente`, `.inconnu` (anciens `.vert/.orange/.rouge/.gris` et `rougeFrequentation` supprimés).

## À vérifier sur Mac
Pastille : rendu des silhouettes (tête + épaules) contre la planche, clair/sombre, AX5 ; Compilation de tout `App/Carte/` ; `MapContent` avec `ForEach` et `MapCircle` ; `.onMapCameraChange` et `Map(position:bounds:)` ; `Mirror` dans `LectureRecalage` (lit `recalee` sur `StationOFB` quand D5 le publie) ; `canOpenURL` avec `LSApplicationQueriesSchemes` ; `PanneauRedimensionnable` : geste de glissement contre le défilement ; fermeture de « Mon spot » 5 fois ; AX5 sur la colonne de droite ; aucune barre de défilement ; `AppUITests/Carte`.
