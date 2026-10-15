# Données embarquées dans l'app

Version du 15 oct. Tiré de `reports/donnees.md` (sources, appels réels), `reports/regles-75-94.md` (brouillon de 98 règles) et corrigé par `reports/eval-mwm.md` et `reports/eval-apple.md`. Remplace la version du 12 oct. (git la garde) : l'app vise toute la France, la règle s'affiche en liste de contrôle, les règles de chaque département viennent de D3.

## Les fichiers
Dossier de l'app : `Packages/Core/Sources/Core/Resources/`. « Saisi » = commité ; « fabriqué » = sorti d'un script, jamais commité, téléchargé par `scripts/donnees.sh`.
| Fichier | Étapes | Source | Licence et obligation | Nature | Qui, quand |
|---|---|---|---|---|---|
| `departements.geojson` | E2 E5 E6 | [france-geojson](https://github.com/gregoiredavid/france-geojson) (IGN Admin Express, version simplifiée) | Licence Ouverte : citer IGN et INSEE | saisi (téléchargé) | D1, en premier |
| `coins-osm.geojson` | E1 | OpenStreetMap, requête Overpass de `reports/donnees.md` §1 | ODbL : « © contributeurs OpenStreetMap » et lien, fichier gardé à part | saisi (exporté) | D1 |
| `coins-maison.json` | E1 E2 | fédération 75/92/93/94 et arrêtés | à nous | saisi, 30 à 60 coins d'accès public d'Île-de-France | D1 |
| `regles.json` | E2 E4 E5 E6 | Légifrance (R436-6 à R436-23, R436-70 à R436-74, L436-16), arrêtés permanents et avis annuels 2026 de chaque département | Licence Ouverte (Légifrance) ; arrêtés : actes publics | saisi, schéma ci-dessous : socle national, 75, 92, 93, 94, 77 relus par S, autres départements chargés depuis D3 | D1 (C), relu par S |
| `especes.json` | E2 E5 E6 | 14 espèces de `reports/donnees.md` §3 (TAXREF, codes Sandre) | Licence Ouverte | saisi | D1, en premier |
| `cas-verdicts.json` | E2 E5 | les 10 cas d'or de ce document, réponses écrites par S contre les arrêtés | à nous | saisi, sert aux tests de L1 et L3 | D1 (C), réponses par S |
| `credits.json` | page « Sources » | les lignes de ce tableau, plus les jeux GBIF des photos d'entraînement (R1) et les illustrations des espèces | reprend les mentions exigées (OSM, IGN et INSEE, OFB, GBIF, BHL) | saisi | D1 |
| `liens-federations.json` | E8 | site officiel de chaque fédération départementale de pêche, et la page de cartedepeche.fr (fédération nationale) | liens seulement : rien de recopié de l'annuaire des associations (`vision.md` §2) | saisi, avec la date de relevé de chaque lien, relu par une 2e personne | D1 |
| 14 illustrations et 14 silhouettes d'espèces (dans `App/Assets.xcassets/`, posées par A depuis la copie de L0) | E1 E2 E5 E6 | Bloch, 1785, et Cuvier et Valenciennes pour le black-bass (BHL, déjà détourées : `docs/maquettes/assets/fish/`) ; truite arc-en-ciel : illustration sous licence libre, à trouver ; silhouettes tirées de ces illustrations, un seul profil | domaine public ; la licence de l'arc-en-ciel et son auteur cités dans `credits.json` | saisi | D1, remis à A |
| `stations-especes.json` | E1 E2 E3 | [Hub'Eau Poissons](https://hubeau.eaufrance.fr/page/api-poisson) | [Licence Ouverte 2.0](https://www.data.gouv.fr/dataservices/hubeau-etat-piscicole-des-rivieres) : citer OFB et Hub'Eau, avec la date | fabriqué, France entière | D2 |
| `rarete-departements.json` | E2 E6 | idem | idem | fabriqué, France entière | D2 |

Fichiers de travail, hors de l'app :
| Fichier | Étapes | Source | Licence et obligation | Nature | Qui, quand |
|---|---|---|---|---|---|
| `outils/regles/consensus/<code>.json` | E2 E5 | arrêtés permanents et annuels de chaque département, recueils des actes administratifs, pages des fédérations (liste par département dans son rapport `reports/regles-dep/<code>.md`) | actes publics ; Légifrance : Licence Ouverte ; la fédération n'est pas un texte réglementaire | fabriqué par deux lectures automatiques indépendantes (`consensus.py` ne garde que les règles où elles trouvent la même valeur et la même citation) ; chargé dans `regles.json` par D1 | D3 (C) |
| `outils/regles/dep/<code>.json`, `dep-b/<code>.json` | E2 E5 | idem, lectures A et B | idem | fabriqué, hors de git | D3 (C) |
| `especes-national.json` (`/mnt/project-files/build/regles/`, en cours le 15 oct.) | E2 E5 | audit des règles nationales de toutes les espèces d'eau douce, pas seulement les 14 : Code de l'environnement (Légifrance) et arrêtés ministériels cités dans `reports/regles-75-94.md` (espèces protégées, envahissantes, anguille) | Licence Ouverte (Légifrance) ; arrêtés : actes publics | contenu et forme à confirmer à son arrivée ; entre dans `regles.json` par D1 | audit en cours, puis D1 |

Écartés : BD TOPAGE (1,3 Go, rien sur le droit de pêche), FishBase (non commercial), photos Commons CC BY-SA, `saisons-montages.json` (il servait la mission première prise, supprimée), les fichiers de rareté déjà commités sur la branche de Titouan (`PecheCore/.../Data/departments/`, `species.json`) : données générées, elles sortent de git.

## Règles d'affichage (pour ne jamais présenter une donnée mince comme solide)
- Chaque espèce d'un coin et chaque rareté affichent « N pêches OFB, dernier relevé AAAA ». Paris n'a que 36 pêches, la dernière en 2011.
- Fenêtre de 10 ans : du 1er janvier de l'année en cours moins 10 (2016 pour 2026) à la date du script. C'est celle qui redonne les 29 pêches du 94. Si le département a moins de 20 pêches sur cette fenêtre, la rareté se calcule sur la région et l'écran le dit (« rareté en Île-de-France »).
- Quatre niveaux (Adem, 12 oct. 18 h 55) : **commun** 50 % des pêches et plus, **peu commun** 20 à 50 %, **rare** moins de 20 %, **légendaire** jamais relevé dans le département sur la fenêtre. Seuils par défaut, à changer d'un mot, dans `Core` seulement (L1) : D2 ne sort que des comptes. Légendaire veut dire « 0 pêche sur N », une phrase vraie ; la carpe ou le black-bass, que l'OFB sous-compte, ne deviennent pas légendaires.
- Attendu dans le 94 (29 pêches depuis 2016, `reports/donnees.md` §3) : commun perche, gardon, chevesne ; peu commun brochet, silure, barbeau ; rare sandre, brème, tanche, black-bass, carpe ; légendaire truite fario, truite arc-en-ciel, ombre. C'est le test de L1 et de D2.
- La rareté s'appelle « rareté dans les relevés OFB » : la pêche électrique sous-compte les gros poissons (la carpe sort « rare » dans le 94, 1 pêche sur 29).
- Le script range chaque station dans un seul département, d'après ses coordonnées et `departements.geojson`, pas d'après le champ de l'API (le point 03082000 est rangé tantôt dans le 93, tantôt dans le 92 : `reports/eval-mwm.md` §1).
- Sans relevé à moins de 30 km : « aucun relevé OFB à proximité », jamais une estimation.
- Forme des deux fichiers fabriqués, figée par D2 avec L1 avant la première lecture. `stations-especes.json` : par station, `id`, `lat`, `lon`, `dep`, `peches`, `derniere`, `vues` (code Sandre vers nombre de pêches), comme l'exemple de `reports/donnees.md` §2. `rarete-departements.json` : en tête la source, la licence et la date ; par département sa région, puis pour `dix_ans` et `historique` le nombre de pêches avec au moins un poisson et, par code Sandre, le nombre de pêches où l'espèce est vue et l'année du dernier relevé, par exemple `"94": {"dix_ans": {"peches": 29, "especes": {"2151": {"peches": 8, "derniere": AAAA}}}}` ; les mêmes comptes pour chaque région. Une espèce jamais vue est absente du fichier.

## Politique de la liste de contrôle (ex-« politique de verdict »)
- Par défaut (question 1 de `README.md`, option b), l'app montre la loi au lieu d'accorder une permission : une ligne par règle qui s'applique (taille, période, quota, mode de pêche, nuit, réserve possible, consommation), chacune avec son état (respectée, non respectée, à vérifier sur place), sa phrase, sa source, sa citation et sa date de lecture. Puis une consigne : « relâche-la » si une ligne n'est pas respectée, « vérifie l'arrêté » si une ligne est à vérifier. Jamais « tu peux la garder ». Toutes lignes respectées : « aucune règle saisie ne l'interdit ; l'arrêté fait foi » (texte par défaut, à valider par Adem). La ligne réserve (« regarde le panneau ») n'apparaît, à vérifier sur place, que si une réserve est listée sur ce cours d'eau dans ce département.
- La règle la plus locale (tronçon, cours d'eau, département) remplace la plus générale de même espèce, type et catégorie. Les règles couvrent toutes les espèces d'eau douce ; les 14 espèces sont celles de la collection.
- Deux textes qui se contredisent sur une valeur : la plus stricte, avec les deux sources (Adem, 15 oct.). Le texte qui fait foi est l'arrêté permanent signé (`reports/qui-est-maitre.md`) ; la plus stricte reste affichée, car relâcher n'est jamais une infraction. La règle porte `valeur.candidats_cm` et le statut `incertain`. Une règle dont `expire_le` est passé donne « vérifie l'arrêté » avec l'année suivante, jamais un feu vert.
- Règles lues par une IA (décidé par Adem le 15 oct. à 11 h 34, remplace la question 3 de `README.md`) : l'app montre chaque règle avec sa source et sa citation, sans étiquette « lue automatiquement » ni « non relue ». La double lecture de D3 est notre contrôle interne : seules les lignes où les deux lectures indépendantes trouvent la même valeur et la même citation sont chargées. Là où elles divergent, l'app dit « vérifie l'arrêté » avec le lien du texte. La relecture humaine par S reste prévue pour l'Île-de-France (75, 92, 93, 94, 77).
- Département sans règle locale chargée : socle national seul, « règles locales non saisies » et le lien de la préfecture. « Relâche-la » seulement sous la plus petite taille minimale applicable, ou quand le socle national ferme l'espèce partout ce jour-là ; sinon « vérifie l'arrêté ». Les réserves et les parcours n'ont pas de coordonnées : la ligne dit « regarde le panneau », l'app ne teste jamais la position.
- « Garder » n'est pas « manger » : un type de règle `consommation` porte l'interdiction de vente et de consommation (Seine, Marne, Yerres, canaux, arrêtés de 2010).
- Chaque ligne porte la source, la date de lecture, et l'écran la phrase « Information indicative : l'arrêté préfectoral fait foi. En cas de doute, relâche. »
- Les 15 et 16 oct. 2026 : 1re catégorie fermée, truite fario fermée partout, 2e catégorie ouverte (brochet compris), truite arc-en-ciel ouverte en 2e catégorie.

## Schéma d'une règle (`regles.json`)
Celui du brouillon de `reports/regles-75-94.md`, plus les ajouts : `citation` (300 caractères au plus, `[...]` marque une coupe), `expire_le`, `portee.lieu`, `valeur.candidats_cm`, `verifie_par`. Exemple (valeurs du brouillon du 15 oct., phrase mise à la plus stricte) :
```json
{ "id": "94-bro-taille", "portee": {"niveau": "departement", "code": "94", "lieu": null},
  "especes": ["2151"], "categorie": "2", "type": "taille_min",
  "valeur": {"cm": null, "candidats_cm": [50, 60]}, "du": null, "au": null, "remplace": "nat-bro-taille",
  "phrase": "Brochet : 60 cm d'après l'avis annuel 2026, 50 cm d'après l'arrêté de 2025 ; la plus stricte s'applique.",
  "source": {"texte": "Avis annuel 2026 Val-de-Marne (rappel de dispositions)", "url": "http://www.federation-peche-paris.fr/cms_viewFile.php?idtf=54987&path=Avis-annuel-94-2026.pdf",
             "lu_le": "2026-10-15", "version": "avis fait à Créteil vers le 10/02/2026 ; PDF numérisé (OCR)"},
  "citation": "Dans les eaux classées en 2ème catégorie, les tailles minimales de captures sont de 0,40 m pour le black-bass, 0,50m pour le sandre et 0,60m pour le brochet.",
  "statut": "incertain", "verifie_par": null, "expire_le": "2026-12-31" }
```
- `portee.niveau` : `national`, `departement`, `cours_eau`, `troncon` ou `plan_eau` ; `portee.lieu` : le lieu avec les mots exacts de l'arrêté, ou `null` (le brouillon l'a encore à la racine de la règle : D1 le déplace). `especes` : codes Sandre, ou le nom quand l'espèce n'a pas de code.
- `type` : `ouverture`, `taille_min`, `quota_jour`, `horaire`, `interdit`, `categorie`, `mode_peche`, `carpe_nuit`, `transport_vivant`, `remise_eau`, `consommation`, `reserve` ; D3 ajoute `no_kill` et `autre`, que `Core` doit accepter.
- `statut` : `brouillon` (lu dans un texte, citation copiée), `incertain` (illisible, introuvable, fédération seule, ou deux textes qui se contredisent), `verifie` (relu par une personne qui n'est pas l'auteur). `verifie` exige `verifie_par` (nom et date). Le squelette de `lot/donnees` disait `saisi` : D1 le remplace par `brouillon`.
- `expire_le` : 31/12/2026 pour une règle d'avis annuel, `null` sinon. Les ids `nat-*` du squelette de `lot/donnees` et du brouillon se fusionnent, sans doublon. `nat-tru-fermeture-2026` du squelette fermait aussi la truite arc-en-ciel (2216) : erreur, R436-7 3° ne la ferme qu'en cours d'eau classé à saumon ou truite de mer et les arrêtés 75 et 94 ne citent que la fario (`nat-arc-pas-fermeture-2e`).

## Cas d'or (`cas-verdicts.json`, 10 cas au moins, réponse écrite par un humain)
Date de référence : 15 oct. 2026. Les cas 1 à 5 viennent du 12 oct. ; les réponses sont reformulées pour la liste de contrôle. Les cas 6 à 10 couvrent chacun un type de ligne : S écrit leur réponse contre les arrêtés avant qu'ils entrent dans le fichier.
1. Brochet 55 cm, Marne à Charenton (94) : la ligne taille n'est pas respectée (60 cm d'après l'avis 2026, 50 cm d'après l'arrêté de 2025, la plus stricte) : « relâche-la ».
2. Brochet 65 cm, même lieu : taille respectée dans les deux textes, ligne consommation interdite (arrêté 2010-5378), réserve listée sur la Marne dans le 94 donc à vérifier sur place : « vérifie l'arrêté », jamais « tu peux la garder ». Sans réserve listée, la consigne serait « aucune règle saisie ne l'interdit ; l'arrêté fait foi ».
3. Sandre 45 cm, Seine à Paris (75) : 40 cm d'après l'arrêté, 50 cm d'après l'avis 2026 : « relâche-la ».
4. Truite fario 30 cm, Lyon (69), département sans règle locale dans le jeu d'essai : période fermée par le socle national (R436-7 3°) : « relâche-la ».
5. Perche 20 cm, Lyon (69), même jeu d'essai : le socle national n'a ni taille ni quota pour la perche, règles locales non saisies : « vérifie l'arrêté ».
6. Black-bass 35 cm, Marne à Charenton (94) : 30 cm d'après l'arrêté, 40 cm d'après l'avis 2026 : la plus stricte.
7. Brochet 70 cm, Seine à Paris (75), le 15 janvier 2027 : la ligne de période vient d'un avis annuel périmé (`expire_le` 31/12/2026) : « vérifie l'arrêté » 2027.
8. Brochet 65 cm, Marne à Charenton (94), avec deux brochets déjà gardés ce jour : quota de trois carnassiers dont deux brochets.
9. Perche 25 cm, Seine à Paris (75), le 15 oct. à 20 h heure de Paris : après la fin légale (coucher du soleil plus 30 minutes, 19 h 33), ligne horaire.
10. Truite arc-en-ciel 25 cm, Marne à Charenton (94) : ouverte toute l'année en 2e catégorie, seule la fario suit la 1re catégorie ; l'erreur de l'ancien brouillon.
Les cas 4 et 5 lisent un jeu d'essai sans règle locale pour le 69, car D3 peut le couvrir. Décision débloquée : quelles lignes l'app affiche pour les prises de la démo, et lesquelles restent à « vérifie l'arrêté ».
