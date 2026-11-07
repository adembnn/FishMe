# Audit i18n US de FishMe

Date : 7 nov. 2026. Branche `lot/us-i18n`, d'après `fishme-tout` (80faaada). Lot sans modification de l'app : un audit, un script et un plan.
Tous les chiffres viennent de `outils/us/i18n/extraire_textes.py` (relancer : `python3 -I outils/us/i18n/extraire_textes.py`) ; le détail est dans `statistiques.json`, `inventaire.csv`, `formats.csv`. Plan : `plan.md`. Glossaire : `glossaire.md`.

## 1. Méthode et limites
- Le script lit le Swift avec un lexeur maison (littéraux simples, multilignes, bruts `#"…"#`, interpolations imbriquées ; commentaires ignorés), trouve l'appel qui enveloppe chaque littéral (`Text`, `Label`, `Button`, `navigationTitle`, `accessibilityLabel`, `alert`…) et lit les JSON de ressources de `Packages/Core`.
- Trois niveaux : « interface » (littéral dans une API d'affichage ou un paramètre `title:`, `texte:`…), « candidat » (littéral français hors API d'affichage : retour de fonction, constante, phrase du moteur) et « interne » (messages de validation pour le développeur, comptés à part). Les candidats sont repérés par heuristique (accents, mots-outils français) : quelques faux positifs (noms propres de lieux, un format) et quelques oublis (mots seuls sans accent) sont possibles. Un échantillon de 25 candidats en contenait environ 3 sans objet.
- Exclus : `AppTests`, `AppUITests`, `mwm-spark-flash-sdk`, catalogues d'images, géométries `.geojson` (3 fichiers, 572 373 octets).
- Hors inventaire : 3 messages d'autorisation du projet Xcode (`INFOPLIST_KEY_NSCameraUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSPhotoLibraryAddUsageDescription`, écrits en dur dans `project.pbxproj`, deux fois chacun) et les textes de `store/`.

## 2. Volumes
Dossiers parcourus : 430 fichiers Swift (App 321, WidgetAquarium 29, Widget 5, Core 75) ; 235 contiennent au moins un texte.

| Ensemble | Textes | Uniques |
|---|---|---|
| Swift, interface | 1 124 | 840 |
| Swift, candidats (841 App, 93 Core, 60 phrases du moteur) | 994 | 836 |
| Swift, interne développeur | 36 | 36 |
| **Swift total** | **2 154** | |
| JSON, texte affiché (règles, conseils, noms d'espèces, crédits, cas) | 43 401 | 30 810 |
| JSON, métadonnées de source (titres d'arrêtés, citations) | 25 138 | 15 789 |
| **Total** | **70 693** | 47 969 |

Par racine : App 1 887, WidgetAquarium 50, Widget 14, Core 68 742 (dont 68 539 JSON et 203 Swift). Interface seule : App 1 060, WidgetAquarium 36, Widget 14, Core 50.
Par appel : Text 418, Button 148, Label 147, accessibilityLabel 123, accessibilityHint 58, accessibilityValue 5 (soit 186 textes d'accessibilité), alerte 20, navigationTitle 15, TextField 13, Picker 8, Link 7, Tab 3, ContentUnavailable 3, Toggle 3, Section, Stepper, Menu 1 chacun, paramètres `title:`/`texte:`/`legende:`… 136, intents et widget 14.
Avec interpolation : 278 textes (155 côté interface).

Dossiers les plus chargés (interface + candidats) : Collection 229, Club 219, Carte 203, Abonnement 163, Amis 140, Conditions 130, Prise 109, Communauté 109, Profil 86, Conseils 72, Session 70, Core/Regles 65, Chat 57, Repères 53, WidgetAquarium 50. La liste complète est dans `statistiques.json`, clé `par_dossier_swift`. Les quatre dossiers réseau social (Club, Amis, Communauté, Chat) pèsent 525 textes, remplacés au lancement par l'écran « bientôt » (décision 6 du 7 nov.).
`App/RootView.swift` : 34 textes seulement sur 1 850 lignes, dont les 3 onglets (« Pescedex », « Carte », « Communauté »).

## 3. Ce qui est déjà localisable
- **988 textes** sont des littéraux passés à `Text`, `Label`, `Button`, `navigationTitle`, `accessibilityLabel`, etc. : SwiftUI les traite comme des clés de localisation, donc Xcode les extrait dans un String Catalog sans changer le code.
- **1 130 textes** ne le sont pas sans retouche : 136 paramètres `title:`/`texte:`/`legende:` de vues maison (type `String`), 841 candidats de l'App, 93 du Core, 60 phrases du moteur. Les 988 + 136 font les 1 124 textes d'interface.
- Déjà en place : **6** `LocalizedStringResource` (intents du widget : « Prendre une prise », « Mettre la session en pause », « Choisir les poissons », « Nourrir les poissons », « Retourner la carte », « Choisir la carte »). **0** `String(localized:)`, **0** `NSLocalizedString`, **0** fichier `.xcstrings`, `.strings` ou `.lproj`.
- Projet : `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`, `developmentRegion = fr`, `knownRegions = (en, fr, Base)`, `STRING_CATALOG_GENERATE_SYMBOLS = YES` sur l'app. Le catalogue peut donc commencer sans réglage de projet, mais il faut ajouter le fichier au projet (garde-fou : `*.pbxproj` refusé aux agents).
- `Package.swift` de Core : aucun `defaultLocalization` ; Core n'a pas de catalogue et ses chaînes `String` ne passent par aucun bundle de localisation.

## 4. Ressources JSON qui dépendent de la région
Tout `Packages/Core/Sources/Core/Resources/` est français :
- `regles/<département>.json` : 98 fichiers (96 départements, `national`, `index`), 20 753 `phrase`, 14 891 `valeur.texte`, 7 122 noms de `eaux`, 20 726 `citation`, 4 280 titres d'arrêtés. Ces 35 644 phrases ne se traduisent pas : une règle américaine est une autre donnée (État, plan d'eau, espèce), avec sa propre source ; les citations d'arrêtés sont du droit français.
- `Conseils/conseils.json` : 276 conseils (espèces françaises, appâts français), 104 sources. À réécrire pour les espèces américaines, pas à traduire.
- `especes.json` (99 noms, espèces françaises), `liens-federations.json` (96 fédérations), `longueur-poids.json` (66 notes ; table a et b en cm et g), `cas-verdicts.json` (13 cas d'or), `credits.json` (14 crédits).
- `departements.geojson`, `coins-osm.geojson` : géométrie française.
- `Package.swift` déclare `regles` en `.copy` : `departementsCouverts()` liste les fichiers présents, donc un dossier par région est possible sans toucher le code de lecture.
- Mots à éviter dans ces données : 5 972 textes affichés contiennent « autoris… » (dont 3 074 champs `phrase` dans 86 fichiers : CLAUDE.md en compte 3 075) ; 400 « permis/permet… » (hors « permis de pêche »), 46 « légal… », 14 « tu peux la garder » ou équivalent. Côté citations de source : 2 372 « autoris… », intouchables (texte de loi).

## 5. Texte dynamique composé en français
- **Pluriels** : 22 ternaires de flexion sur 19 lignes dans 11 fichiers (`n > 1 ? "pêches" : "pêche"`, `prise\(n > 1 ? "s" : "")`, `"jours"/"jour"`, `"offerts"/"offert"` dans `TextesPaywall.swift` lignes 31 à 48, `OuChercherModele.swift` 84, `StyleCarte.swift` 124, `CarteRectoView.swift` 414, `CarteAEssayerView.swift` 417 et 424, `RecapSortieView.swift` 114 et 115, `SessionEnCoursView.swift` 236, `BandeauSession.swift` 72, `RappelCartePeche.swift` 28, `CompteurPescedex.swift` 37, `FicheCoinView.swift` 353). L'anglais a d'autres règles (0 = « 0 catches », pas de « No catch »), et `GalerieSkins.swift` 95 et 96 compose des fragments français entiers dans une interpolation. À remplacer par des clés à variantes de pluriel du String Catalog.
- **Accords** : « offert/offerte/offerts/offertes » (paywall), « légendaire(s) », « relevée(s) », « mesurée », « masqué », « fermée » : aucun équivalent anglais, à supprimer en réécrivant.
- **« N sur M »** : 14 compteurs réels (un 15e repéré, `MesSortiesView.swift` 168, est un faux positif) dans 10 fichiers : `CompteurPescedex.swift` 46, 49, 52, 66, `PescedexView.swift` 1002, 1046, 1092, `CarteRectoView.swift` 415, `LogiqueConseils.swift` 186, `TunnelPremiersPasView.swift` 97, `ListeReperesView.swift` 80, `TextesReperes.swift` 48, `PescedexAmiView.swift` 210, `MoteurConditions.swift` 179. L'anglais dit « N of M ». Locutions de région (`locutionRegion`, « en France », « dans le 75 ») à remplacer par un nom de région.
- **Élisions et articles** : `RegionsFrance.swift` (« en Occitanie », « dans le 75 ») ; « à toi », « chez toi » ; le tutoiement disparaît en anglais.
- **Phrases du moteur** : `PhrasesNeutres.swift` réécrit des phrases françaises par expressions régulières (« se garde à partir de N cm » devient « taille minimale N cm ») : mécanisme entièrement français, sans objet en anglais.
- **Heure et date en clair** : 30 textes d'interface contiennent un mois, un jour, « 1er » ou « 18 h » ; 9 100 textes de règles aussi (« du 1er mars au 1er octobre »).

## 6. Unités et dates en dur
- **Unités dans les textes d'interface** (35 lignes) : cm 17, km/h 4, km 3, mm 3, m 3, hPa 2, m³/s 2, ° 1. Dans les candidats (28 lignes) : cm 14, kg 5, g 3, m³/s 2, km 2. Dans les textes de règles affichés (4 628 lignes) : cm 2 160, m 1 895, g 389, mm 130, km 93, °C 23, kg 5 (tailles, distances de tronçons, poids).
- **Unités dans le modèle de données** : 359 identifiants à unité dans le nom (`tailleCm` 127, `longueurCm` 105, `pluieMm` 31, `valeurCm` 12, `seuilTropheeCm` 11, `distanceMetres` 8, `p95Cm` 8, `poidsKg` 6…), `longueur-poids.json` (W en g, L en cm), mesure de toise en pixels par cm. Aucun `Measurement` ni `UnitLength` : 0 usage. Le stockage restera métrique ; seul l'affichage change.
- **Formats** (`formats.csv`) : `Locale(identifier: "fr_FR")` 31 occurrences (dont `Formats.locale` dans `App/Collection/Formats.swift`), `TimeZone(identifier: "Europe/Paris")` 7, `Calendar(identifier: .gregorian)` 9, `DateFormatter` 11, `dateFormat` 8 (`"dd/MM"` dans `TextesEnvies.swift` 23 et `LogiqueConseils.swift` 124, `"d MMMM"`, `"H 'h'"` dans `StyleMeteo.swift` 99, `"yyyy-MM-dd"`), `.formatted(date…)` 14, `NumberFormatter` 10 (virgule décimale), `String(format:)` 15 (dont 19 formats numériques), `RelativeDateTimeFormatter` via `.relative` 1 (`CompteView.swift` 195). Le jour sans année « dd/MM » est en ordre jour-mois : l'américain est mois-jour.
- Heure à la française : 4 occurrences de `hour(` en 24 h (`BandeauSession`, widgets, Live Activity) ; soleil et fin de session à `Europe/Paris`.
- Température de l'eau, pluie, vent, pression, débit sont écrits en dur avec leur unité dans `App/Conditions` (17 sites de format) et `Core/Conditions`.

## 7. Mots à éviter déjà présents dans l'interface
26 textes Swift (14 d'interface, 12 candidats) portent un mot à éviter, plus 3 textes internes. Les cas qui demandent une décision :
- « Fin légale » / « fin légale dans » : 11 occurrences (`BandeauSession.swift` 51, `SessionEnCoursView.swift` 167, `VuesSessionWidget.swift` 67, 128, 194, `SessionLiveActivity.swift` 30, 36, 128, 161, `RangeeMaintenantView.swift` 107, `SuiviSession.swift` 171). La fin légale du jour de pêche (coucher du soleil plus 30 min en France) n'existe pas telle quelle aux États-Unis : l'horaire dépend de l'État et il ne faut ni « legal » ni « allowed ». Décision à prendre avec le verdict d'horaires.
- « Pêche illégale » (`MotifSignalement.swift` 18) : motif de signalement ; « Suspected poaching » ou « Fishing violation » à choisir.
- `TexteConditions.swift` : « permis », « légal », « garantie légale », « ce qui est permis » dans les conditions d'utilisation (lignes 26, 58, 67, 68, 82, 85, 88, 89, 96, 106). Texte contractuel : à faire écrire par le juriste américain, pas à traduire.
- « Autoriser la position » (`SansPositionView.swift` 83) et « Autorise-le dans les réglages » (`PriseCamera.swift` 118) : vocabulaire des permissions iOS, « Allow » reste correct ; à exclure de la liste.
- « Source météo : page légale d'Apple Weather » (`MarqueMeteoView.swift` 84) : « Legal » est le nom du lien d'Apple, à garder.
