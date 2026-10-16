Décision débloquée : les 261 règles du Cher (18) lues par le lecteur A, dont 215 brouillons tirés de textes signés et 46 incertains, sont prêtes pour la comparaison avec le lecteur B.

Textes (33 lus en entier, sauf 2022-054 : partie, plan annexé non lu ; URL et empreintes dans dep/18.json, champ « textes ») :
- Arrêté permanent DDT-2019-0282, signé le 12/11/2019 (OCR, fait foi), URL martinpecheurduberry.com/.../arrete_permanent_ddt_2019_0282_peche_cher.pdf : entier.
- Arrêté annuel DDT-2025-521, signé le 19/12/2025, URL martinpecheurduberry.com/.../ARRETEDDT2025-521SIGNE2026.odt.pdf : entier.
- Arrêté DDT-2026-247, signé le 06/07/2026 (anguille jaune), URL sancoins.fr/.../Arrete-DDT-2026-247-...pdf : entier.
- 16 arrêtés de carpe de nuit (2004 à 2026), 4 réserves, 7 limitations de technique ou de taille (Auron, black-bass de Bourges, Vernon, Petite Sauldre, Ouatier, Torteron, étang du Puits) et l'interdiction DDT-2026-1052 du 21/07/2026 (marais de Bourges, jusqu'au 31/10/2026) : tous entiers, URL cher.gouv.fr (copies Wayback ou Exa) dans le fichier.
- Guide 2026 de la fédération : lu en entier, utilisé seulement pour des règles incertaines.

Règles par type (brouillon / incertain) : mode_peche 51/2, interdit 42/12, ouverture 37/6, carpe_nuit 20/5, categorie 15/0, taille_min 14/0, remise_eau 14/5, reserve 7/13, autre 8/3, quota_jour 5/0, transport_vivant 2/0.

Choix de forme :
- Tailles, quotas, modes et catégories viennent du permanent 2019 (expire_le null) ; les dates 2026 viennent de l'annuel 2025-521 (expire_le 2026-12-31). Le Code n'est pas recopié.
- Un arrêté qui couvre toute l'année 2026 a du et au à null, et expire_le porte sa fin (ex. 2027-01-31 pour l'Auron, 2029-12-31 pour Marmagne).
- Les 4 écrevisses protégées, les 5 techniques interdites pendant la fermeture du brochet et chaque engin anguillier ont chacun leur règle.
- Les lignes de tableau de l'article 8 du permanent sont citées d'après l'image de la page 7 (l'OCR mélange les colonnes).
- Dates de signature absentes du manifeste, lues dans le texte : Cuffy 2022-12-08, Ouatier 2023-12-07 ; étang du Puits (DDT-2023-018) : seul février 2023 est lisible, jour illisible.

Contradictions et lequel doit primer :
1. Aloses et lamproies : le permanent 2019 autorise la pêche sur la Loire et l'Allier (lamproies : Loire à l'aval du Bec d'Allier), l'annuel 2025-521 article 5 l'interdit jusqu'au 31/12/2030. Les deux versions sont écrites en incertain ; l'annuel, plus récent et signé, doit primer (interdit).
2. Anguille jaune : l'annuel (31 août) et le guide (31 août) sont remplacés par DDT-2026-247 : loisir du 1er avril au 31 juillet 2026, professionnels (Loire, Allier) jusqu'au 31 août. Seule la version 247 est écrite.
3. Auron DDT-2021-101 : texte signé jusqu'au 31/01/2027 (retenu), page de la préfecture 31/12/2027 (écartée).
4. Marmagne : réserve DDT-2025-140, le titre dit « en amont », l'article dit « en aval » (une règle, les deux mots, incertain). La carpe de nuit 2025-089 va jusqu'à cette même écluse de Saint-Aubin et le guide la limite aux vendredis à dimanches d'avril à octobre : recouvrement possible, à vérifier sur le terrain.
5. Sidiailles : le guide dit 4 lignes, le permanent donne 2 lignes en plan d'eau de 1re catégorie ; arrêté interpréfectoral de 1996 non obtenu (règle guide en incertain).

Ce qui manque :
- Arrêté DDT-2021-0280 (carpe, canal latéral), DDT-2025-026 (Arnon), arrêté interpréfectoral de Sidiailles (1996) et DDT-2021-083 (étang du Puits), plans annexés (Val d'Auron zones jaune et verte, étang du Puits, marais de Bourges), arrêtés des réserves du guide (lots A8, B2, E3, Lorrains, CNPE, Linquet, Charenton, Guétin : écrites en incertain depuis le guide).
- Pas de règle pour le sandre en 1re catégorie, ni pour des quotas par AAPPMA (règlements intérieurs absents des textes signés).
- DDT-2023-386 et DDT-2025-133 sont des scans reconstitués : incertain.
- Torteron : l'arrêté ne nomme aucun cours d'eau, cours_eau reste null ; le black-bass n'y est pas repris.

Les 3 règles les plus risquées :
1. 18-*-ouverture/interdit aloses et lamproies (permanent contre annuel, 10 règles incertaines).
2. 18-anguille-jaune-ouverture-loisir : fermeture au 31 juillet 2026 par DDT-2026-247, très récente, que le guide et l'annuel contredisent encore.
3. 18-toutes-carpe_nuit-mareuil-2 : « du jeudi 7 mai au jeudi 28 juin 2026 », le 28 juin 2026 est un dimanche ; dates prises telles qu'écrites, incertain.
