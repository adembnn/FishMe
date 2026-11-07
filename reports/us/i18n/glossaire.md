# Glossaire FR vers EN US (150 termes)

Généré par `outils/us/i18n/glossaire.py` depuis `outils/us/i18n/glossaire.tsv` et `inventaire.csv`. Colonnes de comptage : nombre de textes contenant le terme (interface Swift / phrases de règles JSON / conseils JSON). Le mot n'est pas traduit mot à mot quand la colonne « À ne pas utiliser » l'interdit : on reformule.

Corpus comptés : 2118 textes d'interface, 35644 phrases de règles, 276 conseils. 177 termes candidats, 150 retenus (33 forcés : verdicts, unités, permis de pêche ; puis par fréquence).

## Verdicts et vocabulaire de la loi

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `interdit(?:es?\|s)?\b` | prohibited | illegal, forbidden, not allowed, not permitted, banned | 3 / 11366 / 0 | Verdict à trois valeurs seulement : prohibited / check the regulations / no data |
| `autoris` | (reformuler la phrase) « open », « in season », « the regulation lists… » | allowed, authorized, authorised, permitted, OK to… | 5 / 5972 / 0 | Mot interdit par la décision 10 ; reformuler, ne pas traduire le mot |
| `arrêté` | official regulation (titre de la source recopié tel quel) | decree, order, law | 31 / 855 / 0 | Titre de la source recopié tel quel |
| `relâch` | release | let go, throw back, you must return it | 12 / 403 / 25 | « Release the fish » dans l'état de tête |
| `permis(?:es?)?\b(?! de)` | (reformuler la phrase) | permitted, permissible, you may | 2 / 390 / 0 | Ne pas confondre avec le permis de pêche (license) |
| `source` | source | proof, official proof | 31 / 215 / 0 | Toujours avec l'agence et la date de lecture |
| `sur place` | on site | confirmed on site | 6 / 221 / 0 | « Check the regulations on site » |
| `règle` | regulation | law, legal requirement, rule (pour une règle de pêche) | 63 / 125 / 0 | Une règle de pêche est une « regulation » avec sa source et sa date |
| `réglementation` | regulations | law, legislation, legal info | 3 / 154 / 0 | « Check the regulations » |
| `légal` | (reformuler la phrase) « minimum size », « required » | legal, illegal, lawful, within the law, legal-size, legal limit | 17 / 46 / 0 | « taille légale » devient « minimum size » |
| `à vérifier` | check the regulations | unsure, maybe legal, probably allowed, unverified | 8 / 43 / 0 | Verdict ; forme courte « Check » sur une pastille |
| `information` | info | — | 4 / 25 / 0 |  |
| `garder` | (ne pas traduire) dire « minimum size 14 in » | you can keep it, safe to keep, keeper, OK to keep, you're good | 10 / 15 / 0 | Jamais « tu peux la garder » |
| `fait foi` | the agency's published text is the reference | legally binding, is the law, official ruling | 6 / 0 / 0 | L'app ne tranche pas |
| `respectée?` | met | compliant, legal, OK, passes | 3 / 0 / 0 | Ligne de règle : état « met », jamais de coche verte |
| `non respectée?` | not met | violation, violating, breaking the law | 2 / 0 / 0 | Ligne de règle : état « not met » |
| `donnée absente` | no data | unknown, not available, N/A, no rules | 0 / 0 / 0 | Verdict ; jamais « no restrictions » |

## Règles de pêche

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `nuit` | night | — | 3 / 4670 / 8 | « Night fishing » ; jamais « night fishing allowed » |
| `catégorie` | water classification | category (sauf si la source l'emploie) | 13 / 4617 / 0 | Catégories piscicoles françaises : sans objet US |
| `réserve` | closed area | protected zone (sauf nom officiel), legal reserve | 7 / 4551 / 0 | Reprendre le nom officiel (refuge, sanctuary) s'il existe |
| `carpe de nuit` | night carp fishing | legal night fishing | 2 / 3366 / 0 | Spécifique France ; sans objet côté US |
| `toute l'année` | year-round | all year legal | 0 / 3311 / 2 |  |
| `remise à l'eau` | release | — | 3 / 2530 / 0 |  |
| `no[- ]kill` | catch-and-release only | — | 0 / 2395 / 0 |  |
| `ouverte?` | open | legal to fish, allowed | 11 / 2012 / 2 | Saison : « open » / « closed » |
| `taille` | length | — | 30 / 1940 / 0 | Poisson : « total length » |
| `taille minimale` | minimum size | legal size, legal limit, keeper size | 3 / 1322 / 0 | Aux États-Unis : « minimum length », en pouces |
| `vivant` | live | — | 2 / 1239 / 3 |  |
| `jusqu'au` | through | until legal | 6 / 1234 / 2 | « through Dec 1 » |
| `par jour` | per day | — | 4 / 973 / 0 |  |
| `temporaire` | temporary | — | 0 / 905 / 0 |  |
| `transport` | transport | — | 1 / 782 / 2 |  |
| `permanente?` | year-round | permanent ban (sauf source) | 0 / 738 / 0 |  |
| `période` | season | legal period, allowed period | 6 / 653 / 2 |  |
| `fermeture` | season closes | — | 1 / 623 / 0 |  |
| `AAPPMA` | (sans objet US) | — | 3 / 605 / 0 |  |
| `ardillon écrasé` | barbless hooks | crushed barb only (sauf source) | 0 / 565 / 1 |  |
| `loisir` | recreational | — | 2 / 460 / 0 |  |
| `département` | state | county, department, region | 35 / 390 / 0 | Niveau de règle : l'État, parfois le comté |
| `ouverture` | season opens | legal start | 3 / 294 / 0 |  |
| `fédération` | state agency | federation, association | 13 / 244 / 0 | Agence de l'État |
| `longueur` | length | — | 1 / 212 / 0 |  |
| `fermée?` | closed | banned, off-limits | 27 / 118 / 0 | « Closed through Dec 1 » |
| `quota` | bag limit | allowed catch, legal limit, quota | 8 / 104 / 0 | « daily bag limit » ; « possession limit » est une autre valeur |
| `saison` | season | — | 1 / 90 / 2 |  |
| `protégée?` | protected | — | 7 / 80 / 0 |  |
| `taille encadrée` | size window | protected slot, slot limit (sauf si la source le dit) | 9 / 74 / 0 | Reprendre « slot » seulement si la source l'emploie |
| `poids` | weight | — | 2 / 67 / 1 | lb et oz |
| `carte de pêche` | fishing license | licence, card, permit | 9 / 21 / 0 | Remplace la carte de pêche française |
| `permis de pêche` | fishing license | fishing licence, permit, pass | 0 / 0 / 0 | Orthographe US : license |

## Unités et mesures

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `\bcm\b` | in (inches) | cm | 31 / 2140 / 0 | 1 in = 2,54 cm ; arrondir à 0,25 in |
| `heures?\b` | hr | — | 9 / 1748 / 0 | 12 h AM/PM |
| `\bm\b` | ft | m, metres | 5 / 1683 / 0 |  |
| `lever` | sunrise | — | 3 / 404 / 0 |  |
| `coucher` | sunset | — | 2 / 398 / 0 |  |
| `\bg\b` | oz | g | 0 / 179 / 2 |  |
| `\bmm\b` | in | mm | 4 / 130 / 0 | Pluie |
| `\bkm\b` | mi | km | 9 / 91 / 0 |  |
| `niveau` | water level | — | 16 / 53 / 1 |  |
| `\bkg\b` | lb | kg | 5 / 2 / 0 |  |
| `débit` | flow | — | 4 / 3 / 0 |  |
| `km/h` | mph | km/h | 4 / 0 / 0 | Vent |
| `m³/s` | cfs | m3/s | 4 / 0 / 0 | Débit, pieds cubes par seconde (USGS) |
| `hPa` | inHg | hPa, mbar | 2 / 0 / 0 | Pression |
| `°C` | °F | °C | 0 / 0 / 1 | Température de l'eau et de l'air |

## Eaux et lieux

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `\beau\b` | water | — | 52 / 8118 / 30 |  |
| `\blacs?\b` | lake | — | 3 / 1807 / 1 |  |
| `aval` | downstream | — | 0 / 1446 / 1 |  |
| `plan d'eau` | waterbody | — | 2 / 1326 / 0 | Terme de la règle par plan d'eau |
| `étang` | pond | — | 4 / 1292 / 2 |  |
| `\bpont\b` | bridge | — | 0 / 1038 / 2 |  |
| `canal` | canal | — | 1 / 1009 / 0 |  |
| `amont` | upstream | — | 0 / 985 / 1 |  |
| `barrage` | dam | — | 0 / 980 / 0 |  |
| `cours d'eau` | river or stream | — | 4 / 865 / 1 |  |
| `\brives?\b` | bank | — | 0 / 850 / 1 |  |
| `ruisseau` | creek | — | 0 / 527 / 0 | brook seulement si la source l'emploie |
| `domaine public` | public water | — | 0 / 493 / 0 | Pas de calque : le régime américain diffère |
| `affluents?` | tributaries | — | 0 / 481 / 1 |  |
| `confluence` | confluence | — | 0 / 434 / 0 |  |
| `écluse` | lock | — | 0 / 405 / 0 |  |
| `retenue` | reservoir | — | 0 / 378 / 0 |  |
| `rivière` | river | — | 22 / 209 / 4 |  |
| `domaine privé` | private water | — | 0 / 235 / 0 |  |
| `frayère` | spawning area | — | 0 / 209 / 1 |  |
| `météo` | weather | — | 27 / 3 / 0 | Marque « Apple Weather » et son lien conservés |
| `crue` | flood | — | 13 / 5 / 0 |  |

## Espèces

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `carpe\b` | common carp | — | 4 / 5961 / 1 |  |
| `brochet` | northern pike | pike (seul) | 12 / 2277 / 0 |  |
| `espèces?\b` | species | — | 48 / 1543 / 5 | Même mot au singulier |
| `écrevisse` | crayfish | — | 7 / 1152 / 0 | crawfish seulement si la source l'emploie |
| `sandre` | zander | walleye (autre espèce) | 1 / 1154 / 1 |  |
| `black[- ]bass` | largemouth bass | black bass (sauf choix produit) | 3 / 1089 / 1 | Espèce US de référence |
| `truite fario` | brown trout | — | 1 / 975 / 0 |  |
| `anguille` | European eel | — | 5 / 757 / 0 |  |
| `carnassiers?` | predatory fish | — | 1 / 742 / 0 | gamefish seulement si la source l'emploie |
| `ombre\b` | grayling | — | 5 / 645 / 5 |  |
| `salmonidés` | salmonids | — | 1 / 603 / 0 |  |
| `omble` | char | — | 1 / 515 / 0 |  |
| `truite arc-en-ciel` | rainbow trout | — | 0 / 492 / 0 |  |
| `grenouille` | frog | — | 0 / 473 / 0 |  |
| `saumon` | Atlantic salmon | — | 2 / 391 / 0 |  |
| `perche` | European perch | yellow perch (autre espèce) | 3 / 289 / 0 |  |
| `silure` | wels catfish | — | 1 / 112 / 1 |  |

## Matériel et techniques

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `ligne` | line | — | 12 / 1839 / 15 |  |
| `hameçons?` | hook | — | 1 / 1713 / 34 |  |
| `ardillon` | barb | — | 0 / 1617 / 2 |  |
| `\bmouches?\b` | fly | — | 0 / 1061 / 6 |  |
| `appâts?` | bait | — | 3 / 944 / 24 |  |
| `leurres?` | lure | — | 3 / 946 / 18 |  |
| `esches?` | bait | — | 0 / 660 / 4 |  |
| `canne` | rod | — | 3 / 652 / 4 |  |
| `\bvif\b` | live bait | — | 2 / 644 / 1 |  |
| `asticots?` | maggots | — | 0 / 362 / 9 |  |
| `balance` | scale | — | 0 / 271 / 10 |  |
| `amorçage` | chumming | — | 3 / 249 / 0 |  |
| `bateau` | boat | — | 0 / 148 / 0 |  |
| `float tube` | float tube | — | 0 / 117 / 0 |  |
| `\bver\b` | worm | — | 0 / 44 / 18 |  |

## Interface

| FR (motif) | EN US | À ne pas utiliser | Interface / règles / conseils | Note |
|---|---|---|---|---|
| `\bpêche\b` | fishing | — | 66 / 16778 / 15 | Nom ou verbe selon le contexte |
| `poissons?\b` | fish | fishes (sauf plusieurs espèces) | 59 / 2799 / 13 |  |
| `pêcheur` | angler | fisherman (genré) | 12 / 1412 / 0 |  |
| `\blieu\b` | location | — | 17 / 606 / 0 |  |
| `\bprises?\b` | catch | — | 49 / 394 / 2 | « catches » au pluriel |
| `compte` | account | — | 23 / 228 / 1 |  |
| `\bcartes?\b` | card (collection) ou map (écran) | — | 176 / 49 / 0 | À distinguer : onglet « Map », collection de « cards » |
| `conditions` | terms | — | 12 / 202 / 0 |  |
| `\bvoir\b` | view | see | 41 / 67 / 1 |  |
| `club` | club | — | 90 / 6 / 0 |  |
| `position` | location | GPS position | 25 / 58 / 0 |  |
| `photos?\b` | photo | — | 82 / 0 / 0 |  |
| `\bamis?\b` | friend(s) | buddies | 62 / 8 / 0 |  |
| `profil` | profile | — | 59 / 1 / 0 |  |
| `\bspots?\b` | spot | legal spot, allowed spot, best spot, good spot, hot spot, secret spot | 57 / 2 / 0 | « Choose another spot » ; jamais de jugement |
| `sortie` | trip | — | 21 / 38 / 0 |  |
| `relevé` | survey record | — | 39 / 5 / 0 | « caught in N surveys, last survey YYYY » |
| `signaler` | report | flag | 19 / 22 / 0 | Règle 1.2 d'Apple |
| `OFB` | (sans objet US) agence de l'État | — | 27 / 14 / 0 |  |
| `Pescedex` | Pescedex | Pokédex | 35 / 0 / 0 | Nom de marque gardé |
| `session` | session | — | 26 / 3 / 0 |  |
| `choisir` | choose | select | 28 / 0 / 0 |  |
| `messages?\b` | messages | — | 27 / 0 / 0 |  |
| `\bcoin\b` | spot | best spot | 24 / 0 / 1 |  |
| `bloquer` | block | — | 23 / 0 / 0 |  |
| `réglages` | Settings | Preferences, Options | 22 / 0 / 0 | iOS US |
| `réessaie` | try again | — | 22 / 0 / 0 |  |
| `conseils?` | tips | best practices | 15 / 6 / 0 |  |
| `supprimer` | delete | — | 20 / 0 / 0 |  |
| `fermer` | close | — | 20 / 0 / 0 |  |
| `collection` | collection | — | 19 / 0 / 0 |  |

## Mots à ne jamais afficher côté US

legal, illegal, lawful, allowed, authorized (authorised), permitted, permissible, within the law, legal size, legal limit, keeper, OK to keep, safe to keep, you can keep it, you may keep, approved, compliant, guaranteed, best spot, good spot, hot spot, the fish will bite, fishing score ou index, pourcentage de confiance de l'IA. Orthographe US : license, color, center, gray.

Écartés faute de place (27) : surnom, fleuve, partager, démo, flotteur, abonnement, annuler, inviter, chargement, orage, \bessai\b, continuer, publier, ajouter, toise, rejoindre, espèce protégée, légendaire, rareté, confidentialité, aperçu, erreur, hors de France, bredouille, hors ligne, communauté, bientôt.
