# US4 : socle géographique d'un État américain (`outils/us/geo/`)

Python 3.9+, bibliothèque standard seulement. Rien de ce dossier ne touche l'app. Les fichiers fabriqués vont dans `sortie/` (ignoré par git) ; seule la fixture de test (27 Ko) est commitée.

## Lancer
    python3 construire_etat.py MN --lister                       # couches, statuts, licences
    python3 construire_etat.py MN                                # sortie/couches-us-MN.json (emprise de l'État)
    python3 construire_etat.py MN --couches acces                # une couche
    python3 construire_etat.py MN --emprise=-94.35,46.45,-94.20,46.60 --sortie /chemin   # échantillon (le « = » est obligatoire)
    python3 verifier_geo.py sortie/couches-us-MN.json [--strict] [--min-objets acces=1000]
    python3 -m unittest discover -s tests          # hors réseau ; FISHME_GEO_RESEAU=1 ajoute un test réel

## Méthode
`etats/_communes.json` (couches nationales : tracés et plans d'eau 3DHP, PAD-US, avis EPA) + `etats/<USPS>.json` (couches de l'État, emprise, liens de l'agence). MN, WI, MI faits ; un nouvel État = un fichier. `arcgis.py` : emprise, puis identifiants (`returnIdsOnly`), puis objets par paquets de 200 en POST (marche sans `resultOffset`), réessais, 0,25 s entre requêtes, User-Agent identifié. `normaliser.py` : une fonction par source (id préfixé, nom, type, scalaires seulement), simplification Douglas-Peucker côté client (certains serveurs ignorent `maxAllowableOffset`), arrondi : points publics 5 décimales, lignes et polygones 4 (PAD-US 3). Chaque couche écrit source, éditeur, URL, licence, date de la source, date de lecture, statut.

Confidentialité : seuls des objets d'agence publics passent ; téléphones, contacts, notes libres, « directions » jamais copiés ; aucun spot de pêcheur n'entre ici. Le vérificateur le contrôle.

## Résultats réels (7 nov. 2026)
- Le service EPA hébergé ne contient que CT, MA, NJ, NY, PA, VT : **aucun avis pour MN, WI, MI** (statut `absent_du_service`, lien vers la page de l'État, [?] non ouverte).
- PAD-US 4.0 : le service USGS hébergé est en 3.0. La 4.0 vient d'une copie tierce (Missouri Botanical Garden), non officielle ; seules les terres Fee, accès ouvert ou restreint. Elle dit qu'une terre est publique, jamais que la pêche y est permise.
- Licences : aucune n'est lue sur les services ; toutes marquées [?] (`--strict` les refuse). MN rampes : « non précisée », à demander au DNR.
- Pas d'empoissonnement trouvé pour MN et MI ; WI oui.

## Tailles mesurées (JSON compact)
Rampes et accès, État entier : MN 3 018 objets, 1,01 Mo ; WI 3 108 + 138 rives, 0,87 Mo ; MI 1 203, 0,32 Mo. Empoissonnement WI : 1 398 lacs 1,98 Mo + 642 cours 1,69 Mo.
Échantillon d'un comté (Vilas WI, boîte 1,05° × 0,55°, toutes couches) : 1,60 Mo, 2 472 objets, 47 s. Échantillon 0,15° MN : 0,06 Mo.
Comptes par État (mesurés ; MI non mesuré, le comptage des tracés sur toute l'emprise n'a pas abouti) : tracés d'ordre ≥ 3 : MN 97 545, WI 72 459 ; plans d'eau ≥ 5 ha : MN 24 799, WI 8 370 ; PAD-US OA/RA : MN 7 491, WI 5 855. Estimation (comté × comptes, non mesurée) : tracés ~25 à 33 Mo, plans d'eau ~6 à 19 Mo, PAD-US ~18 Mo par État. Trop lourd pour l'app : tracés et PAD-US se servent par téléchargement ou tuiles, pas embarqués.

## Format `couches-us-<USPS>.json` et côté app (à faire, pas fait)
`{"format":"fishme-couches-us/1","etat","emprise","emprise_etat","liens_etat","avertissement","couches":[{id,role,nom,geometrie,source,editeur,url_source,licence,date_source,date_lecture,statut,compte,collection:FeatureCollection}]}`. Les points d'accès portent `coin` (`acces` ou `peche`) : même forme que `coins-osm.geojson` lu par `CoinOSM.decoder`.
À changer dans l'app : (1) `CoinPublic.departement` est un `Departement` français : prévoir une zone générique (État/comté) ; (2) un décodeur de ce fichier (`Contour.decoder` ne lit que Polygon/MultiPolygon, pas les lignes ni les propriétés numériques) ; (3) région selon la position (décision 7) ; (4) afficher source, licence, date et avertissement ; jamais « pêche autorisée » ; (5) aucune « station avec relevés » US : pas de recalage ici.

## Payant, sur demande, à confirmer
Rien de payant dans ces couches. Bathymétrie WI en vecteur : payante chez un tiers (non faite). Export en masse des avis EPA : sur demande. RIDB (Corps) : clé gratuite. Licences à demander : MN rampes, WI, MI, copie PAD-US tierce, EPA.

## US11 : fichiers embarqués (`embarquer.py`)
Fabrique les fichiers simplifiés de `Packages/Core/Sources/Core/Resources/geo-us/` (un par État et par couche, JSON compact en tableaux ; format `fishme-geo-us/2`), lus par `Core/GeoUS/`.

    python3 construire_etat.py WI --couches acces,peche_rive --sortie /chemin/brut      # points d'accès de l'agence (étape 1)
    python3 embarquer.py WI --brut /chemin/brut --sortie ../../../Packages/Core/Sources/Core/Resources/geo-us

`--brut` reçoit aussi `contour-<USPS>.json` (anneaux de l'État, TIGERweb, téléchargé au premier passage) et les téléchargements 3DHP (`plans-eau-`, `lignes-eau-`), hors de git ; le second passage les relit sans réseau. Couches : `<USPS>-points.json` (accès publics, type rampe, quai, accès public, autre ; chaque source dit « accès public listé par <agence> »), `-plans-eau.json` (plans d'eau nommés d'au moins 5 ha : centre et rayon du cercle de même surface, pas de contour), `-lignes-eau.json` (tronçons nommés d'ordre 4 et plus, simplifiés à 200 m), `-avis.json` (avis EPA s'il y en a ; sinon un seul renvoi daté vers la page de l'agence), `etats.json` (contours à 0,01° pour `GeoUS.etat(pour:)`).

Mesuré le 7 nov. 2026 (3DHP, service USGS) : WI 3 246 points, 4 014 plans d'eau, 17 416 tronçons ; MN 3 018, 7 656, 17 764 ; MI 1 203, 4 277, 14 327 ; total 5,4 Mo (limite 25 Mo). Les plans d'eau des Grands Lacs font répondre 500 au serveur 3DHP : téléchargement par paquets de 50 avec généralisation de 0,002°. Les objets des États voisins pris par la boîte englobante sont retirés avec le contour TIGERweb ; un tronçon qui touche l'État est gardé en entier. Les pages d'agence MN (LakeFind) et MI répondent 403 aux scripts (non confirmées dans un navigateur) ; celles de WI répondent 200.
Autres États : non faits (un État de plus = un `etats/<USPS>.json` avec sa couche d'accès, puis `embarquer.py`) ; PAD-US et bathymétrie restent hors de l'app.
