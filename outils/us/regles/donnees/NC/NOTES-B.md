# Caroline du Nord (NC), lecteur B : notes de lecture (7 nov. 2026)

## Methode (source de depart differente de l'evidence)
1. Point de depart : le Code administratif, 15A NCAC 10C (pêche en eaux intérieures), page officielle du Office of Administrative Hearings, http://reports.oah.state.nc.us/ncac/title%2015a%20-%20environmental%20quality/chapter%2010%20-%20wildlife%20resources%20and%20water%20safety/subchapter%20c/subchapter%20c%20rules.html (en-tête HTTP Last-Modified : 26 août 2026). Lu : .0205, .0206, .0209, .0301, .0302, .0304 à .0324, .0409, .0416. Texte brut : /private/tmp/claude-501/us-regles-nc-b/ncac10c.txt (hors git).
2. Croisement : digest officiel NCWRC 2026-27 (« Inland Fishing, Hunting & Trapping Regulations »), version eRegulations liée depuis https://www.ncwildlife.gov/fishing/regulations, pages « Last Updated » 13 juillet 2026 (nongame : 10 juillet). Aucune différence de fond constatée entre les deux, sauf la formulation de la taille des black bass (voir plus bas).
3. Le serveur OAH ne répond pas en https (échec de connexion) et le schéma exige https : **toutes les sources et citations de lecture-b.json sont donc celles du digest eRegulations (https)**, citées mot pour mot dans le texte extrait. Le code 15A NCAC (http) a servi à la lecture et au recoupement, il n'est pas cité comme URL de règle. Pour les tableaux, la citation joint les cellules d'une ligne par « | » (séparateur de l'extraction, pas du texte).
4. Pas de téléchargement PDF, pas de gros fichier. User-Agent honnête, robots.txt d'eRegulations respecté.

## Édition
Saison 2026-2027, digest mis à jour le 13 juillet 2026 ; code consolidé OAH au 26 août 2026 (plusieurs règles « Amended Eff. August 1, 2026 », donc en vigueur à la date de lecture).

## Ce que le code dit et que lecture-b.json n'écrit PAS (faute de citation du digest)
- « There is no closed season » pour black bass, crappie, sunfish, catfish, walleye, muskie, white bass (code .0305 à .0322, .0416) : non repris, pour ne pas déduire d'un silence du digest.
- Largemouth : code .0305(b) « no minimum size limit, but only two of them may be less than 14 inches » vs digest « 14-inch minimum, except 2 may be less than 14 inches » : taille_min marquée incertain.
- Striped bass : le code (.0314) donne le défaut statutaire (4, 20 pouces) pour toutes les eaux intérieures hors exceptions ; le digest le rattache aux « Inland impoundments and tributaries ». J'ai suivi le digest (portée zone). Roanoke River management area (mars-avril, 1 poisson, 18 pouces, pas plus de 22 pouces, saison par proclamation), Lake Gaston/Roanoke Rapids/Kerr/Dan River (saisonnier), Hyco et autres lacs (16 pouces), Chatuge, Mattamuskeet, Pee Dee : non écrits (niveau 3 ou saisonnier complexe).
- Crappie : eaux à minimum 8, 9 ou 10 pouces et 20 à 30 poissons (.0306) : non écrites en règles séparées.
- Walleye : Lake James 15 pouces ; Gaston, Kerr, Roanoke Rapids 18 pouces et 5 par jour ; Linville River amont 4 (.0317) : non écrits.
- Blue catfish de plus de 32 pouces (1 par jour, 9 plans d'eau) ; Pee Dee 5 en combinaison ; plans d'eau du Community Fishing Program (7 channel catfish) : non écrits, sauf les étangs des game lands.
- Bartram's bass, redeye bass, rock/Roanoke bass, sauger, white perch, pickerel, shad, bullheads, kokanee : non écrits (hors mission), sauf muskellunge.
- Trout : « Public Mountain Trout Waters » classées par plan d'eau et par comté (.0205(d), pages Counties A-M et N-Z du digest) : niveau 3, titres seuls dans `textes`. Les dates 2026-2027 du digest sont des dates de licence ; les règles réelles sont flottantes (premier samedi d'avril, premier samedi de juin) ; les règles concernées sont incertaines.
- Appâts : hors eaux à truites et palangres, le digest ne cite aucune interdiction d'appât général lue ; non écrit. Interdiction des truites en catch and release : écrite.
- Lake Rim, McKinney Lake (.0212), Roanoke River palangre du 1er avril au 30 juin / Waccamaw : non écrits.

## Choix de codage à surveiller par le consensus
- « None » dans une colonne de tableau : type `autre`, statut incertain (aucune permission déduite).
- Possession : « three days' creel limit » est un multiple de la limite quotidienne, pas un nombre de poissons : incertain.
- Dates : fermeture Hatchery Supported écrite 2027-03-01 au 2027-04-02 (dates du digest), incertain.
- Catawba River (Burke) et Roanoke River (amont US 258) : règles de niveau 3 écrites car présentes dans les pages générales.
- Pas de conversion d'unités (pouces, nombre).
