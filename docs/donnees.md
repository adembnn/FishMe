# Données embarquées dans l'app

Version du 12 oct., 17h. Tiré de `reports/donnees.md` (sources, appels réels, schéma) et corrigé par `reports/eval-mwm.md` et `reports/eval-apple.md`.

## Les fichiers
Tous dans `Packages/Core/Sources/Core/Resources/`. « Saisi » = commité ; « fabriqué » = sorti du script, jamais commité, téléchargé par `scripts/donnees.sh`.
| Fichier | Étapes | Source | Licence et obligation | Nature | Qui, quand |
|---|---|---|---|---|---|
| `departements.geojson` | E2 E5 E6 | [france-geojson](https://github.com/gregoiredavid/france-geojson) (IGN Admin Express, version simplifiée) | Licence Ouverte : citer IGN et INSEE | saisi (téléchargé) | C, avant jeudi |
| `coins-osm.geojson` | E1 | OpenStreetMap, requête Overpass de `reports/donnees.md` §1 | ODbL : « © contributeurs OpenStreetMap » et lien, fichier gardé à part | saisi (exporté) | C, avant jeudi |
| `coins-maison.json` | E1 E2 | fédération 75/92/93/94 et arrêtés | à nous | saisi, 30 à 60 coins d'accès public | C, avant jeudi |
| `regles.json` | E2 E5 | Légifrance R436-6, -7, -13, -14, -18, -21 et arrêtés des 5 départements | Licence Ouverte (Légifrance) ; arrêtés : actes publics | saisi, schéma de `reports/donnees.md` §4 | C, avant jeudi, relu par une 2e personne |
| `especes.json` | E2 E5 E6 | 14 espèces de `reports/donnees.md` §3 (TAXREF, codes Sandre) | Licence Ouverte | saisi | C, avant jeudi |
| `saisons-montages.json` | E3 | avis, relu par un pêcheur | à nous | saisi | C, relu par un pêcheur de l'équipe, version suivante |
| `cas-verdicts.json` | E5 | les 5 cas de ce document, réponses confirmées contre les arrêtés | à nous | saisi, sert aux tests de L1 et L3 | C, avant jeudi |
| `credits.json` | page « Sources » | les lignes de ce tableau | reprend les mentions exigées ci-dessus (OSM, IGN et INSEE, OFB) | saisi | C |
| `silhouettes/*.svg` | E2 E5 | dessinées par nous, un seul trait, un seul profil | à nous | saisi | à caler avec le fil Maquettes |
| `stations-especes.json` | E1 E2 | [Hub'Eau Poissons](https://hubeau.eaufrance.fr/page/api-poisson) | [Licence Ouverte 2.0](https://www.data.gouv.fr/dataservices/hubeau-etat-piscicole-des-rivieres) : citer OFB et Hub'Eau, avec la date | fabriqué | script D2 |
| `rarete-departements.json` | E2 E6 | idem | idem | fabriqué | script D2 |

Écartés : BD TOPAGE (1,3 Go, rien sur le droit de pêche), FishBase (non commercial), photos Commons CC BY-SA.

## Règles d'affichage (pour ne jamais présenter une donnée mince comme solide)
- Chaque espèce d'un coin et chaque rareté affichent « N pêches OFB, dernier relevé AAAA ». Paris n'a que 36 pêches, la dernière en 2011.
- Rareté sur 10 ans. Si le département a moins de 20 pêches sur 10 ans, la rareté se calcule sur la région et l'écran le dit (« rareté en Île-de-France »). Paliers : commune 50 % et plus, peu commune 20 à 50 %, rare 5 à 20 %, très rare moins de 5 %, « non relevée ».
- La rareté s'appelle « rareté dans les relevés OFB » : la pêche électrique sous-compte les gros poissons (la carpe sort « très rare »).
- Le script range chaque station dans un seul département, d'après ses coordonnées et `departements.geojson`, pas d'après le champ de l'API (le point 03082000 est rangé tantôt dans le 93, tantôt dans le 92 : `reports/eval-mwm.md` §1).
- Sans relevé à moins de 30 km : « aucun relevé OFB à proximité », jamais une estimation.

## Politique de verdict
- Dans les 5 départements saisis (75, 92, 93, 94, 77) : la règle du département remplace la nationale de même espèce, type et catégorie. Une règle `incertain` interdit le verdict « tu peux la garder ».
- Hors de ces départements : socle national seul, catégorie « inconnue », jamais « tu peux la garder » ; « relâche-la » seulement sous la plus petite taille minimale applicable, ou quand le socle national ferme l'espèce partout ce jour-là ; sinon « vérifie l'arrêté du département » avec le lien de la préfecture.
- « Garder » n'est pas « manger » : un type de règle `consommation` porte l'interdiction de vente et de consommation (Seine, Marne, Yerres, canaux, arrêté 2010-555).
- Chaque verdict porte la source, la date de lecture et la phrase « Information indicative : l'arrêté préfectoral fait foi. En cas de doute, relâche. »
- Les 15 et 16 oct. 2026 : 1re catégorie fermée, truite fario fermée partout, 2e catégorie ouverte (brochet compris). À vérifier dans les cas de démo.

## Cas de test à écrire avant jeudi (`cas-verdicts.json`, 5 cas, réponse écrite par un humain)
1. Brochet 55 cm, Marne à Charenton (94), 15 oct. : relâche (60 cm dans le 94).
2. Brochet 65 cm, même lieu, même jour : garde, avec la mention consommation interdite.
3. Sandre 45 cm, Seine à Paris (75), 15 oct. : relâche (50 cm).
4. Truite fario 30 cm, Lyon (69, non saisi), 15 oct. : relâche (fermée partout par le socle national).
5. Perche 20 cm, Lyon (69, non saisi) : vérifie l'arrêté.
Les réponses sont à confirmer contre les textes par la personne qui saisit `regles.json`.
