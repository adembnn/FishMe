Décision débloquée : entraîner notre propre modèle de reconnaissance des poissons aujourd'hui, ou s'appuyer sur l'IA d'Apple, ou les deux.

Lu le 15/10/2026. [?] = non confirmé. « Estimation » = mon calcul, pas une mesure. Je n'ai pas de Mac ici : rien de ce qui suit sur Create ML n'a été exécuté, c'est de la lecture de documentation. Les comptages d'images, eux, sont de vraies requêtes faites aujourd'hui.

## Version simple
Deux façons d'identifier un poisson sur une photo. (A) Apprendre à l'iPhone à reconnaître nos 14 espèces avec des milliers de photos étiquetées : c'est Create ML, l'outil d'Apple qui fabrique le modèle en glissant des dossiers de photos, sans code. Le modèle obtenu tourne sur tous les iPhone et on peut mesurer sa précision. (B) Demander à l'IA générale d'Apple (Foundation Models) : rien à entraîner, mais seulement sur les iPhone 15 Pro et plus, avec Apple Intelligence activé, et personne n'a mesuré sa précision sur un gardon contre une brème.

Trois constats qui changent le plan :
1. iNaturalist interdit d'utiliser ses données pour entraîner une IA à usage commercial. Notre abonnement est commercial. La source de photos la plus évidente est donc fermée.
2. Les photos libres hors iNaturalist existent mais manquent pour 4 espèces (sandre, silure, barbeau, ombre).
3. Aucun chiffre publié ne couvre gardon/brème/chevesne ni fario/arc-en-ciel sur des photos de pêcheurs. La seule façon de savoir est de tester sur nos propres photos.

Mini-lexique. Create ML : app de Xcode qui entraîne un modèle à partir de dossiers de photos. Core ML : le moteur d'Apple qui fait tourner ce modèle dans l'app. Vision : le module qui prépare l'image et lit le résultat. Apprentissage par transfert : le modèle réutilise un « œil » déjà entraîné par Apple et n'apprend que nos 14 étiquettes. Top-1 : la bonne espèce est la première proposée. Top-3 : elle est parmi les 3 proposées (c'est ce que l'app montre). Matrice de confusion : tableau qui dit « quand c'était un gardon, l'IA a dit brème N fois ». Jeu de test : photos jamais vues à l'entraînement, qui servent à noter le modèle.

## 1. Create ML (classifieur d'images)
| Question | Réponse | Source |
|---|---|---|
| Images par classe | Minimum 10 (Apple), classes équilibrées, images d'au moins 299 x 299 px, angles et lumières variés. Pour le test, 25 images ou plus par classe. Pour une espèce proche d'une autre, viser 150 à 300 en entraînement (estimation, voir §3). | [Apple, Creating an Image Classifier Model](https://developer.apple.com/documentation/createml/creating-an-image-classifier-model) |
| Comment ça apprend | Apprentissage par transfert sur un extracteur de traits fourni par Apple (scene print). | [Apple, featureExtractor](https://developer.apple.com/documentation/createml/mlimageclassifier/modelparameters-swift.struct/featureextractor) |
| Temps d'entraînement | Apple ne donne pas de chiffre. Un tutoriel de 2018 donne environ 30 s pour 160 images. Pour 3 000 à 5 000 images sur Mac Apple silicon : 5 à 20 min par essai (estimation) [?]. | [AppCoda](http://appcoda.com/create-ml/) |
| Taille du modèle | Très petite, car l'œil reste dans l'OS : « bien moins de 100 Ko » pour un exemple de fleurs en 2019. Pour 15 classes, moins de 5 Mo (estimation) [?]. | [WWDCNotes](https://wwdcnotes.com/documentation/wwdc19-430-introducing-the-create-ml-app) |
| Tous les iPhone iOS 27 ? | Oui par construction : Core ML n'est pas Apple Intelligence. iOS 27 va de l'iPhone 11 à l'iPhone 18 Pro. Aucune page Apple ne dit la phrase « sans Apple Intelligence » [?]. | [Apple, modèles compatibles iOS 27](https://support.apple.com/guide/iphone/iphone-models-compatible-with-ios-27-iphe3fa5df43/ios) |
| Nouveautés Create ML sous Xcode 27 | Je n'ai rien trouvé de daté 2026 sur l'image classifier [?]. Les pages lues sont génériques. | |
| Où le lancer | Xcode, menu Open Developer Tool, Create ML. Il faut un Mac (A ou B, pas C). | Apple, même page |

Intégration, 5 lignes avec l'API Vision classique (la forme documentée par Apple) :
```swift
let ml = try VNCoreMLModel(for: PoissonsFR(configuration: .init()).model)
let req = VNCoreMLRequest(model: ml)
try VNImageRequestHandler(cgImage: photo).perform([req])
let top3 = (req.results as? [VNClassificationObservation] ?? []).prefix(3)
// chaque élément : .identifier (espèce) et .confidence (0 à 1)
```
`PoissonsFR` est la classe que Xcode génère à partir du fichier `.mlmodel` déposé dans le projet. Depuis iOS 18, `CoreMLRequest` est la version moderne du même appel ([Apple](https://developer.apple.com/documentation/vision/coremlrequest)) ; sa syntaxe exacte n'est pas vérifiée [?], rester sur la version classique.

## 2. Données utilisables pour une app payante
**iNaturalist est exclu.** Ses conditions d'utilisation, §7 « Prohibited Use for Commercial AI Training » : « Users may not use any iNaturalist data for training artificial intelligence, machine learning models [...] for commercial purposes » ([iNaturalist, Terms](https://www.inaturalist.org/pages/terms), page révisée le 30 oct. 2024). Une photo peut être CC0 ou CC-BY au niveau de son auteur et rester interdite par ce contrat. Le jeu iNaturalist est aussi republié sur GBIF (dataset `50c9509d-22c7-4a22-a47d-8c48425ef4a7`) : y piocher contourne peut-être la lettre du contrat, pas son intention. Je le traite comme interdit. Valeur juridique exacte à faire confirmer [?].

Comptages réels (requêtes du 15/10/2026, monde entier, avant tout tri). iNaturalist : API v1, `photo_license=cc0,cc-by&quality_grade=research&per_page=0`, champ `total_results`. GBIF : `occurrence/search?mediaType=StillImage&license=CC0_1_0&license=CC_BY_4_0&limit=0&facet=datasetKey`, « hors iNat » = total moins le jeu iNaturalist.
| Espèce | Nom latin | iNat (exclu) | GBIF total | GBIF hors iNat |
|---|---|---|---|---|
| Brochet | Esox lucius | 1 422 | 2 888 | 1 356 |
| Sandre | Sander lucioperca | 101 | 226 | 119 |
| Perche | Perca fluviatilis | 1 098 | 1 952 | 700 |
| Black-bass | Micropterus salmoides | 378 | 610 | 281 |
| Silure | Silurus glanis | 98 | 197 | 92 |
| Truite fario | Salmo trutta | 1 513 | 3 764 | 1 995 |
| Truite arc-en-ciel | Oncorhynchus mykiss | 1 526 | 2 542 | 943 |
| Carpe | Cyprinus carpio | 3 154 | 4 689 | 1 737 |
| Gardon | Rutilus rutilus | 3 170 | 1 449 | 740 |
| Brème | Abramis brama | 310 | 779 | 425 |
| Chevesne | Squalius cephalus | 874 | 1 598 | 573 |
| Tanche | Tinca tinca | 854 | 456 | 242 |
| Barbeau | Barbus barbus | 560 | 263 | 121 |
| Ombre | Thymallus thymallus | 208 | 273 | 154 |
| Total | | 15 266 | | 9 478 |

À lire avec prudence :
- Ce sont des observations, pas des photos utilisables : il y a des poissons sous l'eau, des alevins, des spécimens de musée, des erreurs d'identification. Taux de photos utilisables après tri : 40 à 70 % (estimation). Pour la fario, `Salmo trutta` inclut la truite de mer.
- Presque aucune de ces photos n'est « poisson tenu par un pêcheur ». C'est le décalage de domaine : un modèle entraîné sous l'eau note mal une photo de prise.
- Sous 150 photos hors iNat : sandre (119), silure (92), barbeau (121), ombre (154 à la limite). Pour celles-là, il faut des photos apportées par l'équipe ou des clubs.
- Les datasets GBIF hors iNat (clés 93c707dc..., 7e380070..., 9c0c7f86...) n'ont pas été identifiés ni leurs conditions lues [?].
- GBIF lui-même ne fait pas respecter les licences NC mais demande d'honorer l'intention ([GBIF, Terms](https://www.gbif.org/es/terms)). On filtre sur CC0 et CC-BY seulement : CC-BY-SA (partage à l'identique), NC (non commercial) et ND (pas de dérivés) sont écartés.

**Attribution CC-BY quand on entraîne un modèle.** Creative Commons écrit que toute licence CC exige de citer les auteurs et que pour l'entraînement, l'attribution « could be a simple link to the source of the dataset » ([Creative Commons, AI training](https://creativecommons.org/using-cc-licensed-works-for-ai-training-2)). Pratique : un écran « Crédits des photos d'entraînement » avec les jeux GBIF (DOI du téléchargement) et un lien, plus un fichier manifeste généré par script (URL, auteur, licence) gardé hors du dépôt. L'exception européenne de fouille de données pour usage commercial est probable mais non vérifiée ici [?] : à faire valider avant publication.

## 3. Précision attendue
| Mesure publiée | Chiffre | Valeur pour nous |
|---|---|---|
| Fishbrain, 300 espèces, lieu choisi d'abord | « high 80s to low 90s » en moyenne (avant : fin des 70) ; « 99 % dans le top 5 » (page marketing) ([blog](https://fishbrain.com/blog/fishing-news/new-and-improved-fish-identification), [fiche](https://fishbrain.com/features/fish-identifier)) | Chiffres de l'éditeur, non vérifiables. Montre que le lieu aide beaucoup. |
| Photos de pêcheurs, 38 espèces, classifieur CLIP (2025/26) | 85 % en multi-classes, 96 % en 5 espèces à 5 exemples ([Fish and Fisheries](https://onlinelibrary.wiley.com/doi/10.1111/faf.70073)) | Le plus proche de notre cas. Ordre de grandeur pour 38 classes. |
| iNaturalist, modèle 2.12, tous groupes | 89,1 % moyenne ; 90 et plus en Europe ([iNaturalist](https://www.inaturalist.org/blog/91824)) | Des millions d'images : hors de notre portée. |
| iNat 2017, 5 000 espèces | 67 % top-1 ; nette perte sous 100 images par classe ([CVPR 2018](https://openaccess.thecvf.com/content_cvpr_2018/papers/Van_Horn_The_INaturalist_Species_CVPR_2018_paper.pdf)) | Justifie de viser 150 images ou plus par classe. |
| Poissons marins, 3 espèces, caméra fixe | 94 % ; les erreurs viennent des poissons partiels ([Allken 2018](http://courses.washington.edu/fish538/resources/Allken%20et%20al%202018.pdf)) | Confirme que le poisson partiel est le piège. |
| Jeux propres (Fish-Pak etc.) | 98 à 100 % | Fond neutre, labo : ne pas s'en servir. |

Gardon/brème/chevesne et fario/arc-en-ciel : je n'ai trouvé aucun chiffre publié par paire [?]. Hypothèse de travail (estimation, à tester) : fario contre arc-en-ciel facile (points et bande rose), trio de cyprinidés difficile, 20 à 35 % de confusions entre eux sur photos de prise. Un avis d'application, pas une mesure.

## 4. Protocole d'évaluation en une journée
1. **Jeu de test tenu à part.** Au moins 30 vraies photos par espèce (14 espèces = 420), prises par des pêcheurs : poisson mouillé, en main, de profil, partiel, flash, nuit. Jamais utilisées à l'entraînement. Découper par photographe ou par sortie, pas photo par photo : deux photos du même poisson, l'une en test, l'autre en entraînement, gonflent le score. Ajouter 50 photos « pas un poisson » (mains, leurre, bateau, paysage, tasse).
2. **Précision de lecture.** Avec 25 photos par classe, un score de 90 % a une marge d'environ plus ou moins 12 points (calcul : 1,96 fois racine de 0,9 x 0,1 / 25). Seuls les totaux (350 à 420 photos, environ plus ou moins 3 points) sont fiables. Les scores par espèce servent à trouver des trous, pas à certifier.
3. **Mesures.** Top-1, top-3, rappel par espèce, matrice de confusion sur les paires critiques, et part des « pas un poisson » correctement renvoyés vers la grille. Ajouter une classe « autre » à l'entraînement (300 photos hors poisson), sinon le modèle nomme toujours un poisson, comme l'IA d'Apple sur la tasse (`eval-apple.md`, R2).
4. **Seuil de confiance.** Faire varier le seuil de 0,3 à 0,9 sur le jeu de test. Choisir le plus bas pour lequel la proposition n°1 est juste dans 95 % des cas ou plus. Sous ce seuil, ou si « autre » gagne : la grille. Noter aussi la part de photos où l'IA parle encore (la couverture). La confiance de Create ML n'est pas calibrée : le seuil se mesure, il ne se devine pas.
5. **Dans Create ML, sans code.** Glisser le dossier d'entraînement dans Training Data et le dossier de test dans Testing Data, régler les augmentations (retournement, rotation, recadrage, exposition, flou), cliquer Train. L'onglet Evaluation donne la précision d'entraînement, de validation et de test, puis un tableau par classe (nombre d'images, précision, rappel) ([Apple](https://developer.apple.com/documentation/createml/creating-an-image-classifier-model)). Pas confirmé dans l'app : la matrice de confusion et le top-3 [?]. Repli : un script Swift de 30 lignes (boucle sur le dossier de test avec l'appel Vision du §1) qui sort top-1, top-3 et la confusion ; une session Claude Code l'écrit en 15 min.

## 5. Comparaison avec Foundation Models (entrée image)
| Critère | Create ML + Core ML | Foundation Models avec image |
|---|---|---|
| iPhone concernés | Tous les iPhone iOS 27 (iPhone 11 et plus) | Appareils Apple Intelligence seulement : iPhone 15 Pro et plus ([Apple](https://developer.apple.com/documentation/foundationmodels)) |
| Conditions en plus | Aucune | Région et langue prises en charge, Apple Intelligence activé, modèle téléchargé : sinon `deviceNotEligible`, `appleIntelligenceNotEnabled` ou `modelNotReady` ([Apple](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel)) |
| Spécialisé poisson | Oui, par construction | Non : modèle général, aucune mesure publiée sur les espèces proches [?] |
| Mesurable avant publication | Oui | Oui, mais il faut un iPhone éligible et le même jeu de test |
| Latence | Quelques dizaines de ms (estimation) [?] | Aucun chiffre image publié. Texte seul : environ 0,6 ms par jeton d'entrée et 30 jetons/s sur iPhone 15 Pro ([Apple ML](https://machinelearning.apple.com/research/introducing-apple-foundation-models)). Apple prévient que les grandes images coûtent plus de jetons et de latence ([WWDC26 session 241](https://developer.apple.com/videos/play/wwdc2026/241)). |
| Maturité | Stable depuis des années | `Attachment` iOS 27 : un dépôt de recherche signale, sur iPhone réel en bêta 5, que `Attachment(imageURL:)` peut interrompre l'app avant que Swift ne lève une erreur ([GitHub, 12/08/2026](https://github.com/sooyvilla/cupertino_fundations_models/blob/main/doc/ios-27-beta-5-foundation-models.md)). Corrigé en version finale ? [?] |
| Sortie contrôlée | Liste fixe de 14 + « autre » | `@Generable` ferme la liste, mais n'empêche pas une mauvaise réponse dans la liste |
| iPhone du relecteur d'Apple | Même comportement partout, vérifiable | Inconnu : modèle absent, non téléchargé ou désactivé ; on voit alors la grille [?] |

Sur l'iPhone du relecteur : l'état exact de son appareil est inconnu [?]. Avec Core ML, ce qu'on a testé est ce qu'il verra. Avec Foundation Models, il voit soit la grille, soit une IA que personne n'a notée.

## 6. Ce que font les apps existantes
| App | Identification | Avertissements et limites |
|---|---|---|
| Fishbrain | Photo, 300 espèces, on choisit d'abord le plan d'eau pour restreindre les espèces ; propose aussi les espèces voisines | Conditions : l'utilisateur est « fully responsible » de ses permis et autorisations ; clause de décharge de responsabilité large ([ToS](https://fishbrain.com/terms-of-service)) |
| FishVerify | Photo ou scan, eau douce et salée, règles par zone (États-Unis) | §13 « Regulation Disclaimer » : consulter les règlements officiels ; liens vers les autorités dans l'app. Conditions §5.2 : licence sur les photos des utilisateurs pour entraîner leur IA ([Terms](https://www.fishverify.com/terms-page)) |
| Picture Fish | Photo, plus de 2 500 espèces, surtout exotiques et aquarium | 4,3 sur 204 notes en France. Avis : confond les bonites. Réponse de l'éditeur : la précision dépend de l'angle et de la qualité ([App Store FR](https://apps.apple.com/fr/app/picture-fish-fish-identifier/id1474584436), Google Play) |
| HOOKfr | Pas de reconnaissance par photo visible : identification « par critères physiques », plus de 300 poissons, fiches avec législations, hors ligne, gratuit ([hookfr.com](https://hookfr.com/)) | Mentions légales non lues [?] |

HOOKfr, l'app française qui lie espèce et législation, n'a pas pris le risque de l'IA. Notre grille manuelle est ce même chemin ; l'IA est un confort ajouté par-dessus, jamais une condition.

## Recommandation
**Faire les deux, dans cet ordre : la grille manuelle est toujours le chemin de base ; un modèle Create ML devient l'aide principale s'il passe le test ; Foundation Models sort de la version de vendredi pour l'identification d'espèce.** Raison : Core ML marche sur tous les iPhone et sur celui du relecteur, et il se note avec un tableau. Foundation Models est limité aux appareils éligibles, plante peut-être (bêta) et reste sans mesure. L'option écartée la plus forte : garder Foundation Models comme aide principale parce qu'il n'y a rien à entraîner. Elle reste valable si on la passe sur le même jeu de test et qu'elle bat Create ML ; coût 1 h, sur un iPhone éligible.

**Pour Adem, la protection ne vient pas de la précision.** Elle vient du fait que l'IA propose, l'utilisateur confirme, la table sourcée décide (déjà dans `CLAUDE.md`). Ajouter : écran de confirmation avec le critère visuel qui distingue les paires (queue tachetée ou non, bouche, nageoire anale), bouton « Je ne sais pas » toujours visible, et pour toute paire dont les verdicts diffèrent, jamais de verdict avant le tap de confirmation.

**Plan, en heures de travail (estimation, 10 à 12 h pour 2 personnes, 5 à 6 h écoulées) :**
| Étape | Qui | Durée |
|---|---|---|
| 1. Script de téléchargement GBIF : 14 espèces, CC0 et CC-BY, hors jeu iNaturalist, Europe d'abord, manifeste des auteurs | Adem ou Titouan (Claude Code) | 1,5 à 2 h |
| 2. Tri à la main, un dossier par espèce, viser 150 ou plus de photos « poisson en prise », plus classe « autre » (300) | Sullyvan, sans code | 2 à 3 h |
| 3. Photos des 4 espèces rares et jeu de test de 30 par espèce (420) avec accord écrit des pêcheurs | Adem (réseau, clubs) | 2 à 3 h en parallèle |
| 4. Trois entraînements dans l'app Create ML (de base, avec augmentations, plus d'itérations) | Sullyvan : oui, une personne sans code peut le faire, c'est du glisser-déposer | 1 h |
| 5. Test, seuil, décision | Titouan (script top-3) | 1 h |
| 6. Intégration Core ML + Vision, écran de crédits, repli grille | Lot de l'IA photo | 1 à 2 h |

**Feu vert pour publier (test sur le jeu tenu à part, seuils proposés par moi, à valider par Adem) :**
`python3 scripts/evaluer.py` (à écrire à l'étape 5) doit afficher, sur les photos de test : top-3 global de 90 % ou plus ; top-1 global de 70 % ou plus ; au seuil choisi, 95 % de bonnes réponses n°1 avec au moins 50 % de photos couvertes ; au moins 90 % des photos « pas un poisson » renvoyées vers la grille. Si un seul seuil échoue : l'IA reste désactivée pour les espèces concernées et la grille prend le relais. **Point d'arrêt à mi-parcours : après l'étape 2, moins de 100 photos propres par classe pour plus de 4 espèces = on arrête l'entraînement et on publie grille seule, ce qui est légalement le plus sûr et reste publiable.**

Questions (réponse par défaut si pas de retour : 1.a / 2.a / 3.a) :
1. Périmètre de l'IA photo vendredi. a) Hybride : grille toujours, Create ML si le test passe, Foundation Models retiré (ma reco). b) Grille seule, aucune IA. c) Foundation Models seul comme prévu dans `architecture.md`.
2. Photos de test (420 vraies photos de pêcheurs avec accord). a) Adem les rassemble via ses contacts et clubs. b) L'équipe se les partage. c) On réduit le test à 10 espèces faciles et les 4 autres restent en grille.
3. Qui entraîne dans l'app Create ML. a) Sullyvan. b) Titouan. c) Adem.

## Mise à jour du 15 oct. (question d'Adem : l'IA native d'Apple, les iPhone plus anciens, la taille et le poids)
- L'entrée image des Foundation Models d'iOS 27 n'existe que sur les appareils Apple Intelligence ; contexte de 4 000 jetons sur l'iPhone, une grande image en consomme plus et ralentit ; aucune mesure de précision sur des espèces. Dans l'exemple d'Apple sur les plantes, le modèle appelle un outil fondé sur Vision quand il « ne peut pas identifier » lui-même ([résumé de la session WWDC26](https://blakecrosley.com/blog/foundation-models-image-input-ios-27), lu le 15/10/2026, source secondaire [?]).
- iPhone 15 simple : pas d'Apple Intelligence ; iPhone 15 Pro et plus seulement (§5).
- « Recherche visuelle » d'Apple (VisionKit) : l'app peut ouvrir la fiche système, mais ne peut pas lire le nom trouvé. Réponse d'un ingénieur Apple : « There is no API to access this information » ([forum Apple](https://developer.apple.com/forums/thread/770524)).
- Taille : aucune IA ne mesure une longueur sur une photo sans repère (estimation, aucun texte lu ne prétend le contraire). Voies : curseur, mètre visible dans la photo et lu par l'iPhone (Vision lit le texte sur tous les iPhone), mesure en réalité augmentée (ARKit, plus précise avec le LiDAR des modèles Pro [?]).
- Poids : formule longueur-poids par espèce (poids = a × longueur^b). Coefficients publiés pour 40 espèces d'eau douce de Flandre ([Verreycken et al. 2011, J. Appl. Ichthyol.](https://fishbase.se/references/FBRefSummary.php?ID=88166)) ; ne pas recopier FishBase, dont les données sont sous licence non commerciale [?]. Écart attendu de 10 à 20 % (estimation) : l'écran écrit « poids estimé ».
