Décision débloquée : le socle national suffit-il à dire, espèce par espèce, si la pêche est ouverte ou fermée le 15 oct. 2026, et que corriger dans `brouillon-75-94.json` avant de l'afficher.

Brouillon du 15 oct. 2026 pour relecture humaine. Table complète : `regles/especes-national.json` (77 entrées, 41 codes Sandre : 13 repris du brouillon, 28 lus sur les fiches Sandre). « [?] » = non lu dans un texte.

## Réponse courte
- Image : le Code est une grille de règles générales avec quelques exceptions nommées. Une espèce non nommée prend la règle de sa catégorie, sans taille ni quota.
- 2e catégorie (tout Paris et le Val-de-Marne) : ouvert toute l'année, de 30 min avant le lever à 30 min après le coucher du soleil. Exceptions nommées : brochet, ombre, fario, ombles, cristivomer.
- 1re catégorie : PAS toute l'année. Ouvert du 2e samedi de mars au 3e dimanche de septembre seulement : tout est fermé aujourd'hui, réouverture le 13 mars 2027.
- Le Code ne nomme pas toutes les espèces : il traite par arrêtés les migrateurs (anguille, aloses, lamproies, saumon), les écrevisses, les grenouilles et les espèces envahissantes.
- Brouillon : aucune période d'ouverture fausse trouvée sur les 22 règles `nat-*` et les 24 règles d'ouverture 75/94. Il est incomplet : 13 points à corriger, E1 à E13 plus bas. L'arc-en-ciel est bien ouverte en 2e catégorie ; l'erreur venait du squelette `nat-tru-fermeture-2026` de `lot/donnees`, à supprimer.
- Limite : Légifrance et la plupart des sites de l'État sont illisibles depuis ce conteneur. Le Code n'est pas relu à la source. Je l'ai recoupé avec le décret 2016-417 et le décret 2019-352 (lus), service-public.gouv.fr (fiche du 19/06/2026), la FNPF et sept fédérations (lus).

## 1. Ce que le Code et les arrêtés disent (version 2026)
| Sujet | Règle | Lu |
|---|---|---|
| 1re catégorie, R436-6 | 2e samedi de mars au 3e dimanche de septembre (14 mars au 20 sept. 2026). Ombre dès le 3e samedi de mai. Brochet capturé avant le dernier vendredi d'avril : remis à l'eau (décret 2019-352 art. 3) | service-public, FNPF, fédération 31, décret |
| 2e catégorie, R436-7 | « Dans les eaux de 2e catégorie, la pêche est autorisée toute l'année, à l'exception de : » 1° brochet : 1er janv. au dernier dimanche de janv. et dernier samedi d'avril au 31 déc. ; 2° ombre : 3e samedi de mai au 31 déc. ; 3° fario, ombles, cristivomer, et arc-en-ciel seulement en cours d'eau classés à saumon ou truite de mer : temps de la 1re catégorie | alinéa 1 lu mot pour mot ; 1° à 3° brouillon + 3 sources [?] |
| R436-8 | Le préfet peut interdire temporairement une espèce ; le ministre peut l'interdire si son état de conservation l'exige (décret 2016-417) | version 2007 + décret |
| R436-9 | R436-6 et R436-7 1° à 3° ne s'appliquent pas à certains plans d'eau | version 2007 seulement [?] |
| R436-10 | Écrevisses à pattes rouges, des torrents, blanches, grêles : 10 jours consécutifs à partir du 4e samedi de juillet (25 juil. au 3 août 2026) | copie du Code vers 2018 |
| R436-11 | Grenouilles verte et rousse : période fixée par le préfet, 10 mois au plus | projet de décret 2018 + décret 2019 |
| R436-13, 14 | Pêche de 30 min avant le lever à 30 min après le coucher ; dérogations par arrêté : carpe, truite de mer, alose, lamproies, flet, mulet | service-public, FNPF [?] |
| R436-18 tailles | brochet 50, sandre 40 (2e cat.), black-bass 30 (2e cat.), truites 23, ombre 30, corégone 30, cristivomer 35, huchon 70, lamproie fluviatile 20, lamproie marine 40, mulet 20, écrevisses de R436-10 9, grenouilles 8 | carnavenir (2007), peche-assistant (15/08/2026), décret 2019 |
| R436-19 | Le préfet peut relever : brochet 60, sandre 50, black-bass 40, ombre 35 ; truites 18 à 30 | décret 2019 art. 8, fédération 31 [?] |
| R436-21 quotas | salmonidés 10/jour ; 2e cat. : 3 sandres, brochets, black-bass dont 2 brochets ; 1re cat. : 2 brochets | décrets 2016 et 2019, FNPF |
| Protégés | Arrêté du 8/12/1988 : oeufs et frayères (lamproies, corégones, saumon, truites, omble chevalier, aloses, ombre, brochet, barbeau méridional, vandoise, ide, bouvière, loches, blennie, apron), pas la capture des adultes. Arrêté du 9/07/1999 : apron et esturgeon strictement protégés | lus en entier (AIDA) |
| Envahissantes | R432-5 (poisson-chat, perche soleil, crabe chinois, écrevisses sauf 4 indigènes) ; arrêté du 14/02/2018 art. 3 : détention, transport, vente, introduction interdits (perche soleil, pseudorasbora, goujon de l'Amour, écrevisses américaine, de Louisiane, signal, virile, marbrée, crabe chinois, grenouille-taureau) ; arrêté du 2/03/2023 ajoute poisson-chat, gambusies, écrevisse à taches rouges | lus ; R432-5 en version ancienne |
| Silure | Décret 2026-464 du 8 juin 2026, en vigueur le 11 juin : silure à déséquilibre (L432-10) en Adour-Garonne et Loire-Bretagne seulement. Garde vivante interdite, remise à l'eau immédiate permise | 4 fédérations, décret non lu [?] |
| Anguille | Civelle et argentée interdites. Jaune : fermée le 31 juil. 2026, le 15 juil. en Seine-Normandie et Artois-Picardie (arrêté du 12/06/2026), interdite en Rhône-Méditerranée et Corse. Carnet obligatoire | projet d'arrêté + 3 pages [?] |

## 2. Tableau au 15 oct. 2026 (regroupé ici ; une ligne par espèce dans le JSON)
Légende : F = fermée, O = ouverte, I = interdite toute l'année, L = règle locale. Dates de réouverture : 2027.
| Espèce | 1re cat. | 2e cat. | Taille cm | Quota/jour |
|---|---|---|---|---|
| Truite fario | F, 13 mars | F, 13 mars | 23 | 10 |
| Omble de fontaine, omble chevalier | F, 13 mars | F, 13 mars | aucune | 10 |
| Cristivomer | F, 13 mars | F, 13 mars | 35 | 10 |
| Truite arc-en-ciel | F, 13 mars | O (F en rivière classée saumon ou truite de mer) | 23 | 10 |
| Ombre commun | F, 15 mai | O jusqu'au 31 déc. | 30 | 10 [?] |
| Brochet | F, 24 avril | O jusqu'au 31 janv. | 50 | 3 dont 2 brochets (2e) ; 2 (1re) |
| Sandre, black-bass | F, 13 mars | O | 40 et 30 (2e cat.) | 3 communs |
| Perche, grémille, silure | F, 13 mars | O | aucune | aucun |
| Carpes (commune, amour, argentée, grosse tête) | F, 13 mars | O | aucune | aucun |
| Gardon, rotengle, brèmes, chevesne, tanche, barbeau, vandoise, ide, hotu, ablette, goujon, spirlin, able, bouvière, carassins, aspe, vairon | F, 13 mars | O | aucune | aucun |
| Loches, chabot, lotte, épinoche, flet | F, 13 mars | O | aucune | aucun |
| Mulets ; corégones ; huchon | F, 13 mars | O | 20 ; 30 ; 70 | aucun |
| Anguille jaune | F | F (15 juil. en 75/94) | civelle < 12 interdite | carnet |
| Anguille argentée, civelle | I | I | | |
| Grande alose, alose feinte, lamproies, saumon, truite de mer | L (75/94 : I) | L (75/94 : I) | lamproies 20 et 40 | |
| Esturgeon, apron | I | I | | |
| Écrevisses indigènes (4) | F | F (75/94 : I) | 9 | |
| Écrevisses américaine, Louisiane, signal, virile, marbrée, à taches rouges | F | O, ne pas relâcher | aucune | |
| Perche soleil, poisson-chat, pseudorasbora, goujon de l'Amour, gambusie, crabe chinois | F | O, ne pas relâcher, pas de transport vivant | aucune | |
| Grenouilles verte et rousse | L | L (75/94 : O d'après la fédération [?]) | 8 | |
Carpe de plus de 60 cm : transport vivant interdit (L436-16 II). Silure : garde vivante interdite en Adour-Garonne et Loire-Bretagne.

## 3. Contrôle du brouillon
Je ne trouve aucune période fausse. Les dates 2026 recalculées : dernier dimanche de janvier 25/01, dernier samedi d'avril 25/04, 3e samedi de mai 16/05, 2e samedi de mars 14/03, 3e dimanche de septembre 20/09. Toutes justes.
**Justes sans réserve sur la période (16 `nat-*`, mais voir E5 pour `expire_le`)** : hor-horaire, car-nuit-captivite, car-transport-60, bro-taille, san-taille, bla-taille, omb-taille, tru-taille, aut-quota-absent, bro-ouv-2e, bro-ferme-2026, omb-ouv-2e, omb-ferme-2026, arc-pas-fermeture-2e, mode-lignes-2e, res-ouvrages.
**Justes mais à corriger (6 `nat-*`)** : voir E1 à E6.
**75 et 94, 9 règles sur 12 justes** : ouv-generale, bro-ouv, bro-ferme, bro-remise-eau, omb-ouv, omb-ferme, fario-ferme-automne, fario-ferme-hiver, interdit-migrateurs. Les 3 autres : fario-ouv (E8), interdit-anguille (E9), interdit-ecrevisses (E10).

### Erreurs et trous, avec correction
- **E1 `nat-car-quota`** : couvre la 2e catégorie seulement. Ajouter `nat-bro-quota-1re` : brochet, 2 par pêcheur et par jour en 1re catégorie. Citation : « le nombre de captures de brochets autorisé par pêcheur de loisir et par jour est fixé à 2 » (projet de décret 2018 art. 9 ; décret 2019-352 art. 9 ajoute l'alinéa à R436-21).
- **E2 aucune règle de 1re catégorie** : ajouter `nat-1re-ouv-generale`, toutes espèces, 14 mars au 20 sept. 2026, fermée aujourd'hui. Citation du brouillon : « la pêche dans les eaux de 1re catégorie est autorisée du deuxième samedi de mars au troisième dimanche de septembre inclus. » [?]. Brochet : « tout brochet capturé du deuxième samedi de mars au dernier vendredi d'avril doit être immédiatement remis à l'eau » (décret 2019-352 art. 3, lu).
- **E3 `nat-fario-ouv`, `nat-fario-ferme-2026-automne`, `nat-2e-ouv-generale` (phrase)** : R436-7 3° vise aussi l'omble ou saumon de fontaine, l'omble chevalier et le cristivomer. Ajouter 2227, 2226, 2228 aux `especes` et corriger « sauf brochet, ombre et truite fario ». Citation : « 3° La pêche de la truite fario, de l'omble ou saumon de fontaine, de l'omble chevalier et du cristivomer, [...] » (brouillon) [?].
- **E4 silure** : `nat-aut-taille-absente` reste juste, mais il manque la règle du décret 2026-464 (garde vivante interdite en Adour-Garonne et Loire-Bretagne depuis le 11/06/2026). Elle exige une couche par bassin. Pas de citation : décret non lu [?].
- **E5 `expire_le` 2026-12-31** : brochet, ombre et fario viennent d'un texte permanent. Au 1er janvier 2027 le moteur dirait « ouvert » toute l'année. Corriger : écrire les règles en formule (« dernier dimanche de janvier ») ou ajouter 2027 : brochet fermé 2027-02-01 au 2027-04-23, ombre fermé 2027-01-01 au 2027-05-14, fario fermée 2026-09-21 au 2027-03-12.
- **E6 `nat-sal-quota`** : range l'ombre (2247) parmi les « salmonidés ». Le Code ne le dit pas [?]. Retirer 2247 ou passer la règle en `incertain` pour l'ombre.
- **E7 `nat-fario-ouv.valeur.prolongation_possible`** : « 1 à 3 semaines en haute montagne, jusqu'au 11 octobre » vient de R436-6 II, non relu [?]. Si la limite est plus longue, la fario serait ouverte le 15 oct. en haute montagne. Exception connue : lac Léman, truites, ombles, corégones pêchés 89 jours entre mi-octobre et mi-janvier (décret 98-155, état 1998) [?]. R436-9 (plans d'eau) : exception à lire [?].
- **E8 `75-` et `94-fario-ouv-2026`** : l'avis dit 21 mars (OCR). Le Code et la page de la fédération disent le 2e samedi de mars, donc le 14 mars. Garder `incertain`. Le Code prime sauf arrêté signé contraire (R436-8 permet au préfet d'interdire temporairement une espèce, donc de retarder) [?]. Sans effet en octobre.
- **E9 `75-` et `94-interdit-anguille`** : « 15 février au 15 juillet : non vérifié ». Lu : fermeture au 15 juillet 2026 en Seine-Normandie (arrêté du 12/06/2026, 3 pages). Aujourd'hui fermée. Le 15 février n'est pas lu [?].
- **E10 `75-` et `94-interdit-ecrevisses`** : trois espèces. R436-10 en nomme quatre (pattes grêles, Astacus leptodactylus) et la fédération l'ajoute à l'interdiction. Citation : « La pêche des écrevisses à pattes rouges (Astacus astacus), des torrents (Astacus torrentium), à pattes blanches (Austropotamobius pallipes) et à pattes grêles (Astacus leptodactylus) est autorisée pendant une période de dix jours consécutifs commençant le quatrième samedi de juillet. » Fermée aujourd'hui dans tous les cas.
- **E11 grenouilles absentes** : la fédération donne 75/94 ouvert du 1er janv. au 2e dimanche de mars et du 3e samedi de mai au 31 déc., 8 cm (R436-18 : « du bout du museau au cloaque »). Ajouter en `incertain`.
- **E12 tailles 60/50/40 contre 50/40/30** : 60/50/40 sont exactement les plafonds que R436-19 laisse au préfet (décret 2019-352 art. 8). Un avis ne relève pas une taille ; un arrêté préfectoral signé le peut (R436-19, texte non lu) [?]. Qui prime : le dernier arrêté signé. Chercher celui de la révision 2026 ; sinon 50/40/30 (arrêtés 2025). Garder `incertain`.
- **E13 brochet fermé, matériel** : l'interdiction du vif, du poisson mort ou artificiel et des leurres pendant la fermeture est dans les arrêtés 75 et 94 ; la FNPF la donne comme nationale. Son article n'est pas lu [?].

## 4. Espèces hors des 14 que les pêcheurs prennent souvent
| Espèce | Règle nationale | 2e cat. aujourd'hui |
|---|---|---|
| Ablette 2090, rotengle 2135, goujon 2113, vandoise 2122, hotu 2104, aspe | R436-7 alinéa 1, rien dans R436-18 ni R436-21 | ouverte, ni taille ni quota. Vandoise : frayères protégés |
| Carassin commun 2102, carassin argenté / poisson rouge | idem ; absents de l'arrêté de 2018 tel que lu [?] | ouverte |
| Perche soleil 2050 | EEE annexe II-3, R432-5 | ouverte ; ne pas relâcher, pas de transport vivant |
| Poisson-chat | R432-5 ; EEE depuis 2023 (annexe II-4, régime non lu) | ouverte ; ne pas relâcher [?] |
| Anguille | arrêtés ministériels ; argentée et civelle interdites | jaune fermée depuis le 15 juil. 2026 |
| « Sandre hybride » | le Code ne parle pas des hybrides | ouverte ; appliquer prudemment 40 cm et le quota du sandre [?] |
Règle d'Adem inchangée : hors des départements saisis, jamais « tu peux la garder ». Une espèce sans taille ni quota nationaux n'a pas de verdict « gardable ».

## 5. Ce qui reste incertain
- Le Code n'est pas relu à la source : toutes les citations « du brouillon » (R436-6, 7, 13, 14, 18, 21, L436-16) restent à relire sur Légifrance. R432-5, R436-9 et R436-10 sont en version ancienne.
- Arrêté de classement des cours d'eau à saumon ou truite de mer : non lu (arc-en-ciel).
- Aloses, lamproies, saumon, truite de mer hors Seine-Normandie : arrêtés de bassin non lus.
- Anguille 2026-2027 : un moratoire de la pêche de loisir était en projet (déc. 2025, janv. 2026), statut inconnu.
- « Ne pas relâcher » les envahissantes : lecture de la FNPF et de la fédération de l'Allier ; l'arrêté de 2018 n'écrit pas « remise à l'eau ». À faire confirmer par la DDT.
- Codes Sandre : 41 sur 77 ; le site Sandre a limité le débit, le reste est à `null`.
- Outils : la limite de recherche web est atteinte et le moteur Parallel répond « Too Many Requests ». Si besoin, relancer une recherche dans un autre message.

## Décision pour Adem (recommandation d'abord)
1. Fusion des corrections E1 à E13 dans `brouillon-75-94.json` : a. oui, par l'humain qui relit, avec relecture Légifrance des citations marquées [?] (recommandé, défaut) ; b. attendre une lecture complète à la source avant toute fusion.
