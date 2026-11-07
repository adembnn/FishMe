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
Comptes par État (mesurés) : tracés d'ordre ≥ 3 : MN 97 545, WI 72 459 ; plans d'eau ≥ 5 ha : MN 24 799, WI 8 370 ; PAD-US OA/RA : MN 7 491, WI 5 855. Estimation (comté × comptes, non mesurée) : tracés ~25 à 33 Mo, plans d'eau ~6 à 19 Mo, PAD-US ~18 Mo par État. Trop lourd pour l'app : tracés et PAD-US se servent par téléchargement ou tuiles, pas embarqués.

## Format `couches-us-<USPS>.json` et côté app (à faire, pas fait)
`{"format":"fishme-couches-us/1","etat","emprise","emprise_etat","liens_etat","avertissement","couches":[{id,role,nom,geometrie,source,editeur,url_source,licence,date_source,date_lecture,statut,compte,collection:FeatureCollection}]}`. Les points d'accès portent `coin` (`acces` ou `peche`) : même forme que `coins-osm.geojson` lu par `CoinOSM.decoder`.
À changer dans l'app : (1) `CoinPublic.departement` est un `Departement` français : prévoir une zone générique (État/comté) ; (2) un décodeur de ce fichier (`Contour.decoder` ne lit que Polygon/MultiPolygon, pas les lignes ni les propriétés numériques) ; (3) région selon la position (décision 7) ; (4) afficher source, licence, date et avertissement ; jamais « pêche autorisée » ; (5) aucune « station avec relevés » US : pas de recalage ici.

## Payant, sur demande, à confirmer
Rien de payant dans ces couches. Bathymétrie WI en vecteur : payante chez un tiers (non faite). Export en masse des avis EPA : sur demande. RIDB (Corps) : clé gratuite. Licences à demander : MN rampes, WI, MI, copie PAD-US tierce, EPA.
