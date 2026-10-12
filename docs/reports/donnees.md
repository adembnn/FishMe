# Données embarquées : fichiers, sources, licences, fabrication
Décision débloquée : quels fichiers de données l'app embarque vendredi, d'où ils viennent, sous quelle licence, comment et par qui on les fabrique.
Lu le 12/10/2026. [?] = non vérifié. « Estimation » = ordre de grandeur de ma part, pas une mesure. Appels Hub'Eau passés par WebFetch (curl est bloqué par le proxy). Overpass (service de requêtes OpenStreetMap) m'a refusé l'accès : je n'ai pas pu l'exécuter.

## En deux phrases
L'app embarque une dizaine de petits fichiers, comme un carnet glissé dans la poche : aucun serveur. Deux fichiers sortent d'un script qui lit les pêches scientifiques de l'OFB (Office français de la biodiversité) via Hub'Eau, un guichet web gratuit de données sur l'eau ; tous les autres se saisissent à la main, chaque ligne avec sa source.

## Quatre constats qui changent le plan
1. OpenStreetMap (OSM, la carte libre) ne compte que 1 624 objets « lieu de pêche » en France ([taginfo Geofabrik, 11/10/2026](https://taginfo.geofabrik.de/europe:france/api/4/tag/stats?key=leisure&value=fishing)). Seul, il ne couvre pas « toute la France » : il faut ajouter nos coins saisis, puis les stations OFB en dernier recours.
2. Paris est un trou : le 75 a 36 pêches OFB en tout, de 1989 à 2011, la dernière le 07/06/2011 ([Hub'Eau, opérations du 75](https://hubeau.eaufrance.fr/api/v1/etat_piscicole/operations?code_departement=75&size=50&fields=code_operation,date_operation,code_station,libelle_station)). Le test E1 « quai de Paris » passe grâce à la station Seine-15e (4,9 km de Notre-Dame), mais avec des relevés vieux de 15 ans ; le relevé récent le plus proche est la Marne à Charenton-le-Pont, pêchée en 2025, à 11,9 km. L'écran doit donc afficher l'année du dernier relevé.
3. Trois corrections à mes rapports précédents, après relecture du texte Légifrance : le brochet de 2e catégorie rouvre le dernier samedi d'avril (pas le 1er mai) ; en 1re catégorie le brochet est limité à 2 par jour ; « esturgeon 1,80 m » n'est pas dans R436-18.
4. Le 94 n'a que 3 stations pêchées depuis 2016, soit 29 pêches en 10 ans : la rareté d'un petit département repose sur peu de pêches, et la carte doit afficher ce nombre.

## Les fichiers embarqués
| Fichier | Étapes | Source et lien | Licence et obligation | Format, taille (estimation) | Fabrication (qui) | Temps (estimation) |
|---|---|---|---|---|---|---|
| `departements.geojson` | E2 E5 E6 | contours IGN Admin Express via [france-geojson](https://github.com/gregoiredavid/france-geojson), fichier « version simplifiée » (trouver le département sans réseau) | Licence Ouverte (Admin Express) : citer IGN et INSEE [?] | GeoJSON (texte qui décrit points et contours), 0,2 à 1 Mo [?] | téléchargement, sans script (étudiant 3) | 15 min |
| `coins-osm.geojson` | E1 | OSM, requête du §1 | ODbL (licence de base de données d'OSM) : crédit « © contributeurs OpenStreetMap », fichier gardé à part, offert en ODbL sur demande [?] | 1 624 objets, 0,3 à 0,5 Mo | export Overpass Turbo (clic), sans script (étudiant 3) | 30 min |
| `coins-maison.json` | E1 E2 | [fédération 75/92/93/94](http://www.federation-peche-paris.fr/808-reglementation.htm), arrêtés du §4 | nos données ; faits publics cités | 30 à 60 points, 10 Ko | saisie, coordonnées prises dans Plans (étudiant 3) | 2 h |
| `stations-especes.json` | E1 E2 E3 | [Hub'Eau Poissons](https://hubeau.eaufrance.fr/page/api-poisson) | [Licence Ouverte 2.0](https://www.data.gouv.fr/dataservices/hubeau-etat-piscicole-des-rivieres) : citer la source (OFB, Hub'Eau) et la date de mise à jour | au plus 16 142 stations (outre-mer compris ? [?]), JSON de 1 à 2 Mo | script Python (étudiant 1) | script 2 à 3 h, exécution 1 h |
| `rarete-departements.json` | E2 E3 E6 | idem | idem | 96 départements x 14 espèces, 30 Ko | même script | inclus |
| `regles.json` | E2 E4 E5 | [Légifrance](https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006188897) + arrêtés du §4 | Licence Ouverte 2.0 (pied de page Légifrance) ; arrêtés : actes publics [?] | 100 à 150 règles, 40 Ko | saisie à la main (étudiant 2) | national 2 h, 1 h par département |
| `especes.json` | E2 E5 E6 | tableau du §3 (TAXREF, Hub'Eau) | Licence Ouverte | 14 lignes | collé depuis ce rapport (étudiant 2) | 30 min |
| `saisons-montages.json` | E3 | avis, à faire relire par un pêcheur | nos données | 14 lignes | saisie (étudiant 2) | 1 h |
| `silhouettes/*.svg` | E2 E5 | créées par nous (§8) | à nous | 14 SVG, 5 Ko pièce | dessin puis retouche (étudiant 3) | 2 à 3 h |
| `credits.json` | page « À propos » | les lignes ci-dessus | OSM, IGN/INSEE, OFB, USFWS si utilisé | 1 Ko | saisie | 15 min |

Non embarqués : BD TOPAGE (§1), météo (WeatherKit, le service météo d'Apple, en direct), lever et coucher du soleil (calcul sur l'iPhone, §6), hauteur d'eau et température de l'eau (hors périmètre, couverture inégale d'après `kickoff/reports/faisa-donnees.md`). « Étudiant 1/2/3 » = répartition proposée, Adem tranche. JSON = fichier texte structuré ; SVG = dessin vectoriel.

## 1. Coins de pêche (E1)
- Étiquettes OSM : `leisure=fishing` (840 points, 739 surfaces, 45 relations). La clé `fishing=` dit l'accès : yes 965, private 185, no 159, licence 75, permit 52 ([taginfo](https://taginfo.geofabrik.de/europe:france/api/4/key/values?key=fishing&filter=all&sortname=count&sortorder=desc&page=1&rp=10), compte tous objets confondus). `sport=fishing` n'ajoute que 26 objets ([taginfo](https://taginfo.geofabrik.de/europe:france/api/4/tag/stats?key=sport&value=fishing)). Statut de l'étiquette : « de facto » ([wiki](https://wiki.openstreetmap.org/wiki/Tag:leisure=fishing)). Les 1 624 incluent des pêcheries privées et payantes.
- Requête Overpass à coller dans Overpass Turbo (site web qui l'exécute et exporte le résultat) puis Exporter en GeoJSON (non exécutée par moi [?]) :
```
[out:json][timeout:180];
area["ISO3166-1"="FR"][admin_level=2]->.fr;
( nwr["leisure"="fishing"]["fishing"!~"^(no|private)$"](area.fr);
  nwr["sport"="fishing"](area.fr); );
out center tags;
```
- BD TOPAGE (référentiel des cours d'eau et plans d'eau) : de trop vendredi. France entière 1,3 Go en shapefile 2024 ([data.gouv](https://www.data.gouv.fr/api/1/datasets/bd-topage-r/)) ; plans d'eau seuls 30 Mo, Licence Ouverte 2.0, mis à jour le 05/08/2026 ([data.gouv](https://www.data.gouv.fr/api/1/datasets/plans-deau-metropole-2025-bd-topage-r/)). L'app n'a besoin que de points, et TOPAGE ne dit rien du droit de pêche.
- ODbL pour une app payante : usage commercial permis, avec crédit ([FAQ OSMF](https://osmfoundation.org/wiki/Licence_and_Legal_FAQ)). Un extrait de plus de 100 objets est « substantiel » ([OSMF](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Substantial_-_Guideline)) : notre fichier OSM est donc une base dérivée, sous ODbL, mais nos règles, raretés et coins maison restent à nous s'ils sont dans des fichiers séparés. Afficher sur le plan d'Apple demande seulement le crédit. Les petits résultats de recherche stockés ne déclenchent pas le partage ([OSMF géocodage](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Geocoding_-_Guideline)). Avis juridique à confirmer [?]. Plan B sans ODbL : coins maison plus stations OFB.

## 2. Espèces à proximité (E1, E2) : Hub'Eau
- Quatre points d'accès sous `https://hubeau.eaufrance.fr/api/v1/etat_piscicole/` : `stations` (16 142), `operations` (une session de pêche à une date et un lieu : 57 639, dont 18 901 depuis 2016), `observations` (10 769 784 lignes, une par poisson mesuré ou par lot), `indicateurs` (note de qualité de rivière IPR, 72 notes pour le 94, inutile vendredi).
- Filtres lus dans le [swagger](https://hubeau.eaufrance.fr/api/v1/etat_piscicole/api-docs) puis testés : `bbox` (13 stations dans 2.2,48.8,2.5,48.95), `latitude`+`longitude`+`distance` en km (48 stations à 20 km de Paris, 2 à 5 km), `code_departement`, `code_station`, `date_operation_min`, `code_taxon` ou `nom_latin_taxon` (200 valeurs max), `fields` (sans lui, 90 colonnes par ligne), `size`, `page`.
- Pagination (découper une longue liste en pages) : la [doc](https://hubeau.eaufrance.fr/page/api-poisson) donne 5 000 lignes par défaut, 20 000 au maximum, profondeur limitée à 20 000, page numérotée librement. Mes tests : `page=20001` et `page=100000` (taille 1) répondent sans erreur, donc plafond non constaté [?] ; `size=20001` semble ramené à 5 000 [?]. Le script découpe par département, espèce et dates pour rester sous 20 000 lignes par tranche et suit le lien `next` (code HTTP 206 = suite à venir). Débit : aucune limite affichée.
- « À proximité » : stations à moins de 10 km du coin ; s'il y en a moins de 2, 20 km, puis 30 km ; au-delà, l'app écrit « aucun relevé OFB à proximité ». Chaque espèce affiche la part des pêches de ces stations où elle a été vue, avec l'année du dernier relevé.
- Fichier précalculé `stations-especes.json` : `{"id":"03112480","lat":48.8299,"lon":2.5093,"dep":"94","peches":10,"derniere":2025,"vues":{"2151":4,"2133":9}}`, clés = code Sandre de l'espèce (colonne « Hub'Eau » du §3). L'app calcule la distance à l'ouverture (haversine, formule de distance sur une sphère) : pas de serveur.
- Ampleur du script (estimation) : environ 1,24 million de lignes d'observation des 14 espèces depuis 2016 (somme des comptes du §3), 3 à 4 millions tous âges : une centaine à quelques centaines de pages de 20 000 lignes, avec `fields` réduit.

## 3. Espèces jouables (E5) et rareté (E2, E6)
Rareté d'une espèce dans un département = part des pêches du département où elle a été capturée : `p = pêches avec l'espèce / pêches du département (avec au moins un poisson)`. Paliers : Commune p >= 50 %, Peu commune 20 à 50 %, Rare 5 à 20 %, Très rare moins de 5 %, « Non relevée » si p = 0. Fenêtre : 10 ans ; si le département a moins de 20 pêches, tout l'historique ; si toujours moins de 20, la région. La carte affiche le nombre de pêches. Limite : les relevés viennent de la pêche électrique (on étourdit brièvement les poissons pour les compter), qui sous-compte les gros poissons des grands cours d'eau (carpe « très rare » dans le 94 alors que les pêcheurs en prennent, avis). La rareté se présente donc comme « rareté dans les relevés OFB ».

Exemple réel, Val-de-Marne (94), 29 pêches du 01/01/2016 au 12/10/2026 sur 3 stations ([opérations](https://hubeau.eaufrance.fr/api/v1/etat_piscicole/operations?code_departement=94&date_operation_min=2016-01-01&size=200&fields=code_operation,date_operation,code_station,operation_sans_poisson)). Comptes lus par WebFetch dans les observations filtrées par espèce ; contrôle : gardon 222+297+395 lignes = 914 = total API, chevesne 86+346+670 = 1 102. Perche (18) : tri manuel du résumé [?].
| Espèce | Nom latin | TAXREF | Hub'Eau | Lignes France depuis 2016 | Pêches du 94 sur 29 | Rareté 94 |
|---|---|---|---|---|---|---|
| Brochet | Esox lucius | [67606](https://taxref.mnhn.fr/taxref-web/taxa/67606/notes) | 2151 | 9 748 | 8 (28 %) | Peu commune |
| Sandre | Sander lucioperca | [69372](https://taxref.mnhn.fr/taxref-web/taxa/69372) | 2195 | 2 354 | 4 (14 %) | Rare |
| Perche commune | Perca fluviatilis | [69350](https://taxref.mnhn.fr/taxref-web/taxa/69350) | 2193 | 59 523 | 18 (62 %) | Commune |
| Black-bass à grande bouche | Micropterus salmoides | [69346](https://taxref.mnhn.fr/taxref-web/taxa/69346) | 2053 | 1 423 | 1 (3 %) | Très rare |
| Silure glane | Silurus glanis | 67585 [?] | 2238 | 13 130 | 13 (45 %) | Peu commune |
| Truite fario | Salmo trutta | 67772 [?] | 2221 | 375 965 | 0 | Non relevée |
| Truite arc-en-ciel | Oncorhynchus mykiss | 67804 [?] | 2216 | 1 553 | 0 | Non relevée |
| Carpe commune | Cyprinus carpio | [67058](https://taxref.mnhn.fr/taxref-web/taxa/67058) | 2110 + variétés | 6 214 | 1 (3 %, miroir) | Très rare |
| Gardon | Rutilus rutilus | 67422 [?] | 2133 | 204 637 | 27 (93 %) | Commune |
| Brème commune | Abramis brama | [67074](https://taxref.mnhn.fr/taxref-web/taxa/67074) | 2086 | 10 083 | 5 (17 %) | Rare |
| Chevesne | Squalius cephalus | 67310 [?] | 31041 | 414 111 | 25 (86 %) | Commune |
| Tanche | Tinca tinca | [67478](https://taxref.mnhn.fr/taxref-web/taxa/67478) | 2137 | 10 938 | 5 (17 %) | Rare |
| Barbeau fluviatile | Barbus barbus | [67143](https://taxref.mnhn.fr/taxref-web/taxa/67143) | 2096 | 123 546 | 7 (24 %) | Peu commune |
| Ombre commun | Thymallus thymallus | 67759 [?] | 2247 | 4 206 | 0 | Non relevée |
Le 75 donne, sur ses 36 pêches de 1989 à 2011 : perche 28 (78 %), sandre 9 (25 %), brochet 7 (19 %), carpe 6 (17 %), silure 4 (11 %), black-bass 0.
- « Lignes » = enregistrements d'observation (un poisson mesuré ou un lot) : indice de présence, pas d'abondance. Colonne Hub'Eau = code Sandre (référentiel français de l'eau) de l'espèce. TAXREF = référentiel des noms d'espèces de France, `CD_NOM` = son numéro. Les liens sont lus sur TAXREF-Web ; les lignes [?] viennent des liens INPN/TAXREF de Wikipédia ([silure](https://fr.wikipedia.org/wiki/Silurus_glanis), [arc-en-ciel](https://fr.wikipedia.org/wiki/Oncorhynchus_mykiss), [truite](https://fr.wikipedia.org/wiki/Salmo_trutta), [ombre](https://fr.wikipedia.org/wiki/Thymallus_thymallus), [gardon](https://fr.wikipedia.org/wiki/Rutilus_rutilus), [chevesne](https://fr.wikipedia.org/wiki/Squalius_cephalus)) à recouper. Hub'Eau garde l'ancien nom « Leuciscus cephalus » pour le chevesne : joindre par `code_taxon`, pas par le nom latin. L'[API TAXREF](https://taxref.mnhn.fr/api/taxa/search?scientificNames=Esox%20lucius) m'a répondu 403.
- Écartées : perche-soleil (introduction interdite, R432-5, [texte](https://www.ain.gouv.fr/contenu/telechargement/6051/65661/file/Reference_Reglementaire.pdf) ; sort d'une capture à vérifier dans R432-10 [?]), anguille (stades et calendrier spéciaux), poisson-chat, espèces protégées. Les 14 sont pêchées couramment et reconnaissables en photo. Incohérence : l'exemple d'E6 « 12 espèces sur 31 » suppose 31 espèces par département ; avec 14 jouables le dénominateur est au plus 14.

## 4. Règles (E2, E5) et heures de pêche (E4)
Socle national, texte Légifrance relu ce jour ([R436-6 à R436-16](https://www.legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006188897), [R436-18](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000038416171), [R436-21](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000038416184)) :
- Heures, R436-13 : « plus d'une demi-heure avant le lever du soleil, ni plus d'une demi-heure après son coucher » ; seule exception écrite : l'anguille pour les pêcheurs professionnels. Carpe de nuit, R436-14 5° : le préfet peut l'autoriser à toute heure en 2e catégorie, pour la période qu'il fixe ; de nuit aucune carpe ne peut être gardée en captivité ni transportée. Paris : 2 lots de Seine, arrêté du 26/02/2025 ([recueil](https://www.prefectures-regions.gouv.fr/irecontenu/telechargement/125632/928907/file/recueil-75-2025-126-recueil-des-actes-administratifs-special du 27.02.2025.pdf), lu dans [mon rapport A](/mnt/project-files/kickoff/reports/alternatives-donnees.md)).
- Ouvertures, R436-6 (en vigueur depuis 01/08/2021) : 1re catégorie du 2e samedi de mars au 3e dimanche de septembre ; ombre du 3e samedi de mai à la même fin ; brochet remis à l'eau jusqu'au vendredi avant le dernier samedi d'avril. R436-7 (26/04/2019), 2e catégorie : toute l'année sauf brochet (1er janvier au dernier dimanche de janvier, puis dernier samedi d'avril au 31 décembre), ombre (3e samedi de mai au 31 décembre), truite fario et autres salmonidés (temps de la 1re catégorie).
- Dates calculées : 2e samedi de mars 2027 = 13/03/2027 ; 3e dimanche de septembre 2026 = 20/09/2026 ; dernier samedi d'avril 2026 = 25/04/2026. Les 15 et 16/10/2026 de la démo : 1re catégorie fermée ; 2e catégorie ouverte, brochet et ombre compris ; truite fario fermée partout (R436-7 3° la cale sur la 1re catégorie). Stocker les dates de la saison, pas la phrase. Le préfet peut prolonger de 1 à 3 semaines en haute montagne (R436-6 II).
- Tailles, R436-18 (26/04/2019), mesurées museau à queue déployée : brochet 0,50 m ; sandre 0,40 m (2e cat.) ; black-bass 0,30 m (2e cat.) ; ombre 0,30 m ; truites 0,23 m ; huchon 0,70 m. Quotas, R436-21 : salmonidés 10 par jour ; 1re cat. brochet 2 par jour ; 2e cat. sandre, brochet et black-bass 3 par jour dont 2 brochets.
| Dép. | Où trouver | Ce que je sais | Trou |
|---|---|---|---|
| 75 | arrêté du 26/02/2025 (lien ci-dessus) | 2e cat. partout ; interdit à moins de 50 m des ouvrages ; Arsenal en réserve | aucun |
| 92 | [RAA 18/01/2022](https://www.hauts-de-seine.gouv.fr/contenu/telechargement/19570/124654/file/2022-01-18 RAA spécial DCPPAT du 18 janvier 20022.pdf) ; AP 2017-256 (carpe de nuit) | Suresnes PK 16,5 à 17,35 interdit ; ports de Nanterre et Gennevilliers en réserve | PDF refusé aux robots, contenu non lu [?] |
| 93 | recueil des actes de la préfecture | Neuilly-sur-Marne écluse 150 m ; darse du Millénaire, ports d'Épinay et de Gournay en réserve | aucun arrêté 93 trouvé [?] |
| 94 | [RAA n°06 du 09/01/2024](https://www.val-de-marne.gouv.fr/contenu/telechargement/23987/185659/file/RAA spécial n°06 du 09 janvier 2024.pdf) ; AP 2017/4688 | interdit 250 m aux barrages d'Ablon, Port-à-l'Anglais, Créteil, Saint-Maurice ; carpe de nuit Seine, Marne, lac de Créteil | PDF refusé, non lu [?] |
| 77 | [page arrêtés de la fédération 77](https://www.federationpeche77.fr/4263-arretes-prefectoraux.htm) : AP permanent 2024, AP réserves 2023, AP ouvertures 2026, avis 2026 | le projet 2024 : 1re cat. = petites rivières nommées (Lunain, Orvin, Grand Morin amont, Dragon), le reste en 2e ; brochet 0,60, sandre 0,50, black-bass 0,40 ; brochet et sandre fermés jusqu'au dernier samedi d'avril ([projet](https://www.seine-et-marne.gouv.fr/contenu/telechargement/59883/499389/file/PROJET_ARP_PERMANENT_2024.pdf)) | PDF signés vides pour mes outils : à lire à la main [?] |
RAA = recueil des actes administratifs (le journal officiel local d'une préfecture) ; AP = arrêté préfectoral ; actes publics, réutilisation en principe libre [?]. 75, 92, 93, 94 relèvent d'une même page de la [fédération](http://www.federation-peche-paris.fr/808-reglementation.htm) : tous classés 2e catégorie ; brochet 0,60 m, sandre 0,50 m, black-bass 0,40 m, truite 0,23 m ; 3 carnassiers par jour dont 2 brochets ; anguille jaune du 15 février au 15 juillet ; vente et consommation interdites pour la Seine, la Marne, l'Yerres et les canaux (arrêté 2010-555). Un arrêté local relève les tailles ou baisse les quotas (R436-19, R436-21) et ajoute des listes de lieux (réserves, parcours carpe de nuit) : listes de noms, pas de géométrie vendredi.
Schéma d'une règle (`regles.json`) ; une règle d'un département remplace la règle nationale de même `espece`, `type` et `categorie` :
```json
{ "id": "94-bro-taille", "portee": {"niveau": "departement", "code": "94"},
  "especes": ["2151"], "categorie": "2",
  "type": "taille_min | quota_jour | ouverture | horaire | interdit | reserve",
  "valeur": {"cm": 60}, "du": null, "au": null,
  "remplace": "nat-bro-taille",
  "phrase": "Brochet : 60 cm minimum dans le 94.",
  "source": {"texte": "Fédération 75/92/93/94, page Réglementation", "url": "http://www.federation-peche-paris.fr/808-reglementation.htm",
             "lu_le": "2026-10-12", "version": "sans date"},
  "statut": "saisi | verifie | incertain", "verifie_par": null }
```
Un champ `statut` à `incertain` bloque l'affichage d'un verdict « tu peux la garder » (l'IA ne décide jamais). Test E2 : 5 coins (75, 92, 93, 94, 77), chacun comparé au texte de sa `source`.
Hors des 5 départements saisis (proposition, à valider par Adem) : socle national seul, catégorie « inconnue », jamais de verdict « tu peux la garder » ; « relâche-la » seulement si le poisson est sous la taille minimale la plus basse, sinon « vérifie l'arrêté du département » avec le lien de la préfecture. Sandre et black-bass n'ont de taille nationale qu'en 2e catégorie, d'où le besoin de connaître la catégorie.

## 6. Lever et coucher du soleil sans réseau (E4)
- Option A : bibliothèque [Solar](https://github.com/ceeK/Solar), Swift, licence MIT, algorithme de l'observatoire naval américain, aucune connexion, dates en UTC. Option B : 40 lignes de formule NOAA/Meeus (positions du soleil), sans dépendance ; l'outil NOAA n'est plus maintenu mais annonce environ 1 minute d'erreur sous 72° de latitude ([NOAA](https://gml.noaa.gov/grad/solcalc/sunrise.html)).
- Vérifié en Python standard, Paris le 15/10/2026 : mon calcul donne lever 06:10:01 UTC et coucher 17:02:07 UTC ; la référence [sunrise-sunset.org](https://api.sunrise-sunset.org/json?lat=48.8566&lng=2.3522&date=2026-10-15&formatted=0) donne 06:09:29 et 17:03:14, écarts de 32 s et 67 s. Fenêtre légale ce jour-là : 07:39 à 19:33 en heure d'été. Afficher « fin légale » avec une minute de marge en moins.

## 7. Mission première prise (E3)
Entrées : fréquence locale OFB (`stations-especes.json`), saison (`saisons-montages.json`), météo WeatherKit (vent, pluie, pression), heures légales (§6) et ouvertures (`regles.json`). Score sans IA, estimation à ajuster, seuils non sourcés : `score = 100 x A x S x M x H`. A = part des pêches OFB où l'espèce est vue autour du coin (0 à 1). S = 1 saison active, 0,5 moyenne, 0 si l'espèce est fermée ce jour-là. M = 1, fois 0,7 si vent > 30 km/h, fois 0,6 si pluie > 2 mm/h, fois 0,8 si la pression chute de plus de 6 hPa (hectopascals) en 3 h. H = 1 dans les 2 h après le lever et les 2 h avant le coucher, 0,7 ailleurs dans la fenêtre légale, 0 en dehors. On propose le couple (coin à moins de 10 km, espèce, heure) au score le plus haut, avec le montage de la table. Même position et même date donnent toujours la même proposition, ce qui se teste.

## 8. Illustrations des cartes (E6)
Relu : la [partie B](/mnt/project-files/kickoff/reports/alternatives-donnees.md). Voie la plus sûre : la photo détourée du pêcheur est la carte (zéro licence tierce) et les 14 silhouettes SVG viennent de nous. Les dessins USFWS (brochet, black-bass, carpe, truite fario) sont dans le domaine public mais le statut « commandé par l'agence » reste à confirmer ; la silhouette de silure PhyloPic est CC0 ([page](https://www.phylopic.org/images/7cb387d7-9b23-4e5c-a007-2d938339cb8a), lu). Planches de Bloch : licence des numérisations non lue (page d'Heidelberg refusée) [?]. À écarter : FishBase (non commercial), photos Commons CC BY-SA (partage à l'identique), Image Playground tant qu'Apple n'a pas écrit sur les droits.

## 9. Ce qui peut être fabriqué avant jeudi sans code de l'app
- Sans aucun code : `departements.geojson`, `coins-osm.geojson` (export Overpass Turbo), `coins-maison.json`, `regles.json`, `especes.json`, `saisons-montages.json`, `credits.json`, silhouettes (dessin). Environ 10 à 12 h en tout, à répartir sur 3 personnes (estimation).
- Avec un script (hors app) : `stations-especes.json` et `rarete-departements.json`. Sans script, le tableur suffit pour 5 départements pilotes (export CSV de Hub'Eau, tableau croisé) mais pas pour la France entière.
- Règle « les données générées ne sont jamais commitées » : les fichiers saisis sont des sources (commités) ; les deux fichiers du script sont régénérés par une commande, ignorés par git, ajoutés à l'app au moment de la construction.
- Avant de lancer les lots en parallèle : faire passer le 94 de bout en bout (script, fichier, lecture dans l'app) comme cas réel.

## Recommandation
1. Embarquer les 10 fichiers du tableau, sans BD TOPAGE. OSM reste dans son propre fichier ODbL ; sans OSM, plan B coins maison plus stations OFB.
2. Faire tourner le script Hub'Eau sur le 94 mercredi pour tester la chaîne, puis sur la France jeudi matin. Tout l'historique si moins de 20 pêches, rayon 10, 20 puis 30 km.
3. Saisir à la main, sourcées, les règles nationales (R436-6, -7, -13, -14, -18, -21) et les 5 départements ; lire à la main les PDF signés du 77, 92 et 94 que mes outils n'ont pas ouverts.
4. Retenir 14 espèces (tableau du §3) ; corriger l'exemple d'E6 (« sur 31 ») avant la démo.
5. Calculer le soleil avec Solar (MIT) ou la formule NOAA, avec une minute de marge sur la fin légale.
