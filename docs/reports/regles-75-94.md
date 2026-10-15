Décision débloquée : quelles règles de pêche de Paris (75) et du Val-de-Marne (94) l'app peut afficher ce soir, et lesquelles restent à « vérifie l'arrêté ».

Brouillon du 15 oct. 2026 pour relecture humaine. Fichier : `regles/brouillon-75-94.json` (98 règles, 65 `brouillon`, 33 `incertain`, `verifie_par` vide partout). « Non vérifié » veut dire « non fusionné » : rien ne va dans `regles.json` avant relecture.

## Réponse courte
- Candidates à l'affichage ce soir, après relecture (texte lu, citation exacte) : catégorie 2 des cours d'eau, horaires, ouvertures et fermetures 2026 (brochet, ombre, fario), quotas, lignes et modes interdits, zone de 50 m autour des barrages et écluses, espèces interdites, carpe de nuit, consommation interdite en Seine, Marne, Yerres (94) et Seine, Ourcq (75).
- À laisser en « vérifie l'arrêté » : tailles du brochet, du sandre et du black-bass (deux textes se contredisent), plans d'eau et canaux, réserves nommées, lac de Créteil, canaux Saint-Martin et Saint-Denis, no-kill.
- Les 2 verdicts de taille des cas 1 et 3 ne sont donc pas ceux que `donnees.md` attend (voir cas de test).

## Textes trouvés
Lus en entier ou en partie utile ; « OCR » = PDF numérisé, texte reconstitué, accents restitués à la main.
1. Code de l'environnement, versions en vigueur en 2026, lues sur Légifrance :
   - R436-6 `legifrance.gouv.fr/codes/article_lc/LEGIARTI000043940083` et R436-7 `.../LEGIARTI000038416162` : périodes (brochet, ombre, fario, arc-en-ciel).
   - R436-13 `.../LEGIARTI000022850266` et R436-14 `.../LEGIARTI000022850261` : horaires, carpe de nuit.
   - R436-18 `.../LEGIARTI000038416171` : tailles ; R436-21 `.../LEGIARTI000038416184` : quotas.
   - R436-23 `legifrance.gouv.fr/codes/section_lc/LEGITEXT000006074220/LEGISCTA000006188900` : lignes.
   - R436-70/71 et R436-73/74 `.../LEGISCTA000006176938` : ouvrages et réserves ; L436-16 `legifrance.gouv.fr/codes/id/LEGISCTA000006176589` : carpe de plus de 60 cm.
2. Val-de-Marne, arrêté permanent n° 2025/00727 du 25/02/2025 (OCR) : classement, horaires, ouvrages, modes, tailles, quotas, carpe de nuit, introductions, anguille.
   `drieat.ile-de-france.developpement-durable.gouv.fr/IMG/pdf/94_ap_peche_permanente_no2025_00727_du_25_02_25.pdf`
3. Paris, arrêté n° 75-2025-02-26-00012 du 26/02/2025, publié au recueil 75-2025-126 du 27/02/2025 (texte propre), même couverture ; carpe de nuit sur deux lots.
   `prefectures-regions.gouv.fr/ile-de-france/.../125632/928907/file/recueil-75-2025-126-recueil-des-actes-administratifs-special%20du%2027.02.2025.pdf`
4. Avis annuels 2026 : 94 fait à Créteil le 10 févr. 2026 (`federation-peche-paris.fr/cms_viewFile.php?idtf=54987&path=Avis-annuel-94-2026.pdf`) ; 75 fait à Paris le 16 janv. 2026 (`...idtf=54984&path=Avis-annuel-75-2026.pdf`), OCR. Ouvertures 2026, rappels, interdiction de consommer. L'avis 2025 de Paris (dans le recueil ci-dessus) sert de recoupement.
5. Fédération 75/92/93/94, page Réglementation, sans date : `federation-peche-paris.fr/808-reglementation.htm`. Seule source des réserves nommées, de la catégorie des plans d'eau et canaux, du lac de Créteil. Pas un texte réglementaire : tout ce qui vient d'elle seule est `incertain`.
6. Page DRIEAT de consultation 2026 (10/02 au 03/03/2026) sur la révision des arrêtés permanents : projets illisibles (images), aucun texte signé trouvé. `drieat.ile-de-france.developpement-durable.gouv.fr/consultation-du-public-projets-d-arretes-sur-la-a13422.html`

## Manquant ou incertain
- Tailles : arrêtés 2025 (75 et 94, art. 9) = 50/40/30 cm (brochet, sandre, black-bass, copie de R436-18). Avis annuels 2026 et 2025 et fédération (92 et 93 aussi) = 60/50/40 cm. Rien ne permet de trancher. Règles `*-bro-taille`, `*-san-taille`, `*-bla-taille` en `incertain` avec `valeur.candidats_cm`.
- Arrêtés de consommation du 4 juin 2010 (2010-555 Paris, 2010-5378 Val-de-Marne) : texte introuvable (page DRIEAT en maintenance). Seule leur mention dans les avis 2026 est lue. Règles en `brouillon` pour la Seine, la Marne, l'Yerres, l'Ourcq ; `incertain` pour les canaux Saint-Martin et Saint-Denis (fédération seule).
- Révision 2026 des arrêtés permanents (changement annoncé : aloses interdites dans toute l'Île-de-France) : texte signé non trouvé. Les règles lues datent de 2025.
- Réserves nommées du 94 (17) et du 75 (Arsenal) : liste de la fédération, arrêté de réserves et cahier des charges 2023-2027 non lus. Toutes `incertain`. Aucune règle de réserve n'a de coordonnées : l'app ne peut pas tester sa position, il faut une couche géographique faite à la main.
- Lac de Créteil, plans d'eau des bois de Vincennes et de Boulogne : règlements intérieurs non lus.
- Parcours no-kill dans le 75 et le 94 : aucun texte trouvé. Ne pas afficher « il n'y en a pas ».
- Espèces protégées (arrêté du 8 déc. 1988), espèces envahissantes (arrêté du 14 févr. 2018), anguille jaune (dates par arrêté ministériel) : non lus. Aucune des 14 espèces n'est interdite dans les textes lus, hors ce qui est listé.
- Fario : l'avis 2026 écrit ouverture le 21 mars, le code et l'arrêté donnent le deuxième samedi de mars (14 mars 2026). Sans effet en octobre ; règle `incertain`.
- Introduction d'espèces (poisson-chat, perche soleil) : l'arrêté ne dit pas ce qu'on fait d'une prise. Règle `incertain`, informative.

## Nombre de règles par type
Sortie du script de génération (98 règles : 22 nationales, 31 pour le 75, 45 pour le 94).

| type | règles |
|---|---|
| interdit (fermetures, espèces interdites) | 17 |
| reserve | 21 |
| ouverture | 13 |
| taille_min | 12 |
| quota_jour | 7 |
| mode_peche | 7 |
| carpe_nuit | 6 |
| categorie | 4 |
| remise_eau | 4 |
| horaire | 3 |
| consommation | 3 |
| transport_vivant | 1 |

## Les 5 cas de test (`donnees.md`)
Date : 15 oct. 2026. Verdicts calculés avec la règle de `donnees.md` : une règle `incertain` interdit « tu peux la garder » ; avec `candidats_cm`, sous le plus petit candidat = relâche, au-dessus du plus grand = taille respectée, entre les deux = vérifie.

1. Brochet 55 cm, Marne à Charenton (94) : **vérifie l'arrêté** (attendu : relâche, 60 cm).
   - Ouvert : `94-bro-ouv-2026` « Brochet Du 1er janvier au 25 janvier 2026 inclus et du 25 avril au 31 décembre 2026 inclus ».
   - Taille : `94-bro-taille`, 50 cm selon l'arrêté (« 0,50 mètre pour le brochet ; », art. 9), 60 cm selon l'avis 2026 (« les tailles minimales de captures sont de 0,40 m pour le black-bass, 0,50m pour le sandre et 0,60m pour le brochet »). 55 cm tombe entre les deux. Si Adem tranche 60 cm, la réponse devient relâche.
   - Quota : `94-car-quota` « trois poissons dont deux brochets maximums ». Consommation : `94-consom-seine-marne-yerres`.
2. Brochet 65 cm, même lieu : **garde possible, avec « consommation interdite »** (attendu : identique), à condition que le moteur lise `candidats_cm`. 65 cm respecte 50 comme 60 ; sans cette lecture, la règle `incertain` donne « vérifie ».
   - Consommation : « La consommation et la commercialisation de poissons pêchés dans la Seine, la Marne et l'Yerres dans le département du Val-de-Marne est interdite par arrêté préfectoral n° 2010-5378 du 4 juin 2010. »
   - Reste à tester côté app : pas à moins de 50 m d'un barrage ou d'une écluse (`94-res-ouvrages-50m`, « Toute pêche est interdite, en tout temps, à partir des barrages et écluses ainsi que sur les 50 mètres de part et d'autre des ouvrages. »).
3. Sandre 45 cm, Seine à Paris (75) : **vérifie l'arrêté** (attendu : relâche, 50 cm).
   - `75-san-taille` : 40 cm (arrêté de Paris art. 9, « 0,40 mètre pour le sandre dans les eaux de la 2e catégorie ; ») ou 50 cm (avis 2026 de Paris). 45 cm tombe entre les deux.
   - Ouvert toute l'année : `75-ouv-generale`, « Tous les poissons autres que les grands migrateurs et ceux faisant l'objet d'une ouverture spécifique du 1er janvier au 31 décembre 2026 inclus ». Consommation : `75-consom-seine-ourcq`, « ... dans la Seine et le canal de l'Ourcq dans le département de Paris est interdite par arrêté préfectoral n°2010-555 du 4 juin 2010. »
4. Fario 30 cm, Lyon : **relâche** (attendu : identique). `nat-fario-ferme-2026-automne` : la fario en 2e catégorie suit le temps de la 1re catégorie (R436-7 3°, « durant le temps d'ouverture de la pêche dans les eaux de la 1re catégorie »), qui finit « au troisième dimanche de septembre inclus » (R436-6), soit le 20 sept. 2026. Même la prolongation maximale de haute montagne (3 semaines) s'arrête le 11 oct.
5. Perche 20 cm, Lyon : **vérifie l'arrêté** (attendu : identique). Le socle national n'a ni taille ni quota pour la perche (`nat-aut-taille-absente`, `nat-aut-quota-absent` : R436-18 et R436-21 ne la citent pas), mais le 69 n'est pas saisi, donc jamais « tu peux la garder ». Dans le 75 ou le 94, la même perche serait gardable (ouverte, sans taille, sans quota) avec la mention consommation interdite en Seine, Marne, Yerres, Ourcq.

## Ajouts au schéma, à fusionner par C
- Champs ajoutés à chaque règle : `citation` (≤300 caractères, `[...]` marque une coupe), `expire_le` (31/12/2026 pour une règle annuelle, `null` sinon) ; `lieu` {cours_eau, amont, aval, communes} sur les réserves, la carpe de nuit, la catégorie et la consommation.
- Types nouveaux que `Core` doit accepter : `categorie`, `mode_peche`, `carpe_nuit`, `transport_vivant`, `remise_eau`, `consommation`, `reserve`. Le squelette connaît déjà `horaire`, `taille_min`, `quota_jour`, `interdit`, `ouverture`.
- `valeur.candidats_cm` : liste de tailles quand deux textes se contredisent (cas 1 à 3).
- Les ids `nat-*` reprennent ceux du squelette de `lot/donnees` : fusionner, ne pas dupliquer. `nat-tru-fermeture-2026` du squelette ferme aussi la truite arc-en-ciel (2216) : à corriger. R436-7 3° ne la ferme qu'en cours d'eau classé à saumon ou truite de mer, et les arrêtés 75 et 94 ne citent que la fario. Voir `nat-arc-pas-fermeture-2e`.
- Les règles `*-fario-ouv-2026`, `*-bro-*-2026` et `*-omb-*-2026` expirent le 31/12/2026 : l'avis 2027 les remplace.

## Décisions pour Adem (recommandation d'abord, défaut si pas de réponse)
1. Tailles en conflit (cas 1 et 3) : a. afficher « vérifie l'arrêté » tant que personne n'a tranché (recommandé, défaut) ; b. appliquer 60/50/40 (prudent, mais fait relâcher un poisson peut-être gardable) ; c. appliquer 50/40/30.
2. Moteur et `candidats_cm` (cas 2) : a. la taille est respectée si elle dépasse le plus grand candidat (recommandé, défaut) ; b. toute règle `incertain` donne « vérifie ».
3. Qui confirme les tailles : a. un appel à la fédération (01 53 14 19 80) ou à la DRIEAT, fait par Adem (recommandé) ; b. j'écris le message à envoyer.

## À relire en priorité
Une erreur sur ces règles change un verdict.
1. `75-` et `94-bro-taille`, `san-taille`, `bla-taille` (6 règles) : 50/40/30 contre 60/50/40.
2. `94-consom-seine-marne-yerres`, `75-consom-seine-ourcq` : arrêtés de 2010 non lus, étendue (rivière entière ? affluents ? bras ?) inconnue. Une erreur ferait dire « mangeable » à tort.
3. `nat-aut-taille-absente`, `nat-aut-quota-absent` : l'absence de taille et de quota pour perche, silure, carpe, gardon, brème, chevesne, tanche, barbeau est déduite d'une liste fermée. Un arrêté local pourrait en ajouter ; ceux de 75 et 94 n'en ajoutent pas.
4. `nat-arc-pas-fermeture-2e` et `75-`/`94-ouv-generale` : arc-en-ciel ouverte toute l'année en 2e catégorie (le squelette la fermait).
5. Révision 2026 des arrêtés permanents : si elle est signée, les règles 2025 peuvent changer (consultation 10/02 au 03/03/2026).
6. `94-car-nuit-cours-eau` (carpe de nuit dans tous les cours d'eau de 2e catégorie, art. 8) et `75-car-nuit-*` (deux lots) : `75-car-nuit-ailleurs` est une lecture, pas une phrase du texte.
7. `*-res-ouvrages-50m` et les 18 réserves de la fédération (17 dans le 94, l'Arsenal dans le 75, `incertain`) : l'app n'a pas de coordonnées pour les appliquer.
8. `*-fario-ouv-2026` : 14 ou 21 mars (sans effet en octobre, à fixer avant mars 2027).
9. `*-cat-plans-eau-canaux` : catégorie des plans d'eau et canaux affirmée par la fédération seule.
