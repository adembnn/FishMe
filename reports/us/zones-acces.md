# FishMe US : zones de pêche et accès public

Date : 7 nov. 2026
Décision débloquée : choisir le socle de données géographiques à ingérer pour un État pilote américain (tracés, accès, terres publiques, avis sanitaires), et savoir ce que l'app ne pourra PAS affirmer (droit d'accès légal à une rive, équivalent des stations OFB).

Légende : [?] = non vérifié. Aucun chiffre non sourcé. Recherche web par résumés de moteur : les pages de téléchargement n'ont pas toutes été ouvertes (voir « Limites »).

## 1. Sources ouvertes

### 1.1 Tracés de cours d'eau et plans d'eau (USGS)
| Source | URL | Format / accès | Notes |
|---|---|---|---|
| NHD, NHDPlus HR, WBD | https://www.usgs.gov/NHD/DataAccess | Géodatabases fichier zippées par région (vecteur), 7z (raster) ; sélection par zone via https://apps.nationalmap.gov/downloader | NHDPlus HR embarque aussi NHD et WBD. Release nationale 2 (fév. 2025) : régions 01, 02, 13, 14, 15 et quelques HU8 d'Alaska mis à jour. |
| 3DHP (successeur) | https://www.usgs.gov/3d-hydrography-program/access-3dhp-data-products | Téléchargement ; service ArcGIS REST https://hydro.nationalmap.gov/arcgis/rest/services/3DHP_all/MapServer ; GeoPackages par État sur ScienceBase https://www.sciencebase.gov/catalog/item/6797c2c0d34e2b4e5ebcb482 | Depuis 2024 l'USGS produit du 3DHP et n'entretient plus NHD/WBD/NHDPlus HR. Couverture nationale 3DHP encore à plusieurs années : NHD/NHDPlus HR servent de pont (https://www.usgs.gov/media/videos/understanding-transition-nhdplus-hr-3dhp). Collection : https://catalog.data.gov/dataset/usgs-3d-hydrography-program-3dhp-downloadable-data-collection |
- Licence : produits fédéraux, domaine public en principe [?, à confirmer par jeu]. Tailles par région ou État : [?].
- Équivalent FR : tracé Sandre (BD Topage). NHDPlus HR ajoute des identifiants de tronçon (NHDPlusID) et des attributs de débit, utiles pour recaler des stations.
- Décision à prendre : prendre NHDPlus HR (complet, stable, mais figé) ou 3DHP là où l'État pilote est déjà publié.

### 1.2 Points d'accès et rampes
Aucun jeu national unifié et fiable trouvé : c'est un patchwork État par État.
- Minnesota (exemple vérifié) : Public Water Access Sites, DNR, https://gisdata.mn.gov/ru/dataset/struc-water-access-sites ; fgdb, gpkg, SHP ; modifié le 2025-12-06 ; service live https://gis.dnr.state.mn.us/appserver/rest/services/webGDRS/loc_water_access_sites/MapServer ; champs type de surface de rampe, nombre de rampes et de quais ; licence « non précisée » sur la page. Couverture partielle : le DNR dit avoir construit et entretenir la moitié des 3 000 rampes publiques (https://dnr.state.mn.us/fisheries/management/access.html).
- New York : lancements DEC sur le NYS GIS Clearinghouse ; couche ArcGIS « Trout Stream Fishing Access » (https://services6.arcgis.com/DZHaqZm9cxOD4CWM/ArcGIS/rest/services/Trout_Stream_Fishing_Access/FeatureServer) ; jeu « Recommended Fishing Rivers And Streams » en CSV/JSON/XML (https://catalog.data.gov/dataset/recommended-fishing-rivers-and-streams). Licences : [?].
- Army Corps : pas de jeu de rampes dédié trouvé. Passage par RIDB (Recreation Information Database), API https://ridb.recreation.gov/api/v1, clé gratuite à demander (en-tête apikey) ; catalogue https://catalog.data.gov/dataset/recreation-information-database-ridb-58364. Le Corps cite environ 3 700 rampes en agrégat (https://www.swf-wc.usace.army.mil/Waco/Information/2015USACEStats.pdf) mais pas au point. Filtrage « rampe » dans RIDB : [?].
- USFWS : limites de refuges (cadastre « FWS Interest », https://data.commerce.gov/node/241401) ; points d'accès par refuge : [?].
- Agrégateurs tiers de rampes (ex. Apify) : non retenus, qualité et licence inconnues.

### 1.3 Terres publiques
- PAD-US 4.0 (USGS) : https://sciencebase.gov/catalog/item/652ef930d34edd15305a9b03 ; DOI 10.5066/P96WBCHS ; inventaire complet en zip de 1,59 Go ; géodatabase avec 5 classes (Fee, Designation, Easement, Marine, Proclamation) plus Combined, 36 attributs ; domaine public. Statut GAP et statut d'accès public sont des attributs [?, noms exacts à lire dans le manuel PAD-US]. Version GeoPackage : non confirmée.
- BLM : Surface Management Agency (SMA) national, services sur gis.blm.gov (ex. https://gis.blm.gov/arcgis/rest/services/lands/BLM_Natl_SMA_Cached_BLM_Only/MapServer) ; des extraits d'État en Shapefile/GeoJSON/CSV/FGDB sur data.gov (https://catalog.data.gov/dataset/blm-ca-land-status-surface-management-agency). Avertissement des métadonnées : ne pas s'en servir pour dessiner les limites de forêts, parcs ou refuges.
- Forest Service : EDW, https://apps.fs.usda.gov/arcx/rest/services/EDW/EDW_ForestSystemBoundaries_01/MapServer ; couche SMA https://apps.fs.usda.gov/ArcX/rest/services/EDW/EDW_SMABoundary_01/MapServer ; page de téléchargement https://data.fs.usda.gov/geodata/edw [?, non ouverte].
- NPS : limites et parcelles (Land Resources Division), mirroirs https://data.amerigeoss.org/dataset/nps-tracts1 ; usage administratif, pas de précision d'arpentage ; licence « non précisée » ; source primaire à confirmer (IRMA) [?].
- Limite structurelle : PAD-US dit qu'une TERRE est publique, pas qu'on peut atteindre l'eau (enclaves, route absente), ni que la pêche y est permise.

### 1.4 Lacs et bathymétrie
- Minnesota : « Lake Bathymetric Outlines, Contours, and DEM » (DNR Fisheries), https://gisdata.mn.gov/ru/dataset/water-lake-bathymetry ; géodatabase (contours, DEM, contours de lac, végétation aquatique) ; environ 1 900 lacs ; relief ombré par tranches de 5 pieds https://gisdata.mn.gov/ru/dataset/water-lake-bathy-shaded-relief ; fiches par lac : https://www.dnr.state.mn.us/lakefind/index.html (format des cartes LakeFinder [?]). Gratuit, vecteur : le meilleur cas trouvé.
- Wisconsin : cartes de profondeur surtout en PDF numérisés via DNR « Find a Lake » (https://dnr.wi.gov/lakes/findalake/), parfois très anciennes ; pas de vecteur officiel gratuit trouvé (source : https://www.sco.wisc.edu/maps/lake). Jeu de recherche en CSV (aire par profondeur, plus de 750 lacs MN et WI) : https://geo.btaa.org/catalog/13020-f3xa-5h34. Des vecteurs payants par lac existent chez un tiers [?].
- New York : « DEC Lake Contour Maps » cités par un tiers, nature bathymétrique non confirmée [?].

### 1.5 Avis de consommation de poisson
- EPA NLFWA : https://catalog.data.gov/dataset/national-listing-of-fish-and-wildlife-advisories-nlfa ; portail https://fishadvisoryonline.epa.gov ; métadonnées au 16 mars 2024.
- Couche ArcGIS lignes : https://services2.arcgis.com/okXm0pb6aWH6XOGI/ArcGIS/rest/services/EPA_Fish_Consumption_Advisory_line/FeatureServer ; jointure par numéro d'avis vers la table d'avis.
- Export en masse : l'EPA renvoie vers une demande au programme. Pas de bulk libre trouvé [?]. Les avis sont émis par États et tribus : la page de l'État fait foi, l'EPA agrège avec retard. L'app doit afficher la date et renvoyer à l'État.

### 1.6 Empoissonnements
- Wisconsin : service ArcGIS annuel https://dnrmaps.wi.gov/arcgis2/rest/services/FM_WFF/FH_ANNUAL_STOCKING_SUMMARY/MapServer (polygones et lignes, 15 ans d'historique, année en cours publiée après vérification) ; interface https://apps.dnr.wi.gov/fisheriesmanagement/Public/Summary. Licence [?].
- Pennsylvanie : couche PFBC sur PASDA (https://services.pasda.psu.edu/server/rest/services/pasda/PAFishBoat/MapServer) avec événements d'empoissonnement de truites ; accès public et licence non confirmés [?].
- Autres États : surtout des calendriers web non structurés [?]. Pas de source nationale.

### 1.7 Statut d'accès légal (stream access)
Aucune base nationale ne dit « on peut pêcher ici légalement ». Le droit est étatique. Les sources trouvées sont en grande partie journalistiques ou militantes ; la typologie ci-dessous est ma synthèse de travail, pas une classification juridique publiée [?]. Cinq régimes :
1. Droit d'usage large : toute eau praticable en loisir, jusqu'à la laisse des hautes eaux, même sur lit privé, sans droit de traverser les terres (Montana, arrêt Curran 1984 ; loi 1985).
2. Lit public si navigable pour titre (test fédéral) : l'État possède le lit, le public l'utilise (Oregon, selon American Whitewater) [?].
3. Test de navigabilité de loisir ou saisonnier : public si flottable une grande partie de l'année (Californie, Arkansas selon les sources).
4. Servitude de flottage : usage public d'eaux navigables de fait sans que le lit soit public [?, États à identifier].
5. Riparien par défaut : lit privé jusqu'au milieu, accès soumis au propriétaire, exceptions étroites (Colorado, arrêt 2023 ; Idaho décrit comme restrictif).
Sources : https://www.mtpr.org/montana-news/2022-12-21/what-inspired-montanas-exceptionally-strong-stream-access-laws ; https://www.boisestatepublicradio.org/environment/2023-06-12/colorado-supreme-court-upholds-narrow-stream-access-laws-a-total-outlier-in-the-mountain-west ; https://americanwhitewater.org/content/Wiki/access:mt ; https://www.roselawfirm.com/news/public-stream-access-in-arkansas. Revue savante signalée : Osborne 2003 (état par état) [?, non ouverte].
Conséquence produit : même dans un État à accès large, les accès publics (ponts, rampes, terres publiques) sont ce que l'app peut montrer ; ne jamais écrire « pêche autorisée ici ».

## 2. Équivalent américain d'une « station avec relevés » OFB
Rien n'est identique : les inventaires de poissons américains sont répartis entre agences d'État.
- USGS Water Data OGC API (stations « monitoring-locations ») : https://api.waterdata.usgs.gov/ogcapi/v0/ ; clé gratuite https://api.waterdata.usgs.gov/signup ; limites par IP et par clé ; au-delà d'environ 250 sites par requête, erreur 403 rapportée par un utilisateur [?]. Ce sont des jauges (débit, niveau, température selon site), pas des pêches. Les services NWIS historiques sont en fin de vie ; une date de fermeture du 22 février 2027 vient d'un tiers [?].
- Water Quality Portal (USGS + EPA) : https://www.usgs.gov/tools/water-quality-portal ; plus de 680 000 enregistrements d'abondance de poissons sur plus de 13 000 sites (BioData + STORET, chiffre de 2015, probablement dépassé) ; sans compte ; certains jeux biologiques publiés environ un an après collecte. C'est le plus proche d'une « station avec espèces relevées », mais à couverture inégale. La licence n'est pas indiquée sur les pages trouvées [?].
- Meilleur équivalent réel : les relevés des agences d'État (électropêche, filets) [?, non cherché État par État] et les listes d'empoissonnement (1.6). Pas de « rareté par département » possible au national.
- Recalage : le principe FR (recaler sur le tracé, 300 m) s'applique avec les NHDPlusID, car WQP et NWIS donnent latitude et longitude, et certains jeux EPA sont rattachés au Reach Address Database.
- Reformulation : « station US » = jauge USGS (conditions) + zone empoissonnée ou lac suivi par l'État (présence probable). Ce n'est pas la même promesse que « espèces relevées ».

## 3. Gratuit ou sur demande
| Jeu | Accès | Taille |
|---|---|---|
| NHDPlus HR / NHD, 3DHP | Gratuit | [?] par région ou État |
| PAD-US 4.0 | Gratuit | 1,59 Go zippé |
| BLM, Forest Service | Gratuit (services, extraits) | [?] |
| NPS, USFWS | Gratuit, licence non précisée | [?] |
| Rampes MN | Gratuit (3 formats) | [?] |
| Bathymétrie MN | Gratuit | [?] |
| Bathymétrie WI | PDF gratuits ; vecteur payant chez un tiers | [?] |
| Stocking WI | Gratuit (service ArcGIS) | [?] |
| USGS Water Data API | Gratuit, clé facultative, quotas | n/a |
| RIDB | Gratuit, clé à demander | n/a |
| Avis EPA | Couche ArcGIS gratuite ; bulk sur demande | [?] |
Payant ou sur demande : vecteurs de lacs WI chez un tiers, export en masse des avis EPA, états sans portail ouvert. Licences « non précisées » (MN rampes, NPS) : à demander avant de redistribuer dans l'app.

## 4. Recommandation : socle minimal pour un État pilote
Critère : données complètes, vecteurs gratuits, pêche d'eau douce importante.
- Candidat principal : Minnesota. Seul État où j'ai trouvé rampes (3 formats), bathymétrie vecteur de ~1 900 lacs, tracé via 3DHP/NHDPlus HR, et terres publiques via PAD-US. Wisconsin donne en plus l'empoissonnement en service ArcGIS, mais ses cartes de lacs sont des PDF. Choix entre MN et WI à trancher avec le jeu de points d'accès WI [?, non cherché].
- Socle (5 couches) : 1) tracé NHDPlus HR ou 3DHP de l'État ; 2) rampes et accès de l'État ; 3) PAD-US filtré à l'État (accès public et statut) ; 4) bathymétrie ou fiches de lacs de l'État ; 5) avis de consommation (lien vers l'État, avec date).
- Ajouts si le temps le permet : stations USGS (conditions) et empoissonnement.
- À ne pas faire en v1 : promettre l'accès légal à un cours d'eau, afficher une rareté, fusionner 50 États.
- Pipeline : un script par État qui produit un fichier compact, comme `donnees.sh` en France ; PAD-US (1,59 Go) se filtre hors de l'app, jamais embarqué.

## Limites
Résumés issus de recherches web ; je n'ai pas ouvert les pages de téléchargement ni mesuré les tailles. Licences à confirmer jeu par jeu. La typologie des 5 régimes est une synthèse à faire valider par un juriste avant tout texte affiché.

## Résumé
1. Tracés : NHDPlus HR gratuit en géodatabases ; 3DHP est le successeur mais pas encore national.
2. Accès/rampes : pas de jeu national ; patchwork d'États (MN très bon, NY partiel, Corps via RIDB).
3. PAD-US 4.0 : 1,59 Go, domaine public ; dit si la terre est publique, pas si on atteint l'eau.
4. Aucun jeu ne donne l'accès légal : 5 régimes d'État, à ne jamais présenter comme « autorisé ».
5. Bathymétrie : MN vecteur gratuit (~1 900 lacs) ; WI en PDF ; NY non confirmé.
6. Avis sanitaires : couche EPA mais l'État fait foi ; bulk sur demande.
7. Empoissonnement : WI en service ArcGIS ; PA partiel ; pas de source nationale.
8. Équivalent « station avec relevés » : aucun exact ; jauge USGS (conditions) + WQP/BioData (poissons, inégal).
9. Gratuit presque partout ; licences « non précisées » pour MN rampes et NPS.
10. Recommandation : pilote Minnesota (5 couches), sans promesse d'accès légal ni rareté.
