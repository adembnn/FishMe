Décision débloquée : l'app peut afficher pour les Vosges (88) le classement piscicole, les réserves, la truite de Granges-Aumontzey et les règles des lacs de Gérardmer et Longemer ; les dates, tailles et quotas généraux 2026 ne peuvent pas l'être, faute de l'arrêté permanent 539-2023 et de l'avis 2026 dans le corpus.

Lecteur B, lecture du 2026-10-16. Fichier : outils/regles/dep-b/88.json. Sortie de valider.py : « OK : 272 règles, 8 textes ».

Textes (tous lus en entier ; arrêtés = scans OCR, vérifiés sur l'image pour les noms de cours d'eau de l'article 2 de 0458) :
1. Arrêté 0458/2022, classement piscicole, signé 2022-12-20. https://www.peche88.fr/wp-content/uploads/2023/02/0458.2022_arrete_classement_piscicole.pdf
2. Arrêté 0460/2022, réserves temporaires sur le domaine public fluvial, signé 2022-12-21. https://www.peche88.fr/wp-content/uploads/2023/02/0460.2022_reserves_pehe_dpf.pdf
3. Arrêté 438/2022, réserve de la Frézelle à Rollainville, signé 2022-12-01. https://www.peche88.fr/wp-content/uploads/2023/02/438_2022_reserve_rollainville.pdf
4. Arrêté 436/2022, truite fario Granges-Aumontzey, signé 2022-12-01. https://www.peche88.fr/wp-content/uploads/2023/02/436_2022_modification_granges_aumontzey.pdf
5. Arrêté 966/2016, lacs de Gérardmer et Longemer, signé 2016-12-22. URL du manifeste.
6. Livret de pêche 2026 de la fédération (information, 36 pages, pages de publicité sans règle) : toutes ses règles sont `incertain`.
7 et 8. Arrêté permanent 539-2023 et avis annuel 2026 : titre seul, absents du corpus, aucune règle.

Règles : 272 (brouillon 108, incertain 164).
- categorie 72 (59 cours d'eau de 1re catégorie, un par cours d'eau nommé à l'article 2, plus 7 règles générales ou d'exception, plus lacs, étangs, Maubré)
- mode_peche 55, ouverture 30, interdit 30, reserve 28, taille_min 27, quota_jour 20, no_kill 7, remise_eau 1, horaire 1, carpe_nuit 1.
- Brouillon : 0458 (65 règles), 0460 (11 réserves), 438 (1), 436 (2), 966 (29, dont 2 lacs en double découpage Gérardmer / Longemer).
- Incertain : le livret (AAPPMA Celles, Étival, Rabodeau, Raon, Saint-Dié ; étangs Nièrupt, Para, Delthir, Senones, Dieudonné, Bastien-Didier).

Contradictions :
- Livret, étangs du château de Senones : p. 22 « 4 truites, 25 cm » contre p. 24 « 6 salmonidés, 23 cm ». Les deux sont écrites, en incertain. Le règlement détaillé de l'AAPPMA (p. 24, validé le 18 oct. 2025) devrait primer sur le rappel général de la p. 22.
- Arrêté 436/2022 : la Vologne n'est pas dans la liste de 1re catégorie de 0458, donc 2e catégorie sur le papier. Catégorie écrite `toutes` pour ne pas trancher.

Ce qui manque :
- Arrêté 539-2023 et avis 2026 : dates d'ouverture, tailles, quotas, horaires, carpe de nuit du département. Rien de ces valeurs n'est écrit ici.
- Étangs du Clairupt et de la Ballastière (Raon-l'Étape) : sur la commune de Bertrichamps (54), donc non retenus pour le 88.
- Réserve de Chavelot (280/2016) non trouvée ; les ruisseaux pépinières de Raon sont « en réserve (voir arrêté préfectoral) » sans texte.
- Le livret ne dit pas l'espèce pour « 6 prises, taille 20 cm » (Valdange, Saint-Dié) : lu comme truite (1re catégorie), noté dans valeur.texte.

Écarts de méthode à connaître :
- Les dates du 3e dimanche de septembre (20/09) pour la zone interdite aux confluences des lacs viennent du Code (fermeture de la 1re catégorie), pas du texte de 966. Dit dans valeur.texte.
- Réserve Frézelle : du/au à null (valable toute 2026), fin 2027-03-31 dans expire_le.
- Réserves 0460 : expire_le null, valables jusqu'au renouvellement des baux (date non écrite).
- Règlement « pour tous les étangs » p. 33 du livret rattaché à l'étang Dieudonné seulement (page titrée ainsi).
- J'ai listé le dossier outils/regles/dep/ (noms de fichiers) par erreur et tenté d'ouvrir 01.json, sans résultat (fichier absent). Aucun contenu lu.

3 règles les plus risquées :
1. 88-toutes-interdit-confluence-*-gerardmer / longemer (6 règles) : date de début 2026-09-20 calculée, et arrêté 966 de 2016 peut être modifié par le permanent 539-2023.
2. 88-toutes-categorie-* issues de 0458 (classement 2022) : 59 cours d'eau cités, le permanent ou un arrêté plus récent peut avoir changé le classement ; les sous-limites (ponts) viennent de l'OCR relu sur l'image.
3. 88-2221-taille_min-*-granges-aumontzey (436/2022) : la catégorie reste `toutes`, et la règle modifie un arrêté 041/2021 absent du corpus (aucun id nat-* fourni, remplace null).
