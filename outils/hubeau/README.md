# D2 Données Hub'Eau

Fabrique pour la France entière les trois fichiers lus par l'app (jamais commités, publiés en pièce jointe de la release privée `donnees`) :
`stations-especes.json`, `rarete-departements.json`, `stations-hydro.json`. Python 3 seul, aucune dépendance.

## Tout refaire (Mac de Sullyvan)
```
outils/hubeau/lancer.sh            # calcule, puis demande avant d'envoyer
outils/hubeau/lancer.sh --publier  # envoie sans demander
```
Reprise : le cache `outils/hubeau/cache/` garde chaque page reçue (valable 14 jours) ; si la connexion coupe, relancer la même commande.
Prérequis : `python3`, `gh auth status` (connecté). Durée : de l'ordre d'une à plusieurs heures, l'API est lente (voir « Mesures »).

## Options de `hubeau.py`
- `--departement 94` (ou `75 92 93`) : seulement ces départements (les régions non complètes sont marquées `complete: false`).
- `--especes chemin` : `especes.json` de D1 ; sinon le fichier de `Core/Resources` s'il est rempli, sinon `species_source.csv` de Titouan (avertissement affiché).
- `--departements-geojson chemin` : `departements.geojson` de D1 ; sinon celui de `Core/Resources` s'il est rempli, sinon le geojson simplifié de la maquette (avertissement).
- `--verifier-especes` : compare chaque code Sandre au nom latin renvoyé par Hub'Eau (`cache/rapports/especes-verifiees.json`).
- `--recuperer-seulement` (remplit le cache), `--cache-seulement` (aucun appel réseau), `--workers N`, `--max-requetes N`, `--sans-hydro`, `--sortie dossier`.
- Tests : `python3 -m unittest discover -s outils/hubeau/tests`.

## Règles
- Une station = un département, d'après ses coordonnées de station (`coordonnee_x/y_station`, Lambert 93 converti en WGS84) et un point dans un polygone en Python pur ; jamais le `code_departement` de l'API. Un point à moins de 1,5 km d'un polygone (trait de côte ou frontière simplifiés) est rangé dans le plus proche (`stations_rangees_par_bord` dans le rapport) ; au-delà, la station est écartée et listée.
- Une pêche = une opération OFB avec au moins un poisson. `code_operation` est comparé en texte. Les espèces sont jointes par `code_taxon` (code Sandre), les variétés de carpe gardent chacune leur code.
- Des comptes seulement : aucune classe de rareté, aucun seuil, aucun plafond (c'est `Core`, lot L1).
- Fenêtre : du 1er janvier de l'année en cours moins 10 à ce jour, plus tout l'historique.

## Forme des fichiers
En tête de chaque fichier : `source`, `licence` (Licence Ouverte 2.0), `mis_a_jour`.
- `stations-especes.json` : `stations: [{id, lat, lon, dep, eau, code_eau, peches, derniere, vues: {code: n}, historique: {peches, derniere, vues}}]`. `peches`, `derniere`, `vues` = fenêtre de 10 ans ; `historique` = toutes les années (une station sans pêche récente reste, avec son dernier relevé). `eau` = `libelle_entite_hydrographique`, `null` si la station n'a pas de cours d'eau.
- `rarete-departements.json` : `departements: {"94": {region, dix_ans: {peches, especes: {code: {peches, derniere}}}, historique: {...}}}` et `regions: {"11": {nom, dix_ans, historique, complete}}`. Tous les départements du lancement y sont, un département sans pêche avec `peches: 0` ; une espèce jamais vue est absente. Table des régions : INSEE (COG), `regions.json`.
- `stations-hydro.json` : `stations: [{code, nom, eau, code_eau, lat, lon, dep, en_service, debit, debit_site}]`, API hydrométrie v2 (`referentiel/stations`). Aucune mesure. `debit` = la station a publié un débit dans les 3 dernières heures à la date de mise à jour (l'API ne donne pas de drapeau « mesure un débit ») ; `debit_site` = seul le site en publie.

## Mesures sur l'API (15 oct. 2026)
- `size` d'etat_piscicole : au-dessus de 20 000, l'API revient à 5 000 sans erreur ; 20 000 lignes mettent ~41 s (2 champs). La profondeur n'est pas limitée à 20 000 : page 21 de `size=10000` (ligne 200 000) répond. Hydrométrie : `size` ≤ 10 000, erreur explicite au-delà.
- Le temps est proportionnel au nombre de lignes (~2 ms/ligne avec `fields`), 4 appels en parallèle ne se ralentissent pas ; d'où `workers` = 4.
- Chaque point de prélèvement d'une station est une ligne de l'endpoint `stations` : doublons fusionnés par `code_station`.

## Lancé dans le cloud (15 oct. 2026)
- Hub'Eau répond depuis le conteneur cloud (la mention « jamais dans le cloud » ne vaut plus). Lancé avec `--workers 10` (4 au début, puis 10 après reprise par le cache) : environ 1 h 50 au total.
- Entrées : `especes.json` de D1 (99 espèces dont 41 avec code Sandre), contours `gregoiredavid/france-geojson` (`departements-version-simplifiee.geojson`, 96 départements, IGN Admin Express COG 2018, Licence ouverte).
- Comptes : 8 234 stations piscicoles (4 846 avec une pêche sur 10 ans, 6 300 avec un cours d'eau), 96 départements tous présents (75 et 93 sans pêche sur 10 ans), 18 400 pêches sur 10 ans, 37 espèces vues, 3 stations écartées ; 6 159 stations hydro (95 départements).
- Vérification Sandre : 37 codes sur 41 concordent ; 3 jamais vus par Hub'Eau (omble chevalier, huchon, carpe à grosse tête) ; chevesne : nom latin ancien (Leuciscus cephalus), même espèce.
- La release `donnees` n'a pas pu être créée depuis cette session (403 « releases not permitted ») : les fichiers sont dans `/home/user/partage/`.
