# FishMe USA : données de conditions (hydrologie, météo, alertes)

Date : 7 nov. 2026

**Décision débloquée : quelles sources utiliser aux États-Unis à la place de Hub'Eau (niveau, débit, température des rivières), de WeatherKit seul (météo/alertes) et du calcul solaire, et sur quelle API USGS bâtir le pilote, sachant que l'ancienne API est en cours d'arrêt.**

Légende : [?] = non vérifié. Aucun chiffre n'est inventé ; les chiffres proviennent des pages citées.

## 1. Alerte structurante : USGS migre vers de nouvelles API

- L'ancien service `waterservices.usgs.gov` (IV, DV, Site) est en cours de retrait. Un résumé de recherche indique : migration à faire avant le 16 nov. 2026, retrait de WaterServices au T1 2027, NWISWeb fermé après février 2027. Sources : https://waterdata.usgs.gov/blog/api-waterservices-decom/ (page non lisible directement, 403), https://waterdata.usgs.gov/blog/nwisweb-decommission-summary/
- Dates précises (ralentissement volontaire dès le 16 nov. 2026, coupures dès le 27 janv. 2027, arrêt le 22 févr. 2027) : relevées uniquement dans un module tiers [?] (https://zitniklab.hms.harvard.edu/ToolUniverse/en/_modules/tooluniverse/usgs_water_tool.html).
- **Conséquence : ne PAS développer FishMe sur `waterservices.usgs.gov`. Partir directement sur `api.waterdata.usgs.gov`.**

## 2. USGS Water Data APIs (équivalent principal de Hub'Eau)

- Base : `https://api.waterdata.usgs.gov/ogcapi/v1/collections/{collection}` (OGC API - Features, GeoJSON avec `f=json`). Le guide de migration utilise /v1 ; certains docs/outils mentionnent v0 [?]. https://api.waterdata.usgs.gov/docs/ogcapi/migration
- Correspondances : /iv -> `continuous` (et `latest-continuous` pour la dernière valeur par série) ; /dv -> `daily` (`latest-daily`) ; /site -> `monitoring-locations` ; `time-series-metadata` pour la période de données ; /peak -> `peaks` ; /stats -> API statistiques séparée ; /gwlevels -> `field-measurements`.
- Codes paramètres : 00060 = débit (ft³/s), 00065 = hauteur d'eau (ft) (cités dans le guide de migration) ; 00010 = température de l'eau (°C) [code classique USGS, non revalidé sur cette doc, ?].
- Filtres : `parameter_code`, `monitoring_location_id` (format `USGS-02238500`), `datetime` (instant, intervalle, `..`, durée ISO `P7D`), `limit`, pagination par lien `next` (offset/limit). `daily` accepte `bbox`. Pas de filtre natif par état/comté/bassin sur les autres collections : interroger `monitoring-locations` d'abord. `continuous` : max 3 ans par requête. https://api.waterdata.usgs.gov/docs/ogcapi/
- Clé API (api.data.gov) : nécessaire au-delà de quelques requêtes par heure ; envoi par `api_key=` ou en-tête `X-Api-Key` ; sans clé, erreurs 429 ; limites exposées via `X-RateLimit-Limit/Remaining` (aucun chiffre officiel publié sur la page). https://api.waterdata.usgs.gov/docs/ogcapi/keys/
- Implication architecture : une clé unique embarquée dans l'app serait partagée par tous les utilisateurs => prévoir un **petit backend/proxy FishMe avec cache** (clé côté serveur) plutôt qu'un appel direct depuis l'iPhone. C'est aussi vrai pour agréger (voir §9).
- Fraîcheur : mesures typiquement toutes les 15 min, transmises environ toutes les heures (page de l'ancien service, https://waterservices.usgs.gov/docs/) ; pour d'autres sites l'enregistrement va de 15 à 60 min et la transmission de 1 à 4 h (https://waterdata.usgs.gov/nwis/rt/index.html [?]).
- Ampleur du réseau : 12 165 stations de jaugeage continues en 2024 (https://www.usgs.gov/publications/us-geological-survey-national-streamgage-network-2024). Température de l'eau : seul chiffre trouvé = 2 842 sites (32 % des stations) en 2018 (présentation USGS, https://www.gov.nl.ca/ecc/files/waterres-rti-rtwq-conf-2018-17-patrickrasmussen.pdf) ; chiffre actuel [?]. À mesurer au démarrage par requête `time-series-metadata` sur 00010.
- Différence vs Hub'Eau : la température y est bien moins répandue ; beaucoup de stations n'ont que débit et/ou hauteur. Prévoir un état "pas de température sur cette station" et afficher la station avec température la plus proche (avec distance).
- Licence : données USGS en domaine public, gratuites, mais la mention de la source est demandée et les données provisoires doivent porter l'avertissement officiel (peuvent être révisées). https://www.usgs.gov/data-management/publishshare ; https://water.usgs.gov/data/disclaimer.html. Champ `approval_status` = Approved/Provisional dans les réponses.

## 3. USGS WaterWatch

- Carte USGS qui situe le débit de chaque station par rapport à l'historique du même jour de l'année (percentile, stations avec au moins 30 ans de données), mise à jour environ toutes les heures, données provisoires. Services web (flux courant, crue/hauts débits, moyennes 7/14/28 j, stations en crue) et exports SIG/KML : https://waterwatch.usgs.gov/ ; présentation : https://www.drought.gov/data-maps-tools/usgs-waterwatch. Adresses exactes des services et pérennité après l'arrêt de l'ancienne API [?].
- Intérêt FishMe : le "niveau par rapport à la normale" (bas/normal/haut) est plus parlant qu'un débit brut. Pour le pilote, le calculer soi-même avec l'API statistiques USGS (percentiles du jour) plutôt que dépendre de WaterWatch [?].

## 4. NOAA / NWS api.weather.gov

- Gratuit, sans clé ; **en-tête User-Agent obligatoire** identifiant l'app (site ou e-mail recommandé) ; clé API prévue plus tard. Limites réelles non publiées ; au dépassement, erreur et nouvel essai possible après environ 5 s. https://www.weather.gov/documentation/services-web-api
- Alertes : `/alerts/active?area={État}` (ou par zone/UGC) ; `/alerts` couvre les 7 derniers jours ; archive officielle = NCEI.
- Prévisions : appeler `/points/{lat},{lon}` puis suivre `forecast` (périodes de 12 h), `forecastHourly`, `forecastGridData`. Les mailles (office, gridX, gridY) peuvent changer : revalider `/points` périodiquement. Formats via en-tête Accept (GeoJSON, JSON-LD, CAP, ATOM, DWML).
- Couverture : États-Unis et territoires uniquement [?].
- Alertes utiles pêche : Flood Warning/Watch/Advisory, Flash Flood, Severe Thunderstorm, Tornado, Small Craft Advisory/Gale (pêche embarquée), Beach Hazards [?] ; liste exacte des types d'événements à confirmer.

## 5. NWS flood gauges (NWPS)

- API : https://api.water.noaa.gov/nwps/v1/docs/ . Fournit stations de crue NWS, observations et prévisions de hauteur/débit, seuils de catégories (action, mineure, modérée, majeure), phrases d'impact, courbes de tarage, prévisions du National Water Model (via client R tiers, https://ui-research.github.io/nwps/articles/nwps.html). Chemins exacts des endpoints de prévision [?].
- Les stations sans seuils sont "Flood Category Not Defined". Mise à jour de la couche cartographique : 30 min (https://mapservices.weather.noaa.gov/eventdriven/rest/services/water/riv_gauges/MapServer). La plupart des niveaux observés viennent d'USGS.
- **Usage FishMe : équivalent direct des "vigilances crue" Vigicrues** -- affichage de la catégorie de crue et des seuils pour les stations qui en ont, hauteur prévue sur quelques jours.

## 6. NOAA Tides & Currents (CO-OPS)

- API `https://api.tidesandcurrents.noaa.gov/api/prod/datagetter` (JSON/XML). Produits dont niveau d'eau, prédictions de marée et température de l'eau mesurée. Limites de période : 1 mois pour niveau 6 min, 1 an pour horaire/hautes-basses (https://tidesandcurrents.noaa.gov/api/ ; https://tidesandcurrents.noaa.gov/web_services_info.html). Pas de prédiction de température [?].
- Pertinent pour estuaires, rivières à marée, pêche côtière ; hors périmètre "eau douce" du pilote sauf rivières à marée (Hudson, Potomac...).

## 7. NOAA GLERL (Grands Lacs)

- Température de surface : analyse satellitaire quotidienne GLSEA par lac, via CoastWatch Great Lakes (ERDDAP et THREDDS hébergés par GLERL) ; modèle GLCFS (nowcast/prévisions 3D de température et courants) via THREDDS. Les données du site GLERL sont qualifiées d'expérimentales. Sources : https://www.glerl.noaa.gov/data ; https://www.glerl.noaa.gov/res/Programs/ipemf/glcfs_data_access.html ; https://noaa-glerl.github.io/access-glcfs-fvcom-from-thredds-py.html. Identifiants de jeux ERDDAP, chemins THREDDS, licence : [?].
- Hors périmètre eau douce de rivière du pilote ; à garder pour une phase Grands Lacs (pêche côtière des lacs). Pour la température d'une rive de lac, les stations CO-OPS des Grands Lacs (§6) sont plus simples.

## 8. WeatherKit aux USA

- Inclus : 500 000 appels/mois par adhésion Apple Developer Program ; paliers payants : 1 M = 49,99 USD, 2 M = 99,99, 5 M = 249,99, 10 M = 499,99, etc. ; pas de report des appels non utilisés. https://developer.apple.com/weatherkit/get-started/
- Alertes météo : "régions sélectionnées" ; aucune liste de pays officielle trouvée [?] ; l'endpoint de disponibilité de l'API REST (jeux de données disponibles pour un lieu) permet de tester par coordonnée (https://developer.apple.com/documentation/weatherkitrestapi). Les alertes américaines sont bien les alertes NWS ; le délai de publication a changé en 2022 (forum Apple : https://developer.apple.com/forums/thread/723959), comportement actuel [?]. Précipitations minute par minute : régions sélectionnées [?] pour les USA. Sources US : modèles, stations, radar et alertes proviennent de NWS/NOAA (https://developer.apple.com/weatherkit/data-source-attribution/).
- Attribution obligatoire : marque "Apple Weather" + lien légal vers la page de sources ; chaque alerte doit inclure le lien Apple de détail, nommer l'agence émettrice, et son texte ne doit pas être modifié.
- Choix : WeatherKit pour météo courante/horaire/quotidienne ; api.weather.gov pour alertes officielles NWS et pour les zones où WeatherKit n'en renvoie pas [?].

## 9. Soleil / lune

- Calcul local (algorithme NOAA/Meeus) suffisant : lever/coucher du soleil, aube/crépuscule, phase de lune, sans réseau. Alternative : WeatherKit (`WeatherKit` fournit aussi ces données). L'heure légale de fin de pêche aux USA n'est PAS universelle : selon l'État, "demi-heure avant le lever / après le coucher" ou 24 h, etc. [?] -> relève du volet réglementation, pas de celui-ci.

## 10. Fuseaux horaires, unités, attributions

- Les USA couvrent plusieurs fuseaux (Eastern, Central, Mountain, Pacific, Alaska, Hawaii) et l'Arizona (hors Navajo) n'applique pas l'heure d'été. Utiliser le fuseau du point de pêche (via `TimeZone` de l'IANA depuis les coordonnées), jamais celui du téléphone. Les API USGS acceptent des ISO 8601 avec décalage ; NWS renvoie des horodatages ISO avec décalage [?].
- Unités : °F, pieds (ft), ft³/s (cfs), pouces de pluie, mph, livres/pouces pour les poissons. Conversions : °F = °C × 9/5 + 32 ; 1 ft = 0,3048 m ; 1 ft³/s = 0,0283168 m³/s ; 1 in = 25,4 mm ; 1 lb = 0,45359237 kg ; 1 mph = 1,609344 km/h. Utiliser `Measurement`/`UnitTemperature` de Foundation.
- Attributions : USGS (source + avertissement "provisoire"), NOAA/NWS (domaine public, mention de source), Apple Weather (marque + lien).

## 11. Recommandation : socle minimal pour un pilote

1. Hydrologie : API `api.waterdata.usgs.gov` (`latest-continuous`, `continuous` sur 7 jours, `monitoring-locations`), codes 00060/00065/00010, via backend avec cache et clé.
2. Crue : NWPS pour catégories et prévisions de hauteur.
3. Alertes : api.weather.gov (User-Agent), plus WeatherKit pour la météo.
4. Soleil/lune en local ; fuseau du point de pêche ; unités impériales par défaut.
5. Pilote régional (un ou deux États à bon réseau de stations de température) pour valider la couverture.

## 12. Équivalents américains de Hub'Eau (synthèse)

| Besoin FishMe | France | USA |
|---|---|---|
| Hauteur / débit temps réel | Hub'Eau hydrométrie | USGS `continuous` / `latest-continuous` (00065, 00060) |
| Température rivière | Hub'Eau température | USGS 00010 (couverture partielle) |
| Position vs normale | (calcul) | USGS statistiques / WaterWatch |
| Vigilance crue | Vigicrues | NWPS (catégories, prévisions) + alertes NWS |
| Orage / alertes | WeatherKit | api.weather.gov + WeatherKit |
| Marée / estuaire | (mer hors périmètre) | NOAA CO-OPS |

## 13. Points ouverts [?]

- Dates officielles de ralentissement/arrêt de waterservices.usgs.gov (relire les notices USGS avant de figer le planning).
- Quotas chiffrés de la clé USGS (en-têtes `X-RateLimit-*`), taux de stations avec 00010 par État.
- Liste d'événements NWS utiles à notifier ; couverture WeatherKit (alertes, minute par minute) sur les territoires hors des 50 États.
- Règles de pêche par État : hors de ce volet.
