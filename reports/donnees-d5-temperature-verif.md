# D5 (stations recalées) et température de l'eau : vérification du 20 oct. 2026

Branche `lot/compile-20oct`. Données générées dans le scratchpad (`.../scratchpad/d5/`), rien commité (`git status` : aucun fichier fabriqué ; `App/Donnees/` est ignoré).

## Résumé simple
Le recalage marche de bout en bout, mais le fichier de la release `donnees` (publié le 15 oct.) est l'ancien : il n'a pas de champ `recalee`. Il faut le republier recalé. Pour la température : 24 stations en service, mais le vérificateur refuse le fichier tel quel (22 stations de La Réunion).

## (1) Critères 2, 3, 4 de la fiche D5
- Critère 2 (10 stations Charenton/Marne sur l'eau, capture) : la partie "sur l'eau" est vérifiable par script, la capture non (visuelle). Dans le 94, 15 stations : 13 `recalee: true` (Marne x5 dont 2 "Bras de la Marne", Seine x2, Yerres, Reveillon x3), 2 `false` sans cours d'eau (03063294, 03063801). Station 03112480 (Marne à Charenton) : 48.8169, 2.41963, `La Marne`, true.
- Critère 3 (station "rue de Cécile") : non vérifiable par script, la fiche ne donne aucun identifiant. À donner par Adem. Garantie du script : une station est soit `true` à 300 m max du tracé de son cours d'eau, soit `false` (halo).
- Critère 4 (release publiée, `donnees.sh` la télécharge, app compile) : `donnees.sh` télécharge bien. Mais le fichier publié est pré-D5 :
```
$ bash scripts/donnees.sh   -> ✓ stations-especes.json ✓ rarete-departements.json ✓ stations-hydro.json ; ⚠ stations-temperature.json absent (facultatif)
$ gh release list           -> Données Hub'Eau  Latest  donnees  2026-10-15T22:52:07Z
$ python3 -I outils/verifier_donnees.py --stations App/Donnees/stations-especes.json ...
ERREUR App/Donnees/stations-especes.json : 8234 station(s) sur 8234 sans champ recalee (booléen)
```
Compilation de l'app : non testée (pas de swift build, consigne).
- Critère 1 et 5 : tests `python3 -I -m unittest discover -s outils/hubeau/tests` = 46 tests OK ; `python3 -I outils/test_verifier_donnees.py` = 20 tests OK ; `git status` : seulement 2 rapports d'autres agents, aucun fichier de données.

## (2) Recalage de bout en bout (France, avec les données de `donnees.sh`)
Commande (réseau libre : Sandre WFS, HTTP 200 ; aucune clé) :
```
python3 -I outils/hubeau/recalage.py App/Donnees/stations-especes.json <scratchpad>/d5/france.json --dossier <scratchpad>/d5/trace
```
Durée 63 min 27 s (139 paquets de cours d'eau + 1114 cellules de voisinage, une requête à la fois). Sortie :
```
"stations": 8234, "recalees": 7921, "non_recalees": 313,
"raisons_false": {"sans_cours_d_eau": 188, "code_et_nom_absents_du_trace": 6, "trop_loin": 37, "plan_d_eau": 0, "voisin_sans_nom": 82},
"ecart_median_m": 0.7, "ecart_max_m": 293.5, "seuil_m": 300.0
```
Vérificateur sur le résultat :
```
france.json : 7921/8234 recalées (96.2%) ; échantillon 20/20 à 50 m au plus du tracé   (aucune ERREUR sur ce fichier)
```
Contrôles à part : 8234 stations avec `recalee`, 0 `true` à 2 décimales, 0 station supprimée. Essai du 94 seul : 31 s, 13/15 recalées, écart max 0,7 m (le vérificateur y dit 86,7 % < 90 %, normal sur 15 stations : le seuil vaut pour la France).
Remarque : écart médian 0,7 m. Les coordonnées de Hub'Eau étaient déjà sur le tracé ; le recalage corrige surtout l'arrondi 0,01° de l'ancien fichier.

## (3) Température de l'eau : stations en service (30 jours)
Commande (16 s, Hub'Eau) : `python3 -I outils/hubeau/stations_temperature.py --sortie <scratchpad>/d5/stations-temperature.json`
```
stations : 872 / 872
mesures depuis le 2026-09-20 : 9846 lignes, 24 stations
872 stations, 24 en service (mesure depuis le 2026-09-20)
```
Test : `test_stations_temperature.py` 10 tests OK. 24 attendues, 24 obtenues. Liste (code dep cours d'eau) :
03053310 45 La Clery ; 03057000 45 L'Ouanne ; 03193520 28 La Blaise ; 04049625 45 Bec d'Able ; 04051650 45 l'Ardoux ; 04068550 18 la Petite Sauldre ; 04070215 36 le Nahon ; 04070300 41 le Cher ; 04072150 37 la Roumer ; 04091250 36 la Bouzanne ; 04096430 36 l'Anglin ; 04097050 37 l'Esves ; 04105680 28 l'Ozanne ; 04105800 28 la Conie ; 04108000 41 le Loir ; 04108050 41 le Boulon ; 05015900 16 La Touvre ; 05018000 16 La Charente ; 05019930 16 La Bonnieure ; 05022400 16 L'Argent-Or ; 05024300 16 La Charente ; 06076720 01 Le Furans ; 06166000 84 La Durance ; 06184800 34 L'Orb.
Aucune dans le 94 (la Marne à Charenton, 03112480, est dans le fichier mais hors service).

Commandes de publication (NON lancées), depuis un ordinateur avec `gh` connecté :
```
# température (4e fichier facultatif)
python3 outils/hubeau/stations_temperature.py        # écrit outils/hubeau/sortie/stations-temperature.json (ignoré par git)
gh release upload donnees outils/hubeau/sortie/stations-temperature.json --clobber
# stations recalées : le fichier doit s'appeler stations-especes.json
cp <scratchpad>/d5/france.json outils/hubeau/sortie/stations-especes.json
gh release upload donnees outils/hubeau/sortie/stations-especes.json --clobber
```
Puis `bash scripts/donnees.sh` sur chaque ordinateur. (Alternative : `outils/hubeau/lancer.sh --publier`, qui refait tout, environ 2 h de plus, et publie les 3 fichiers.)

## (4) Écarts avec la fiche et à décider
1. Release `donnees` pré-D5 : sans `recalee`. À republier (commande ci-dessus). Tant que ce n'est pas fait, le vérificateur général sort en ERREUR sur `App/Donnees/`.
2. `verifier_donnees.py` refuse `stations-temperature.json` : 22 stations de La Réunion (dep 974, lat -21, lon 55) sont "hors France métropolitaine" ; aucune n'est en service. Sans correction, `python3 outils/verifier_donnees.py` sort en erreur après publication. Options : (a) `stations_temperature.py` écarte les dep 97x ; (b) le vérificateur les tolère. Recommandation : (a), l'app n'a que la métropole. Je n'ai rien modifié (périmètre : un seul fichier).
3. Fiche : "Les 10 stations autour de Charenton" : le 94 en compte 15 (13 recalées). Le "10" est approximatif.
4. Fiche : `scripts/donnees.sh` "ne change pas" ; il a pourtant gagné le 4e fichier facultatif (lot N3). Sans conséquence.
5. Le seuil 90 % est respecté en France (96,2 %). 313 `false` : 188 sans cours d'eau, 82 voisin sans nom, 37 trop loin, 6 absents du tracé.
6. Critères 2 (capture) et 3 (rue de Cécile) : nécessitent un regard humain ou un identifiant de station.
