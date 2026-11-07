# FishMe US : sources de règles de pêche en eau douce, État par État

Date : 6 nov. 2026. Volet : sources de règles par État.

**Décision débloquée : choisir 1 à 3 États pilotes pour un portage US de FishMe et savoir quel pipeline (données ouvertes vs lecture IA de PDF) y appliquer. Reco provisoire : Californie (données ouvertes), Minnesota (cartes/plans d'eau, copyright à lever), Washington (appli officielle, prix élevés, bon vivier). Elle doit être confirmée par une 2e passe (voir « Limites »).**

## Limites de cette passe (à lire d'abord)

- Plusieurs sites officiels (myfwc.com, dnr.state.mn.us) ont répondu 403 à WebFetch, et tpwd.texas.gov n'a donné aucun prix. Beaucoup de prix viennent donc d'agrégateurs tiers ou de la presse : ils sont marqués [?].
- Les URLs de règles listées sont celles des agences. Elles n'ont pas toutes été ouvertes dans cette passe : la mention « (non ouverte) » le dit.
- Aucune licence de réutilisation n'a pu être lue en direct pour la plupart des États. Par défaut, on l'écrit [?] : pour un usage commercial, il faudra un courriel à chaque agence.
- Le principe FishMe « verdict jamais permissif » s'applique encore plus ici : les États ont des règles par plan d'eau, des règles spéciales et des avis d'urgence.

## Tableau des États (18)

Colonnes : agence / URL règles eau douce / format / fréquence / permis annuel résident puis non-résident / appli officielle / licence données.

| État | Agence et URL règles | Format | MàJ | Permis rés. / non-rés. | Appli officielle | Réutilisation |
|---|---|---|---|---|---|---|
| CA | CDFW. Données : https://www.lab.data.ca.gov/dataset/freshwater-sport-fishing-regulations et https://catalog.data.gov/dataset/cdfw-fishing-guide | **Open data** (ArcGIS Hub/GeoService, jeu « Freshwater Sport Fishing Regulations »), plus livret PDF [?] | annuelle pour le livret [?] ; fréquence du jeu non lue | [?] (non vérifié) | [?] | catalogue data.gov : licence exacte non lue [?] |
| WA | WDFW. https://www.eregulations.com/washington/fishing/license-fees | site eRegulations + appli ; PDF [?] | licence du 1er avr. 2026 au 31 mars 2027 | 39,95 $ / 115,85 $ (eau douce, adulte) https://www.eregulations.com/washington/fishing/license-fees | « Fish Washington » https://apps.apple.com/us/app/-/id1329839426 | [?] |
| MN | MN DNR. LakeFinder https://www.dnr.state.mn.us/lakefind/ | **Interactif par plan d'eau** (plus de 4 500 lacs et rivières) ; jeux SIG sur gisdata.mn.gov https://gisdata.mn.gov/sr/dataset?tags=site | continue [?] | [?] | [?] | le DNR garde le copyright sur ses cartes de lacs (https://www.mndnr.gov/lakefind) ; données du Geospatial Commons : termes [?] |
| CO | CPW. Fishing Atlas https://ndismaps.nrel.colostate.edu/fishingatlas/definitions.html | carte interactive (atlas) ; couches ArcGIS (ex. eaux « Gold Medal ») dont la licence est restreinte à cet usage ; hub CPW non confirmé | [?] | [?] | [?] | restreinte pour certaines couches, voir ci-contre [?] pour le reste |
| NY | NYS DEC | Interactif : HuntFishNY avec « Tackle Box » par plan d'eau (cité dans https://tvcvps4-do-ny.tvc.mx/talk/which-android-fishing-apps-provide-real-time-information-on-kl3k.html, source faible) | [?] | [?] | HuntFishNY | [?] |
| FL | FWC. https://myfwc.com/fishing/freshwater/ (non ouverte, 403 sur les pages permis) | site + PDF [?] ; règles eau douce dans Fish Rules (partenariat FWC rapporté, source faible) | [?] | 17 $ / 47 $ [?] (agrégateur https://udpwr.com/blogs/lifestyle/florida-fishing-license) | [?] | [?] |
| TX | TPWD. https://tpwd.texas.gov/regulations/outdoor-annual/licenses/fishing | site « Outdoor Annual » découpé en pages (eau douce, eau salée, règles générales) | [?] | [?] (page lue sans prix) | [?] | [?] |
| PA | PFBC. Résumé PDF https://www.pa.gov/content/dam/copapwp-pagov/en/fishandboat/documents/fishing/regulations/summarybook.pdf | **PDF annuel** ; appli FishBoatPA (avis tiers) | annuelle [?] | [?] (fiches tierces peu fiables) | FishBoatPA [?] | [?] |
| MI | MI DNR https://www.michigan.gov/DNRLicenses | site ; achat via appli Hunt Fish https://content.govdelivery.com/accounts/MIDNR/bulletins/40c40a7 | licences 2026 valables jusqu'au 31 mars 2027 (même source) | environ 27 $ / 76 $ [?] (sources tierces) | Hunt Fish (achat de permis) | [?] |
| WI | WI DNR | site [?] | année du 1er avr. au 31 mars [?] | 20 $ / 55 $ [?] (agrégateurs, ex. https://stateoutdoors.org/fishing/Wisconsin-fishing-license/) ; timbres en plus | [?] | [?] |
| OH | ODNR Wildlife | [?] | [?] | [?] | [?] | [?] |
| NC | NCWRC | [?] | [?] | résident 30 $ prévu à 32 $ au 1er juil. 2026 : simple proposition, adoption non vérifiée [?] (source citée dans la recherche : https://tacklevillage.com/?p=8387) | [?] | [?] |
| GA | GA DNR WRD | [?] | [?] | [?] | [?] | [?] |
| VA | VDWR | site + PDF [?] | [?] | statut 12 $ / 30 $ (https://law.lis.virginia.gov/vacode/29.1-310/), contredit par un agrégateur à 23 $ : conflit non tranché [?] | [?] | [?] |
| TN | TWRA | [?] | [?] | [?] | [?] | [?] |
| MO | MDC | [?] | [?] | [?] | [?] | [?] |
| AL | ADCNR | [?] | [?] | [?] | [?] | [?] |
| ID | IDFG | [?] | [?] | [?] | [?] | [?] |
| UT | UDWR | [?] | [?] | [?] | [?] | [?] |
| IN (bonus) | IN DNR https://www.eregulations.com/indiana/fishing/fishing-licenses-fees/ | eRegulations | 1er avr. 2026 au 31 mars 2027 | 23 $ / 60 $ | [?] | [?] |

Autres chiffres repérés (tiers, [?]) : NH non-résident eau douce 63 $ (https://www.eregulations.com/newhampshire/fishing/freshwater/licenses-fees-requirements), MD résident non-tidal 32 $ (https://fishinglicenceusa-com.pages.dev/maryland-fishing-licenses.html), ME résident 30 $ (https://maineguide.com/maine-fishing-license-guide/).

Ordre de grandeur global, selon un guide tiers : environ 25 $ en moyenne pour un résident et 60 $ pour un non-résident (https://tacklevillage.com/?p=8387). Fourchette large, donc [?].

Les lignes OH, NC, GA, TN, MO, AL, ID, UT sont presque vides : elles n'ont pas pu être instruites ici et demandent une passe dédiée. Le critère « au moins 15 États » est donc tenu en nombre de lignes, pas en profondeur de données.

## Données structurées ou PDF seul ?

**Données structurées réutilisables (à confirmer licence par licence)**
- Californie : le seul cas net trouvé. Le jeu « Freshwater Sport Fishing Regulations » est publié en open data (data.ca.gov, relayé par data.gov) avec des services ArcGIS (https://catalog.data.gov/dataset/cdfw-fishing-guide). Le catalogue de métadonnées « Fishing Locations » se trouve aussi sur le site du CDFW (https://filelib.wildlife.ca.gov/public/BDB/GIS/BIOS/metadata/sec/DS2880.html).
- Minnesota : jeu de sites de pêche publics sur le Geospatial Commons (https://gisdata.mn.gov/sr/dataset?tags=site). Une API est mentionnée sur la page de recherche sans endpoint précis. Les règles par lac vivent dans LakeFinder, dont le DNR revendique le copyright des cartes.
- Colorado : atlas interactif et couches ArcGIS sur des serveurs d'État. La licence de la couche Gold Medal limite l'usage.

**Surtout interactif ou PDF (lecture IA nécessaire, comme pour les arrêtés français)** : PA (résumé PDF), et probablement la plupart des autres États [?]. Les plateformes eRegulations (WA, IN, NH) offrent un HTML structuré mais un contenu éditorial dont le droit de reprise n'a pas été lu [?].

**À vérifier** : la présence de règles par plan d'eau (« special regulations ») sous forme de données ouvertes dans TX, FL, NY, MI, WI, OH. Aucune preuve trouvée ici.

## Agrégateurs

- **Fish Rules** (Fish Rules, LLC) : société privée, sans lien avec les agences ; son texte indique que les règles n'ont pas valeur légale. Partenariats rapportés avec le FWC de Floride (eau douce) et les conseils fédéraux du Golfe et de l'Atlantique Sud (https://apps.apple.com/us/app/-/id597875361, https://www.fisherycouncils.org/s/16_fish-rules-mobile-app.pdf). Couverture annoncée surtout eau salée, Maine au Texas plus Californie et Hawaï. Le support est une adresse @fishbrain.com, lien capitalistique non confirmé. Conditions : page https://fishrulesapp.com/privacy ; CGU non lues [?]. Concurrent direct, donc pas une source à reprendre.
- **Fishbrain** : CGU du 3 juin 2025 (loi du Delaware, arbitrage) ; collecte d'identifiants et de localisation (https://tostracker.app/document/fishbraincom-tos, https://fishbrain.com/privacy). Une section « règles de pêche » existe (https://fishbrain.helpshift.com/hc/en/3-fishbrain---social-fishing-forecast-app/faq/378-what-areas-do-fishbrain-s-fishing-regulations-cover), contenu non lu. Aucune API publique repérée [?].
- **onX, FishingBooker** : non instruits dans cette passe (ma recherche n'a couvert que Fishbrain). Rien d'affirmé.
- **Apps d'agences** : WA (Fish Washington), NY (HuntFishNY), MI (Hunt Fish, achat de permis). Toutes sont des concurrents locaux gratuits, avec des règles officielles à jour.

Conclusion sur les agrégateurs : aucun ne semble offrir de données réutilisables sous licence claire. FishMe devrait s'alimenter à la source (agences), comme en France.

## Pistes d'États pilotes

1. **Californie** : les règles d'eau douce y sont en open data (ArcGIS), ce qui supprime la lecture IA de PDF et réduit le risque d'erreur. Grand bassin de pêcheurs [?]. Reste à lire la licence du jeu et la fraîcheur des données.
2. **Minnesota** : culture de la pêche très forte, base par plan d'eau (LakeFinder) et jeux SIG ouverts. Obstacle : copyright du DNR sur les cartes, à lever par un courriel avant tout usage commercial. Pas de chiffre de pêcheurs vérifié ici [?].
3. **Washington** : prix des permis élevés (39,95 $ et 115,85 $), donc forte valeur d'un verdict clair. Règles sur eRegulations et appli officielle déjà présente (concurrence). Données ouvertes non confirmées : à traiter par IA [?].

Le choix reste provisoire : la couverture en nombre de pêcheurs (chiffres de licences vendues) n'a pas été collectée pour ces États [?].

## Prochaines vérifications

1. Lire la licence du jeu CDFW et sa date de mise à jour.
2. Écrire à MN DNR (copyright) et CPW (licence des couches).
3. Instruire OH, NC, GA, TN, MO, AL, ID, UT, ainsi que TX, FL, NY, MI, WI (prix officiels, format, appli).
4. Instruire onX et FishingBooker, et les CGU de Fish Rules.
5. Récupérer les volumes de permis vendus par État pour pondérer le choix.
