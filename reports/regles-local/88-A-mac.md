Décision débloquée : l'app peut afficher pour les Vosges (88) le classement des cours d'eau, les réserves du domaine public, deux tailles de truite et les lots des lacs de Gérardmer et Longemer, chacun avec sa source signée ; les dates, tailles et quotas généraux 2026 restent sans source.

Lecteur A, lu le 2026-10-16. Fichier : outils/regles/dep/88.json (valider.py : OK, 234 règles, 6 textes).

Textes (tous lus en entier ; scans par OCR, noms et dates vérifiés sur l'image pour 0458 p.1 à 3, 0460 p.3, 436 p.2, 966 p.2)
1. Arrêté 0458/2022, 2022-12-20, classement piscicole. https://www.peche88.fr/wp-content/uploads/2023/02/0458.2022_arrete_classement_piscicole.pdf
2. Arrêté 0460/2022, 2022-12-21, réserves du domaine public fluvial (valables jusqu'au renouvellement des baux, date non écrite : expire_le null).
3. Arrêté 438/2022, 2022-12-01, réserve de la Frezelle à Rollainville, jusqu'au 2027-03-31 (expire_le 2027-03-31).
4. Arrêté 436/2022, 2022-12-01, truite fario Vologne 30 cm et affluents 23 cm (lots de Granges-Aumontzey).
5. Arrêté 966/2016, 2016-12-22, lacs de Gérardmer et Longemer.
6. Livret de pêche 2026 EH3VV : information, règles en incertain seulement.

Règles : 234 (101 brouillon, 133 incertain)
- categorie 64, reserve 34, mode_peche 49, taille_min 22, ouverture 21, quota_jour 18, interdit 15, no_kill 7, horaire 2, remise_eau 1, autre 1.
- Brouillon : 0458 (une règle par cours d'eau cité, un par portion, deux noms joints coupés en deux), 0460 (11 réserves), 438, 436, 966 (par lac).
- Incertain : le livret (Celles-sur-Plaine, Étival-Clairefontaine dont l'étang Delthir, Rabodeau, étangs de Senones, Raon-l'Étape, Saint-Dié/Saint-Michel, étang Dieudonné), plus la rigole de Bouzey (Pont le Prieur à Sanchey) et le lac de la Plaine, classés en 2e catégorie par déduction (exclus de la 1re, non cités).

Contradictions
- Livret p.22 : étangs de Senones 4 prises et truite 25 cm ; livret p.24 (règlement du 18 oct. 2025) : salmonidés 6 prises et 23 cm. Je les ai écrites toutes les deux. Le règlement de l'AAPPMA (p.24, daté) devrait primer.
- Livret p.10 : Plaine 1 ligne dans les plans d'eau privés vs 2 lignes au domaine public : lots différents, pas de conflit.

Ce qui manque
- L'arrêté permanent 539-2023 et l'avis annuel 2026 ne sont pas dans le corpus : aucune date d'ouverture générale, aucune taille ni quota départemental. Les textes de 2016 et 2022 sont « en vigueur à confirmer ».
- Le 041/2021 (base de l'arrêté 436/2022) n'est pas lu : d'autres dispositions des lots de Granges-Aumontzey peuvent exister. L'arrêté 436 écrit « 041/2022 » dans un considérant (coquille probable).
- Livret non repris : étangs du Clairupt et de la Ballastière (Bertrichamps, 54, hors département), lac de Pierre Percée (règle de Meurthe-et-Moselle), étangs Bastien-Didier / Dorner / Maurer (découpage ambigu), « 6 prises, 20 ou 23 cm » sans espèce (Valdange, Saint-Dié), tailles brochet 60 et sandre 50 de Delthir (identiques au Code).

Choix de lecture à connaître (pour le consensus)
- Arrêté 966, zones interdites près des confluences : du = 2026-09-20 (date de fermeture de la 1re catégorie, lue à la lettre), au = 2026-11-01.
- Arrêté 966, « espèces autres que les salmonidés, corégones exceptés » : espèce écrite autre:espèces autres que les salmonidés, corégones exceptés ; le texte laisse douteux le sort des corégones.
- Plaine, Madon/Colon, Durbion/Abîme, Vair/Petit Vair, Saône/Thuillières, Coney/Bagnerot : une règle par cours d'eau.
- Affluents d'une rivière cités sans nom (« affluents de la Vologne ») : cours_eau = « affluents de la Vologne ».

Les 3 règles les plus risquées
1. 88-toutes-categorie-cours-eau-non-cites : la 2e catégorie « par défaut » ; si l'arrêté 539-2023 reclasse un cours d'eau, la règle est fausse.
2. 88-2221-taille-min-vologne-granges-aumontzey (et affluents 23 cm) : lue dans un arrêté modificatif dont la base 041/2021 manque.
3. Les règles de l'arrêté 966/2016 (brochet ouvert le 1er mai, 3 lignes, tailles) : texte de 2016, peut être modifié par le permanent 2023.
