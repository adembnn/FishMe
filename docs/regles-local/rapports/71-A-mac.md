Décision débloquée : l'app peut afficher 401 règles de Saône-et-Loire en brouillon (5 en incertain), avec source ; la carpe de nuit 2026 et les réserves 2023-2027 sont lues ligne à ligne.

Lecteur A, département 71 (Saône-et-Loire), lu le 2026-10-16. Fichier : outils/regles/dep/71.json (valider.py : OK, 406 règles, 5 textes).

Textes (tous lus en entier, tables vérifiées sur l'image des pages)
1. Arrêté permanent n° 71-2022-12-22-00001, signé 22/12/2022 (copie fédération). Base.
2. Arrêté modificatif n° 71-2026-01-09-00001, signé 09/01/2026 (préfecture). Fait foi : alose interdite, arc-en-ciel 2e cat. du 2e samedi de mars au 31/12, 13 plans d'eau ajoutés à la taille maximale du brochet.
3. Arrêté 2026-0031-DDT, signé 20/02/2026, carpe de nuit 2026 (expire 2026-12-31).
4. Arrêté réserves temporaires 2023-2027, n° 71-2022-12-22-00002 : signature lue sur l'image (22 déc. 2022). expire_le 2027-12-31.
5. AP complémentaire du 13/12/2024 : ABROGÉ (art. 2 du texte 2). Listé « titre seul », aucune règle tirée de lui.

Règles par type : carpe_nuit 149, reserve 84, ouverture 62, interdit 45, fenetre_capture 24, autre 15, remise_eau 7, mode_peche 7, quota_jour 6, taille_min 4, horaire 2, transport_vivant 1.
Règles par statut : brouillon 401, incertain 5.

Incertains
- anguille jaune : dates « fixées par arrêté interministériel », aucune date dans le texte.
- Seille lots SE3 à SE8 : simple rappel d'un APPB du 8/7/2016 non lu.
- Canal du Centre « lots CC4 à CC2 » et Saône/Grosne « lots SA23 à SA18 » : plage de lots imprimée à l'envers, nombre de lots non établi, donc une seule règle chacune.
- Enduro « Carnacarpe 71 : et du 11 au 14 juillet » : la mise en page ne dit pas si c'est Torcy-Vieux ou la Grande Sablière ; placé à Torcy-Vieux, tel qu'imprimé.

Contradictions : aucune entre textes en vigueur. Le texte 2 modifie le texte 1 (arc-en-ciel) ; le texte 2 prime. La liste du brochet 80 cm = liste de base (9 sites) + les 13 du modificatif ; le modificatif abroge l'AP 2024 qui avait étendu la liste, donc la liste à jour est celle-là, mais je ne peux pas prouver qu'elle est complète.

Ce qui manque
- Aucun arrêté annuel d'ouvertures 2026 : les ouvertures viennent du permanent (2022) modifié.
- Pas lus : classement en catégories 1/2 des cours d'eau (arrêté de 2003), no-kill, interdictions de consommation (PCB), cahier des charges de pêche de l'État. Donc aucune règle `categorie` (le texte ne classe aucun cours d'eau).
- Dates 2026 calculées (ex. 3e samedi de mai = 16/05, 2e dimanche de mars = 08/03). La fermeture sandre/brochet des réserves temporaires est déduite des deux périodes ouvertes écrites.

Choix de découpe
- Une règle par lot (CC13, CC14, CC15...), par période de carpe de nuit, par plan d'eau de la liste brochet.
- Réserves du domaine public : la ligne « réserve » et la ligne « interdiction de pêche en barque / aux engins » sont séparées (reserve / interdit).
- Réserves temporaires brochet-sandre : 10 sites x 6 règles (2 ouvertures brochet, 2 ouvertures sandre, 2 interdictions de techniques pendant la fermeture).
- Sandre 2e cat. : 4 règles (période de début, Saône, Doubs, reste du département).
- Les lignes de fond et le carrelet (membres d'AAPPMA, 2e cat. non domaniale) ont chacun plusieurs règles.

Les 3 règles les plus risquées
1. Carpe de nuit « tous les jours » et « tous les week-ends » (≈ 80 règles) : le tableau imprime « du 1er mars au 31 décembre 2025 » alors que l'arrêté vise l'année 2026. J'ai pris 2026 (titre de l'arrêté, consultation de janvier 2026), signalé dans chaque valeur.texte.
2. Brochet 80 cm sur « l'ensemble des cours d'eau » et « les canaux » : lieu au niveau département, plus 22 plans d'eau ; liste complète non prouvée.
3. Réserves : longueurs OCR douteuses ou doubles (Brume-Vaux 600 m / 1000 m, Guye-Joncy 500 m / 200 m, laissées telles quelles) ; la signature de l'arrêté des réserves tient au tampon lu sur l'image.
