# Faisabilité technique : app de pêche + Pokédex de prises

Décision débloquée : quoi mettre dans la v1 de vendredi 15 h, et quoi couper. Lu le 12/10/2026. [?] = non vérifié. Statuts : DISPO / MAIN (à saisir à la main) / BLOQUANT. Aucun outil de plateforme interdit utilisé ; WebFetch/WebSearch ont répondu, sauf la page des quotas CloudKit (erreur) ; Parallel_Search non essayé.

## Version simple
L'iPhone sait déjà détourer un sujet, mesurer à la caméra et dessiner une carte. Ce qu'il ne sait pas faire de façon prouvée : dire « brochet » ou « sandre » à coup sûr depuis une photo. Donc l'IA propose, l'humain confirme. Le Pokédex public est le morceau risqué : il impose la modération (règle 1.2). Pour vendredi : Pokédex en local + partage en image, public seulement si la modération tient.

## 1. Identification d'espèce par photo
| Option | Statut | Ce qui est établi |
|---|---|---|
| Foundation Models, entrée image (iOS 27) | DISPO sous réserve | L'image s'insère dans le prompt (`Attachment(UIImage)`), toute taille, plus c'est grand plus c'est lent : https://developer.apple.com/videos/play/wwdc2026/241/ . Réservé aux appareils Apple Intelligence : https://blakecrosley.com/zh-Hans/blog/foundation-models-image-input-ios-27 (source secondaire). Précision sur poissons d'eau douce : aucune mesure publiée [?]. Contexte on-device 4K selon cette source secondaire (la session parle de 8192 dans son exemple) : à lire au runtime. |
| Vision `VNClassifyImageRequest` | DISPO, mais pas fait pour ça | Classifie avec la taxonomie intégrée d'Apple (iOS 13+) : https://developer.apple.com/documentation/vision/vnclassifyimagerequest.md . Que la liste contienne « poisson » oui, « brochet » vs « sandre » : à tester avec `supportedIdentifiers()` [?]. |
| Modèle Core ML maison (Create ML) | DISPO en 1 jour si on a les photos | Glisser des dossiers d'images par espèce, 10 images minimum par classe, 25+ pour un jeu de test, ça sort un modèle importable dans Xcode : https://developer.apple.com/documentation/createml/creating-an-image-classifier-model.md . Le goulot est le jeu de photos, pas l'outil. |
| Fishial.ai | BLOQUANT [?] | Je n'ai trouvé aucune API ni licence de données ; un test de 2022 le juge « total failure » (tout mal identifié) : https://reefbuilders.com/2022/10/14/fishial-project-uses-artificial-intelligence-to-identify-fish . Sans doute amélioré depuis [?] mais pas utilisable sans accord. |
| iNaturalist / Seek | BLOQUANT | « Pas d'API publique pour le modèle de vision » (réponse de 2020, à confirmer) : https://forum.inaturalist.org/t/computer-vision-suggestion-api/12336 . Les photos d'observations existent en données ouvertes (licences variables par photo [?]) pour entraîner, pas le modèle. |
| Jeux ouverts poissons | Pas adaptés tels quels | Fish Net : 86 029 images mais prises par caméras de bateaux de pêche, 29 classes thons et autres ; 41,5 % de précision sur les non-thons : https://arxiv.org/pdf/2106.09178 (licence non indiquée). Montre surtout que le fin est dur. Roboflow Universe propose des jeux de poissons, qualité et licences à vérifier un par un [?] : https://universe.roboflow.com/learn-7i9af/fishidentify |

**Recommandation** : liste fermée de 8 à 12 espèces d'eau douce françaises (brochet, sandre, perche, black-bass, truite fario, carpe commune, silure, brème, gardon, barbeau…). Foundation Models reçoit la photo ET la liste fermée ; l'app affiche les 3 meilleures propositions, **l'utilisateur confirme**. Repli sans IA : liste des 3 espèces les plus fréquentes dans le département. Si le test à 20 photos (réelles, de pêcheurs, prises par les testeurs) donne moins de ~70 % de bonne espèce dans le top 3 [seuil à fixer par vous], on ne vend pas « l'IA reconnaît le poisson » ; on vend « l'IA propose, tu valides ». Le test ne coûte rien : le modèle est sur l'appareil.
Point d'étape à ne pas rater : si un testeur ne peut pas obtenir 20 photos de poissons réels d'ici mardi soir, la précision restera non mesurée [?].

## 2. Mesure de taille
| Méthode | Statut | Fiabilité |
|---|---|---|
| Saisie manuelle (curseur en cm) | DISPO | Fiable, c'est la base. Le verdict légal en dépend. |
| Objet de référence (carte bancaire à côté du poisson) | À construire | Nécessite détection du poisson + de l'objet : risque de bricolage en 1 semaine [?]. Précision non mesurée. |
| LiDAR / ARKit | DISPO sur iPhone Pro seulement [?] | Mesure de distance entre 2 points tapés par l'utilisateur, via raycast ARKit ; réservé aux modèles avec LiDAR. Un poisson mouillé et qui bouge se mesure mal ; précision annoncée par Apple non vérifiée [?]. Fishing Calendar l'annonce déjà : voir concurrence-peche.md. |
Recommandation : v1 = curseur manuel + règle posée sur le dessin du poisson (planche à mesurer à l'écran). LiDAR = idéal, à tenter samedi seulement si le reste est vert. Règle de sécurité : taille mesurée = indication, jamais preuve devant un garde-pêche.

## 3. La carte « Pokémon »
| Brique | Statut | Détail |
|---|---|---|
| Détourage du poisson/personne | DISPO | VisionKit « lift subject » : `ImageAnalyzer` + `ImageAnalysisInteraction.subjects`, depuis iOS 16 (de mémoire ; page Apple non lisible sans JS) : https://developer.apple.com/documentation/visionkit/imageanalysisinteraction [?]. Alternative Vision : `VNGenerateForegroundInstanceMaskRequest` [?]. Marche mal sur poisson tenu à la main devant un ciel gris ? À tester. |
| Mise en page de la carte | DISPO | SwiftUI, `ImageRenderer` pour exporter en PNG [?]. C'est le plus facile : 1 vue, 3 gabarits de rareté. |
| Statistiques | MAIN / calculées | Taille, poids saisi, date, lune, météo (WeatherKit). Pas d'IA. |
| Rareté | MAIN pour vendredi | Idéal = fréquence réelle par département via Hub'Eau poissons (opérations de pêche électrique depuis 50 ans, JSON/GeoJSON/CSV, Licence Ouverte 2.0) : https://www.data.gouv.fr/dataservices/hubeau-etat-piscicole-des-rivieres . Vendredi : table de rareté fixe par espèce (5 niveaux) écrite à la main, Hub'Eau en v1.1. La rareté réelle est le différenciateur de 4-pistes-produit.md, mais coûte un pipeline de données. |
| Texte de carte (« flavor text ») | DISPO | Foundation Models génère 1 phrase sur l'espèce, hors ligne, gratuit. Texte purement décoratif : à ne jamais utiliser pour une règle (règle de sécurité du cadrage). Test critique « si on retire l'IA » : la carte marche sans, donc l'IA doit servir à l'identification, pas au texte. |
| Image Playground | Optionnel | Pas nécessaire ; l'API ImageCreator est annoncée dépréciée en iOS 27 [?] : https://www.blakecrosley.com/writing . Ne pas en dépendre. |
| Partage en image | DISPO | `ShareLink` avec l'image rendue. |

## 4. Pokédex public : backend, modération, comptes
| Option | Coût | Verdict |
|---|---|---|
| CloudKit base publique | Pas de serveur, pas de facture pour vous ; quotas par utilisateur actif (page quotas non lue, erreur) [?] | Écrire exige un compte iCloud connecté : https://developer.apple.com/documentation/cloudkit/designing-and-creating-a-cloudkit-database.md . Schéma de production : ajouts seulement, pas de suppression (même page). Pas de tableau de modération côté serveur à part la console CloudKit. Recommandé si on garde le public. |
| Firebase (Spark) | Gratuit au départ [?] ; non vérifié ici | Compte Google, SDK à ajouter, règles de sécurité à écrire. |
| Supabase | Gratuit : base 500 Mo, stockage 1 Go, 50 000 MAU ; **le projet se met en pause après une semaine sans activité** ; Pro 25 $/mois : https://www.jetadmin.io/blog/supabase-pricing-2026-guide-to-plans-limits-and-real-world-costs/ | Le plus souple (SQL, modération par requête), mais un serveur de plus à tenir. Pause = risque pour une démo. |

**Flou du spot** : on ne publie jamais les coordonnées exactes. Stocker uniquement le département + un nom libre ou un alias ; si on garde la position, l'arrondir à ~10 km côté téléphone avant l'envoi. Ainsi un fuite de base ne révèle aucun coin.

**Modération (obligatoire)** : la règle 1.2 exige filtre du contenu, signalement avec réponse rapide, blocage d'utilisateurs, contact publié : https://developer.apple.com/app-store/review/guidelines/ . Le « 24 h » que vous citez n'est pas dans le texte que j'ai lu (« timely responses ») [?]. Vérifié dans la page : 4 exigences. Minimum viable : bouton « Signaler » sur chaque carte, « Bloquer cet utilisateur », filtre de texte sur pseudo/alias, e-mail de contact dans l'app et dans la fiche, **photos : file d'attente de validation par un des trois avant publication publique** (c'est le plus sûr). Humain à astreinte jusqu'à la review.
**Comptes** : si compte il y a, suppression du compte dans l'app obligatoire (5.1.1(v)) ; sans compte, un Pokédex public n'est pas possible. Sign in with Apple n'est imposé que si vous proposez un autre login tiers (4.8) ; seul, il suffit et c'est le plus simple (source ci-dessus).
**Plan** : v1 = Pokédex **local** (SwiftData) + partage en image. Public = bascule « publier cette carte » derrière Sign in with Apple + CloudKit + modération. Si mardi/mercredi la modération n'est pas prête, le public est coupé sans toucher au reste.

## 5. Carte « où pêcher »
- MapKit sait décoder du GeoJSON (`MKGeoJSONDecoder`, iOS 13+) : https://developer.apple.com/documentation/mapkit/mkgeojsondecoder.md . DISPO.
- Couches hors ligne : fichier GeoJSON embarqué dans l'app (départements, catégories 1re/2e) : DISPO si on obtient le fichier. **Données de classement des cours d'eau : non trouvées en ouvert** [?] ; Géopêche est fermé (voir concurrence-peche.md). BLOQUANT pour la carte nationale ; MAIN pour 3-5 départements.
- Point-dans-polygone : pas de fonction clé en main dans MapKit [?] ; 30 lignes de code (lancer de rayon) ou `MKPolygon` + `MKPolygonRenderer` pour l'affichage. DISPO, testable avec 5 points connus.
- Position : permission « quand l'app est active » seulement, motif précis (5.1.5 : n'utiliser la localisation que si utile) ; nécessaire ici.
- Les règles (taille légale, ouverture) restent une table saisie et sourcée ; l'IA explique, ne décide pas.

## 6. Reste des briques
| Brique | Statut v1 |
|---|---|
| App Intents / Siri | « Mon carnet » ou « Ai-je le droit ici ? » : 1 intent simple DISPO, retour textuel. v1 si le temps. |
| Widget | Un widget « dernière carte / indice du jour » : possible, non indispensable. Coupé de la v1 minimale. |
| Live Activity | Compte à rebours d'ouverture : joli, hors cœur. Coupé. |
| Liquid Glass | Gratuit en compilant avec le SDK récent et des composants système [?] ; ne pas dessiner à la main. |
| StoreKit 2 + paywall | MWM fournit un fichier StoreKit de test (cadrage). Paywall après la première carte créée ; achat clair, résiliation simple (déception des concurrents : voir concurrence-peche.md). 3.1.2 : abonnement ≥ 7 jours, valeur continue. Prix/produits : à vous de trancher. |
| SDK Spark Flash (MWM) | Fourni par le kit ; contenu et API non vus par moi [?]. À intégrer le mardi, avec l'aide du MCP MWM. |

## 7. Plan mardi → vendredi 15 h (3 non-développeurs, Claude Code + Xcode)
Règle d'équipe : un lot = un dossier = une personne ; pas de fusion sans build vert.
- **Mardi** : projet Xcode dans le compte MWM, Spark Flash + StoreKit branchés, écran vide qui se lance sur l'iPhone de test. Test à 20 photos d'espèces (Foundation Models + liste fermée). Données de règles : 3 départements saisis à la main, source citée. Critère : l'app s'installe sur l'iPhone.
- **Mercredi** : ① photo → 3 propositions → confirmation → fiche prise dans le carnet (SwiftData) ; ② règle « ai-je le droit ici ? » (position → département → verdict) ; ③ carte SwiftUI + détourage + partage image. Critère : un parcours héros complet de 30 s.
- **Jeudi** : paywall + achat de test ; modération et Pokédex public (CloudKit) OU décision de le couper ; icône, captures, fiche App Store, politique de confidentialité, contact. Soumission jeudi soir.
- **Vendredi matin** : correctifs de review, vérification sur un vrai iPhone. Rien de nouveau.

**Dans la v1** : carnet avec photo, espèce confirmée, mesure manuelle, règle de 3 départements, carte partageable, Pokédex local, paywall.
**Coupé** : LiDAR, rareté Hub'Eau, widgets, Live Activity, Siri (si en retard), carte nationale, Pokédex public (si modération non prête).
**Risques de review** (délai : Apple annonce 90 % des soumissions revues en moins de 24 h : https://www.choicely.com/tutorials/how-long-does-app-review-take ; mais un rejet coûte un tour de plus, donc soumettre jeudi) :
- 2.1 complétude (plus de 40 % des problèmes non résolus selon la même page) : crash, lien mort, contenu factice, **compte de démo** si login.
- 4.2 fonctionnalité minimale : éviter une coquille ; le carnet + règle + carte doivent marcher hors ligne.
- 1.2 contenu utilisateur : filtre, signalement, blocage, contact (voir 4).
- 5.1 confidentialité/localisation : lien de politique, motifs de permission clairs, suppression de compte, ne pas exiger la position pour payer.
- 3.1 achats : prix clair, restauration des achats, pas de déverrouillage maison.

## Architecture minimale (10 lignes)
1. App SwiftUI iOS 27, une cible, données locales SwiftData (carnet, cartes).
2. `SpeciesService` : photo + liste fermée → Foundation Models → 3 propositions ; repli départemental.
3. `RulesService` : table JSON embarquée (département → catégorie, ouvertures, tailles, quotas, source).
4. `LocationService` : position → département par point-dans-polygone sur GeoJSON embarqué.
5. `CardService` : détourage VisionKit + vue SwiftUI + `ImageRenderer` → PNG ; texte de carte par Foundation Models.
6. `Rarity` : table fixe par espèce (Hub'Eau en v1.1).
7. `Store` : StoreKit 2 + Spark Flash MWM, paywall après la première carte.
8. `PublicDex` (optionnel) : CloudKit base publique, Sign in with Apple, file de validation, signaler/bloquer.
9. Zone floue : département + alias seulement, jamais de coordonnées exactes publiées.
10. Aucun serveur à nous ; l'IA tourne sur l'appareil, donc pas de coût par requête ni de clé.
