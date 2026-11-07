# FishMe États-Unis : espèces, photos, modèles, réentraînement (7 nov. 2026)

Décision débloquée : choisir la liste d'espèces américaines à entraîner, la source de photos par licence, et si le modèle américain est un second modèle (région) ou un modèle mondial.

Convention : `[?]` = non vérifié ; aucun chiffre inventé ; chaque source a son URL. Base : sections 1 à 3 de `reports/etat/reconnaissance.md` (DINOv2-small + régression logistique int8, 55 classes, ~22 Mo, top-1 72,8 %, prises de pêcheurs 82,5 %, photos GBIF de terrain 47,9 %).

## 1. Liste proposée : 78 espèces ou hybrides en 66 lignes

Noms latins et statut (natif/introduit) : connaissance générale d'ichtyologie, à faire relire par une source de référence (AFS / USGS NAS) avant le jeu d'étiquettes final [?]. Colonne « EU » : lien avec une classe du modèle actuel (= même espèce ; ~ = espèce proche ; - = rien).

### Centrarchidés (black bass, sunfish, crappie)
| Nom commun | Latin | Statut / région | Confusions | EU |
|---|---|---|---|---|
| Largemouth bass | Micropterus salmoides (inclut Florida bass M. floridanus [?]) | Natif Est/Sud-Est, introduit partout | spotted bass, smallmouth | = black-bass (introduit en Europe) |
| Smallmouth bass | Micropterus dolomieu | Natif Grands Lacs/Est, introduit Ouest | largemouth, spotted, rock bass | ~ black-bass |
| Spotted bass (Kentucky) | Micropterus punctulatus | Natif bassin Mississippi/Sud | largemouth, redeye | - |
| Redeye / Guadalupe / Suwannee bass | M. coosae, M. treculii, M. notius | Natifs Sud-Est/Texas | spotted bass | - |
| Bluegill | Lepomis macrochirus | Natif Est, introduit partout | pumpkinseed, redear, green sunfish | ~ perche-soleil |
| Pumpkinseed | Lepomis gibbosus | Natif Nord-Est | bluegill, redbreast | = perche-soleil |
| Redear sunfish (shellcracker) | Lepomis microlophus | Natif Sud-Est, introduit | bluegill, pumpkinseed | - |
| Green sunfish | Lepomis cyanellus | Natif Centre, introduit | warmouth, bluegill | - |
| Longear sunfish | Lepomis megalotis | Natif Centre/Sud | green, bluegill | - |
| Warmouth | Lepomis gulosus | Natif Sud-Est | green sunfish, rock bass | - |
| Redbreast sunfish | Lepomis auritus | Natif côte Atlantique | pumpkinseed, longear | - |
| Rock bass | Ambloplites rupestris | Natif Est/Nord | warmouth, smallmouth jeune | - |
| White crappie | Pomoxis annularis | Natif Centre/Est | black crappie | - |
| Black crappie | Pomoxis nigromaculatus | Natif Est/Centre | white crappie | - |

### Moronidés, percidés
| Nom commun | Latin | Statut / région | Confusions | EU |
|---|---|---|---|---|
| Striped bass (rockfish) | Morone saxatilis | Natif Atlantique (anadrome), introduit lacs/Ouest | white bass, wiper | ~ bar (le bar de l'app est le bar européen, autre genre) |
| White bass | Morone chrysops | Natif Centre | striped, yellow bass | - |
| Wiper (hybride striped x white) | M. saxatilis x M. chrysops | Empoissonné | striped, white bass | - |
| Yellow bass | Morone mississippiensis | Natif Mississippi | white bass | - |
| White perch | Morone americana | Natif Atlantique, introduit Grands Lacs | white bass | - |
| Walleye | Sander vitreus | Natif Nord/Centre | sauger, saugeye | ~ sandre (genre commun, espèce différente) |
| Sauger | Sander canadensis | Natif Nord/Centre | walleye | ~ sandre |
| Saugeye (hybride) | S. vitreus x S. canadensis | Empoissonné | walleye, sauger | - |
| Yellow perch | Perca flavescens | Natif Nord/Est | walleye jeune | ~ perche (P. fluviatilis, espèce soeur) |

### Ictaluridés, brochets
| Nom commun | Latin | Statut / région | Confusions | EU |
|---|---|---|---|---|
| Channel catfish | Ictalurus punctatus | Natif Centre/Est, introduit | blue catfish, white catfish | ~ poisson-chat [?] |
| Blue catfish | Ictalurus furcatus | Natif Sud/Mississippi, introduit Atlantique | channel catfish | - |
| Flathead catfish | Pylodictis olivaris | Natif Centre, introduit Est | bullheads | - |
| White catfish | Ameiurus catus | Natif Atlantique | channel | - |
| Black / yellow / brown bullhead | A. melas, A. natalis, A. nebulosus | Natifs Est/Centre | entre eux, madtoms | = poisson-chat (bullheads européens) [?] |
| Northern pike | Esox lucius | Natif Nord (holarctique) | muskie, pickerel | = brochet |
| Muskellunge | Esox masquinongy | Natif Grands Lacs/Nord-Est | pike, tiger muskie | - |
| Tiger muskie (hybride) | E. masquinongy x E. lucius | Empoissonné | muskie, pike | - |
| Chain pickerel | Esox niger | Natif Est/Sud-Est | grass pickerel, pike | - |
| Grass / redfin pickerel | Esox americanus | Natif Est | chain pickerel | - |

### Salmonidés
| Nom commun | Latin | Statut / région | Confusions | EU |
|---|---|---|---|---|
| Rainbow trout / steelhead | Oncorhynchus mykiss | Natif côte Pacifique, introduit partout | cutthroat, brown, coho | = truite-arc-en-ciel |
| Brown trout | Salmo trutta | Introduit (d'Europe) | brook, Atlantic salmon | = truite-commune |
| Brook trout | Salvelinus fontinalis | Natif Est/Nord | lake trout, bull trout | = omble-fontaine |
| Cutthroat trout | Oncorhynchus clarkii | Natif Ouest (sous-espèces) | rainbow | - |
| Lake trout | Salvelinus namaycush | Natif Nord/Grands Lacs | brook, bull trout | = cristivomer |
| Bull trout / Dolly Varden | S. confluentus / S. malma | Natifs Nord-Ouest/Alaska | brook, lake trout | ~ omble-chevalier |
| Arctic char | Salvelinus alpinus | Natif Alaska/Maine | lake trout | = omble-chevalier |
| Chinook (king) | Oncorhynchus tshawytscha | Natif Pacifique, Grands Lacs introduit | coho | - |
| Coho (silver) | Oncorhynchus kisutch | Natif Pacifique, Grands Lacs introduit | chinook, steelhead | - |
| Sockeye / kokanee | Oncorhynchus nerka | Natif Pacifique/Nord-Ouest | pink, coho | - |
| Pink salmon (humpy) | Oncorhynchus gorbuscha | Natif Pacifique, Grands Lacs | chum | - |
| Atlantic salmon | Salmo salar | Natif Nord-Est (dont landlocked) | brown trout | = saumon |
| Arctic grayling | Thymallus arcticus | Natif Alaska/Montana | whitefish | ~ ombre |
| Mountain whitefish | Prosopium williamsoni | Natif Ouest | cisco | ~ coregones |
| Cisco / lake whitefish | Coregonus artedi / C. clupeaformis | Natifs Grands Lacs | entre eux | ~ coregones |

### Cyprinidés, catostomidés et autres
| Nom commun | Latin | Statut / région | Confusions | EU |
|---|---|---|---|---|
| Common carp | Cyprinus carpio | Introduit | buffalo, goldfish | = carpe-commune |
| Grass carp | Ctenopharyngodon idella | Introduit | common carp | = carpe-amour |
| Bighead carp | Hypophthalmichthys nobilis | Introduit (envahissant) | silver carp | = carpe-grosse-tete |
| Silver carp | Hypophthalmichthys molitrix | Introduit (envahissant) | bighead | = carpe-argentee |
| Goldfish | Carassius auratus | Introduit | common carp | = carassin / poisson rouge (grille) |
| Bigmouth / smallmouth buffalo | Ictiobus cyprinellus / I. bubalus | Natifs Mississippi | carp, quillback | ~ carpe (confusion fréquente) |
| White sucker | Catostomus commersonii | Natif Nord/Est | redhorse | - |
| Redhorse (groupe) | Moxostoma spp. | Natifs Est/Centre | white sucker | - |
| Freshwater drum | Aplodinotus grunniens | Natif Centre/Est | - | - |
| Longnose gar | Lepisosteus osseus | Natif Est/Centre | spotted, shortnose | - |
| Spotted gar | Lepisosteus oculatus | Natif Sud/Centre | longnose | - |
| Alligator gar | Atractosteus spatula | Natif Sud | longnose | - |
| Bowfin | Amia calva | Natif Est/Centre | snakehead (envahissant) | - |
| Northern snakehead | Channa argus | Introduit (Est) | bowfin | - |
| Paddlefish | Polyodon spathula | Natif Mississippi | - | - |
| Lake sturgeon | Acipenser fulvescens | Natif Grands Lacs/Mississippi | shovelnose, white | ~ esturgeon |
| Shovelnose sturgeon | Scaphirhynchus platorynchus | Natif Mississippi/Missouri | pallid | ~ esturgeon |
| White sturgeon | Acipenser transmontanus | Natif Pacifique | green sturgeon | ~ esturgeon |
| American shad | Alosa sapidissima | Natif Atlantique, introduit Pacifique | - | ~ grande-alose |
| American eel | Anguilla rostrata | Natif Atlantique | - | ~ anguille |
| Burbot | Lota lota | Natif Nord (holarctique) | - | = lotte |
| Blue tilapia | Oreochromis aureus | Introduit Sud | - | - |
| Peacock bass | Cichla ocellaris | Introduit Floride | - | - |

Comptage : 78 espèces ou hybrides (14 centrarchidés + 11 moronidés/percidés + 12 silures/brochets + 17 salmonidés + 24 divers, selon la façon de compter les groupes redhorse et bullheads) [?]. Noms latins, statuts et régions viennent de la connaissance générale, non d'une source citée : à faire relire (American Fisheries Society, USGS NAS) avant d'écrire les étiquettes [?]. Taxonomie à trancher avant l'entraînement : iNaturalist a scindé le largemouth bass (Micropterus nigricans / salmoides / floridanus), ce qui change les comptes ci-dessous.

Recouvrement avec les 55 classes actuelles (colonne EU) :
- Même espèce, classe existante : carpes commune, amour, argentée, grosse tête ; brochet ; truite arc-en-ciel ; truite commune ; omble de fontaine ; cristivomer ; saumon ; perche-soleil ; lotte ; omble chevalier (13 classes).
- Espèce proche mais différente (le modèle européen ne suffit pas) : perche, sandre/walleye, black-bass, anguille, esturgeon, ombre, coregones, alose.
- Rien : bluegill et la plupart des sunfish, crappies, catfish américains, gars, bowfin, paddlefish, muskie, striped/white bass.
- Mesures européennes utiles (`reconnaissance.md`) : black-bass 87,6 %, perche-soleil 87,8 %, sandre 88,1 %, esturgeon 98,6 %, brochet 77,1 %, truite arc-en-ciel 62,8 %, omble fontaine 63,2 %, carpe commune 71,9 %.
- Confusions probables aux États-Unis, par analogie avec l'Europe (truite/saumon/arc-en-ciel y étaient déjà confondus) : salmonidés entre eux, sunfish entre eux, crappie blanc/noir, striped/white/yellow bass, gars entre eux, bowfin/snakehead [hypothèse, à mesurer].

## 2. Jeux de photos

### 2.1 iNaturalist (source principale)
- Données : bucket public `inaturalist-open-data` (us-east-1), lisible sans compte (`--no-sign-request`), photos en `photos/<id>/medium.<ext>`, métadonnées (observations, photos, taxons, observateurs) mises à jour chaque mois ; chaque photo porte sa licence (CC ou CC0), l'attribution se construit avec photographe + licence ; certaines lignes pointent vers des photos supprimées. Citation demandée par le registre. https://registry.opendata.aws/inaturalist-open-data et https://github.com/J87/inaturalist-open-data
- Licence par défaut d'un contenu : CC BY-NC ; l'observateur la change photo par photo. https://help.inaturalist.org/en/support/solutions/articles/151000173511
- Entraînement : les CGU interdiraient l'entraînement d'IA à des fins commerciales avec des données iNaturalist (citation de forum, CGU non lues : la page renvoie 403) [?] ; lecture d'un utilisateur : cette clause vise l'accès par le site/l'API, et le bucket serait régi par la seule licence des photos [?] ; aucune réponse du personnel dans le fil. https://forum.inaturalist.org/t/can-i-use-inaturalist-aws-open-data-to-train-commercial-ai-model/77663 et https://forum.inaturalist.org/t/use-of-inaturalist-data-to-train-ai-computer-vision-outside-the-inaturalist-platform/45139
- Règle pour FishMe : prendre par le bucket (pas l'API), garder CC0 et CC BY pour le noyau d'entraînement, exclure ND, ne pas lancer de requêtes en masse sur l'API, écrire à help@inaturalist.org pour demander la position du site (adresse donnée par le registre).
- Volume mesuré le 7 nov. (API publique, observations de qualité « research », lieu = États-Unis, `place_id=1` [?], lues via un résumeur, donc à revérifier ; une observation peut avoir plusieurs photos ou aucune photo de poisson en main) :

| Espèce | Obs. toutes licences | Obs. CC0 + CC BY | Part |
|---|--:|--:|--:|
| Bluegill | 60 358 | 4 695 | 7,8 % |
| Largemouth bass (entrée « nigricans ») | 35 303 | 2 212 | 6,3 % |
| Rainbow trout | 17 683 | 914 | 5,2 % |
| Smallmouth bass | 13 963 | 822 | 5,9 % |
| Common carp | 12 910 | 1 174 | 9,1 % |
| Channel catfish | 10 496 | 730 | 7,0 % |
| Brook trout | 9 353 | 440 | 4,7 % |
| Black crappie | 8 737 | 441 | 5,0 % |
| Yellow perch | 7 516 | 475 | 6,3 % |
| Brown trout | 7 384 | 377 | 5,1 % |
| Northern pike | 3 462 | 225 | 6,5 % |
| Walleye | 2 549 | 245 | 9,6 % |
| Flathead catfish | 1 702 | 138 | 8,1 % |
| Bowfin | 1 015 | 51 | 5,0 % |
| Lake trout | 759 | 45 | 5,9 % |

Lecture : avec seulement CC0 + CC BY, il reste environ 5 à 10 % des observations, soit des centaines par espèce courante et moins de 100 pour les rares (lake trout 45, bowfin 51). Les 6 espèces de la démo (§5) dépassent 200 observations chacune. Le recensement complet des 78 espèces reste à faire avec le même script.
- Biais : les photos iNaturalist sont des photos de terrain (poissons dans l'eau, de loin, morts, sur la berge) ; le jeu « photos de terrain GBIF » donnait 47,9 % de top-1 contre 82,5 % sur les prises de pêcheurs (`reconnaissance.md`). Prévoir une baisse du même ordre si on teste sur iNaturalist et un décalage entre test iNaturalist et photos réelles de pêcheurs.

### 2.2 Autres sources
| Source | Licence / règle | Usage pour FishMe | URL |
|---|---|---|---|
| GBIF | Politique de 2014 : CC0, CC BY, CC BY-NC pour les jeux ; chaque média peut avoir sa licence ; citation par DOI de téléchargement | Filtrer licence + image ; recouvre iNaturalist (dédupliquer par identifiant d'observation [?]) | https://www.gbif.org/citation-guidelines |
| Wikimedia Commons | Licence par fichier (la catégorie « Fish of the United States » compte 72 pages, copie à jour non garantie) ; CC BY-SA impose le partage à l'identique, effet sur un modèle non tranché [?] | Compléter les raretés ; publication seulement si CC0/CC BY/domaine public | https://wiki.riteme.site/wiki/Category:Fish_of_the_United_States |
| USFWS National Digital Library | Images du domaine public (employés, ou photographes ayant signé une cession) ; une photo marquée protégée exige l'accord du photographe | Poissons posés, publiable | https://www.fws.gov/program/national-conservation-training-center/usfws-conservation-library |
| USGS, images annotées (7 espèces : lake trout, largemouth, smallmouth, brook, rainbow, walleye, northern pike) | CC0 1.0 ; mais photos « compilées d'Anglers Atlas », donc droits d'origine à vérifier [?] ; nombre d'images non lu | Prises de pêcheurs, utile pour le test ; DOI 10.5066/P9NMVL2Q | https://www.usgs.gov/data/annotated-fish-imagery-data-individual-and-species-recognition-deep-learning |
| Photos d'États | Pas de licence générale : le Maine range des photos historiques avec des mentions par fichier, la Californie ne régit que les photos reçues ; Minnesota et Texas non vérifiés [?] | Écrire à chaque État si besoin ; ne rien aspirer | https://digitalmaine.com/ifw_photos/3321 ; https://wildlife.ca.gov/Photo-Submissions/Terms-and-Conditions |
| Fish-Vista (Imageomics) | Licence par image héritée de Fish-AIR ; sur un aperçu de 96 lignes, 53 CC BY-NC, 24 CC0, 6 CC BY, plus des CC BY-NC-ND/SA ; nombre d'images non lu | Photos de musée sur fond uni, peu proches d'un pêcheur ; seulement CC0/CC BY | https://huggingface.co/datasets/imageomics/fish-vista |
| FishNet (Khan, ICCV 2023) | 94 532 images, 17 357 espèces ; licence non lue [?] | Trop large (mer), peu d'espèces pêchées | https://openaccess.thecvf.com/content/ICCV2023/papers/Khan_FishNet_A_Large-scale_Dataset_and_Benchmark_for_Fish_Recognition_Detection_ICCV_2023_paper.pdf |
| Fishnet Open Images (bateaux de pêche) | Licence non lue [?] | Hors sujet | https://deepai.org/publication/the-fishnet-open-images-database-a-dataset-for-fish-detection-and-fine-grained-categorization-in-fisheries |
| Fish4Knowledge | 27 230 images, 23 espèces de récif taïwanais ; CC BY 4.0 seulement sur une copie Roboflow | Hors sujet (eau douce US) | https://universe.roboflow.com/trucho/fish4knowledge-dataset-bfnad/dataset/ |
| FishBase | Photos protégées, licence par photo | Ne pas aspirer | https://fishbase.org/photos/ThumbnailsSummary.php?id=2969 |

### 2.3 Entraînement ET publication
- Publication (cartes, fiche App Store, crédits) : seulement domaine public, CC0, CC BY (attribution dans l'app). CC BY-NC exclu : l'app est vendue par abonnement. CC BY-SA et ND exclus.
- Entraînement seul : la décision d'Adem du 15 oct. (photos non libres permises) a été prise pour la France, avant la contrainte des CGU iNaturalist ; recommandation : noyau CC0 + CC BY, puis CC BY-NC seulement après un avis écrit d'Adem, car le droit américain sur l'entraînement n'est pas tranché (un contributeur de forum le dit aussi) [?].
- Photos de pêcheurs : le jeu qui ressemble à l'usage réel n'existe pas librement ; voir §5 (collecte avec consentement dans l'app).

## 3. Planches illustrées libres pour les cartes
- Règle de droit : un ouvrage publié aux États-Unis avant 1931 est dans le domaine public américain en 2026 ; les publications du gouvernement fédéral (US Fish Commission) aussi. À confirmer par la notice de chaque scan [?].
- Hubbs et Lagler, Fishes of the Great Lakes Region (1958), Public Domain Mark 1.0 sur Fulcrum, planches en demi-teinte (noir et blanc, peu adapté à des cartes en couleur) : https://www.fulcrum.org/concern/monographs/44558h089
- Goode, Fisheries and Fishery Industries of the United States (US Commission of Fish and Fisheries, 1884-87), BHL, notice sans licence : https://www.biodiversitylibrary.org/bibliography/989 [la notice exacte est à confirmer, la recherche l'a renvoyée sans titre] ; atlas de planches numérisé par NOAA (section I, près de 300 planches) : https://webarchive.library.unt.edu/eot2008/20090513125706/http:/www.nefsc.noaa.gov/publications/classics/goode1884/1-plates.pdf
- Storer, History of the Fishes of Massachusetts (1867), copie BHL de Cornell, planches gravées des années 1850 : https://biodiversitylibrary.org/bibliography/46369 [identifiant non confirmé] ; planches de l'Académie américaine : https://amacad.org/archives/fa/fishes
- Bulletins de la US Fish Commission et Jordan & Evermann (1896-1900) : non trouvés dans ces recherches, à chercher dans BHL [?].
- Pas de couleurs garanties : Goode et Storer ont des planches coloriées par endroits [?]. Une illustration par espèce n'est pas acquise pour les 78 : prévoir un fond de carte neutre pour les trous.
- Photos du domaine public pour les cartes : USFWS (ci-dessus), à filtrer par espèce [?].

## 4. Modèles et API existants
| Service | Ce qui est vérifié | Conditions | URL |
|---|---|---|---|
| iNaturalist vision par ordinateur | Points d'entrée non documentés, non prévus pour le public, ouverts à des tiers pour des cas particuliers (forum) | CGU : pas d'entraînement commercial [?] ; ne pas en dépendre | https://forum.inaturalist.org/t/hidden-computer-vision-api/41775 |
| Fishial | Code MIT ; dernier classifieur DINOv2 + ViT, 866 espèces, 93,22 % (chiffre du dépôt, non revérifié) ; démo portal.fishial.ai ; clés API par le portail développeur | Licence des poids et conditions du portail : non trouvées [?] | https://github.com/fishial/fish-identification ; https://github.com/fishial/devapi |
| Fishbrain | Modèle de plus de 300 espèces (avant : 80 espèces américaines), « 99 % sur le top 5 » (affirmation de l'entreprise) | Pas d'API publique trouvée ; concurrent direct | https://fishbrain.com/blog/fishing-news/new-and-improved-fish-identification ; https://fishbrain.com/features/fish-identifier |
- Conséquence : aucune API ne remplace un modèle embarqué (hors ligne au bord de l'eau, coût par appel, dépendance). Fishial reste un étalon de comparaison à utiliser seulement après lecture de ses conditions.

## 5. Recommandation de réentraînement
**Architecture : un tronc commun, une tête par région.** Les 21,8 Mo du modèle sont presque tous dans le tronc DINOv2-small ; la tête (régression logistique sur un plongement de 384 valeurs, ce qui donne environ 30 Ko pour 78 classes à 1 octet par poids, calcul à refaire sur l'export réel) est négligeable. Donc : un seul fichier, une tête Europe (55 classes, inchangée) et une tête États-Unis (78 espèces + « autre poisson » + « pas un poisson »), choisie par le pays ou le département de l'utilisateur, avec un réglage manuel. Écartés : un modèle mondial à une seule tête (les espèces soeurs perche/yellow perch, sandre/walleye, black-bass diffèrent d'un continent à l'autre et le prior régional est gratuit) ; deux modèles complets (double taille, ~44 Mo pour une limite de 30 Mo). Les espèces communes (carpes, brochet, truites, ombles, saumon, perche-soleil, lotte) s'entraînent avec les photos des deux continents dans chaque tête.

**Première démo : 6 espèces américaines**, choisies pour le volume iNaturalist et la pêche (même logique que le repli français) : largemouth bass, bluegill, channel catfish, rainbow trout, walleye, northern pike. Tout le reste passe par « Autre » et la grille. Cibles de confusion à regarder en premier : largemouth/smallmouth, bluegill/pumpkinseed, walleye/yellow perch, pike/muskie.

**Protocole d'examen avant embarquement** (à fixer par Adem avant d'entraîner ; chiffres de seuil à lui, ceux-ci sont des propositions) :
1. Séparer train/validation/test par observateur, jamais par photo (même pêcheur, même poisson = fuite) ; dédupliquer iNaturalist/GBIF/Wikimedia par empreinte d'image.
2. Test à deux niveaux : (a) photos iNaturalist CC0/CC BY mises de côté ; (b) photos de pêcheurs, seul test qui compte pour l'app, relu et trié par S.
3. Seuil de passage proposé : au moins l'égal du v2 européen sur les prises de pêcheurs (82,5 % top-1, 91,6 % top-3), plancher par classe à fixer, refus des « pas un poisson » au moins aussi bon que 92,9 %.
4. Mesurer le seuil de confiance sur les scores par photo (le v2 n'en avait pas, `reconnaissance.md`) et le recalibrer au lieu de garder 0,4.
5. Vérifier sur iPhone avec Vision (le v2 ne l'avait pas été) et la taille du fichier (30 Mo au plus).
6. Aucun poisson protégé donné comme « peut être gardé » : l'IA propose, l'humain confirme (règle du dépôt).

**Jeu de test de pêcheurs** : pas de source libre. Option : opt-in dans l'app après la première prise (photo, espèce confirmée, pas de GPS), avec consentement et crédit ; en attendant, ~100 photos par classe de démo relues à la main [proposition, volume à valider]. Effectif de l'USGS (7 espèces) à lire avant de s'en servir [?].

**Ordre de travail** : (1) trancher la position de licence (avis écrit) ; (2) script de comptage des 78 espèces ; (3) démo 6 espèces ; (4) montée à 78 ; (5) examen ; (6) embarquement.

## Résumé (10 lignes)
1. Liste proposée : 78 espèces ou hybrides américains en 66 lignes, avec latin, statut, région et confusions.
2. 13 classes européennes sont la même espèce (carpes, brochet, arc-en-ciel, fario, omble de fontaine, cristivomer, saumon, perche-soleil, lotte, omble chevalier) ; sandre/perche/black-bass sont proches mais pas identiques.
3. iNaturalist (bucket AWS) est la source principale ; seuls 5 à 10 % des observations sont en CC0/CC BY, soit des centaines par espèce courante et moins de 100 pour les rares (volumes mesurés, [?]).
4. Les CGU iNaturalist interdiraient l'entraînement commercial (citation de forum, non lue [?]) : noyau CC0 + CC BY, avis écrit avant d'ajouter CC BY-NC.
5. Pour publier des cartes : domaine public, CC0, CC BY ; planches Hubbs-Lagler (noir et blanc), Goode, Storer à confirmer.
6. Aucune API n'est recommandée : iNaturalist CV réservé, Fishial sans conditions lues, Fishbrain fermé.
7. Reco : un tronc DINOv2-small partagé et une tête par région, ~30 Ko par tête (calcul).
8. Démo : largemouth bass, bluegill, channel catfish, rainbow trout, walleye, northern pike.
9. Examen : découpage par observateur, test sur prises de pêcheurs, seuil ≥ v2 européen (proposition), recalibrage du seuil.
10. Point dur : aucun jeu libre de photos de pêcheurs ; il faut un opt-in dans l'app ou une relecture manuelle.
