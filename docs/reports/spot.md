Décision débloquée : comment l'app définit un « spot » de pêche (l'unité que le gratuit offre et que l'abonnement élargit), et ce qu'il faut, en droit et en technique, pour le construire.

Fait le 15 oct. 2026 pour la question d'Adem (fil Maquettes). « [?] » = non vérifié dans un texte lu aujourd'hui. « Estimation » = calcul de Claude, pas une mesure.

## Version simple
Un spot doit être un morceau d'eau, pas un cercle sur la carte. La loi, les poissons et l'accès suivent l'eau : un cercle de 1 km posé sur Charenton attrape la Marne, la Seine, une berge privée et la frontière entre le 94 et Paris, avec des règles différentes. Un morceau de rivière (par exemple 2 km de la Marne) ou un lac entier, lui, a un nom, une catégorie, une liste d'espèces relevées et une liste de règles.

## 1. Ce que dit le droit quand l'app propose un lieu
- **Le droit de pêche appartient à quelqu'un.** Sur un cours d'eau domanial (les grandes rivières de l'État), il appartient à l'État, qui le loue en général à l'association de pêche locale (AAPPMA). Ailleurs, il appartient au propriétaire riverain, qui le cède souvent à l'AAPPMA. Les plans d'eau fermés (« eaux closes ») échappent à la police de la pêche : il faut l'accord du propriétaire (Code de l'environnement, L431-3 à L431-7 et L435-1 à L435-5 [?]). Conséquence : l'app ne propose qu'un spot dont l'eau est publique ou tenue par une AAPPMA ; sinon elle écrit « vérifie qui détient le droit de pêche ».
- **La carte de pêche.** Pêcher en eau douce demande la carte de l'année (adhésion à une AAPPMA). L'app la rappelle, elle ne la vend pas (Mon club, E8).
- **L'accès à la berge.** Traverser un terrain privé reste interdit. Le long des cours d'eau domaniaux, une servitude de marchepied (environ 3,25 m) laisse passer les pêcheurs à pied (Code général de la propriété des personnes publiques, L2131-2 [?]).
- **Les interdictions de lieu.** Réserves de pêche (arrêtés préfectoraux, lus par D3), abords des barrages et des écluses (distance fixée par le Code ou l'arrêté [?]), arrêtés de protection de biotope, arrêtés municipaux. Aucune de ces zones n'a de tracé national ouvert : l'app dit « une réserve est listée sur ce cours d'eau, regarde le panneau », comme dans le plan actuel.
- **La catégorie (1re ou 2e) change les dates et les tailles.** Le classement est fixé par arrêté, rivière par rivière ; je ne connais pas de carte nationale ouverte du classement [?]. Sans elle, l'app montre les deux et applique la plus stricte.
- **Une rivière qui sert de frontière.** Beaucoup de rivières séparent deux départements. L'arrêté de l'Ain dit qu'en cas de divergence on applique la règle la moins restrictive des deux départements (lu par D3) ; d'autres départements peuvent dire autre chose [?]. L'app affiche les deux départements.
- **Ce qui reste vrai** : aucune position exacte du pêcheur ne quitte l'iPhone (CLAUDE.md) ; un spot proposé par l'app vient de données publiques, ce n'est pas un coin d'utilisateur.
- **La mer** est un autre régime (zones en mer, quotas refaits chaque année, déclaration RecFishing) : `reports/mer.md`, recommandé pour une version suivante. La frontière entre eau douce et mer est la limite de salure des eaux, fixée par décret (lue par D3 sur la Loire : le Migron, à Frossay [?]).

## 2. Ce qu'il faut techniquement
| Brique | Donnée ou outil | Licence | Ce que ça permet |
|---|---|---|---|
| Tracé des rivières et des lacs | BD TOPAGE (IGN et OFB), avec les codes Sandre des cours d'eau | Licence Ouverte 2.0 [?] | découper un spot, lui donner un nom (« La Marne à Charenton ») |
| Espèces relevées | Hub'Eau, état piscicole : chaque pêche OFB porte le code Sandre de son cours d'eau | Licence Ouverte | « relevé dans 9 pêches sur 29, dernier relevé 2023 » pour CE spot |
| Département | limites administratives de l'IGN (ADMIN EXPRESS) | Licence Ouverte [?] | choisir l'arrêté qui s'applique, même sans réseau |
| Règles | sortie de D3 : chaque règle locale commence par le nom du cours d'eau (consigne version 2) | arrêtés publics | rattacher réserves, no-kill, carpe de nuit au spot par le nom |
| Carte | MapKit (Apple) | inclus | afficher, pas découper : MapKit ne connaît pas les rivières comme objets |

Éviter les rivières d'OpenStreetMap : leur licence (ODbL) oblige à repartager la base qu'on en tire [?].

Comment ça marche dans l'app (estimation) :
1. Le pêcheur touche la berge, ou l'app lui propose un spot. L'iPhone cherche le tronçon de rivière ou le lac le plus proche dans un fichier embarqué (index spatial, sans réseau).
2. Le spot = 1 km en amont et 1 km en aval sur cette rivière, ou le lac entier. Identifiant stable : code Sandre plus point kilométrique.
3. Espèces : les pêches OFB de la même rivière dans le spot ou à 10 km au plus le long de l'eau ; sinon les stations à moins de 10 km, présentées comme « à proximité ». Toujours N pêches et l'année. Jamais « on y trouve ».
4. Règles : département, catégorie (ou les deux), règles nationales, puis règles locales dont le lieu porte le nom de cette rivière.
5. Gratuit et payant : le spot gratuit est retenu sur l'iPhone. Sans compte, une réinstallation l'effacerait ; le trousseau d'iOS (Keychain) survit en général à une réinstallation [?]. Les règles et la fiche de chaque spot restent gratuites partout (règle du plan, et premier angle d'attaque du jury) ; ce qui se paie, c'est la session et la carte à collectionner ailleurs.

Volume : la BD TOPAGE nationale pèse plusieurs centaines de Mo [?] ; on ne garde que les cours d'eau nommés et les lacs de plus de 1 ha, simplifiés, découpés par département (estimation : 20 à 60 Mo pour la France).

## 3. Coût pour vendredi (estimation)
| Travail | Lot | Durée |
|---|---|---|
| Script : extraire de la BD TOPAGE les rivières nommées et les lacs, simplifier, découper ; joindre les stations OFB par code Sandre | D2 | 2 à 4 h |
| `spot(pres:)`, `especesDuSpot`, règles du spot dans `Core` (testable sous Linux) | L1 | 2 à 3 h |
| Écran : toucher la berge, nom du spot, fiche | L2 | 1 à 2 h |
| Règle du paywall par spot | L6 | 1 h |
Mesure du fil Maquettes (`/mnt/project-files/maquettes/reports/spot-technique.md`) : la BD TOPAGE pèse 1,3 Go, l'extrait par département n'est pas faisable avant vendredi. Donc, pour vendredi : un cercle de 1 km figé à sa création, nommé d'après l'eau la plus proche (coins OpenStreetMap déjà prévus), règles du département de son centre, espèces par étages (même eau à 5 km, puis 30 km, puis département, puis région), toujours avec N et l'année. Le tronçon ou le lac entier arrive dans la mise à jour.

## 4. Ce qui reste à décider (Adem)
- La forme du spot : tranché par Adem le 15 oct. 12h26, cercle de 1 km vendredi, tronçon ou lac dans la mise à jour.
- Ce que garde le gratuit : tranché le 15 oct. 12h26, un spot et ses sessions illimitées. Paywall (12h28) : il s'ouvre et se ferme à la fin de la 1re session, il bloque au choix d'un 2e spot.
- Le spot proposé au gratuit : le plus proche avec des relevés OFB récents et au moins une espèce ouverte ce jour (proposition), jamais présenté comme « le meilleur ».
