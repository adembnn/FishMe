# État du code, fonction par fonction (lecture du 15 oct. 2026)

Lu avec `git grep` sur les branches `origin/lot/*`, `origin/claude/core-linux-veq964` et `origin/sullyvan/*`. Aucune case de `fonctions-du-build.md` n'est cochée ici : le cochage se fait à l'écran, sur l'iPhone.

Deux faits qui valent pour tout le tableau :
- Il n'y a pas de branche `origin/main`. Chaque lot vit sur sa branche.
- `App/RootView.swift` est encore le « Hello, world! » du kit MWM sur toutes les branches (par exemple `origin/lot/abonnement:App/RootView.swift:6-27`). Aucune vue n'est donc branchée ni visible dans un build tant que A n'a pas câblé `RootView`. « Écrit » veut dire « la vue ou la logique existe dans son lot », pas « vu à l'écran ».

Les lots `aquarium`, `atelier`, `ecran-verrouille`, `hubeau`, `reconnaissance`, `regles-france` et `store` n'ont aucun fichier sous `App/` ni `Packages/`.

| Fonction | Branche | Preuve file:ligne | État |
|---|---|---|---|
| Carte autour du pêcheur, « N pêches, dernier relevé AAAA » | `lot/carte` | `App/Carte/StyleCarte.swift:61-65` ; `App/Carte/Vues/VueCarte.swift:85,91` | écrit |
| Position refusée : département ou commune, sans blocage | `lot/carte` | `App/Carte/Modele/GestionPosition.swift:28` ; `App/Carte/Vues/ChoixDeZoneView.swift:5-6` | écrit |
| Question du niveau, qu'on peut passer | `lot/premier-pas` | `App/Conseils/QuestionNiveauView.swift:5,35` | écrit |
| Cartes à glisser, cartes « déclarées » à part | `lot/premier-pas` | `App/Conseils/TunnelPremiersPasView.swift:7,64,143` | écrit |
| Vigilance orage et crue en bandeau, gratuite | `lot/conditions` | `App/Conditions/BandeauVigilanceView.swift:4,6` ; alertes lues dans `App/Conditions/SourceWeatherKit.swift:13` | écrit |
| Fiche d'un coin : rareté, conditions, jauge de la rivière | `lot/carte`, `lot/conditions` | `App/Carte/Vues/FicheCoinView.swift:8` ; `App/Conditions/JaugeRiviereView.swift:6` | écrit |
| Règles du jour, source et citation d'un toucher | `lot/carte` | `App/Carte/Vues/LigneRegleView.swift:5-6,38` | écrit |
| Départements couverts par `departementsCouverts()` | `lot/donnees` et autres | voir la section suivante : 75 et 94 seulement | partiel |
| Session : chrono, fin légale, prises, carte « à essayer » | `lot/session`, `lot/premier-pas` | `App/Session/BandeauSession.swift:37,46,52` ; `App/Session/MoteurSession.swift:87-91,133` ; `App/Conseils/CarteAEssayerView.swift:4,6` | écrit |
| Photo : 3 espèces en images, « Autre », « Pas un poisson », sans pourcentage | `lot/prise` | `App/Prise/PriseVuesEspece.swift:51,81,82` ; `App/Prise/PriseServices.swift:32` (repli : aucun score, la grille s'ouvre) | partiel (interface faite, pas de modèle de reconnaissance) |
| Bouton de photo d'exemple | `lot/prise` | `App/Prise/PriseCamera.swift:37-41` ; le fichier `photo-exemple.jpg` n'est pas dans la branche | partiel |
| Nombre d'espèces du modèle livré | `lot/reconnaissance` | aucun fichier de code, aucun `.mlmodel` sur aucune branche | absent |
| Toise lue, taille confirmée, poids « estimé » | `lot/prise` | `App/Prise/ToiseLecteur.swift:4,6,8` (Vision) ; `App/Prise/PriseLogique.swift:75-77` ; `App/Prise/PriseVuesResultat.swift:6` | écrit |
| Carte révélée : recto, dos avec photo et conditions | `lot/collection` | `App/Collection/CarteRectoView.swift:38` ; `App/Collection/CarteVersoView.swift:6,94-99` | écrit |
| Reflet sur rare et légendaire seulement | `lot/collection` | `App/Collection/StyleRarete.swift:88` ; `App/Collection/CarteRectoView.swift:56` ; `App/Collection/CartePleinEcranView.swift:39` | écrit |
| Toutes les espèces en images, compteur par zone | `lot/collection`, `lot/images-poissons` | `App/Collection/CompteurPescedex.swift:15,63` ; `App/Assets.xcassets/Especes/` (images par espèce) | écrit |
| Carte de sortie quand on rentre bredouille | `lot/collection`, `lot/session` | `App/Collection/BredouilleView.swift:5` ; `App/Session/MoteurSession.swift:35` | écrit |
| Partage d'une image sans coin exact | `lot/amis`, `lot/collection`, `lot/club` | `App/Collection/ImagePartage.swift:7` ; `App/Amis/ImageSansGPS.swift:5-6` ; `App/Collection/NettoyagePhoto.swift:5` ; `App/Club/PartageCarteView.swift:5` | écrit |
| Paywall : fin de 1re session qui se ferme, 2e spot qui bloque, « 7 jours » qui l'ouvre | `lot/abonnement` | `App/Abonnement/PaywallVue.swift:17` ; `App/Mesure/CoucheMesure.swift:6-9` (`finPremiereSession`, `autreSpot`) ; `App/Abonnement/TextesPaywall.swift:44,103-104,111-112` | partiel (vue et déclencheurs faits, rien n'ouvre le paywall tant que `RootView` n'est pas câblé) |
| Météo du jour et niveau de l'eau, avec Apple Weather | `lot/conditions` | `App/Conditions/SourceWeatherKit.swift:4,13,54` ; `App/Conditions/MarqueMeteoView.swift:57` ; `Packages/Core/Sources/Core/Conditions/HubEauNiveauService.swift:7` | écrit |
| Pro : 7 jours, courbe de 48 h, « Préviens-moi », conseils, « Tes conditions » | `lot/conditions`, `lot/premier-pas`, `lot/conseils` | `App/Conditions/SeptJoursView.swift:5` ; `App/Conditions/CourbeRiviereView.swift:5-6` ; `App/Conditions/PreviensMoi.swift:32,127` ; `App/Conditions/TesConditionsView.swift:6` ; `App/Conseils/ConseilsEspeceView.swift:48` ; `Packages/Core/Sources/Core/Conseils/ConseilsParEspece.swift:39` | écrit |
| Consentement avant Spark Flash, refus = SDK éteint | `lot/abonnement` | `App/Mesure/FeuilleConsentement.swift:5` ; `App/Mesure/Consentement.swift:4-9` ; `App/Mesure/CoucheMesure.swift:29` ; `App/Mesure/PasserelleSpark.swift:2,18` | écrit |

Total : 18 écrites, 4 partielles, 1 absente (23 lignes).

## Départements de règles couverts

`departementsCouverts()` ne code aucune liste en dur. Elle liste les fichiers `regles/<code>.json` présents (`Packages/Core/Sources/Core/Regles/MoteurRegles.swift:40-53`, qui s'appuie sur `ChargeurRegles.codesPresents()` à `ChargeurRegles.swift:93`, branche `origin/claude/core-linux-veq964` et copies dans les branches de lots).

Fichiers présents dans `Packages/Core/Sources/Core/Resources/regles/` (sur `lot/donnees`, `lot/moteur`, `lot/contrats`, `lot/carte`, `lot/conditions`, `lot/abonnement`, `lot/amis` et `claude/core-linux-veq964`) :
- `national.json` : socle national, 33 règles, 1 à vérifier, niveau « partiel ».
- `75.json` : Paris, 31 règles confirmées, 0 à vérifier, niveau « partiel ».
- `94.json` : Val-de-Marne, 45 règles confirmées, 0 à vérifier, niveau « partiel ».
- `index.json` (version 2026-10-15.1) ne liste que `75` et `94`, tous deux avec `expire_min` au 2026-12-31.

Donc **2 départements couverts : 75 et 94**, tous deux en niveau « partiel ». Les départements 92, 93 et 77, prévus par `CLAUDE.md`, n'ont aucun fichier sur aucune branche. Les 3 pilotes (01, 87, 44) et les autres départements non plus. `lot/regles-france`, `lot/veille` (mise à jour des règles) et `sullyvan/relecture-d1` ne contiennent aucun fichier de règles.

## Ce qui manque

- Le modèle de reconnaissance (R1) : aucun `.mlmodel`, donc « Nombre d'espèces » reste vide et la photo passe par la grille seule ; `photo-exemple.jpg` manque aussi.
- Les règles de 92, 93, 94 (écrit mais incomplet), 77 et le reste de la France : 2 départements sur les 5 promis.
- Le câblage dans `App/RootView.swift` (A) : tant qu'il est le « Hello, world! », aucune ligne du tableau ne peut être vue ni cochée sur l'iPhone.
