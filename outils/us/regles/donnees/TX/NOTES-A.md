# Notes lecteur A, Texas (lecture du 2026-11-07)

## Sources lues (TPWD, Texas Outdoor Annual, pages HTML, aucune page bloquée)
Les pages portent la mention « Valid Sep. 1, 2026 through Aug. 31, 2027 » (édition 2026-27). Aucune date de publication lisible (les métadonnées HTML datent de 2024-2026 et ne sont pas une date d'édition). Texte brut : /private/tmp/claude-501/us-regles-tx-a/ (hors git).
- Bag and length limits : https://tpwd.texas.gov/regulations/outdoor-annual/fishing/freshwater-fishing/bag-length-limits (entier)
- Legal devices : .../fishing/general-rules-regulations/legal-devices-for-fish (entier)
- General Fishing Regulations (appâts, game fish) : .../general-rules-regulations/general-fishing-regulations (entier)
- Exceptions (index) : .../fishing/freshwater-fishing/freshwater-fishing-laws-and-exceptions/ (entier, sans les fiches)
- Alligator gar : .../freshwater-fishing/gar-closure ; Definitions : .../general-rules-regulations/definitions (partie).
robots.txt respecté (aucun chemin lu n'est exclu), User-Agent honnête, 1 s entre requêtes.

## Niveau 3 (exceptions par plan d'eau)
104 plans d'eau ou groupes d'eaux ont une fiche, listés avec leur URL dans `exceptions-niveau3.json` (modèle : https://tpwd.texas.gov/fishboat/fish/action/fishregs2.php?water=NNNN). Fiches NON lues, sauf Generations Park lue en test (non transcrite). Aucune règle de plan d'eau écrite, hors les exceptions de portée zone ou tronçon citées dans les pages d'État (listées ci-dessous).

## Règles écrites : 68 (brouillon et incertain)
Espèces : largemouth, smallmouth, spotted, Guadalupe, Alabama, striped, hybrid striped, white bass ; channel, blue, flathead catfish ; crappie (white/black groupés, comme la page) ; sunfish ; rainbow et brown trout ; walleye ; paddlefish (aucune prise) ; alligator gar (incertain). Plus engins et appâts généraux d'État, et 7 règles de portée zone ou tronçon tirées des pages d'État (Community Fishing Lakes, 18 comtés de l'ouest, Red River/Big Cypress/Sulphur, Guadalupe en aval de Canyon Dam).

## Choix et pièges
- Florida bass : la page ne distingue pas le Florida bass ; il suit « Largemouth bass ». Aucune règle séparée écrite.
- La limite journalière de 5 est cumulée sur largemouth, smallmouth, Alabama, Guadalupe et spotted : écrite par espèce, le champ texte rappelle le cumul. Spotted, Guadalupe, Alabama : taille minimale « None » (pas de règle de taille).
- Striped et hybrid : 5 cumulés, 18 pouces. Texoma (striped) et autres plans d'eau ont des exceptions non lues.
- Catfish channel et blue : 25 cumulés, dont au plus 10 de 20 pouces ou plus (règle « autre » distincte). Taille minimale « No Limit » non transcrite.
- Sunfish « No limit » : règle incertaine de type autre (pas de nombre inventé). Rainbow/brown trout : 5 cumulés, taille « None ».
- Possession : le texte dit « twice the statewide daily bag limits » ; les valeurs (10, 50) sont CALCULÉES par moi (brouillon) ; incertaines pour striped, hybrid et les catfish (exception Texoma ; sous-limite de 20 pouces non doublée par le texte).
- Les règles s'appliquent « à toutes les eaux publiques douces sauf lieux listés » : toute règle d'État est donc susceptible d'une exception de plan d'eau non lue.
- Aucune saison de fermeture générale n'est écrite dans les pages lues : le silence n'est pas transcrit (aucune règle de saison).
- « Game fish » utilisé comme espèce pour les règles qui visent la catégorie (canne et ligne, arc, appâts) ; ce n'est pas une espèce, le consensus la traitera à part.
- Citations jointes à partir de lignes voisines de la page (titre d'espèce + champ), espaces normalisés ; la mise en page HTML sépare ces champs. Vérifiées par programme comme sous-chaînes du texte extrait.
- Page gar-closure : contient un texte daté 2025 resté en ligne (« through August 31, 2025 ») : fermeture alligator gar laissée incertaine.
- Trotline/jugline/throwline : engins limités aux catfish et poissons non-game ; la restriction d'espèces est dans la phrase, pas dans le champ espèce (règles incertaines pour juglines, throwlines, handfishing, trotline).
- Non lu : tags d'engin détaillés, crabes, engins d'eau salée, pages « Restricted Areas in Counties », bow fishing, permis, pêche en eau frontalière.
