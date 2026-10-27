# Aquarium : deux rendus à 0 pixel (27 oct.)

État : les 5 tests de `AquariumDepuisJSONTests` passent (run réelle ci-dessous). Rien commité.

## Cause (mesurée)
Sans animation, `ImagesAnimees` dessinait `image(0)`, la pose 0 de chaque poisson. Depuis le 16 oct. (« pleine eau », `NageWidget.traversees`), la pose 0 est un point de DÉPART de traversée : hors du cadre ou à opacité 0.
Preuve (`NageWidget.traversees` compilé seul, brochet du JSON de test) : sur 8 créneaux la pose 0 est à x = -0.20, 1.13, 1.12, -0.19, 0.44 (opacité 0), 1.22, 0.40 (opacité 0), -0.10 ; sur 200 créneaux, elle n'est jamais visible dans le cadre.
Défaut produit : « Réduire les animations » = aucun poisson dans le widget (même chemin).

## Changements (sans commit)
- `WidgetAquarium/AnimationWidget.swift` : le repli sans animation appelle `image(-1)` (pose de repos).
- `WidgetAquarium/VuesAquariumWidget.swift` : `Nageur.repos(l:)` choisit la pose où le poisson se voit le mieux (opacité x part visible dans le cadre x échelle, 2/3 hauts préférés) ; `j < 0` l'utilise.
  Une 1re version (première pose dans une fenêtre étroite) échouait pour 38 % des créneaux : fait mesuré, remplacée.
- `AppTests/WidgetRendu/AquariumDepuisJSONTests.swift` :
  - `renduFixeMontreLePoisson` : date fixe (créneau où le brochet traverse les 2/3 hauts) au lieu de `.now`, sinon le résultat dépendait de l'heure (certains créneaux ont le poisson sur le bord bas). Seuil `> 200` inchangé.
  - `coucheDeBaseVisibleSousLAnimation` remplacé (choix d'Adem, option b) par `uneCopieDeLAnimationMontreLePoisson` : rend une seule copie `image(j)` du poisson, à une pose dans le cadre, et exige `> 200` pixels opaques. La couche de base n'est PAS rétablie (retirée exprès le 16 oct., widget noir sur iPhone 12).

## Run réelle (iPhone 17, `-only-testing:BuildChallengeTests/AquariumDepuisJSONTests`, log aq-run4.log)
** TEST SUCCEEDED **
Test case 'AquariumDepuisJSONTests/renduFixeMontreLePoisson()' passed
Test case 'AquariumDepuisJSONTests/configurationParDefautGardeLesPoissons()' passed
Test case 'AquariumDepuisJSONTests/uneCopieDeLAnimationMontreLePoisson()' passed
Test case 'AquariumDepuisJSONTests/policesDeMasqueChargees()' passed
Test case 'AquariumDepuisJSONTests/imageDuPoissonTrouvee()' passed
(Pas de ligne « Test run with » dans ce log xcodebuild : décompte 5 passés, 0 échec.)

## Limites
- Le rendu du widget animé complet n'est pas testé : `ImageRenderer` ne dessine pas les masques chronos.
- Dans certains créneaux le poisson de repos est sur le bord bas (nage le long du fond) : voulu par l'animation.
- Le test des décors `DecorsDessinesTests.leCadreGardeLeSolEnBasEtLePlafondEnHaut` contredit `CadreDecor` : non touché.
