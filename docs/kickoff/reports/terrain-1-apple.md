# Terrain 1 - Couche Officiel (Apple) - au 12 oct. 2026

Convention : une source par affirmation, [?] = non vérifié. Les finalistes ADA n'ont pas de raison publiée par Apple.

## 1. Apple Design Awards

### 2026 (annoncés 2 juin 2026) - source : https://www.apple.com/newsroom/2026/06/apple-reveals-winners-of-the-2026-apple-design-awards/
Gagnants (catégorie : app, puis jeu) :
- Delight and Fun : **grug** (Ocho) - courts prompts façon homme des cavernes qui donnent un moment de réflexion quotidien. / Is This Seat Taken?
- Inclusivity : **Guitar Wiz** - cours de guitare parlés + Dynamic Type, contraste, couleur non seule. / Pine Hearts
- Innovation : **NBA: Live Games & Scores** - jusqu'à 5 matchs en direct sur Vision Pro. / Blue Prince
- Interaction : **Moonlitt: Moon Phase Tracker** - suivi lunaire simple, forte intégration Liquid Glass. / Sago Mini Jinja's Garden
- Social Impact : **Primary: News in Depth** - actu spatiale Vision Pro, éditeurs humains. / Consume Me
- Visuals : **Tide Guide: Charts & Tables** - prévisions de marées heure par heure, animations custom. / Cyberpunk 2077
Finalistes apps notables : Blippo+, Metaballs, Hearing Buddy, **Structured**, **Detail: AI Video Editor**, Pickle Pro, **The Outsiders: Athlete Tracker**, Harvee, Katha Room, **(Not Boring) Camera**, Caradise (même source).
- Lecture : aucun gagnant 2026 n'est vendu comme "Apple Intelligence" ; 9to5mac ne mentionne ni Foundation Models ni Liquid Glass pour les gagnants https://9to5mac.com/2026/06/02/apple-reveals-apple-design-awards-app-and-game-winners-for-2026/ (hors Moonlitt, cité pour Liquid Glass par Apple).

### 2025 - source : https://www.apple.com/newsroom/2025/06/apple-unveils-winners-and-finalists-of-the-2025-apple-design-awards/
- Delight : **CapWords** - photo d'objet -> sticker interactif pour apprendre des mots en 9 langues. / Balatro
- Innovation : **Play** (Rabbit 3 Times) - prototypes SwiftUI interactifs, collaboration temps réel. / PBJ - The Musical
- Interaction : **Taobao** - achat 3D immersif Vision Pro. / DREDGE
- Inclusivity : **Speechify** - texte vers audio, centaines de voix, 50+ langues. / Art of Fauna
- Social Impact : **Watch Duty** - alertes feux, périmètres, évacuations pendant les feux de LA. / Neva
- Visuals : **Feather: Draw in 3D** - 2D vers 3D à l'Apple Pencil. / Infinity Nikki
Finalistes apps notables : Lumy, Denim, Moises, Capybara, Pawz, iA Writer, **Mela - Recipe Manager**, Evolve, Train Fitness, Ground News, **Opal**, Vocabulary, CellWalk (même source).

### 2024 - source : https://apple.com/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards
- Delight : **Bears Gratitude** - journal de gratitude avec personnages chaleureux, habitude quotidienne. / NYT Games
- Inclusivity : **oko** - signale les feux piétons aux malvoyants (haptique + audio). / Crayola Adventures
- Innovation : **Procreate Dreams** - animation 2D avec pinceaux/gestes Procreate. / Lost in Play
- Interaction : **Crouton** - recettes, interface qui reste utilisable au plan de travail. / Rytmos
- Social Impact : **Gentler Streak** - fitness/bien-être, progrès perso sans comparaison. / The Wreck
- Visuals : **Rooms** (Things, Inc.). / Lies of P
- Spatial : **djay pro** / Blackbox
Finalistes apps notables : Dudel Draw, Tiimo, **Copilot Money**, SmartGym, Wavelength, Arc Search, finity., Ahead, How We Feel, Sky Guide, Sunlitt (même source).

### Constat transversal (déduction, à défendre)
- Les gagnants sont des **outils étroits, soignés, à usage quotidien** (marées, lune, gratitude, recettes, feux) : le jury récompense une promesse simple et un détail d'exécution, pas la techno IA. Cohérent avec "omission par design" (grug).
- Récurrence : accessibilité, haptique, animations sur-mesure, intégration fine des API système (Liquid Glass en 2026).

## 2. WWDC 2025 (iOS 26)

### Foundation Models framework
- API Swift pour le modèle on-device d'Apple Intelligence ; offline, sans coût d'inférence par usage https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/
- Contexte : **4096 tokens** entrée+sortie combinées ; texte seul ; petit modèle (hallucine, logique faible), pas de recherche web, savoir figé (~oct. 2023) https://www.natashatherobot.com/p/apple-foundation-models
- iOS 26.4 : `contextSize` et `tokenCount(for:)` pour mesurer le budget, rétro-compatibles https://infoq.com/news/2026/03/apple-foundation-models-context
- Fort sur : résumé, extraction, classification, tagging, réécriture https://www.natashatherobot.com/p/apple-foundation-models
- **Guided generation** : macro `@Generable` -> objets Swift typés sans JSON ; contraintes `.anyOf`, regex, plages, nombre d'éléments ; l'ordre des propriétés compte https://www.natashatherobot.com/p/swift-prompt-engineering-apples-foundationmodels
- **Tool calling** : outils passés à `LanguageModelSession`, le modèle décide quand les appeler (calendrier, rappels, localisation) https://www.natashatherobot.com/p/apple-foundation-models ; les définitions d'outils consomment du contexte https://infoq.com/news/2026/03/apple-foundation-models-context
- Langues : EN, FR, DE, IT, PT-BR, ES, JA, KO, ZH-Hans (autres prévues) https://www.natashatherobot.com/p/apple-foundation-models
- Prérequis : appareil compatible Apple Intelligence activé, iOS 26+ ; prévoir 4 cas d'indisponibilité et un fallback https://www.natashatherobot.com/p/apple-foundation-models
- Garde-fous parfois à faux positifs ; limiter la saisie libre dans le prompt https://www.natashatherobot.com/p/swift-prompt-engineering-apples-foundationmodels
- Pas de version du modèle épinglable https://www.natashatherobot.com/p/apple-foundation-models
- Implication : "IA décorative" évitable en faisant produire une **sortie structurée** (@Generable) qui pilote l'UI ; chatbot libre = mauvais usage (et interdit par la carte de rejet).

### Autres nouveautés iOS 26 (utilisateur)
- Liquid Glass : nouveau matériau translucide (contrôles, navigation, icônes, widgets, écran d'accueil) https://www.apple.com/newsroom/2025/06/apple-elevates-the-iphone-experience-with-ios-26/
- Visual Intelligence sur le contenu de l'écran (ChatGPT, recherche Google/Etsy, événements -> Calendrier) ; Live Translation on-device (Messages, FaceTime, Téléphone) ; Call Screening, Hold Assist https://www.apple.com/newsroom/2025/06/apple-elevates-the-iphone-experience-with-ios-26/
- Shortcuts : actions Apple Intelligence, prompts vers modèle on-device ou Private Cloud Compute https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/
- Wallet : Live Activities pour cartes d'embarquement https://www.apple.com/newsroom/2025/06/apple-elevates-the-iphone-experience-with-ios-26/
- Image Playground / Genmoji enrichis ; Workout Buddy (Watch) https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/
- App Intents "interactive snippets", Visual Intelligence API pour apps tierces, Speech (SpeechAnalyzer), Translation API, Live Activities sur Mac/CarPlay : [?] non retrouvés dans les sources lues cette session, à vérifier sur developer.apple.com/wwdc25.

## 3. WWDC 2026 (keynote 9 juin ; iOS 27 sorti le 14 sept. 2026)

### Pour développeurs
- Foundation Models : entrée **image**, modèles tiers (Claude, Gemini) via la même API Swift, **Dynamic Profiles** (changer modèle/outils/instructions dans une session), framework **Evaluations** https://developer.apple.com/wwdc26/guides/ios/
- **Accès gratuit à Apple Foundation Models sur Private Cloud Compute** pour les devs avec < 2 M de premiers téléchargements (Small Business Program) : plus de coût serveur https://developer.apple.com/wwdc26/guides/ios/ et https://www.macrumors.com/2026/06/09/apple-outlines-major-ai-and-developer-tool-updates/
- Les outils Vision (OCR, code-barres) sont appelables par le modèle on-device https://developer.apple.com/wwdc26/guides/ios/
- Taille de contexte du nouveau modèle PCC/on-device : [?] non trouvée ; ne pas supposer plus de 4096 en local.
- Open-source du framework annoncé "later this summer" https://www.macrumors.com/2026/06/09/apple-outlines-major-ai-and-developer-tool-updates/ ; réalisé ? [?]
- **App Intents / Siri** : schémas d'entités (contenu indexé dans l'index sémantique Spotlight avec attribution), schémas d'intents (actions sans phrases prédéfinies), **View Annotations** (Siri agit sur le contenu à l'écran), framework AppIntentsTesting https://developer.apple.com/wwdc26/guides/ios/
- **Core AI** : exécuter ses propres modèles on-device, sans token ni serveur https://developer.apple.com/wwdc26/guides/ios/ (trop lourd pour une semaine, [?] utilité).
- WidgetKit : widgets personnalisables via App Intents et styles dynamiques https://developer.apple.com/wwdc26/guides/ios/
- Music Understanding, Now Playing frameworks https://developer.apple.com/wwdc26/guides/ios/
- Liquid Glass : adoption automatique en recompilant avec Xcode 27, opt-out supprimé, curseur de transparence utilisateur https://www.macrumors.com/2026/06/09/apple-outlines-major-ai-and-developer-tool-updates/
- Xcode 27 : agents (simulateur, tests, correction de crashs Organizer), Device Hub remplace Simulator https://www.macrumors.com/2026/06/09/apple-outlines-major-ai-and-developer-tool-updates/
- Speech, Translation, HealthKit, Live Activities 2026 : rien trouvé dans les sources lues [?].

### Pour utilisateurs (ce qu'Apple fait déjà)
- **Siri AI** : refonte complète ; recherche par sens dans Mail/Messages/Photos/Notes/Rappels/Calendrier/Fichiers, connaissance web, conscience de l'écran, app Siri avec historique, "Search or Ask" remplace Spotlight, "Write with Siri" partout https://www.igeeksblog.com/siri-ai-ios-27-features/
- **Visual Intelligence dans l'app Appareil photo** : infos nutritionnelles, partage d'addition, plusieurs événements depuis une photo, contacts depuis cartes de visite, cartes de fidélité -> Wallet, explication d'étiquettes/ingrédients https://www.igeeksblog.com/siri-ai-ios-27-features/
- Safari : surveillance de pages (restock, baisse de prix), regroupement d'onglets ; Photos : Extend, Spatial Reframing, Clean Up https://nextrift.com/202643597/
- Matériel : Siri AI exige iPhone 15 Pro+ ; fonctions avancées de voix/dictée iPhone 17 Pro+ https://www.igeeksblog.com/siri-ai-ios-27-features/
- Disponibilité : anglais d'abord (US, UK, CA, AU, IE, IN, NZ, ZA) ; FR/JA/KO/PT/ES annoncées via iOS 27.2 beta ; absent de Chine et de l'UE sur iPhone/iPad au lancement ; liste d'attente https://www.igeeksblog.com/siri-ai-ios-27-features/
- Private Cloud Compute : Siri AI combine on-device et PCC, données non accessibles à Apple https://www.igeeksblog.com/siri-ai-ios-27-features/ (source secondaire ; vérifier sur security.apple.com [?]).

## 4. Apps tierces remarquables (Foundation Models)
Source : https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/ (Apple les a mises en avant, sept. 2025)
- **SmartGym** : décrit un entraînement en langage naturel -> routine structurée ; résumés et messages de coaching.
- **Stoic** : prompts de journal depuis les entrées récentes, recherche en langage naturel.
- **7 Minute Workout** : séances depuis demandes libres ("éviter ce qui aggrave ma blessure").
- **Train Fitness** : exercice alternatif si l'équipement manque.
- **Streaks** : suggère et catégorise des tâches ; **Stuff** : reconnaît dates/tags en tapant, voix -> tâches ; **OmniFocus 4** : projets et étapes ; **Agenda** : "Ask Agenda" sur ses notes.
- **CellWalk** : explique des termes scientifiques selon le niveau ; **Grammo** : explique l'erreur et génère des exercices ; **Lil Artist** : histoires illustrées pour enfants (+ ImageCreator) ; **Vocabulary** : classe les mots par thème.
- **Detail: AI Video Editor** : plan -> script téléprompteur, titres, hashtags ; **VLLO** : musique/stickers par scène ; **Essayist** : extraction PDF + citations (avec Vision) ; **Signeasy** : résumé et questions sur un document.
- Verbatim développeurs (Stuff, SmartGym, CellWalk) https://9to5mac.com/2025/09/29/apple-intelligence-ios-26-models-developers/
- Recoupement ADA : SmartGym, Train Fitness, Vocabulary, CellWalk, Detail sont **finalistes ADA** (sections 1) -> l'IA on-device bien intégrée aide, ne suffit pas.
- Exemples marquants d'usage App Intents 2026 (Siri/Spotlight) : [?] aucune app citée par Apple dans les sources lues.

## 5. Déjà couvert nativement (à ne pas refaire) - cf. carte de rejet
- Résumés Mail/Notes/Notifications, Writing Tools, Genmoji, Image Playground, nettoyage photo https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/
- Traduction en direct (Messages, FaceTime, appels), filtrage d'appels https://www.apple.com/newsroom/2025/06/apple-elevates-the-iphone-experience-with-ios-26/
- Recherche sémantique perso, assistant écran, rédaction, Visual Intelligence (nutrition, addition, cartes, événements, étiquettes) https://www.igeeksblog.com/siri-ai-ios-27-features/
- Suivi de prix/restock dans Safari https://nextrift.com/202643597/
- Rappels auto-catégorisés, suivi de commandes dans Wallet, sondages Messages, recherche Photos en langage naturel https://www.apple.com/newsroom/2025/06/apple-intelligence-gets-even-more-powerful-with-new-capabilities-across-apple-devices/
- Risque : tout chatbot / assistant généraliste / résumeur de texte est écrasé par Siri AI.

## 6. Implications pour la décision (jugement, pas sourcé)
1. Différenciateurs réellement accessibles à des non-devs en 1 semaine : `@Generable` (sortie typée), tool calling sur données perso (Calendrier, Rappels), PCC gratuit < 2 M de downloads (coût IA nul, argument marge), entrée image, App Intents pour que Siri/Spotlight appellent l'app.
2. À éviter : dépendre de Siri AI (liste d'attente, absent UE/Chine, anglais d'abord) ; fenêtre 4096 tokens en local (documents longs impossibles sans découpage) ; Core AI.
3. Prévoir fallback sans Apple Intelligence (appareils non éligibles) : impact test sur iPhone de test sur place.
4. Les ADA suggèrent : promesse minuscule, exécution très soignée, accessibilité, Liquid Glass natif (gratuit en recompilant).
