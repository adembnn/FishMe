# Rareté américaine (lot US-rarete)

Calcul de la rareté d'un poisson aux États-Unis à partir d'événements d'échantillonnage. Deux implémentations qui doivent donner le même résultat : Swift (`Packages/Core/Sources/Core/RareteUS/`, tests dans `Packages/Core/Tests/CoreTests/RareteUS/`) et Python (`rarete_us.py`, bibliothèque standard, Python 3.9+). Rien n'est branché dans l'app.

## Définitions
- **Événement** : une pêche scientifique (un site, un jour, un engin). Colonnes du CSV : `evenement_id, huc8, etat, milieu, engin, annee, source, especes` (voir l'en-tête de `rarete_us.py`). Aucune coordonnée, jamais. Un événement sans poisson reste dans le fichier (il compte au dénominateur).
- **Fréquence** = événements avec l'espèce ÷ événements totaux, dans une **strate** (milieu × engin) et un **échelon**.
- **Échelon** : HUC8 s'il a au moins N événements (N = 20 au départ, à fixer sur l'État pilote), sinon HUC6, sinon l'État ; l'échelon utilisé est écrit dans chaque sortie (`echelle`, `code_echelle`).
- **Classes** : commun, peu commun, rare, donnée insuffisante. **Pas de « légendaire »** : une absence de donnée n'est pas une rareté. Une espèce jamais vue dans un échelon fourni sort « donnée insuffisante, non observée ».
- **Seuils par quantiles** (pas ceux de l'OFB) : on prend les fréquences des cellules fiables (espèce vue × HUC8 d'au moins N événements) de la strate ; rare sous le tiers inférieur, commun à partir des deux tiers (quantile de type 7, paramétrable). Moins de 10 cellules : seuils non calibrés, donnée insuffisante. Des seuils fixes existent pour tester (`--fixes`), jamais par défaut.
- Chaque ligne porte `n_evenements_espece`, `n_evenements_total`, `derniere_annee` et `sources`.

## Pièges
- **Biais d'échantillonnage** : les agences pêchent là où elles cherchent une espèce ; un site de suivi de truite gonfle la truite. Les sites NRSA, tirés au hasard, sont moins biaisés mais peu nombreux par HUC8.
- **Événements vides absents** : le Water Quality Portal ne contient que des événements avec résultats, donc la fréquence y est gonflée.
- **Natives et introduites** : le statut dépend du bassin (même poisson natif d'un côté, introduit de l'autre). La fréquence ne le dit pas ; il faut un statut par HUC ou État (USGS NAS).
- **Engins** : électropêche, filets, seine ne capturent pas les mêmes espèces ; les strates les séparent. Un engin inconnu forme sa propre strate.
- **Poissons stockés** : une truite lâchée peut sembler commune.
- Le repli HUC6 ou État lit une fréquence plus large que le lieu de l'utilisateur, d'où l'échelle affichée.
- Les seuils HUC8 servent aussi aux replis : à vérifier au pilote.
- Séries qui s'arrêtent (Wisconsin 2014 d'après le rapport) : la dernière année reste affichée.

## Conditions pour afficher la rareté
1. Calibrage des seuils et du minimum d'événements sur un État pilote.
2. **Revue par un biologiste d'agence** (`revueBiologisteValidee`, faux par défaut ; sans elle `affichageRarete` reste faux).
3. Avant la revue : seulement la présence connue (`libellePresence` : nombre d'événements, dernière année, source), jamais un niveau.

## Utilisation
```
python3 rarete_us.py evenements.csv -o sortie.csv        # mêmes colonnes que exemples/attendu-fixture.csv
python3 alimenter_csv.py sources                          # comment alimenter le CSV (NRSA, WQP, agence d'État)
python3 alimenter_csv.py wqp Result.csv Station.csv -o evenements.csv
python3 fabriquer_fixture.py                              # régénère la fixture
```
Fichiers de `exemples/` : `evenements-fixture.csv` et `attendu-fixture.csv` sont une **FIXTURE synthétique** (fréquences inventées, ne rien en conclure ; `attendu` sort de Python et le test 18 de Swift le relit) ; `exemple-reel-wqp-wi-2012.csv` est réel mais minuscule : 4 événements du Water Quality Portal (organisation STOCKBRIDGE_MUNSEE, Wisconsin, HUC8 04030202, été 2012, 19 taxons), converti par `alimenter_csv.py wqp`. Avec N = 20 il donne « donnée insuffisante » partout, ce qui est le comportement voulu.
