Décision débloquée : quelles règles des Pyrénées-Orientales (66) l'app peut afficher en 2026, ligne par ligne, avec source (lecteur B, 339 règles dans outils/regles/dep-b/66.json).

Textes lus
- Règlement permanent DDTM/SER/2025346-0001, signé le 2025-12-12, lu en entier (couche texte). https://www.pyrenees-orientales.gouv.fr/contenu/telechargement/48045/366451/file/2025346-0001.pdf
- Arrêté annuel 2026 DDTM/SER/2025350-0001, signé le 2025-12-16, lu en entier. Annexes III et IV lues sur l'image des pages 21 à 23 (l'OCR de l'annexe IV était illisible), annexe II (Le Soler, Millas, Saillagouse, Rivesaltes) lue sur l'image. https://www.peche66.org/sites/default/files/deversements/arreteprefectoralannuel.pdf
- Carte des catégories piscicoles (2023, sans signature, OCR bruité) : lue en partie, aucune règle tirée.
- Dépliant de la fédération 2026 : lu, information seule, aucune règle tirée.

Règles : 339, dont 336 brouillon et 3 incertain.
Par type : reserve 72 (43 en rivière, 29 en plans d'eau), mode_peche 53, interdit 49, ouverture 37, no_kill 28, taille_min 22, categorie 18, autre 15, transport_vivant 14, carpe_nuit 13, quota_jour 11, limite_eau_douce 4, horaire 2, remise_eau 1.
Les 28 parcours no kill ont chacun une règle no_kill et une règle mode_peche (mouche seule, mouche et leurres, ou tous modes avec 2 hameçons simples sans ardillon).

Contradictions
- Interdiction du vif et des leurres pour le brochet : l'arrêté annuel dit du 26 janvier au 24 avril, le permanent dit du dernier dimanche de janvier au dernier samedi d'avril (25 janvier au 25 avril). J'ai écrit deux règles, la seconde en incertain. L'annuel devrait primer.
- Anguille : le permanent donne une taille de 12 cm, l'annuel interdit toute pêche de l'anguille. Règle 12 cm en incertain, l'annuel prime.
- Réserve de l'Agly à Cassagnes : 200 m dans l'annexe IV (rivières), 300 m dans l'annexe III (« en aval du barrage jusqu'au ravin de la Guichère »). Les deux sont écrites, le même lieu risque d'être compté deux fois.
- Lignes : le permanent donne 2 lignes dans les grandes retenues de première catégorie et 3 en deuxième catégorie ; le dépliant (non utilisé) dit 1 ligne en première catégorie.

Ce qui manque ou est fragile
- Carnassiers (3 par jour) : le texte ne dit pas quelles espèces. J'ai listé brochet, sandre, perche, black-bass, règle en incertain.
- Annexe I (une soixantaine de lacs de montagne) : une seule règle d'ouverture (2 mai au 11 octobre) pour tous les lacs de plus de 1000 m, pas une par lac.
- Osséja : le permanent le cite comme exception à l'ouverture des lacs de montagne, l'annuel n'en parle pas. Aucune règle (le dépliant dit « ouvert toute l'année », non retenu).
- Date de dégel (permanent art. 4) : remplacée par les dates de l'annuel, pas de règle.
- Aloses : le texte dit « aloses », j'ai écrit une règle pour la grande alose et une pour l'alose feinte.
- Annexe II de Millas : zone de float tube et lacs n°1 et n°2 lus sur l'image, seules les règles citées dans le texte sont écrites.
- Les lignes du tableau de l'annexe IV (réserves en rivière) sont lues sur l'image ; la citation de ces règles est l'article 6, qui renvoie au tableau.
- Pas de réserve de pêche ni de no kill hors de ces deux arrêtés (aucun autre texte dans le corpus).

3 règles les plus risquées
1. 66-...-quota_jour-carnassiers : liste d'espèces supposée, d'où incertain.
2. 66-2151-interdit-vifs-leurres-brochet (annuel) contre sa jumelle du permanent : dates décalées d'un jour, à trancher.
3. Les 43 réserves en rivière de l'annexe IV : noms de ponts et limites lus sur une image de tableau, une faute de lecture d'un nom est possible.

Vérification : python3 -I outils/regles/valider.py outils/regles/dep-b/66.json donne « OK : 339 règles, 4 textes ».
