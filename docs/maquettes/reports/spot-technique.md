# Définir un « spot de pêche » : recherche technique

Décision débloquée : comment l'app dit « tu es dans ton spot gratuit » et « voilà les espèces et les règles de ce spot ».
Sources lues le 15 oct. 2026. Marqueur [à vérifier] = non confirmé. Les chiffres Hub'Eau viennent d'appels réels faits aujourd'hui.

## L'idée en image
Un spot, c'est une punaise sur la carte avec un cercle autour. La punaise sait trois choses : dans quel département elle est
(donc les règles), quelle eau est la plus proche (rivière, lac, mer), et quelles pêches scientifiques ont eu lieu près d'elle
(donc les espèces). Tout le reste (tronçon exact, grille) est plus précis mais demande des fichiers que l'équipe n'a pas le temps de préparer.

## 1. Géométrie de l'eau

| Jeu de données | Contenu | Licence | Poids / format | Source |
|---|---|---|---|---|
| BD TOPAGE (Sandre, OFB, IGN) | 8 jeux dont cours d'eau, plans d'eau, tronçons, limites terre-eau, bassins | Licence Ouverte 2.0 (la fiche 2019 dit 1.0) | 1,3 Go (`donnees.md`), SHP, GeoPackage, GeoJSON | [Doc Sandre](https://www.sandre.eaufrance.fr/ftp/documents/fr/DocAdmin/ETH/1/sandre_administration_topage_1.pdf), [fiche](https://www.geo2france.fr/geonetwork/srv/api/records/a535c474-eca0-4295-880e-a95c8e633a51) |
| OpenStreetMap | `waterway=river/stream/canal`, `natural=water` + `water=lake`, `leisure=fishing`, `fishing=yes/no/private` | ODbL : « © contributeurs OpenStreetMap » | via Overpass, au choix de la zone | [fishing=*](https://wiki.openstreetmap.org/wiki/Key:fishing), [Lakes](https://wiki.openstreetmap.org/wiki/Lakes) |
| Limite terre-mer (Shom, IGN) | trait de côte récent (marée coef. 120), remplace Histolitt 2009 | « licence ouverte » (Shom) [à vérifier : version] | SHP, par département ou France | [Shom](https://www.shom.fr/fr/liste-actualites/une-nouvelle-limite-entre-la-terre-et-la-mer-qui-reunit-terriens-et-marins-la) |
| Limites de salure des eaux (LSE) et transversale de la mer (LTM) | frontière rivière/mer : pêche fluviale en amont, maritime en aval | Etalab pour les limites de pêche Shom ; LSE/LTM [à vérifier] | SHP | [Shom](https://services.data.shom.fr/geonetwork/src/search?topicCat=boundaries), [CNIG](https://cnig.gouv.fr/IMG/documents_wordpress/2021/10/LIMLATPREF_reunion_gimel_20210610.pdf) |

Termes : un **tronçon** est un petit morceau de rivière entre deux jonctions. Un **identifiant Sandre** est le numéro officiel
de chaque objet de l'eau (il sert de clé entre jeux de données). La **salure** est le point où l'eau devient salée : au-delà, le droit de la mer remplace celui de la rivière.

Constats :
- TOPAGE est la bonne clé (identifiants stables, liens cours d'eau / tronçon / plan d'eau) mais trop gros pour l'app. Il faudrait un extrait par département, simplifié. Pas faisable avant vendredi.
- Le fichier OSM déjà prévu (`coins-osm.geojson`) donne des points de pêche et des plans d'eau. C'est assez pour accrocher un spot.
- Pour la mer : les 5 départements saisis (75, 92, 93, 94, 77) sont tous dans les terres. Vendredi, la mer peut rester « bientôt » sans bloquer.

**Accrocher un point GPS à « sa » rivière.** On cherche l'eau la plus proche du point (distance au segment, pas au sommet) et on
la garde si elle est assez près :
- rivière : 50 m. La position GPS de l'iPhone est fausse de 5 à 20 m en général, davantage sous les arbres [à vérifier sur le terrain] ;
- lac, étang : 0 m dedans, ou 100 m du bord (le pêcheur est sur la rive, pas dans l'eau) ;
- au-delà : « aucune eau reconnue ici », le spot est créé quand même, avec les règles du département seules.
Sur un fleuve large (Seine), la rive opposée peut être le mauvais côté de la limite de département : on garde le département du point GPS, pas celui de la rivière.

## 2. Espèces présentes

| Source | Ce que c'est | Couverture | Licence | Utilité pour nous |
|---|---|---|---|---|
| Hub'Eau poissons (`etat_piscicole`) | pêches électriques OFB, par station | 16 255 stations, 57 639 pêches (appels du 15 oct.) | Licence Ouverte 2.0 | **La seule source utilisable.** Rivières surtout |
| Naïades | qualité de l'eau (chimie, biologie) des agences | nationale | Licence Ouverte [à vérifier] | Pas d'espèces de pêche. À écarter |
| INPN / OpenObs | observations naturalistes | 71 M de données en 2020, mailles 10 km pour les données floutées | licence variable selon le jeu ("Other (Open)") [à vérifier] | Peu de poissons de pêche, pas de garantie. Mailles 10 km : [zip 3 Mo](https://inpn.mnhn.fr/referentiels-donnees) |
| GBIF | même famille, mondial | grande, hétérogène | **CC0, CC-BY ou CC-BY-NC selon le jeu** | Risque : une donnée NC est interdite dans une app payante. À écarter |
| Ifremer campagnes (EVHOE, CGFS, MEDITS) | chalutages scientifiques, abondance par km² | mer, fonds de 10 m et plus | Licence Ouverte [à vérifier jeu par jeu] | Pas la côte où pêche un pêcheur du bord |
| DCSMM | 4 sous-régions marines (découpage) | France | [à vérifier] | Bon « bassin » de repli pour la mer, pas une liste d'espèces |
| Débarquements, RecFishing | pêche pro / déclarations des plaisanciers | — | non ouvertes par spot | Absence de données ouvertes fiables pour le bord de mer |

Couverture Hub'Eau, nombre de stations **toutes dates confondues** par département (appels du 15 oct.) :
75 : 3 · 93 : 4 · 94 : 19 · 2A : 51 · 59 : 92 · 77 : 98 · 06 : 104 · 62 : 120 · 69 : 129 · 33 : 403 · 22 : 430 · 29 : 581 · 64 : 596.
Non obtenus (erreur de lecture) : 92, 13, 83 [à vérifier]. Le nombre exact de départements peu couverts n'est pas compté :
96 appels `?code_departement=XX&size=1` le donnent en une minute [à vérifier, script D2].
Lecture : l'Île-de-France centrale est un désert (3 à 4 stations dans 75 et 93), la Bretagne et le Pays basque sont riches.
Attention, « 19 stations » dans le 94 au total mais **3 stations actives depuis 2016** (`donnees.md`) : l'ancienneté compte autant que le nombre.

**Estimer « ce qu'on peut trouver » sans station proche** : on remonte par étages, et on dit à quel étage on s'est arrêté.

| Étage | Condition | Phrase affichée |
|---|---|---|
| A. Station sur la même eau | station à 5 km ou moins, même cours d'eau ou même plan d'eau | « 18 pêches OFB sur ce cours d'eau, dernière en 2023 » |
| B. Station proche | 5 à 30 km (règle déjà dans `donnees.md`) | « relevés à 12 km, autre cours d'eau possible » |
| C. Département | au moins 20 pêches sur 10 ans (rareté, `donnees.md`) | « rareté dans le département : 29 pêches » |
| D. Région | moins de 20 pêches | « rareté en Île-de-France » |
| E. Rien | aucun relevé à moins de 30 km et région vide | « aucun relevé OFB à proximité » |

Remonter au tronçon ou au bassin hydrographique demande TOPAGE : étape suivante. Écart à afficher : la distance à la station, le
nombre de pêches N et l'année du dernier relevé. Jamais de pourcentage seul. La pêche électrique sous-compte les gros poissons
(carpe, silure) : l'écran le dit déjà (`donnees.md`).

Mer, vendredi : aucune donnée ouverte fiable pour le bord. Option honnête : liste « espèces fréquentes de la façade »
(Manche, Atlantique, Méditerranée) écrite à la main par un pêcheur de l'équipe, étiquetée « liste indicative, pas un relevé ».

## 3. Règles

| Sujet | Existe-t-il en données ouvertes ? | Source / licence |
|---|---|---|
| Catégories piscicoles (1re / 2e) | **Pas de couche nationale trouvée.** Des couches par département : Bas-Rhin, Ardennes, Yonne… | [Bas-Rhin](https://www.data.gouv.fr/datasets/lineaire-des-categories-piscicoles-des-cours-deau-et-plan-deau), [Ardennes](https://www.data.gouv.fr/datasets/categorie-piscicole-des-cours-deau-lineaire), Licence Ouverte. Aucune trouvée pour 75, 92, 93, 94, 77 [à vérifier] |
| Réserves de pêche | pas de couche nationale ; cartes des fédérations (Ariège, Isère…) | non réutilisables sans accord [à vérifier] |
| Aires marines protégées | **oui, nationale** | OFB, Licence Ouverte 2.0, mise à jour 31 juil. 2026 ; [data.gouv](https://www.data.gouv.fr/datasets/aires-marines-protegees-francaises-2/community-resources), service WFS `wxs.ofb.fr/geoserver/gestion/ows`, couche `ges_omon_amp_ofb_pol_3857_vue` |
| Zones portuaires | aucune couche ouverte nationale trouvée | [à vérifier] |
| Arrêtés préfectoraux | PDF seulement (77, 92, 94 illisibles par outil, 93 introuvable : fiche D1) | Légifrance et préfectures |

Conséquence : la catégorie d'un cours d'eau ne se calcule pas pour la France entière. L'app garde le modèle déjà décidé : règles
**par département** (`regles.json`), catégorie « inconnue » ailleurs, jamais « tu peux la garder » sans règle lue. La mer a un socle
national (arrêté du 26 octobre 2012 sur les tailles minimales, [mer.gouv.fr](https://www.mer.gouv.fr/peche-de-loisir-en-mer)) ; les AMP s'ajoutent plus tard.

## 4. Trois modèles de spot

| | A. Cercle autour d'un point | B. Tronçon ou plan d'eau entier (TOPAGE) | C. Cellule de grille (ex. 10 km) |
|---|---|---|---|
| Calcul hors ligne | Très simple : une distance (formule de haversine, quelques lignes) | Lourd : extrait TOPAGE par département, index spatial, accrochage ligne | Simple : arrondir latitude et longitude |
| Cohérence espèces | Bonne : rayon de recherche de stations identique | Excellente si station sur le même tronçon, mais beaucoup de tronçons sans station | Moyenne : une cellule mêle plusieurs eaux |
| Cohérence règles | Bonne : le département du centre | Excellente (catégorie par tronçon, si elle existait) | Mauvaise : une cellule traverse des limites de département |
| Vérifier « je suis dans mon spot » | Distance au centre ≤ rayon + marge de précision GPS | Distance à la ligne ≤ 50 m, et il faut le tronçon embarqué | Même cellule, mais 100 km² = « mon spot » est énorme |
| Géorepérage iOS (20 régions max par app, [Apple](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/LocationAwarenessPG/RegionMonitoring/RegionMonitoring.html)) | 1 spot = 1 région : OK ; tous les spots d'un utilisateur payant au-delà de 20 : choisir les plus proches | Une ligne n'est pas un cercle : il faut des cercles qui la couvrent, donc plusieurs régions par spot | 1 cellule = 1 grand cercle (rayon limité par le système) : pas exact |
| Triche | Déplacer le centre (parade : le centre est figé à la création) ; fausse position GPS (existe pour tout modèle) | Difficile de tricher sur la ligne, mais « spot » = 40 km de Seine gratuite : trop généreux | Facile : à la frontière de cellule, deux voisines pour le prix d'une |
| Prêt vendredi | Oui | Non | Oui, mais produit faible |

Le géorepérage (région surveillée par l'iPhone qui réveille l'app à l'entrée ou la sortie) n'est **pas nécessaire** pour vérifier
« je suis dans mon spot gratuit » : l'app ouverte lit la position et compare. Le géorepérage sert plus tard aux alertes
(« tu arrives sur ton spot »). Il ne génère pas d'événement si on est déjà dedans à l'enregistrement. Rayon minimal fiable : [à vérifier], Apple parle d'un plafond, pas d'un plancher dans ce que j'ai lu.
Les triches GPS (simulateur de position) ne se bloquent pas côté appareil. La parade réaliste est un verrou à la **création** du spot gratuit, pas un contrôle permanent.

## 5. Recommandation

**Pour vendredi : modèle A, cercle de 1 km autour d'un point.** Le centre vient de la position GPS ou d'un coin de `coins-osm.geojson` / `coins-maison.json` choisi sur la carte.
- Stocké : identifiant, centre, rayon (1 000 m), date de création, département (déjà calculé par `departement(de:)`).
- Règles : celles du département du centre (`verdict` existant). Espèces : étages A à E du §2, rayon de recherche 30 km (déjà prévu).
- Dans le spot ? `distance(position, centre) ≤ 1 000 m + précision GPS`, affichée dans l'app ouverte. Pas de géorepérage vendredi.
- Spot gratuit verrouillé à la création (stocké dans le Trousseau de l'iPhone pour survivre à la réinstallation) [à vérifier : ce que MWM/StoreKit permet].
- Rayon de 1 km car c'est la portée d'une session à pied sur une berge, et assez petit pour qu'on ne couvre pas tout un fleuve. À valider avec un pêcheur de l'équipe.
- Mer : « bientôt » ou liste indicative écrite à la main.

**Ensuite, dans l'ordre :**
1. Géorepérage d'un spot (1 région) pour l'alerte d'arrivée, puis les spots payants (les plus proches, 20 max).
2. Script D2 sur la France entière : table station → département, étages A et B réels.
3. Extrait TOPAGE par département, simplifié, pour accrocher au tronçon / plan d'eau, étage « même cours d'eau ».
4. Couche AMP OFB, limite terre-mer et LSE pour décider eau douce / mer et signaler les zones protégées.
5. Catégorie piscicole par département là où une couche DDT existe ; PDF à saisir ailleurs.

## Questions pour toi (décisions qui te reviennent)
Décor : le cercle est le plus simple, mais deux choix de produit restent ouverts.
1. Rayon du spot gratuit : a) 500 m (reco si on veut vendre), b) 1 km (reco usage), c) 2 km (généreux).
2. Si l'utilisateur veut changer de spot gratuit : a) jamais, b) une fois par mois (reco), c) à volonté.
3. Mer vendredi : a) « bientôt » (reco, rien d'inventé), b) liste indicative à la main par façade.
Défaut si tu ne réponds pas : 1.b, 2.b, 3.a.
